import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../../shared/widgets/tap_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Workspace concepts selection section.
///
/// Renders a horizontal scrollable list of [concept] chips (toggleable) and
/// an [instanceCount] selector row (1 / 2 / 3).
///
/// All tap targets are wrapped in [TapScale] and fire
/// [HapticFeedback.lightImpact()] as the first action.
class ConceptsSection extends StatelessWidget {
  const ConceptsSection({
    super.key,
    required this.concepts,
    required this.selectedConcepts,
    required this.onConceptToggled,
    required this.instanceCount,
    required this.onInstanceSelected,
  });

  /// Full list of available concept labels.
  final List<String> concepts;

  /// Currently active concept labels.
  final Set<String> selectedConcepts;

  /// Called when the user taps a concept chip.
  final ValueChanged<String> onConceptToggled;

  /// Currently selected instance count (1, 2, or 3).
  final int instanceCount;

  /// Called when the user selects a different instance count.
  final ValueChanged<int> onInstanceSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WsTheme.spacingLg,
            vertical: WsTheme.spacingSm,
          ),
          child: Text(
            'CONCEPTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: WsColors.textTertiary,
            ),
          ),
        ),

        // ── Concept chip list (L33–71) ──────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: WsTheme.spacingLg,
            ),
            itemCount: concepts.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: WsTheme.spacingSm),
            itemBuilder: (context, index) {
              final concept = concepts[index];
              final isSelected = selectedConcepts.contains(concept);

              return _ConceptChip(
                label: concept,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onConceptToggled(concept);
                },
              );
            },
          ),
        ),

        const SizedBox(height: WsTheme.spacingLg),

        // ── Instance selector header ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WsTheme.spacingLg,
          ),
          child: Text(
            'INSTANCES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: WsColors.textTertiary,
            ),
          ),
        ),

        const SizedBox(height: WsTheme.spacingSm),

        // ── Instance selector buttons (L98–138) ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WsTheme.spacingLg,
          ),
          child: Row(
            children: [1, 2, 3].map((count) {
              final isActive = instanceCount == count;
              return Padding(
                padding: EdgeInsets.only(
                  right: count < 3 ? WsTheme.spacingSm : 0,
                ),
                child: _InstanceButton(
                  count: count,
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onInstanceSelected(count);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: WsTheme.spacingLg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConceptChip  — single toggleable concept chip
// ─────────────────────────────────────────────────────────────────────────────

class _ConceptChip extends StatelessWidget {
  const _ConceptChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // TapScale wraps the AnimatedContainer so that both the 1.0→0.95 scale
    // animation and HapticFeedback fire on every press. The outer
    // GestureDetector is provided by TapScale — no extra nesting needed.
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: WsTheme.animFast,
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? WsColors.gradientPrimary : null,
          color: isSelected ? null : WsColors.glassWhite,
          borderRadius: BorderRadius.circular(WsTheme.borderRadiusPill),
          border: Border.all(
            color: isSelected ? Colors.transparent : WsColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? WsColors.textPrimary
                : WsColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InstanceButton  — 1 / 2 / 3 instance count selector
// ─────────────────────────────────────────────────────────────────────────────

class _InstanceButton extends StatelessWidget {
  const _InstanceButton({
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // TapScale wraps the AnimatedContainer — provides scale animation + tap
    // routing. HapticFeedback is already wired in [onTap] by the parent.
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: WsTheme.animFast,
        curve: Curves.easeInOut,
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive ? WsColors.gradientPrimary : null,
          color: isActive ? null : WsColors.glassWhite,
          borderRadius: BorderRadius.circular(WsTheme.borderRadiusSm),
          border: Border.all(
            color: isActive ? Colors.transparent : WsColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive
                  ? WsColors.textPrimary
                  : WsColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
