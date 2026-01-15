import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  static ThemeData getLightTheme({Color? primaryColor, Color? primaryLightColor}) {
    final primary = primaryColor ?? AppColors.racingOrange;
    final primaryLight = primaryLightColor ?? AppColors.racingOrangeLight;
    
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        error: AppColors.alertRed,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.lightTextPrimary,
        onSecondary: AppColors.lightTextPrimary,
        onError: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: GoogleFonts.robotoCondensedTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.lightTextPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 2,
      ),
    );
  }

  static ThemeData getDarkTheme({Color? primaryColor, Color? primaryLightColor}) {
    final primary = primaryColor ?? AppColors.racingOrange;
    final primaryLight = primaryLightColor ?? AppColors.racingOrangeLight;
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        error: AppColors.alertRed,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkTextPrimary,
        onSecondary: AppColors.darkTextPrimary,
        onError: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: GoogleFonts.robotoCondensedTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          displaySmall: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.alertRed, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // Mantido para compatibilidade
  static ThemeData get lightTheme => getLightTheme();
  static ThemeData get darkTheme => getDarkTheme();
}
