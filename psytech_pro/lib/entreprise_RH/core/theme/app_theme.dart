import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radius = 6;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.turquoise,
        primary: AppColors.turquoise,
        secondary: AppColors.navy,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    // On passe uniquement le nom de la police (String) pour éviter le
    // conflit de types TextTheme entre flutter et google_fonts.
    final fontFamily = GoogleFonts.inter().fontFamily;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textSecondary.withValues(alpha: 0.8),
        ),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.turquoise, 1.4),
        errorBorder: border(AppColors.error),
        focusedErrorBorder: border(AppColors.error, 1.4),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.turquoise,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.disabledBg,
          disabledForegroundColor: AppColors.disabledText,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
