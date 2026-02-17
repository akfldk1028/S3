import '../../features/auth/models/user_model.dart';
import '../models/job.dart';
import '../models/job_item.dart';
import '../models/job_progress.dart';
import 'api_client.dart';

/// Mock implementation of [ApiClient] for development and testing.
///
/// Returns in-memory fixture data with simulated network delays.
/// Use this in ProviderScope overrides for widget tests or offline development.
class MockApiClient implements ApiClient {
  /// In-memory job store, keyed by jobId.
  final Map<String, Job> _jobs = {
    'job-001': const Job(
      jobId: 'job-001',
      status: 'done',
      preset: 'portrait',
      progress: JobProgress(done: 10, failed: 0, total: 10),
      outputsReady: [
        JobItem(
          idx: 0,
          resultUrl: 'https://example.com/results/job-001/0.jpg',
          previewUrl: 'https://picsum.photos/seed/job001/56/56',
        ),
      ],
      createdAt: '2026-02-15T10:30:00.000Z',
    ),
    'job-002': const Job(
      jobId: 'job-002',
      status: 'running',
      preset: 'landscape',
      progress: JobProgress(done: 4, failed: 0, total: 8),
      outputsReady: [],
      createdAt: '2026-02-16T08:15:00.000Z',
    ),
    'job-003': const Job(
      jobId: 'job-003',
      status: 'failed',
      preset: 'macro',
      progress: JobProgress(done: 0, failed: 3, total: 3),
      outputsReady: [],
      createdAt: '2026-02-14T14:45:00.000Z',
    ),
  };

  // ── Auth ─────────────────────────────────────────────────────────────────

  @override
  Future<LoginResponse> createAnonUser() async {
    await _simulateDelay();
    return const LoginResponse(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      user: User(id: 'anon-user-1', email: 'anon@example.com'),
    );
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    await _simulateDelay();
    return LoginResponse(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      user: User(id: 'user-1', email: email),
    );
  }

  // ── User ─────────────────────────────────────────────────────────────────

  @override
  Future<User> getMe() async {
    await _simulateDelay();
    return const User(id: 'user-1', email: 'test@example.com', name: 'Test User');
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────

  @override
  Future<Job> createJob(Map<String, dynamic> jobData) async {
    await _simulateDelay();
    final jobId = 'job-${DateTime.now().millisecondsSinceEpoch}';
    final newJob = Job(
      jobId: jobId,
      status: 'queued',
      preset: jobData['preset'] as String? ?? 'default',
      progress: const JobProgress(done: 0, failed: 0, total: 0),
      outputsReady: const [],
      createdAt: DateTime.now().toIso8601String(),
    );
    _jobs[jobId] = newJob;
    return newJob;
  }

  @override
  Future<void> confirmUpload(String jobId) async {
    await _simulateDelay();
  }

  @override
  Future<void> executeJob(String jobId) async {
    await _simulateDelay();
  }

  @override
  Future<Job> getJob(String jobId) async {
    await _simulateDelay();
    final job = _jobs[jobId];
    if (job == null) {
      throw Exception('Job not found: $jobId');
    }
    return job;
  }

  @override
  Future<List<Job>> listJobs() async {
    await _simulateDelay();
    // Return all jobs sorted by createdAt, newest first
    final sorted = List<Job>.from(_jobs.values)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<void> cancelJob(String jobId) async {
    await _simulateDelay();
    final job = _jobs[jobId];
    if (job != null) {
      _jobs[jobId] = job.copyWith(status: 'canceled');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _simulateDelay([int ms = 300]) async {
    await Future.delayed(Duration(milliseconds: ms));
  }
}
