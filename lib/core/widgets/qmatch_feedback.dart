import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/qmatch_main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum QMatchFeedbackType { error, success, warning, info }

/// Single QMatch transient feedback API.
///
/// Replaces default Material SnackBars. Persistent auth/form banners and
/// confirmation dialogs stay where they are.
class QMatchFeedback {
  QMatchFeedback._();

  static const Key bannerKey = Key('qmatch-feedback-banner');
  static const Key messageKey = Key('qmatch-feedback-message');
  static const Key actionKey = Key('qmatch-feedback-action');

  static const Color _surface = Color(0xF5111629);

  static Duration durationFor(QMatchFeedbackType type,
      {bool hasAction = false}) {
    if (hasAction) return const Duration(seconds: 6);
    switch (type) {
      case QMatchFeedbackType.error:
      case QMatchFeedbackType.warning:
        return const Duration(seconds: 4);
      case QMatchFeedbackType.success:
      case QMatchFeedbackType.info:
        return const Duration(seconds: 3);
    }
  }

  static IconData iconFor(QMatchFeedbackType type) {
    switch (type) {
      case QMatchFeedbackType.error:
        return Icons.error_outline_rounded;
      case QMatchFeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case QMatchFeedbackType.warning:
        return Icons.warning_amber_rounded;
      case QMatchFeedbackType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color accentFor(QMatchFeedbackType type) {
    switch (type) {
      case QMatchFeedbackType.error:
        return AppColors.error;
      case QMatchFeedbackType.success:
        return AppColors.success;
      case QMatchFeedbackType.warning:
        return const Color(0xFFDAC8ED);
      case QMatchFeedbackType.info:
        return AppColors.resonanceViolet;
    }
  }

  static String semanticLabelFor(QMatchFeedbackType type) {
    switch (type) {
      case QMatchFeedbackType.error:
        return 'Error';
      case QMatchFeedbackType.success:
        return 'Success';
      case QMatchFeedbackType.warning:
        return 'Warning';
      case QMatchFeedbackType.info:
        return 'Info';
    }
  }

  /// Replaces any current transient banner. Does not stack duplicates.
  static void show(
    BuildContext context, {
    required String message,
    QMatchFeedbackType type = QMatchFeedbackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onTap,
    Duration? duration,
    bool compact = false,
    ScaffoldMessengerState? messenger,
  }) {
    final host = messenger ?? ScaffoldMessenger.maybeOf(context);
    if (host == null) return;
    final text = message.trim();
    if (text.isEmpty) return;

    final mediaContext = host.context.mounted ? host.context : context;
    final media = MediaQuery.maybeOf(mediaContext);
    final keyboard = media?.viewInsets.bottom ?? 0;
    final safeBottom = media?.padding.bottom ?? 0;
    // Match QMatchMainShell: navContentHeight + safe + lg, then a small gap.
    final navLift =
        compact ? 0.0 : QMatchMainShell.navContentHeight + AppSpacing.lg;
    final bottomMargin =
        AppSpacing.md + (keyboard > 0 ? 0.0 : safeBottom + navLift);

    final accent = accentFor(type);
    final hasAction = (actionLabel != null &&
            actionLabel.trim().isNotEmpty &&
            onAction != null) ||
        onTap != null;

    host
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            bottomMargin,
          ),
          duration: duration ?? durationFor(type, hasAction: hasAction),
          dismissDirection: DismissDirection.down,
          content: _QMatchFeedbackBanner(
            message: text,
            type: type,
            accent: accent,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    host.hideCurrentSnackBar();
                    onAction();
                  },
            onTap: onTap,
          ),
        ),
      );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }
}

class _QMatchFeedbackBanner extends StatelessWidget {
  const _QMatchFeedbackBanner({
    required this.message,
    required this.type,
    required this.accent,
    this.actionLabel,
    this.onAction,
    this.onTap,
  });

  final String message;
  final QMatchFeedbackType type;
  final Color accent;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = QMatchFeedback.semanticLabelFor(type);
    final body = Semantics(
      container: true,
      liveRegion: true,
      label: '$label. $message',
      child: Material(
        key: QMatchFeedback.bannerKey,
        color: QMatchFeedback._surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                QMatchFeedback.iconFor(type),
                key: Key('qmatch-feedback-icon-${type.name}'),
                color: accent,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  key: QMatchFeedback.messageKey,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF3EFFA),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              if (actionLabel != null &&
                  actionLabel!.trim().isNotEmpty &&
                  onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  key: QMatchFeedback.actionKey,
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDAC8ED),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
