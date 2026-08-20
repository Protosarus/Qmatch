import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/messages/widgets/qmatch_conversation_tile.dart';
import 'package:qmatch/features/messages/widgets/qmatch_conversation_unmatch_swipe.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpSwipe(
    WidgetTester tester, {
    required Future<void> Function() onUnmatch,
    required List<String> ids,
    required VoidCallback onRemoved,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ListView(
                children: [
                  for (final id in ids)
                    QMatchConversationUnmatchSwipe(
                      threadId: id,
                      onUnmatch: () async {
                        await onUnmatch();
                        setState(onRemoved);
                      },
                      child: QMatchConversationTile(
                        displayName: 'Ada $id',
                        previewText: 'hi',
                        onTap: () {},
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('left swipe reveals Eşleşmeyi kaldır / Unmatch', (tester) async {
    await pumpSwipe(
      tester,
      onUnmatch: () async {},
      ids: const ['t1'],
      onRemoved: () {},
    );

    await tester.drag(
      find.byKey(const Key('qmatch-messages-unmatch-swipe-t1')),
      const Offset(-220, 0),
    );
    await tester.pump();

    expect(find.byKey(const Key('qmatch-messages-swipe-unmatch-label')),
        findsOneWidget);
    expect(find.text('Unmatch'), findsWidgets);

    final bg = tester.widget<ColoredBox>(
      find.byKey(const Key('qmatch-messages-swipe-unmatch-bg')),
    );
    expect(bg.color, isNot(AppColors.softGold));
    expect(bg.color, isNot(AppColors.warmGold));
  });

  testWidgets('cancel does nothing; confirm calls unmatch once and row goes',
      (tester) async {
    var calls = 0;
    final ids = <String>['t1', 't2'];

    await pumpSwipe(
      tester,
      onUnmatch: () async {
        calls++;
      },
      ids: ids,
      onRemoved: () {
        ids.remove('t1');
      },
    );

    await tester.drag(
      find.byKey(const Key('qmatch-messages-unmatch-swipe-t1')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unmatch?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Ada t1'), findsOneWidget);
    expect(find.text('Ada t2'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('qmatch-messages-unmatch-swipe-t1')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('qmatch-messages-unmatch-confirm')));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Ada t1'), findsNothing);
    expect(find.text('Ada t2'), findsOneWidget);
  });

  test('Messages swipe uses existing unmatch; no Sil; no thread delete', () {
    final screen = File(
      'lib/features/messages/screens/messages_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('MatchService'), isTrue);
    expect(screen.contains('_unmatchThread'), isTrue);
    expect(screen.contains('QMatchConversationUnmatchSwipe'), isTrue);
    expect(screen.contains("collection('messages')"), isFalse);
    expect(screen.contains('.delete('), isFalse);
    expect(screen.contains('deleteAction'), isFalse);
    expect(screen.contains("'Sil'"), isFalse);

    final swipe = File(
      'lib/features/messages/widgets/qmatch_conversation_unmatch_swipe.dart',
    ).readAsStringSync();
    expect(swipe.contains('chatMenuUnmatch'), isTrue);
    expect(swipe.contains('DismissDirection.endToStart'), isTrue);
    expect(swipe.contains('MatchService'), isFalse);
    expect(swipe.contains('cloud_firestore'), isFalse);
    expect(swipe.contains('AppColors.softGold'), isFalse);

    expect(
      File('lib/features/messages/screens/chat_detail_screen.dart')
          .readAsStringSync()
          .contains("case 'unmatch':"),
      isTrue,
    );
  });
}
