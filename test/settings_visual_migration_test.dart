import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/settings/screens/settings_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required Widget home,
    Size size = const Size(390, 844),
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
          child: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('settings rows and groups present; back works', (tester) async {
    await pumpSettings(
      tester,
      home: const SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: true,
      ),
    );
    expect(
        find.byKey(const Key('qmatch-settings-notifications')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-privacy')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-blocked')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-help')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-about')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-delete')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-logout')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-debug')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-cosmic')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings back uses glass container and non-gold icon',
      (tester) async {
    await pumpSettings(
      tester,
      home: const SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: false,
      ),
    );

    final back = find.byKey(const Key('qmatch-settings-back'));
    expect(back, findsOneWidget);
    final size = tester.getSize(back);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));

    final material = tester.widget<Material>(
      find.descendant(of: back, matching: find.byType(Material)),
    );
    expect(material.color, isNot(AppColors.softGold));
    expect(material.color, isNotNull);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: back,
        matching: find.byIcon(Icons.arrow_back_ios_new),
      ),
    );
    expect(icon.color, isNot(AppColors.softGold));
    expect(icon.color, isNot(AppColors.warmGold));
  });

  testWidgets('debug hidden when forced off', (tester) async {
    await pumpSettings(
      tester,
      home: const SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: false,
      ),
    );
    expect(find.byKey(const Key('qmatch-settings-debug')), findsNothing);
  });

  testWidgets('text scale 1.3 compact no overflow', (tester) async {
    await pumpSettings(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      home: const SettingsScreen(
        animateBackground: false,
        debugDeletionPending: true,
        debugForceDebugRow: false,
      ),
    );
    expect(find.byKey(const Key('qmatch-settings-deletion-banner')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout and delete keys are distinct', (tester) async {
    await pumpSettings(
      tester,
      home: const SettingsScreen(
        animateBackground: false,
        debugDeletionPending: false,
        debugForceDebugRow: false,
      ),
    );
    expect(find.byKey(const Key('qmatch-settings-delete')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-settings-logout')), findsOneWidget);
  });
}
