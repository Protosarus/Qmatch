import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Visual style for [QCosmicButton].
enum QCosmicButtonVariant {
  /// Violet → indigo → electric blue fill.
  primary,

  /// Soft → warm gold fill.
  gold,

  /// Transparent with gold outline.
  ghost,
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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final QCosmicButtonVariant variant;
  final bool expanded;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final child = _ButtonFace(
      label: label,
      icon: icon,
      variant: variant,
      enabled: _enabled,
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.buttonBorder,
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
  });

  final String label;
  final IconData? icon;
  final QCosmicButtonVariant variant;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isGhost = variant == QCosmicButtonVariant.ghost;
    final gradient = switch (variant) {
      QCosmicButtonVariant.primary => AppGradients.primaryActionGradient,
      QCosmicButtonVariant.gold => AppGradients.goldActionGradient,
      QCosmicButtonVariant.ghost => null,
    };

    final foreground = isGhost
        ? AppColors.buttonText
        : (variant == QCosmicButtonVariant.gold
            ? AppColors.cosmicBlack
            : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.buttonHorizontal,
        vertical: AppSpacing.buttonVertical,
      ),
      decoration: BoxDecoration(
        gradient: isGhost ? null : gradient,
        color: isGhost ? Colors.transparent : null,
        borderRadius: AppRadii.buttonBorder,
        border: Border.all(
          color: isGhost ? AppColors.buttonOutline : AppColors.borderSubtle,
          width: isGhost ? 2 : 1,
        ),
        boxShadow: !isGhost && enabled && variant == QCosmicButtonVariant.gold
            ? AppShadows.goldGlow
            : null,
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
