import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../utils/conversation_identity_format.dart';
import 'qmatch_conversation_avatar.dart';
import 'qmatch_unread_indicator.dart';

/// Presentation-only conversation row. No Firebase / scoring.
class QMatchConversationTile extends StatelessWidget {
  const QMatchConversationTile({
    super.key,
    required this.displayName,
    required this.previewText,
    required this.onTap,
    this.age,
    this.photoUrl,
    this.photoImageProvider,
    this.timestampText,
    this.unreadCount = 0,
    this.avatarSemanticLabel,
    this.unreadSemanticLabel,
    this.rowSemanticLabel,
  });

  final String displayName;
  final int? age;
  final String? photoUrl;
  final ImageProvider? photoImageProvider;
  final String previewText;
  final String? timestampText;
  final int unreadCount;
  final VoidCallback onTap;
  final String? avatarSemanticLabel;
  final String? unreadSemanticLabel;
  final String? rowSemanticLabel;

  bool get _hasUnread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final identity = formatConversationIdentity(
          name: displayName,
          age: age,
        ) ??
        displayName.trim();

    final nameWeight = _hasUnread ? FontWeight.w700 : FontWeight.w600;
    final previewWeight = _hasUnread ? FontWeight.w600 : FontWeight.w400;

    return Semantics(
      key: const Key('qmatch-conversation-tile'),
      button: true,
      label: rowSemanticLabel ?? identity,
      child: QGlassCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              QMatchConversationAvatar(
                photoUrl: photoUrl,
                imageProvider: photoImageProvider,
                semanticLabel: avatarSemanticLabel ?? identity,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key: const Key('qmatch-conversation-identity'),
                            identity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: nameWeight,
                            ),
                          ),
                        ),
                        if (timestampText != null &&
                            timestampText!.trim().isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            key: const Key('qmatch-conversation-timestamp'),
                            timestampText!,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs + 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key: const Key('qmatch-conversation-preview'),
                            previewText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: _hasUnread
                                  ? AppColors.textPrimary
                                      .withValues(alpha: 0.88)
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: previewWeight,
                            ),
                          ),
                        ),
                        if (_hasUnread) ...[
                          const SizedBox(width: AppSpacing.xs),
                          QMatchUnreadIndicator(
                            count: unreadCount,
                            semanticLabel:
                                unreadSemanticLabel ?? 'Unread $unreadCount',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin divider spacing between conversation tiles.
class QMatchConversationListSeparator extends StatelessWidget {
  const QMatchConversationListSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: AppSpacing.sm);
  }
}
