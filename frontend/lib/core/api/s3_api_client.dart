import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../constants/api_endpoints.dart';
import '../../core/models/job.dart';
import 'api_client.dart';

/// Real Dio-based HTTP client for the S3 Workers REST API.
///
/// Automatically attaches the JWT access token (stored in [FlutterSecureStorage])
/// to every request via an [InterceptorsWrapper].
///
/// File uploads to presigned S3 URLs use a separate Dio instance without the
/// auth interceptor, because S3 presigned URLs are self-authenticating.
class S3ApiClient implements ApiClient {
  final Dio _dio;

  /// A plain Dio instance used exclusively for presigned S3 uploads.
  /// Authorization headers must NOT be sent to S3.
  final Dio _s3Dio;

  S3ApiClient({
    required FlutterSecureStorage secureStorage,
  })  : _dio = _buildDio(secureStorage),
        _s3Dio = Dio();

  static Dio _buildDio(FlutterSecureStorage secureStorage) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

    return dio;
  }

  /// POST /jobs — creates a new processing job and returns the job ID
  /// and presigned upload URLs.
  @override
  Future<({String jobId, List<String> uploadUrls})> createJob({
    required int imageCount,
    required String presetId,
  }) async {
    final response = await _dio.post(ApiEndpoints.jobs, data: {
      'image_count': imageCount,
      'preset_id': presetId,
    });
    final data = response.data as Map<String, dynamic>;
    return (
      jobId: data['job_id'] as String,
      uploadUrls: List<String>.from(data['upload_urls'] as List),
    );
  }

  /// Uploads a single image byte buffer to the given presigned S3 URL.
  ///
  /// Uses a plain Dio instance — S3 presigned URLs must not receive an
  /// Authorization header (it would invalidate the presigned signature).
  @override
  Future<void> uploadFile(String url, List<int> bytes) async {
    await _s3Dio.put(
      url,
      data: Stream.fromIterable(bytes.map((b) => [b])),
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length,
        },
        followRedirects: false,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
  }

  /// POST /jobs/{id}/confirm-upload — signals that all images are uploaded.
  @override
  Future<void> confirmUpload(String jobId) async {
    await _dio.post(ApiEndpoints.confirmUpload(jobId));
  }

  /// POST /jobs/{id}/execute — triggers processing with the given concept actions.
  ///
  /// The [prompts] list is conditionally included in the request body only when
  /// it is non-null and non-empty, so the `prompts` key is omitted entirely for
  /// jobs that have no custom SAM3 prompts.
  @override
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
    List<String>? prompts,
  }) async {
    await _dio.post(ApiEndpoints.execute(jobId), data: {
      'concepts': concepts.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      if (protect != null) 'protect': protect,
      if (ruleId != null) 'rule_id': ruleId,
      if (outputTemplate != null) 'output_template': outputTemplate,
      if (prompts != null && prompts.isNotEmpty) 'prompts': prompts,
    });
  }

  /// GET /jobs/{id} — polls the current status and progress of a job.
  @override
  Future<Job> pollJob(String jobId) async {
    final response = await _dio.get(ApiEndpoints.jobById(jobId));
    return Job.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /jobs/{id}/cancel — cancels a running job and refunds credits.
  @override
  Future<void> cancelJob(String jobId) async {
    await _dio.post(ApiEndpoints.cancel(jobId));
  }
}
