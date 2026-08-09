import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Shared cosmic chrome for profile setup / display-name gate screens.
///
/// Accents follow Frequency question language (lavender / cool glass), not
/// flat soft-gold text fills.
class ProfileSetupChrome {
  ProfileSetupChrome._();

  static const String cosmicBackgroundAsset =
      'assets/images/welcome_cosmic_background.png';

  /// Frequency progress-label lavender.
  static const Color accentLabel = Color(0xFFDAC8ED);

  /// Cool glass icon / chevron (matches [QMatchGlassIconButton]).
  static const Color accentIcon = Color(0xFFD7DCF2);

  /// Unselected glass border (Frequency option row).
  static const Color borderIdle = Color(0x554F4D79);

  /// Selected / focused cool border.
  static const Color borderFocus = Color(0x88C4B5E8);

  /// Readable glass fill (matches assessment complete indicator cards).
  static Color get fieldFill => AppColors.surface.withValues(alpha: 0.55);

  static TextStyle stepTitleStyle({double fontSize = 26}) =>
      GoogleFonts.playfairDisplay(
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle stepSubtitleStyle({double fontSize = 15}) =>
      GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: fontSize,
        height: 1.4,
      );

  /// Stronger subtitle for lines that sit on busy nebula areas.
  static TextStyle emphasizedSubtitleStyle() => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Soft opaque wash behind a single subtitle phrase only.
  static Widget highlightedSubtitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C14).withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(text, style: emphasizedSubtitleStyle()),
        ),
      ),
    );
  }

  static TextStyle labelStyle() => GoogleFonts.inter(
        color: accentLabel,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  static TextStyle fieldTextStyle() => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  /// Brighter than [AppColors.textMuted] so placeholders stay readable on glass.
  static TextStyle hintStyle() => GoogleFonts.inter(
        color: const Color(0xFFC4C4D4),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      );

  static Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: labelStyle()),
    );
  }

  static InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: hintStyle(),
      filled: true,
      fillColor: fieldFill,
      border: OutlineInputBorder(
        borderRadius: AppRadii.buttonBorder,
        borderSide: const BorderSide(color: borderIdle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.buttonBorder,
        borderSide: const BorderSide(color: borderIdle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.buttonBorder,
        borderSide: const BorderSide(color: borderFocus, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }

  static BoxDecoration glassFieldDecoration({bool emphasized = false}) {
    return BoxDecoration(
      color: fieldFill,
      borderRadius: AppRadii.buttonBorder,
      border: Border.all(
        color: emphasized ? borderFocus : borderIdle,
        width: emphasized ? 1.2 : 1,
      ),
    );
  }

  /// Selected chip / option fill — Frequency answer gradient language.
  static BoxDecoration selectedChipDecoration() {
    return BoxDecoration(
      borderRadius: AppRadii.pillBorder,
      gradient: const LinearGradient(
        colors: [
          Color(0xB34C25C9),
          Color(0xA06D34DA),
          Color(0x99D89C47),
        ],
      ),
      border: Border.all(color: const Color(0x99F2D08A)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x554D25D2),
          blurRadius: 10,
        ),
      ],
    );
  }

  static BoxDecoration idleChipDecoration() {
    return BoxDecoration(
      color: fieldFill,
      borderRadius: AppRadii.pillBorder,
      border: Border.all(color: borderIdle),
    );
  }
}
