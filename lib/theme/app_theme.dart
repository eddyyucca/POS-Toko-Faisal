import 'package:flutter/material.dart';

class AppColors {
  static const Color sidebar = Color(0xFF1B3A1C); // dark green
  static const Color sidebarActive = Color(0xFF28522A);
  static const Color primary = Color(0xFF4A8540);       // hijau daun
  static const Color primaryDark = Color(0xFF386630);   // hijau gelap
  static const Color primaryLight = Color(0xFF5EA352);  // hijau terang
  static const Color accent = Color(0xFF689F38);        // hijau terang/olive
  static const Color accentLight = Color(0xFF8BC34A);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFBC02D);       // kuning (bukan orange)
  static const Color background = Color(0xFFF7FBF7);    // hijau krem sangat terang
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B3A1C);   // dark green text
  static const Color textSecondary = Color(0xFF7B947E);
  static const Color border = Color(0xFFE1EAE1);
  static const Color cardShadow = Color(0x144A8540);    // shadow hijau tipis
  static const Color primaryLightBg = Color(0xFFE8F5E9);   // latar hijau sangat terang
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
