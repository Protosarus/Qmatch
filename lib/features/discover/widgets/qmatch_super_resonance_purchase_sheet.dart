import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/qmatch_purchase_error_kind.dart';
import '../../iap/widgets/qmatch_purchase_error_banner.dart';

const _lilac = Color(0xFFDAC8ED);

/// Super Resonance consumable unlock. Separate from the Resonance paywall.
Future<int?> showQMatchSuperResonancePurchaseSheet(
  BuildContext context, {
  required int trustedBalance,
  required Future<int> Function() purchaseThenReadBalance,
  Future<String?> Function()? loadLocalizedPrice,
}) async {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
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
        trustedBalance: trustedBalance,
        purchaseThenReadBalance: purchaseThenReadBalance,
        loadLocalizedPrice: loadLocalizedPrice,
      );
    },
  );
}

class _SuperResonancePurchaseBody extends StatefulWidget {
  const _SuperResonancePurchaseBody({
    required this.l10n,
    required this.trustedBalance,
    required this.purchaseThenReadBalance,
    this.loadLocalizedPrice,
  });

  final AppLocalizations l10n;
  final int trustedBalance;
  final Future<int> Function() purchaseThenReadBalance;
  final Future<String?> Function()? loadLocalizedPrice;

  @override
  State<_SuperResonancePurchaseBody> createState() =>
      _SuperResonancePurchaseBodyState();
}

class _SuperResonancePurchaseBodyState
    extends State<_SuperResonancePurchaseBody> {
  bool _busy = false;
  String? _price;
  QmatchPurchaseErrorKind? _error;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final load = widget.loadLocalizedPrice;
    if (load == null) return;
    try {
      final price = await load();
      if (!mounted) return;
      setState(() => _price = price);
    } catch (_) {
      if (mounted) setState(() => _price = null);
    }
  }

  Future<void> _buy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final balance = await widget.purchaseThenReadBalance();
      if (!mounted) return;
      Navigator.of(context).pop(balance);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = classifyPurchaseException(
          e,
          productFailure: QmatchPurchaseErrorKind.superResonanceConsumable,
        );
      });
    }
  }

  void _dismiss() {
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final price = _price;
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              key: const Key('qmatch-super-resonance-purchase-balance'),
              l10n.discoverSuperResonanceBalance(widget.trustedBalance),
              style: GoogleFonts.inter(
                color: _lilac,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              key: const Key('qmatch-super-resonance-purchase-quantity'),
              l10n.discoverSuperResonanceQuantity,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (price != null && price.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                key: const Key('qmatch-super-resonance-purchase-price'),
                price,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              QmatchPurchaseErrorBanner.fromKind(
                key: const Key('qmatch-super-resonance-purchase-error'),
                l10n: l10n,
                kind: _error!,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
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
              onPressed: _busy ? null : _dismiss,
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
