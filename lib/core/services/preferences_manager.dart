import 'package:shared_preferences/shared_preferences.dart';

class PreferencesManager {
  static final PreferencesManager _instance = PreferencesManager._internal();
  factory PreferencesManager() => _instance;
  PreferencesManager._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> setBool(String key, bool value) async {
    await init();
    return await _prefs!.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
}
