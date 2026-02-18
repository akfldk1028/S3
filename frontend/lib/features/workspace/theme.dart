import 'package:flutter/material.dart';

/// Central color palette and theme constants for the S3 workspace.
///
/// All UI components should reference these values rather than using
/// hardcoded [Color] literals so the entire dark theme can be updated
/// from a single location.
abstract final class WsColors {
  // ---------------------------------------------------------------------------
  // Primary accent colors (gradient endpoints)
  // ---------------------------------------------------------------------------

  /// Indigo-blue accent — start of the primary gradient. `0xFF667EEA`.
  static const Color accent1 = Color(0xFF667EEA);

  /// Pink accent — end of the primary gradient. `0xFFFF6B9D`.
  static const Color accent2 = Color(0xFFFF6B9D);

  // ---------------------------------------------------------------------------
  // Background / surface palette
  // ---------------------------------------------------------------------------

  /// Page / scaffold background (near-black). `0xFF0F0F17`.
  static const Color bg = Color(0xFF0F0F17);

  /// Card / list-item surface. `0xFF1A1A2E`.
  static const Color surface = Color(0xFF1A1A2E);

  /// Shimmer highlight colour (lighter surface). `0xFF252540`.
  static const Color surfaceLight = Color(0xFF252540);

  // ---------------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------------

  /// Error / destructive action. `0xFFEF4444`.
  static const Color error = Color(0xFFEF4444);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Primary diagonal gradient used for the splash screen and hero areas.
  ///
  /// Flows top-left → bottom-right from [accent1] to [accent2].
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent1, accent2],
  );
}

/// Shared theme constants (radii, elevations, etc.).
abstract final class WsTheme {
  /// Standard card corner radius used throughout the app. `12.0`.
  static const double radius = 12.0;
}
