import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/discover_passport_snapshot.dart';
import '../domain/passport_destination_catalog.dart';

/// Compact Discover geography control.
class QMatchDiscoverPassportChip extends StatelessWidget {
  const QMatchDiscoverPassportChip({
    super.key,
    required this.snapshot,
    required this.onPressed,
  });

  final DiscoverPassportSnapshot snapshot;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';
    final active = snapshot.passportEnabled;
    final label = active
        ? l10n.discoverPassportChipActive(
            PassportDestinationCatalog.displayCity(
              country: snapshot.passportCountry,
              citySlug: snapshot.passportCity,
              turkish: turkish,
            ),
          )
        : l10n.discoverPassportWorldwide;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(
          active
              ? 'qmatch-discover-passport-chip-active'
              : 'qmatch-discover-passport-chip-worldwide',
        ),
        onTap: onPressed,
        borderRadius: AppRadii.pillBorder,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            color: QMatchGlassIconButton.glassFill.withValues(alpha: 0.55),
            border: Border.all(color: QMatchGlassIconButton.coolBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.public : Icons.language,
                size: 14,
                color: QMatchGlassIconButton.iconDefault,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              if (!snapshot.resonanceAccess) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
