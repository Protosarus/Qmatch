import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'qmatch_conversation_avatar.dart';

/// Modern chat-detail app bar content (title + avatar + menu).
class QMatchConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const QMatchConversationAppBar({
    super.key,
    required this.title,
    required this.loading,
    this.photoUrl,
    this.photoImageProvider,
    this.avatarSemanticLabel,
    this.menuItems = const [],
    this.onMenuSelected,
    this.onTitleTap,
  });

  final String title;
  final bool loading;
  final String? photoUrl;
  final ImageProvider? photoImageProvider;
  final String? avatarSemanticLabel;
  final List<PopupMenuEntry<String>> menuItems;
  final ValueChanged<String>? onMenuSelected;
  /// Optional title/avatar tap (e.g. profile). Null = not navigable.
  final VoidCallback? onTitleTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: const Key('qmatch-chat-app-bar'),
      backgroundColor: AppColors.glassSurfaceStrong,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleSpacing: AppSpacing.xs,
      actions: [
        if (menuItems.isNotEmpty)
          PopupMenuButton<String>(
            key: const Key('qmatch-chat-menu'),
            icon:
                const Icon(Icons.more_vert_rounded, color: AppColors.softGold),
            color: AppColors.surfaceElevated,
            onSelected: onMenuSelected,
            itemBuilder: (_) => menuItems,
          ),
      ],
      title: loading
          ? Text(
              key: const Key('qmatch-chat-app-bar-loading'),
              title,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          : InkWell(
              key: const Key('qmatch-chat-app-bar-identity'),
              onTap: onTitleTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  QMatchConversationAvatar(
                    photoUrl: photoUrl,
                    imageProvider: photoImageProvider,
                    semanticLabel: avatarSemanticLabel ?? title,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      key: const Key('qmatch-chat-app-bar-title'),
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
