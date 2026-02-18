import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../../../shared/widgets/tap_scale.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Workspace protect-elements selection section.
///
/// Renders a horizontal scrollable list of [protectItems] chips (toggleable).
/// Each chip represents an element to be protected from modification.
///
/// All tap targets are wrapped in [TapScale] and fire
/// [HapticFeedback.lightImpact()] as the first action.
class ProtectSection extends StatelessWidget {
  const ProtectSection({
    super.key,
    required this.protectItems,
    required this.selectedItems,
    required this.onItemToggled,
  });

  /// Full list of available protect-element labels.
  final List<String> protectItems;

  /// Currently active protect-element labels.
  final Set<String> selectedItems;

  /// Called when the user taps a protect chip.
  final ValueChanged<String> onItemToggled;

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
            'PROTECT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: WsColors.textTertiary,
            ),
          ),
        ),

        // ── Protect chip list (L31–82) ──────────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: WsTheme.spacingLg,
            ),
            itemCount: protectItems.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: WsTheme.spacingSm),
            itemBuilder: (context, index) {
              final item = protectItems[index];
              final isSelected = selectedItems.contains(item);

              return _ProtectChip(
                label: item,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onItemToggled(item);
                },
              );
            },
          ),
        ),

        const SizedBox(height: WsTheme.spacingLg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProtectChip  — single toggleable protect chip
// ─────────────────────────────────────────────────────────────────────────────

class _ProtectChip extends StatelessWidget {
  const _ProtectChip({
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: WsTheme.iconSizeSm,
              color: isSelected
                  ? WsColors.textPrimary
                  : WsColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
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
          ],
        ),
      ),
    );
  }
}
