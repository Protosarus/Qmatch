import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Premium glassmorphism card (Cosmic Minimal).
class QGlassCard extends StatelessWidget {
  const QGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.emphasized = false,
    this.color,
    this.includeShadow = true,
    this.includeWash = true,
    this.starVisibleGlass = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Stronger glass fill + gold-tinted border for focal cards.
  final bool emphasized;

  /// Optional fill override (e.g. lighter profile / empty panels).
  final Color? color;

  /// Soft drop shadow under the card.
  final bool includeShadow;

  /// Light gradient wash over the fill.
  final bool includeWash;

  /// Soft blur + translucent navy so cosmic stars stay readable through the card
  /// (Profile / Discover empty language).
  final bool starVisibleGlass;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding:
          padding ?? const EdgeInsets.all(AppSpacing.cardPaddingComfortable),
      child: child,
    );

    final body = onTap == null
        ? padded
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.cardBorder,
              splashColor: AppColors.resonanceViolet.withValues(alpha: 0.12),
              highlightColor: AppColors.softGold.withValues(alpha: 0.06),
              child: padded,
            ),
          );

    if (starVisibleGlass) {
      final card = ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardBorder,
              color: const Color(0xFF141A2E).withValues(alpha: 0.22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 0.8,
              ),
            ),
            child: body,
          ),
        ),
      );
      if (margin == null) return card;
      return Padding(padding: margin!, child: card);
    }

    final fill = color ??
        (emphasized ? AppColors.glassSurfaceStrong : AppColors.glassSurface);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.cardBorder,
        border: Border.all(
          color: emphasized ? AppColors.borderGlow : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: includeShadow
            ? (emphasized ? AppShadows.goldGlow : AppShadows.glassCard)
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: includeWash
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppGradients.glassCardGradient,
                ),
                child: body,
              )
            : body,
      ),
    );
  }
}
