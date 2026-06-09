import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en');
  String? _currentUserId;

  Locale get locale => _locale;

  LocaleProvider() {
    // Initial load will use global key if exists, otherwise default 'en'
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _currentUserId != null ? '${_localeKey}_$_currentUserId' : _localeKey;
    final String? languageCode = prefs.getString(key);
    
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }

  Future<void> loadLocaleForUser(String userId) async {
    _currentUserId = userId;
    await _loadLocale();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    final String key = _currentUserId != null ? '${_localeKey}_$_currentUserId' : _localeKey;
    await prefs.setString(key, locale.languageCode);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _currentUserId = null;
    _locale = const Locale('en');
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('en');
    notifyListeners();
  }
}
