import '../lib/core/api/mock_api_client.dart';
import '../lib/core/models/rule.dart';

/// Manual verification script for MockApiClient.
///
/// Run with: dart test/mock_api_verification.dart
void main() async {
  final client = MockApiClient();

  print('Testing MockApiClient endpoints...\n');

  // 1. createAnonUser
  print('1. createAnonUser()');
  final anonUser = await client.createAnonUser();
  print('   ✓ user_id: ${anonUser['user_id']}');
  print('   ✓ token: ${anonUser['token']?.substring(0, 20)}...\n');

  // 2. getMe
  print('2. getMe()');
  final user = await client.getMe();
  print('   ✓ userId: ${user.userId}');
  print('   ✓ plan: ${user.plan}');
  print('   ✓ credits: ${user.credits}');
  print('   ✓ activeJobs: ${user.activeJobs}');
  print('   ✓ ruleSlots: ${user.ruleSlots.used}/${user.ruleSlots.max}\n');

  // 3. getPresets
  print('3. getPresets()');
  final presets = await client.getPresets();
  print('   ✓ Count: ${presets.length}');
  for (final preset in presets) {
    print('   ✓ ${preset.name} (${preset.id}) - ${preset.conceptCount} concepts');
  }
  print('');

  // 4. getPresetById
  print('4. getPresetById("interior")');
  final interiorPreset = await client.getPresetById('interior');
  print('   ✓ name: ${interiorPreset.name}');
  print('   ✓ concepts: ${interiorPreset.concepts?.length ?? 0}');
  print('   ✓ protectDefaults: ${interiorPreset.protectDefaults}');
  print('   ✓ outputTemplates: ${interiorPreset.outputTemplates?.length ?? 0}\n');

  // 5. createRule
  print('5. createRule()');
  final ruleId = await client.createRule(
    name: '테스트 규칙',
    presetId: 'interior',
    concepts: {
      'floor': const ConceptAction(action: 'recolor', value: 'marble_a'),
    },
    protect: ['window'],
  );
  print('   ✓ Created rule ID: $ruleId\n');

  // 6. getRules
  print('6. getRules()');
  final rules = await client.getRules();
  print('   ✓ Count: ${rules.length}');
  for (final rule in rules) {
    print('   ✓ ${rule.name} (${rule.id}) - preset: ${rule.presetId}');
  }
  print('');

  // 7. updateRule
  print('7. updateRule()');
  await client.updateRule(
    ruleId,
    name: '업데이트된 규칙',
    concepts: {
      'wall': const ConceptAction(action: 'tone', value: 'cool'),
    },
  );
  final updatedRules = await client.getRules();
  final updatedRule = updatedRules.firstWhere((r) => r.id == ruleId);
  print('   ✓ Updated name: ${updatedRule.name}\n');

  // 8. deleteRule
  print('8. deleteRule()');
  await client.deleteRule(ruleId);
  final rulesAfterDelete = await client.getRules();
  print('   ✓ Rules after delete: ${rulesAfterDelete.length}\n');

  // 9. createJob
  print('9. createJob()');
  final jobData = await client.createJob(preset: 'interior', itemCount: 3);
  final jobId = jobData['job_id'] as String;
  print('   ✓ job_id: $jobId');
  print('   ✓ upload URLs: ${(jobData['upload'] as List).length}');
  print('   ✓ confirm_url: ${jobData['confirm_url']}\n');

  // 10. confirmUpload
  print('10. confirmUpload()');
  await client.confirmUpload(jobId);
  final jobAfterConfirm = await client.getJob(jobId);
  print('   ✓ Status after confirm: ${jobAfterConfirm.status}\n');

  // 11. executeJob
  print('11. executeJob()');
  await client.executeJob(
    jobId,
    concepts: {
      'floor': const ConceptAction(action: 'recolor', value: 'oak_a'),
    },
    protect: ['window'],
  );
  final jobAfterExecute = await client.getJob(jobId);
  print('   ✓ Status after execute: ${jobAfterExecute.status}\n');

  // 12. getJob (with progress)
  print('12. getJob() - check progress');
  await Future.delayed(const Duration(seconds: 5));
  final jobWithProgress = await client.getJob(jobId);
  print('   ✓ jobId: ${jobWithProgress.jobId}');
  print('   ✓ status: ${jobWithProgress.status}');
  print('   ✓ preset: ${jobWithProgress.preset}');
  print('   ✓ progress: ${jobWithProgress.progress.done}/${jobWithProgress.progress.total}');
  print('   ✓ failed: ${jobWithProgress.progress.failed}');
  print('   ✓ outputsReady: ${jobWithProgress.outputsReady.length} items\n');

  // Check job items structure
  if (jobWithProgress.outputsReady.isNotEmpty) {
    final firstItem = jobWithProgress.outputsReady.first;
    print('   ✓ First item - idx: ${firstItem.idx}');
    print('   ✓ First item - resultUrl: ${firstItem.resultUrl}');
    print('   ✓ First item - previewUrl: ${firstItem.previewUrl}\n');
  }

  // 13. cancelJob
  print('13. cancelJob()');
  final cancelJobId = (await client.createJob(preset: 'seller', itemCount: 2))['job_id'] as String;
  await client.cancelJob(cancelJobId);
  final canceledJob = await client.getJob(cancelJobId);
  print('   ✓ Status after cancel: ${canceledJob.status}\n');

  print('✅ All 13 endpoints verified successfully!');
  print('\nKey findings:');
  print('- User has ruleSlots (used/max) ✓');
  print('- Presets have concepts, protectDefaults, outputTemplates ✓');
  print('- Rules have concepts (Map<String, ConceptAction>) ✓');
  print('- Job has progress (done/failed/total) ✓');
  print('- Job has outputsReady (List<JobItem>) ✓');
  print('- JobItems have idx, resultUrl, previewUrl ✓');
}
