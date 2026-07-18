import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Premium Cosmic Minimal gradient tokens (DS-0).
///
/// Neo Lab channel gradients ([iqGradient], [eqGradient], [frequencyGradient],
/// [compatibilityRingGradient]) are for assessment / compatibility viz only.
class AppGradients {
  AppGradients._();

  static const LinearGradient cosmicBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.midnightNavy,
      AppColors.cosmicBlack,
      Color(0xFF08060F),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient primaryActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.resonanceViolet,
      AppColors.deepIndigo,
      AppColors.electricBlue,
    ],
  );

  static const LinearGradient goldActionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.softGold,
      AppColors.warmGold,
    ],
  );

  /// Soft glass wash for cards (pair with [AppColors.glassSurface]).
  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x14A8B0D0),
      Color(0x0A000000),
    ],
  );

  /// Future CosmicProfileHero orbital halo (static token; no motion yet).
  static const SweepGradient profileHeroGlowGradient = SweepGradient(
    colors: [
      AppColors.resonanceViolet,
      AppColors.electricBlue,
      AppColors.deepIndigo,
      AppColors.softGold,
      AppColors.resonanceViolet,
    ],
  );

  // ── Neo Lab viz (assessment / compatibility only) ─────────────────────────

  static const LinearGradient compatibilityRingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.resonanceViolet,
      AppColors.electricBlue,
      AppColors.softGold,
    ],
  );

  static const LinearGradient iqGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.vizIq,
      AppColors.electricBlue,
    ],
  );

  static const LinearGradient eqGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.vizEq,
      AppColors.resonanceViolet,
    ],
  );

  static const LinearGradient frequencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.vizFrequency,
      AppColors.cosmicPurple,
    ],
  );
}
