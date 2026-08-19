import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
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

  static const Color _lilac = Color(0xFFDAC8ED);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final menuTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.resonanceViolet,
        secondary: AppColors.resonanceViolet,
        surface: AppColors.surfaceElevated,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      splashColor: AppColors.resonanceViolet.withValues(alpha: 0.14),
      highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.10),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.glassSurfaceStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        textStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(color: _lilac.withValues(alpha: 0.38)),
        ),
      ),
    );

    return AppBar(
      key: const Key('qmatch-chat-app-bar'),
      backgroundColor: AppColors.glassSurfaceStrong,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleSpacing: AppSpacing.xs,
      actions: [
        if (menuItems.isNotEmpty)
          Theme(
            data: menuTheme,
            child: PopupMenuButton<String>(
              key: const Key('qmatch-chat-menu'),
              icon: const Icon(Icons.more_vert_rounded, color: _lilac),
              color: AppColors.glassSurfaceStrong,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.45),
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.cardBorder,
                side: BorderSide(color: _lilac.withValues(alpha: 0.38)),
              ),
              style: ButtonStyle(
                overlayColor: WidgetStatePropertyAll(
                  AppColors.resonanceViolet.withValues(alpha: 0.14),
                ),
              ),
              onSelected: onMenuSelected,
              itemBuilder: (_) => menuItems,
            ),
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
