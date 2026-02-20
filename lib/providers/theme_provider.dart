import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme mode key for shared preferences
  static const String _themeKey = 'theme_mode';
  
  // Default to system theme
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  // Load theme preference from shared preferences
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = savedTheme == 'dark' 
            ? ThemeMode.dark 
            : savedTheme == 'light' 
                ? ThemeMode.light 
                : ThemeMode.system;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  // Save theme preference to shared preferences
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeValue;
      
      switch (mode) {
        case ThemeMode.dark:
          themeValue = 'dark';
          break;
        case ThemeMode.light:
          themeValue = 'light';
          break;
        default:
          themeValue = 'system';
      }
      
      await prefs.setString(_themeKey, themeValue);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  // Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    await _saveThemePreference(mode);
  }
  
  // Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
} 