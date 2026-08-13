import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/iap_exceptions.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/features/iap/screens/resonance_paywall_screen.dart';
import 'package:qmatch/features/iap/services/ios_iap_client.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_controller.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_iap_port.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  group('ResonancePaywallController', () {
    late FakePaywallIap iap;

    setUp(() {
      iap = FakePaywallIap();
    });

    test('loads localized plans without granting access locally', () async {
      iap.entitlement = const EntitlementSnapshot(
        uid: 'u1',
        tier: 'free',
        subscriptionState: 'none',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 0,
      );
      iap.products = [
        _product(QmatchIapProductIds.resonanceMonthly, '₺499.99'),
        _product(QmatchIapProductIds.resonanceAnnual, '₺3.999,99'),
      ];

      final c = ResonancePaywallController(iap: iap);
      await c.load();

      expect(c.loading, isFalse);
      expect(c.monthly?.price, '₺499.99');
      expect(c.annual?.price, '₺3.999,99');
      expect(c.hasResonanceAccess, isFalse);
      expect(c.selectedProductId, QmatchIapProductIds.resonanceAnnual);
    });

    test('purchase refreshes entitlement from trusted result only', () async {
      iap.products = [
        _product(QmatchIapProductIds.resonanceAnnual, '\$39.99'),
      ];
      iap.purchaseResult = IapClientResult(
        backendResponse: const {
          'ok': true,
          'trusted': true,
          'verified': true,
        },
        entitlement: const EntitlementSnapshot(
          uid: 'u1',
          tier: 'resonance',
          subscriptionState: 'active',
          resonanceAccess: true,
          superResonanceBalance: 0,
          boostBalance: 0,
        ),
        productId: QmatchIapProductIds.resonanceAnnual,
      );

      final c = ResonancePaywallController(iap: iap);
      await c.load();
      final unlocked = await c.purchaseSelected();

      expect(iap.purchasedIds, [QmatchIapProductIds.resonanceAnnual]);
      expect(unlocked, isTrue);
      expect(c.hasResonanceAccess, isTrue);
    });

    test('verification failure fails closed — no local Resonance grant',
        () async {
      iap.products = [
        _product(QmatchIapProductIds.resonanceMonthly, '\$4.99'),
      ];
      iap.purchaseError = IapVerificationFailedException(
        code: 'verification_failed',
        message: 'Backend rejected purchase verification.',
      );

      final c = ResonancePaywallController(iap: iap);
      await c.load();
      c.selectProduct(QmatchIapProductIds.resonanceMonthly);
      final unlocked = await c.purchaseSelected();

      expect(unlocked, isFalse);
      expect(c.hasResonanceAccess, isFalse);
      expect(c.errorMessage, contains('Backend rejected'));
    });

    test('restore refreshes entitlement from trusted backend', () async {
      iap.restoreResult = IapClientResult(
        backendResponse: const {
          'ok': true,
          'trusted': true,
          'verified': true,
        },
        entitlement: const EntitlementSnapshot(
          uid: 'u1',
          tier: 'resonance',
          subscriptionState: 'active',
          resonanceAccess: true,
          superResonanceBalance: 0,
          boostBalance: 0,
        ),
      );

      final c = ResonancePaywallController(iap: iap);
      await c.load();
      final unlocked = await c.restore();

      expect(iap.restoreCalls, 1);
      expect(unlocked, isTrue);
      expect(c.hasResonanceAccess, isTrue);
    });

    test('Android / purchasesEnabled false blocks purchase and restore',
        () async {
      final c = ResonancePaywallController(
        iap: iap,
        purchasesEnabled: false,
      );
      await c.load();
      expect(c.availablePlans, isEmpty);

      expect(await c.purchaseSelected(), isFalse);
      expect(await c.restore(), isFalse);
      expect(iap.purchasedIds, isEmpty);
      expect(iap.restoreCalls, 0);
      expect(c.hasResonanceAccess, isFalse);
    });

    test('StoreKit-shaped success without entitlement access stays locked',
        () async {
      iap.products = [
        _product(QmatchIapProductIds.resonanceAnnual, '\$39.99'),
      ];
      // Backend trusted call returned, but snapshot still free (fail-closed UX).
      iap.purchaseResult = IapClientResult(
        backendResponse: const {
          'ok': true,
          'trusted': true,
          'verified': true,
        },
        entitlement: const EntitlementSnapshot(
          uid: 'u1',
          tier: 'free',
          subscriptionState: 'none',
          resonanceAccess: false,
          superResonanceBalance: 0,
          boostBalance: 0,
        ),
      );

      final c = ResonancePaywallController(iap: iap);
      await c.load();
      final unlocked = await c.purchaseSelected();
      expect(unlocked, isFalse);
      expect(c.hasResonanceAccess, isFalse);
    });
  });

  group('ResonancePaywallScreen', () {
    testWidgets('renders monthly/annual StoreKit prices and actions',
        (tester) async {
      final iap = FakePaywallIap()
        ..products = [
          _product(QmatchIapProductIds.resonanceMonthly, '₺499.99'),
          _product(QmatchIapProductIds.resonanceAnnual, '₺3.999,99'),
        ];
      final controller = ResonancePaywallController(iap: iap);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResonancePaywallScreen(
            controller: controller,
            purchasesEnabledOverride: true,
            animateBackground: false,
          ),
        ),
      );
      await tester.pump();
      await controller.load();
      await tester.pumpAndSettle();

      expect(find.text('₺499.99'), findsOneWidget);
      expect(find.text('₺3.999,99'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-resonance-paywall-purchase')),
          findsOneWidget);
      expect(find.byKey(const Key('qmatch-resonance-paywall-restore')),
          findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-resonance-paywall-android-disabled')),
        findsNothing,
      );
    });

    testWidgets('shows Android disabled state without purchase actions',
        (tester) async {
      final controller = ResonancePaywallController(
        iap: FakePaywallIap(),
        purchasesEnabled: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ResonancePaywallScreen(
            controller: controller,
            purchasesEnabledOverride: false,
            animateBackground: false,
          ),
        ),
      );
      await tester.pump();
      await controller.load();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('qmatch-resonance-paywall-android-disabled')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('qmatch-resonance-paywall-purchase')),
          findsNothing);
    });
  });
}

ProductDetails _product(String id, String price) => ProductDetails(
      id: id,
      title: id,
      description: id,
      price: price,
      rawPrice: 1,
      currencyCode: 'USD',
    );

class FakePaywallIap implements ResonancePaywallIapPort {
  EntitlementSnapshot entitlement = EntitlementSnapshot.free;
  List<ProductDetails> products = [];
  IapClientResult? purchaseResult;
  IapClientResult? restoreResult;
  Object? purchaseError;
  Object? restoreError;
  final purchasedIds = <String>[];
  int restoreCalls = 0;

  @override
  Future<EntitlementSnapshot> fetchEntitlement() async => entitlement;

  @override
  Future<List<ProductDetails>> loadProducts() async => products;

  @override
  Future<IapClientResult> purchase(String productId) async {
    purchasedIds.add(productId);
    final err = purchaseError;
    if (err != null) throw err;
    return purchaseResult ??
        IapClientResult(
          backendResponse: const {},
          entitlement: entitlement,
          productId: productId,
        );
  }

  @override
  Future<IapClientResult> restorePurchases() async {
    restoreCalls += 1;
    final err = restoreError;
    if (err != null) throw err;
    return restoreResult ??
        IapClientResult(
          backendResponse: const {},
          entitlement: entitlement,
        );
  }
}
