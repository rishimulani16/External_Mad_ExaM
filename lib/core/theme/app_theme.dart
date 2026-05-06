import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralised Material 3 theme for AppointQ.
///
/// Colour palette is inspired by the QueueEase design:
///   Primary   — Deep teal  #0D7377   (buttons, AppBar, active nav)
///   Background — Warm cream #F0EDE5  (scaffold background)
///   Surface    — White      #FFFFFF  (cards, inputs)
class AppTheme {
  AppTheme._();

  // ── Brand colours ───────────────────────────────────────────────────────────
  static const Color _teal      = Color(0xFF0D7377); // primary — deep teal
  static const Color _tealDark  = Color(0xFF095E62); // pressed / dark variant
  static const Color _cream     = Color(0xFFF0EDE5); // scaffold background
  static const Color _error     = Color(0xFFE84855);

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    final cs = ColorScheme.fromSeed(
      seedColor: _teal,
      primary: _teal,
      onPrimary: Colors.white,
      secondary: _teal,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A1A),
      error: _error,
      brightness: Brightness.light,
    ).copyWith(
      // Warm cream background applied via scaffoldBackgroundColor below.
      surfaceContainerHighest: const Color(0xFFEAE7DF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _cream,
      fontFamily: 'Roboto',

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: _tealDark,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── FilledButton ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _teal,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: _teal, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── ElevatedButton ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),

      // ── Input ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: _teal, width: 2),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── BottomNavigationBar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _teal,
        unselectedItemColor: Color(0xFF9CA3AF),
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),

      // ── FilterChip ──────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),

      // ── SnackBar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ── Dark Theme (respects teal brand) ────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          primary: const Color(0xFF4DB6BC),
          onPrimary: Colors.black,
          error: _error,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF0A3A3D),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF4DB6BC),
          unselectedItemColor: Color(0xFF6B7280),
          type: BottomNavigationBarType.fixed,
        ),
      );
}
