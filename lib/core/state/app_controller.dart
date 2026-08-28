import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/field_models.dart';
import '../network/api_client.dart';
import '../services/geography_repository.dart';
import '../storage/local_store.dart';

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(api: ApiClient(), store: LocalStore());
  unawaited(controller.initialize());
  return controller;
});

class AppController extends ChangeNotifier {
  AppController({required ApiClient api, required LocalStore store})
    : _api = api,
      _store = store {
    _api.onSessionRefreshed = _handleSessionRefresh;
    _api.onSessionExpired = _expireSession;
  }

  final ApiClient _api;
  final LocalStore _store;
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? _accessToken;
  String? _refreshToken;

  AppStage stage = AppStage.booting;
  AppUser? user;
  List<FieldAssignment> assignments = [];
  List<SubmissionRecord> submissions = [];
  List<DraftRecord> drafts = [];
  List<OutboxItem> outbox = [];
  ThemeMode themeMode = ThemeMode.system;
  bool highContrast = false;
  double textScale = 1;
  bool isOnline = true;
  bool isBusy = false;
  bool isRefreshing = false;
  bool isSyncing = false;
  bool isUpdatingProfilePhoto = false;
  bool previewMode = false;
  String? errorMessage;
  DateTime? lastSyncedAt;
  String deviceId = AppConfig.deviceName;

  int get pendingReviewCount =>
      submissions.where((item) => item.isAwaitingReview).length;
  int get acceptedCount =>
      submissions.where((item) => item.status == 'accepted').length;
  int get completedToday => submissions.where((item) {
    final now = DateTime.now();
    return item.createdAt.year == now.year &&
        item.createdAt.month == now.month &&
        item.createdAt.day == now.day;
  }).length;
  bool get hasLocalWork => drafts.isNotEmpty || outbox.isNotEmpty;
  String? get avatarUrl =>
      user?.avatarUrl == null ? null : AppConfig.absoluteUrl(user!.avatarUrl!);
  Map<String, String> get avatarHeaders => _api.authorizationHeaders;

  Future<void> initialize() async {
    try {
      await _store.initialize();
      themeMode = _parseThemeMode(_store.themeMode);
      highContrast = _store.highContrast;
      textScale = _store.textScale;
      deviceId =
          _store.deviceId ??
          '${AppConfig.deviceName}-${_uuid.v4().substring(0, 8).toUpperCase()}';
      await _store.saveDeviceId(deviceId);
      user = await _store.readUser();
      await _loadCachedOperationalData();

      final connectivity = await _connectivity.checkConnectivity();
      isOnline = !connectivity.contains(ConnectivityResult.none);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      final token = await _store.readToken();
      final refreshToken = await _store.readRefreshToken();
      if (token == null || token.isEmpty) {
        stage = AppStage.signedOut;
      } else {
        _accessToken = token;
        _refreshToken = refreshToken;
        _api.setSession(token, refreshToken);
        if (isOnline) {
          try {
            user = await _api.getCurrentUser();
            await _store.saveSession(
              _accessToken!,
              user!,
              refreshToken: _refreshToken,
            );
            stage = AppStage.signedIn;
            await refreshAll(silent: true);
          } on ApiException catch (error) {
            if (error.statusCode == 401) {
              await _store.clearSession();
              user = null;
              stage = AppStage.signedOut;
            } else if (user != null) {
              stage = AppStage.signedIn;
              errorMessage = 'Working offline with the latest saved data.';
            } else {
              stage = AppStage.signedOut;
            }
          }
        } else if (user != null) {
          stage = AppStage.signedIn;
        } else {
          stage = AppStage.signedOut;
        }
      }
    } catch (_) {
      stage = AppStage.signedOut;
      errorMessage = 'Local app data could not be opened. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await _api.login(email, password);
      user = session.user;
      _accessToken = session.token;
      _refreshToken = session.refreshToken;
      previewMode = false;
      await _store.saveSession(
        session.token,
        session.user,
        refreshToken: session.refreshToken,
      );
      await _loadCachedOperationalData();
      stage = AppStage.signedIn;
      notifyListeners();
      await refreshAll(silent: true);
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<String?> requestPasswordReset(String email) =>
      _api.requestPasswordReset(email);

  Future<String> verifyPasswordResetCode(String email, String otp) =>
      _api.verifyPasswordResetCode(email, otp);

  Future<void> resetPassword(String resetToken, String password) =>
      _api.resetPassword(resetToken, password);

  Future<void> updateProfilePhoto({
    required String filename,
    required Uint8List bytes,
  }) async {
    isUpdatingProfilePhoto = true;
    notifyListeners();
    try {
      final updated = await _api.updateProfilePhoto(
        filename: filename,
        bytes: bytes,
      );
      user = updated;
      if (_accessToken != null) {
        await _store.saveSession(
          _accessToken!,
          updated,
          refreshToken: _refreshToken,
        );
      }
    } finally {
      isUpdatingProfilePhoto = false;
      notifyListeners();
    }
  }

  Future<void> removeProfilePhoto() async {
    isUpdatingProfilePhoto = true;
    notifyListeners();
    try {
      final updated = await _api.removeProfilePhoto();
      user = updated;
      if (_accessToken != null) {
        await _store.saveSession(
          _accessToken!,
          updated,
          refreshToken: _refreshToken,
        );
      }
    } finally {
      isUpdatingProfilePhoto = false;
      notifyListeners();
    }
  }

  Future<void> enterPreview() async {
    previewMode = true;
    user = const AppUser(
      id: -1,
      organizationId: 1,
      name: 'Abena Mensah',
      email: 'abena.mensah@iccasa.local',
      role: 'field_agent',
      phone: '+233 20 000 0201',
    );
    assignments = _previewAssignments();
    submissions = _previewSubmissions();
    drafts = [];
    outbox = [];
    stage = AppStage.signedIn;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshAll({bool silent = false}) async {
    if (previewMode || stage != AppStage.signedIn || !isOnline) return;
    if (!silent) {
      isRefreshing = true;
      errorMessage = null;
      notifyListeners();
    }
    ApiException? refreshError;
    try {
      try {
        assignments = (user?.canReview ?? false)
            ? await _api.getForms()
            : await _api.getAssignedForms();
        await _store.saveAssignments(assignments);
      } on ApiException catch (error) {
        refreshError = error;
      }
      try {
        submissions = await _api.getSubmissions(
          mine: !(user?.canReview ?? false),
        );
        await _store.saveSubmissions(submissions);
      } on ApiException catch (error) {
        refreshError ??= error;
      }
      if (assignments.isNotEmpty || submissions.isNotEmpty) {
        lastSyncedAt = DateTime.now();
        if (outbox.isNotEmpty) await syncOutbox();
      }
      if (refreshError != null) {
        errorMessage = refreshError.message;
      }
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  FieldAssignment? assignmentById(int id) {
    for (final assignment in assignments) {
      if (assignment.id == id) return assignment;
    }
    return null;
  }

  String formName(int id) => assignmentById(id)?.name ?? 'Collection form';

  DraftRecord beginDraft(FieldAssignment assignment) {
    final existing = drafts
        .where((draft) => draft.formId == assignment.id)
        .firstOrNull;
    if (existing != null) return existing;
    final draft = DraftRecord(
      id: _uuid.v4(),
      formId: assignment.id,
      formVersionId: assignment.version?.id ?? 0,
      formName: assignment.name,
      values: {},
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    drafts = [draft, ...drafts];
    unawaited(_store.saveDrafts(drafts));
    notifyListeners();
    return draft;
  }

  DraftRecord? draftById(String id) =>
      drafts.where((draft) => draft.id == id).firstOrNull;

  Future<void> updateDraft(String id, Map<String, dynamic> values) async {
    drafts = drafts
        .map(
          (draft) => draft.id == id
              ? DraftRecord(
                  id: draft.id,
                  formId: draft.formId,
                  formVersionId: draft.formVersionId,
                  formName: draft.formName,
                  values: Map<String, dynamic>.from(values),
                  startedAt: draft.startedAt,
                  updatedAt: DateTime.now(),
                )
              : draft,
        )
        .toList();
    await _store.saveDrafts(drafts);
    notifyListeners();
  }

  Future<void> deleteDraft(String id) async {
    drafts = drafts.where((draft) => draft.id != id).toList();
    await _store.saveDrafts(drafts);
    notifyListeners();
  }

  Future<void> discardOutboxItem(String id) async {
    outbox = outbox.where((item) => item.id != id).toList();
    submissions = submissions.where((item) => item.id != id).toList();
    await _persistOperationalData();
    notifyListeners();
  }

  Future<bool> submitDraft(String id, Map<String, dynamic> values) async {
    final draft = draftById(id);
    if (draft == null) {
      throw const ApiException('This draft is no longer available.');
    }
    await updateDraft(id, values);

    if (previewMode) {
      _completeLocalDraft(draft, values, status: 'queued');
      await _persistOperationalData();
      notifyListeners();
      return true;
    }

    if (isOnline) {
      try {
        final submitted = await _api.submit(
          formId: draft.formId,
          formVersionId: draft.formVersionId,
          clientSubmissionId: draft.id,
          deviceId: deviceId,
          data: await _prepareUploads(values),
        );
        drafts = drafts.where((item) => item.id != id).toList();
        submissions = [
          submitted,
          ...submissions.where((item) => item.id != submitted.id),
        ];
        await _persistOperationalData();
        notifyListeners();
        return true;
      } on ApiException catch (error) {
        if (error.statusCode != null && error.statusCode! < 500) rethrow;
      }
    }

    final item = OutboxItem(
      id: draft.id,
      formId: draft.formId,
      formVersionId: draft.formVersionId,
      formName: draft.formName,
      data: Map<String, dynamic>.from(values),
      createdAt: DateTime.now(),
    );
    drafts = drafts.where((entry) => entry.id != id).toList();
    outbox = [item, ...outbox.where((entry) => entry.id != item.id)];
    submissions = [
      SubmissionRecord(
        id: item.id,
        formId: item.formId,
        formVersionId: item.formVersionId,
        status: 'queued',
        data: submissionDataFromValues(item.data),
        createdAt: item.createdAt,
        localState: LocalRecordState.queued,
        formName: item.formName,
        countryName: geographyFromValues(item.data)['country_name']?.toString(),
        administrativeAreaName: geographyFromValues(
          item.data,
        )['administrative_area_name']?.toString(),
        administrativeAreaType: geographyFromValues(
          item.data,
        )['administrative_area_type']?.toString(),
      ),
      ...submissions.where((entry) => entry.id != item.id),
    ];
    await _persistOperationalData();
    notifyListeners();
    return false;
  }

  Future<void> syncOutbox() async {
    if (!isOnline || previewMode || outbox.isEmpty || isSyncing) return;
    isSyncing = true;
    errorMessage = null;
    notifyListeners();
    final remaining = <OutboxItem>[];
    for (final item in outbox.reversed) {
      try {
        final submitted = await _api.submit(
          formId: item.formId,
          formVersionId: item.formVersionId,
          clientSubmissionId: item.id,
          deviceId: deviceId,
          data: await _prepareUploads(item.data),
        );
        submissions = [
          submitted,
          ...submissions.where(
            (record) => record.id != item.id && record.id != submitted.id,
          ),
        ];
      } on ApiException catch (error) {
        remaining.add(
          item.copyWith(attempts: item.attempts + 1, lastError: error.message),
        );
      }
    }
    outbox = remaining.reversed.toList();
    lastSyncedAt = DateTime.now();
    isSyncing = false;
    if (outbox.isNotEmpty) {
      errorMessage = '${outbox.length} record(s) still need attention.';
    }
    await _persistOperationalData();
    notifyListeners();
  }

  Future<void> review(String id, String status, {String? note}) async {
    if (previewMode) {
      submissions = submissions
          .map(
            (item) => item.id == id
                ? SubmissionRecord(
                    id: item.id,
                    formId: item.formId,
                    formVersionId: item.formVersionId,
                    status: status,
                    data: item.data,
                    createdAt: item.createdAt,
                    reviewNote: note,
                    formName: item.formName,
                    countryName: item.countryName,
                    administrativeAreaName: item.administrativeAreaName,
                    administrativeAreaType: item.administrativeAreaType,
                  )
                : item,
          )
          .toList();
    } else {
      final reviewed = await _api.reviewSubmission(
        id,
        status: status,
        note: note,
      );
      submissions = [reviewed, ...submissions.where((item) => item.id != id)];
    }
    await _store.saveSubmissions(submissions);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _store.saveThemeMode(value.name);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    highContrast = value;
    await _store.saveHighContrast(value);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value.clamp(0.9, 1.3);
    await _store.saveTextScale(textScale);
    notifyListeners();
  }

  Future<void> clearCachedOperationalData() async {
    assignments = [];
    submissions = [];
    drafts = [];
    outbox = [];
    await _store.clearOperationalData();
    notifyListeners();
    if (isOnline && !previewMode) await refreshAll();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!previewMode) await _api.logout();
    await _store.clearSession();
    _accessToken = null;
    _refreshToken = null;
    user = null;
    previewMode = false;
    assignments = [];
    submissions = [];
    drafts = [];
    outbox = [];
    stage = AppStage.signedOut;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleSessionRefresh(
    String accessToken,
    String refreshToken,
    AppUser refreshedUser,
  ) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    user = refreshedUser;
    await _store.saveSession(
      accessToken,
      refreshedUser,
      refreshToken: refreshToken,
    );
    notifyListeners();
  }

  Future<void> _expireSession() async {
    _accessToken = null;
    _refreshToken = null;
    user = null;
    assignments = [];
    submissions = [];
    stage = AppStage.signedOut;
    errorMessage = 'Your session expired. Sign in again to continue.';
    await _store.clearSession();
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = isOnline;
    isOnline = !results.contains(ConnectivityResult.none);
    notifyListeners();
    if (!wasOnline && isOnline && stage == AppStage.signedIn) {
      unawaited(refreshAll(silent: true));
    }
  }

  void _completeLocalDraft(
    DraftRecord draft,
    Map<String, dynamic> values, {
    required String status,
  }) {
    drafts = drafts.where((item) => item.id != draft.id).toList();
    submissions = [
      SubmissionRecord(
        id: 'preview-${DateTime.now().millisecondsSinceEpoch}',
        formId: draft.formId,
        formVersionId: draft.formVersionId,
        status: status,
        data: submissionDataFromValues(values),
        createdAt: DateTime.now(),
        formName: draft.formName,
        countryName: geographyFromValues(values)['country_name']?.toString(),
        administrativeAreaName: geographyFromValues(
          values,
        )['administrative_area_name']?.toString(),
        administrativeAreaType: geographyFromValues(
          values,
        )['administrative_area_type']?.toString(),
      ),
      ...submissions,
    ];
  }

  Future<void> _persistOperationalData() => Future.wait([
    _store.saveDrafts(drafts),
    _store.saveOutbox(outbox),
    _store.saveSubmissions(submissions),
  ]);

  Future<void> _loadCachedOperationalData() async {
    assignments = await _store.readAssignments();
    final secureData = await Future.wait([
      _store.readSubmissions(),
      _store.readDrafts(),
      _store.readOutbox(),
    ]);
    submissions = secureData[0] as List<SubmissionRecord>;
    drafts = secureData[1] as List<DraftRecord>;
    outbox = secureData[2] as List<OutboxItem>;
  }

  Future<Map<String, dynamic>> _prepareUploads(
    Map<String, dynamic> data,
  ) async {
    final prepared = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map && value['_upload_bytes'] is String) {
        final upload = await _api.uploadFile(
          filename: value['filename']?.toString() ?? '${entry.key}.png',
          contentType: value['content_type']?.toString(),
          bytes: base64Decode(value['_upload_bytes'] as String),
        );
        prepared[entry.key] = upload;
      } else {
        prepared[entry.key] = value;
      }
    }
    return prepared;
  }

  ThemeMode _parseThemeMode(String value) => ThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeMode.system,
  );

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

List<FieldAssignment> _previewAssignments() {
  final forms = [
    (
      101,
      'Inclusive Adaptation Results Verification',
      'Verify participation, inclusion and adaptation outcomes at implementation sites.',
    ),
    (
      102,
      'Climate Finance Beneficiary Survey',
      'Capture beneficiary reach, finance access and safeguarding feedback.',
    ),
    (
      103,
      'Early Warning System Site Check',
      'Confirm accessibility, uptime and community use of early warning channels.',
    ),
    (
      104,
      'Quarterly Partner Monitoring Visit',
      'Document delivery progress, evidence quality and agreed follow-up actions.',
    ),
  ];
  return forms.map((form) {
    final fields = [
      {
        'id': 1,
        'key': 'country',
        'label': 'Country',
        'field_type': 'Select',
        'order': 0,
        'required': true,
        'config': {
          'options': ['Ghana', 'Senegal', 'Kenya', 'Zambia'],
        },
      },
      {
        'id': 2,
        'key': 'district',
        'label': 'District or region',
        'field_type': 'Text',
        'order': 1,
        'required': true,
        'config': {},
      },
      {
        'id': 3,
        'key': 'reporting_period',
        'label': 'Reporting period',
        'field_type': 'Date',
        'order': 2,
        'required': true,
        'config': {},
      },
      {
        'id': 4,
        'key': 'site_name',
        'label': 'Implementation site',
        'field_type': 'Text',
        'order': 3,
        'required': true,
        'config': {},
      },
      {
        'id': 5,
        'key': 'women_participants',
        'label': 'Women participants',
        'field_type': 'Number',
        'order': 4,
        'required': true,
        'config': {},
      },
      {
        'id': 6,
        'key': 'men_participants',
        'label': 'Men participants',
        'field_type': 'Number',
        'order': 5,
        'required': true,
        'config': {},
      },
      {
        'id': 7,
        'key': 'pwd_participants',
        'label': 'Participants with disabilities',
        'field_type': 'Number',
        'order': 6,
        'required': false,
        'config': {},
      },
      {
        'id': 8,
        'key': 'value',
        'label': 'Verified result value',
        'field_type': 'Number',
        'order': 7,
        'required': true,
        'config': {},
      },
      {
        'id': 9,
        'key': 'evidence_verified',
        'label': 'Supporting evidence verified',
        'field_type': 'Checkbox',
        'order': 8,
        'required': true,
        'config': {},
      },
      {
        'id': 10,
        'key': 'gps',
        'label': 'GPS location',
        'field_type': 'GPS',
        'order': 9,
        'required': false,
        'config': {},
      },
      {
        'id': 11,
        'key': 'notes',
        'label': 'Enumerator observations',
        'field_type': 'Long Text',
        'order': 10,
        'required': false,
        'config': {},
      },
    ];
    return FieldAssignment.fromJson({
      'id': form.$1,
      'project_id': 25,
      'indicator_id': form.$1,
      'name': form.$2,
      'description': form.$3,
      'is_active': true,
      'current_version': {
        'id': form.$1 + 1000,
        'version': 2,
        'is_published': true,
        'schema': {
          'instructions':
              'Confirm consent, review the source documents and complete every required field before submission.',
        },
        'fields': fields,
      },
    });
  }).toList();
}

List<SubmissionRecord> _previewSubmissions() {
  final now = DateTime.now();
  return List.generate(14, (index) {
    final statuses = ['accepted', 'queued', 'accepted', 'rejected'];
    return SubmissionRecord(
      id: '${8000 + index}',
      formId: 101 + (index % 4),
      formVersionId: 1101 + (index % 4),
      status: statuses[index % statuses.length],
      formName: _previewAssignments()[index % 4].name,
      createdAt: now.subtract(Duration(hours: index * 7)),
      reviewNote: index % 4 == 3
          ? 'Please attach a clearer source register.'
          : null,
      countryName: ['Ghana', 'Senegal', 'Kenya', 'Zambia'][index % 4],
      administrativeAreaName: [
        'Tamale',
        'Dakar',
        'Kisumu',
        'Lusaka',
      ][index % 4],
      administrativeAreaType: index % 4 == 2 ? 'County' : 'District',
      data: {
        'site_name': 'Partner site ${index + 1}',
        'women_participants': 14 + index,
        'men_participants': 9 + index,
        'value': 64 + index,
        'evidence_verified': true,
      },
    );
  });
}
