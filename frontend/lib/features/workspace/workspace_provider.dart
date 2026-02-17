import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'workspace_state.dart';

part 'workspace_provider.g.dart';

/// Riverpod notifier that manages the [WorkspaceState] for the workspace feature.
///
/// Access via `ref.read(workspaceProvider.notifier)`.
/// Watch state via `ref.watch(workspaceProvider)`.
@riverpod
class Workspace extends _$Workspace {
  @override
  WorkspaceState build() => const WorkspaceState();

  // ── Prompt Management ─────────────────────────────────────────────────────

  /// Adds a free-text prompt to [WorkspaceState.customPrompts].
  ///
  /// Trims whitespace before storing. Silently ignores:
  /// - empty or whitespace-only strings
  /// - exact duplicates (case-sensitive)
  void addPrompt(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;
    if (state.customPrompts.contains(trimmed)) return;
    state = state.copyWith(
      customPrompts: [...state.customPrompts, trimmed],
    );
  }

  /// Removes a text prompt from [WorkspaceState.customPrompts].
  ///
  /// No-op if [prompt] is not present in the list.
  void removePrompt(String prompt) {
    state = state.copyWith(
      customPrompts: state.customPrompts.where((p) => p != prompt).toList(),
    );
  }
}
