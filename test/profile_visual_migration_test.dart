import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/identity/identity.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/profile/models/profile_read_result.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/features/profile/widgets/qmatch_profile_presentation.dart';
import 'package:qmatch/l10n/app_localizations.dart';

import 'support/profile_golden_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    required Widget home,
    Size size = ProfileGoldenFixtures.standardIphone,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.cosmicBlack,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 34),
            textScaler: TextScaler.linear(textScale),
          ),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: home,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  group('Profile visual migration', () {
    testWidgets('name + age via shared resolver', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      expect(find.text('Ada, 26'), findsOneWidget);
      expect(find.text(', 26'), findsNothing);
      expect(
        UserIdentityResolver.formatNameAndAge(displayName: 'Ada', age: 26),
        'Ada, 26',
      );
    });

    testWidgets('name only / missing age', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.nameOnly()),
      );
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text(', 26'), findsNothing);
      expect(find.textContaining(', '), findsNothing);
    });

    testWidgets('long Turkish display name', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.longTurkishName(),
        ),
      );
      expect(find.byKey(const Key('qmatch-profile-identity')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cyrillic display name', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.longCyrillicName(),
        ),
      );
      expect(find.textContaining('Александра'), findsOneWidget);
    });

    testWidgets('missing photo placeholder', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.missingPhoto(),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-profile-photo-missing')),
        findsOneWidget,
      );
    });

    testWidgets('missing location omits location key', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.full(locationText: null),
        ),
      );
      expect(find.byKey(const Key('qmatch-profile-location')), findsNothing);
    });

    testWidgets('missing biography empty state', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.missingBio(),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-profile-about-empty')),
        findsOneWidget,
      );
    });

    testWidgets('empty interests empty state', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.emptyInterests(),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-profile-interests-empty')),
        findsOneWidget,
      );
    });

    testWidgets('many interests wrap without overflow', (tester) async {
      await pumpProfile(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        home: ProfileScreen(
          debugProfile: ProfileGoldenFixtures.manyInterests(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('qmatch-profile-interest-chip')), findsWidgets);
    });

    testWidgets('long biography', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.longBio()),
      );
      expect(find.byKey(const Key('qmatch-profile-bio')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading state', (tester) async {
      await pumpProfile(
        tester,
        home: const ProfileScreen(debugForceLoading: true),
      );
      expect(find.byKey(const Key('qmatch-profile-loading')), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('error state with retry', (tester) async {
      await pumpProfile(
        tester,
        home: const ProfileScreen(debugStatus: ProfileReadStatus.failed),
      );
      expect(find.byKey(const Key('qmatch-profile-error')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-profile-retry')), findsOneWidget);
    });

    testWidgets('Settings action reachable with 44px target', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      final settings = find.byKey(const Key('qmatch-profile-settings'));
      expect(settings, findsOneWidget);
      final box = tester.getSize(settings);
      expect(box.width, greaterThanOrEqualTo(44));
      expect(box.height, greaterThanOrEqualTo(44));
    });

    testWidgets('Settings icon is not strongly gold by default',
        (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('qmatch-profile-settings')),
          matching: find.byIcon(Icons.settings_outlined),
        ),
      );
      expect(icon.color, isNot(AppColors.softGold));
      expect(icon.color, isNot(AppColors.warmGold));
      final c = icon.color!;
      final luminance = (c.r + c.g + c.b) / 3.0;
      expect(luminance, greaterThan(0.65));
    });

    testWidgets('photo camera action has no solid-gold fill', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.cosmicBlack,
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QMatchProfileIdentityCard(
              profile: ProfileGoldenFixtures.full(),
              missingPhotoLabel: 'Add photo',
              editPhotoSemanticLabel: 'Edit photo',
              onPhotoTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final camera = find.byKey(const Key('qmatch-profile-photo-edit'));
      expect(camera, findsOneWidget);
      final box = tester.getSize(camera);
      expect(box.width, greaterThanOrEqualTo(44));
      expect(box.height, greaterThanOrEqualTo(44));

      final material = tester.widget<Material>(
        find.descendant(
          of: camera,
          matching: find.byType(Material),
        ),
      );
      expect(material.color, isNot(AppColors.softGold));
      expect(material.color, isNot(AppColors.warmGold));
      expect(material.color, isNotNull);
      expect((material.color!.a * 255.0).round(), greaterThan(200));
    });

    testWidgets('no malformed punctuation / no Member / no scores',
        (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      expect(find.text(', 26'), findsNothing);
      expect(find.text('Member'), findsNothing);
      expect(find.textContaining('HH'), findsNothing);
      expect(find.textContaining('Vizyon'), findsNothing);
      expect(find.textContaining('IQ'), findsNothing);
      expect(find.textContaining('EQ'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('text scale 1.3 compact viewport', (tester) async {
      await pumpProfile(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        textScale: 1.3,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('qmatch-profile-ready')), findsOneWidget);
    });

    testWidgets('bottom padding leaves room for shell nav', (tester) async {
      await pumpProfile(
        tester,
        home: ProfileScreen(debugProfile: ProfileGoldenFixtures.full()),
      );
      final list = tester.widget<ListView>(find.byType(ListView).first);
      final padding = list.padding as EdgeInsets;
      expect(padding.bottom, greaterThanOrEqualTo(34));
    });

    testWidgets('route widget remains ProfileScreen', (tester) async {
      expect(const ProfileScreen(), isA<ProfileScreen>());
    });
  });
}
