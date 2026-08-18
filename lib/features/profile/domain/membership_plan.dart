import '../../iap/domain/entitlement_snapshot.dart';
import '../../iap/domain/qmatch_iap_product_ids.dart';

/// Trusted subscription period from `entitlements/{uid}` only.
///
/// Never inferred from StoreKit local state.
enum MembershipPlanPeriod {
  monthly,
  annual,
}

abstract final class MembershipPlan {
  /// [canonicalProductKey] wins over [productId]. Unknown keys stay null.
  static MembershipPlanPeriod? fromEntitlement(EntitlementSnapshot snap) {
    if (snap.resonanceAccess != true) return null;
    return fromTrustedKeys(
      canonicalProductKey: snap.canonicalProductKey,
      productId: snap.productId,
    );
  }

  static MembershipPlanPeriod? fromTrustedKeys({
    String? canonicalProductKey,
    String? productId,
  }) {
    return _classify(canonicalProductKey) ?? _classify(productId);
  }

  static MembershipPlanPeriod? _classify(String? raw) {
    if (raw == null) return null;
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (key == QmatchIapProductIds.resonanceAnnual.toLowerCase()) {
      return MembershipPlanPeriod.annual;
    }
    if (key == QmatchIapProductIds.resonanceMonthly.toLowerCase()) {
      return MembershipPlanPeriod.monthly;
    }
    if (key.contains('annual') || key.contains('yearly')) {
      return MembershipPlanPeriod.annual;
    }
    if (key.contains('monthly')) {
      return MembershipPlanPeriod.monthly;
    }
    return null;
  }
}
