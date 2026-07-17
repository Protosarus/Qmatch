import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/reveal_state_model.dart';

class BlurredProfilePhoto extends StatelessWidget {
  final String? imageUrl;
  final int blurLevel;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;
  final String? overlayText;

  const BlurredProfilePhoto({
    super.key,
    required this.imageUrl,
    required this.blurLevel,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.person,
    this.overlayText,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final radius = borderRadius ?? BorderRadius.circular(16);

    if (url == null || url.isEmpty) {
      return _placeholder(radius);
    }

    final sigma = RevealStateModel(blurLevel: blurLevel).blurSigma;
    final img = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(radius),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );

    Widget content = img;
    if (sigma > 0) {
      content = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: img,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          if (sigma > 0)
            Container(
              width: width,
              height: height,
              color: Colors.black.withValues(alpha: 0.18),
            ),
          if (sigma > 0 && overlayText != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        overlayText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade900,
        child: Icon(
          placeholderIcon,
          size: (width < height ? width : height) * 0.35,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
