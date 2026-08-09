import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Candidate photo with loading / error / missing placeholders.
///
/// Uses only the URL provided by the existing Discover data source.
/// Optional [imageProvider] is presentation-only (golden / widget tests) and
/// never performs Firebase I/O.
class QMatchCandidatePhoto extends StatelessWidget {
  const QMatchCandidatePhoto({
    super.key,
    required this.photoUrl,
    required this.semanticLabel,
    required this.missingPhotoLabel,
    this.imageProvider,
  });

  final String? photoUrl;
  final String semanticLabel;
  final String missingPhotoLabel;

  /// When set, renders this provider instead of [NetworkImage].
  /// Production Discover never passes this.
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final hasProvider = imageProvider != null;
    final showPhoto = hasProvider || hasUrl;

    return Semantics(
      key: const Key('qmatch-candidate-photo'),
      image: true,
      label: showPhoto ? semanticLabel : missingPhotoLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadii.cardBorder,
        ),
        child: showPhoto
            ? Image(
                image: imageProvider ?? NetworkImage(url!),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const _PhotoPlaceholder(
                  key: Key('qmatch-candidate-photo-error'),
                  icon: Icons.broken_image_outlined,
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _PhotoPlaceholder(
                    key: Key('qmatch-candidate-photo-loading'),
                    showSpinner: true,
                  );
                },
              )
            : const _PhotoPlaceholder(
                key: Key('qmatch-candidate-photo-missing'),
                icon: Icons.person_outline_rounded,
              ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    super.key,
    this.icon,
    this.showSpinner = false,
  });

  final IconData? icon;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceElevated,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGold),
                ),
              )
            : Icon(
                icon ?? Icons.person_outline_rounded,
                size: 72,
                color: AppColors.textMuted.withValues(alpha: 0.85),
              ),
      ),
    );
  }
}
