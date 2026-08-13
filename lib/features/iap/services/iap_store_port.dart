import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin StoreKit facade so unit tests avoid the real plugin.
abstract class IapStorePort {
  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);

  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});

  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  });

  Future<void> restorePurchases({String? applicationUserName});

  Future<void> completePurchase(PurchaseDetails purchase);
}

/// Production adapter over [InAppPurchase.instance].
class PluginIapStorePort implements IapStorePort {
  PluginIapStorePort([InAppPurchase? instance])
      : _iap = instance ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _iap.queryProductDetails(identifiers);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _iap.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) =>
      _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: autoConsume,
      );

  @override
  Future<void> restorePurchases({String? applicationUserName}) =>
      _iap.restorePurchases(applicationUserName: applicationUserName);

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}
