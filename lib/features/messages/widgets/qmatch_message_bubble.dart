import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'qmatch_message_timestamp.dart';

/// Incoming / outgoing / system chat bubble (presentation only).
class QMatchMessageBubble extends StatelessWidget {
  const QMatchMessageBubble({
    super.key,
    required this.text,
    required this.isOutgoing,
    this.isSystem = false,
    this.timestampText,
    this.maxWidthFraction = 0.78,
  });

  final String text;
  final bool isOutgoing;
  final bool isSystem;
  final String? timestampText;
  final double maxWidthFraction;

  @override
  Widget build(BuildContext context) {
    final body = text.trim();
    if (body.isEmpty && !isSystem) {
      return const SizedBox.shrink(key: Key('qmatch-chat-bubble-empty'));
    }

    if (isSystem) {
      return Padding(
        key: const Key('qmatch-chat-bubble-system'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            ),
            child: Text(
              body.isEmpty ? '—' : body,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary.withValues(alpha: 0.95),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    final maxW = MediaQuery.sizeOf(context).width * maxWidthFraction;
    final bubbleColor = isOutgoing
        ? AppColors.resonanceViolet.withValues(alpha: 0.88)
        : AppColors.glassSurfaceStrong;
    final textColor =
        isOutgoing ? AppColors.textPrimary : AppColors.textPrimary;

    return Align(
      key: Key(isOutgoing ? 'qmatch-chat-bubble-out' : 'qmatch-chat-bubble-in'),
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment:
                isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOutgoing ? 18 : 6),
                    bottomRight: Radius.circular(isOutgoing ? 6 : 18),
                  ),
                  border: Border.all(
                    color: isOutgoing
                        ? AppColors.softGold.withValues(alpha: 0.22)
                        : AppColors.borderSubtle,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    body,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      height: 1.38,
                    ),
                  ),
                ),
              ),
              if (timestampText != null && timestampText!.trim().isNotEmpty)
                QMatchMessageTimestamp(
                  text: timestampText!.trim(),
                  alignEnd: isOutgoing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
