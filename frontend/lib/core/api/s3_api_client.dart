import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/api_endpoints.dart';
import '../../features/auth/models/user_model.dart';
import '../models/job.dart';
import 'api_client.dart';

/// Production implementation of [ApiClient] using Dio HTTP client.
///
/// Communicates with the S3 Cloudflare Workers REST API.
/// Handles JWT auth via [FlutterSecureStorage] and envelope unwrapping.
class S3ApiClient implements ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  S3ApiClient({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Auth interceptor: attach JWT Bearer token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'accessToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // Envelope unwrapper: { success: true, data: ... } → unwrap data
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final body = response.data;
          if (body is Map<String, dynamic> && body['success'] == true) {
            response.data = body['data'];
          }
          handler.next(response);
        },
      ),
    );
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  @override
  Future<LoginResponse> createAnonUser() async {
    final response = await _dio.post(ApiEndpoints.authAnon);
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return LoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── User ─────────────────────────────────────────────────────────────────

  @override
  Future<User> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────

  @override
  Future<Job> createJob(Map<String, dynamic> jobData) async {
    final response = await _dio.post(ApiEndpoints.jobs, data: jobData);
    return Job.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> confirmUpload(String jobId) async {
    await _dio.post(ApiEndpoints.confirmUpload(jobId));
  }

  @override
  Future<void> executeJob(String jobId) async {
    await _dio.post(ApiEndpoints.execute(jobId));
  }

  @override
  Future<Job> getJob(String jobId) async {
    final response = await _dio.get(ApiEndpoints.jobById(jobId));
    return Job.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Job>> listJobs() async {
    final response = await _dio.get(ApiEndpoints.jobs);
    final list = response.data as List<dynamic>;
    return list.map((e) => Job.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> cancelJob(String jobId) async {
    await _dio.post(ApiEndpoints.cancel(jobId));
  }
}
