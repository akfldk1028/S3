import '../../features/auth/models/user_model.dart';
import '../models/job.dart';
import '../models/preset.dart';
import '../models/rule.dart';
import 'api_client.dart';

/// Mock implementation of [ApiClient] for development and testing.
///
/// Returns in-memory fixture data with simulated network delays.
/// Use this in ProviderScope overrides for widget tests or offline development.
class MockApiClient implements ApiClient {
  /// In-memory job store, keyed by jobId.
  final Map<String, Job> _jobs = {
    'job-001': const Job(
      id: 'job-001',
      status: 'done',
      progress: 100,
    ),
    'job-002': const Job(
      id: 'job-002',
      status: 'running',
      progress: 50,
    ),
    'job-003': const Job(
      id: 'job-003',
      status: 'failed',
      errorMessage: 'GPU timeout',
      progress: 0,
    ),
  };

  /// In-memory rule store.
  final List<Rule> _rules = [];

  // ── Auth ─────────────────────────────────────────────────────────────────

  @override
  Future<LoginResponse> createAnonUser() async {
    await _simulateDelay();
    return const LoginResponse(
      userId: 'anon-user-1',
      token: 'mock-jwt-token',
    );
  }

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    await _simulateDelay();
    return const LoginResponse(
      userId: 'user-1',
      token: 'mock-jwt-token',
    );
  }

  // ── User ─────────────────────────────────────────────────────────────────

  @override
  Future<User> getMe() async {
    await _simulateDelay();
    return const User(id: 'user-1', credits: 10, ruleSlots: 0);
  }

  // ── Presets ──────────────────────────────────────────────────────────────

  @override
  Future<List<Preset>> getPresets() async {
    await _simulateDelay();
    return const [
      Preset(id: 'interior', name: 'Interior', conceptCount: 6),
      Preset(id: 'seller', name: 'Seller', conceptCount: 4),
    ];
  }

  @override
  Future<Preset> getPresetById(String presetId) async {
    await _simulateDelay();
    if (presetId == 'interior') {
      return const Preset(
        id: 'interior',
        name: 'Interior',
        conceptCount: 6,
        concepts: ['wall', 'floor', 'ceiling', 'furniture', 'window', 'door'],
        protectDefaults: ['window'],
      );
    }
    return const Preset(
      id: 'seller',
      name: 'Seller',
      conceptCount: 4,
      concepts: ['background', 'product', 'shadow', 'label'],
      protectDefaults: ['product'],
    );
  }

  // ── Rules ────────────────────────────────────────────────────────────────

  @override
  Future<List<Rule>> getRules() async {
    await _simulateDelay();
    return List.unmodifiable(_rules);
  }

  @override
  Future<Rule> createRule({
    required String name,
    required String presetId,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    await _simulateDelay();
    final rule = Rule(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      presetId: presetId,
      createdAt: DateTime.now().toIso8601String(),
      concepts: concepts,
      protect: protect,
    );
    _rules.add(rule);
    return rule;
  }

  @override
  Future<Rule> updateRule(
    String id, {
    required String name,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    await _simulateDelay();
    final idx = _rules.indexWhere((r) => r.id == id);
    if (idx < 0) throw Exception('Rule not found: $id');
    final updated = _rules[idx].copyWith(
      name: name,
      concepts: concepts,
      protect: protect,
    );
    _rules[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteRule(String id) async {
    await _simulateDelay();
    _rules.removeWhere((r) => r.id == id);
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────

  @override
  Future<Job> createJob(Map<String, dynamic> jobData) async {
    await _simulateDelay();
    final jobId = 'job-${DateTime.now().millisecondsSinceEpoch}';
    final newJob = Job(
      id: jobId,
      status: 'queued',
      progress: 0,
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
    return _jobs.values.toList();
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
