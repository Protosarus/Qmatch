import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'qmatch_message_timestamp.dart';

class QMatchImageMessageBubble extends StatelessWidget {
  const QMatchImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isOutgoing,
    this.timestampText,
  });

  final String imageUrl;
  final bool isOutgoing;
  final String? timestampText;

  Future<void> _openPreview(
    BuildContext context,
    String url,
  ) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(
                  tooltip: MaterialLocalizations.of(dialogContext)
                      .closeButtonTooltip,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    if (url.isEmpty) {
      return const SizedBox.shrink(
        key: Key('qmatch-chat-image-empty'),
      );
    }

    final availableWidth = MediaQuery.sizeOf(context).width * 0.64;
    final maxBubbleWidth = availableWidth > 240 ? 240.0 : availableWidth;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 6),
      bottomRight: Radius.circular(isOutgoing ? 6 : 18),
    );

    return Align(
      key: Key(
        isOutgoing ? 'qmatch-chat-image-out' : 'qmatch-chat-image-in',
      ),
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: const Key('qmatch-chat-image-open-preview'),
              onTap: () => _openPreview(context, url),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: isOutgoing
                          ? AppColors.softGold.withValues(alpha: 0.22)
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: SizedBox(
                    width: maxBubbleWidth,
                    height: 220,
                    child: Image.network(
                      url,
                      key: const Key('qmatch-chat-image'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textMuted,
                            size: 34,
                          ),
                        );
                      },
                    ),
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
    );
  }
}
