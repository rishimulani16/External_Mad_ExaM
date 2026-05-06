import 'package:flutter/material.dart';

/// Centralised Material 3 theme for AppointQ.
/// All colour decisions live here; screens/widgets reference
/// Theme.of(context) — never hard-code colours in widget trees.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand Colour Seeds
  // ---------------------------------------------------------------------------
  static const Color _brandPrimary = Color(0xFF4A6FA5);    // Calm blue
  static const Color _brandSecondary = Color(0xFF47B39C);  // Teal accent
  static const Color _brandError = Color(0xFFE84855);

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandPrimary,
          secondary: _brandSecondary,
          error: _brandError,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          filled: true,
        ),
      );

  // ---------------------------------------------------------------------------
  // Dark Theme  (placeholder — can be fleshed out in Milestone 5)
  // ---------------------------------------------------------------------------
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandPrimary,
          secondary: _brandSecondary,
          error: _brandError,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      );
}
