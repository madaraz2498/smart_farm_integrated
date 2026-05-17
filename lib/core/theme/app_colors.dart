import 'package:flutter/material.dart';

// =============================================================================
// AppColors — Unified color palette for Smart Farm AI
//
// This is the SINGLE SOURCE OF TRUTH for every color in the app.
// Never hardcode colors in widgets. Always use Theme.of(context).colorScheme
// or AppColors constants where a theme token is not available.
//
// Usage in widgets:
//   final cs = Theme.of(context).colorScheme;
//   cs.primary          → brand green
//   cs.surface          → card/surface backgrounds
//   cs.onSurface        → primary text on surfaces
//   cs.onSurfaceVariant → secondary/subtle text
//   AppColors.success   → semantic status color (not in Material scheme)
//   AppColors.warning   → semantic status color
//   AppColors.info      → semantic status color
// =============================================================================

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand palette  (theme-independent, always the same)
  // ---------------------------------------------------------------------------

  /// Primary brand green — buttons, active states, FABs, links
  static const Color primary = Color(0xFF2BAB6F);

  /// A slightly deeper green for pressed/hover states
  static const Color primaryDark = Color(0xFF1D8353);

  /// Very light green used for tinted surfaces / icon backgrounds
  static const Color primarySurface = Color(0xFFE6F5EE);

  /// Alias for old AppColors.primaryLight
  static const Color primaryLight = Color(0xFF5CC091);

  // ---------------------------------------------------------------------------
  // Semantic / status colors  (theme-independent)
  // These are NOT in Material's ColorScheme so keep them as constants.
  // ---------------------------------------------------------------------------

  /// Success — same as primary for this app (green = success)
  static const Color success = Color(0xFF15B86C);

  /// Warning — amber/orange for alerts and caution states
  static const Color warning = Color(0xFFF59E0B);

  /// Info — blue for informational badges and callouts
  static const Color info = Color(0xFF3B82F6);

  /// Error — already in ColorScheme but useful as a shorthand
  static const Color error = Color(0xFFEF4444);

  /// Notification Red - Alias for old AppColors.notifRed
  static const Color notifRed = Color(0xFFEF4444);

  // ---------------------------------------------------------------------------
  // Admin accent  (used only in admin-specific UI)
  // ---------------------------------------------------------------------------
  static const Color adminAccent = Color(0xFFE65100);
  static const Color adminAccentSurface = Color(0xFFFFF3E0);
  static const Color adminSurface =
      Color(0xFFFFF3E0); // Alias for old AppColors.adminSurface

  // ---------------------------------------------------------------------------
  // Surface/Background (Compatibility aliases)
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Light palette  — resolved by the app via Theme.of(context).colorScheme
  //                  Do NOT use these directly in widgets; use ColorScheme tokens
  // ---------------------------------------------------------------------------
  static const LightPalette light = LightPalette();

  // ---------------------------------------------------------------------------
  // Dark palette
  // ---------------------------------------------------------------------------
  static const DarkPalette dark = DarkPalette();
}

// =============================================================================
// Internal palette definitions — used only by app_theme.dart to build ThemeData
// =============================================================================

final class LightPalette {
  const LightPalette();

  // Backgrounds
  Color get background => const Color(0xFFF6F7F9); // page scaffold
  Color get surface => const Color(0xFFFFFFFF); // cards, app bar, bottom nav
  Color get surfaceVariant => const Color(0xFFF0F4F2); // subtle sections
  Color get inverseSurface =>
      const Color(0xFF1F2937); // dark surfaces in light mode

  // Text on background/surface
  Color get onBackground => const Color(0xFF161F1B); // body text, headings
  Color get onSurface => const Color(0xFF161F1B);
  Color get onSurfaceVariant => const Color(0xFF3A4640); // secondary/labels
  Color get onInverseSurface => const Color(0xFFF6F7F9);

  // Borders, dividers
  Color get outline => const Color(0xFFD1DAD6);
  Color get outlineVariant => const Color(0xFFEEF0EB);

  // Specific component fills
  Color get inputFill => const Color(0xFFFFFFFF);
  Color get topBarBg => const Color(0xFFE8F5E9);
}

final class DarkPalette {
  const DarkPalette();

  // Backgrounds
  Color get background => const Color(0xFF0F0F0F); // Very dark (almost black)
  Color get surface => const Color(0xFF1E1E1E); // Cards (slightly lighter)
  Color get surfaceVariant => const Color(0xFF262626); // Subtle sections
  Color get inverseSurface => const Color(0xFFF3F4F6);

  // Text
  Color get onBackground => const Color(0xFFFFFFFF); // Pure white titles
  Color get onSurface => const Color(0xFFD1D5DB); // Light gray body
  Color get onSurfaceVariant =>
      const Color(0xFF9CA3AF); // Darker gray secondary
  Color get onInverseSurface => const Color(0xFF0F0F0F);

  // Borders, dividers
  Color get outline => const Color(0xFF3F3F3F);
  Color get outlineVariant => const Color(0xFF262626);

  // Specific component fills
  Color get inputFill => const Color(0xFF181818);
  Color get topBarBg => const Color(0xFF121212);
}

// =============================================================================
// ColorScheme Extensions — convenient access to semantic colors that are
//                           not in the standard Material 3 scheme.
// =============================================================================

extension ColorSchemeExtensions on ColorScheme {
  Color get info => AppColors.info;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
}
