import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:qmatch/features/discover/widgets/qmatch_super_resonance_purchase_sheet.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/iap_exceptions.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/features/iap/domain/qmatch_purchase_error_kind.dart';
import 'package:qmatch/features/iap/screens/resonance_paywall_screen.dart';
import 'package:qmatch/features/iap/services/ios_iap_client.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_controller.dart';
import 'package:qmatch/features/iap/services/resonance_paywall_iap_port.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/who_liked_you/screens/who_liked_you_screen.dart';
import 'package:qmatch/features/who_liked_you/services/super_resonance_inbox_client.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final en = AppLocalizationsEn();

  test('EN/TR purchase error copy matches the product contract', () {
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(tr.superResonancePurchaseFailedTitle, 'Super Resonance alınamadı');
    expect(
      tr.superResonancePurchaseFailedBody,
      'İşlem tamamlanamadı. Biraz sonra yeniden deneyebilirsin.',
    );
    expect(tr.resonancePurchaseFailedTitle, 'Resonance etkinleştirilemedi');
    expect(
      tr.resonancePurchaseFailedBody,
      'Satın alma işlemi tamamlanamadı. Lütfen biraz sonra yeniden dene.',
    );
    expect(tr.iapVerificationFailedTitle, 'İşlem tamamlanamadı');
    expect(
      tr.iapVerificationFailedBody,
      'Ödeme doğrulanırken bir sorun oluştu. Satın alımın varsa yeniden yüklemeyi deneyebilirsin.',
    );

    expect(
        en.superResonancePurchaseFailedTitle, "Couldn't get Super Resonance");
    expect(
      en.superResonancePurchaseFailedBody,
      "The purchase didn't complete. You can try again in a moment.",
    );
    expect(en.resonancePurchaseFailedTitle, "Couldn't activate Resonance");
    expect(
      en.resonancePurchaseFailedBody,
      "The purchase didn't complete. Please try again in a moment.",
    );
    expect(en.iapVerificationFailedTitle, "Couldn't complete this");
    expect(
      en.iapVerificationFailedBody,
      'There was a problem confirming the payment. If you already purchased, you can try Restore Purchases.',
    );
    expect(tr.iapAlreadyOwnedTitle, 'Bu satın alım zaten mevcut');
    expect(
      tr.iapAlreadyOwnedBody,
      "Erişimini yenilemek için Satın Alımları Geri Yükle'yi kullanabilirsin.",
    );
    expect(en.iapAlreadyOwnedTitle, 'You already have this purchase');
    expect(
      en.iapAlreadyOwnedBody,
      'Use Restore Purchases to refresh your access.',
    );
  });

  test('cancel is classified as silent', () {
    expect(
      classifyPurchaseException(
        IapPurchaseCanceledException(),
        productFailure: QmatchPurchaseErrorKind.superResonanceConsumable,
      ),
      isNull,
    );
  });

  test('already-owned StoreKit signals classify as alreadyOwned', () {
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException(
          'This In-App Purchase has already been bought.',
        ),
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      ),
      QmatchPurchaseErrorKind.alreadyOwned,
    );
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException(
          'StoreKit purchase error',
          storeCode: 'itemAlreadyOwned',
        ),
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      ),
      QmatchPurchaseErrorKind.alreadyOwned,
    );
    expect(
      looksLikeAlreadyOwnedStoreError(
        IapPurchaseFailedException(
          'SKErrorDomain',
          storeCode: 'purchase_error',
          storeDetails: '{NSLocalizedDescription: You are currently subscribed}',
        ),
      ),
      isTrue,
    );
  });

  test('generic StoreKit error is not classified as already-owned', () {
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException('StoreKit purchase error'),
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      ),
      QmatchPurchaseErrorKind.resonanceSubscription,
    );
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException(
          'SKErrorDomain',
          storeCode: 'purchase_error',
        ),
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      ),
      QmatchPurchaseErrorKind.resonanceSubscription,
    );
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException('Purchase is still pending.'),
        productFailure: QmatchPurchaseErrorKind.resonanceSubscription,
      ),
      QmatchPurchaseErrorKind.resonanceSubscription,
    );
    expect(
      classifyPurchaseException(
        IapPurchaseFailedException(
          'already been bought',
        ),
        productFailure: QmatchPurchaseErrorKind.superResonanceConsumable,
      ),
      QmatchPurchaseErrorKind.superResonanceConsumable,
    );
    expect(
      looksLikeAlreadyOwnedStoreError(
        IapPurchaseFailedException('StoreKit purchase error'),
      ),
      isFalse,
    );
  });

  testWidgets('user cancel is silent in Super Resonance sheet', (tester) async {
    await _pumpSrSheet(
      tester,
      purchase: () async => throw IapPurchaseCanceledException(),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-super-resonance-purchase-cta')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.byKey(const Key('qmatch-super-resonance-purchase-error')),
      findsNothing,
    );
    expect(find.text(en.superResonancePurchaseFailedTitle), findsNothing);
    expect(find.text(en.iapVerificationFailedTitle), findsNothing);
    expect(
      find.byKey(const Key('qmatch-super-resonance-purchase-sheet')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Super Resonance failure uses Super Resonance copy, not a snackbar',
      (tester) async {
    await _pumpSrSheet(
      tester,
      purchase: () async => throw IapPurchaseFailedException('StoreKit'),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-super-resonance-purchase-cta')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(en.superResonancePurchaseFailedTitle), findsOneWidget);
    expect(find.text(en.superResonancePurchaseFailedBody), findsOneWidget);
    expect(find.text(en.resonancePurchaseFailedTitle), findsNothing);
    expect(find.text(en.iapVerificationFailedTitle), findsNothing);
    expect(find.text(en.discoverSuperResonancePurchaseFailed), findsNothing);
  });

  testWidgets('Super Resonance verification failure uses verification copy',
      (tester) async {
    await _pumpSrSheet(
      tester,
      purchase: () async => throw IapVerificationFailedException(
        code: 'verification_failed',
        message: 'Backend rejected purchase verification.',
      ),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-super-resonance-purchase-cta')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(en.iapVerificationFailedTitle), findsOneWidget);
    expect(find.text(en.iapVerificationFailedBody), findsOneWidget);
    expect(find.text(en.superResonancePurchaseFailedTitle), findsNothing);
    expect(find.text('Backend rejected purchase verification.'), findsNothing);
  });

  testWidgets('Resonance purchase failure uses subscription copy',
      (tester) async {
    await _pumpPaywall(
      tester,
      purchaseError: IapPurchaseFailedException('StoreKit purchase error'),
    );
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-resonance-paywall-purchase')),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-resonance-paywall-purchase')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.byKey(const Key('qmatch-resonance-paywall-error')),
      findsOneWidget,
    );
    expect(find.text(en.resonancePurchaseFailedTitle), findsOneWidget);
    expect(find.text(en.resonancePurchaseFailedBody), findsOneWidget);
    expect(find.text(en.superResonancePurchaseFailedTitle), findsNothing);
    expect(find.text(en.iapAlreadyOwnedTitle), findsNothing);
    expect(find.text('StoreKit purchase error'), findsNothing);
    expect(
      find.byKey(const Key('qmatch-purchase-error-restore')),
      findsNothing,
    );
  });

  testWidgets('Resonance verification failure uses verification copy',
      (tester) async {
    await _pumpPaywall(
      tester,
      purchaseError: IapVerificationFailedException(
        code: 'verification_failed',
        message: 'Backend rejected purchase verification.',
      ),
    );
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-resonance-paywall-purchase')),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-resonance-paywall-purchase')));
    await tester.pumpAndSettle();

    expect(find.text(en.iapVerificationFailedTitle), findsOneWidget);
    expect(find.text(en.iapVerificationFailedBody), findsOneWidget);
    expect(find.text(en.resonancePurchaseFailedTitle), findsNothing);
    expect(find.text('Backend rejected purchase verification.'), findsNothing);
  });

  testWidgets('Resonance cancel is silent', (tester) async {
    await _pumpPaywall(
      tester,
      purchaseError: IapPurchaseCanceledException(),
    );
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-resonance-paywall-purchase')),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-resonance-paywall-purchase')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.byKey(const Key('qmatch-resonance-paywall-error')),
      findsNothing,
    );
    expect(find.text(en.resonancePurchaseFailedTitle), findsNothing);
  });

  testWidgets(
      'failed StoreKit with trusted access pops paywall without error banner',
      (tester) async {
    bool? popped;
    final iap = _FakePaywallIap()
      ..products = [
        ProductDetails(
          id: QmatchIapProductIds.resonanceAnnual,
          title: 'Annual',
          description: 'Annual',
          price: '\$39.99',
          rawPrice: 39.99,
          currencyCode: 'USD',
        ),
      ]
      ..purchaseError = IapPurchaseFailedException('StoreKit purchase error')
      ..entitlementAfterPurchase = const EntitlementSnapshot(
        uid: 'u1',
        tier: 'resonance',
        subscriptionState: 'active',
        resonanceAccess: true,
        superResonanceBalance: 0,
        boostBalance: 0,
      );
    final controller = ResonancePaywallController(iap: iap);
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return TextButton(
              key: const Key('qmatch-open-paywall'),
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => MediaQuery(
                      data: const MediaQueryData(size: Size(390, 1600)),
                      child: ResonancePaywallScreen(
                        controller: controller,
                        purchasesEnabledOverride: true,
                        animateBackground: false,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('qmatch-open-paywall')));
    await tester.pump();
    await controller.load();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('qmatch-resonance-paywall-purchase')),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-resonance-paywall-purchase')));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(
      find.byKey(const Key('qmatch-resonance-paywall-error')),
      findsNothing,
    );
    expect(find.text(en.resonancePurchaseFailedTitle), findsNothing);
    expect(find.text(en.iapAlreadyOwnedTitle), findsNothing);
  });

  testWidgets('already-owned classified error shows restore copy and action',
      (tester) async {
    await _pumpPaywall(
      tester,
      purchaseError: IapPurchaseFailedException(
        'This In-App Purchase has already been bought.',
      ),
    );
    await tester.ensureVisible(
      find.byKey(const Key('qmatch-resonance-paywall-purchase')),
    );
    await tester
        .tap(find.byKey(const Key('qmatch-resonance-paywall-purchase')));
    await tester.pumpAndSettle();

    expect(find.text(en.iapAlreadyOwnedTitle), findsOneWidget);
    expect(find.text(en.iapAlreadyOwnedBody), findsOneWidget);
    expect(find.text(en.resonancePurchaseFailedTitle), findsNothing);
    expect(
      find.byKey(const Key('qmatch-purchase-error-restore')),
      findsOneWidget,
    );
    expect(find.text('Restore Purchases'), findsWidgets);

    await tester.tap(find.byKey(const Key('qmatch-purchase-error-restore')));
    await tester.pumpAndSettle();
    expect(_lastPaywallIap!.restoreCalls, 1);
  });

  testWidgets('purchase error does not survive navigation to Alignment Signals',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _PurchaseThenSignalsHost(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('qmatch-open-sr-purchase')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('qmatch-super-resonance-purchase-cta')));
    await tester.pumpAndSettle();
    expect(find.text(en.superResonancePurchaseFailedTitle), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('qmatch-super-resonance-purchase-dismiss')));
    await tester.pumpAndSettle();
    expect(find.text(en.superResonancePurchaseFailedTitle), findsNothing);

    await tester.tap(find.byKey(const Key('qmatch-open-alignment-signals')));
    await tester.pumpAndSettle();

    expect(find.text('Alignment Signals'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(en.superResonancePurchaseFailedTitle), findsNothing);
    expect(find.text(en.superResonancePurchaseFailedBody), findsNothing);
    expect(find.text(en.discoverSuperResonancePurchaseFailed), findsNothing);
    expect(
      find.byKey(const Key('qmatch-super-resonance-purchase-error')),
      findsNothing,
    );
  });

  test('Super Resonance sheet no longer posts a red snackbar', () {
    final src = File(
      'lib/features/discover/widgets/qmatch_super_resonance_purchase_sheet.dart',
    ).readAsStringSync();
    expect(src.contains('showSnackBar'), isFalse);
    expect(src.contains('AppColors.error'), isFalse);
    expect(src.contains('qmatch-super-resonance-purchase-error'), isTrue);
  });
}

class _PurchaseThenSignalsHost extends StatelessWidget {
  const _PurchaseThenSignalsHost();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            key: const Key('qmatch-open-sr-purchase'),
            onPressed: () {
              showQMatchSuperResonancePurchaseSheet(
                context,
                trustedBalance: 0,
                purchaseThenReadBalance: () async {
                  throw IapPurchaseFailedException('StoreKit');
                },
              );
            },
            child: const Text('Open SR'),
          ),
          TextButton(
            key: const Key('qmatch-open-alignment-signals'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WhoLikedYouScreen(
                    client: WhoLikedYouClient(
                      call: (_, __) async => {
                        'resonance_access': true,
                        'items': <Map<String, dynamic>>[],
                      },
                    ),
                    superResonanceInbox: SuperResonanceInboxClient(
                      call: (_, __) async => {
                        'items': <Map<String, dynamic>>[],
                      },
                    ),
                    likeUser: (_) async => LikeMatchOutcome.noMatch,
                    passUser: (_) async {},
                    onUnlock: () async {},
                    currentUidProvider: () => 'me',
                    animateBackground: false,
                  ),
                ),
              );
            },
            child: const Text('Open signals'),
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpSrSheet(
  WidgetTester tester, {
  required Future<int> Function() purchase,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              key: const Key('qmatch-open-sr-purchase'),
              onPressed: () {
                showQMatchSuperResonancePurchaseSheet(
                  context,
                  trustedBalance: 0,
                  purchaseThenReadBalance: purchase,
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('qmatch-open-sr-purchase')));
  await tester.pumpAndSettle();
}

_FakePaywallIap? _lastPaywallIap;

Future<void> _pumpPaywall(
  WidgetTester tester, {
  required Object purchaseError,
}) async {
  final iap = _FakePaywallIap()
    ..products = [
      ProductDetails(
        id: QmatchIapProductIds.resonanceAnnual,
        title: 'Annual',
        description: 'Annual',
        price: '\$39.99',
        rawPrice: 39.99,
        currencyCode: 'USD',
      ),
    ]
    ..purchaseError = purchaseError;
  _lastPaywallIap = iap;
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
}

class _FakePaywallIap implements ResonancePaywallIapPort {
  EntitlementSnapshot entitlement = EntitlementSnapshot.free;
  EntitlementSnapshot? entitlementAfterPurchase;
  List<ProductDetails> products = [];
  Object? purchaseError;
  final purchasedIds = <String>[];
  int restoreCalls = 0;

  @override
  Future<EntitlementSnapshot> fetchEntitlement() async {
    if (purchasedIds.isNotEmpty && entitlementAfterPurchase != null) {
      return entitlementAfterPurchase!;
    }
    return entitlement;
  }

  @override
  Future<List<ProductDetails>> loadProducts() async => products;

  @override
  Future<IapClientResult> purchase(String productId) async {
    purchasedIds.add(productId);
    final err = purchaseError;
    if (err != null) throw err;
    return IapClientResult(
      backendResponse: const {},
      entitlement: entitlement,
      productId: productId,
    );
  }

  @override
  Future<IapClientResult> restorePurchases() async {
    restoreCalls += 1;
    return IapClientResult(
      backendResponse: const {},
      entitlement: entitlement,
    );
  }
}
