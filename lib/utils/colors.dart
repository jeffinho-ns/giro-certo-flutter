import 'package:flutter/material.dart';

class AppColors {
  // Cores principais - Laranja (cor do logo) e variações
  static const Color racingOrange = Color(0xFFFF4500); // Laranja principal
  static const Color racingOrangeLight = Color(0xFFFF6B35); // Laranja claro
  static const Color racingOrangeDark = Color(0xFFCC3700); // Laranja escuro
  static const Color racingOrangeAccent = Color(0xFFFF8C42); // Laranja accent
  
  // Cores de status
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color alertRed = Color(0xFFFF1744);
  static const Color statusOk = neonGreen;
  static const Color statusWarning = Color(0xFFFFA500);
  static const Color statusCritical = alertRed;
  
  // Cores para tema Dark
  static const Color darkBackground = Color(0xFF2C2C2C); // #2c2c2c
  static const Color darkSurface = Color(0xFF3A3A3A);
  static const Color darkCard = Color(0xFF383838);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  
  // Cores para tema Light
  static const Color lightBackground = Color(0xFFF4F4F4); // #f4f4f4
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  
  // Cores auxiliares (mantidas para compatibilidade)
  static const Color darkGrafite = darkBackground;
  static const Color darkGray = Color(0xFF383838);
  static const Color mediumGray = Color(0xFF2C2C2C);
  static const Color lightGray = Color(0xFF3A3A3A);
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
}
