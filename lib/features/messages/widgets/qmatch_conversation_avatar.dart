import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Conversation avatar with missing / error placeholders.
class QMatchConversationAvatar extends StatelessWidget {
  const QMatchConversationAvatar({
    super.key,
    required this.photoUrl,
    required this.semanticLabel,
    this.imageProvider,
    this.size = 52,
  });

  final String? photoUrl;
  final String semanticLabel;
  final ImageProvider? imageProvider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final hasProvider = imageProvider != null;
    final showPhoto = hasProvider || hasUrl;

    return Semantics(
      key: const Key('qmatch-conversation-avatar'),
      image: true,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: showPhoto
              ? Image(
                  image: imageProvider ?? NetworkImage(url!),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, __, ___) => const _AvatarPlaceholder(
                    key: Key('qmatch-conversation-avatar-error'),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const _AvatarPlaceholder(
                      key: Key('qmatch-conversation-avatar-loading'),
                      showSpinner: true,
                    );
                  },
                )
              : const _AvatarPlaceholder(
                  key: Key('qmatch-conversation-avatar-missing'),
                ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({
    super.key,
    this.showSpinner = false,
  });

  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevated,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGold),
                ),
              )
            : Icon(
                Icons.person_outline_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.9),
                size: 26,
              ),
      ),
    );
  }
}
