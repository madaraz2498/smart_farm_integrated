import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors  —  single source of truth for every colour in Smart Farm AI.
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const Color primary        = Color(0xFF4CAF50);
  static const Color primaryLight   = Color(0xFF66BB6A);
  static const Color primaryDark    = Color(0xFF388E3C);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // Admin accent
  static const Color adminAccent    = Color(0xFFE65100);
  static const Color adminSurface   = Color(0xFFFFF3E0);

  // Background / surface
  static const Color background     = Color(0xFFFAFBF7);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color topBarBg       = Color(0xFFE8F5E9);

  // Text
  static const Color textDark       = Color(0xFF1F2937);
  static const Color textMid        = Color(0xFF374151);
  static const Color textDisabled   = Color(0xFF9CA3AF);
  static const Color textSubtle     = Color(0xFF6B7280);

  // Status
  static const Color success        = Color(0xFF4CAF50);
  static const Color warning        = Color(0xFFFF9800);
  static const Color error          = Color(0xFFEF4444);
  static const Color info           = Color(0xFF2196F3);

  // Misc
  static const Color notifRed       = Color(0xFFEF4444);
  static const Color divider        = Color(0xFFE5E7EB);
  static const Color cardBorder     = Color(0xFFEEF0EB);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSizes  —  consistent spacing & radius values.
// ─────────────────────────────────────────────────────────────────────────────
class AppSizes {
  AppSizes._();

  // Padding
  static const double pagePadding   = 24.0;
  static const double cardPadding   = 18.0;
  static const double itemPadding   = 12.0;

  // Border radius
  static const double radiusSmall   = 6.0;
  static const double radiusMid     = 10.0;
  static const double radiusCard    = 12.0;
  static const double radiusLarge   = 16.0;

  // Top bar
  static const double topBarHeight  = 64.0;

  // Sidebar
  static const double sidebarWidth  = 220.0;

  // Breakpoints
  static const double wideBreak     = 700.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles  —  reusable text styles.
// ─────────────────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark,
  );
  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 14, color: AppColors.textSubtle,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, color: AppColors.textDisabled,
  );
  static const TextStyle tableHeader = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textDisabled, letterSpacing: 0.8,
  );
}
