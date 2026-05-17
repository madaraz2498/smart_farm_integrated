import 'package:flutter/material.dart';

// =============================================================================
// AppTextStyles — semantic helpers only (NO COLORS HERE)
// =============================================================================

abstract final class AppTextStyles {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  static const TextStyle chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle strikethrough = TextStyle(
    fontSize: 16,
    decoration: TextDecoration.lineThrough,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

// =============================================================================
// TextTheme — NOW BASED ON ColorScheme ✅
// =============================================================================

TextTheme buildTextTheme(ColorScheme cs) {
  return TextTheme(
    // Display
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),

    // Headlines
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),

    // Titles
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
    ),

    // Body
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      color: cs.onSurface,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: cs.onSurface,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: cs.onSurfaceVariant,
    ),

    // Labels
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: cs.onPrimary, // for buttons
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
    ),
  );
}
