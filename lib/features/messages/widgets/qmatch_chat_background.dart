import 'package:flutter/material.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/qmatch_chat_wallpaper_assets.dart';

/// Intentional WhatsApp-like science / love / space chat wallpaper.
///
/// Uses [BoxFit.cover] (not [ImageRepeat.repeat]) because the source is a
/// square non-seamless texture — edges do not tile cleanly.
class QMatchChatBackground extends StatefulWidget {
  const QMatchChatBackground({
    super.key,
    this.child,
    this.overlayOpacity = 0.55,
  });

  final Widget? child;

  /// Dark/purple wash so bubbles stay readable above the doodle pattern.
  final double overlayOpacity;

  @override
  State<QMatchChatBackground> createState() => _QMatchChatBackgroundState();
}

class _QMatchChatBackgroundState extends State<QMatchChatBackground> {
  bool _loggedWallpaper = false;

  void _markWallpaperLoaded() {
    if (_loggedWallpaper) return;
    _loggedWallpaper = true;
    QmatchPerf.mark('chat.wallpaper.loaded');
  }

  Widget _wallpaperImage(String asset) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          _markWallpaperLoaded();
        }
        return child;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('qmatch-chat-background'),
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: ColoredBox(color: AppColors.cosmicBlack),
        ),
        Positioned.fill(
          child: SizedBox.expand(
            child: Image.asset(
              key: const Key('qmatch-chat-wallpaper-image'),
              QMatchChatWallpaperAssets.runtimePrimary,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  _markWallpaperLoaded();
                }
                return child;
              },
              errorBuilder: (_, __, ___) {
                QmatchPerf.mark('chat.wallpaper.fallback_png');
                return _wallpaperImage(QMatchChatWallpaperAssets.sourcePng);
              },
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            key: const Key('qmatch-chat-wallpaper-overlay'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.midnightNavy
                      .withValues(alpha: widget.overlayOpacity * 0.85),
                  AppColors.cosmicBlack.withValues(alpha: widget.overlayOpacity),
                  AppColors.deepIndigo
                      .withValues(alpha: widget.overlayOpacity * 0.75),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
