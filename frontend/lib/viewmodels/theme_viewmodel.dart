import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for theme mode
final themeProvider = StateNotifierProvider<ThemeViewModel, ThemeMode>((ref) {
  return ThemeViewModel();
});

class ThemeViewModel extends StateNotifier<ThemeMode> {
  ThemeViewModel() : super(ThemeMode.system) {
    _loadThemePreference();
  }

  // Load saved theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[themeIndex];
  }

  // Save theme preference
  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(state);
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemePreference(state);
  }
}