import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s3_frontend/features/workspace/workspace_provider.dart';

void main() {
  group('Workspace prompt management', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ── addPrompt ────────────────────────────────────────────────────────────

    test('addPrompt adds a prompt to an empty list', () {
      container.read(workspaceProvider.notifier).addPrompt('wall');
      expect(container.read(workspaceProvider).customPrompts, ['wall']);
    });

    test('addPrompt trims whitespace before storing', () {
      container.read(workspaceProvider.notifier).addPrompt('  floor  ');
      expect(container.read(workspaceProvider).customPrompts, ['floor']);
    });

    test('addPrompt ignores whitespace-only strings', () {
      container.read(workspaceProvider.notifier).addPrompt('   ');
      expect(container.read(workspaceProvider).customPrompts, isEmpty);
    });

    test('addPrompt ignores exact duplicates (case-sensitive)', () {
      container.read(workspaceProvider.notifier).addPrompt('wall');
      container.read(workspaceProvider.notifier).addPrompt('wall');
      expect(container.read(workspaceProvider).customPrompts.length, 1);
    });

    // ── removePrompt ─────────────────────────────────────────────────────────

    test('removePrompt removes an existing prompt from the list', () {
      container.read(workspaceProvider.notifier).addPrompt('wall');
      container.read(workspaceProvider.notifier).removePrompt('wall');
      expect(container.read(workspaceProvider).customPrompts, isEmpty);
    });

    test('removePrompt is a no-op when prompt is not present', () {
      container.read(workspaceProvider.notifier).addPrompt('wall');
      container.read(workspaceProvider.notifier).removePrompt('floor');
      expect(container.read(workspaceProvider).customPrompts, ['wall']);
    });
  });
}
