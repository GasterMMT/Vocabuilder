import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  AppLanguageMode _languageMode = AppLanguageMode.system;
  AppThemeMode _themeMode = AppThemeMode.system;

  AppLanguageMode get languageMode => _languageMode;
  AppThemeMode get themeMode => _themeMode;

  // Localized strings based on current language
  String get localeString {
    switch (_languageMode) {
      case AppLanguageMode.chinese:
        return 'zh';
      case AppLanguageMode.english:
        return 'en';
      case AppLanguageMode.system:
        return 'system';
    }
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final langIndex = _prefs?.getInt('language_mode') ?? 0;
    _languageMode = AppLanguageMode.values[langIndex];

    final themeIndex = _prefs?.getInt('theme_mode') ?? 0;
    _themeMode = AppThemeMode.values[themeIndex];

    notifyListeners();
  }

  Future<void> setLanguageMode(AppLanguageMode mode) async {
    _languageMode = mode;
    await _prefs?.setInt('language_mode', mode.index);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  // String localization helper
  String t(String zh, String en) {
    switch (_languageMode) {
      case AppLanguageMode.chinese:
        return zh;
      case AppLanguageMode.english:
        return en;
      case AppLanguageMode.system:
        // Default to Chinese for system (since target is Chinese users)
        return zh;
    }
  }
}
