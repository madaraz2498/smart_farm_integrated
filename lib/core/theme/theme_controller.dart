import 'package:flutter/material.dart';
import '../constants/storage_keys.dart';
import '../services/preferences_manager.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);
  static String? _currentUserId;

  static Future<void> init() async {
    await PreferencesManager().init();
    // Default to light if no user is logged in yet or first run
    themeNotifier.value = ThemeMode.light;
  }

  static Future<void> loadThemeForUser(String userId) async {
    _currentUserId = userId;
    final bool isDark =
        PreferencesManager().getBool('${StorageKey.theme}_$userId') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> resetToDefault() async {
    _currentUserId = null;
    themeNotifier.value = ThemeMode.light;
  }

  static Future<void> toggleTheme() async {
    final bool newIsDark = themeNotifier.value != ThemeMode.dark;
    themeNotifier.value = newIsDark ? ThemeMode.dark : ThemeMode.light;

    if (_currentUserId != null) {
      await PreferencesManager()
          .setBool('${StorageKey.theme}_$_currentUserId', newIsDark);
    } else {
      // Fallback for global if needed, but per user's request we focus on user-linked
      await PreferencesManager().setBool(StorageKey.theme, newIsDark);
    }
  }

  static bool isDark() => themeNotifier.value == ThemeMode.dark;
}
