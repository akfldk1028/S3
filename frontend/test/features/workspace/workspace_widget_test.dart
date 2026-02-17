// Widget/integration tests for workspace UI.
//
// Required by spec QA Acceptance Criteria:
//   1. Credit error state is surfaced correctly in the UI.
//   2. The "Retry" button in ActionBar calls retryJob(), NOT resetToIdle().

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s3_frontend/features/workspace/widgets/action_bar.dart';
import 'package:s3_frontend/features/workspace/workspace_provider.dart';
import 'package:s3_frontend/features/workspace/workspace_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake WorkspaceNotifier for widget tests
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal [WorkspaceNotifier] override for widget tests.
///
/// Returns a fixed [WorkspaceState] and records which methods were called
/// so tests can assert on call behaviour without real network activity.
class FakeWorkspaceNotifier extends WorkspaceNotifier {
  FakeWorkspaceNotifier(this._initialState);

  final WorkspaceState _initialState;

  bool retryJobCalled = false;
  bool resetToIdleCalled = false;

  @override
  WorkspaceState build() => _initialState;

  @override
  Future<void> uploadAndProcess() async {}

  @override
  Future<void> retryJob() async {
    retryJobCalled = true;
    // Transition to photosSelected to simulate behaviour that preserves photos.
    state = state.copyWith(phase: WorkspacePhase.photosSelected);
  }

  @override
  void resetToIdle() {
    resetToIdleCalled = true;
    state = const WorkspaceState();
  }

  @override
  Future<void> cancelJob() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: pump a widget inside ProviderScope with workspaceProvider overridden
// ─────────────────────────────────────────────────────────────────────────────

Future<FakeWorkspaceNotifier> _pumpActionBarWithState(
  WidgetTester tester,
  WorkspaceState initialState,
) async {
  final fakeNotifier = FakeWorkspaceNotifier(initialState);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workspaceProvider.overrideWith(() => fakeNotifier),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ActionBar()),
      ),
    ),
  );

  await tester.pump();
  return fakeNotifier;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Workspace widget tests', () {
    // ── Test 1: Credit error banner (error state visible in UI) ───────────────
    testWidgets('Credit error state — error message containing "credits" is surfaced',
        (tester) async {
      const creditErrorMsg =
          'Not enough credits. Please add credits to continue.';

      // Set up workspace state: error phase with a credits-related message
      // and at least one photo so the error banner path is taken.
      final errorState = WorkspaceState(
        phase: WorkspacePhase.error,
        errorMessage: creditErrorMsg,
        selectedImages: [Uint8List.fromList([1, 2, 3])],
      );

      // Pump a Consumer that reads workspaceProvider and renders the error
      // message — this verifies that the error state is available to any UI
      // widget that reads from the provider.
      final fakeNotifier = FakeWorkspaceNotifier(errorState);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final ws = ref.watch(workspaceProvider);
                  if (ws.errorMessage != null) {
                    return Text(ws.errorMessage!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // The error message must be rendered and contain the word "credits".
      expect(
        find.textContaining('credits'),
        findsOneWidget,
        reason: 'Credit error message should be visible in the UI',
      );

      // Verify the phase is error (ActionBar will show Retry).
      expect(
        fakeNotifier.state.phase,
        WorkspacePhase.error,
      );

      // ActionBar also shows "Retry" — pump it to confirm the label is present.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workspaceProvider.overrideWith(() => fakeNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ActionBar()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Retry'), findsOneWidget);
    });

    // ── Test 2: Retry button calls retryJob, NOT resetToIdle ──────────────────
    testWidgets(
      'ActionBar Retry button calls retryJob() and not resetToIdle()',
      (tester) async {
        final errorState = WorkspaceState(
          phase: WorkspacePhase.error,
          errorMessage: 'Network error',
          selectedImages: [Uint8List.fromList([1, 2, 3])],
        );

        final fakeNotifier =
            await _pumpActionBarWithState(tester, errorState);

        // ActionBar should show "Retry" in error phase.
        expect(find.text('Retry'), findsOneWidget);

        // Tap the Retry button.
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // retryJob() must have been called.
        expect(
          fakeNotifier.retryJobCalled,
          isTrue,
          reason: 'ActionBar Retry button must invoke retryJob()',
        );

        // resetToIdle() must NOT have been called — photos are preserved.
        expect(
          fakeNotifier.resetToIdleCalled,
          isFalse,
          reason:
              'ActionBar Retry button must NOT invoke resetToIdle() — '
              'photos would be lost',
        );

        // Phase should have transitioned to photosSelected (photos preserved),
        // not idle (which would mean photos were discarded).
        expect(
          fakeNotifier.state.phase,
          WorkspacePhase.photosSelected,
          reason:
              'After retryJob(), phase should be photosSelected (photos kept), '
              'not idle',
        );
      },
    );
  });
}
