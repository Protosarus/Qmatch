import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../utils/qmatch_chat_wallpaper_assets.dart';

/// Intentional WhatsApp-like science / love / space chat wallpaper.
///
/// Uses [BoxFit.cover] (not [ImageRepeat.repeat]) because the source is a
/// square non-seamless texture — edges do not tile cleanly.
class QMatchChatBackground extends StatelessWidget {
  const QMatchChatBackground({
    super.key,
    this.child,
    this.overlayOpacity = 0.55,
  });

  final Widget? child;

  /// Dark/purple wash so bubbles stay readable above the doodle pattern.
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('qmatch-chat-background'),
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.cosmicBlack),
        Image.asset(
          key: const Key('qmatch-chat-wallpaper-image'),
          QMatchChatWallpaperAssets.runtimePrimary,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Image.asset(
            QMatchChatWallpaperAssets.sourcePng,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
        ),
        DecoratedBox(
          key: const Key('qmatch-chat-wallpaper-overlay'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.midnightNavy.withValues(alpha: overlayOpacity * 0.85),
                AppColors.cosmicBlack.withValues(alpha: overlayOpacity),
                AppColors.deepIndigo.withValues(alpha: overlayOpacity * 0.75),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
