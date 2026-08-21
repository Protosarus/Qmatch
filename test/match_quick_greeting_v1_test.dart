import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_match_dialog.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Future<void> Function(String text) onSendGreeting,
    void Function(DiscoverMatchDialogAction? action)? onClosed,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('show-match-dialog'),
                  onPressed: () async {
                    final l10n = AppLocalizations.of(context)!;
                    final action = await showQMatchDiscoverMatchDialog(
                      context: context,
                      title: l10n.discoverItsAMatch,
                      body: l10n.discoverMatchDialogBody,
                      openChatLabel: l10n.discoverMatchOpenChat,
                      continueLabel: l10n.continueAction,
                      quickGreetings: [
                        l10n.discoverMatchGreetingHi,
                        l10n.discoverMatchGreetingHello,
                        l10n.discoverMatchGreetingHowsItGoing,
                      ],
                      sendFailedLabel: l10n.discoverMatchGreetingSendFailed,
                      onSendGreeting: onSendGreeting,
                    );
                    onClosed?.call(action);
                  },
                  child: const Text('show'),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('show-match-dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('EN greeting chips are shown between body and Open chat',
      (tester) async {
    await pumpDialog(tester, onSendGreeting: (_) async {});
    expect(find.byKey(const Key('qmatch-discover-match-greetings')), findsOneWidget);
    expect(find.text('Hi 👋'), findsOneWidget);
    expect(find.text('Hello 😊'), findsOneWidget);
    expect(find.text("How's it going?"), findsOneWidget);
    final greetingsY =
        tester.getCenter(find.byKey(const Key('qmatch-discover-match-greetings'))).dy;
    final bodyY = tester.getCenter(find.text('You can now start a conversation.')).dy;
    final openY =
        tester.getCenter(find.byKey(const Key('qmatch-discover-match-open-chat'))).dy;
    expect(greetingsY, greaterThan(bodyY));
    expect(openY, greaterThan(greetingsY));
  });

  testWidgets('TR greeting chips use localized copy', (tester) async {
    await pumpDialog(
      tester,
      locale: const Locale('tr'),
      onSendGreeting: (_) async {},
    );
    expect(find.text('Merhaba 👋'), findsOneWidget);
    expect(find.text('Selam 😊'), findsOneWidget);
    expect(find.text('Nasılsın?'), findsOneWidget);
    expect(find.text('Sohbete git'), findsOneWidget);
  });

  testWidgets('successful greeting send closes with sentQuickGreeting',
      (tester) async {
    DiscoverMatchDialogAction? action;
    final sent = <String>[];
    await pumpDialog(
      tester,
      onSendGreeting: (text) async {
        sent.add(text);
      },
      onClosed: (a) => action = a,
    );

    await tester.tap(find.byKey(const Key('qmatch-discover-match-greeting-0')));
    await tester.pumpAndSettle();

    expect(sent, ['Hi 👋']);
    expect(action, DiscoverMatchDialogAction.sentQuickGreeting);
    expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
  });

  testWidgets('failed greeting keeps dialog open with inline error',
      (tester) async {
    DiscoverMatchDialogAction? action;
    await pumpDialog(
      tester,
      onSendGreeting: (_) async {
        throw StateError('send failed');
      },
      onClosed: (a) => action = a,
    );

    await tester.tap(find.byKey(const Key('qmatch-discover-match-greeting-1')));
    await tester.pumpAndSettle();

    expect(action, isNull);
    expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsOneWidget);
    expect(
      find.byKey(const Key('qmatch-discover-match-greeting-error')),
      findsOneWidget,
    );
    expect(find.text("Couldn't send. Try again."), findsOneWidget);
  });

  testWidgets('double tap does not send duplicate greetings', (tester) async {
    DiscoverMatchDialogAction? action;
    var calls = 0;
    await pumpDialog(
      tester,
      onSendGreeting: (text) async {
        calls += 1;
        await Future<void>.delayed(const Duration(milliseconds: 80));
      },
      onClosed: (a) => action = a,
    );

    await tester.tap(find.byKey(const Key('qmatch-discover-match-greeting-0')));
    await tester.tap(find.byKey(const Key('qmatch-discover-match-greeting-0')));
    await tester.tap(find.byKey(const Key('qmatch-discover-match-greeting-2')));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(action, DiscoverMatchDialogAction.sentQuickGreeting);
  });

  testWidgets('Open chat and Continue still work', (tester) async {
    DiscoverMatchDialogAction? action;
    await pumpDialog(
      tester,
      onSendGreeting: (_) async {},
      onClosed: (a) => action = a,
    );
    await tester.tap(find.byKey(const Key('qmatch-discover-match-open-chat')));
    await tester.pumpAndSettle();
    expect(action, DiscoverMatchDialogAction.openChat);

    action = null;
    await pumpDialog(
      tester,
      onSendGreeting: (_) async {},
      onClosed: (a) => action = a,
    );
    await tester.tap(find.byKey(const Key('qmatch-discover-match-continue')));
    await tester.pumpAndSettle();
    expect(action, DiscoverMatchDialogAction.continueDiscover);
  });

  test('Discover opens ChatDetailScreen only for openChat action', () {
    final src = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();
    expect(src.contains('ChatService().sendTextMessage'), isTrue);
    expect(src.contains('DiscoverMatchDialogAction.openChat'), isTrue);
    final openIdx =
        src.indexOf('if (action == DiscoverMatchDialogAction.openChat)');
    expect(openIdx, greaterThanOrEqualTo(0));
    final openBlock = src.substring(openIdx, openIdx + 280);
    expect(openBlock.contains('ChatDetailScreen'), isTrue);
  });
}
