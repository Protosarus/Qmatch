import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/qmatch_iap_product_ids.dart';
import '../domain/resonance_paywall_feature.dart';
import '../services/ios_iap_client.dart';
import '../services/ios_iap_session.dart';
import '../services/resonance_paywall_controller.dart';
import '../services/resonance_paywall_iap_port.dart';
import '../widgets/qmatch_purchase_error_banner.dart';
import '../../settings/screens/legal_document_screen.dart';

/// Production Resonance subscription paywall (Monthly + Annual).
///
/// Prices come from StoreKit [ProductDetails]. Entitlement / access is refreshed
/// only after trusted backend verification via [IosIapClient].
class ResonancePaywallScreen extends StatefulWidget {
  const ResonancePaywallScreen({
    super.key,
    this.feature = ResonancePaywallFeature.settingsResonance,
    this.iapClient,
    this.controller,
    this.purchasesEnabledOverride,
    this.animateBackground,
  });

  final ResonancePaywallFeature feature;

  /// Optional injected client (tests / feature entry).
  final IosIapClient? iapClient;

  /// Optional pre-built controller (tests).
  final ResonancePaywallController? controller;

  /// When non-null, overrides iOS purchase gate (tests).
  final bool? purchasesEnabledOverride;

  final bool? animateBackground;

  /// Open paywall as a pushed route. Returns whether Resonance access is active
  /// when the screen is popped (from trusted entitlement only).
  static Future<bool> open(
    BuildContext context, {
    ResonancePaywallFeature feature = ResonancePaywallFeature.settingsResonance,
    IosIapClient? iapClient,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ResonancePaywallScreen(
          feature: feature,
          iapClient: iapClient ?? IosIapSession.instance.client,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<ResonancePaywallScreen> createState() => _ResonancePaywallScreenState();
}

class _ResonancePaywallScreenState extends State<ResonancePaywallScreen> {
  late final ResonancePaywallController _controller;
  late final bool _ownsController;

  bool get _purchasesEnabled {
    if (widget.purchasesEnabledOverride != null) {
      return widget.purchasesEnabledOverride!;
    }
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      final client = widget.iapClient ?? IosIapSession.instance.client;
      _controller = ResonancePaywallController(
        iap: IosResonancePaywallIap(client),
        purchasesEnabled: _purchasesEnabled,
      );
      _ownsController = true;
    }
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      _controller.load();
    });
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _purchase() async {
    final unlocked = await _controller.purchaseSelected();
    if (!mounted) return;
    if (unlocked) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restore() async {
    final unlocked = await _controller.restore();
    if (!mounted) return;
    if (unlocked) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openLegal({
    required String title,
    required String body,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(
          title: title,
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-resonance-paywall-cosmic'),
        seed: 71,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                title: l10n.resonancePaywallTitle,
                backButtonKey: const Key('qmatch-resonance-paywall-back'),
                titleKey: const Key('qmatch-resonance-paywall-title'),
                onBack: () => Navigator.of(context).pop(c.hasResonanceAccess),
              ),
              Expanded(
                child: c.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          key: Key('qmatch-resonance-paywall-loading'),
                          color: Color(0xFFDAC8ED),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        children: [
                          QGlassCard(
                            key: const Key('qmatch-resonance-paywall-hero'),
                            emphasized: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.resonancePaywallHeadline,
                                  style: GoogleFonts.playfairDisplay(
                                    color: AppColors.textPrimary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.resonancePaywallBody,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _BenefitRow(
                                  key: const Key(
                                    'qmatch-resonance-paywall-benefit-who-liked-you',
                                  ),
                                  title:
                                      l10n.resonancePaywallBenefitWhoLikedYou,
                                  status: l10n.resonancePaywallIncludedNow,
                                  live: true,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _BenefitRow(
                                  key: const Key(
                                    'qmatch-resonance-paywall-benefit-rewind',
                                  ),
                                  title: l10n.resonancePaywallBenefitRewind,
                                  status: l10n.resonancePaywallComingLater,
                                  live: false,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                _BenefitRow(
                                  key: const Key(
                                    'qmatch-resonance-paywall-benefit-deeper',
                                  ),
                                  title: l10n.resonancePaywallBenefitDeeper,
                                  status: l10n.resonancePaywallComingLater,
                                  live: false,
                                ),
                                if (c.hasResonanceAccess) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    key: const Key(
                                      'qmatch-resonance-paywall-active',
                                    ),
                                    l10n.resonancePaywallActive,
                                    style: GoogleFonts.inter(
                                      color: AppColors.softGold,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!c.hasResonanceAccess) ...[
                            const SizedBox(height: AppSpacing.md),
                            if (c.availablePlans.isEmpty && c.purchasesEnabled)
                              QGlassCard(
                                child: Text(
                                  l10n.resonancePaywallPlansUnavailable,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              )
                            else if (!c.purchasesEnabled)
                              QGlassCard(
                                key: const Key(
                                  'qmatch-resonance-paywall-android-disabled',
                                ),
                                child: Text(
                                  l10n.resonancePaywallAndroidDisabled,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              )
                            else ...[
                              if (c.monthly != null)
                                _PlanTile(
                                  key: const Key(
                                    'qmatch-resonance-plan-monthly',
                                  ),
                                  title: l10n.resonancePlanMonthly,
                                  product: c.monthly!,
                                  selected: c.selectedProductId ==
                                      QmatchIapProductIds.resonanceMonthly,
                                  onTap: c.busy
                                      ? null
                                      : () => c.selectProduct(
                                            QmatchIapProductIds
                                                .resonanceMonthly,
                                          ),
                                ),
                              if (c.monthly != null && c.annual != null)
                                const SizedBox(height: AppSpacing.sm),
                              if (c.annual != null)
                                _PlanTile(
                                  key: const Key(
                                    'qmatch-resonance-plan-annual',
                                  ),
                                  title: l10n.resonancePlanAnnual,
                                  product: c.annual!,
                                  selected: c.selectedProductId ==
                                      QmatchIapProductIds.resonanceAnnual,
                                  badge: l10n.resonancePlanAnnualBadge,
                                  onTap: c.busy
                                      ? null
                                      : () => c.selectProduct(
                                            QmatchIapProductIds.resonanceAnnual,
                                          ),
                                ),
                              const SizedBox(height: AppSpacing.lg),
                              QCosmicButton(
                                key: const Key(
                                  'qmatch-resonance-paywall-purchase',
                                ),
                                label: c.purchasing
                                    ? l10n.resonancePaywallPurchasing
                                    : l10n.resonancePaywallPurchase,
                                onPressed: c.busy || c.selectedProduct == null
                                    ? null
                                    : _purchase,
                                variant: QCosmicButtonVariant.cosmic,
                                pill: true,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Center(
                                child: TextButton(
                                  key: const Key(
                                    'qmatch-resonance-paywall-restore',
                                  ),
                                  onPressed: c.busy ? null : _restore,
                                  child: Text(
                                    c.restoring
                                        ? l10n.resonancePaywallRestoring
                                        : l10n.resonancePaywallRestore,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (c.purchaseError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            QmatchPurchaseErrorBanner.fromKind(
                              key: const Key(
                                'qmatch-resonance-paywall-error',
                              ),
                              l10n: l10n,
                              kind: c.purchaseError!,
                              onRestore: c.busy ? null : _restore,
                            ),
                          ] else if (c.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            QmatchPurchaseErrorBanner(
                              key: const Key(
                                'qmatch-resonance-paywall-error',
                              ),
                              title: '',
                              body: c.errorMessage!,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.resonancePaywallLegalNote,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: AppSpacing.md,
                            children: [
                              _PaywallLegalLink(
                                buttonKey: const Key(
                                  'qmatch-resonance-paywall-terms',
                                ),
                                label: l10n.termsOfUseTitle,
                                onPressed: () => _openLegal(
                                  title: l10n.termsOfUseTitle,
                                  body: l10n.termsOfUseBody,
                                ),
                              ),
                              _PaywallLegalLink(
                                buttonKey: const Key(
                                  'qmatch-resonance-paywall-privacy',
                                ),
                                label: l10n.privacyPolicyTitle,
                                onPressed: () => _openLegal(
                                  title: l10n.privacyPolicyTitle,
                                  body: l10n.privacyPolicyBody,
                                ),
                              ),
                            ],
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

class _PaywallLegalLink extends StatelessWidget {
  const _PaywallLegalLink({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
  });

  /// Cool lavender — secondary to the CTA. No matching AppColors token.
  static const Color _color = Color(0xFFB8B5D6);

  final Key buttonKey;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: buttonKey,
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.textPrimary;
          }
          return _color;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.textPrimary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: _color,
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    super.key,
    required this.title,
    required this.status,
    required this.live,
  });

  final String title;
  final String status;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          live ? Icons.check_circle_outline : Icons.schedule,
          size: 18,
          color: live ? AppColors.softGold : AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.inter(
                  color: live ? AppColors.softGold : AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    super.key,
    required this.title,
    required this.product,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final ProductDetails product;
  final bool selected;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      emphasized: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.softGold : AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.resonanceViolet.withValues(
                            alpha: 0.25,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.inter(
                            color: AppColors.softGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  // Localized StoreKit price string.
                  product.price,
                  key: Key('qmatch-resonance-price-${product.id}'),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
