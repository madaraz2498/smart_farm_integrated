import 'package:flutter/material.dart';

class AppColors {
  // Static references for easy access
  static const primary = Color(0xFF10B981); // Emerald Green
  static const secondary = Color(0xFF3B82F6); // Blue

  // Semantic Colors
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;
  final Color success;

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.success,
  });

  static const light = AppColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
  );

  static const dark = AppColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    card: Color(0xFF1E293B),
    border: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    error: Color(0xFFF87171),
    success: Color(0xFF34D399),
  );
}
