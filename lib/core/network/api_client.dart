import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/field_models.dart';
import '../services/geography_repository.dart';
import '../services/disability_metadata.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

typedef SessionRefreshHandler =
    FutureOr<void> Function(
      String accessToken,
      String refreshToken,
      AppUser user,
    );
typedef SessionExpiredHandler = FutureOr<void> Function();

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;
  String? _refreshToken;
  Future<bool>? _refreshInFlight;
  SessionRefreshHandler? onSessionRefreshed;
  SessionExpiredHandler? onSessionExpired;

  Map<String, String> get authorizationHeaders {
    final authorization = _dio.options.headers['Authorization']?.toString();
    return authorization == null ? const {} : {'Authorization': authorization};
  }

  void setAccessToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void setSession(String? accessToken, String? refreshToken) {
    setAccessToken(accessToken);
    _refreshToken = refreshToken;
  }

  Future<({String token, String refreshToken, AppUser user})> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = response.data ?? const <String, dynamic>{};
      final token = data['access_token']?.toString() ?? '';
      final refreshToken =
          _readRefreshToken(response) ?? _nonEmptyString(data['refresh_token']);
      if (token.isEmpty || refreshToken == null || data['user'] is! Map) {
        throw const ApiException(
          'The server returned an incomplete sign-in response.',
        );
      }
      setSession(token, refreshToken);
      return (
        token: token,
        refreshToken: refreshToken,
        user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
      );
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Unable to sign in. Check your connection and try again.',
      );
    }
  }

  Future<AppUser> getCurrentUser() async {
    try {
      final response = await _authenticated(
        () => _dio.get<Map<String, dynamic>>('/auth/me'),
      );
      final user = response.data?['user'];
      if (user is! Map) {
        throw const ApiException('Your session could not be verified.');
      }
      return AppUser.fromJson(Map<String, dynamic>.from(user));
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Your session could not be verified.');
    }
  }

  Future<String?> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );
      return response.data?['debug_otp']?.toString();
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'A password reset code could not be requested.',
      );
    }
  }

  Future<String> verifyPasswordResetCode(String email, String otp) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {'email': email.trim(), 'otp': otp.trim()},
      );
      final token = response.data?['reset_token']?.toString() ?? '';
      if (token.isEmpty) {
        throw const ApiException('The reset code could not be verified.');
      }
      return token;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'The reset code could not be verified.');
    }
  }

  Future<void> resetPassword(String resetToken, String password) async {
    try {
      await _dio.post<void>(
        '/auth/reset-password',
        data: {'reset_token': resetToken, 'password': password},
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Your password could not be updated.');
    }
  }

  Future<AppUser> updateProfilePhoto({
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final response = await _authenticated(
        () => _dio.put<Map<String, dynamic>>(
          '/me/avatar',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: filename),
          }),
        ),
      );
      final rawUser = response.data?['user'];
      if (rawUser is! Map) {
        throw const ApiException(
          'The server returned an incomplete profile response.',
        );
      }
      return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Your profile photo could not be updated.',
      );
    }
  }

  Future<AppUser> removeProfilePhoto() async {
    try {
      final response = await _authenticated(
        () => _dio.delete<Map<String, dynamic>>('/me/avatar'),
      );
      final rawUser = response.data?['user'];
      if (rawUser is! Map) {
        throw const ApiException(
          'The server returned an incomplete profile response.',
        );
      }
      return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Your profile photo could not be removed.',
      );
    }
  }

  Future<List<FieldAssignment>> getAssignedForms() async {
    try {
      final response = await _authenticated(
        () => _dio.get<dynamic>('/forms/assigned'),
      );
      return _listPayload(response.data)
          .whereType<Map>()
          .map(
            (item) => FieldAssignment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Assigned forms could not be loaded.');
    }
  }

  Future<List<FieldAssignment>> getForms() async {
    try {
      final response = await _authenticated(() => _dio.get<dynamic>('/forms'));
      final forms = _listPayload(response.data)
          .whereType<Map>()
          .map(
            (item) => FieldAssignment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      final hydrated = <FieldAssignment>[];
      const batchSize = 6;
      for (var start = 0; start < forms.length; start += batchSize) {
        final end = (start + batchSize).clamp(0, forms.length);
        hydrated.addAll(
          await Future.wait(
            forms.sublist(start, end).map((form) async {
              if (form.version != null) return form;
              try {
                final detail = await _authenticated(
                  () => _dio.get<Map<String, dynamic>>('/forms/${form.id}'),
                );
                return FieldAssignment.fromJson(
                  detail.data ?? const <String, dynamic>{},
                );
              } on DioException {
                return form;
              }
            }),
          ),
        );
      }
      return hydrated;
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Collection forms could not be loaded.');
    }
  }

  Future<List<SubmissionRecord>> getSubmissions({
    bool mine = true,
    int limit = 200,
  }) async {
    try {
      final response = await _authenticated(
        () => _dio.get<dynamic>(
          '/submissions',
          queryParameters: {'mine': mine, 'limit': limit},
        ),
      );
      return _listPayload(response.data)
          .whereType<Map>()
          .map(
            (item) =>
                SubmissionRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'Submission history could not be loaded.',
      );
    }
  }

  Future<SubmissionRecord> submit({
    required int formId,
    required int formVersionId,
    required String clientSubmissionId,
    required String deviceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final submissionData = Map<String, dynamic>.from(data);
      final geography = submissionData.remove(geographyValueKey);
      final disability = submissionData.remove(disabilityValueKey);
      final response = await _authenticated(
        () => _dio.post<Map<String, dynamic>>(
          '/forms/$formId/submissions',
          data: {
            'form_id': formId,
            'form_version_id': formVersionId,
            'device_id': deviceId,
            'client_submission_id': clientSubmissionId,
            'geography': geography,
            'disability': disability,
            'data': submissionData,
          },
        ),
      );
      return SubmissionRecord.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'This record could not be submitted.');
    }
  }

  Future<Map<String, dynamic>> uploadFile({
    required String filename,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      final ticket = await _authenticated(
        () => _dio.post<Map<String, dynamic>>(
          '/files/presign-upload',
          data: {'filename': filename},
        ),
      );
      final ticketData = ticket.data ?? const <String, dynamic>{};
      final uploadUrl = ticketData['upload_url']?.toString();
      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw const ApiException(
          'The upload service returned an incomplete response.',
        );
      }
      final response = await _authenticated(
        () => _dio.put<Map<String, dynamic>>(
          AppConfig.absoluteUrl(uploadUrl),
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: filename),
          }),
        ),
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Evidence could not be uploaded.');
    }
  }

  Future<SubmissionRecord> reviewSubmission(
    String submissionId, {
    required String status,
    String? note,
  }) async {
    try {
      final response = await _authenticated(
        () => _dio.patch<Map<String, dynamic>>(
          '/submissions/$submissionId/review',
          data: {'status': status, 'review_note': note},
        ),
      );
      return SubmissionRecord.fromJson(
        response.data ?? const <String, dynamic>{},
      );
    } on DioException catch (error) {
      throw _mapError(
        error,
        fallback: 'The review decision could not be saved.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(
        '/auth/logout',
        data: {'refresh_token': _refreshToken},
      );
    } on DioException {
      // Local sign-out must still succeed when the network is unavailable.
    }
    setSession(null, null);
  }

  Future<Response<T>> _authenticated<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      if (error.response?.statusCode != 401 || !await _refreshSession()) {
        rethrow;
      }
      return request();
    }
  }

  Future<bool> _refreshSession() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;
    final refresh = _performRefresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _performRefresh() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );
      final data = response.data ?? const <String, dynamic>{};
      final accessToken = data['access_token']?.toString() ?? '';
      final refreshedToken =
          _readRefreshToken(response) ?? _nonEmptyString(data['refresh_token']);
      final rawUser = data['user'];
      if (accessToken.isEmpty || refreshedToken == null || rawUser is! Map) {
        setSession(null, null);
        await onSessionExpired?.call();
        return false;
      }
      final user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));
      setSession(accessToken, refreshedToken);
      await onSessionRefreshed?.call(accessToken, refreshedToken, user);
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        setSession(null, null);
        await onSessionExpired?.call();
      }
      return false;
    }
  }

  String? _readRefreshToken(Response<dynamic> response) {
    final cookies = response.headers.map['set-cookie'] ?? const <String>[];
    for (final cookie in cookies) {
      final match = RegExp(
        r'(?:^|;\s*)iccasa_refresh_token=([^;]+)',
      ).firstMatch(cookie);
      final value = match?.group(1);
      if (value != null && value.isNotEmpty) return Uri.decodeComponent(value);
    }
    return null;
  }

  String? _nonEmptyString(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty || text == 'null' ? null : text;
  }

  List<dynamic> _listPayload(Object? body) {
    if (body is List) return body;
    if (body is Map && body['results'] is List) {
      return body['results'] as List;
    }
    return const [];
  }

  ApiException _mapError(DioException error, {required String fallback}) {
    final body = error.response?.data;
    String? detail;
    if (body is Map) {
      final errorBody = body['error'];
      final raw =
          body['detail'] ??
          body['message'] ??
          (errorBody is Map
              ? errorBody['message'] ?? errorBody['details']
              : null);
      if (raw is String) detail = raw;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        detail = (raw.first as Map)['msg']?.toString();
      }
      if (raw is Map && raw.isNotEmpty) {
        final first = raw.values.first;
        detail = first is List && first.isNotEmpty
            ? first.first.toString()
            : first.toString();
      }
    }
    return ApiException(
      detail ?? fallback,
      statusCode: error.response?.statusCode,
    );
  }
}
