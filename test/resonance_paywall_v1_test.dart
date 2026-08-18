import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/iap_exceptions.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/features/iap/screens/resonance_paywall_screen.dart';
import 'package:qmatch/features/iap/services/ios_iap_client.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_controller.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_iap_port.dart';
import 'package:qmatch/features/settings/screens/legal_document_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

    test('dispose during purchase does not notify after dispose', () async {
      iap.products = [
        _product(QmatchIapProductIds.resonanceAnnual, '\$39.99'),
      ];
      iap.purchaseHold = Completer<IapClientResult>();
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
      var disposed = false;
      var notifiedAfterDispose = false;
      c.addListener(() {
        if (disposed) notifiedAfterDispose = true;
      });

      final pending = c.purchaseSelected();
      await Future<void>.value();
      expect(c.purchasing, isTrue);

      disposed = true;
      c.dispose();
      iap.purchaseHold!.complete(iap.purchaseResult!);

      expect(await pending, isTrue);
      expect(c.hasResonanceAccess, isTrue);
      expect(c.purchasing, isFalse);
      expect(notifiedAfterDispose, isFalse);
      expect(iap.purchasedIds, [QmatchIapProductIds.resonanceAnnual]);
    });

    test('dispose during restore does not notify after dispose', () async {
      iap.restoreHold = Completer<IapClientResult>();
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
      var disposed = false;
      var notifiedAfterDispose = false;
      c.addListener(() {
        if (disposed) notifiedAfterDispose = true;
      });

      final pending = c.restore();
      await Future<void>.value();
      expect(c.restoring, isTrue);

      disposed = true;
      c.dispose();
      iap.restoreHold!.complete(iap.restoreResult!);

      expect(await pending, isTrue);
      expect(c.hasResonanceAccess, isTrue);
      expect(c.restoring, isFalse);
      expect(notifiedAfterDispose, isFalse);
      expect(iap.restoreCalls, 1);
    });

    test('dispose during load does not notify after dispose', () async {
      iap.entitlementHold = Completer<EntitlementSnapshot>();
      iap.products = [
        _product(QmatchIapProductIds.resonanceAnnual, '\$39.99'),
      ];

      final c = ResonancePaywallController(iap: iap);
      var disposed = false;
      var notifiedAfterDispose = false;
      c.addListener(() {
        if (disposed) notifiedAfterDispose = true;
      });

      final pending = c.load();
      await Future<void>.value();
      expect(c.loading, isTrue);

      disposed = true;
      c.dispose();
      iap.entitlementHold!.complete(EntitlementSnapshot.free);

      await pending;
      expect(c.loading, isFalse);
      expect(c.annual?.id, QmatchIapProductIds.resonanceAnnual);
      expect(notifiedAfterDispose, isFalse);
    });

    test('successful active-screen purchase still notifies and unlocks',
        () async {
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
      var ticks = 0;
      c.addListener(() => ticks++);
      await c.load();
      final beforePurchase = ticks;
      final unlocked = await c.purchaseSelected();

      expect(unlocked, isTrue);
      expect(c.hasResonanceAccess, isTrue);
      expect(c.purchasing, isFalse);
      expect(ticks, greaterThan(beforePurchase));
      c.dispose();
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

      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 1600)),
            child: ResonancePaywallScreen(
              controller: controller,
              purchasesEnabledOverride: true,
              animateBackground: false,
            ),
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
      expect(find.text('Unlock Resonance'), findsWidgets);
      expect(
        find.byKey(const Key('qmatch-resonance-paywall-android-disabled')),
        findsNothing,
      );
    });

    testWidgets('loading spinner uses lilac not gold', (tester) async {
      final iap = FakePaywallIap()
        ..entitlementHold = Completer<EntitlementSnapshot>();
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
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byKey(const Key('qmatch-resonance-paywall-loading')),
      );
      expect(indicator.color, const Color(0xFFDAC8ED));
      expect(indicator.color, isNot(AppColors.softGold));
    });

    testWidgets('EN copy marks Who Liked You live and later benefits as coming',
        (tester) async {
      await _pumpPaywall(tester);

      expect(find.text('Unlock Resonance'), findsWidgets);
      expect(
        find.text(
          'Who Liked You is included with Resonance now. Resonance does not change who you match with or how ranking works.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-resonance-paywall-benefit-who-liked-you')),
        findsOneWidget,
      );
      expect(find.text('Who liked you'), findsOneWidget);
      expect(find.text('Included now'), findsOneWidget);
      expect(find.text('Rewind'), findsOneWidget);
      expect(find.text('Deeper compatibility explanations'), findsOneWidget);
      expect(find.text('Coming later — not available yet'), findsNWidgets(2));
      expect(
        find.textContaining('renews automatically'),
        findsOneWidget,
      );
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
      expect(find.textContaining('Super Resonance'), findsNothing);
      expect(find.textContaining('Boost'), findsNothing);
    });

    testWidgets('TR copy uses Unlock Resonance equivalent and later labels',
        (tester) async {
      await _pumpPaywall(tester, locale: const Locale('tr'));

      expect(find.text("Resonance'ı aç"), findsWidgets);
      expect(
        find.text(
          'Seni beğenenler Resonance ile şimdi dahil. Resonance kimi eşleştireceğini veya sıralamayı değiştirmez.',
        ),
        findsOneWidget,
      );
      expect(find.text('Seni beğenenler'), findsOneWidget);
      expect(find.text('Şimdi dahil'), findsOneWidget);
      expect(find.text('Rewind'), findsOneWidget);
      expect(find.text('Daha derin uyumluluk açıklamaları'), findsOneWidget);
      expect(find.text('Daha sonra gelecek — henüz yok'), findsNWidgets(2));
      expect(find.text('Kullanım Şartları'), findsOneWidget);
      expect(find.text('Gizlilik Politikası'), findsOneWidget);
    });

    testWidgets('Terms of Use opens LegalDocumentScreen', (tester) async {
      await _pumpPaywall(tester);
      final terms = find.byKey(const Key('qmatch-resonance-paywall-terms'));
      await tester.ensureVisible(terms);
      await tester.tap(terms);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.byKey(const Key('qmatch-legal-title')), findsOneWidget);
      expect(find.text('Terms of Use'), findsWidgets);
    });

    testWidgets('Privacy Policy opens LegalDocumentScreen', (tester) async {
      await _pumpPaywall(tester);
      final privacy = find.byKey(const Key('qmatch-resonance-paywall-privacy'));
      await tester.ensureVisible(privacy);
      await tester.tap(privacy);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.byKey(const Key('qmatch-legal-title')), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
    });

    testWidgets('active entitlement still shows Resonance active copy',
        (tester) async {
      final iap = FakePaywallIap()
        ..entitlement = const EntitlementSnapshot(
          uid: 'u1',
          tier: 'resonance',
          subscriptionState: 'active',
          resonanceAccess: true,
          superResonanceBalance: 0,
          boostBalance: 0,
        );
      await _pumpPaywall(tester, iap: iap);

      expect(
        find.byKey(const Key('qmatch-resonance-paywall-active')),
        findsOneWidget,
      );
      expect(find.text('Resonance is active on this account.'), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-resonance-paywall-purchase')),
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

  group('paywall copy wiring (source)', () {
    test('does not offer Super Resonance or Boost and uses legal documents',
        () {
      final src = File(
        'lib/features/iap/screens/resonance_paywall_screen.dart',
      ).readAsStringSync();
      expect(src.contains('LegalDocumentScreen'), isTrue);
      expect(src.contains('termsOfUseTitle'), isTrue);
      expect(src.contains('privacyPolicyTitle'), isTrue);
      expect(src.contains('Super Resonance'), isFalse);
      expect(src.contains('superResonance'), isFalse);
      expect(src.contains('Boost'), isFalse);
      expect(src.contains('resonancePaywallComingLater'), isTrue);
      expect(src.contains('resonancePaywallBenefitWhoLikedYou'), isTrue);
    });

    test('loading spinner uses lilac not gold', () {
      final src = File(
        'lib/features/iap/screens/resonance_paywall_screen.dart',
      ).readAsStringSync();
      final idx = src.indexOf('qmatch-resonance-paywall-loading');
      expect(idx, greaterThanOrEqualTo(0));
      final snippet = src.substring(idx, idx + 180);
      expect(snippet.contains('0xFFDAC8ED'), isTrue);
      expect(snippet.contains('softGold'), isFalse);
    });
  });
}

Future<void> _pumpPaywall(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  FakePaywallIap? iap,
}) async {
  final resolved = iap ??
      (FakePaywallIap()
        ..products = [
          _product(QmatchIapProductIds.resonanceMonthly, '₺499.99'),
          _product(QmatchIapProductIds.resonanceAnnual, '₺3.999,99'),
        ]);
  final controller = ResonancePaywallController(iap: resolved);
  await tester.binding.setSurfaceSize(const Size(390, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 1600)),
        child: ResonancePaywallScreen(
          controller: controller,
          purchasesEnabledOverride: true,
          animateBackground: false,
        ),
      ),
    ),
  );
  await tester.pump();
  await controller.load();
  await tester.pumpAndSettle();
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
  Completer<EntitlementSnapshot>? entitlementHold;
  Completer<IapClientResult>? purchaseHold;
  Completer<IapClientResult>? restoreHold;
  List<ProductDetails> products = [];
  IapClientResult? purchaseResult;
  IapClientResult? restoreResult;
  Object? purchaseError;
  Object? restoreError;
  final purchasedIds = <String>[];
  int restoreCalls = 0;

  @override
  Future<EntitlementSnapshot> fetchEntitlement() {
    final hold = entitlementHold;
    if (hold != null) return hold.future;
    return Future.value(entitlement);
  }

  @override
  Future<List<ProductDetails>> loadProducts() async => products;

  @override
  Future<IapClientResult> purchase(String productId) async {
    purchasedIds.add(productId);
    final hold = purchaseHold;
    if (hold != null) {
      final result = await hold.future;
      final err = purchaseError;
      if (err != null) throw err;
      return result;
    }
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
    final hold = restoreHold;
    if (hold != null) {
      final result = await hold.future;
      final err = restoreError;
      if (err != null) throw err;
      return result;
    }
    final err = restoreError;
    if (err != null) throw err;
    return restoreResult ??
        IapClientResult(
          backendResponse: const {},
          entitlement: entitlement,
        );
  }
}
