import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter'; // Assuming Inter or system font

  static TextStyle headingLarge(bool isDark) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.dark.textPrimary : AppColors.light.textPrimary,
        fontFamily: fontFamily,
      );

  static TextStyle headingMedium(bool isDark) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.dark.textPrimary : AppColors.light.textPrimary,
        fontFamily: fontFamily,
      );

  static TextStyle body(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.dark.textPrimary : AppColors.light.textPrimary,
        fontFamily: fontFamily,
      );

  static TextStyle caption(bool isDark) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.dark.textSecondary : AppColors.light.textSecondary,
        fontFamily: fontFamily,
      );

  static TextStyle button(bool isDark) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: fontFamily,
      );
}
