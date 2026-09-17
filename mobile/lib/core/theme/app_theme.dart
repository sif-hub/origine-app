// lib/core/theme/app_theme.dart
// Identité visuelle ORIGINE — vert forêt camerounaise + or savane

import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color vertForet     = Color(0xFF0A3D2E); // vert profond
  static const Color vertClair     = Color(0xFF1D7A4C); // vert moyen
  static const Color vertTres      = Color(0xFF2E9D64); // vert accent
  static const Color or            = Color(0xFFC9942C); // or / savane
  static const Color orClair       = Color(0xFFE3B34F);

  // Neutres
  static const Color creme         = Color(0xFFF7F3EC);
  static const Color blanc         = Color(0xFFFFFFFF);
  static const Color noir          = Color(0xFF1B1B1B);
  static const Color gris          = Color(0xFF6B6B6B);
  static const Color grisClair     = Color(0xFFE5E1D8);

  // États
  static const Color succes        = Color(0xFF1D7A4C);
  static const Color erreur        = Color(0xFFA8311F);
  static const Color alerte        = Color(0xFFC9942C);

  // Surfaces sombres
  static const Color surfaceSombre = Color(0xFF062A20);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.vertForet,
      primary: AppColors.vertForet,
      secondary: AppColors.or,
      tertiary: AppColors.vertClair,
      surface: AppColors.blanc,
      background: AppColors.creme,
      error: AppColors.erreur,
      onPrimary: AppColors.blanc,
      onSecondary: AppColors.noir,
      onSurface: AppColors.noir,
      onBackground: AppColors.noir,
    ),

    fontFamily: 'Poppins',

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.vertForet,
      foregroundColor: AppColors.blanc,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.blanc,
      ),
    ),

    scaffoldBackgroundColor: AppColors.creme,

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.or,
        foregroundColor: AppColors.noir,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.vertForet,
        side: const BorderSide(color: AppColors.vertForet, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blanc,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grisClair),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.grisClair),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.or, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.erreur),
      ),
      labelStyle: const TextStyle(color: AppColors.gris),
      hintStyle: const TextStyle(color: AppColors.gris, fontSize: 14),
    ),

    cardTheme: CardThemeData(
      color: AppColors.blanc,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.grisClair),
      ),
      margin: EdgeInsets.zero,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.blanc,
      selectedItemColor: AppColors.vertForet,
      unselectedItemColor: AppColors.gris,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.noir),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.noir),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.noir),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.noir),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.noir),
      bodyLarge: TextStyle(fontSize: 15, color: AppColors.noir),
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.gris),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blanc),
    ),
  );
}
