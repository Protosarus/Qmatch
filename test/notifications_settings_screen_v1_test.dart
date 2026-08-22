import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/settings/domain/notification_prefs_snapshot.dart';
import 'package:qmatch/features/settings/screens/notifications_settings_screen.dart';
import 'package:qmatch/features/settings/services/notification_prefs_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  NotificationPrefsClient fakeClient({
    NotificationPrefsSnapshot initial = NotificationPrefsSnapshot.allEnabled,
    Future<NotificationPrefsSnapshot> Function()? onGet,
    Future<NotificationPrefsSnapshot> Function(NotificationPrefsSnapshot)?
        onSet,
  }) {
    var stored = initial;
    return NotificationPrefsClient(
      call: (name, data) async {
        if (name == NotificationPrefsClient.getCallableName) {
          if (onGet != null) return (await onGet()).toCallablePayload();
          return stored.toCallablePayload();
        }
        if (name == NotificationPrefsClient.setCallableName) {
          final next = NotificationPrefsSnapshot.fromTrustedMap(data);
          if (onSet != null) return (await onSet(next)).toCallablePayload();
          stored = next;
          return stored.toCallablePayload();
        }
        fail('Unexpected callable $name');
      },
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    required NotificationPrefsClient client,
  }) async {
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
        home: NotificationsSettingsScreen(client: client),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> flushUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  List<Switch> switchesOf(WidgetTester tester) {
    return tester.widgetList<Switch>(find.byType(Switch)).toList();
  }

  testWidgets('loads persisted prefs and omits Frequency row', (tester) async {
    await pumpScreen(
      tester,
      client: fakeClient(
        initial: const NotificationPrefsSnapshot(
          pushMaster: true,
          messages: false,
          matches: true,
          superResonance: false,
        ),
      ),
    );

    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('New match notifications'), findsOneWidget);
    expect(find.text('New message notifications'), findsOneWidget);
    expect(find.text('Super Resonance notifications'), findsOneWidget);
    expect(find.textContaining('Frequency'), findsNothing);
    expect(find.textContaining('daily suggestions'), findsNothing);

    final switches = switchesOf(tester);
    expect(switches, hasLength(4));
    expect(switches[0].value, isTrue); // master
    expect(switches[1].value, isTrue); // matches
    expect(switches[2].value, isFalse); // messages
    expect(switches[3].value, isFalse); // super resonance
  });

  testWidgets('master OFF disables children but remembers values',
      (tester) async {
    Map<String, dynamic>? lastSet;
    await pumpScreen(
      tester,
      client: fakeClient(
        initial: const NotificationPrefsSnapshot(
          pushMaster: true,
          messages: true,
          matches: false,
          superResonance: true,
        ),
        onSet: (next) async {
          lastSet = next.toCallablePayload();
          return next;
        },
      ),
    );

    // Turn master OFF — children stay at remembered values.
    await tester.tap(find.byType(Switch).first);
    await flushUi(tester);

    expect(lastSet, {
      'push_master': false,
      'messages': true,
      'matches': false,
      'super_resonance': true,
    });

    var switches = switchesOf(tester);
    expect(switches[0].value, isFalse);
    expect(switches[1].value, isFalse); // matches remembered
    expect(switches[2].value, isTrue); // messages remembered
    expect(switches[3].value, isTrue); // super resonance remembered
    expect(switches[1].onChanged, isNull);
    expect(switches[2].onChanged, isNull);
    expect(switches[3].onChanged, isNull);

    // Child taps while master OFF must not call set.
    lastSet = null;
    await tester.tap(find.byType(Switch).at(2));
    await flushUi(tester);
    expect(lastSet, isNull);
    expect(switchesOf(tester)[2].value, isTrue);
  });

  testWidgets('save failure rolls back and shows snackbar', (tester) async {
    await pumpScreen(
      tester,
      client: fakeClient(
        onSet: (_) async => throw StateError('save failed'),
      ),
    );

    expect(switchesOf(tester)[2].value, isTrue); // messages ON
    await tester.tap(find.byType(Switch).at(2));
    await flushUi(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(switchesOf(tester)[2].value, isTrue); // rolled back
    expect(
      find.text("Couldn't save notification preferences. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('load failure defaults all ON and shows snackbar',
      (tester) async {
    final gate = Completer<NotificationPrefsSnapshot>();
    await pumpScreen(
      tester,
      client: fakeClient(onGet: () => gate.future),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    gate.completeError(StateError('load failed'));
    await flushUi(tester);
    await tester.pump(const Duration(milliseconds: 500));

    final switches = switchesOf(tester);
    expect(switches.every((s) => s.value), isTrue);
    expect(
      find.text(
        "Couldn't load notification preferences. Try again later.",
      ),
      findsOneWidget,
    );
  });

  test('screen uses EU prefs client and never SharedPreferences', () {
    final src = File(
      'lib/features/settings/screens/notifications_settings_screen.dart',
    ).readAsStringSync();
    expect(src, contains('NotificationPrefsClient'));
    expect(src, contains('_client.set'));
    expect(src, isNot(contains('SharedPreferences')));
    expect(src, isNot(contains('frequencyDailySuggestions')));
  });
}
