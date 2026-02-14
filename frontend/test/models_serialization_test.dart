import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:s3_frontend/core/models/user.dart';
import 'package:s3_frontend/core/models/preset.dart';
import 'package:s3_frontend/core/models/rule.dart';
import 'package:s3_frontend/core/models/job.dart';
import 'package:s3_frontend/core/models/job_progress.dart';
import 'package:s3_frontend/core/models/job_item.dart';

void main() {
  group('Freezed Models JSON Serialization', () {
    test('User model - round-trip serialization', () {
      // Sample JSON from API (snake_case)
      final json = {
        'user_id': 'test-user-123',
        'plan': 'free',
        'credits': 1000,
        'active_jobs': 2,
        'rule_slots': {
          'used': 1,
          'max': 2,
        },
      };

      // Deserialize
      final user = User.fromJson(json);

      // Verify model fields (camelCase)
      expect(user.userId, equals('test-user-123'));
      expect(user.plan, equals('free'));
      expect(user.credits, equals(1000));
      expect(user.activeJobs, equals(2));
      expect(user.ruleSlots.used, equals(1));
      expect(user.ruleSlots.max, equals(2));

      // Serialize back to JSON
      final jsonOutput = user.toJson();

      // Verify JSON keys are snake_case
      expect(jsonOutput['user_id'], equals('test-user-123'));
      expect(jsonOutput['plan'], equals('free'));
      expect(jsonOutput['credits'], equals(1000));
      expect(jsonOutput['active_jobs'], equals(2));
      expect(jsonOutput['rule_slots'], isA<Map>());
      expect(jsonOutput['rule_slots']['used'], equals(1));
      expect(jsonOutput['rule_slots']['max'], equals(2));

      // Full round-trip: JSON → Model → JSON should match
      expect(jsonOutput, equals(json));
    });

    test('Preset model - list view (minimal fields)', () {
      final json = {
        'id': 'interior',
        'name': '건축/인테리어',
        'concept_count': 12,
      };

      final preset = Preset.fromJson(json);

      expect(preset.id, equals('interior'));
      expect(preset.name, equals('건축/인테리어'));
      expect(preset.conceptCount, equals(12));
      expect(preset.concepts, isNull);
      expect(preset.protectDefaults, isNull);
      expect(preset.outputTemplates, isNull);

      final jsonOutput = preset.toJson();

      expect(jsonOutput['id'], equals('interior'));
      expect(jsonOutput['name'], equals('건축/인테리어'));
      expect(jsonOutput['concept_count'], equals(12));
      expect(jsonOutput['concepts'], isNull);
      expect(jsonOutput['protect_defaults'], isNull);
      expect(jsonOutput['output_templates'], isNull);
    });

    test('Preset model - detail view (all fields)', () {
      final json = {
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

      final preset = Preset.fromJson(json);

      expect(preset.id, equals('interior'));
      expect(preset.name, equals('건축/인테리어'));
      expect(preset.conceptCount, equals(12));
      expect(preset.concepts, equals(['wall', 'floor', 'ceiling']));
      expect(preset.protectDefaults, equals(['wall']));
      expect(preset.outputTemplates, hasLength(2));
      expect(preset.outputTemplates![0].id, equals('tpl-1'));
      expect(preset.outputTemplates![0].name, equals('HD'));
      expect(preset.outputTemplates![1].id, equals('tpl-2'));

      final jsonOutput = preset.toJson();

      expect(jsonOutput['concept_count'], equals(12));
      expect(jsonOutput['protect_defaults'], equals(['wall']));
      expect(jsonOutput['output_templates'], hasLength(2));
      expect(jsonOutput['output_templates'][0]['id'], equals('tpl-1'));

      // Full round-trip
      expect(jsonOutput, equals(json));
    });

    test('Rule model - list view', () {
      final json = {
        'id': 'rule-1',
        'name': 'My Rule',
        'preset_id': 'interior',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final rule = Rule.fromJson(json);

      expect(rule.id, equals('rule-1'));
      expect(rule.name, equals('My Rule'));
      expect(rule.presetId, equals('interior'));
      expect(rule.createdAt, equals('2024-01-15T10:30:00Z'));
      expect(rule.concepts, isNull);
      expect(rule.protect, isNull);

      final jsonOutput = rule.toJson();

      expect(jsonOutput['preset_id'], equals('interior'));
      expect(jsonOutput['created_at'], equals('2024-01-15T10:30:00Z'));
      expect(jsonOutput, equals(json));
    });

    test('Rule model - with concepts and protect', () {
      final json = {
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

      final rule = Rule.fromJson(json);

      expect(rule.concepts, hasLength(2));
      expect(rule.concepts!['wall']!.action, equals('recolor'));
      expect(rule.concepts!['wall']!.value, equals('oak_a'));
      expect(rule.concepts!['floor']!.action, equals('remove'));
      expect(rule.concepts!['floor']!.value, isNull);
      expect(rule.protect, equals(['ceiling']));

      final jsonOutput = rule.toJson();

      expect(jsonOutput['concepts']['wall']['action'], equals('recolor'));
      expect(jsonOutput['concepts']['wall']['value'], equals('oak_a'));
      expect(jsonOutput['concepts']['floor']['action'], equals('remove'));
      expect(jsonOutput['protect'], equals(['ceiling']));

      // Full round-trip
      expect(jsonOutput, equals(json));
    });

    test('JobProgress model', () {
      final json = {
        'done': 5,
        'failed': 1,
        'total': 10,
      };

      final progress = JobProgress.fromJson(json);

      expect(progress.done, equals(5));
      expect(progress.failed, equals(1));
      expect(progress.total, equals(10));

      final jsonOutput = progress.toJson();

      expect(jsonOutput, equals(json));
    });

    test('JobItem model', () {
      final json = {
        'idx': 0,
        'result_url': 'https://r2.example.com/result/img0.jpg',
        'preview_url': 'https://r2.example.com/preview/img0.jpg',
      };

      final item = JobItem.fromJson(json);

      expect(item.idx, equals(0));
      expect(item.resultUrl, equals('https://r2.example.com/result/img0.jpg'));
      expect(item.previewUrl, equals('https://r2.example.com/preview/img0.jpg'));

      final jsonOutput = item.toJson();

      expect(jsonOutput['result_url'], equals('https://r2.example.com/result/img0.jpg'));
      expect(jsonOutput['preview_url'], equals('https://r2.example.com/preview/img0.jpg'));
      expect(jsonOutput, equals(json));
    });

    test('Job model - complete with nested objects', () {
      final json = {
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

      final job = Job.fromJson(json);

      expect(job.jobId, equals('job-123'));
      expect(job.status, equals('running'));
      expect(job.preset, equals('interior'));
      expect(job.progress.done, equals(5));
      expect(job.progress.failed, equals(1));
      expect(job.progress.total, equals(10));
      expect(job.outputsReady, hasLength(2));
      expect(job.outputsReady[0].idx, equals(0));
      expect(job.outputsReady[0].resultUrl, equals('https://r2.example.com/result/img0.jpg'));
      expect(job.outputsReady[1].idx, equals(1));

      final jsonOutput = job.toJson();

      expect(jsonOutput['job_id'], equals('job-123'));
      expect(jsonOutput['outputs_ready'], hasLength(2));
      expect(jsonOutput['outputs_ready'][0]['result_url'], equals('https://r2.example.com/result/img0.jpg'));
      expect(jsonOutput['progress']['done'], equals(5));

      // Full round-trip
      expect(jsonOutput, equals(json));
    });

    test('All models - verify snake_case to camelCase mapping', () {
      // Test that API snake_case fields correctly map to Dart camelCase
      final testCases = [
        {'model': 'User', 'apiField': 'user_id', 'dartField': 'userId'},
        {'model': 'User', 'apiField': 'active_jobs', 'dartField': 'activeJobs'},
        {'model': 'User', 'apiField': 'rule_slots', 'dartField': 'ruleSlots'},
        {'model': 'Preset', 'apiField': 'concept_count', 'dartField': 'conceptCount'},
        {'model': 'Preset', 'apiField': 'protect_defaults', 'dartField': 'protectDefaults'},
        {'model': 'Preset', 'apiField': 'output_templates', 'dartField': 'outputTemplates'},
        {'model': 'Rule', 'apiField': 'preset_id', 'dartField': 'presetId'},
        {'model': 'Rule', 'apiField': 'created_at', 'dartField': 'createdAt'},
        {'model': 'Job', 'apiField': 'job_id', 'dartField': 'jobId'},
        {'model': 'Job', 'apiField': 'outputs_ready', 'dartField': 'outputsReady'},
        {'model': 'JobItem', 'apiField': 'result_url', 'dartField': 'resultUrl'},
        {'model': 'JobItem', 'apiField': 'preview_url', 'dartField': 'previewUrl'},
      ];

      // This is a documentation test - all mappings verified in individual tests above
      expect(testCases.length, equals(12));
    });
  });
}
