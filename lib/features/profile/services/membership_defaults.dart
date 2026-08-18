import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../iap/domain/entitlement_snapshot.dart';
import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../../iap/services/ios_iap_session.dart';

/// Production actions for Membership. Entitlement still comes from Firestore.
abstract final class MembershipDefaults {
  static final Uri appleManageSubscriptions = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );

  /// Restore → existing IAP client → trusted `entitlements/{uid}` re-read.
  static Future<EntitlementSnapshot> restorePurchases() async {
    final result = await IosIapSession.instance.client.restorePurchases();
    return result.entitlement;
  }

  static Future<void> manageSubscription() async {
    await launchUrl(
      appleManageSubscriptions,
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> openUpgrade(BuildContext context) {
    return ResonancePaywallScreen.open(
      context,
      feature: ResonancePaywallFeature.settingsResonance,
    );
  }
}
