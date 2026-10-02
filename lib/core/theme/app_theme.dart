import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF818CF8),
    brightness: Brightness.dark,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        scaffoldBackgroundColor: const Color(0xFF111318),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
