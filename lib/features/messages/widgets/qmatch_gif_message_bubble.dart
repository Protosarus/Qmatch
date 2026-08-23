import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'qmatch_message_timestamp.dart';

class QMatchGifMessageBubble extends StatelessWidget {
  const QMatchGifMessageBubble({
    super.key,
    required this.gifUrl,
    required this.isOutgoing,
    this.timestampText,
  });

  final String gifUrl;
  final bool isOutgoing;
  final String? timestampText;

  Future<void> _openPreview(
    BuildContext context,
    String url,
  ) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
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
    final url = gifUrl.trim();
    if (url.isEmpty) {
      return const SizedBox.shrink(
        key: Key('qmatch-chat-gif-empty'),
      );
    }

    final availableWidth = MediaQuery.sizeOf(context).width * 0.52;
    final maxBubbleWidth = availableWidth > 195 ? 195.0 : availableWidth;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isOutgoing ? 18 : 6),
      bottomRight: Radius.circular(isOutgoing ? 6 : 18),
    );

    return Align(
      key: Key(
        isOutgoing ? 'qmatch-chat-gif-out' : 'qmatch-chat-gif-in',
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
              key: const Key('qmatch-chat-gif-open-preview'),
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
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxBubbleWidth,
                      maxHeight: 150,
                    ),
                    child: Image.network(
                      url,
                      key: const Key('qmatch-chat-gif-image'),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) {
                        return SizedBox(
                          width: maxBubbleWidth,
                          height: 120,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.textMuted,
                            ),
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
