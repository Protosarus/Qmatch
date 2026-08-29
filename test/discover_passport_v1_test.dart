import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/discover/domain/discover_eligible_query_plan.dart';
import 'package:qmatch/features/discover/domain/discover_passport_snapshot.dart';
import 'package:qmatch/features/discover/domain/passport_destination_catalog.dart';
import 'package:qmatch/features/discover/screens/passport_destination_picker_screen.dart';
import 'package:qmatch/features/discover/services/discover_passport_client.dart';
import 'package:qmatch/core/widgets/cosmic/q_cosmic_button.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_empty_state.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_header.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_passport_chip.dart';
import 'package:qmatch/features/iap/domain/resonance_paywall_feature.dart';
import 'package:qmatch/features/settings/screens/settings_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  String read(String path) => File(path).readAsStringSync();

  DiscoverPassportSnapshot snap({
    bool access = false,
    bool enabled = false,
    String? country,
    String? city,
  }) {
    return DiscoverPassportSnapshot(
      resonanceAccess: access,
      passportEnabled: enabled,
      passportCountry: country,
      passportCity: city,
    );
  }

  group('Discover query plan', () {
    test('Passport OFF keeps global query', () {
      final plan = DiscoverEligibleQueryPlan.fromPassport(
        snap(access: true, enabled: false, country: 'TR', city: 'istanbul'),
      );
      expect(plan.passportActive, isFalse);
      expect(plan.usesDestinationFilter, isFalse);
      expect(plan.skipEligibleQuery, isFalse);
      expect(plan.country, isNull);
      expect(plan.city, isNull);
    });

    test('Passport ON adds country+city filters', () {
      final plan = DiscoverEligibleQueryPlan.fromPassport(
        snap(access: true, enabled: true, country: 'TR', city: 'istanbul'),
      );
      expect(plan.passportActive, isTrue);
      expect(plan.usesDestinationFilter, isTrue);
      expect(plan.skipEligibleQuery, isFalse);
      expect(plan.country, 'TR');
      expect(plan.city, 'istanbul');
    });

    test('empty destination does not fall back to global', () {
      final plan = DiscoverEligibleQueryPlan.fromPassport(
        snap(access: true, enabled: true),
      );
      expect(plan.passportActive, isTrue);
      expect(plan.usesDestinationFilter, isFalse);
      expect(plan.skipEligibleQuery, isTrue);
    });

    test('expired access -> effective Worldwide', () {
      final expired = DiscoverPassportSnapshot.fromTrustedMap({
        'resonance_access': false,
        'passport_enabled': false,
        'passport_country': 'GB',
        'passport_city': 'london',
      });
      expect(expired.resonanceAccess, isFalse);
      expect(expired.passportEnabled, isFalse);
      expect(expired.passportCountry, 'GB');
      expect(expired.passportCity, 'london');
      final plan = DiscoverEligibleQueryPlan.fromPassport(expired);
      expect(plan.passportActive, isFalse);
      expect(plan.usesDestinationFilter, isFalse);
      expect(plan.skipEligibleQuery, isFalse);
    });
  });

  group('Passport client', () {
    test('Free cannot activate', () async {
      final client = DiscoverPassportClient(
        setOverride: (country, city) async {
          throw const DiscoverPassportResonanceRequiredException();
        },
      );
      expect(
        () => client.set(country: 'TR', city: 'istanbul'),
        throwsA(isA<DiscoverPassportResonanceRequiredException>()),
      );
    });

    test('Resonance can activate', () async {
      final client = DiscoverPassportClient(
        setOverride: (country, city) async {
          return snap(
            access: true,
            enabled: true,
            country: country,
            city: city,
          );
        },
      );
      final next = await client.set(country: 'TR', city: 'İstanbul');
      expect(next.passportEnabled, isTrue);
      expect(next.passportCountry, 'TR');
      expect(next.passportCity, 'istanbul');
      expect(next.resonanceAccess, isTrue);
    });

    test('get/set/disable call trusted names only', () async {
      final names = <String>[];
      final client = DiscoverPassportClient(
        call: (name, data) async {
          names.add(name);
          expect(data.containsKey('resonance_access'), isFalse);
          expect(data.containsKey('location'), isFalse);
          expect(data.containsKey('geohash'), isFalse);
          expect(data.containsKey('latitude'), isFalse);
          return {
            'resonance_access': true,
            'passport_enabled': name == 'setDiscoverPassport',
            'passport_country': data['passport_country'] ?? 'TR',
            'passport_city': data['passport_city'] ?? 'istanbul',
          };
        },
      );
      await client.get();
      await client.set(country: 'DE', city: 'berlin');
      await client.disable();
      expect(names, [
        'getDiscoverPassport',
        'setDiscoverPassport',
        'disableDiscoverPassport',
      ]);
    });
  });

  group('Discover chip states', () {
    testWidgets('Passport OFF shows Worldwide', (tester) async {
      await _pumpLocalized(
        tester,
        QMatchDiscoverHeader(
          title: 'Discover',
          chip: QMatchDiscoverPassportChip(
            snapshot: snap(access: true),
            onPressed: () {},
          ),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-discover-passport-chip-worldwide')),
        findsOneWidget,
      );
      expect(find.text('Worldwide'), findsOneWidget);
    });

    testWidgets('Passport ON shows city display, not slug', (tester) async {
      await _pumpLocalized(
        tester,
        QMatchDiscoverHeader(
          title: 'Discover',
          chip: QMatchDiscoverPassportChip(
            snapshot: snap(
              access: true,
              enabled: true,
              country: 'TR',
              city: 'istanbul',
            ),
            onPressed: () {},
          ),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-discover-passport-chip-active')),
        findsOneWidget,
      );
      expect(find.text('Istanbul · Passport'), findsOneWidget);
      expect(find.text('istanbul'), findsNothing);
      expect(find.textContaining('istanbul'), findsNothing);
    });

    testWidgets('Free chip can be tapped and stays locked', (tester) async {
      var taps = 0;
      await _pumpLocalized(
        tester,
        QMatchDiscoverPassportChip(
          snapshot: snap(),
          onPressed: () => taps++,
        ),
      );
      await tester.tap(
        find.byKey(const Key('qmatch-discover-passport-chip-worldwide')),
      );
      expect(taps, 1);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Worldwide'), findsOneWidget);
    });
  });

  group('Settings states', () {
    testWidgets('Free shows locked Passport row and paywall CTA',
        (tester) async {
      ResonancePaywallFeature? feature;
      final client = DiscoverPassportClient(
        getOverride: () async => snap(),
      );
      await _pumpLocalized(
        tester,
        SettingsScreen(
          animateBackground: false,
          debugDeletionPending: false,
          debugForceDebugRow: false,
          passportClient: client,
          openPaywall: (context, f) async {
            feature = f;
            return false;
          },
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('qmatch-settings-passport')), findsOneWidget);
      expect(find.text('Unlock with Resonance'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-settings-passport')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('qmatch-passport-picker')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-passport-city-TR-istanbul')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(feature, ResonancePaywallFeature.passport);
    });

    testWidgets('Resonance shows destination or Worldwide and opens picker',
        (tester) async {
      final client = DiscoverPassportClient(
        getOverride: () async => snap(access: true, enabled: false),
      );
      await _pumpLocalized(
        tester,
        SettingsScreen(
          animateBackground: false,
          debugDeletionPending: false,
          debugForceDebugRow: false,
          passportClient: client,
          openPaywall: (_, __) async => false,
        ),
      );
      await tester.pump();
      final worldwide = find.descendant(
        of: find.byKey(const Key('qmatch-settings-passport')),
        matching: find.text('Worldwide'),
      );
      expect(worldwide, findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-settings-passport')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('qmatch-passport-picker')), findsOneWidget);
    });

    testWidgets('Resonance active destination uses display city', (tester) async {
      final client = DiscoverPassportClient(
        getOverride: () async => snap(
          access: true,
          enabled: true,
          country: 'TR',
          city: 'istanbul',
        ),
      );
      await _pumpLocalized(
        tester,
        SettingsScreen(
          animateBackground: false,
          debugDeletionPending: false,
          debugForceDebugRow: false,
          passportClient: client,
        ),
      );
      await tester.pump();
      expect(find.text('Istanbul'), findsOneWidget);
      expect(find.text('istanbul'), findsNothing);
    });
  });

  group('Destination picker', () {
    testWidgets('Resonance select destination stores ISO+slug', (tester) async {
      String? setCountry;
      String? setCity;
      final client = DiscoverPassportClient(
        getOverride: () async => snap(access: true),
        setOverride: (country, city) async {
          setCountry = country;
          setCity = city;
          return snap(
            access: true,
            enabled: true,
            country: country,
            city: city,
          );
        },
      );
      await _pumpLocalized(
        tester,
        PassportDestinationPickerScreen(
          client: client,
          initial: snap(access: true),
          animateBackground: false,
          openPaywall: (_, __) async => false,
        ),
      );
      expect(find.text('Istanbul'), findsWidgets);
      expect(find.text('istanbul'), findsNothing);
      await tester.tap(find.byKey(const Key('qmatch-passport-city-TR-istanbul')));
      await tester.pumpAndSettle();
      expect(setCountry, 'TR');
      expect(setCity, 'istanbul');
    });

    testWidgets('Free select opens paywall and does not activate',
        (tester) async {
      var setCalls = 0;
      var paywall = 0;
      final client = DiscoverPassportClient(
        setOverride: (country, city) async {
          setCalls++;
          throw const DiscoverPassportResonanceRequiredException();
        },
      );
      await _pumpLocalized(
        tester,
        PassportDestinationPickerScreen(
          client: client,
          initial: snap(),
          animateBackground: false,
          openPaywall: (_, feature) async {
            paywall++;
            expect(feature, ResonancePaywallFeature.passport);
            return false;
          },
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-passport-city-TR-istanbul')));
      await tester.pumpAndSettle();
      expect(paywall, 1);
      expect(setCalls, 0);
    });

    testWidgets('Use Worldwide disables Passport', (tester) async {
      var disabled = 0;
      final client = DiscoverPassportClient(
        disableOverride: () async {
          disabled++;
          return snap(access: true);
        },
      );
      await _pumpLocalized(
        tester,
        PassportDestinationPickerScreen(
          client: client,
          initial: snap(
            access: true,
            enabled: true,
            country: 'DE',
            city: 'berlin',
          ),
          animateBackground: false,
        ),
      );
      final worldwide = tester.widget<QCosmicButton>(
        find.byKey(const Key('qmatch-passport-use-worldwide')),
      );
      expect(worldwide.variant, QCosmicButtonVariant.glass);
      await tester.tap(find.byKey(const Key('qmatch-passport-use-worldwide')));
      await tester.pumpAndSettle();
      expect(disabled, 1);
    });
  });

  group('Empty destination', () {
    testWidgets('shows dedicated copy and does not auto-change', (tester) async {
      var change = 0;
      var worldwide = 0;
      await _pumpLocalized(
        tester,
        QMatchDiscoverEmptyState(
          emptyKey: const Key('qmatch-discover-passport-empty'),
          title: 'New profiles are still arriving here',
          body:
              'Change your Passport destination or return to Worldwide.',
          retryLabel: 'Change destination',
          onRetry: () => change++,
          secondaryLabel: 'Use Worldwide',
          onSecondary: () => worldwide++,
        ),
      );
      expect(
        find.byKey(const Key('qmatch-discover-passport-empty')),
        findsOneWidget,
      );
      expect(find.text('New profiles are still arriving here'), findsOneWidget);
      final retry = tester.widget<QCosmicButton>(
        find.byKey(const Key('qmatch-discover-empty-retry')),
      );
      final secondary = tester.widget<QCosmicButton>(
        find.byKey(const Key('qmatch-discover-empty-secondary')),
      );
      expect(retry.variant, QCosmicButtonVariant.glass);
      expect(secondary.variant, QCosmicButtonVariant.glass);
      expect(secondary.variant, isNot(QCosmicButtonVariant.ghost));
      expect(secondary.variant, isNot(QCosmicButtonVariant.gold));
      await tester.tap(find.byKey(const Key('qmatch-discover-empty-retry')));
      await tester.tap(find.byKey(const Key('qmatch-discover-empty-secondary')));
      expect(change, 1);
      expect(worldwide, 1);
    });
  });

  group('Preserve + security source', () {
    test('no precise location fields used for Passport query/UI', () {
      final service = read(
        'lib/features/discover/services/discover_service.dart',
      );
      expect(service.contains("where('location'"), isFalse);
      expect(service.contains("where('geohash'"), isFalse);
      expect(service.contains('GeoPoint'), isFalse);

      final picker = read(
        'lib/features/discover/screens/passport_destination_picker_screen.dart',
      );
      expect(picker.contains('package:geolocator'), isFalse);
      expect(picker.contains('Geolocator'), isFalse);
      expect(picker.contains('getCurrentPosition'), isFalse);
      expect(picker.contains('GoogleMap'), isFalse);
      expect(picker.contains("where('geohash'"), isFalse);

      final client = read(
        'lib/features/discover/services/discover_passport_client.dart',
      );
      expect(client.contains("data['geohash']"), isFalse);
      expect(client.contains("'geohash':"), isFalse);
      expect(client.contains('latitude'), isFalse);
    });

    test('no L2 payload/query or ranking changes', () {
      final l2Client = read(
        'lib/features/discover/services/discover_stage_b2_trusted_l2_client.dart',
      );
      expect(l2Client.contains('passport'), isFalse);
      expect(l2Client.contains('home_country'), isFalse);
      expect(l2Client.contains("'candidate_uids': candidateUids"), isTrue);

      final l2Js = read('functions/src/stage_b2_l2_callable.js');
      expect(l2Js.contains('passport'), isFalse);

      final ranking = read(
        'lib/features/discover/services/discover_structural_l2_ranking.dart',
      );
      expect(ranking.contains('passport'), isFalse);
      expect(ranking.contains('home_city'), isFalse);

      final discover = read(
        'lib/features/discover/services/discover_service.dart',
      );
      expect(discover.contains('DiscoverStructuralL2Ranking.rankL1Batch'), isTrue);
      expect(discover.contains('applyTrustedMembership'), isTrue);
    });

    test('required users and public_profiles composite indexes exist', () {
      final indexes = read('firestore.indexes.json');
      expect(indexes.contains('"collectionGroup": "public_profiles"'), isTrue);
      expect(indexes.contains('"fieldPath": "discover_eligible"'), isTrue);
      expect(indexes.contains('"fieldPath": "home_country"'), isTrue);
      expect(indexes.contains('"fieldPath": "home_city"'), isTrue);
    });

    test('city slug is catalog query key, not display', () {
      final istanbul = PassportDestinationCatalog.find(
        country: 'TR',
        citySlug: 'istanbul',
      );
      expect(istanbul, isNotNull);
      expect(istanbul!.cityEn, 'Istanbul');
      expect(istanbul.cityTr, 'İstanbul');
      expect(
        PassportDestinationCatalog.displayCity(
          country: 'TR',
          citySlug: 'istanbul',
          turkish: false,
        ),
        'Istanbul',
      );
      expect(
        PassportDestinationCatalog.friendlyCityFromSlug('new-york'),
        'New York',
      );
    });

    test('Worldwide return CTAs use glass, not gold/ghost', () {
      final empty = read(
        'lib/features/discover/widgets/qmatch_discover_empty_state.dart',
      );
      final emptySecondary = empty.substring(
        empty.indexOf("key: const Key('qmatch-discover-empty-secondary')"),
        empty.indexOf(
          "key: const Key('qmatch-discover-empty-secondary')",
        ) +
            280,
      );
      expect(emptySecondary.contains('QCosmicButtonVariant.glass'), isTrue);
      expect(emptySecondary.contains('QCosmicButtonVariant.ghost'), isFalse);
      expect(emptySecondary.contains('QCosmicButtonVariant.gold'), isFalse);
      expect(emptySecondary.contains('AppColors.softGold'), isFalse);

      final picker = read(
        'lib/features/discover/screens/passport_destination_picker_screen.dart',
      );
      final worldwide = picker.substring(
        picker.indexOf("key: const Key('qmatch-passport-use-worldwide')"),
        picker.indexOf(
              "key: const Key('qmatch-passport-use-worldwide')",
            ) +
            260,
      );
      expect(worldwide.contains('QCosmicButtonVariant.glass'), isTrue);
      expect(worldwide.contains('QCosmicButtonVariant.ghost'), isFalse);
      expect(worldwide.contains('QCosmicButtonVariant.gold'), isFalse);
      expect(worldwide.contains('AppColors.softGold'), isFalse);

      final discover = read(
        'lib/features/discover/screens/discover_screen.dart',
      );
      expect(discover.contains('onSecondary: passportEmpty ? _turnPassportOff'), isTrue);
      expect(discover.contains('_passportClient.disable()'), isTrue);

      final pickerAction = read(
        'lib/features/discover/screens/passport_destination_picker_screen.dart',
      );
      expect(pickerAction.contains('await widget.client.disable();'), isTrue);
      expect(
        read('lib/features/discover/services/discover_passport_client.dart')
            .contains("disableCallableName = 'disableDiscoverPassport'"),
        isTrue,
      );
    });

    test('TR/EN empty destination copy is present', () {
      final en = read('lib/l10n/app_en.arb');
      final tr = read('lib/l10n/app_tr.arb');
      expect(
        en.contains('New profiles are still arriving here'),
        isTrue,
      );
      expect(
        en.contains(
          'Change your Passport destination or return to Worldwide.',
        ),
        isTrue,
      );
      expect(tr.contains('Bu şehirde yeni profiller bekleniyor'), isTrue);
      expect(
        tr.contains(
          "Passport konumunu değiştirebilir veya Worldwide'a dönebilirsin.",
        ),
        isTrue,
      );
    });

    test('Discover applies trusted getDiscoverPassport before eligible query',
        () {
      final src = read(
        'lib/features/discover/services/discover_service.dart',
      );
      final getIdx = src.indexOf('_passportClient.get()');
      final eligibleIdx = src.indexOf("'discover.eligible_query'");
      expect(getIdx, greaterThan(0));
      expect(eligibleIdx, greaterThan(getIdx));
      expect(src.contains('usesDestinationFilter'), isTrue);
      expect(src.contains('skipEligibleQuery'), isTrue);
      expect(src.contains("where('home_country', isEqualTo: plan.country)"),
          isTrue);
      expect(src.contains("where('home_city', isEqualTo: plan.city)"), isTrue);
    });
  });
}

Future<void> _pumpLocalized(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    ),
  );
  await tester.pump();
}
