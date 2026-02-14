/// ShadcnUI Theme Configuration
///
/// This file defines the app's visual theme using the shadcn_ui package.
/// It provides both light and dark mode themes with ShadcnUI's design system.
///
/// Usage:
/// ```dart
/// ShadApp.materialRouter(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   routerConfig: router,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Central theme configuration for the S3 app.
///
/// Provides ShadcnUI-based themes with:
/// - Slate color scheme for professional, neutral palette
/// - Consistent design system
/// - Light and dark mode support
/// - Material Design 3 compatibility
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Light theme configuration
  ///
  /// Uses Slate color scheme for a clean, professional look.
  /// Optimized for daytime use and well-lit environments.
  ///
  /// Features:
  /// - Neutral slate colors for professional UI
  /// - High contrast for readability
  /// - Clean, modern aesthetic
  static final ShadThemeData lightTheme = ShadThemeData(
    brightness: Brightness.light,
    colorScheme: const ShadSlateColorScheme.light(),
  );

  /// Dark theme configuration
  ///
  /// Uses Slate color scheme for a comfortable dark mode experience.
  /// Optimized for low-light environments and extended use.
  ///
  /// Features:
  /// - Reduced eye strain in low-light conditions
  /// - Maintains color consistency with light theme
  /// - OLED-friendly dark backgrounds
  static final ShadThemeData darkTheme = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadSlateColorScheme.dark(),
  );

  /// Get ThemeData for Material widgets compatibility
  ///
  /// Converts ShadcnUI theme to Material ThemeData for use with
  /// standard Flutter widgets that expect Material themes.
  ///
  /// This is useful when mixing ShadcnUI components with standard
  /// Material widgets in the app.
  static ThemeData getMaterialTheme(Brightness brightness) {
    final colorScheme = brightness == Brightness.light
        ? const ShadSlateColorScheme.light()
        : const ShadSlateColorScheme.dark();

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colorScheme.primary,
        onPrimary: colorScheme.primaryForeground,
        secondary: colorScheme.secondary,
        onSecondary: colorScheme.secondaryForeground,
        error: colorScheme.destructive,
        onError: colorScheme.destructiveForeground,
        surface: colorScheme.background,
        onSurface: colorScheme.foreground,
      ),
      useMaterial3: true,
      fontFamily: 'Inter', // Modern sans-serif font
      textTheme: TextTheme(
        // Display styles (largest)
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: colorScheme.foreground,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: colorScheme.foreground,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: colorScheme.foreground,
        ),
        // Headline styles
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: colorScheme.foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: colorScheme.foreground,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: colorScheme.foreground,
        ),
        // Title styles
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colorScheme.foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: colorScheme.foreground,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.foreground,
        ),
        // Body styles
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: colorScheme.foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: colorScheme.foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: colorScheme.mutedForeground,
        ),
        // Label styles
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: colorScheme.foreground,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.foreground,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: colorScheme.mutedForeground,
        ),
      ),
    );
  }

  /// Light Material theme for fallback/compatibility
  static final ThemeData lightMaterialTheme = getMaterialTheme(Brightness.light);

  /// Dark Material theme for fallback/compatibility
  static final ThemeData darkMaterialTheme = getMaterialTheme(Brightness.dark);
}
