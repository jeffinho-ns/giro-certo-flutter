import 'package:flutter/material.dart';

class AppColors {
  // Cores principais - Laranja (cor do logo) e variações - SUAVES PARA USO PROLONGADO
  // Cores menos saturadas e mais confortáveis para os olhos
  static const Color racingOrange = Color(0xFFFF6B3D); // Laranja suave - menos saturado
  static const Color racingOrangeLight = Color(0xFFFF8A65); // Laranja claro suave
  static const Color racingOrangeDark = Color(0xFFE55100); // Laranja escuro suave
  static const Color racingOrangeAccent = Color(0xFFFF9A6B); // Laranja accent suave
  
  // Cores de status - SUAVES PARA REDUZIR CANSAÇO VISUAL
  static const Color neonGreen = Color(0xFF66BB6A); // Verde suave (mais natural)
  static const Color alertRed = Color(0xFFE57373); // Vermelho suave (menos agressivo)
  static const Color statusOk = Color(0xFF66BB6A); // Verde suave para OK
  static const Color statusWarning = Color(0xFFFFB74D); // Laranja suave para aviso
  static const Color statusCritical = Color(0xFFE57373); // Vermelho suave para crítico
  
  // Cores para tema Dark - OTIMIZADAS PARA USO PROLONGADO (10-12h)
  // Tons mais escuros mas com menos contraste para reduzir fadiga ocular
  static const Color darkBackground = Color(0xFF1E1E1E); // Fundo escuro suave (menos cinza)
  static const Color darkSurface = Color(0xFF2D2D2D); // Superfície escura suave
  static const Color darkCard = Color(0xFF2A2A2A); // Card escuro suave
  static const Color darkTextPrimary = Color(0xFFE8E8E8); // Texto claro suave (não branco puro)
  static const Color darkTextSecondary = Color(0xFFB8B8B8); // Texto secundário suave
  
  // Cores para tema Light - OTIMIZADAS PARA USO PROLONGADO (10-12h)
  // Tons mais suaves e menos brilhantes para reduzir fadiga ocular
  static const Color lightBackground = Color(0xFFFAF8F5); // Fundo bege claro suave (não branco puro)
  static const Color lightSurface = Color(0xFFFFFEFB); // Superfície quase branca suave
  static const Color lightCard = Color(0xFFFFFEFB); // Card claro suave
  static const Color lightTextPrimary = Color(0xFF2D2D2D); // Texto escuro suave (não preto puro)
  static const Color lightTextSecondary = Color(0xFF6B6B6B); // Texto secundário suave
  
  // Cores auxiliares (mantidas para compatibilidade)
  static const Color darkGrafite = darkBackground;
  static const Color darkGray = Color(0xFF2A2A2A);
  static const Color mediumGray = Color(0xFF1E1E1E);
  static const Color lightGray = Color(0xFF2D2D2D);
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
}
