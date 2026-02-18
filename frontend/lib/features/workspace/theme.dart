import 'package:flutter/material.dart';

/// SNOW / B612-inspired dark colour palette for the workspace screens.
abstract class WsColors {
  /// Deep dark navy — main background.
  static const bg = Color(0xFF0F0F17);

  /// Dark background (alias for [bg]).
  static const Color bgDark = Color(0xFF0F0F1A);

  /// Glass card background (10% white).
  static const Color bgCard = Color(0x1AFFFFFF);

  /// Slightly lighter dark — surface / card background.
  static const surface = Color(0xFF1A1A2E);

  /// Light surface variant.
  static const surfaceLight = Color(0xFF2A2A3E);

  /// Card background (alias for [surface]).
  static const card = Color(0xFF1A1A2E);

  /// Success / positive colour.
  static const success = Color(0xFF4ADE80);

  /// Warning / caution colour.
  static const warning = Color(0xFFFFB347);

  /// Accent 1 — purple-blue.
  static const accent1 = Color(0xFF6C63FF);

  /// Accent 2 — pink / rose.
  static const accent2 = Color(0xFFFF6B9D);

  /// Error / destructive colour.
  static const error = Color(0xFFFF4D6A);

  /// Glass overlay white — 10% opacity.
  static const glassWhite = Color(0x1AFFFFFF);

  /// Glass border — 20% opacity white.
  static const glassBorder = Color(0x33FFFFFF);

  /// Glass hover — 15% opacity white.
  static const Color glassHover = Color(0x26FFFFFF);

  /// Primary text colour.
  static const text = Color(0xFFFFFFFF);

  /// High-emphasis text (87% white).
  static const textPrimary = Color(0xDEFFFFFF);

  /// Secondary / subdued text colour.
  static const textSecondary = Color(0xFF9CA3AF);

  /// Muted placeholder/hint text (50% white).
  static const textMuted = Color(0x80FFFFFF);

  /// Tertiary text (50% white — alias for [textMuted]).
  static const Color textTertiary = Color(0x80FFFFFF);

  /// Status: running / active.
  static const Color statusRunning = Color(0xFF6C63FF);

  /// Status: success.
  static const Color statusSuccess = Color(0xFF4ADE80);

  /// Status: error (alias for [error]).
  static const Color statusError = Color(0xFFFF4D6A);

  /// Primary gradient: accent1 → accent2 (left → right).
  static const gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Diagonal gradient: accent1 → accent2 (top-left → bottom-right).
  static const LinearGradient gradientDiagonal = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Design tokens for the workspace UI.
abstract class WsTheme {
  /// Default corner radius for cards and containers.
  static const double radius = 12.0;

  /// Default corner radius (alias for [radius]).
  static const double borderRadius = 12.0;

  /// Small corner radius (grid thumbnails, chips).
  static const double radiusSm = 8.0;

  /// Small corner radius (alias for [radiusSm]).
  static const double borderRadiusSm = 8.0;

  /// Large corner radius (sheets, bottom panels).
  static const double radiusLg = 20.0;

  /// Large corner radius (alias for [radiusLg]).
  static const double borderRadiusLg = 16.0;

  /// Extra-large corner radius (pill buttons, bottom sheets).
  static const double radiusXl = 28.0;

  /// Pill border radius (alias for [radiusXl]).
  static const double borderRadiusPill = 24.0;

  /// Default spacing unit.
  static const double spacing = 12.0;

  /// Small spacing unit.
  static const double spacingSm = 8.0;

  /// Large spacing unit.
  static const double spacingLg = 16.0;

  /// Extra-large spacing unit.
  static const double spacingXl = 24.0;

  /// Default icon size.
  static const double iconSize = 18.0;

  /// Small icon size.
  static const double iconSizeSm = 14.0;

  /// Large icon size.
  static const double iconSizeLg = 22.0;

  /// Fast animation duration (150ms).
  static const Duration animFast = Duration(milliseconds: 150);

  /// Normal animation duration (250ms).
  static const Duration animNormal = Duration(milliseconds: 250);

  /// Slow animation duration (400ms).
  static const Duration animSlow = Duration(milliseconds: 400);

  /// Height of the bottom action bar.
  static const double actionBarHeight = 72.0;

  /// Horizontal padding of the bottom action bar.
  static const double actionBarPadding = 16.0;

  /// Standard card decoration.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: WsColors.glassWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: WsColors.glassBorder, width: 0.5),
      );

  /// Glassmorphism container decoration.
  ///
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
