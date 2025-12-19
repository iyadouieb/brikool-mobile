import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC107), brightness: Brightness.light),
      textTheme: GoogleFonts.interTextTheme(),
      primaryColor: const Color(0xFFFFC107),
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFC107),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        selectedColor: const Color(0xFFFFC107),
        labelStyle: const TextStyle(color: Colors.black),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFFFFC107), // yellow accent
        secondary: const Color(0xFFFFC107),
        background: const Color(0xFF0B0B0D),
        surface: const Color(0xFF121213),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: const Color(0xFF0B0B0D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0B0D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF141416),
      cardTheme: const CardThemeData(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0B0B0D),
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey[400],
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFF141416),
        selectedColor: const Color(0xFFFFC107),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
