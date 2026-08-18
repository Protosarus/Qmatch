import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../l10n/app_localizations.dart';

const _lilac = Color(0xFFDAC8ED);

/// Confirm sending one Super Resonance. Does not Like or create a match.
Future<bool> showQMatchSuperResonanceConfirmSheet(
  BuildContext context, {
  required String candidateName,
  required int balance,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          key: const Key('qmatch-super-resonance-confirm-sheet'),
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
                key: const Key('qmatch-super-resonance-confirm-name'),
                l10n.discoverSuperResonanceConfirmTitle(candidateName),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                key: const Key('qmatch-super-resonance-confirm-balance'),
                l10n.discoverSuperResonanceBalance(balance),
                style: GoogleFonts.inter(
                  color: _lilac,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                key: const Key('qmatch-super-resonance-confirm-uses'),
                l10n.discoverSuperResonanceUsesOne,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                key: const Key('qmatch-super-resonance-confirm-body'),
                l10n.discoverSuperResonanceConfirmBody,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              QCosmicButton(
                key: const Key('qmatch-super-resonance-confirm'),
                label: l10n.discoverSuperResonanceConfirm,
                onPressed: () => Navigator.of(ctx).pop(true),
                variant: QCosmicButtonVariant.cosmic,
                pill: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                key: const Key('qmatch-super-resonance-cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  l10n.discoverSuperResonanceCancel,
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
  return confirmed == true;
}
