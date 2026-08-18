import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/entitlement_snapshot.dart';
import '../../iap/domain/iap_exceptions.dart';
import '../../iap/services/entitlement_repository.dart';
import '../domain/membership_plan.dart';
import '../services/membership_defaults.dart';

const _lilac = Color(0xFFDAC8ED);

/// Owner membership from trusted `entitlements/{uid}` only.
class MembershipScreen extends StatefulWidget {
  const MembershipScreen({
    super.key,
    this.initialSnapshot,
    this.readEntitlement,
    this.restorePurchases,
    this.manageSubscription,
    this.openUpgrade,
    this.skipFetch = false,
    this.animateBackground,
  });

  /// Last known snapshot (Profile). Not inferred from local store state.
  final EntitlementSnapshot? initialSnapshot;

  /// Test injection. Production reads `entitlements/{uid}`.
  final Future<EntitlementSnapshot> Function()? readEntitlement;

  final Future<EntitlementSnapshot> Function()? restorePurchases;
  final Future<void> Function()? manageSubscription;
  final Future<void> Function(BuildContext context)? openUpgrade;

  /// Tests / synthetic Profile: do not hit Firestore.
  final bool skipFetch;

  final bool? animateBackground;

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late EntitlementSnapshot _snapshot;
  bool _loading = true;
  bool _restoring = false;
  String? _error;

  bool get _resonance => _snapshot.resonanceAccess == true;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot ?? EntitlementSnapshot.free;
    if (widget.skipFetch) {
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await _read();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _snapshot = EntitlementSnapshot.free;
        _loading = false;
      });
    }
  }

  Future<EntitlementSnapshot> _read() async {
    final custom = widget.readEntitlement;
    if (custom != null) return custom();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return EntitlementSnapshot.free;
    return EntitlementRepository().fetch(uid);
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() {
      _restoring = true;
      _error = null;
    });
    try {
      final restore =
          widget.restorePurchases ?? MembershipDefaults.restorePurchases;
      final snap = await restore();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _restoring = false;
      });
    } on IapException catch (e) {
      await _restoreFailed(e.message);
    } catch (e) {
      await _restoreFailed(e.toString());
    }
  }

  Future<void> _restoreFailed(String message) async {
    EntitlementSnapshot next = EntitlementSnapshot.free;
    try {
      next = await _read();
    } catch (_) {
      next = EntitlementSnapshot.free;
    }
    if (!mounted) return;
    setState(() {
      _snapshot = next;
      _error = message;
      _restoring = false;
    });
  }

  Future<void> _manage() async {
    final custom =
        widget.manageSubscription ?? MembershipDefaults.manageSubscription;
    await custom();
  }

  Future<void> _upgrade() async {
    final custom = widget.openUpgrade;
    if (custom != null) {
      await custom(context);
    } else {
      await MembershipDefaults.openUpgrade(context);
    }
    if (!mounted || widget.skipFetch) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-membership-cosmic'),
        seed: 29,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-membership-header'),
                title: l10n.membershipTitle,
                backButtonKey: const Key('qmatch-membership-back'),
                titleKey: const Key('qmatch-membership-title'),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          key: Key('qmatch-membership-loading'),
                          color: _lilac,
                        ),
                      )
                    : ListView(
                        key: const Key('qmatch-membership-screen'),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        children: [
                          if (_resonance)
                            _ResonanceCard(
                              snapshot: _snapshot,
                              l10n: l10n,
                              restoring: _restoring,
                              onRestore: _restore,
                              onManage: _manage,
                            )
                          else
                            _FreeCard(l10n: l10n, onUpgrade: _upgrade),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            QGlassCard(
                              key: const Key('qmatch-membership-error'),
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  height: 1.45,
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

class _FreeCard extends StatelessWidget {
  const _FreeCard({
    required this.l10n,
    required this.onUpgrade,
  });

  final AppLocalizations l10n;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      key: const Key('qmatch-membership-free'),
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.membershipFreeName,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            key: const Key('qmatch-membership-free-included'),
            l10n.membershipFreeIncluded,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          QCosmicButton(
            key: const Key('qmatch-membership-upgrade'),
            label: l10n.membershipUpgradeCta,
            onPressed: onUpgrade,
            variant: QCosmicButtonVariant.cosmic,
            pill: true,
          ),
        ],
      ),
    );
  }
}

class _ResonanceCard extends StatelessWidget {
  const _ResonanceCard({
    required this.snapshot,
    required this.l10n,
    required this.restoring,
    required this.onRestore,
    required this.onManage,
  });

  final EntitlementSnapshot snapshot;
  final AppLocalizations l10n;
  final bool restoring;
  final VoidCallback onRestore;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final plan = MembershipPlan.fromEntitlement(snapshot);
    final planLabel = switch (plan) {
      MembershipPlanPeriod.monthly => l10n.membershipPlanMonthly,
      MembershipPlanPeriod.annual => l10n.membershipPlanAnnual,
      null => null,
    };
    final planKey = switch (plan) {
      MembershipPlanPeriod.monthly =>
        const Key('qmatch-membership-plan-monthly'),
      MembershipPlanPeriod.annual => const Key('qmatch-membership-plan-annual'),
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QGlassCard(
          key: const Key('qmatch-membership-resonance'),
          emphasized: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.membershipResonanceName,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                key: const Key('qmatch-membership-active'),
                l10n.membershipStatusActive,
                style: GoogleFonts.inter(
                  color: _lilac,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (planLabel != null && planKey != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  key: planKey,
                  planLabel,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        QGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BenefitRow(
                key: const Key('qmatch-membership-benefit-alignment-signals'),
                title: l10n.whoLikedYouTitle,
                live: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _BenefitRow(
                key: const Key('qmatch-membership-benefit-rewind'),
                title: l10n.resonancePaywallBenefitRewind,
                live: false,
                laterLabel: l10n.membershipComingLater,
              ),
              const SizedBox(height: AppSpacing.sm),
              _BenefitRow(
                key: const Key('qmatch-membership-benefit-deeper'),
                title: l10n.resonancePaywallBenefitDeeper,
                live: false,
                laterLabel: l10n.membershipComingLater,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            key: const Key('qmatch-membership-restore'),
            onPressed: restoring ? null : onRestore,
            child: Text(
              restoring
                  ? l10n.resonancePaywallRestoring
                  : l10n.resonancePaywallRestore,
              style: GoogleFonts.inter(
                color: _lilac,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Center(
          child: TextButton(
            key: const Key('qmatch-membership-manage'),
            onPressed: onManage,
            child: Text(
              l10n.membershipManageSubscription,
              style: GoogleFonts.inter(
                color: _lilac,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    super.key,
    required this.title,
    required this.live,
    this.laterLabel,
  });

  final String title;
  final bool live;
  final String? laterLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          live ? Icons.check_circle_outline : Icons.schedule,
          size: 18,
          color: live ? _lilac : AppColors.textMuted,
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
              if (!live && laterLabel != null)
                Text(
                  laterLabel!,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
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
