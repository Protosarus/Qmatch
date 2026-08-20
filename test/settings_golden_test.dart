import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/cosmic/qmatch_cosmic_background.dart';
import 'package:qmatch/core/widgets/qmatch_primary_action.dart';
import 'package:qmatch/core/widgets/qmatch_pushed_screen_header.dart';
import 'package:qmatch/features/debug/debug_home_screen.dart';
import 'package:qmatch/features/discover/domain/discover_passport_snapshot.dart';
import 'package:qmatch/features/discover/services/discover_passport_client.dart';
import 'package:qmatch/features/settings/screens/help_support_screen.dart';
import 'package:qmatch/features/settings/screens/privacy_settings_screen.dart';
import 'package:qmatch/features/settings/screens/settings_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pump(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(375, 667),
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
            textScaler: TextScaler.linear(textScale),
            devicePixelRatio: 1,
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  Future<void> expectGolden(WidgetTester tester, String path) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(path),
    );
  }

  testWidgets('cosmic static reduced-motion', (tester) async {
    await pump(
      tester,
      child: const Scaffold(
        body: QMatchCosmicBackground(
          seed: 42,
          animate: false,
          child: SizedBox.expand(),
        ),
      ),
    );
    await expectGolden(
      tester,
      'goldens/cosmic_background/static_reduced_motion_1_0.png',
    );
  });

  testWidgets('cosmic phase A', (tester) async {
    await pump(
      tester,
      child: const Scaffold(
        body: QMatchCosmicBackground(
          seed: 42,
          debugTimeSeconds: 0,
          child: SizedBox.expand(),
        ),
      ),
    );
    await expectGolden(
      tester,
      'goldens/cosmic_background/phase_a_1_0.png',
    );
  });

  testWidgets('cosmic phase B', (tester) async {
    await pump(
      tester,
      child: const Scaffold(
        body: QMatchCosmicBackground(
          seed: 42,
          debugTimeSeconds: 2.6,
          child: SizedBox.expand(),
        ),
      ),
    );
    await expectGolden(
      tester,
      'goldens/cosmic_background/phase_b_1_0.png',
    );
  });

  DiscoverPassportClient _passportStub() {
    return DiscoverPassportClient(
      getOverride: () async => DiscoverPassportSnapshot.worldwide,
    );
  }

  testWidgets('settings full compact', (tester) async {
    await pump(
      tester,
      child: SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: true,
        passportClient: _passportStub(),
      ),
    );
    await expectGolden(tester, 'goldens/settings/full_compact_1_0.png');
  });

  testWidgets('settings release-like no debug', (tester) async {
    await pump(
      tester,
      child: SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: false,
        passportClient: _passportStub(),
      ),
    );
    await expectGolden(tester, 'goldens/settings/release_no_debug_1_0.png');
  });

  testWidgets('settings deletion pending', (tester) async {
    await pump(
      tester,
      child: SettingsScreen(
        animateBackground: false,
        debugDeletionPending: true,
        debugForceDebugRow: false,
        passportClient: _passportStub(),
      ),
    );
    await expectGolden(tester, 'goldens/settings/deletion_pending_1_0.png');
  });

  testWidgets('settings textScale 1.3', (tester) async {
    await pump(
      tester,
      textScale: 1.3,
      child: SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: false,
        passportClient: _passportStub(),
      ),
    );
    await expectGolden(tester, 'goldens/settings/full_compact_1_3.png');
  });

  testWidgets('privacy compact', (tester) async {
    await pump(tester, child: const PrivacySettingsScreen());
    await expectGolden(tester, 'goldens/settings/privacy_compact_1_0.png');
  });

  testWidgets('debug compact', (tester) async {
    await pump(tester, child: const DebugHomeScreen());
    await expectGolden(tester, 'goldens/settings/debug_compact_1_0.png');
  });

  testWidgets('help compact', (tester) async {
    await pump(tester, child: const HelpSupportScreen());
    await expectGolden(tester, 'goldens/settings/help_compact_1_0.png');
  });

  testWidgets('shared header compact', (tester) async {
    await pump(
      tester,
      size: const Size(320, 568),
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title: 'Long destination title for compact verification',
          backButtonKey: Key('header-back'),
        ),
      ),
    );
    await expectGolden(tester, 'goldens/settings/header_compact_1_0.png');
  });

  testWidgets('shared header textScale 1.3', (tester) async {
    await pump(
      tester,
      textScale: 1.3,
      child: const SafeArea(
        child: QMatchPushedScreenHeader(
          title: 'Very long Turkish and English pushed screen title',
          backButtonKey: Key('header-back'),
        ),
      ),
    );
    await expectGolden(tester, 'goldens/settings/header_compact_1_3.png');
  });

  testWidgets('primary action states', (tester) async {
    await pump(
      tester,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QMatchPrimaryAction(
              label: 'Add photo',
              icon: Icons.add_a_photo_outlined,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            const QMatchPrimaryAction(
              label: 'Add photo',
              icon: Icons.add_a_photo_outlined,
              onPressed: null,
              enabled: false,
            ),
            const SizedBox(height: 12),
            const QMatchPrimaryAction(
              label: 'Uploading…',
              icon: Icons.add_a_photo_outlined,
              onPressed: null,
              loading: true,
            ),
            const SizedBox(height: 12),
            QMatchPrimaryAction(
              label: 'Delete account',
              onPressed: () {},
              tone: QMatchPrimaryActionTone.destructive,
            ),
          ],
        ),
      ),
    );
    await expectGolden(
        tester, 'goldens/settings/primary_action_states_1_0.png');
  });
}
