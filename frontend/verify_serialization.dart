import 'dart:convert';
import 'lib/core/models/user.dart';
import 'lib/core/models/preset.dart';
import 'lib/core/models/rule.dart';
import 'lib/core/models/job.dart';
import 'lib/core/models/job_progress.dart';
import 'lib/core/models/job_item.dart';

void main() {
  print('=== JSON Round-Trip Serialization Verification ===\n');

  bool allPassed = true;

  // Test 1: User model
  try {
    print('1. Testing User model...');
    final userJson = {
      'user_id': 'test-user-123',
      'plan': 'free',
      'credits': 1000,
      'active_jobs': 2,
      'rule_slots': {
        'used': 1,
        'max': 2,
      },
    };

    final user = User.fromJson(userJson);
    final userOutput = user.toJson();

    assert(userOutput['user_id'] == 'test-user-123');
    assert(userOutput['plan'] == 'free');
    assert(userOutput['credits'] == 1000);
    assert(userOutput['active_jobs'] == 2);
    assert(userOutput['rule_slots']['used'] == 1);
    assert(userOutput['rule_slots']['max'] == 2);

    print('   ✓ User model: PASSED');
    print('     - user_id → userId: ${user.userId}');
    print('     - active_jobs → activeJobs: ${user.activeJobs}');
    print('     - rule_slots → ruleSlots: ${user.ruleSlots}');
  } catch (e) {
    print('   ✗ User model: FAILED - $e');
    allPassed = false;
  }

  // Test 2: Preset model (list view)
  try {
    print('\n2. Testing Preset model (list view)...');
    final presetJson = {
      'id': 'interior',
      'name': '건축/인테리어',
      'concept_count': 12,
    };

    final preset = Preset.fromJson(presetJson);
    final presetOutput = preset.toJson();

    assert(presetOutput['id'] == 'interior');
    assert(presetOutput['name'] == '건축/인테리어');
    assert(presetOutput['concept_count'] == 12);

    print('   ✓ Preset (list): PASSED');
    print('     - concept_count → conceptCount: ${preset.conceptCount}');
  } catch (e) {
    print('   ✗ Preset (list): FAILED - $e');
    allPassed = false;
  }

  // Test 3: Preset model (detail view)
  try {
    print('\n3. Testing Preset model (detail view)...');
    final presetDetailJson = {
      'id': 'interior',
      'name': '건축/인테리어',
      'concept_count': 12,
      'concepts': ['wall', 'floor', 'ceiling'],
      'protect_defaults': ['wall'],
      'output_templates': [
        {'id': 'tpl-1', 'name': 'HD', 'description': 'High resolution'},
        {'id': 'tpl-2', 'name': 'Preview', 'description': 'Low resolution'},
      ],
    };

    final preset = Preset.fromJson(presetDetailJson);
    final presetOutput = preset.toJson();

    assert(presetOutput['protect_defaults']?.length == 1);
    assert(presetOutput['output_templates']?.length == 2);

    print('   ✓ Preset (detail): PASSED');
    print('     - protect_defaults → protectDefaults: ${preset.protectDefaults}');
    print('     - output_templates → outputTemplates: ${preset.outputTemplates?.length} items');
  } catch (e) {
    print('   ✗ Preset (detail): FAILED - $e');
    allPassed = false;
  }

  // Test 4: Rule model
  try {
    print('\n4. Testing Rule model...');
    final ruleJson = {
      'id': 'rule-1',
      'name': 'My Rule',
      'preset_id': 'interior',
      'created_at': '2024-01-15T10:30:00Z',
      'concepts': {
        'wall': {'action': 'recolor', 'value': 'oak_a'},
        'floor': {'action': 'remove'},
      },
      'protect': ['ceiling'],
    };

    final rule = Rule.fromJson(ruleJson);
    final ruleOutput = rule.toJson();

    assert(ruleOutput['preset_id'] == 'interior');
    assert(ruleOutput['created_at'] == '2024-01-15T10:30:00Z');
    assert(ruleOutput['concepts']['wall']['action'] == 'recolor');
    assert(ruleOutput['protect']?.length == 1);

    print('   ✓ Rule model: PASSED');
    print('     - preset_id → presetId: ${rule.presetId}');
    print('     - created_at → createdAt: ${rule.createdAt}');
    print('     - concepts: ${rule.concepts?.keys.join(', ')}');
  } catch (e) {
    print('   ✗ Rule model: FAILED - $e');
    allPassed = false;
  }

  // Test 5: JobProgress model
  try {
    print('\n5. Testing JobProgress model...');
    final progressJson = {
      'done': 5,
      'failed': 1,
      'total': 10,
    };

    final progress = JobProgress.fromJson(progressJson);
    final progressOutput = progress.toJson();

    assert(progressOutput['done'] == 5);
    assert(progressOutput['failed'] == 1);
    assert(progressOutput['total'] == 10);

    print('   ✓ JobProgress model: PASSED');
    print('     - done: ${progress.done}, failed: ${progress.failed}, total: ${progress.total}');
  } catch (e) {
    print('   ✗ JobProgress model: FAILED - $e');
    allPassed = false;
  }

  // Test 6: JobItem model
  try {
    print('\n6. Testing JobItem model...');
    final itemJson = {
      'idx': 0,
      'result_url': 'https://r2.example.com/result/img0.jpg',
      'preview_url': 'https://r2.example.com/preview/img0.jpg',
    };

    final item = JobItem.fromJson(itemJson);
    final itemOutput = item.toJson();

    assert(itemOutput['idx'] == 0);
    assert(itemOutput['result_url'] == 'https://r2.example.com/result/img0.jpg');
    assert(itemOutput['preview_url'] == 'https://r2.example.com/preview/img0.jpg');

    print('   ✓ JobItem model: PASSED');
    print('     - result_url → resultUrl: ${item.resultUrl}');
    print('     - preview_url → previewUrl: ${item.previewUrl}');
  } catch (e) {
    print('   ✗ JobItem model: FAILED - $e');
    allPassed = false;
  }

  // Test 7: Job model (with nested objects)
  try {
    print('\n7. Testing Job model (with nested objects)...');
    final jobJson = {
      'job_id': 'job-123',
      'status': 'running',
      'preset': 'interior',
      'progress': {
        'done': 5,
        'failed': 1,
        'total': 10,
      },
      'outputs_ready': [
        {
          'idx': 0,
          'result_url': 'https://r2.example.com/result/img0.jpg',
          'preview_url': 'https://r2.example.com/preview/img0.jpg',
        },
        {
          'idx': 1,
          'result_url': 'https://r2.example.com/result/img1.jpg',
          'preview_url': 'https://r2.example.com/preview/img1.jpg',
        },
      ],
    };

    final job = Job.fromJson(jobJson);
    final jobOutput = job.toJson();

    assert(jobOutput['job_id'] == 'job-123');
    assert(jobOutput['status'] == 'running');
    assert(jobOutput['preset'] == 'interior');
    assert(jobOutput['progress']['done'] == 5);
    assert(jobOutput['outputs_ready'].length == 2);

    print('   ✓ Job model: PASSED');
    print('     - job_id → jobId: ${job.jobId}');
    print('     - outputs_ready → outputsReady: ${job.outputsReady.length} items');
    print('     - Nested progress: ${job.progress.done}/${job.progress.total} (${job.progress.failed} failed)');
  } catch (e) {
    print('   ✗ Job model: FAILED - $e');
    allPassed = false;
  }

  print('\n' + '=' * 50);
  if (allPassed) {
    print('✓ ALL TESTS PASSED');
    print('\nAll 6 models successfully serialize and deserialize!');
    print('Snake_case API fields correctly map to camelCase Dart fields.');
  } else {
    print('✗ SOME TESTS FAILED');
    print('\nPlease review the errors above.');
  }
  print('=' * 50);
}
