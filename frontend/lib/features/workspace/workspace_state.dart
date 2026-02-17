import 'dart:typed_data';

import '../../core/models/job.dart';

/// Phases of the workspace UI lifecycle.
enum WorkspacePhase { idle, uploading, processing, done, error }

/// An image selected by the user before submitting a job.
class SelectedImage {
  /// File path on the local filesystem.
  final String path;

  /// Raw bytes of the image — used as the "Before" side of the comparison slider.
  final Uint8List bytes;

  /// Display name (file name).
  final String name;

  const SelectedImage({
    required this.path,
    required this.bytes,
    required this.name,
  });
}

/// Immutable state snapshot for the workspace feature.
class WorkspaceState {
  final WorkspacePhase phase;
  final String? selectedPresetId;

  /// Original uploaded images — indexed 0-based.
  /// Maps to [JobItem.idx] via [selectedImages[item.idx - 1]].
  final List<SelectedImage> selectedImages;

  final String? activeJobId;
  final double uploadProgress;
  final Job? activeJob;
  final String? selectedRuleId;
  final String? errorMessage;

  const WorkspaceState({
    this.phase = WorkspacePhase.idle,
    this.selectedPresetId,
    this.selectedImages = const [],
    this.activeJobId,
    this.uploadProgress = 0.0,
    this.activeJob,
    this.selectedRuleId,
    this.errorMessage,
  });

  WorkspaceState copyWith({
    WorkspacePhase? phase,
    String? selectedPresetId,
    List<SelectedImage>? selectedImages,
    String? activeJobId,
    double? uploadProgress,
    Job? activeJob,
    String? selectedRuleId,
    String? errorMessage,
  }) {
    return WorkspaceState(
      phase: phase ?? this.phase,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      selectedImages: selectedImages ?? this.selectedImages,
      activeJobId: activeJobId ?? this.activeJobId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      activeJob: activeJob ?? this.activeJob,
      selectedRuleId: selectedRuleId ?? this.selectedRuleId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
