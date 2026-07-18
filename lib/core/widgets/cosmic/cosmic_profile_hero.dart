import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Static Cosmic Profile Hero shell — large circular portrait + orbital halo.
///
/// Not wired into screens in DS-1. No animation. Uses [Image.network] only when
/// [imageUrl] is provided (same pattern as existing profile / discover code).
class CosmicProfileHero extends StatelessWidget {
  const CosmicProfileHero({
    super.key,
    required this.name,
    this.imageProvider,
    this.imageUrl,
    this.metaLine,
    this.quote,
    this.compatibilityText,
    this.portraitSize = 168,
  });

  /// Display name (hero-level identity).
  final String name;

  /// Preferred local / resolved image (asset, memory, file, network provider).
  final ImageProvider? imageProvider;

  /// Optional URL fallback using existing [Image.network] pattern.
  final String? imageUrl;

  /// e.g. "28 · Designer · Istanbul"
  final String? metaLine;

  /// Short bio / quote near the portrait.
  final String? quote;

  /// Quiet compatibility cue (text or score label) — not a control panel.
  final String? compatibilityText;

  /// Diameter of the circular portrait (halo is slightly larger).
  final double portraitSize;

  @override
  Widget build(BuildContext context) {
    final haloSize = portraitSize + 28;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: haloSize,
          height: haloSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft atmospheric glow (static)
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.cosmicGlow,
                ),
              ),
              // Orbital ring (static sweep gradient)
              Container(
                width: haloSize,
                height: haloSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.profileHeroGlowGradient,
                ),
              ),
              // Inner cutout so ring reads as a halo
              Container(
                width: haloSize - 10,
                height: haloSize - 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cosmicBlack,
                ),
              ),
              // Portrait
              Container(
                width: portraitSize,
                height: portraitSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.deepIndigo,
                  border: Border.all(
                    color: AppColors.borderSubtle,
                    width: 1.5,
                  ),
                  boxShadow: AppShadows.glassCard,
                ),
                clipBehavior: Clip.antiAlias,
                child: _PortraitImage(
                  imageProvider: imageProvider,
                  imageUrl: imageUrl,
                  size: portraitSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            height: 1.2,
          ),
        ),
        if (metaLine != null && metaLine!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            metaLine!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
        if (quote != null && quote!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Text(
              '“${quote!.trim()}”',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (compatibilityText != null &&
            compatibilityText!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: AppRadii.pillBorder,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              compatibilityText!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.softGold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PortraitImage extends StatelessWidget {
  const _PortraitImage({
    required this.imageProvider,
    required this.imageUrl,
    required this.size,
  });

  final ImageProvider? imageProvider;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageProvider != null) {
      return Image(
        image: imageProvider!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.softGold.withValues(alpha: 0.7),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.deepIndigo,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: size * 0.36,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
