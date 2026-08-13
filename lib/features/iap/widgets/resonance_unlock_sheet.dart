import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/resonance_paywall_feature.dart';
import '../services/ios_iap_client.dart';
import '../screens/resonance_paywall_screen.dart';

/// Soft unlock sheet (no prices) → opens the production Resonance paywall.
///
/// Honors `qmatch_resonance_paywall_tease_ux_v1` unlock-sheet anatomy.
Future<bool> showResonanceUnlockSheet(
  BuildContext context, {
  required ResonancePaywallFeature feature,
  required String title,
  required String body,
  IosIapClient? iapClient,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final proceed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                key: const Key('qmatch-resonance-unlock-title'),
                title,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                key: const Key('qmatch-resonance-unlock-body'),
                body,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              QCosmicButton(
                key: const Key('qmatch-resonance-unlock-cta'),
                label: l10n.resonanceUnlockCta,
                onPressed: () => Navigator.of(ctx).pop(true),
                variant: QCosmicButtonVariant.cosmic,
                pill: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                key: const Key('qmatch-resonance-unlock-dismiss'),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l10n.resonanceUnlockNotNow,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (proceed != true || !context.mounted) return false;
  return ResonancePaywallScreen.open(
    context,
    feature: feature,
    iapClient: iapClient,
  );
}
