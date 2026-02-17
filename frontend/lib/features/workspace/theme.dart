import 'package:flutter/material.dart';

/// Workspace colour tokens and theme helpers.
///
/// All workspace widgets should reference [WsColors] for consistent theming.
/// Do NOT use hard-coded colour literals elsewhere in the workspace feature.
class WsColors {
  WsColors._();

  // ── Primary accent palette ────────────────────────────────────────────────
  static const Color accent1 = Color(0xFF667EEA); // purple-blue
  static const Color accent2 = Color(0xFFFF6B9D); // pink

  // ── Glass / overlay surfaces ──────────────────────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassHover = Color(0x26FFFFFF); // 15% white

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textTertiary = Color(0x80FFFFFF); // 50% white

  // ── Background ────────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F0F1A);
  static const Color bgCard = Color(0x1AFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color statusRunning = Color(0xFF667EEA);
  static const Color statusSuccess = Color(0xFF4ADE80);
  static const Color statusError = Color(0xFFFF6B6B);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient gradientDiagonal = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Layout and dimension tokens for the workspace feature.
class WsTheme {
  WsTheme._();

  static const double borderRadius = 12.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusPill = 24.0;

  static const double spacing = 12.0;
  static const double spacingSm = 8.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;

  static const double iconSize = 18.0;
  static const double iconSizeSm = 14.0;
  static const double iconSizeLg = 22.0;

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  static const double actionBarHeight = 72.0;
  static const double actionBarPadding = 16.0;
}
