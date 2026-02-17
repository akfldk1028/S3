import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_client.dart';
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

  // ── Job Execution ─────────────────────────────────────────────────────────

  /// Uploads selected images and triggers job execution via [ApiClient].
  ///
  /// Passes [WorkspaceState.customPrompts] as the [prompts] parameter to
  /// [ApiClient.executeJob], so SAM3 uses them during segmentation.
  /// Omits the key entirely when [customPrompts] is empty — matching the
  /// conditional map entry in [S3ApiClient].
  Future<void> uploadAndProcess({
    required ApiClient apiClient,
    required Map<String, ConceptAction> concepts,
    List<String>? protect,
    String? ruleId,
  }) async {
    if (state.activeJobId == null) return;
    await apiClient.executeJob(
      state.activeJobId!,
      concepts: concepts,
      protect: protect,
      ruleId: ruleId,
      prompts: state.customPrompts.isEmpty ? null : state.customPrompts,
    );
  }
}
