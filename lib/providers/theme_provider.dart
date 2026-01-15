import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

enum AppThemeMode {
  light,
  dark,
}

enum AppThemeColor {
  orange,
  blue,
  green,
  purple,
  red,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _colorKey = 'app_theme_color';
  
  AppThemeMode _themeMode = AppThemeMode.dark;
  AppThemeColor _themeColor = AppThemeColor.orange;

  AppThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == AppThemeMode.dark;
  AppThemeColor get themeColor => _themeColor;

  Color get primaryColor {
    switch (_themeColor) {
      case AppThemeColor.orange:
        return AppColors.racingOrange;
      case AppThemeColor.blue:
        return const Color(0xFF2196F3);
      case AppThemeColor.green:
        return const Color(0xFF4CAF50);
      case AppThemeColor.purple:
        return const Color(0xFF9C27B0);
      case AppThemeColor.red:
        return const Color(0xFFF44336);
    }
  }

  Color get primaryLightColor {
    switch (_themeColor) {
      case AppThemeColor.orange:
        return AppColors.racingOrangeLight;
      case AppThemeColor.blue:
        return const Color(0xFF64B5F6);
      case AppThemeColor.green:
        return const Color(0xFF81C784);
      case AppThemeColor.purple:
        return const Color(0xFFBA68C8);
      case AppThemeColor.red:
        return const Color(0xFFE57373);
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Carregar tema
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => AppThemeMode.dark,
        );
      }
      
      // Carregar cor
      final savedColor = prefs.getString(_colorKey);
      if (savedColor != null) {
        _themeColor = AppThemeColor.values.firstWhere(
          (color) => color.toString() == savedColor,
          orElse: () => AppThemeColor.orange,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.toString());
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    _themeColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorKey, color.toString());
    } catch (e) {
      debugPrint('Erro ao salvar cor: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.dark
        ? AppThemeMode.light
        : AppThemeMode.dark;
    await setTheme(newMode);
  }
}
