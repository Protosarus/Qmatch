import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Soft glow / elevation tokens for Premium Cosmic Minimal (DS-0).
///
/// Prefer luminous 1px borders ([AppColors.borderSubtle] / [AppColors.borderGlow])
/// over heavy Material drop shadows. Use these sparingly — max one glow focus
/// per viewport (e.g. CosmicProfileHero halo later).
class AppShadows {
  AppShadows._();

  /// Quiet lift for glass cards (almost flat).
  static List<BoxShadow> get glassCard => [
        BoxShadow(
          color: AppColors.cosmicBlack.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Soft gold glow for primary CTA focus / match moments.
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.softGold.withValues(alpha: 0.22),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset.zero,
        ),
      ];

  /// Violet / indigo atmospheric glow (hero halo / Frequency peak — static token).
  static List<BoxShadow> get cosmicGlow => [
        BoxShadow(
          color: AppColors.resonanceViolet.withValues(alpha: 0.28),
          blurRadius: 28,
          spreadRadius: 0,
          offset: Offset.zero,
        ),
        BoxShadow(
          color: AppColors.electricBlue.withValues(alpha: 0.12),
          blurRadius: 40,
          spreadRadius: 2,
          offset: Offset.zero,
        ),
      ];

  /// Dialog / sheet soft presence (restrained).
  static List<BoxShadow> get dialog => [
        BoxShadow(
          color: AppColors.softGold.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}
