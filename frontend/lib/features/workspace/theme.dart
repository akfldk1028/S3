import 'package:flutter/material.dart';

/// SNOW/B612-inspired glassmorphism design tokens.
/// All colors must be referenced via these tokens — never hardcode hex values.
class WsColors {
  WsColors._();

  // ── Background Layers ────────────────────────────────────────────────────
  /// Deepest background: 0xFF0F0F17
  static const Color bg = Color(0xFF0F0F17);

  /// Mid-layer surface: 0xFF1A1A2E
  static const Color surface = Color(0xFF1A1A2E);

  /// Card surface: 0xFF1E1E32
  static const Color card = Color(0xFF1E1E32);

  /// Slightly elevated surface: 0xFF252540
  static const Color surfaceLight = Color(0xFF252540);

  // ── Accent Colors ────────────────────────────────────────────────────────
  /// Primary accent — electric purple: 0xFF667EEA
  static const Color accent1 = Color(0xFF667EEA);

  /// Secondary accent — neon pink: 0xFFFF6B9D
  static const Color accent2 = Color(0xFFFF6B9D);

  // ── Text Colors ──────────────────────────────────────────────────────────
  /// Primary text: 0xFFE8E8F0
  static const Color textPrimary = Color(0xFFE8E8F0);

  /// Secondary text: 0xFF9898B8
  static const Color textSecondary = Color(0xFF9898B8);

  /// Muted text: 0xFF585870
  static const Color textMuted = Color(0xFF585870);

  // ── Glass Effects ────────────────────────────────────────────────────────
  /// Glass border — 20% white: 0x33FFFFFF
  static const Color glassBorder = Color(0x33FFFFFF);

  /// Glass white fill — 8% white: 0x14FFFFFF
  static const Color glassWhite = Color(0x14FFFFFF);

  // ── Status Colors ────────────────────────────────────────────────────────
  /// Error red: 0xFFEF4444
  static const Color error = Color(0xFFEF4444);

  /// Success green: 0xFF22C55E
  static const Color success = Color(0xFF22C55E);

  /// Warning amber: 0xFFF59E0B
  static const Color warning = Color(0xFFF59E0B);

  // ── Gradients ────────────────────────────────────────────────────────────
  /// Primary gradient: accent1 (purple) → accent2 (pink)
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// WsTheme design system constants: radii, decorations, spacing.
class WsTheme {
  WsTheme._();

  // ── Border Radii ─────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radius = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ── Decorations ──────────────────────────────────────────────────────────

  /// Glass card decoration: semi-transparent fill + glass border.
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      );

  /// Solid card decoration: card surface + glass border + subtle shadow.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: WsColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: WsColors.accent1.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
