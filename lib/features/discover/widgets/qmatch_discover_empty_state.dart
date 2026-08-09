import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';

/// Modern empty state when the Discover feed has no further candidates.
class QMatchDiscoverEmptyState extends StatelessWidget {
  const QMatchDiscoverEmptyState({
    super.key,
    required this.title,
    required this.body,
    required this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String body;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('qmatch-discover-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: QGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.resonanceViolet.withValues(alpha: 0.22),
                  border: Border.all(
                    color: QMatchGlassIconButton.coolBorder,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: QMatchGlassIconButton.iconDefault,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                QCosmicButton(
                  key: const Key('qmatch-discover-empty-retry'),
                  label: retryLabel,
                  onPressed: onRetry,
                  variant: QCosmicButtonVariant.glass,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
