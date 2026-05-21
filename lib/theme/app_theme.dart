import 'package:flutter/material.dart';

class AppColors {
  // Dari logo: orange utama, navy gelap, hijau daun
  static const Color sidebar = Color(0xFF1C2B3A);
  static const Color sidebarActive = Color(0xFF243648);
  static const Color primary = Color(0xFFF7941D);       // orange logo
  static const Color primaryDark = Color(0xFFE07D0A);   // orange gelap
  static const Color primaryLight = Color(0xFFFFB347);  // orange terang
  static const Color accent = Color(0xFF4A8540);        // hijau daun
  static const Color accentLight = Color(0xFF5EA352);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color background = Color(0xFFFFF8F0);    // krem hangat
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1C2B3A);   // navy gelap
  static const Color textSecondary = Color(0xFF7B8794);
  static const Color border = Color(0xFFEAE0D5);
  static const Color cardShadow = Color(0x14F7941D);    // shadow orange tipis
  static const Color orangeLight = Color(0xFFFFF3E0);   // latar orange sangat terang
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
    );
  }
}
