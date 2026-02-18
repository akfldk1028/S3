import 'package:flutter/material.dart';

/// SNOW/B612-inspired dark theme for the photo workspace.
class WsColors {
  WsColors._();

  // Backgrounds
  static const bg = Color(0xFF0F0F17);
  static const surface = Color(0xFF1A1A2E);
  static const surfaceLight = Color(0xFF252540);
  static const card = Color(0xFF1E1E32);

  // Accents — gradient pair
  static const accent1 = Color(0xFF667EEA); // Purple-blue
  static const accent2 = Color(0xFFFF6B9D); // Pink

  // Text
  static const textPrimary = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF8888A0);
  static const textMuted = Color(0xFF55556A);

  // Functional
  static const success = Color(0xFF4ADE80);
  static const error = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFD93D);

  // Glass
  static const glassWhite = Color(0x1AFFFFFF); // 10%
  static const glassBorder = Color(0x33FFFFFF); // 20%

  static const gradientPrimary = LinearGradient(
    colors: [accent1, accent2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class WsTheme {
  WsTheme._();

  static const radius = 12.0;
  static const radiusSm = 8.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;

  static final cardDecoration = BoxDecoration(
    color: WsColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: WsColors.glassBorder, width: 0.5),
  );

  static final glassDecoration = BoxDecoration(
    color: WsColors.glassWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: WsColors.glassBorder, width: 0.5),
  );
}
