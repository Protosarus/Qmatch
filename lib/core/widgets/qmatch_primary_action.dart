import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum QMatchPrimaryActionTone {
  standard,
  destructive,
}

/// Shared restrained primary action for modern QMatch flows.
class QMatchPrimaryAction extends StatelessWidget {
  const QMatchPrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.semanticLabel,
    this.tone = QMatchPrimaryActionTone.standard,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;
  final String? semanticLabel;
  final QMatchPrimaryActionTone tone;

  bool get _interactive => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == QMatchPrimaryActionTone.destructive;
    final foreground = AppColors.textPrimary;
    final borderColor = isDestructive
        ? AppColors.danger.withValues(alpha: 0.45)
        : const Color(0x66A8B0D0);
    final Gradient fillGradient = isDestructive
        ? LinearGradient(
            colors: [
              AppColors.danger.withValues(alpha: 0.26),
              AppColors.deepIndigo.withValues(alpha: 0.92),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A2550),
              AppColors.deepIndigo,
              Color(0xFF1A2240),
            ],
          );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: semanticLabel ?? label,
      child: Opacity(
        opacity: _interactive ? 1 : AppColors.disabledOpacity,
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _interactive ? onPressed : null,
              borderRadius: AppRadii.buttonBorder,
              splashColor: AppColors.softGold.withValues(alpha: 0.14),
              highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.10),
              child: Ink(
                height: 52,
                decoration: BoxDecoration(
                  gradient: fillGradient,
                  color: AppColors.glassSurfaceStrong,
                  borderRadius: AppRadii.buttonBorder,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: (isDestructive
                              ? AppColors.danger
                              : AppColors.resonanceViolet)
                          .withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: loading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: foreground,
                            ),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  size: 20,
                                  color: isDestructive
                                      ? foreground
                                      : const Color(0xFFE8EBF8),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: foreground,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
