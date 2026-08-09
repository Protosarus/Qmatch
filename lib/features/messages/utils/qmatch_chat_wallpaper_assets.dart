/// Bundled chat wallpaper asset paths (ASCII only — never Downloads).
class QMatchChatWallpaperAssets {
  QMatchChatWallpaperAssets._();

  /// Traceable source PNG (full fidelity).
  static const String sourcePng =
      'assets/images/chat/qmatch_chat_pattern_source.png';

  /// Optimized runtime derivative (same artwork, smaller).
  static const String runtimeWebp =
      'assets/images/chat/qmatch_chat_pattern.webp';

  /// Prefer WebP at runtime; PNG remains for audits / fallbacks.
  static const String runtimePrimary = runtimeWebp;
}
