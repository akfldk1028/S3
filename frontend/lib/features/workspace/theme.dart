import 'package:flutter/material.dart';

/// Dark-mode workspace color palette.
class WsColors {
  WsColors._();

  // Backgrounds
  static const Color bg = Color(0xFF0F0F17);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color card = Color(0xFF1E1E32);

  // Accents
  static const Color accent1 = Color(0xFF667EEA);
  static const Color accent2 = Color(0xFFFF6B9D);

  // Gradient
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text
  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0xFF8888A0);
  static const Color textMuted = Color(0xFF55556A);

  // Glass effects
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Functional
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFD93D);
}

/// Workspace theme constants.
class WsTheme {
  WsTheme._();

  static const double radius = 12.0;
  static const double radiusSm = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
}
