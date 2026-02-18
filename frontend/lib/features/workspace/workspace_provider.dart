import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'workspace_state.dart';

/// Notifier that manages the workspace lifecycle state.
class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() => const WorkspaceState();

  /// Resets the workspace back to the idle phase and clears all transient state.
  void resetToIdle() {
    state = const WorkspaceState();
  }

  /// Signals a job cancellation request.
  void cancelJob() {
    state = state.copyWith(phase: WorkspacePhase.idle);
  }
}

/// Global provider for the workspace state.
///
/// Access via [ref.watch(workspaceProvider)] in ConsumerWidgets.
/// Call mutations via [ref.read(workspaceProvider.notifier).method()].
final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(
  WorkspaceNotifier.new,
);
