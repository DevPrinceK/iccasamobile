import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/field_models.dart';

class LocalStore {
  static const _tokenKey = 'iccasa_access_token';
  static const _refreshTokenKey = 'iccasa_refresh_token';
  static const _userKey = 'iccasa_user';
  static const _formsKey = 'iccasa_assigned_forms';
  static const _submissionsKey = 'iccasa_submissions';
  static const _draftsKey = 'iccasa_drafts';
  static const _outboxKey = 'iccasa_outbox';
  static const _themeKey = 'iccasa_theme_mode';
  static const _contrastKey = 'iccasa_high_contrast';
  static const _textScaleKey = 'iccasa_text_scale';
  static const _deviceIdKey = 'iccasa_device_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _preferences;
  int? _ownerId;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  Future<String?> readToken() async => _readSecure(_tokenKey);
  Future<String?> readRefreshToken() async => _readSecure(_refreshTokenKey);

  Future<void> saveSession(
    String token,
    AppUser user, {
    String? refreshToken,
  }) async {
    _ownerId = user.id;
    final writes = <Future<void>>[
      _writeSecure(_tokenKey, token),
      _writeSecure(_userKey, encodeJsonList([user], (item) => item.toJson())),
    ];
    if (refreshToken != null && refreshToken.isNotEmpty) {
      writes.add(_writeSecure(_refreshTokenKey, refreshToken));
    }
    await Future.wait(writes);
  }

  Future<AppUser?> readUser() async {
    final rows = decodeJsonList(await _readSecure(_userKey));
    if (rows.isEmpty) return null;
    final user = AppUser.fromJson(rows.first);
    _ownerId = user.id;
    return user;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _deleteSecure(_tokenKey),
      _deleteSecure(_refreshTokenKey),
      _deleteSecure(_userKey),
    ]);
    _ownerId = null;
  }

  Future<List<FieldAssignment>> readAssignments() async => decodeJsonList(
    await _readSecure(_scoped(_formsKey)),
  ).map(FieldAssignment.fromJson).toList();

  Future<void> saveAssignments(List<FieldAssignment> values) => _writeSecure(
    _scoped(_formsKey),
    encodeJsonList(values, (item) => item.toJson()),
  );

  Future<List<SubmissionRecord>> readSubmissions() async => decodeJsonList(
    await _readSecure(_scoped(_submissionsKey)),
  ).map(SubmissionRecord.fromJson).toList();

  Future<void> saveSubmissions(List<SubmissionRecord> values) => _writeSecure(
    _scoped(_submissionsKey),
    encodeJsonList(values, (item) => item.toJson()),
  );

  Future<List<DraftRecord>> readDrafts() async => decodeJsonList(
    await _readSecure(_scoped(_draftsKey)),
  ).map(DraftRecord.fromJson).toList();

  Future<void> saveDrafts(List<DraftRecord> values) => _writeSecure(
    _scoped(_draftsKey),
    encodeJsonList(values, (item) => item.toJson()),
  );

  Future<List<OutboxItem>> readOutbox() async => decodeJsonList(
    await _readSecure(_scoped(_outboxKey)),
  ).map(OutboxItem.fromJson).toList();

  Future<void> saveOutbox(List<OutboxItem> values) => _writeSecure(
    _scoped(_outboxKey),
    encodeJsonList(values, (item) => item.toJson()),
  );

  String get themeMode => _preferences.getString(_themeKey) ?? 'system';
  bool get highContrast => _preferences.getBool(_contrastKey) ?? false;
  double get textScale => _preferences.getDouble(_textScaleKey) ?? 1;
  String? get deviceId => _preferences.getString(_deviceIdKey);

  Future<void> saveThemeMode(String value) =>
      _preferences.setString(_themeKey, value);
  Future<void> saveHighContrast(bool value) =>
      _preferences.setBool(_contrastKey, value);
  Future<void> saveTextScale(double value) =>
      _preferences.setDouble(_textScaleKey, value);
  Future<void> saveDeviceId(String value) =>
      _preferences.setString(_deviceIdKey, value);

  Future<void> clearOperationalData() async {
    await Future.wait([
      _deleteSecure(_scoped(_formsKey)),
      _deleteSecure(_scoped(_submissionsKey)),
      _deleteSecure(_scoped(_draftsKey)),
      _deleteSecure(_scoped(_outboxKey)),
    ]);
  }

  String _scoped(String key) => '${key}_${_ownerId ?? 'signed_out'}';

  Future<String?> _readSecure(String key) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) return secureValue;
    final legacyValue = _preferences.getString(key);
    if (legacyValue != null) {
      try {
        await _secureStorage.write(key: key, value: legacyValue);
      } finally {
        await _preferences.remove(key);
      }
    }
    return legacyValue;
  }

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } finally {
      await _preferences.remove(key);
    }
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } finally {
      await _preferences.remove(key);
    }
  }
}
