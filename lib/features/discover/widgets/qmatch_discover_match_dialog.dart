import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';

/// Result of the mutual-match success dialog.
enum DiscoverMatchDialogAction {
  openChat,
  continueDiscover,
}

/// Mutual-match dialog body (presentation only).
class QMatchDiscoverMatchDialogContent extends StatelessWidget {
  const QMatchDiscoverMatchDialogContent({
    super.key,
    required this.title,
    required this.body,
    required this.openChatLabel,
    required this.continueLabel,
    required this.onOpenChat,
    required this.onContinue,
  });

  final String title;
  final String body;
  final String openChatLabel;
  final String continueLabel;
  final VoidCallback onOpenChat;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      key: const Key('qmatch-discover-match-dialog'),
      emphasized: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.resonanceViolet.withValues(alpha: 0.22),
              border: Border.all(color: AppColors.borderGlow),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.softGold,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 24,
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
          const SizedBox(height: AppSpacing.lg),
          QCosmicButton(
            key: const Key('qmatch-discover-match-open-chat'),
            label: openChatLabel,
            onPressed: onOpenChat,
            variant: QCosmicButtonVariant.gold,
          ),
          const SizedBox(height: AppSpacing.sm),
          QCosmicButton(
            key: const Key('qmatch-discover-match-continue'),
            label: continueLabel,
            onPressed: onContinue,
            variant: QCosmicButtonVariant.ghost,
          ),
        ],
      ),
    );
  }
}

/// Mutual-match confirmation — Open chat (primary) or Continue (secondary).
Future<DiscoverMatchDialogAction?> showQMatchDiscoverMatchDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String openChatLabel,
  required String continueLabel,
}) {
  return showDialog<DiscoverMatchDialogAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: QMatchDiscoverMatchDialogContent(
          title: title,
          body: body,
          openChatLabel: openChatLabel,
          continueLabel: continueLabel,
          onOpenChat: () =>
              Navigator.of(ctx).pop(DiscoverMatchDialogAction.openChat),
          onContinue: () =>
              Navigator.of(ctx).pop(DiscoverMatchDialogAction.continueDiscover),
        ),
      );
    },
  );
}
