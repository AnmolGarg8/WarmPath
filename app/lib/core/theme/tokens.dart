import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color textDark = Color(0xFF16163A);      // Indigo
  static const Color deepIndigo = Color(0xFF2B2D6E);
  static const Color primaryAction = Color(0xFFFF6B4A); // Coral
  static const Color teal = Color(0xFF0FB5A5);
  static const Color successGreen = Color(0xFF15803D);
  static const Color amber = Color(0xFFF5A524);
  static const Color slate = Color(0xFF64748B);
  static const Color surface = Color(0xFFEEF1F8);
  static const Color white = Color(0xFFFFFFFF);

  // Rating Bands
  static const Color bandRising = Color(0xFF64748B);
  static const Color bandTrusted = Color(0xFF0FB5A5);
  static const Color bandTopRated = Color(0xFFF5A524);
}

class AppRadii {
  static const BorderRadius card = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius badge = BorderRadius.all(Radius.circular(8.0));
}

ThemeData getAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepIndigo,
      primary: AppColors.primaryAction,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
    ),
    textTheme: GoogleFonts.interTextTheme(),
  );
}
