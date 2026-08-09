import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../qmatch_glass_icon_button.dart';

/// Visual style for [QCosmicButton].
enum QCosmicButtonVariant {
  /// Violet → indigo → electric blue fill.
  primary,

  /// Soft → warm gold fill.
  gold,

  /// Violet → soft gold (premium welcome / concept CTA).
  cosmic,

  /// Transparent with gold outline.
  ghost,

  /// Translucent navy glass — matches Profile / empty-state cards.
  glass,
}

/// Premium Cosmic CTA — static gradients only (no motion / paywall logic).
class QCosmicButton extends StatelessWidget {
  const QCosmicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = QCosmicButtonVariant.primary,
    this.expanded = true,
    this.pill = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final QCosmicButtonVariant variant;
  final bool expanded;

  /// Large pill radius (concept launch CTAs).
  final bool pill;

  /// Optional fixed height for oversized premium CTAs.
  final double? height;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final radius = pill ? AppRadii.pillBorder : AppRadii.buttonBorder;

    final child = _ButtonFace(
      label: label,
      icon: icon,
      variant: variant,
      enabled: _enabled,
      borderRadius: radius,
      height: height,
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        splashColor: AppColors.softGold.withValues(alpha: 0.15),
        child: child,
      ),
    );

    final wrapped = Opacity(
      opacity: _enabled ? 1.0 : AppColors.disabledOpacity,
      child: button,
    );

    if (!expanded) return wrapped;
    return SizedBox(width: double.infinity, child: wrapped);
  }
}

class _ButtonFace extends StatelessWidget {
  const _ButtonFace({
    required this.label,
    required this.icon,
    required this.variant,
    required this.enabled,
    required this.borderRadius,
    required this.height,
  });

  final String label;
  final IconData? icon;
  final QCosmicButtonVariant variant;
  final bool enabled;
  final BorderRadius borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isGhost = variant == QCosmicButtonVariant.ghost;
    final isGlass = variant == QCosmicButtonVariant.glass;
    final gradient = switch (variant) {
      QCosmicButtonVariant.primary => AppGradients.primaryActionGradient,
      QCosmicButtonVariant.gold => AppGradients.goldActionGradient,
      QCosmicButtonVariant.cosmic => AppGradients.cosmicCtaGradient,
      QCosmicButtonVariant.ghost => null,
      QCosmicButtonVariant.glass => null,
    };

    final foreground = isGhost
        ? AppColors.buttonText
        : (isGlass
            ? QMatchGlassIconButton.iconDefault
            : (variant == QCosmicButtonVariant.gold
                ? AppColors.cosmicBlack
                : AppColors.textPrimary));

    final bloom = !isGhost && !isGlass && enabled
        ? (variant == QCosmicButtonVariant.cosmic
            ? [
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.softGold.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: Offset.zero,
                ),
              ]
            : (variant == QCosmicButtonVariant.gold
                ? AppShadows.goldGlow
                : null))
        : (isGlass && enabled
            ? [
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null);

    if (isGlass) {
      // Same surface language as Profile [QGlassCard] — no BackdropFilter.
      return Container(
        height: height,
        alignment: height != null ? Alignment.center : null,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonHorizontal,
          vertical: height != null ? 0 : AppSpacing.buttonVertical + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: AppColors.glassSurface,
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: bloom,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: AppGradients.glassCardGradient,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.35,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      alignment: height != null ? Alignment.center : null,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.buttonHorizontal,
        vertical: height != null ? 0 : AppSpacing.buttonVertical + 2,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        color: isGhost ? Colors.transparent : null,
        borderRadius: borderRadius,
        border: Border.all(
          color: isGhost
              ? AppColors.buttonOutline
              : (variant == QCosmicButtonVariant.cosmic
                  ? AppColors.softGold.withValues(alpha: 0.35)
                  : AppColors.borderSubtle),
          width: isGhost ? 2 : 1,
        ),
        boxShadow: bloom,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.35,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
