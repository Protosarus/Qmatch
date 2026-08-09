import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';

/// Empty Messages inbox — conversations appear after a mutual match.
///
/// iOS-dock frosted glass (same recipe as bottom nav) — Messages empty only.
class QMatchMessagesEmptyState extends StatelessWidget {
  const QMatchMessagesEmptyState({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('qmatch-messages-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ClipRRect(
          borderRadius: AppRadii.cardBorder,
          child: BackdropFilter(
            // Soft frost only — keep star points visible through the glass.
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadii.cardBorder,
                color: const Color(0xFF141A2E).withValues(alpha: 0.22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPaddingComfortable),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.resonanceViolet.withValues(alpha: 0.16),
                      border: Border.all(
                        color: QMatchGlassIconButton.coolBorder,
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recoverable Messages stream/query error.
class QMatchMessagesErrorState extends StatelessWidget {
  const QMatchMessagesErrorState({
    super.key,
    required this.title,
    required this.body,
    this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String body;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('qmatch-messages-error'),
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
                  color: AppColors.danger.withValues(alpha: 0.14),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.danger.withValues(alpha: 0.9),
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
              if (onRetry != null && retryLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                QCosmicButton(
                  key: const Key('qmatch-messages-error-retry'),
                  label: retryLabel!,
                  onPressed: onRetry,
                  variant: QCosmicButtonVariant.primary,
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
