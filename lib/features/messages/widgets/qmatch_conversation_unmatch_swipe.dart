import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/qmatch_feedback.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Left-swipe (end-to-start) to unmatch. Presentation only — caller runs
/// the existing unmatch flow. No thread/message deletes.
class QMatchConversationUnmatchSwipe extends StatelessWidget {
  const QMatchConversationUnmatchSwipe({
    super.key,
    required this.threadId,
    required this.child,
    required this.onUnmatch,
  });

  final String threadId;
  final Widget child;
  final Future<void> Function() onUnmatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dismissible(
      key: Key('qmatch-messages-unmatch-swipe-$threadId'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.chatUnmatchDialogTitle,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              l10n.chatUnmatchDialogBody,
              style: GoogleFonts.inter(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                key: const Key('qmatch-messages-unmatch-confirm'),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.chatMenuUnmatch,
                  style: GoogleFonts.inter(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return false;
        try {
          await onUnmatch();
          return true;
        } catch (_) {
          if (context.mounted) {
            QMatchFeedback.show(
              context,
              message: l10n.chatActionFailed,
              type: QMatchFeedbackType.error,
            );
          }
          return false;
        }
      },
      background: const SizedBox.shrink(),
      secondaryBackground: ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: ColoredBox(
          key: const Key('qmatch-messages-swipe-unmatch-bg'),
          color: AppColors.danger.withValues(alpha: 0.90),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.heart_broken_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key: const Key('qmatch-messages-swipe-unmatch-label'),
                    l10n.chatMenuUnmatch,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
