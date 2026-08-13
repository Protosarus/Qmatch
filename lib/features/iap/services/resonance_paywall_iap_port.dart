import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/entitlement_snapshot.dart';
import 'ios_iap_client.dart';

/// Narrow IAP surface used by the Resonance subscription paywall.
abstract class ResonancePaywallIapPort {
  Future<EntitlementSnapshot> fetchEntitlement();

  Future<List<ProductDetails>> loadProducts();

  Future<IapClientResult> purchase(String productId);

  Future<IapClientResult> restorePurchases();
}

/// Production adapter over [IosIapClient].
class IosResonancePaywallIap implements ResonancePaywallIapPort {
  IosResonancePaywallIap(this.client);

  final IosIapClient client;

  @override
  Future<EntitlementSnapshot> fetchEntitlement() => client.fetchEntitlement();

  @override
  Future<List<ProductDetails>> loadProducts() => client.loadProducts();

  @override
  Future<IapClientResult> purchase(String productId) =>
      client.purchase(productId);

  @override
  Future<IapClientResult> restorePurchases() => client.restorePurchases();
}
