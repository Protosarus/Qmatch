import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/cosmic/qmatch_cosmic_background.dart';
import 'package:qmatch/core/widgets/qmatch_pushed_screen_header.dart';
import 'package:qmatch/features/debug/debug_home_screen.dart';
import 'package:qmatch/features/settings/screens/about_screen.dart';
import 'package:qmatch/features/settings/screens/help_support_screen.dart';
import 'package:qmatch/features/settings/screens/legal_document_screen.dart';
import 'package:qmatch/features/settings/domain/notification_prefs_snapshot.dart';
import 'package:qmatch/features/settings/screens/notifications_settings_screen.dart';
import 'package:qmatch/features/settings/screens/privacy_settings_screen.dart';
import 'package:qmatch/features/settings/services/notification_prefs_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpScreen(
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

  testWidgets('privacy uses cosmic background and shared header',
      (tester) async {
    await pumpScreen(tester, home: const PrivacySettingsScreen());
    expect(find.byType(QMatchCosmicBackground), findsOneWidget);
    expect(find.byType(QMatchPushedScreenHeader), findsOneWidget);
    expect(find.byKey(const Key('qmatch-privacy-discover')), findsOneWidget);
  });

  testWidgets('privacy toggles remain local and textScale 1.3 has no overflow',
      (tester) async {
    await pumpScreen(
      tester,
      textScale: 1.3,
      home: const PrivacySettingsScreen(),
    );
    final before = tester.widget<Switch>(find.byType(Switch).first).value;
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    final after = tester.widget<Switch>(find.byType(Switch).first).value;
    expect(before, isTrue);
    expect(after, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real Settings destinations use shared pushed-screen styling',
      (tester) async {
    final screens = <Widget>[
      NotificationsSettingsScreen(
        client: NotificationPrefsClient(
          call: (_, __) async =>
              NotificationPrefsSnapshot.allEnabled.toCallablePayload(),
        ),
      ),
      const PrivacySettingsScreen(),
      const HelpSupportScreen(),
      const AboutScreen(),
      const DebugHomeScreen(),
      const LegalDocumentScreen(title: 'Policy', body: 'Body copy'),
    ];

    for (final screen in screens) {
      await pumpScreen(tester, home: screen);
      expect(find.byType(QMatchCosmicBackground), findsOneWidget);
      expect(find.byType(QMatchPushedScreenHeader), findsOneWidget);
    }
  });

  testWidgets('debug route remains available only in debug mode',
      (tester) async {
    await pumpScreen(tester, home: const DebugHomeScreen());
    expect(find.byKey(const Key('qmatch-debug-header')), findsOneWidget);
    await tester.tap(find.text('Assessment Admin'));
    await tester.pumpAndSettle();
    expect(find.byType(DebugHomeScreen), findsNothing);
  });

  test('privacy persistence keys remain unchanged', () {
    final file = File(
      'lib/features/settings/screens/privacy_settings_screen.dart',
    ).readAsStringSync();
    expect(file, contains('_showInDiscover'));
    expect(file, contains('_showApproxLocation'));
    expect(file, isNot(contains('SharedPreferences')));
  });

  test('notifications prefs are server-backed', () {
    final notifications = File(
      'lib/features/settings/screens/notifications_settings_screen.dart',
    ).readAsStringSync();
    expect(notifications, contains('settingsMvpNotificationsNote'));
    expect(notifications, contains('NotificationPrefsClient'));
    expect(notifications, isNot(contains('SharedPreferences')));
    expect(notifications, isNot(contains('frequencyDailySuggestions')));
  });

  test('account deletion destination also uses shared pushed styling in source',
      () {
    final file = File(
      'lib/features/settings/screens/account_deletion_request_screen.dart',
    ).readAsStringSync();
    expect(file, contains('QMatchCosmicBackground'));
    expect(file, contains('QMatchPushedScreenHeader'));
  });
}
