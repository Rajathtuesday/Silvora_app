import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SilvoraColors {
  // Backgrounds
  static const bg         = Color(0xFF080910);
  static const surface    = Color(0xFF0F1018);
  static const card       = Color(0xFF141620);
  static const card2      = Color(0xFF1A1D2E);

  // Brand
  static const primary      = Color(0xFF5B4FE8);
  static const primaryLight = Color(0xFF7B6FF8);
  static const primaryGlow  = Color(0x405B4FE8);

  // Accent
  static const gold      = Color(0xFFD4AF6A);
  static const goldLight = Color(0xFFE8C87A);

  // Semantic
  static const success = Color(0xFF3DD68C);
  static const error   = Color(0xFFF05B6D);
  static const warn    = Color(0xFFFFB84D);

  // Text
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8A8FAA);
  static const textMuted     = Color(0xFF4A4F6A);

  // Borders
  static const border = Color(0x12FFFFFF);
  static const borderFocus = Color(0x405B4FE8);
}

class SilvoraTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SilvoraColors.bg,
      textTheme: GoogleFonts.dmSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: SilvoraColors.textPrimary,
        displayColor: SilvoraColors.textPrimary,
      ),

      colorScheme: const ColorScheme.dark(
        primary: SilvoraColors.primary,
        secondary: SilvoraColors.gold,
        surface: SilvoraColors.surface,
        error: SilvoraColors.error,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: SilvoraColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: SilvoraColors.textSecondary),
      ),

      cardTheme: CardThemeData(
        color: SilvoraColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SilvoraColors.border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SilvoraColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SilvoraColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SilvoraColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SilvoraColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: SilvoraColors.textMuted,
          fontFamily: 'Space Mono',
          fontSize: 11,
          letterSpacing: 0.8,
        ),
        hintStyle: const TextStyle(color: SilvoraColors.textMuted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SilvoraColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          elevation: 0,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: SilvoraColors.card2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SilvoraColors.border),
        ),
        contentTextStyle: const TextStyle(
          color: SilvoraColors.textPrimary,
          fontFamily: 'DM Sans',
          fontSize: 13,
        ),
        actionTextColor: SilvoraColors.primaryLight,
      ),
    );
  }
}
