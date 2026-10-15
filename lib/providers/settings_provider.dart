import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

enum AppLang { ru, en }

class SettingsProvider extends ChangeNotifier {
  AppLang _lang = AppLang.ru;
  AppThemeMode _themeMode = AppThemeMode.wellness;

  AppLang get lang => _lang;
  AppThemeMode get themeMode => _themeMode;

  Map<String, dynamic> exportSettings() => {
    'language': _lang.name,
    'theme': _themeMode.name,
  };

  Future<void> restoreSettings(Map<String, dynamic> value) async {
    final language = value['language'];
    final theme = value['theme'];
    _lang = language == AppLang.en.name ? AppLang.en : AppLang.ru;
    _themeMode = AppThemeMode.values.firstWhere(
      (candidate) => candidate.name == theme,
      orElse: () => AppThemeMode.wellness,
    );
    if (_themeMode == AppThemeMode.system) {
      _themeMode = AppThemeMode.wellness;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, _lang.name);
    await prefs.setString(_kTheme, _themeMode.name);
    notifyListeners();
  }

  static const _kLang = 'balance_lang';
  static const _kTheme = 'balance_theme';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final l = prefs.getString(_kLang);
    final t = prefs.getString(_kTheme);
    if (l == 'en') _lang = AppLang.en;
    if (t == 'light') _themeMode = AppThemeMode.wellness;
    if (t == 'dark') _themeMode = AppThemeMode.dark;
    if (t == 'system') _themeMode = AppThemeMode.wellness;
    notifyListeners();
  }

  Future<void> setLang(AppLang l) async {
    _lang = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, l == AppLang.en ? 'en' : 'ru');
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode m) async {
    _themeMode = m == AppThemeMode.system ? AppThemeMode.wellness : m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTheme,
      _themeMode == AppThemeMode.dark ? 'dark' : 'wellness',
    );
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _lang = AppLang.ru;
    _themeMode = AppThemeMode.wellness;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, 'ru');
    await prefs.setString(_kTheme, 'wellness');
    notifyListeners();
  }
}
