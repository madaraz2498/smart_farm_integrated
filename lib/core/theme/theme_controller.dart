import 'package:flutter/material.dart';
import '../constants/storage_keys.dart';
import '../services/preferences_manager.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  static Future<void> init() async {
    await PreferencesManager().init();
    final bool isDark = PreferencesManager().getBool(StorageKey.theme) ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> toggleTheme() async {
    if (themeNotifier.value == ThemeMode.dark) {
      themeNotifier.value = ThemeMode.light;
      await PreferencesManager().setBool(StorageKey.theme, false);
    } else {
      themeNotifier.value = ThemeMode.dark;
      await PreferencesManager().setBool(StorageKey.theme, true);
    }
  }

  static bool isDark() => themeNotifier.value == ThemeMode.dark;
}
