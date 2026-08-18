import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/iap/domain/entitlement_snapshot.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/features/profile/domain/membership_plan.dart';
import 'package:qmatch/features/profile/screens/membership_screen.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

import 'support/profile_golden_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const lilac = Color(0xFFDAC8ED);

  EntitlementSnapshot resonance({
    String? productId,
    String? canonicalProductKey,
  }) {
    return EntitlementSnapshot(
      uid: 'u1',
      tier: 'resonance',
      subscriptionState: 'active',
      resonanceAccess: true,
      superResonanceBalance: 0,
      boostBalance: 0,
      productId: productId,
      canonicalProductKey: canonicalProductKey,
    );
  }

  Future<void> pumpMembership(
    WidgetTester tester, {
    required EntitlementSnapshot snapshot,
    Locale locale = const Locale('en'),
    Future<EntitlementSnapshot> Function()? restorePurchases,
    Future<void> Function()? manageSubscription,
    Future<void> Function(BuildContext context)? openUpgrade,
    Future<EntitlementSnapshot> Function()? readEntitlement,
    bool skipFetch = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MembershipScreen(
          initialSnapshot: snapshot,
          skipFetch: skipFetch,
          readEntitlement: readEntitlement,
          restorePurchases: restorePurchases,
          manageSubscription: manageSubscription,
          openUpgrade: openUpgrade,
          animateBackground: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('MembershipPlan from trusted entitlement keys', () {
    test('monthly and annual from product_id / canonical_product_key', () {
      expect(
        MembershipPlan.fromEntitlement(
          resonance(productId: QmatchIapProductIds.resonanceMonthly),
        ),
        MembershipPlanPeriod.monthly,
      );
      expect(
        MembershipPlan.fromEntitlement(
          resonance(canonicalProductKey: 'resonance_annual'),
        ),
        MembershipPlanPeriod.annual,
      );
      expect(
        MembershipPlan.fromEntitlement(
          resonance(
            canonicalProductKey: QmatchIapProductIds.resonanceMonthly,
            productId: QmatchIapProductIds.resonanceAnnual,
          ),
        ),
        MembershipPlanPeriod.monthly,
      );
    });

    test('unknown keys and non-access do not invent a plan', () {
      expect(
        MembershipPlan.fromEntitlement(
          resonance(productId: 'unknown.sku'),
        ),
        isNull,
      );
      expect(
        MembershipPlan.fromEntitlement(EntitlementSnapshot.free),
        isNull,
      );
    });
  });

  test('EN/TR membership copy', () {
    final en = AppLocalizationsEn();
    final tr = AppLocalizationsTr();
    expect(en.membershipTitle, 'Membership');
    expect(en.membershipFreeName, 'QMatch Free');
    expect(en.membershipFreeIncluded,
        'Assessments, Discover, match, and chat included');
    expect(en.membershipUpgradeCta, 'Upgrade to Resonance');
    expect(en.membershipStatusActive, 'Active');
    expect(en.membershipPlanMonthly, 'Monthly');
    expect(en.membershipPlanAnnual, 'Annual');
    expect(en.membershipComingLater, 'Coming later');
    expect(en.membershipManageSubscription, 'Manage Subscription');
    expect(en.whoLikedYouTitle, 'Alignment Signals');

    expect(tr.membershipTitle, 'Üyelik');
    expect(tr.membershipFreeIncluded,
        'Değerlendirmeler, Keşfet, eşleşme ve sohbet dahil');
    expect(tr.membershipUpgradeCta, 'Resonance\'a yükselt');
    expect(tr.membershipStatusActive, 'Aktif');
    expect(tr.membershipPlanMonthly, 'Aylık');
    expect(tr.membershipPlanAnnual, 'Yıllık');
    expect(tr.membershipComingLater, 'Daha sonra gelecek');
    expect(tr.membershipManageSubscription, 'Aboneliği yönet');
    expect(tr.whoLikedYouTitle, 'Uyum Sinyalleri');
  });

  testWidgets('Free state shows included apps and Upgrade CTA', (tester) async {
    var upgrades = 0;
    await pumpMembership(
      tester,
      snapshot: EntitlementSnapshot.free,
      openUpgrade: (_) async {
        upgrades++;
      },
    );

    expect(find.byKey(const Key('qmatch-membership-free')), findsOneWidget);
    expect(find.text('QMatch Free'), findsOneWidget);
    expect(
      find.text('Assessments, Discover, match, and chat included'),
      findsOneWidget,
    );
    expect(find.text('Upgrade to Resonance'), findsOneWidget);
    expect(find.byKey(const Key('qmatch-membership-resonance')), findsNothing);
    expect(find.byKey(const Key('qmatch-membership-restore')), findsNothing);

    await tester.tap(find.byKey(const Key('qmatch-membership-upgrade')));
    await tester.pump();
    expect(upgrades, 1);
  });

  testWidgets('TR Free state uses localized included + CTA', (tester) async {
    await pumpMembership(
      tester,
      snapshot: EntitlementSnapshot.free,
      locale: const Locale('tr'),
      openUpgrade: (_) async {},
    );
    expect(find.text('Üyelik'), findsOneWidget);
    expect(
      find.text('Değerlendirmeler, Keşfet, eşleşme ve sohbet dahil'),
      findsOneWidget,
    );
    expect(find.text('Resonance\'a yükselt'), findsOneWidget);
  });

  testWidgets('Resonance monthly shows live Alignment Signals and later items',
      (tester) async {
    var restores = 0;
    var manages = 0;
    await pumpMembership(
      tester,
      snapshot: resonance(productId: QmatchIapProductIds.resonanceMonthly),
      restorePurchases: () async {
        restores++;
        return resonance(productId: QmatchIapProductIds.resonanceMonthly);
      },
      manageSubscription: () async {
        manages++;
      },
    );

    expect(
        find.byKey(const Key('qmatch-membership-resonance')), findsOneWidget);
    expect(find.text('Resonance'), findsWidgets);
    expect(find.text('Active'), findsOneWidget);
    expect(find.byKey(const Key('qmatch-membership-plan-monthly')),
        findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Alignment Signals'), findsOneWidget);
    expect(find.text('Rewind'), findsOneWidget);
    expect(find.text('Deeper compatibility explanations'), findsOneWidget);
    expect(find.text('Coming later'), findsNWidgets(2));
    expect(find.text('Who liked you'), findsNothing);
    expect(find.byKey(const Key('qmatch-membership-free')), findsNothing);

    await tester.tap(find.byKey(const Key('qmatch-membership-restore')));
    await tester.pump();
    expect(restores, 1);

    await tester.tap(find.byKey(const Key('qmatch-membership-manage')));
    await tester.pump();
    expect(manages, 1);
  });

  testWidgets('Resonance annual uses trusted canonical_product_key',
      (tester) async {
    await pumpMembership(
      tester,
      snapshot: resonance(canonicalProductKey: 'qmatch.resonance.annual'),
      restorePurchases: () async => resonance(),
      manageSubscription: () async {},
    );
    expect(
        find.byKey(const Key('qmatch-membership-plan-annual')), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-membership-plan-monthly')), findsNothing);
  });

  testWidgets('Active status uses lilac not gold', (tester) async {
    await pumpMembership(
      tester,
      snapshot: resonance(productId: QmatchIapProductIds.resonanceAnnual),
      restorePurchases: () async => resonance(),
      manageSubscription: () async {},
    );
    final active = tester.widget<Text>(
      find.byKey(const Key('qmatch-membership-active')),
    );
    expect(active.style?.color, lilac);
    expect(active.style?.color, isNot(AppColors.softGold));
  });

  testWidgets('entitlement read error fail-closes to Free', (tester) async {
    await pumpMembership(
      tester,
      snapshot: resonance(productId: QmatchIapProductIds.resonanceAnnual),
      skipFetch: false,
      readEntitlement: () async => throw StateError('denied'),
      openUpgrade: (_) async {},
    );
    await tester.pump();
    expect(find.byKey(const Key('qmatch-membership-free')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-membership-resonance')), findsNothing);
  });

  testWidgets('false resonance_access fail-closes to Free', (tester) async {
    await pumpMembership(
      tester,
      snapshot: const EntitlementSnapshot(
        uid: 'u1',
        tier: 'resonance',
        subscriptionState: 'active',
        resonanceAccess: false,
        superResonanceBalance: 0,
        boostBalance: 0,
        productId: 'qmatch.resonance.annual',
      ),
      openUpgrade: (_) async {},
    );
    expect(find.byKey(const Key('qmatch-membership-free')), findsOneWidget);
    expect(find.text('Annual'), findsNothing);
  });

  testWidgets('Profile membership row opens Membership screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.full(),
          debugResonanceAccess: false,
          animateBackground: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('QMatch Free'), findsOneWidget);
    await tester.tap(find.byKey(const Key('qmatch-profile-membership')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qmatch-membership-free')), findsOneWidget);
    expect(find.text('Upgrade to Resonance'), findsOneWidget);
  });

  test('Membership UI does not infer access from StoreKit', () {
    final screen = File(
      'lib/features/profile/screens/membership_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('InAppPurchase'), isFalse);
    expect(screen.contains('purchaseStream'), isFalse);
    expect(screen.toLowerCase().contains('storekit'), isFalse);
    expect(screen.contains('resonanceAccess == true'), isTrue);
    expect(screen.contains('EntitlementRepository'), isTrue);

    final plan = File(
      'lib/features/profile/domain/membership_plan.dart',
    ).readAsStringSync();
    expect(plan.contains('InAppPurchase'), isFalse);
    expect(plan.contains('canonicalProductKey'), isTrue);
    expect(plan.contains('productId'), isTrue);
  });
}
