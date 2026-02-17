import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/models/job.dart';

part 'workspace_state.freezed.dart';

/// The phases of the workspace processing pipeline.
///
/// State machine: idle → photosSelected → uploading → processing → done | error
enum WorkspacePhase {
  /// No photos selected; initial state
  idle,

  /// At least one photo has been selected; ready to process
  photosSelected,

  /// Photos are being uploaded to presigned S3 URLs
  uploading,

  /// Upload complete; job is queued/running on the GPU worker
  processing,

  /// Job completed successfully
  done,

  /// An error occurred (credit check failure, network error, or job failure)
  error,
}

/// Immutable state for the workspace feature.
///
/// All mutations go through [WorkspaceNotifier] via [copyWith] (auto-generated
/// by Freezed).
@freezed
abstract class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    /// Current phase of the processing pipeline
    @Default(WorkspacePhase.idle) WorkspacePhase phase,

    /// Raw bytes of photos selected by the user; preserved across retries
    @Default([]) List<Uint8List> selectedImages,

    /// Upload progress [0.0, 1.0]; only meaningful during [WorkspacePhase.uploading]
    @Default(0.0) double uploadProgress,

    /// Server-assigned job ID, set after POST /jobs succeeds
    String? activeJobId,

    /// Latest job status polled from GET /jobs/:id
    Job? activeJob,

    /// Human-readable error message shown in the error banner
    String? errorMessage,

    /// Number of consecutive network failures during polling (for UI feedback)
    @Default(0) int networkRetryCount,

    /// User-supplied text prompts passed to SAM3 during executeJob.
    ///
    /// Added via [WorkspaceNotifier.addPrompt]; removed via
    /// [WorkspaceNotifier.removePrompt]. Passed as `prompts` in the
    /// POST /jobs/:id/execute request body when non-empty.
    @Default([]) List<String> customPrompts,
  }) = _WorkspaceState;
}
