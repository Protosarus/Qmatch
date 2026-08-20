import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/entitlement_snapshot.dart';
import '../domain/iap_exceptions.dart';
import '../domain/qmatch_iap_product_ids.dart';
import '../domain/qmatch_purchase_error_kind.dart';
import 'resonance_paywall_iap_port.dart';

/// UI state for the Resonance subscription paywall.
///
/// Entitlement / `resonanceAccess` comes only from trusted backend / Firestore
/// via [ResonancePaywallIapPort] — never from StoreKit success alone.
class ResonancePaywallController extends ChangeNotifier {
  ResonancePaywallController({
    required ResonancePaywallIapPort iap,
    bool purchasesEnabled = true,
  })  : _iap = iap,
        purchasesEnabled = purchasesEnabled;

  final ResonancePaywallIapPort _iap;

  /// False on Android / non-iOS — purchase & restore stay disabled.
  final bool purchasesEnabled;

  bool loading = true;
  bool purchasing = false;
  bool restoring = false;
  String? errorMessage;
  QmatchPurchaseErrorKind? purchaseError;
  EntitlementSnapshot entitlement = EntitlementSnapshot.free;
  ProductDetails? monthly;
  ProductDetails? annual;
  String selectedProductId = QmatchIapProductIds.resonanceAnnual;
  bool _disposed = false;

  bool get busy => loading || purchasing || restoring;

  bool get hasResonanceAccess => entitlement.resonanceAccess;

  ProductDetails? get selectedProduct {
    if (selectedProductId == QmatchIapProductIds.resonanceMonthly) {
      return monthly;
    }
    return annual;
  }

  List<ProductDetails> get availablePlans => [
        if (monthly != null) monthly!,
        if (annual != null) annual!,
      ];

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    purchaseError = null;
    notifyListeners();

    try {
      entitlement = await _iap.fetchEntitlement();
    } on IapException catch (e) {
      errorMessage = e.message;
      entitlement = EntitlementSnapshot.free;
    } catch (e) {
      errorMessage = e.toString();
      entitlement = EntitlementSnapshot.free;
    }

    if (!purchasesEnabled) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      final products = await _iap.loadProducts();
      monthly = _find(products, QmatchIapProductIds.resonanceMonthly);
      annual = _find(products, QmatchIapProductIds.resonanceAnnual);
      if (annual != null) {
        selectedProductId = QmatchIapProductIds.resonanceAnnual;
      } else if (monthly != null) {
        selectedProductId = QmatchIapProductIds.resonanceMonthly;
      } else if (errorMessage == null) {
        errorMessage = 'Resonance plans are unavailable right now.';
      }
    } on IapException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void selectProduct(String productId) {
    if (productId != QmatchIapProductIds.resonanceMonthly &&
        productId != QmatchIapProductIds.resonanceAnnual) {
      return;
    }
    selectedProductId = productId;
    notifyListeners();
  }

  Future<bool> purchaseSelected() async {
    if (!purchasesEnabled) {
      errorMessage = 'Purchases are not available on this platform yet.';
      notifyListeners();
      return false;
    }
    if (selectedProduct == null) {
      errorMessage = 'Select a Resonance plan to continue.';
      notifyListeners();
      return false;
    }

    final productId = selectedProductId;
    purchasing = true;
    errorMessage = null;
    purchaseError = null;
    notifyListeners();

    try {
      final result = await _iap.purchase(productId);
      // Authoritative access only from trusted entitlement snapshot.
      entitlement = result.entitlement;
      purchasing = false;
      notifyListeners();
      return entitlement.resonanceAccess;
    } on IapPurchaseCanceledException {
      purchasing = false;
      errorMessage = null;
      purchaseError = null;
      notifyListeners();
      return false;
    } catch (e) {
      purchasing = false;
      errorMessage = null;
      try {
        entitlement = await _iap.fetchEntitlement();
      } catch (_) {}
      // Trusted snapshot only — never infer access from StoreKit error.
      if (entitlement.resonanceAccess) {
        purchaseError = null;
        notifyListeners();
        return true;
      }
      purchaseError = classifyPurchaseException(
        e,
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> restore() async {
    if (!purchasesEnabled) {
      errorMessage = 'Restore is not available on this platform yet.';
      notifyListeners();
      return false;
    }

    restoring = true;
    errorMessage = null;
    purchaseError = null;
    notifyListeners();

    try {
      final result = await _iap.restorePurchases();
      entitlement = result.entitlement;
      restoring = false;
      notifyListeners();
      return entitlement.resonanceAccess;
    } on IapPurchaseCanceledException {
      restoring = false;
      errorMessage = null;
      purchaseError = null;
      notifyListeners();
      return false;
    } catch (e) {
      purchaseError = classifyPurchaseException(
        e,
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      );
      errorMessage = null;
      restoring = false;
      try {
        entitlement = await _iap.fetchEntitlement();
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static ProductDetails? _find(List<ProductDetails> products, String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }
}
