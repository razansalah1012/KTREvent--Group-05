// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
    ),
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.smoochSans(
        color: AppColors.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.quicksand(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.quicksand(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
  );
}