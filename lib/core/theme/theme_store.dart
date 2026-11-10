import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStore {
  static const String _themeKey = 'app_theme_mode';

  final _themeMode = Observable<ThemeMode>(ThemeMode.dark);
  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeKey);
    if (savedMode != null) {
      runInAction(() {
        if (savedMode == 'light') {
          _themeMode.value = ThemeMode.light;
        } else if (savedMode == 'system') {
          _themeMode.value = ThemeMode.system;
        } else {
          _themeMode.value = ThemeMode.dark;
        }
      });
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    runInAction(() {
      _themeMode.value = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light
          ? 'light'
          : (mode == ThemeMode.system ? 'system' : 'dark'),
    );
  }

  void toggleTheme() {
    if (themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
