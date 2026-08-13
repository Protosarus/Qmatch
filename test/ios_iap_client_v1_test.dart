import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qmatch/features/iap/domain/apple_app_account_token.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/iap_exceptions.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/features/iap/services/entitlement_repository.dart';
import 'package:qmatch/features/iap/services/iap_backend_client.dart';
import 'package:qmatch/features/iap/services/iap_store_port.dart';
import 'package:qmatch/features/iap/services/ios_iap_client.dart';

void main() {
  group('AppleAppAccountToken', () {
    test('deterministic UUID v5 golden vectors match Functions', () {
      expect(AppleAppAccountToken.namespaceV1,
          'b3e1f9a0-7c4d-4e2b-9f1a-8d6c5b4a3e2f');
      expect(
        AppleAppAccountToken.fromUid('uid-1'),
        'c2089afd-fde1-5d45-b054-7d3f81339887',
      );
      expect(
        AppleAppAccountToken.fromUid('uid-1'),
        AppleAppAccountToken.fromUid('uid-1'),
      );
      expect(
        AppleAppAccountToken.fromUid('uid-1'),
        isNot(AppleAppAccountToken.fromUid('uid-2')),
      );
      expect(
        AppleAppAccountToken.fromUid('uid-1'),
        matches(RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        )),
      );
    });

    test('never uses raw uid as token', () {
      expect(AppleAppAccountToken.fromUid('uid-1'), isNot('uid-1'));
    });
  });

  group('QmatchIapProductIds', () {
    test('frozen Apple launch SKUs', () {
      expect(
        QmatchIapProductIds.appleLaunchIds,
        {
          'qmatch.resonance.monthly',
          'qmatch.resonance.annual',
          'qmatch.super_resonance.x1',
          'qmatch.boost.x1',
        },
      );
      expect(QmatchIapProductIds.isConsumable('qmatch.boost.x1'), isTrue);
      expect(
        QmatchIapProductIds.isSubscription('qmatch.resonance.monthly'),
        isTrue,
      );
    });
  });

  group('EntitlementSnapshot', () {
    test('fail closed when resonance_access missing or falsey', () {
      final missing = EntitlementSnapshot.fromMap('u1', {});
      expect(missing.resonanceAccess, isFalse);

      final stringTruthy = EntitlementSnapshot.fromMap('u1', {
        'resonance_access': 'true',
      });
      expect(stringTruthy.resonanceAccess, isFalse);

      final trusted = EntitlementSnapshot.fromMap('u1', {
        'tier': 'resonance',
        'subscription_state': 'active',
        'resonance_access': true,
        'super_resonance_balance': 2,
        'boost_balance': 1,
      });
      expect(trusted.resonanceAccess, isTrue);
      expect(trusted.superResonanceBalance, 2);
      expect(trusted.boostBalance, 1);
    });
  });

  group('IapBackendClient helpers', () {
    test('isTrustedVerified requires ok+trusted+verified', () {
      expect(IapBackendClient.isTrustedVerified(null), isFalse);
      expect(
        IapBackendClient.isTrustedVerified({
          'ok': true,
          'trusted': false,
          'verified': true,
        }),
        isFalse,
      );
      expect(
        IapBackendClient.isTrustedVerified({
          'ok': true,
          'trusted': true,
          'verified': true,
        }),
        isTrue,
      );
    });
  });

  group('IosIapClient', () {
    late FakeIapStore store;
    late List<Map<String, dynamic>> verifyCalls;
    late List<Map<String, dynamic>> restoreCalls;
    late EntitlementSnapshot entitlementState;

    setUp(() {
      store = FakeIapStore();
      verifyCalls = [];
      restoreCalls = [];
      entitlementState = const EntitlementSnapshot(
        uid: 'uid-1',
        tier: 'free',
        subscriptionState: 'none',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 0,
      );
    });

    IosIapClient buildClient({
      String? uid = 'uid-1',
      bool isIos = true,
      Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
          call,
    }) {
      return IosIapClient(
        store: store,
        isIosOverride: isIos,
        uidProvider: () => uid,
        entitlements: EntitlementRepository(
          fetchOverride: (u) async => entitlementState.uid.isEmpty
              ? entitlementState
              : EntitlementSnapshot(
                  uid: u,
                  tier: entitlementState.tier,
                  subscriptionState: entitlementState.subscriptionState,
                  resonanceAccess: entitlementState.resonanceAccess,
                  superResonanceBalance:
                      entitlementState.superResonanceBalance,
                  boostBalance: entitlementState.boostBalance,
                ),
        ),
        backend: IapBackendClient(
          call: call ??
              (name, data) async {
                if (name == IapBackendClient.verifyAndApplyPurchaseName) {
                  verifyCalls.add(data);
                  return {
                    'ok': true,
                    'trusted': true,
                    'verified': true,
                    'repository_applied': true,
                    'resonance_access': true,
                  };
                }
                if (name == IapBackendClient.restorePurchasesName) {
                  restoreCalls.add(data);
                  return {
                    'ok': true,
                    'trusted': true,
                    'verified': true,
                    'restored_count': 1,
                    'repository_applied': true,
                  };
                }
                fail('unexpected callable $name');
              },
        ),
      );
    }

    test('Android / non-iOS purchase path is disabled', () async {
      final client = buildClient(isIos: false);
      expect(
        () => client.loadProducts(),
        throwsA(isA<IapPlatformDisabledException>()),
      );
    });

    test('requires Firebase auth uid', () async {
      final client = buildClient(uid: null);
      expect(
        () => client.purchase(QmatchIapProductIds.resonanceMonthly),
        throwsA(isA<IapAuthRequiredException>()),
      );
    });

    test('purchase sets deterministic UUID appAccountToken and verifies',
        () async {
      store.products = [
        _product(QmatchIapProductIds.resonanceMonthly),
      ];
      store.nextPurchase = _purchase(
        productId: QmatchIapProductIds.resonanceMonthly,
        status: PurchaseStatus.purchased,
        signed: 'jws-monthly',
        purchaseId: 'txn-1',
        pendingComplete: true,
      );

      entitlementState = const EntitlementSnapshot(
        uid: 'uid-1',
        tier: 'resonance',
        subscriptionState: 'active',
        resonanceAccess: true,
        superResonanceBalance: 0,
        boostBalance: 0,
      );

      final client = buildClient();
      final result =
          await client.purchase(QmatchIapProductIds.resonanceMonthly);

      expect(
        store.lastApplicationUserName,
        AppleAppAccountToken.fromUid('uid-1'),
      );
      expect(store.lastApplicationUserName, isNot('uid-1'));
      expect(store.completedPurchaseIds, ['txn-1']);
      expect(verifyCalls, hasLength(1));
      expect(verifyCalls.single['platform'], 'ios');
      expect(verifyCalls.single['signedTransaction'], 'jws-monthly');
      expect(verifyCalls.single['transactionId'], 'txn-1');
      expect(result.entitlement.resonanceAccess, isTrue);
      // Access came from entitlement repo snapshot, not inventing from StoreKit.
      expect(result.resonanceAccess, result.entitlement.resonanceAccess);
    });

    test('fail closed on verification error — no completePurchase grant path',
        () async {
      store.products = [
        _product(QmatchIapProductIds.superResonanceX1),
      ];
      store.nextPurchase = _purchase(
        productId: QmatchIapProductIds.superResonanceX1,
        status: PurchaseStatus.purchased,
        signed: 'jws-sr',
        purchaseId: 'txn-sr',
        pendingComplete: true,
      );

      final client = buildClient(
        call: (name, data) async {
          verifyCalls.add(data);
          return {
            'ok': false,
            'trusted': false,
            'verified': false,
            'code': 'uid_binding_mismatch',
            'resonance_access': false,
          };
        },
      );

      await expectLater(
        client.purchase(QmatchIapProductIds.superResonanceX1),
        throwsA(
          isA<IapVerificationFailedException>().having(
            (e) => e.code,
            'code',
            'uid_binding_mismatch',
          ),
        ),
      );
      expect(store.completedPurchaseIds, isEmpty);
      expect(entitlementState.resonanceAccess, isFalse);
    });

    test('never treats StoreKit success alone as resonance access', () async {
      store.products = [
        _product(QmatchIapProductIds.resonanceAnnual),
      ];
      store.nextPurchase = _purchase(
        productId: QmatchIapProductIds.resonanceAnnual,
        status: PurchaseStatus.purchased,
        signed: 'jws-annual',
        purchaseId: 'txn-a',
        pendingComplete: true,
      );

      // Backend trusted, but Firestore still free (e.g. apply pending / lag).
      entitlementState = const EntitlementSnapshot(
        uid: 'uid-1',
        tier: 'free',
        subscriptionState: 'none',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 0,
      );

      final client = buildClient();
      final result =
          await client.purchase(QmatchIapProductIds.resonanceAnnual);

      expect(result.backendResponse['trusted'], isTrue);
      expect(result.entitlement.resonanceAccess, isFalse);
    });

    test('restorePurchases calls restore callable with Apple transactions',
        () async {
      store.restoreEmits = [
        _purchase(
          productId: QmatchIapProductIds.resonanceMonthly,
          status: PurchaseStatus.restored,
          signed: 'jws-r1',
          purchaseId: 'txn-r1',
          pendingComplete: true,
        ),
      ];

      entitlementState = const EntitlementSnapshot(
        uid: 'uid-1',
        tier: 'resonance',
        subscriptionState: 'active',
        resonanceAccess: true,
        superResonanceBalance: 0,
        boostBalance: 0,
      );

      final client = buildClient();
      final result = await client.restorePurchases();

      expect(
        store.lastRestoreApplicationUserName,
        AppleAppAccountToken.fromUid('uid-1'),
      );
      expect(store.lastRestoreApplicationUserName, isNot('uid-1'));
      expect(restoreCalls, hasLength(1));
      expect(restoreCalls.single['platform'], 'ios');
      final txns = restoreCalls.single['transactions'] as List;
      expect(txns, hasLength(1));
      expect(txns.single['signedTransaction'], 'jws-r1');
      expect(txns.single['transactionId'], 'txn-r1');
      expect(result.entitlement.resonanceAccess, isTrue);
      expect(store.completedPurchaseIds, ['txn-r1']);
    });

    test('restore fails closed when backend rejects', () async {
      store.restoreEmits = [
        _purchase(
          productId: QmatchIapProductIds.resonanceMonthly,
          status: PurchaseStatus.restored,
          signed: 'jws-bad',
          purchaseId: 'txn-bad',
        ),
      ];

      final client = buildClient(
        call: (name, data) async {
          restoreCalls.add(data);
          return {
            'ok': false,
            'trusted': false,
            'verified': false,
            'restored_count': 0,
            'code': 'restore_failed',
          };
        },
      );

      await expectLater(
        client.restorePurchases(),
        throwsA(isA<IapVerificationFailedException>()),
      );
      expect(store.completedPurchaseIds, isEmpty);
    });

    test('consumable uses buyConsumable with autoConsume false', () async {
      store.products = [_product(QmatchIapProductIds.boostX1)];
      store.nextPurchase = _purchase(
        productId: QmatchIapProductIds.boostX1,
        status: PurchaseStatus.purchased,
        signed: 'jws-boost',
        purchaseId: 'txn-b',
        pendingComplete: true,
      );

      entitlementState = const EntitlementSnapshot(
        uid: 'uid-1',
        tier: 'free',
        subscriptionState: 'none',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 1,
      );

      final client = buildClient();
      await client.purchase(QmatchIapProductIds.boostX1);

      expect(store.lastBuyMode, 'consumable');
      expect(store.lastAutoConsume, isFalse);
    });
  });
}

ProductDetails _product(String id) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: '\$1.00',
      rawPrice: 1,
      currencyCode: 'USD',
    );

PurchaseDetails _purchase({
  required String productId,
  required PurchaseStatus status,
  required String signed,
  required String purchaseId,
  bool pendingComplete = false,
}) {
  final p = PurchaseDetails(
    productID: productId,
    purchaseID: purchaseId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: signed,
      source: 'app_store',
    ),
    transactionDate: '0',
    status: status,
  );
  p.pendingCompletePurchase = pendingComplete;
  return p;
}

class FakeIapStore implements IapStorePort {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  List<ProductDetails> products = [];
  PurchaseDetails? nextPurchase;
  List<PurchaseDetails> restoreEmits = [];
  String? lastApplicationUserName;
  String? lastRestoreApplicationUserName;
  String? lastBuyMode;
  bool? lastAutoConsume;
  final completedPurchaseIds = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: products
          .where((p) => identifiers.contains(p.id))
          .toList(growable: false),
      notFoundIDs: identifiers
          .where((id) => products.every((p) => p.id != id))
          .toList(),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastBuyMode = 'non_consumable';
    lastApplicationUserName = purchaseParam.applicationUserName;
    final purchase = nextPurchase;
    if (purchase != null) {
      scheduleMicrotask(() => _controller.add([purchase]));
    }
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    lastBuyMode = 'consumable';
    lastAutoConsume = autoConsume;
    lastApplicationUserName = purchaseParam.applicationUserName;
    final purchase = nextPurchase;
    if (purchase != null) {
      scheduleMicrotask(() => _controller.add([purchase]));
    }
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    lastRestoreApplicationUserName = applicationUserName;
    final emits = List<PurchaseDetails>.from(restoreEmits);
    scheduleMicrotask(() {
      if (emits.isNotEmpty) {
        _controller.add(emits);
      }
    });
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchaseIds.add(purchase.purchaseID ?? purchase.productID);
  }
}
