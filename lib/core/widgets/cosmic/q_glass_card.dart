import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Premium glassmorphism card (Cosmic Minimal).
///
/// Static surface only — no BackdropFilter / motion in DS-1.
class QGlassCard extends StatelessWidget {
  const QGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Stronger glass fill + gold-tinted border for focal cards.
  final bool emphasized;

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

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.glassSurfaceStrong
            : AppColors.glassSurface,
        borderRadius: AppRadii.cardBorder,
        border: Border.all(
          color: emphasized ? AppColors.borderGlow : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: emphasized ? AppShadows.goldGlow : AppShadows.glassCard,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppGradients.glassCardGradient,
          ),
          child: body,
        ),
      ),
    );
  }
}
