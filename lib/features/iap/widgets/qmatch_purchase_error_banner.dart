import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/qmatch_purchase_error_kind.dart';

const _lilac = Color(0xFFDAC8ED);

String purchaseErrorTitle(
  AppLocalizations l10n,
  QmatchPurchaseErrorKind kind,
) {
  switch (kind) {
    case QmatchPurchaseErrorKind.superResonanceConsumable:
      return l10n.superResonancePurchaseFailedTitle;
    case QmatchPurchaseErrorKind.resonanceSubscription:
      return l10n.resonancePurchaseFailedTitle;
    case QmatchPurchaseErrorKind.verification:
      return l10n.iapVerificationFailedTitle;
    case QmatchPurchaseErrorKind.alreadyOwned:
      return l10n.iapAlreadyOwnedTitle;
  }
}

String purchaseErrorBody(
  AppLocalizations l10n,
  QmatchPurchaseErrorKind kind,
) {
  switch (kind) {
    case QmatchPurchaseErrorKind.superResonanceConsumable:
      return l10n.superResonancePurchaseFailedBody;
    case QmatchPurchaseErrorKind.resonanceSubscription:
      return l10n.resonancePurchaseFailedBody;
    case QmatchPurchaseErrorKind.verification:
      return l10n.iapVerificationFailedBody;
    case QmatchPurchaseErrorKind.alreadyOwned:
      return l10n.iapAlreadyOwnedBody;
  }
}

/// Inline dark-glass purchase error. Not a snackbar. No gold, no bright red.
class QmatchPurchaseErrorBanner extends StatelessWidget {
  const QmatchPurchaseErrorBanner({
    super.key,
    required this.title,
    required this.body,
    this.onRestore,
    this.restoreLabel,
  });

  factory QmatchPurchaseErrorBanner.fromKind({
    Key? key,
    required AppLocalizations l10n,
    required QmatchPurchaseErrorKind kind,
    VoidCallback? onRestore,
  }) {
    return QmatchPurchaseErrorBanner(
      key: key,
      title: purchaseErrorTitle(l10n, kind),
      body: purchaseErrorBody(l10n, kind),
      onRestore: kind == QmatchPurchaseErrorKind.alreadyOwned ? onRestore : null,
      restoreLabel: kind == QmatchPurchaseErrorKind.alreadyOwned
          ? l10n.resonancePaywallRestore
          : null,
    );
  }

  final String title;
  final String body;
  final VoidCallback? onRestore;
  final String? restoreLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF141A2E).withValues(alpha: 0.72),
          borderRadius: AppRadii.cardBorder,
          border: Border.all(
            color: _lilac.withValues(alpha: 0.38),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: _lilac.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        key: const Key('qmatch-purchase-error-title'),
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      key: const Key('qmatch-purchase-error-body'),
                      body,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    if (onRestore != null &&
                        restoreLabel != null &&
                        restoreLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('qmatch-purchase-error-restore'),
                          onPressed: onRestore,
                          style: TextButton.styleFrom(
                            foregroundColor: _lilac,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            restoreLabel!,
                            style: GoogleFonts.inter(
                              color: _lilac,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
