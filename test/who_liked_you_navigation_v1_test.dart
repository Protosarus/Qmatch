import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/widgets/qmatch_glass_icon_button.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_header.dart';
import 'package:qmatch/features/iap/domain/resonance_paywall_feature.dart';
import 'package:qmatch/features/settings/screens/settings_screen.dart';
import 'package:qmatch/features/who_liked_you/navigation/who_liked_you_entry.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('WhoLikedYouEntry gating', () {
    testWidgets('Settings entitled opens inbox and skips paywall',
        (tester) async {
      var inbox = 0;
      var paywall = 0;
      var sheet = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => true,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async {
          paywall++;
          return false;
        },
        showUnlockSheet: (_) async {
          sheet++;
          return false;
        },
      );

      await _pumpAction(tester, onPressed: entry.openFromSettings);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(inbox, 1);
      expect(paywall, 0);
      expect(sheet, 0);
    });

    testWidgets('Settings free opens existing settings Resonance paywall',
        (tester) async {
      ResonancePaywallFeature? feature;
      var inbox = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => false,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, f) async {
          feature = f;
          return false;
        },
        showUnlockSheet: (_) async => false,
      );

      await _pumpAction(tester, onPressed: entry.openFromSettings);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(feature, ResonancePaywallFeature.settingsResonance);
      expect(inbox, 0);
    });

    testWidgets('Settings purchase success then opens Who Liked You',
        (tester) async {
      var inbox = 0;
      var paywall = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => false,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async {
          paywall++;
          return true;
        },
        showUnlockSheet: (_) async => false,
      );

      await _pumpAction(tester, onPressed: entry.openFromSettings);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(paywall, 1);
      expect(inbox, 1);
    });

    testWidgets('Discover entitled opens inbox and skips unlock sheet',
        (tester) async {
      var inbox = 0;
      var sheet = 0;
      var paywall = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => true,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async {
          paywall++;
          return false;
        },
        showUnlockSheet: (_) async {
          sheet++;
          return false;
        },
      );

      await _pumpAction(tester, onPressed: entry.openFromDiscover);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(inbox, 1);
      expect(sheet, 0);
      expect(paywall, 0);
    });

    testWidgets('Discover free opens Alignment Signals without unlock sheet',
        (tester) async {
      var inbox = 0;
      var sheet = 0;
      var paywall = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => false,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async {
          paywall++;
          return false;
        },
        showUnlockSheet: (_) async {
          sheet++;
          return false;
        },
      );

      await _pumpAction(tester, onPressed: entry.openFromDiscover);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(inbox, 1);
      expect(sheet, 0);
      expect(paywall, 0);
    });

    testWidgets('Discover opens inbox regardless of Resonance access',
        (tester) async {
      var inbox = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => true,
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async => false,
        showUnlockSheet: (_) async => true,
      );

      await _pumpAction(tester, onPressed: entry.openFromDiscover);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(inbox, 1);
    });

    testWidgets('entitlement read failure fail-closes to locked UX',
        (tester) async {
      var inbox = 0;
      var paywall = 0;
      final entry = WhoLikedYouEntry(
        readResonanceAccess: () async => throw StateError('unavailable'),
        openInbox: (_) async {
          inbox++;
        },
        openPaywall: (_, __) async {
          paywall++;
          return false;
        },
        showUnlockSheet: (_) async => false,
      );

      await _pumpAction(tester, onPressed: entry.openFromSettings);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(inbox, 0);
      expect(paywall, 1);
    });
  });

  group('Settings Resonance row', () {
    testWidgets('entitled tap opens inbox via Settings flow', (tester) async {
      var inbox = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            animateBackground: false,
            debugDeletionPending: false,
            debugForceDebugRow: false,
            whoLikedYouEntry: WhoLikedYouEntry(
              readResonanceAccess: () async => true,
              openInbox: (_) async {
                inbox++;
              },
              openPaywall: (_, __) async => false,
              showUnlockSheet: (_) async => false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('qmatch-settings-resonance')));
      await tester.pumpAndSettle();

      expect(inbox, 1);
    });

    testWidgets('free tap does not open inbox until purchase succeeds',
        (tester) async {
      var inbox = 0;
      var paywall = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(
            animateBackground: false,
            debugDeletionPending: false,
            whoLikedYouEntry: WhoLikedYouEntry(
              readResonanceAccess: () async => false,
              openInbox: (_) async {
                inbox++;
              },
              openPaywall: (_, feature) async {
                expect(feature, ResonancePaywallFeature.settingsResonance);
                paywall++;
                return false;
              },
              showUnlockSheet: (_) async => false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('qmatch-settings-resonance')));
      await tester.pumpAndSettle();

      expect(paywall, 1);
      expect(inbox, 0);
    });
  });

  group('Discover header', () {
    testWidgets('shows a subtle Who Liked You control without counts',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QMatchDiscoverHeader(
              title: 'Discover',
              trailing: QMatchGlassIconButton(
                key: const Key('qmatch-discover-who-liked-you'),
                icon: Icons.favorite_border,
                tooltip: 'Who liked you',
                semanticLabel: 'Who liked you',
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('qmatch-discover-header')), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-discover-who-liked-you')),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r'\d')), findsNothing);
      expect(find.textContaining('aligned with you'), findsNothing);

      await tester.tap(find.byKey(const Key('qmatch-discover-who-liked-you')));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('wiring (source)', () {
    test('Settings Resonance uses WhoLikedYouEntry, not a 4th tab', () {
      final settings = File(
        'lib/features/settings/screens/settings_screen.dart',
      ).readAsStringSync();
      expect(settings.contains('openFromSettings'), isTrue);
      expect(settings.contains('WhoLikedYouEntry'), isTrue);
      expect(settings.contains('ResonancePaywallScreen('), isFalse);
    });

    test('Discover header wires Who Liked You without counts or callable', () {
      final discover = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(discover.contains('openFromDiscover'), isTrue);
      expect(discover.contains('qmatch-discover-who-liked-you'), isTrue);
      expect(discover.contains('listWhoLikedYou'), isFalse);
      expect(discover.contains('people aligned'), isFalse);
      expect(discover.toLowerCase().contains('badge'), isFalse);
    });

    test('Discover always opens Alignment Signals; ordinary likes stay callable-gated',
        () {
      final entry = File(
        'lib/features/who_liked_you/navigation/who_liked_you_entry.dart',
      ).readAsStringSync();
      expect(entry.contains('openFromDiscover'), isTrue);
      expect(entry.contains('_openInboxAlways'), isTrue);
      expect(entry.contains('ResonancePaywallFeature.settingsResonance'), isTrue);
      expect(RegExp(r'listWhoLikedYou\(').hasMatch(entry), isFalse);
      expect(entry.contains('listSuperResonanceInbox'), isTrue);
    });

    test('bottom tabs still do not include Who Liked You', () {
      const paths = [
        'lib/core/navigation/main_navigation_screen.dart',
        'lib/core/navigation/qmatch_main_shell.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src.contains('WhoLikedYouScreen'), isFalse, reason: path);
        expect(src.contains('WhoLikedYouEntry'), isFalse, reason: path);
      }
    });
  });
}

Future<void> _pumpAction(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () => onPressed(context),
              child: const Text('go'),
            ),
          );
        },
      ),
    ),
  );
}
