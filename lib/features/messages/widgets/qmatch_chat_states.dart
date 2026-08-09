import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';

/// Empty conversation — subtle invitation; wallpaper remains visible behind.
class QMatchChatEmptyState extends StatelessWidget {
  const QMatchChatEmptyState({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('qmatch-chat-empty'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: QGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.softGold.withValues(alpha: 0.85),
                size: 36,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 20,
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
    );
  }
}

/// Lightweight loading over the patterned wallpaper.
class QMatchChatLoadingState extends StatelessWidget {
  const QMatchChatLoadingState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('qmatch-chat-loading'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGold),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distinct recoverable error (no raw Firebase text).
class QMatchChatErrorState extends StatelessWidget {
  const QMatchChatErrorState({
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
      key: const Key('qmatch-chat-error'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: QGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger.withValues(alpha: 0.9),
                size: 36,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 20,
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
                  key: const Key('qmatch-chat-error-retry'),
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
