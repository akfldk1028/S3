import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/api_endpoints.dart';
import '../../core/auth/user_provider.dart';
import '../../core/models/job.dart';
import '../auth/queries/get_me_query.dart';
import 'workspace_state.dart';

/// Manages the workspace processing pipeline state.
///
/// State machine:
///   idle → photosSelected → uploading → processing → done | error
///
/// Key methods:
/// - [addPhotos] — append raw image bytes; transitions to [WorkspacePhase.photosSelected]
/// - [removePhoto] — remove a single photo by index
/// - [uploadAndProcess] — pre-flight credit check → upload → execute → poll
/// - [retryJob] — reset state (preserving photos) and re-run [uploadAndProcess]
/// - [cancelJob] — cancel the active job and return to idle
/// - [resetToIdle] — clear all state
class WorkspaceNotifier extends Notifier<WorkspaceState> {
  Timer? _pollingTimer;

  /// Counts consecutive poll failures (non-network) before surfacing error state
  int _pollFailures = 0;

  /// Counts consecutive network failures during polling; drives exponential backoff
  int _networkFailures = 0;

  @override
  WorkspaceState build() {
    ref.onDispose(() => _pollingTimer?.cancel());
    return const WorkspaceState();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Photo Management
  // ──────────────────────────────────────────────────────────────────────────

  /// Appends [images] to the selected photos list.
  void addPhotos(List<Uint8List> images) {
    state = state.copyWith(
      selectedImages: [...state.selectedImages, ...images],
      phase: WorkspacePhase.photosSelected,
    );
  }

  /// Removes the photo at [index] from the selected photos list.
  void removePhoto(int index) {
    final updated = List<Uint8List>.from(state.selectedImages)..removeAt(index);
    state = state.copyWith(
      selectedImages: updated,
      phase:
          updated.isEmpty ? WorkspacePhase.idle : WorkspacePhase.photosSelected,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Core Upload & Process Flow
  // ──────────────────────────────────────────────────────────────────────────

  /// Runs the full upload → execute → poll pipeline.
  ///
  /// **Credit pre-flight check**: reads [userProvider] synchronously via
  /// `ref.read(...).valueOrNull`. If the user has zero or fewer credits,
  /// transitions immediately to [WorkspacePhase.error] WITHOUT making any
  /// network calls.
  ///
  /// Steps:
  /// 1. Credit guard — abort if credits ≤ 0
  /// 2. POST /jobs — obtain job ID + presigned upload URLs
  /// 3. PUT presigned URLs — upload each photo
  /// 4. POST /jobs/:id/confirm-upload
  /// 5. POST /jobs/:id/execute
  /// 6. Start polling GET /jobs/:id
  Future<void> uploadAndProcess() async {
    // ── Step 1: Credit pre-flight check ─────────────────────────────────────
    // Read userProvider synchronously — no network call; uses cached AsyncValue.
    // If the user data hasn't loaded yet (valueOrNull == null), treat as 0 credits.
    final credits = ref.read(userProvider).valueOrNull?.credits ?? 0;
    if (credits <= 0) {
      state = state.copyWith(
        phase: WorkspacePhase.error,
        errorMessage: 'Not enough credits. Please add credits to continue.',
      );
      return;
    }

    if (state.selectedImages.isEmpty) return;

    // ── Step 2: Create job ───────────────────────────────────────────────────
    state = state.copyWith(phase: WorkspacePhase.uploading, uploadProgress: 0.0);

    try {
      final dio = ref.read(dioProvider);

      final createResponse = await dio.post(
        ApiEndpoints.jobs,
        data: {'photoCount': state.selectedImages.length},
      );
      final jobId = createResponse.data['id'] as String;
      final presignedUrls = (createResponse.data['presignedUrls'] as List)
          .map((e) => e as String)
          .toList();

      state = state.copyWith(activeJobId: jobId);

      // ── Step 3: Upload photos to presigned S3 URLs ───────────────────────
      final totalPhotos = state.selectedImages.length;
      for (var i = 0; i < totalPhotos; i++) {
        await dio.put(
          presignedUrls[i],
          data: state.selectedImages[i],
          options: Options(headers: {'Content-Type': 'image/jpeg'}),
          onSendProgress: (sent, total) {
            final overallProgress =
                (i + (total > 0 ? sent / total : 0)) / totalPhotos;
            state = state.copyWith(uploadProgress: overallProgress);
          },
        );
      }

      // ── Step 4: Confirm upload ────────────────────────────────────────────
      await dio.post(ApiEndpoints.confirmUpload(jobId));

      // ── Step 5: Execute job ───────────────────────────────────────────────
      await dio.post(ApiEndpoints.execute(jobId));

      // ── Step 6: Start polling ─────────────────────────────────────────────
      state = state.copyWith(phase: WorkspacePhase.processing);
      _startPolling(jobId);
    } on DioException catch (e) {
      state = state.copyWith(
        phase: WorkspacePhase.error,
        errorMessage: e.message ?? 'Upload failed. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        phase: WorkspacePhase.error,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Polling
  // ──────────────────────────────────────────────────────────────────────────

  /// Starts a periodic poll of [ApiEndpoints.jobById].
  ///
  /// Network failures are handled with exponential backoff up to
  /// [_maxNetworkFailures] before surfacing [WorkspacePhase.error].
  void _startPolling(String jobId) {
    const pollInterval = Duration(seconds: 3);
    const maxNonNetworkFailures = 10;
    const maxNetworkFailures = 5;

    _pollFailures = 0;
    _networkFailures = 0;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(pollInterval, (_) async {
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get(ApiEndpoints.jobById(jobId));
        final job = Job.fromJson(response.data as Map<String, dynamic>);

        // Reset network failure counter on any successful response
        _networkFailures = 0;
        state = state.copyWith(activeJob: job);

        switch (job.status) {
          case 'completed':
          case 'done':
            _pollingTimer?.cancel();
            state = state.copyWith(phase: WorkspacePhase.done);
          case 'failed':
            _pollingTimer?.cancel();
            // Keep phase as processing; UI will show retry via activeJob.status
          default:
            // Still running — continue polling
        }
      } on DioException catch (_) {
        // ── Network auto-reconnect with exponential backoff ──────────────────
        _networkFailures++;
        if (_networkFailures >= maxNetworkFailures) {
          _pollingTimer?.cancel();
          state = state.copyWith(
            phase: WorkspacePhase.error,
            errorMessage: 'Network connection lost. Tap Retry to try again.',
          );
        } else {
          // Back off before the next poll; Timer.periodic will fire again
          await Future.delayed(Duration(seconds: _networkFailures * 2));
        }
      } catch (_) {
        _pollFailures++;
        if (_pollFailures >= maxNonNetworkFailures) {
          _pollingTimer?.cancel();
          state = state.copyWith(
            phase: WorkspacePhase.error,
            errorMessage: 'Processing failed. Please try again.',
          );
        }
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Retry & Reset
  // ──────────────────────────────────────────────────────────────────────────

  /// Resets error state and re-runs [uploadAndProcess] with original photos.
  ///
  /// Guards:
  /// - If [selectedImages] is empty, falls back to [resetToIdle] (defensive)
  /// - If already uploading/processing (double-tap guard), returns immediately
  Future<void> retryJob() async {
    if (state.selectedImages.isEmpty) {
      resetToIdle();
      return;
    }

    if (state.phase == WorkspacePhase.uploading ||
        state.phase == WorkspacePhase.processing) {
      return;
    }

    _pollingTimer?.cancel();

    // Reset error/job fields but preserve selectedImages for the retry
    state = state.copyWith(
      phase: WorkspacePhase.photosSelected,
      errorMessage: null,
      activeJobId: null,
      activeJob: null,
      uploadProgress: 0.0,
      networkRetryCount: 0,
    );

    await uploadAndProcess();
  }

  /// Cancels the active job on the server and resets to idle.
  Future<void> cancelJob() async {
    _pollingTimer?.cancel();

    if (state.activeJobId != null) {
      try {
        final dio = ref.read(dioProvider);
        await dio.post(ApiEndpoints.cancel(state.activeJobId!));
      } catch (_) {
        // Ignore cancel errors — local state reset is the priority
      }
    }

    resetToIdle();
  }

  /// Clears all workspace state; returns to [WorkspacePhase.idle].
  ///
  /// NOTE: This discards selected photos. Use [retryJob] to restart
  /// processing while preserving photos.
  void resetToIdle() {
    _pollingTimer?.cancel();
    state = const WorkspaceState();
  }
}

/// The single Riverpod provider for [WorkspaceNotifier].
///
/// Consumers:
/// - `ref.watch(workspaceProvider)` — reactive state (WorkspaceState)
/// - `ref.read(workspaceProvider.notifier)` — call methods
final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(WorkspaceNotifier.new);
