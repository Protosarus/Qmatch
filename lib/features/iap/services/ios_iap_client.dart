import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../domain/apple_app_account_token.dart';
import '../domain/entitlement_snapshot.dart';
import '../domain/iap_exceptions.dart';
import '../domain/qmatch_iap_product_ids.dart';
import 'entitlement_repository.dart';
import 'iap_backend_client.dart';
import 'iap_store_port.dart';

/// Result of a verified purchase or restore. Entitlement comes from Firestore.
class IapClientResult {
  const IapClientResult({
    required this.backendResponse,
    required this.entitlement,
    this.productId,
  });

  final Map<String, dynamic> backendResponse;
  final EntitlementSnapshot entitlement;
  final String? productId;

  /// Convenience — still sourced from trusted snapshot, not StoreKit.
  bool get resonanceAccess => entitlement.resonanceAccess;
}

/// Minimal production-safe Flutter iOS IAP client.
///
/// - Requires Firebase Auth
/// - Sets Apple `appAccountToken` via `applicationUserName` =
///   deterministic UUID derived from Firebase uid (never raw uid)
/// - Never grants premium from StoreKit success alone
/// - Calls `verifyAndApplyPurchase` / `restorePurchases` then re-reads Firestore
/// - Android purchase path disabled
class IosIapClient {
  IosIapClient({
    IapStorePort? store,
    IapBackendClient? backend,
    EntitlementRepository? entitlements,
    FirebaseAuth? auth,
    String? Function()? uidProvider,
    bool? isIosOverride,
    Duration purchaseTimeout = const Duration(minutes: 2),
  })  : _store = store ?? PluginIapStorePort(),
        _backend = backend ?? IapBackendClient(),
        _entitlements = entitlements ?? EntitlementRepository(),
        _auth = auth,
        _uidProvider = uidProvider,
        _isIosOverride = isIosOverride,
        _purchaseTimeout = purchaseTimeout;

  final IapStorePort _store;
  final IapBackendClient _backend;
  final EntitlementRepository _entitlements;
  final FirebaseAuth? _auth;
  final String? Function()? _uidProvider;
  final bool? _isIosOverride;
  final Duration _purchaseTimeout;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final _pendingPurchases = <String, Completer<PurchaseDetails>>{};
  final _restoreBuffer = <PurchaseDetails>[];
  Completer<List<PurchaseDetails>>? _restoreCompleter;
  final _inFlightRecovery = <String>{};

  bool get _isIos {
    if (_isIosOverride != null) return _isIosOverride!;
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  String? get currentUid {
    final injected = _uidProvider;
    if (injected != null) return injected();
    return (_auth ?? FirebaseAuth.instance).currentUser?.uid;
  }

  void _ensureIos() {
    if (!_isIos) {
      throw IapPlatformDisabledException(
          kIsWeb ? 'web' : Platform.operatingSystem);
    }
  }

  String _requireUid() {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      throw IapAuthRequiredException();
    }
    return uid;
  }

  bool get isListening => _purchaseSub != null;

  /// Start listening to StoreKit updates. Idempotent — one subscription.
  void startListening() {
    _ensureIos();
    _purchaseSub ??= _store.purchaseStream.listen(_onPurchaseUpdates);
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _inFlightRecovery.clear();
    _pendingPurchases.clear();
    _restoreCompleter = null;
    _restoreBuffer.clear();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final completer = _pendingPurchases.remove(purchase.productID);
      final ownedByPaywallFlow = completer != null && !completer.isCompleted;
      if (ownedByPaywallFlow) {
        completer.complete(purchase);
      }

      final restoreWait = _restoreCompleter;
      if (restoreWait != null &&
          (purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased)) {
        _restoreBuffer.add(purchase);
        continue;
      }

      if (!ownedByPaywallFlow &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored)) {
        unawaited(_recoverUnfinished(purchase));
      }
    }

    // Restore stream often ends after a burst; ignore empty ticks (race).
    final restoreWait = _restoreCompleter;
    if (restoreWait != null &&
        !restoreWait.isCompleted &&
        purchases.isNotEmpty &&
        purchases.every(
          (p) =>
              p.status == PurchaseStatus.restored ||
              p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.error ||
              p.status == PurchaseStatus.canceled,
        )) {
      scheduleMicrotask(() {
        if (!restoreWait.isCompleted) {
          restoreWait.complete(List<PurchaseDetails>.from(_restoreBuffer));
        }
      });
    }
  }

  String _recoveryKey(PurchaseDetails purchase) {
    final txnId = purchase.purchaseID ?? '';
    final signed = purchase.verificationData.serverVerificationData;
    return '$txnId|$signed|${purchase.productID}';
  }

  /// Unfinished StoreKit txn with no active paywall purchase/restore.
  ///
  /// Verify → re-read trusted entitlement → complete only after verify.
  /// Never grants access locally.
  Future<void> _recoverUnfinished(PurchaseDetails purchase) async {
    if (!QmatchIapProductIds.isKnownAppleProduct(purchase.productID)) {
      return;
    }
    if (currentUid == null || currentUid!.isEmpty) {
      return;
    }
    try {
      await _settleVerifiedPurchase(purchase);
    } catch (_) {
      // Leave unfinished for a later session. Never complete or self-grant.
    }
  }

  Future<IapClientResult> _settleVerifiedPurchase(
    PurchaseDetails purchase,
  ) async {
    final uid = _requireUid();
    final key = _recoveryKey(purchase);
    if (!_inFlightRecovery.add(key)) {
      throw IapPurchaseFailedException(
        'Purchase is already being verified.',
      );
    }
    try {
      final signed = purchase.verificationData.serverVerificationData;
      final txnId = purchase.purchaseID ?? '';
      if (signed.isEmpty && txnId.isEmpty) {
        throw IapVerificationFailedException(
          code: 'missing_transaction_proof',
          message: 'StoreKit returned no signed transaction or transaction id.',
        );
      }

      Map<String, dynamic> backendResponse;
      try {
        backendResponse = await _backend.verifyAndApplyPurchase(
          signedTransaction: signed,
          transactionId: txnId,
        );
      } catch (e) {
        throw IapVerificationFailedException(
          code: 'verify_callable_failed',
          message: e.toString(),
        );
      }

      if (!IapBackendClient.isTrustedVerified(backendResponse)) {
        throw IapVerificationFailedException(
          code: (backendResponse['code'] as String?) ?? 'verification_failed',
          message: (backendResponse['message'] as String?) ??
              'Backend rejected purchase verification.',
          response: backendResponse,
        );
      }

      final entitlement = await _entitlements.fetch(uid);
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      return IapClientResult(
        backendResponse: backendResponse,
        entitlement: entitlement,
        productId: purchase.productID,
      );
    } finally {
      _inFlightRecovery.remove(key);
    }
  }

  /// Load frozen Apple launch products from StoreKit.
  Future<List<ProductDetails>> loadProducts() async {
    _ensureIos();
    _requireUid();
    startListening();

    if (!await _store.isAvailable()) {
      throw IapStoreUnavailableException();
    }

    final response =
        await _store.queryProductDetails(QmatchIapProductIds.appleLaunchIds);
    if (response.error != null) {
      throw IapStoreUnavailableException(response.error!.message);
    }
    return response.productDetails
        .where((p) => QmatchIapProductIds.isKnownAppleProduct(p.id))
        .toList(growable: false);
  }

  /// Purchase a known Apple SKU. Entitlement only after backend verify + Firestore.
  Future<IapClientResult> purchase(String productId) async {
    _ensureIos();
    final uid = _requireUid();
    startListening();

    if (!QmatchIapProductIds.isKnownAppleProduct(productId)) {
      throw IapProductUnavailableException(productId);
    }

    final products = await loadProducts();
    ProductDetails? details;
    for (final p in products) {
      if (p.id == productId) {
        details = p;
        break;
      }
    }
    if (details == null) {
      throw IapProductUnavailableException(productId);
    }

    final completer = Completer<PurchaseDetails>();
    _pendingPurchases[productId] = completer;

    final param = PurchaseParam(
      productDetails: details,
      // Apple appAccountToken = UUID v5(uid); backend derives the same value.
      applicationUserName: AppleAppAccountToken.fromUid(uid),
    );

    final initiated = QmatchIapProductIds.isConsumable(productId)
        ? await _store.buyConsumable(
            purchaseParam: param,
            autoConsume: false,
          )
        : await _store.buyNonConsumable(purchaseParam: param);

    if (!initiated) {
      _pendingPurchases.remove(productId);
      throw IapPurchaseFailedException(
          'StoreKit rejected purchase initiation.');
    }

    late final PurchaseDetails purchase;
    try {
      purchase = await completer.future.timeout(_purchaseTimeout);
    } on TimeoutException {
      _pendingPurchases.remove(productId);
      throw IapPurchaseFailedException(
          'Timed out waiting for StoreKit update.');
    }

    if (purchase.status == PurchaseStatus.canceled) {
      throw IapPurchaseCanceledException();
    }
    if (purchase.status == PurchaseStatus.error) {
      throw IapPurchaseFailedException(
        purchase.error?.message ?? 'StoreKit purchase error',
      );
    }
    if (purchase.status == PurchaseStatus.pending) {
      throw IapPurchaseFailedException('Purchase is still pending.');
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      throw IapPurchaseFailedException('Unexpected purchase status.');
    }

    // NEVER grant from StoreKit alone — verify with trusted backend.
    return _settleVerifiedPurchase(purchase);
  }

  /// Restore Purchases → collect StoreKit txns → `restorePurchases` callable.
  Future<IapClientResult> restorePurchases() async {
    _ensureIos();
    final uid = _requireUid();
    startListening();

    if (!await _store.isAvailable()) {
      throw IapStoreUnavailableException();
    }

    _restoreBuffer.clear();
    final restoreWait = Completer<List<PurchaseDetails>>();
    _restoreCompleter = restoreWait;

    await _store.restorePurchases(
      applicationUserName: AppleAppAccountToken.fromUid(uid),
    );

    List<PurchaseDetails> restored;
    try {
      restored = await restoreWait.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => List<PurchaseDetails>.from(_restoreBuffer),
      );
    } finally {
      _restoreCompleter = null;
    }

    final transactions = <Map<String, String>>[];
    final seen = <String>{};
    for (final p in restored) {
      if (p.status != PurchaseStatus.restored &&
          p.status != PurchaseStatus.purchased) {
        continue;
      }
      final signed = p.verificationData.serverVerificationData;
      final txnId = p.purchaseID ?? '';
      final key = '$txnId|$signed';
      if (!seen.add(key)) continue;
      if (signed.isEmpty && txnId.isEmpty) continue;
      transactions.add({
        if (signed.isNotEmpty) 'signedTransaction': signed,
        if (txnId.isNotEmpty) 'transactionId': txnId,
      });
    }

    if (transactions.isEmpty) {
      throw IapVerificationFailedException(
        code: 'no_restorable_transactions',
        message: 'No Apple transactions available to restore.',
      );
    }

    Map<String, dynamic> backendResponse;
    try {
      backendResponse = await _backend.restorePurchases(
        transactions: transactions,
      );
    } catch (e) {
      throw IapVerificationFailedException(
        code: 'restore_callable_failed',
        message: e.toString(),
      );
    }

    if (!IapBackendClient.isTrustedRestore(backendResponse)) {
      throw IapVerificationFailedException(
        code: (backendResponse['code'] as String?) ?? 'restore_failed',
        message: (backendResponse['message'] as String?) ??
            'Backend rejected restore verification.',
        response: backendResponse,
      );
    }

    for (final p in restored) {
      if (p.pendingCompletePurchase) {
        await _store.completePurchase(p);
      }
    }

    final entitlement = await _entitlements.fetch(uid);
    return IapClientResult(
      backendResponse: backendResponse,
      entitlement: entitlement,
    );
  }

  /// Entitlement from trusted Firestore only.
  Future<EntitlementSnapshot> fetchEntitlement() async {
    final uid = _requireUid();
    return _entitlements.fetch(uid);
  }

  Stream<EntitlementSnapshot> watchEntitlement() {
    final uid = _requireUid();
    return _entitlements.watch(uid);
  }
}
