// History feature widget tests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s3_frontend/core/api/api_client.dart';
import 'package:s3_frontend/core/api/mock_api_client.dart';
import 'package:s3_frontend/core/models/job.dart';
import 'package:s3_frontend/core/models/job_progress.dart';
import 'package:s3_frontend/features/history/widgets/status_badge.dart';
import 'package:s3_frontend/features/history/widgets/history_empty_state.dart';
import 'package:s3_frontend/features/history/history_screen.dart';
import 'package:s3_frontend/features/workspace/theme.dart';

void main() {
  // ─── StatusBadge color mapping tests ─────────────────────────────────────

  group('StatusBadge', () {
    Widget buildBadge(String status) {
      return MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: status),
        ),
      );
    }

    testWidgets('renders "DONE" text for done status', (tester) async {
      await tester.pumpWidget(buildBadge('done'));
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('renders "FAILED" text for failed status', (tester) async {
      await tester.pumpWidget(buildBadge('failed'));
      expect(find.text('FAILED'), findsOneWidget);
    });

    testWidgets('renders "RUNNING" text for running status', (tester) async {
      await tester.pumpWidget(buildBadge('running'));
      expect(find.text('RUNNING'), findsOneWidget);
    });

    testWidgets('renders "QUEUED" text for queued status', (tester) async {
      await tester.pumpWidget(buildBadge('queued'));
      expect(find.text('QUEUED'), findsOneWidget);
    });

    testWidgets('renders "CANCELED" text for canceled status', (tester) async {
      await tester.pumpWidget(buildBadge('canceled'));
      expect(find.text('CANCELED'), findsOneWidget);
    });

    testWidgets('done status uses success color', (tester) async {
      await tester.pumpWidget(buildBadge('done'));
      final text = tester.widget<Text>(find.text('DONE'));
      expect(text.style?.color, equals(WsColors.success));
    });

    testWidgets('failed status uses error color', (tester) async {
      await tester.pumpWidget(buildBadge('failed'));
      final text = tester.widget<Text>(find.text('FAILED'));
      expect(text.style?.color, equals(WsColors.error));
    });

    testWidgets('running status uses accent1 color', (tester) async {
      await tester.pumpWidget(buildBadge('running'));
      final text = tester.widget<Text>(find.text('RUNNING'));
      expect(text.style?.color, equals(WsColors.accent1));
    });

    testWidgets('unknown status uses textMuted color', (tester) async {
      await tester.pumpWidget(buildBadge('pending'));
      final text = tester.widget<Text>(find.text('PENDING'));
      expect(text.style?.color, equals(WsColors.textMuted));
    });
  });

  // ─── HistoryEmptyState tests ──────────────────────────────────────────────

  group('HistoryEmptyState', () {
    testWidgets('renders "No jobs yet" text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryEmptyState()),
        ),
      );
      expect(find.text('No jobs yet'), findsOneWidget);
    });

    testWidgets('renders subtitle text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryEmptyState()),
        ),
      );
      expect(find.text('Your processed jobs will appear here'), findsOneWidget);
    });

    testWidgets('renders history icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HistoryEmptyState()),
        ),
      );
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });
  });

  // ─── HistoryScreen state tests ────────────────────────────────────────────

  group('HistoryScreen', () {
    /// Build HistoryScreen with the given ApiClient override.
    Widget buildWithClient(ApiClient client) {
      return ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(client),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      );
    }

    testWidgets('shows loading indicator on first frame', (tester) async {
      // Use a client with minimal 1ms delay so the timer resolves in the same
      // test without leaving pending timers.
      await tester.pumpWidget(buildWithClient(_DelayedEmptyMockApiClient()));
      // First frame: future not resolved yet → loading indicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Complete the pending timer so teardown is clean
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
    });

    testWidgets('shows empty state when no jobs returned', (tester) async {
      await tester.pumpWidget(buildWithClient(_EmptyMockApiClient()));
      await tester.pump(); // let the synchronous future resolve
      await tester.pump(); // rebuild after state change

      expect(find.byType(HistoryEmptyState), findsOneWidget);
    });

    testWidgets('shows job list after data loads', (tester) async {
      await tester.pumpWidget(buildWithClient(_JobsMockApiClient()));
      await tester.pump();
      await tester.pump();

      // Loading indicator should be gone
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // HistoryEmptyState should not be shown
      expect(find.byType(HistoryEmptyState), findsNothing);
    });

    testWidgets('shows RefreshIndicator when data is loaded', (tester) async {
      await tester.pumpWidget(buildWithClient(_JobsMockApiClient()));
      await tester.pump();
      await tester.pump();

      // When jobs are present, a RefreshIndicator wraps the list
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('back button is shown in AppBar', (tester) async {
      await tester.pumpWidget(buildWithClient(_EmptyMockApiClient()));
      await tester.pump();
      await tester.pump();

      // HistoryScreen has a BackButton in its AppBar
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('HistoryScreen displays "History" title in AppBar',
        (tester) async {
      await tester.pumpWidget(buildWithClient(_EmptyMockApiClient()));
      await tester.pump();
      await tester.pump();

      expect(find.text('History'), findsOneWidget);
    });
  });
}

// ── Test doubles ─────────────────────────────────────────────────────────────

/// Returns an empty list after a minimal 1ms delay.
/// Used to test the loading state (timer is brief enough to not linger).
class _DelayedEmptyMockApiClient extends MockApiClient {
  @override
  Future<List<Job>> listJobs() async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return [];
  }
}

/// Returns an empty list synchronously (no delay). Used for empty-state test.
class _EmptyMockApiClient extends MockApiClient {
  @override
  Future<List<Job>> listJobs() async => [];
}

/// Returns one job synchronously. Used for data-loaded test.
class _JobsMockApiClient extends MockApiClient {
  @override
  Future<List<Job>> listJobs() async => [
        const Job(
          jobId: 'test-001',
          status: 'done',
          preset: 'portrait',
          progress: JobProgress(done: 10, failed: 0, total: 10),
          outputsReady: [],
          createdAt: '2026-02-15T10:30:00.000Z',
        ),
      ];
}

