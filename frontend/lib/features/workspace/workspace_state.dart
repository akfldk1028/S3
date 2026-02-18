import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/job_item.dart';

// ---------------------------------------------------------------------------
// SelectedImage
// ---------------------------------------------------------------------------

/// An image selected by the user as input for the current batch job.
class SelectedImage {
  const SelectedImage({
    required this.bytes,
    required this.name,
  });

  /// Raw bytes of the original image (used as the "before" side of the
  /// Before/After comparison slider).
  final Uint8List bytes;

  /// Original file name (e.g. "photo.jpg").
  final String name;
}

// ---------------------------------------------------------------------------
// WorkspacePhase
// ---------------------------------------------------------------------------

/// The current lifecycle phase of the workspace.
enum WorkspacePhase {
  /// No job in progress; waiting for user input.
  idle,

  /// User has selected images; uploading or submitting the job.
  uploading,

  /// Job submitted; AI processing in progress.
  processing,

  /// Job complete; results are ready to display.
  results,
}

// ---------------------------------------------------------------------------
// WorkspaceState
// ---------------------------------------------------------------------------

/// Immutable state for the workspace screen.
class WorkspaceState {
  const WorkspaceState({
    this.phase = WorkspacePhase.idle,
    this.items = const [],
    this.selectedImages = const [],
  });

  /// Current lifecycle phase.
  final WorkspacePhase phase;

  /// Completed job result items (non-empty when [phase] is
  /// [WorkspacePhase.results]).
  final List<JobItem> items;

  /// Input images chosen by the user for the current batch.
  final List<SelectedImage> selectedImages;

  WorkspaceState copyWith({
    WorkspacePhase? phase,
    List<JobItem>? items,
    List<SelectedImage>? selectedImages,
  }) {
    return WorkspaceState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      selectedImages: selectedImages ?? this.selectedImages,
    );
  }
}

// ---------------------------------------------------------------------------
// WorkspaceNotifier  (Riverpod 3.x — uses Notifier<T>)
// ---------------------------------------------------------------------------

/// Notifier that manages [WorkspaceState] transitions.
class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() => const WorkspaceState();

  /// Reset the workspace to the idle phase, clearing all results and
  /// selected images.
  void resetToIdle() {
    state = const WorkspaceState();
  }

  /// Transition to the [WorkspacePhase.uploading] phase with the given images.
  void startUploading(List<SelectedImage> images) {
    state = state.copyWith(
      phase: WorkspacePhase.uploading,
      selectedImages: images,
      items: [],
    );
  }

  /// Transition to the [WorkspacePhase.processing] phase.
  void startProcessing() {
    state = state.copyWith(phase: WorkspacePhase.processing);
  }

  /// Transition to the [WorkspacePhase.results] phase with the given items.
  void setResults(List<JobItem> items) {
    state = state.copyWith(phase: WorkspacePhase.results, items: items);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Global workspace provider — use `ref.watch(workspaceProvider)` to read
/// state and `ref.read(workspaceProvider.notifier)` to call methods.
final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
