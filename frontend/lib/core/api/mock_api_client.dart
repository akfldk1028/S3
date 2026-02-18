import '../../core/models/job.dart';
import 'api_client.dart';

/// In-memory stub implementation of [ApiClient] for unit testing.
///
/// All methods return successful results by default. Override individual
/// responses by subclassing or using the callback fields.
///
/// The [executeJob] signature includes [prompts] to stay in sync with the
/// abstract [ApiClient] interface and [S3ApiClient] — the parameter is
/// accepted but not used in the stub.
class MockApiClient implements ApiClient {
  /// Tracks how many times [createJob] was called.
  int createJobCallCount = 0;

  /// Tracks how many times [executeJob] was called.
  int executeJobCallCount = 0;

  /// The last prompts value passed to [executeJob], for assertion in tests.
  List<String>? lastExecuteJobPrompts;

  /// Configurable stub response for [createJob].
  String stubJobId = 'mock-job-id';
  List<String> stubUploadUrls = ['https://example.com/upload/1'];

  /// Configurable stub response for [pollJob].
  Job stubJob = const Job(id: 'mock-job-id', status: 'completed');

  @override
  Future<({String jobId, List<String> uploadUrls})> createJob({
    required int imageCount,
    required String presetId,
  }) async {
    createJobCallCount++;
    return (jobId: stubJobId, uploadUrls: stubUploadUrls);
  }

  @override
  Future<void> uploadFile(String url, List<int> bytes) async {
    // No-op stub — upload succeeds immediately.
  }

  @override
  Future<void> confirmUpload(String jobId) async {
    // No-op stub — confirmation succeeds immediately.
  }

  @override
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
    List<String>? prompts,
  }) async {
    executeJobCallCount++;
    lastExecuteJobPrompts = prompts;
    // No-op stub — execution succeeds immediately.
  }

  @override
  Future<Job> pollJob(String jobId) async {
    return stubJob;
  }

  @override
  Future<void> cancelJob(String jobId) async {
    // No-op stub — cancellation succeeds immediately.
  }
}
