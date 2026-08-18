import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../../iap/services/entitlement_repository.dart';
import '../screens/who_liked_you_screen.dart';

/// UX routing for Who Liked You entry points.
///
/// Client [resonance_access] is a navigation hint only for Settings.
/// Discover always opens Alignment Signals. Ordinary likes still come
/// exclusively from trusted `listWhoLikedYou`. Super Resonance identities
/// come from `listSuperResonanceInbox`.
class WhoLikedYouEntry {
  WhoLikedYouEntry({
    Future<bool> Function()? readResonanceAccess,
    Future<bool> Function(
      BuildContext context,
      ResonancePaywallFeature feature,
    )? openPaywall,
    @Deprecated('Discover always opens the inbox')
    Future<bool> Function(BuildContext context)? showUnlockSheet,
    Future<void> Function(BuildContext context)? openInbox,
  })  : _readResonanceAccess = readResonanceAccess,
        _openPaywall = openPaywall,
        _openInbox = openInbox;

  final Future<bool> Function()? _readResonanceAccess;
  final Future<bool> Function(
    BuildContext context,
    ResonancePaywallFeature feature,
  )? _openPaywall;
  final Future<void> Function(BuildContext context)? _openInbox;

  bool _opening = false;

  /// Settings → Resonance: entitled inbox, otherwise existing paywall.
  Future<void> openFromSettings(BuildContext context) {
    return _open(
      context,
      ifLocked: (ctx) =>
          _paywall(ctx, ResonancePaywallFeature.settingsResonance),
    );
  }

  /// Discover header: always open Alignment Signals.
  /// Super Resonance identities are visible to Free; ordinary likes stay gated.
  Future<void> openFromDiscover(BuildContext context) {
    return _openInboxAlways(context);
  }

  Future<void> _openInboxAlways(BuildContext context) async {
    if (_opening) return;
    _opening = true;
    try {
      if (!context.mounted) return;
      await _inbox(context);
    } finally {
      _opening = false;
    }
  }

  Future<void> _open(
    BuildContext context, {
    required Future<bool> Function(BuildContext context) ifLocked,
  }) async {
    if (_opening) return;
    _opening = true;
    try {
      final entitled = await _access();
      if (!context.mounted) return;
      if (entitled) {
        await _inbox(context);
        return;
      }
      final unlocked = await ifLocked(context);
      if (!unlocked || !context.mounted) return;
      await _inbox(context);
    } finally {
      _opening = false;
    }
  }

  Future<bool> _access() async {
    try {
      final custom = _readResonanceAccess;
      if (custom != null) return await custom();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return false;
      final snap = await EntitlementRepository().fetch(uid);
      return snap.resonanceAccess == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _paywall(
    BuildContext context,
    ResonancePaywallFeature feature,
  ) {
    final custom = _openPaywall;
    if (custom != null) return custom(context, feature);
    return ResonancePaywallScreen.open(context, feature: feature);
  }

  Future<void> _inbox(BuildContext context) {
    final custom = _openInbox;
    if (custom != null) return custom(context);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const WhoLikedYouScreen(),
      ),
    );
  }
}
