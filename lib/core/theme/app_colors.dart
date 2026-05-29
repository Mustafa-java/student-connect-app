import 'package:flutter/material.dart';

/// Основная цветовая палитра приложения
/// Вдохновлена Instagram, но адаптирована для студенческой платформы
class AppColors {
  AppColors._();

  // Основные цвета
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFA5B4FC);
  
  // Акцентные цвета
  static const Color accent = Color(0xFF06B6D4); // Cyan
  static const Color accentDark = Color(0xFF0891B2);
  
  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Темная тема
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarkLight = Color(0xFF2A2A2A);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFE0E0E0);
  static const Color textDarkSecondary = Color(0xFF9E9E9E);
  
  // Светлая тема
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color surfaceLightDark = Color(0xFFE9ECEF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF1F1F1F);
  static const Color textLightSecondary = Color(0xFF6C757D);
  
  // Статусные цвета
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Цвета для UI элементов
  static const Color divider = Color(0xFF2D2D2D);
  static const Color dividerLight = Color(0xFFDEE2E6);
  static const Color skeleton = Color(0xFF2D2D2D);
  static const Color skeletonHighlight = Color(0xFF3D3D3D);
  
  // Цвета для навигации
  static const Color navSelected = primary;
  static const Color navUnselected = Color(0xFF6B7280);
  
  // Цвета для сообщений
  static const Color messageSent = Color(0xFF6366F1);
  static const Color messageReceived = Color(0xFF2A2A2A);
}
