// Widget tests for MobilePipelineTabs, ProBadge, and PlanComparisonSheet.
//
// These tests cover the QA Acceptance Criteria:
//   - ProBadge renders gradient diamond when showBadge: true
//   - ProBadge renders child only when showBadge: false
//   - PlanComparisonSheet shows Free/Pro headers and feature rows
//   - MobilePipelineTabs renders all 4 tab labels on mobile viewport

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s3_frontend/features/auth/models/user_model.dart';
import 'package:s3_frontend/features/auth/queries/get_me_query.dart';
import 'package:s3_frontend/features/workspace/widgets/mobile_pipeline_tabs.dart';
import 'package:s3_frontend/features/workspace/workspace_provider.dart';
import 'package:s3_frontend/features/workspace/workspace_state.dart';

// ---------------------------------------------------------------------------
// Test workspace notifier — returns a state with photos so the widget renders.
// ---------------------------------------------------------------------------
class _TestWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => WorkspaceState(
        phase: WorkspacePhase.photosSelected,
        selectedImages: [Uint8List.fromList(const [0])],
      );
}

// Fake free-plan user returned by the getMeQuery override in tests.
const _fakeUser = User(
  id: 'test-user',
  email: 'test@example.com',
  plan: 'free',
  ruleSlotsUsed: 0,
  ruleSlotsMax: 2,
);

void main() {
  // ────────────────────────────────────────────────────────────────────────
  // ProBadge tests
  // ────────────────────────────────────────────────────────────────────────

  group('ProBadge', () {
    testWidgets('shows diamond badge when showBadge is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProBadge(showBadge: true, child: Text('child')),
          ),
        ),
      );
      // _ProDiamondBadge renders 'PRO' text inside the gradient diamond.
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('renders child only when showBadge is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProBadge(showBadge: false, child: Text('child')),
          ),
        ),
      );
      // No badge text should appear.
      expect(find.text('PRO'), findsNothing);
      // The wrapped child is still present.
      expect(find.text('child'), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // PlanComparisonSheet tests
  // ────────────────────────────────────────────────────────────────────────

  group('PlanComparisonSheet', () {
    testWidgets('shows Free and Pro column headers and feature rows',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PlanComparisonSheet()),
        ),
      );

      // Header columns
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);

      // Feature rows from the comparison table
      expect(find.text('Rule Slots'), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────────────
  // MobilePipelineTabs tests
  // ────────────────────────────────────────────────────────────────────────

  group('MobilePipelineTabs', () {
    testWidgets('renders all 4 tab labels', (tester) async {
      // Set a mobile viewport (< 768 px wide) so the desktop guard is bypassed.
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override workspace provider to simulate photos selected.
            workspaceProvider.overrideWith(_TestWorkspaceNotifier.new),
            // Override the underlying API query to avoid real HTTP requests.
            // This resolves userProvider without creating any timers.
            getMeQueryProvider.overrideWith((ref) => _fakeUser),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MobilePipelineTabs()),
          ),
        ),
      );

      // Allow async providers to settle.
      await tester.pump();

      // All 4 tab labels must be present in the tab strip.
      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Instances'), findsOneWidget);
      expect(find.text('Protect'), findsOneWidget);
      expect(find.text('Rules'), findsOneWidget);
    });
  });
}
