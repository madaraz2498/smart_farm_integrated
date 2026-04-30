import 'package:flutter/material.dart';

// =============================================================================
// AppTextStyles — Semantic text style constants for Smart Farm AI
//
// GUIDELINES:
//  1. Prefer Theme.of(context).textTheme.XXXX inside widgets — those are
//     already color-adapted to the current brightness.
//  2. Use the static constants below ONLY in places where a BuildContext is
//     not available, or when you need the raw style for a TextTheme definition.
//  3. Never hardcode Color in widget text styles — use theme tokens instead.
//
// HIERARCHY MAP (matches Material 3 naming):
//   displayLarge  32 / w400 → hero numbers, splash titles
//   displayMedium 28 / w400 → section heroes
//   displaySmall  24 / w400 → sub-section heroes
//   headlineLarge 26 / w600 → page titles
//   headlineMedium 22 / w600 → card headings, dialog titles
//   headlineSmall 18 / w600 → sub-headings
//   titleLarge    20 / w500 → app bar, prominent labels
//   titleMedium   16 / w500 → list primary text
//   titleSmall    14 / w500 → secondary labels
//   bodyLarge     16 / w400 → body copy
//   bodyMedium    14 / w400 → descriptions, secondary body
//   bodySmall     12 / w400 → captions, helper text
//   labelLarge    16 / w600 → buttons
//   labelMedium   14 / w500 → chips, tags
//   labelSmall    12 / w500 → overlines, badges, table headers
// =============================================================================

abstract final class AppTextStyles {
  // Tab bar / table header
  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // Chip / tag
  static const TextStyle chip = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // Convenience: for done/strikethrough task state
  static const TextStyle strikethrough = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.lineThrough,
    overflow: TextOverflow.ellipsis,
  );
}

// =============================================================================
// TextTheme factories
// Called once by light_theme.dart / dark_theme.dart.
// Colors use explicit values here because TextTheme is color-adapted
// by the framework through DefaultTextStyle inheritance — do not apply
// colorScheme here; let the theme engine handle it via onSurface.
// =============================================================================

TextTheme buildTextTheme({required bool isDark}) {
  final textPrimary = isDark ? const Color(0xFFFFFCFC) : const Color(0xFF161F1B);
  final textSecondary = isDark ? const Color(0xFFC6C6C6) : const Color(0xFF3A4640);
  final textDisabled = isDark ? const Color(0xFF6E6E6E) : const Color(0xFF9CA3AF);
  final strikeColor = isDark ? const Color(0xFFA0A0A0) : const Color(0xFF6A6A6A);

  return TextTheme(
    // ── Display ──────────────────────────────────────────────────────────────
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),

    // ── Headline ─────────────────────────────────────────────────────────────
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),

    // ── Title ────────────────────────────────────────────────────────────────
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textSecondary,
    ),

    // ── Body ─────────────────────────────────────────────────────────────────
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: textDisabled,
    ),

    // ── Label ────────────────────────────────────────────────────────────────
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimary,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: textDisabled,
      letterSpacing: 0.6,
    ),
  );
}
