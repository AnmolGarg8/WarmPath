import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WarmPathColors {
  static const Color darkIndigo = Color(0xFF16163A);
  static const Color deepIndigo = Color(0xFF2B2D6E);
  static const Color coral = Color(0xFFFF6B4A);
  static const Color teal = Color(0xFF0FB5A5);
  static const Color successGreen = Color(0xFF15803D);
  static const Color amber = Color(0xFFF5A524);
  static const Color slate = Color(0xFF64748B);
  static const Color surface = Color(0xFFEEF1F8);
  static const Color white = Color(0xFFFFFFFF);
}

class WarmPathTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: WarmPathColors.surface,
      primaryColor: WarmPathColors.coral,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: WarmPathColors.darkIndigo,
        displayColor: WarmPathColors.darkIndigo,
      ),
      cardTheme: CardTheme(
        color: WarmPathColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WarmPathColors.coral,
          foregroundColor: WarmPathColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
