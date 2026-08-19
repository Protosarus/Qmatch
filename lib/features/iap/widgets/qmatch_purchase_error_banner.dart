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
  }
}

/// Inline dark-glass purchase error. Not a snackbar. No gold, no bright red.
class QmatchPurchaseErrorBanner extends StatelessWidget {
  const QmatchPurchaseErrorBanner({
    super.key,
    required this.title,
    required this.body,
  });

  factory QmatchPurchaseErrorBanner.fromKind({
    Key? key,
    required AppLocalizations l10n,
    required QmatchPurchaseErrorKind kind,
  }) {
    return QmatchPurchaseErrorBanner(
      key: key,
      title: purchaseErrorTitle(l10n, kind),
      body: purchaseErrorBody(l10n, kind),
    );
  }

  final String title;
  final String body;

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
