import 'package:flutter/material.dart';

/// SNOW / B612-inspired dark colour palette for the workspace screens.
abstract class WsColors {
  /// Deep dark navy — main background.
  static const bg = Color(0xFF0F0F17);

  /// Slightly lighter dark — surface / card background.
  static const surface = Color(0xFF1A1A2E);

  /// Accent 1 — purple-blue.
  static const accent1 = Color(0xFF6C63FF);

  /// Accent 2 — pink / rose.
  static const accent2 = Color(0xFFFF6B9D);

  /// Error / destructive colour.
  static const error = Color(0xFFFF4D6A);

  /// Glass overlay white — 10 % opacity.
  static const glassWhite = Color(0x1AFFFFFF);

  /// Glass border — 20 % opacity white.
  static const glassBorder = Color(0x33FFFFFF);

  /// Primary text colour.
  static const text = Color(0xFFFFFFFF);

  /// High-emphasis text (87% white).
  static const textPrimary = Color(0xDEFFFFFF);

  /// Secondary / subdued text colour.
  static const textSecondary = Color(0xFF9CA3AF);

  /// Muted placeholder/hint text (50% white).
  static const textMuted = Color(0x80FFFFFF);

  /// Primary gradient: accent1 (top-left) → accent2 (bottom-right).
  static const gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Design tokens for the workspace UI.
abstract class WsTheme {
  /// Default corner radius for cards and containers.
  static const double radius = 12.0;

  /// Small corner radius (grid thumbnails, chips).
  static const double radiusSm = 8.0;

  /// Large corner radius (sheets, bottom panels).
  static const double radiusLg = 20.0;

  /// Extra-large corner radius (pill buttons, bottom sheets).
  static const double radiusXl = 28.0;

  /// Standard card decoration.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      );

  /// Glassmorphism container decoration.
  /// MUST be used inside a [Stack] over a blurrable (non-opaque) background,
  /// combined with [BackdropFilter].
  static final glassDecoration = BoxDecoration(
    color: WsColors.glassWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: WsColors.glassBorder, width: 0.5),
  );

  /// Glassmorphism decoration with smaller radius (for compact elements).
  static final glassDecorationSm = BoxDecoration(
    color: WsColors.glassWhite,
    borderRadius: BorderRadius.circular(radiusSm),
    border: Border.all(color: WsColors.glassBorder, width: 0.5),
  );
}
