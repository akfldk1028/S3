import 'package:flutter/foundation.dart';

import '../../core/models/job.dart';

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
/// All mutations go through [WorkspaceNotifier.state] via [copyWith].
@immutable
class WorkspaceState {
  const WorkspaceState({
    this.phase = WorkspacePhase.idle,
    this.selectedImages = const [],
    this.uploadProgress = 0.0,
    this.activeJobId,
    this.activeJob,
    this.errorMessage,
    this.networkRetryCount = 0,
  });

  /// Current phase of the processing pipeline
  final WorkspacePhase phase;

  /// Raw bytes of photos selected by the user; preserved across retries
  final List<Uint8List> selectedImages;

  /// Upload progress [0.0, 1.0]; only meaningful during [WorkspacePhase.uploading]
  final double uploadProgress;

  /// Server-assigned job ID, set after POST /jobs succeeds
  final String? activeJobId;

  /// Latest job status polled from GET /jobs/:id
  final Job? activeJob;

  /// Human-readable error message shown in the error banner
  final String? errorMessage;

  /// Number of consecutive network failures during polling (for UI feedback)
  final int networkRetryCount;

  /// Returns a copy of this state with the specified fields replaced.
  ///
  /// For nullable fields ([activeJobId], [activeJob], [errorMessage]), pass
  /// `null` to explicitly clear them. The default sentinel value means
  /// "keep the current value".
  WorkspaceState copyWith({
    WorkspacePhase? phase,
    List<Uint8List>? selectedImages,
    double? uploadProgress,
    Object? activeJobId = _unset,
    Object? activeJob = _unset,
    Object? errorMessage = _unset,
    int? networkRetryCount,
  }) {
    return WorkspaceState(
      phase: phase ?? this.phase,
      selectedImages: selectedImages ?? this.selectedImages,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      activeJobId:
          identical(activeJobId, _unset) ? this.activeJobId : activeJobId as String?,
      activeJob:
          identical(activeJob, _unset) ? this.activeJob : activeJob as Job?,
      errorMessage:
          identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
      networkRetryCount: networkRetryCount ?? this.networkRetryCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkspaceState &&
          runtimeType == other.runtimeType &&
          phase == other.phase &&
          listEquals(selectedImages, other.selectedImages) &&
          uploadProgress == other.uploadProgress &&
          activeJobId == other.activeJobId &&
          activeJob == other.activeJob &&
          errorMessage == other.errorMessage &&
          networkRetryCount == other.networkRetryCount;

  @override
  int get hashCode => Object.hash(
        phase,
        Object.hashAll(selectedImages),
        uploadProgress,
        activeJobId,
        activeJob,
        errorMessage,
        networkRetryCount,
      );

  @override
  String toString() => 'WorkspaceState('
      'phase: $phase, '
      'photos: ${selectedImages.length}, '
      'uploadProgress: ${uploadProgress.toStringAsFixed(2)}, '
      'activeJobId: $activeJobId, '
      'activeJob: $activeJob, '
      'errorMessage: $errorMessage, '
      'networkRetryCount: $networkRetryCount'
      ')';
}

// Private sentinel to distinguish "not provided" from explicit null in copyWith
const _unset = _Unset();

class _Unset {
  const _Unset();
}
