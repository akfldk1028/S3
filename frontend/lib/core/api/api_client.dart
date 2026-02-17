import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/user_model.dart';
import '../models/job.dart';

/// Abstract API client interface.
///
/// Defines all communication with the S3 Workers REST API.
/// Concrete implementations: [S3ApiClient] (production), [MockApiClient] (testing/dev).
abstract class ApiClient {
  /// 1. POST /auth/anon - Create anonymous user + JWT
  Future<LoginResponse> createAnonUser();

  /// 2. POST /auth/login - Email/password login
  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  /// 3. GET /me - Get user status (credits, plan, rule_slots)
  Future<User> getMe();

  /// 10. POST /jobs - Create job + presigned URLs
  Future<Job> createJob(Map<String, dynamic> jobData);

  /// 11. POST /jobs/:id/confirm-upload - Confirm upload complete
  Future<void> confirmUpload(String jobId);

  /// 12. POST /jobs/:id/execute - Execute rule application (Queue push)
  Future<void> executeJob(String jobId);

  /// 13. GET /jobs/:id - Get job status/progress
  Future<Job> getJob(String jobId);

  /// 13.5. GET /jobs - List all user jobs ordered by created_at DESC
  Future<List<Job>> listJobs();

  /// 14. POST /jobs/:id/cancel - Cancel job + refund credits
  Future<void> cancelJob(String jobId);
}

/// Riverpod provider for the [ApiClient].
///
/// Override this provider in tests or feature flags to swap implementations.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden before use. '
    'Override with S3ApiClient or MockApiClient in ProviderScope.',
  );
});
