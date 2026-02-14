import 'api_client.dart';
import '../models/user.dart';
import '../models/preset.dart';
import '../models/rule.dart';
import '../models/job.dart';
import '../models/job_progress.dart';
import '../models/job_item.dart';

/// Mock API client implementation for Phase 1 development.
///
/// Returns hardcoded data matching the API response structure from workflow.md §6.
/// All methods simulate 300ms network delay for realistic UI behavior.
class MockApiClient implements ApiClient {
  // In-memory storage for mock data
  final List<Rule> _rules = [
    Rule(
      id: 'rule-1',
      name: '따뜻한 톤 변경',
      presetId: 'interior',
      createdAt: '2026-02-01T10:00:00Z',
      concepts: {
        'floor': ConceptAction(action: 'recolor', value: 'oak_a'),
        'wall': ConceptAction(action: 'tone', value: 'warm'),
      },
      protect: ['window', 'door'],
    ),
    Rule(
      id: 'rule-2',
      name: '배경 제거',
      presetId: 'seller',
      createdAt: '2026-02-10T14:30:00Z',
      concepts: {
        'background': ConceptAction(action: 'remove'),
      },
      protect: [],
    ),
  ];

  final Map<String, Job> _jobs = {};
  int _ruleIdCounter = 3;
  int _jobIdCounter = 1;

  @override
  Future<Map<String, dynamic>> createAnonUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'user_id': 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      'token': 'mock-jwt-token-${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  @override
  Future<User> getMe() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const User(
      userId: 'mock-user-123',
      plan: 'free',
      credits: 1000,
      activeJobs: 1,
      ruleSlots: RuleSlots(used: 2, max: 2),
    );
  }

  @override
  Future<List<Preset>> getPresets() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const Preset(
        id: 'interior',
        name: '건축/인테리어',
        conceptCount: 12,
      ),
      const Preset(
        id: 'seller',
        name: '쇼핑/셀러',
        conceptCount: 6,
      ),
    ];
  }

  @override
  Future<Preset> getPresetById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (id == 'interior') {
      return const Preset(
        id: 'interior',
        name: '건축/인테리어',
        conceptCount: 12,
        concepts: [
          'floor',
          'wall',
          'ceiling',
          'window',
          'door',
          'furniture',
          'lighting',
          'curtain',
          'plant',
          'decoration',
          'floor_mat',
          'wall_art',
        ],
        protectDefaults: ['window', 'door'],
        outputTemplates: [
          OutputTemplate(
            id: 'hdr',
            name: 'HDR 보정',
            description: 'High Dynamic Range 색상 보정',
          ),
          OutputTemplate(
            id: 'natural',
            name: '자연광',
            description: '자연스러운 조명 효과',
          ),
        ],
      );
    } else if (id == 'seller') {
      return const Preset(
        id: 'seller',
        name: '쇼핑/셀러',
        conceptCount: 6,
        concepts: [
          'product',
          'background',
          'shadow',
          'lighting',
          'reflection',
          'packaging',
        ],
        protectDefaults: ['product'],
        outputTemplates: [
          OutputTemplate(
            id: 'white_bg',
            name: '흰색 배경',
            description: '깨끗한 흰색 배경',
          ),
          OutputTemplate(
            id: 'studio',
            name: '스튜디오 조명',
            description: '전문 스튜디오 조명 효과',
          ),
        ],
      );
    }

    throw Exception('Preset not found: $id');
  }

  @override
  Future<String> createRule({
    required String name,
    required String presetId,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final newRuleId = 'rule-$_ruleIdCounter';
    _ruleIdCounter++;

    _rules.add(Rule(
      id: newRuleId,
      name: name,
      presetId: presetId,
      createdAt: DateTime.now().toIso8601String(),
      concepts: concepts,
      protect: protect ?? [],
    ));

    return newRuleId;
  }

  @override
  Future<List<Rule>> getRules() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_rules);
  }

  @override
  Future<void> updateRule(
    String id, {
    required String name,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] = _rules[index].copyWith(
        name: name,
        concepts: concepts,
        protect: protect,
      );
    }
  }

  @override
  Future<void> deleteRule(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rules.removeWhere((r) => r.id == id);
  }

  @override
  Future<Map<String, dynamic>> createJob({
    required String preset,
    required int itemCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final jobId = 'mock-job-$_jobIdCounter';
    _jobIdCounter++;

    final uploadUrls = List.generate(
      itemCount,
      (idx) => {
        'idx': idx,
        'url': 'https://mock-r2.example.com/upload/$jobId/item-$idx',
        'key': 'jobs/$jobId/inputs/item-$idx.jpg',
      },
    );

    // Initialize job in created state
    _jobs[jobId] = Job(
      jobId: jobId,
      status: 'created',
      preset: preset,
      progress: JobProgress(done: 0, failed: 0, total: itemCount),
      outputsReady: const [],
    );

    return {
      'job_id': jobId,
      'upload': uploadUrls,
      'confirm_url': 'https://mock-api.example.com/jobs/$jobId/confirm-upload',
    };
  }

  @override
  Future<void> confirmUpload(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final job = _jobs[jobId];
    if (job != null) {
      _jobs[jobId] = job.copyWith(status: 'uploaded');
    }
  }

  @override
  Future<void> executeJob(
    String jobId, {
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
    String? outputTemplate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final job = _jobs[jobId];
    if (job != null) {
      _jobs[jobId] = job.copyWith(status: 'queued');

      // Simulate job progression
      _simulateJobProgress(jobId);
    }
  }

  @override
  Future<Job> getJob(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final job = _jobs[jobId];
    if (job != null) {
      return job;
    }

    // Return a default mock job if not found
    return Job(
      jobId: jobId,
      status: 'running',
      preset: 'interior',
      progress: const JobProgress(done: 5, failed: 0, total: 10),
      outputsReady: [
        JobItem(
          idx: 0,
          resultUrl: 'https://mock-r2.example.com/results/$jobId/item-0-result.jpg',
          previewUrl: 'https://mock-r2.example.com/results/$jobId/item-0-preview.jpg',
        ),
        JobItem(
          idx: 1,
          resultUrl: 'https://mock-r2.example.com/results/$jobId/item-1-result.jpg',
          previewUrl: 'https://mock-r2.example.com/results/$jobId/item-1-preview.jpg',
        ),
        JobItem(
          idx: 2,
          resultUrl: 'https://mock-r2.example.com/results/$jobId/item-2-result.jpg',
          previewUrl: 'https://mock-r2.example.com/results/$jobId/item-2-preview.jpg',
        ),
        JobItem(
          idx: 3,
          resultUrl: 'https://mock-r2.example.com/results/$jobId/item-3-result.jpg',
          previewUrl: 'https://mock-r2.example.com/results/$jobId/item-3-preview.jpg',
        ),
        JobItem(
          idx: 4,
          resultUrl: 'https://mock-r2.example.com/results/$jobId/item-4-result.jpg',
          previewUrl: 'https://mock-r2.example.com/results/$jobId/item-4-preview.jpg',
        ),
      ],
    );
  }

  @override
  Future<void> cancelJob(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final job = _jobs[jobId];
    if (job != null) {
      _jobs[jobId] = job.copyWith(status: 'canceled');
    }
  }

  /// Simulate job progression over time (for demo purposes)
  void _simulateJobProgress(String jobId) async {
    final job = _jobs[jobId];
    if (job == null) return;

    final totalItems = job.progress.total;
    final outputs = <JobItem>[];

    // Simulate processing stages
    await Future.delayed(const Duration(seconds: 1));
    _jobs[jobId] = job.copyWith(status: 'running');

    // Simulate incremental progress
    for (int i = 0; i < totalItems; i++) {
      await Future.delayed(const Duration(seconds: 3));

      outputs.add(JobItem(
        idx: i,
        resultUrl: 'https://mock-r2.example.com/results/$jobId/item-$i-result.jpg',
        previewUrl: 'https://mock-r2.example.com/results/$jobId/item-$i-preview.jpg',
      ));

      _jobs[jobId] = _jobs[jobId]!.copyWith(
        progress: JobProgress(done: i + 1, failed: 0, total: totalItems),
        outputsReady: List.from(outputs),
      );
    }

    // Mark as complete
    await Future.delayed(const Duration(seconds: 1));
    _jobs[jobId] = _jobs[jobId]!.copyWith(status: 'done');
  }
}
