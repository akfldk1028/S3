import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../workspace_provider.dart';

/// Displays the domain concept-chip grid and the custom SAM3 prompt input UI.
///
/// ## Structure (when [presetId] is non-null)
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │ [Concept chips — togglable]             │  ← passed via [concepts]
/// │ ─────────────────────────────────────── │
/// │ 프롬프트 추가...            [+]          │  ← TextField + add button
/// │ [wall ×]  [floor ×]  [ceiling ×]        │  ← custom prompt chips
/// └─────────────────────────────────────────┘
/// ```
///
/// When [presetId] is `null`, a single "Select a domain first" hint is shown
/// and the prompt input is hidden.
///
/// ## State ownership
/// - Concept chip *selection* is managed by the caller via [onToggleConcept].
/// - Custom prompts live in [workspaceProvider] ([WorkspaceState.customPrompts]).
/// - [TextEditingController] is owned by this widget's [State] and properly
///   disposed on unmount.
class ConceptsSection extends ConsumerStatefulWidget {
  /// The active preset/domain ID. When `null`, the "no domain" placeholder is
  /// shown and all interactive elements are hidden.
  final String? presetId;

  /// Ordered list of concept labels to render as togglable chips.
  final List<String> concepts;

  /// Currently selected concept labels (subset of [concepts]).
  final Set<String> selectedConcepts;

  /// Called when the user taps a concept chip to toggle its selection state.
  final void Function(String concept) onToggleConcept;

  const ConceptsSection({
    super.key,
    required this.presetId,
    this.concepts = const [],
    this.selectedConcepts = const {},
    required this.onToggleConcept,
  });

  @override
  ConsumerState<ConceptsSection> createState() => _ConceptsSectionState();
}

class _ConceptsSectionState extends ConsumerState<ConceptsSection> {
  // TextEditingController for the custom-prompt text field.
  // Must be disposed here to avoid memory leaks (reason we need StatefulWidget).
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Prompt helpers ─────────────────────────────────────────────────────────

  /// Reads the current text, delegates to the provider, then clears the field.
  void _submitPrompt() {
    ref.read(workspaceProvider.notifier).addPrompt(_ctrl.text);
    _ctrl.clear();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── No domain selected ──────────────────────────────────────────────────
    if (widget.presetId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Select a domain first',
          style: TextStyle(
            fontSize: 12,
            color: WsColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // ── Domain selected — watch custom prompts ──────────────────────────────
    final customPrompts = ref.watch(workspaceProvider).customPrompts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Concept chips ───────────────────────────────────────────────────
        if (widget.concepts.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.concepts.map(_buildConceptChip).toList(),
          ),

        // ── Separator ───────────────────────────────────────────────────────
        const SizedBox(height: 12),

        // ── Prompt input row ────────────────────────────────────────────────
        _buildPromptInputRow(),

        // ── Custom prompt chips ─────────────────────────────────────────────
        if (customPrompts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customPrompts.map(_buildPromptChip).toList(),
          ),
        ],
      ],
    );
  }

  // ── Private builders ───────────────────────────────────────────────────────

  /// Builds a single togglable concept chip using the glass-morphism style.
  Widget _buildConceptChip(String concept) {
    final selected = widget.selectedConcepts.contains(concept);

    return GestureDetector(
      onTap: () => widget.onToggleConcept(concept),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected ? WsColors.gradientPrimary : null,
          color: selected ? null : WsColors.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : WsColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          concept,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : WsColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Builds the prompt text-input row (TextField + add-button).
  Widget _buildPromptInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              hintText: '프롬프트 추가...',
              hintStyle: TextStyle(fontSize: 12, color: WsColors.textMuted),
              filled: true,
              fillColor: WsColors.glassWhite,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: WsColors.glassBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1), // indigo — matches gradientPrimary
                  width: 1,
                ),
              ),
            ),
            onSubmitted: (_) => _submitPrompt(),
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(width: 6),
        _AddButton(onTap: _submitPrompt),
      ],
    );
  }

  /// Builds a dismissible custom-prompt chip (gradient background + X button).
  Widget _buildPromptChip(String prompt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: WsColors.promptChipDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () =>
                ref.read(workspaceProvider.notifier).removePrompt(prompt),
            child: const Icon(Icons.close, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Helper widget ──────────────────────────────────────────────────────────────

/// Circular gradient "+" button used to submit a prompt.
///
/// Extracted into its own widget to keep [_ConceptsSectionState.build] readable.
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: WsColors.gradientPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, size: 18, color: Colors.white),
      ),
    );
  }
}
