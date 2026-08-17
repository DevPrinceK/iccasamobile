import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/field_models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

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

  void setAccessToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<({String token, AppUser user})> login(
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
      if (token.isEmpty || data['user'] is! Map) {
        throw const ApiException(
          'The server returned an incomplete sign-in response.',
        );
      }
      setAccessToken(token);
      return (
        token: token,
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
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final user = response.data?['user'];
      if (user is! Map) {
        throw const ApiException('Your session could not be verified.');
      }
      return AppUser.fromJson(Map<String, dynamic>.from(user));
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Your session could not be verified.');
    }
  }

  Future<List<FieldAssignment>> getAssignedForms() async {
    try {
      final response = await _dio.get<List<dynamic>>('/forms/assigned');
      return (response.data ?? const [])
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
      final response = await _dio.get<List<dynamic>>('/forms');
      return (response.data ?? const [])
          .whereType<Map>()
          .map(
            (item) => FieldAssignment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Collection forms could not be loaded.');
    }
  }

  Future<List<SubmissionRecord>> getSubmissions({
    bool mine = true,
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/submissions',
        queryParameters: {'mine': mine, 'limit': limit},
      );
      return (response.data ?? const [])
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
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/forms/$formId/submissions',
        data: {
          'form_id': formId,
          'form_version_id': formVersionId,
          'device_id': AppConfig.deviceName,
          'data': data,
        },
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
      final ticket = await _dio.post<Map<String, dynamic>>(
        '/files/presign-upload',
        data: {'filename': filename},
      );
      final ticketData = ticket.data ?? const <String, dynamic>{};
      final uploadUrl = ticketData['upload_url']?.toString();
      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw const ApiException(
          'The upload service returned an incomplete response.',
        );
      }
      final response = await _dio.put<Map<String, dynamic>>(
        uploadUrl,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
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
      final response = await _dio.patch<Map<String, dynamic>>(
        '/submissions/$submissionId/review',
        data: {'status': status, 'note': note},
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
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Local sign-out must still succeed when the network is unavailable.
    }
    setAccessToken(null);
  }

  ApiException _mapError(DioException error, {required String fallback}) {
    final body = error.response?.data;
    String? detail;
    if (body is Map) {
      final raw = body['detail'] ?? body['message'];
      if (raw is String) detail = raw;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        detail = (raw.first as Map)['msg']?.toString();
      }
    }
    return ApiException(
      detail ?? fallback,
      statusCode: error.response?.statusCode,
    );
  }
}
