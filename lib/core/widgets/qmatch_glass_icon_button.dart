import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Shared glass icon control for Profile / Settings navigation actions.
///
/// Control bodies stay dark-purple/glass. Gold is reserved for pressed/focus
/// feedback only — never as a solid fill in the default state.
class QMatchGlassIconButton extends StatelessWidget {
  const QMatchGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.size = 44,
    this.iconSize = 20,
    this.circular = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double size;
  final double iconSize;
  final bool circular;

  static const Color iconDefault = Color(0xFFD7DCF2);
  static const Color glassFill = Color(0xE61A2040);
  static const Color coolBorder = Color(0x66A8B0D0);

  @override
  Widget build(BuildContext context) {
    final shape = circular
        ? const CircleBorder(side: BorderSide(color: coolBorder))
        : RoundedRectangleBorder(
            borderRadius: AppRadii.buttonBorder,
            side: const BorderSide(color: coolBorder),
          );
    final borderRadius =
        circular ? BorderRadius.circular(size) : AppRadii.buttonBorder;

    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: glassFill,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          borderRadius: borderRadius,
          onTap: onPressed,
          splashColor: AppColors.softGold.withValues(alpha: 0.18),
          highlightColor: AppColors.softGold.withValues(alpha: 0.08),
          child: Icon(
            icon,
            size: iconSize,
            color: iconDefault,
          ),
        ),
      ),
    );

    final labeled = semanticLabel == null
        ? button
        : Semantics(
            button: true,
            label: semanticLabel,
            child: button,
          );

    if (tooltip == null) return labeled;
    return Tooltip(message: tooltip!, child: labeled);
  }
}
