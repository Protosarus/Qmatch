import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';

/// Pass / Like action bar for Discover. Handlers are provided by the screen.
class QMatchDiscoverActionBar extends StatelessWidget {
  const QMatchDiscoverActionBar({
    super.key,
    required this.passLabel,
    required this.likeLabel,
    required this.onPass,
    required this.onLike,
    required this.isActionLoading,
  });

  final String passLabel;
  final String likeLabel;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('qmatch-discover-action-bar'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              enabled: onPass != null,
              label: passLabel,
              child: OutlinedButton(
                key: const Key('qmatch-discover-pass'),
                onPressed: onPass,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  disabledForegroundColor:
                      AppColors.textMuted.withValues(alpha: 0.55),
                  side: BorderSide(
                    color: AppColors.borderSubtle.withValues(alpha: 0.9),
                  ),
                  minimumSize: const Size(48, 52),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadii.buttonBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close_rounded, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        passLabel,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              button: true,
              enabled: onLike != null,
              label: likeLabel,
              child: SizedBox(
                key: const Key('qmatch-discover-like'),
                height: 52,
                child: isActionLoading
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.buttonBorder,
                          color: AppColors.resonanceViolet.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : QCosmicButton(
                        label: likeLabel,
                        icon: Icons.favorite_rounded,
                        onPressed: onLike,
                        variant: QCosmicButtonVariant.cosmic,
                        height: 52,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
