// Unit tests for WorkspaceNotifier — verifies credit pre-check, retryJob
// photo-preservation, network retry backoff, and max-failure error state.
//
// All 4 tests are required by the spec QA Acceptance Criteria.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:s3_frontend/core/auth/user_provider.dart';
import 'package:s3_frontend/features/auth/models/user_model.dart';
import 'package:s3_frontend/features/auth/queries/get_me_query.dart';
import 'package:s3_frontend/features/workspace/workspace_provider.dart';
import 'package:s3_frontend/features/workspace/workspace_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock / fake helpers
// ─────────────────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

/// Build a [ProviderContainer] with mocked [dioProvider] and a fixed-credits
/// [getMeQueryProvider] (which [userProvider] depends on).
ProviderContainer _makeContainer({
  required int userCredits,
  required Dio dio,
}) {
  return ProviderContainer(overrides: [
    // Override Dio so no real network calls are made.
    dioProvider.overrideWith((ref) => dio),
    // Override getMeQuery so userProvider resolves to a user with known credits.
    getMeQueryProvider.overrideWith(
      (ref) async =>
          User(id: 'test-user', email: 'test@example.com', credits: userCredits),
    ),
  ]);
}

/// Convenience: build a [Response] with the given [data] and [path].
Response<T> _ok<T>(T data, String path) => Response<T>(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Shared upload-flow stubs
// ─────────────────────────────────────────────────────────────────────────────

/// Stubs all upload steps on [mockDio] so they succeed:
///   POST /jobs  → { id: 'job1', presignedUrls: ['http://fake.s3/1'] }
///   PUT  *      → 200 OK
///   POST *      → 200 OK  (confirm-upload + execute)
void _stubUploadSuccess(MockDio mockDio) {
  // POST /jobs (has data: photoCount)
  when(
    () => mockDio.post(any(), data: any(named: 'data')),
  ).thenAnswer((inv) async {
    final path = inv.positionalArguments[0] as String;
    if (path.endsWith('/jobs')) {
      return _ok<Map<String, dynamic>>(
        {'id': 'job1', 'presignedUrls': ['http://fake.s3.example.com/1']},
        path,
      );
    }
    return _ok<Map<String, dynamic>>({}, path);
  });

  // PUT presigned URLs
  when(
    () => mockDio.put(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
      onSendProgress: any(named: 'onSendProgress'),
    ),
  ).thenAnswer(
    (_) async => _ok<dynamic>(null, '/s3'),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  group('WorkspaceNotifier', () {
    // ── Test 1: Credit pre-check blocks upload ────────────────────────────────
    test('uploadAndProcess aborts with phase:error when credits <= 0', () async {
      final mockDio = MockDio();
      final container = _makeContainer(userCredits: 0, dio: mockDio);
      addTearDown(container.dispose);

      // Warm up userProvider so its AsyncValue is resolved before the call.
      await container.read(userProvider.future);

      final notifier = container.read(workspaceProvider.notifier);
      notifier.addPhotos([Uint8List.fromList([1, 2, 3])]);

      await notifier.uploadAndProcess();

      final state = container.read(workspaceProvider);
      expect(
        state.phase,
        WorkspacePhase.error,
        reason: 'Should abort immediately with error when credits == 0',
      );
      expect(
        state.errorMessage!.toLowerCase(),
        contains('credit'),
        reason: 'errorMessage must mention credits',
      );
      // No Dio network calls should have been made.
      verifyNever(() => mockDio.post(any(), data: any(named: 'data')));
      verifyNever(() => mockDio.get(any()));
    });

    // ── Test 2: retryJob preserves selectedImages ─────────────────────────────
    test('retryJob preserves selectedImages and re-enters upload flow', () async {
      final mockDio = MockDio();

      // Make the first POST call fail so we can get into error state.
      when(
        () => mockDio.post(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/jobs'),
          type: DioExceptionType.connectionError,
        ),
      );

      final container = _makeContainer(userCredits: 10, dio: mockDio);
      addTearDown(container.dispose);

      await container.read(userProvider.future);

      final notifier = container.read(workspaceProvider.notifier);

      // Add photo bytes and trigger a failing upload to reach error state.
      final testImage = Uint8List.fromList([1, 2, 3]);
      notifier.addPhotos([testImage]);

      await notifier.uploadAndProcess(); // fails → phase: error

      expect(container.read(workspaceProvider).phase, WorkspacePhase.error);
      expect(
        container.read(workspaceProvider).selectedImages,
        isNotEmpty,
        reason: 'selectedImages must be preserved after a failed upload',
      );

      // Call retryJob — should reset error fields but keep selectedImages.
      await notifier.retryJob();

      final stateAfterRetry = container.read(workspaceProvider);
      expect(
        stateAfterRetry.selectedImages,
        isNotEmpty,
        reason: 'retryJob must preserve selectedImages across retry',
      );
      // Phase transitions through photosSelected → uploading → error (fails again)
      // but selectedImages must never be cleared.
    });

    // ── Test 3: Network retry — 3 failures then success ───────────────────────
    // Uses testWidgets so Timer.periodic is controlled by tester.pump().
    testWidgets(
      '3 DioException failures then success completes job',
      (tester) async {
        final mockDio = MockDio();
        _stubUploadSuccess(mockDio);

        // GET /jobs/job1: fail 3 times, then return completed.
        var getCallCount = 0;
        when(() => mockDio.get(any())).thenAnswer((_) async {
          getCallCount++;
          if (getCallCount <= 3) {
            throw DioException(
              requestOptions: RequestOptions(path: '/jobs/job1'),
              type: DioExceptionType.connectionError,
            );
          }
          return _ok<Map<String, dynamic>>(
            {'id': 'job1', 'status': 'completed'},
            '/jobs/job1',
          );
        });

        final container = _makeContainer(userCredits: 10, dio: mockDio);
        addTearDown(container.dispose);

        // Warm up userProvider.
        await container.read(userProvider.future);

        final notifier = container.read(workspaceProvider.notifier);
        notifier.addPhotos([Uint8List.fromList([1, 2, 3])]);

        // Start the upload + process pipeline. After upload completes,
        // _startPolling is called (sets up Timer.periodic).
        await notifier.uploadAndProcess();

        expect(
          container.read(workspaceProvider).phase,
          WorkspacePhase.processing,
          reason: 'Should be processing after upload completes',
        );

        // Drive the polling timer:
        // Poll 1 @ 3s (fail, backoff 2s) → resolved at 5s
        // Poll 2 @ 6s (fail, backoff 4s) → resolved at 10s
        // Poll 3 @ 9s (fail, backoff 6s) → resolved at 15s
        // Poll 4 @ 12s (success) → phase = done, timer cancelled
        // Total: advance 60s to be safe.
        await tester.pump(const Duration(seconds: 60));

        expect(
          container.read(workspaceProvider).phase,
          WorkspacePhase.done,
          reason: 'Job should complete after 3 failures then success',
        );
      },
    );

    // ── Test 4: Max network failures → error state ────────────────────────────
    testWidgets(
      '5 consecutive DioException failures set phase:error',
      (tester) async {
        final mockDio = MockDio();
        _stubUploadSuccess(mockDio);

        // GET always fails — triggers the max-failure error path.
        when(() => mockDio.get(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/jobs/job1'),
            type: DioExceptionType.connectionError,
          ),
        );

        final container = _makeContainer(userCredits: 10, dio: mockDio);
        addTearDown(container.dispose);

        await container.read(userProvider.future);

        final notifier = container.read(workspaceProvider.notifier);
        notifier.addPhotos([Uint8List.fromList([1, 2, 3])]);

        await notifier.uploadAndProcess();

        expect(
          container.read(workspaceProvider).phase,
          WorkspacePhase.processing,
        );

        // Drive polling until 5th failure triggers error state.
        // Poll 1 @ 3s (fail 1, backoff 2s), Poll 2 @ 6s (fail 2, backoff 4s),
        // Poll 3 @ 9s (fail 3, backoff 6s), Poll 4 @ 12s (fail 4, backoff 8s),
        // Poll 5 @ 15s (fail 5 → _networkFailures >= 5 → error state).
        // Advance 90s to be safe.
        await tester.pump(const Duration(seconds: 90));

        final state = container.read(workspaceProvider);
        expect(
          state.phase,
          WorkspacePhase.error,
          reason: 'Should enter error after 5 consecutive network failures',
        );
        final msg = (state.errorMessage ?? '').toLowerCase();
        expect(
          msg.contains('network') || msg.contains('retry'),
          isTrue,
          reason: 'errorMessage should mention "Network" or "Retry"',
        );
      },
    );
  });
}
