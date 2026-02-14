import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/user.dart';
import '../models/preset.dart';
import '../models/rule.dart';
import '../models/job.dart';

/// Real API client using Dio with JWT authentication.
///
/// Implements all 13 frontend endpoints from workflow.md §6
/// (excludes internal #13 /jobs/{id}/callback endpoint).
///
/// Features:
/// - Automatic JWT Bearer token injection via interceptor
/// - 401 unauthorized error handling
/// - Request/response envelope unwrapping
class S3ApiClient implements ApiClient {
  final Dio _dio;
  final String _baseUrl;

  S3ApiClient({required String baseUrl, required String jwt})
      : _baseUrl = baseUrl,
        _dio = Dio(BaseOptions(baseURL: baseUrl)) {
    // Add JWT interceptor to all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $jwt';
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Handle token expiration (MVP: just log, v2: refresh token)
          print('Unauthorized: Token expired');
        }
        return handler.next(error);
      },
    ));
  }

  @override
  Future<Map<String, dynamic>> createAnonUser() async {
    final response = await _dio.post('/auth/anon');
    return response.data;
  }

  @override
  Future<User> getMe() async {
    final response = await _dio.get('/me');
    return User.fromJson(response.data);
  }

  @override
  Future<List<Preset>> getPresets() async {
    final response = await _dio.get('/presets');
    final List<dynamic> data = response.data;
    return data.map((json) => Preset.fromJson(json)).toList();
  }

  @override
  Future<Preset> getPresetById(String id) async {
    final response = await _dio.get('/presets/$id');
    return Preset.fromJson(response.data);
  }

  @override
  Future<String> createRule({
    required String name,
    required String presetId,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    final response = await _dio.post('/rules', data: {
      'name': name,
      'preset_id': presetId,
      'concepts': concepts.map((key, value) => MapEntry(key, value.toJson())),
      if (protect != null) 'protect': protect,
    });
    return response.data['id'];
  }

  @override
  Future<List<Rule>> getRules() async {
    final response = await _dio.get('/rules');
    final List<dynamic> data = response.data;
    return data.map((json) => Rule.fromJson(json)).toList();
  }

  @override
  Future<void> updateRule(
    String id, {
    required String name,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    await _dio.put('/rules/$id', data: {
      'name': name,
      'concepts': concepts.map((key, value) => MapEntry(key, value.toJson())),
      if (protect != null) 'protect': protect,
    });
  }

  @override
  Future<void> deleteRule(String id) async {
    await _dio.delete('/rules/$id');
  }

  @override
  Future<Map<String, dynamic>> createJob({
    required String preset,
    required int itemCount,
  }) async {
    final response = await _dio.post('/jobs', data: {
      'preset': preset,
      'item_count': itemCount,
    });
    return response.data;
  }

  @override
  Future<void> confirmUpload(String jobId) async {
    await _dio.post('/jobs/$jobId/confirm-upload');
  }

  @override
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
  }) async {
    await _dio.post('/jobs/$jobId/execute', data: {
      'concepts': concepts.map((key, value) => MapEntry(key, value.toJson())),
      if (protect != null) 'protect': protect,
      if (ruleId != null) 'rule_id': ruleId,
      if (outputTemplate != null) 'output_template': outputTemplate,
    });
  }

  @override
  Future<Job> getJob(String jobId) async {
    final response = await _dio.get('/jobs/$jobId');
    return Job.fromJson(response.data);
  }

  @override
  Future<void> cancelJob(String jobId) async {
    await _dio.post('/jobs/$jobId/cancel');
  }
}
