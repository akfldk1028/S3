import 'package:flutter/material.dart';

/// WsColors — SNOW/B612-inspired dark theme color palette.
/// All UI code should reference these constants exclusively.
class WsColors {
  WsColors._();

  // Backgrounds
  static const Color bg = Color(0xFF080810);
  static const Color surface = Color(0xFF0F0F1E);
  static const Color surfaceLight = Color(0xFF1A1A2E);

  // Text
  static const Color textPrimary = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF8888A0);
  static const Color textMuted = Color(0xFF555572);

  // Accent
  static const Color accent1 = Color(0xFF7C3AED);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

/// WsTheme — reusable decoration helpers.
class WsTheme {
  WsTheme._();

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  /// Glass-morphism card decoration used by JobHistoryItem and similar cards.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: WsColors.surface,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(
          color: WsColors.textMuted.withValues(alpha: 0.2),
          width: 0.5,
        ),
      );
}
