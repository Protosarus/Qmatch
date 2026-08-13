/// Frozen Apple StoreKit product IDs for QMatch launch IAP (iOS).
///
/// Android billing is intentionally not configured in this client.
abstract final class QmatchIapProductIds {
  static const resonanceMonthly = 'qmatch.resonance.monthly';
  static const resonanceAnnual = 'qmatch.resonance.annual';
  static const superResonanceX1 = 'qmatch.super_resonance.x1';
  static const boostX1 = 'qmatch.boost.x1';

  /// Launch SKUs the iOS client is allowed to query / purchase.
  static const Set<String> appleLaunchIds = {
    resonanceMonthly,
    resonanceAnnual,
    superResonanceX1,
    boostX1,
  };

  static const Set<String> subscriptionIds = {
    resonanceMonthly,
    resonanceAnnual,
  };

  static const Set<String> consumableIds = {
    superResonanceX1,
    boostX1,
  };

  static bool isKnownAppleProduct(String productId) =>
      appleLaunchIds.contains(productId);

  static bool isConsumable(String productId) =>
      consumableIds.contains(productId);

  static bool isSubscription(String productId) =>
      subscriptionIds.contains(productId);
}
