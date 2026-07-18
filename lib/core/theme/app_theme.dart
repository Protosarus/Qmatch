import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';

/// Centralized dark ThemeData for Premium Cosmic Minimal (DS-0).
///
/// Token-ready only: [main.dart] still uses a seed [ThemeData] so wiring this
/// in does not restyle screens until a later DS application phase.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.resonanceViolet,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.cosmicBlack,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      // Existing Playfair + Inter via google_fonts (no new font packages).
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.textGold,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: AppColors.textGold,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textGold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.buttonText,
          side: const BorderSide(color: AppColors.buttonOutline, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonHorizontal,
            vertical: AppSpacing.buttonVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonBorder,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.glassSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.glassSurfaceStrong,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.sheetBorder,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),

      dividerColor: AppColors.borderSubtle,
    );
  }
}
