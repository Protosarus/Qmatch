import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/iap_exceptions.dart';
import '../../iap/domain/qmatch_iap_product_ids.dart';

/// Super Resonance consumable unlock. Separate from the Resonance paywall.
Future<int?> showQMatchSuperResonancePurchaseSheet(
  BuildContext context, {
  required Future<int> Function() purchaseThenReadBalance,
}) async {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return _SuperResonancePurchaseBody(
        l10n: l10n,
        purchaseThenReadBalance: purchaseThenReadBalance,
      );
    },
  );
}

class _SuperResonancePurchaseBody extends StatefulWidget {
  const _SuperResonancePurchaseBody({
    required this.l10n,
    required this.purchaseThenReadBalance,
  });

  final AppLocalizations l10n;
  final Future<int> Function() purchaseThenReadBalance;

  @override
  State<_SuperResonancePurchaseBody> createState() =>
      _SuperResonancePurchaseBodyState();
}

class _SuperResonancePurchaseBodyState
    extends State<_SuperResonancePurchaseBody> {
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final balance = await widget.purchaseThenReadBalance();
      if (!mounted) return;
      Navigator.of(context).pop(balance);
    } on IapPurchaseCanceledException {
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.discoverSuperResonancePurchaseFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: Padding(
        key: const Key('qmatch-super-resonance-purchase-sheet'),
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
              key: const Key('qmatch-super-resonance-purchase-title'),
              l10n.discoverSuperResonancePurchaseTitle,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const Key('qmatch-super-resonance-purchase-body'),
              l10n.discoverSuperResonancePurchaseBody,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              key: const Key('qmatch-super-resonance-purchase-sku'),
              QmatchIapProductIds.superResonanceX1,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            QCosmicButton(
              key: const Key('qmatch-super-resonance-purchase-cta'),
              label: _busy
                  ? l10n.discoverLoading
                  : l10n.discoverSuperResonancePurchaseCta,
              onPressed: _busy ? null : _buy,
              variant: QCosmicButtonVariant.cosmic,
              pill: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const Key('qmatch-super-resonance-purchase-dismiss'),
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n.discoverSuperResonancePurchaseNotNow,
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
  }
}
