import 'package:flutter/material.dart';

/// Workspace-specific colour tokens and glass-morphism helpers.
///
/// These constants define the visual language for the SidePanel and all
/// workspace widgets (concept chips, prompt chips, input fields, etc.).
///
/// All values are designed for use on dark/semi-transparent backgrounds.
class WsColors {
  WsColors._();

  // ── Glass surface ──────────────────────────────────────────────────────────

  /// Semi-transparent white used as the fill for un-selected glass chips
  /// and input field backgrounds.
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white

  /// Subtle white border drawn around glass surfaces.
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white

  // ── Text ──────────────────────────────────────────────────────────────────

  /// Muted white used for placeholder / hint text inside glass inputs.
  static const Color textMuted = Color(0x80FFFFFF); // 50% white

  /// Primary body text colour (near-white for dark surfaces).
  static const Color textPrimary = Color(0xDEFFFFFF); // 87% white

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Primary indigo-to-violet gradient applied to selected chips and active
  /// UI elements.  Matches the overall product accent palette.
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Utility helpers ───────────────────────────────────────────────────────

  /// Standard glass chip decoration for *un-selected* concept chips.
  static BoxDecoration get glassChipDecoration => BoxDecoration(
        color: glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder, width: 0.5),
      );

  /// Standard chip decoration for *selected* concept chips (gradient fill).
  static BoxDecoration get selectedChipDecoration => BoxDecoration(
        gradient: gradientPrimary,
        borderRadius: BorderRadius.circular(16),
      );

  /// Standard chip decoration for *prompt* chips (always gradient + removable).
  static BoxDecoration get promptChipDecoration => BoxDecoration(
        gradient: gradientPrimary,
        borderRadius: BorderRadius.circular(16),
      );
}
