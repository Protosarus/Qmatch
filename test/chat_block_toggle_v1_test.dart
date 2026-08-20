import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/messages/screens/chat_detail_screen.dart';
import 'package:qmatch/features/messages/utils/chat_block_overflow.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('chatBlockOverflow helpers', () {
    test('not blocked -> block only', () {
      expect(
        chatBlockOverflowAction(blockedByMe: false),
        ChatBlockOverflowAction.block,
      );
      expect(chatBlockOverflowValue(blockedByMe: false), 'block');
    });

    test('blocked -> unblock only', () {
      expect(
        chatBlockOverflowAction(blockedByMe: true),
        ChatBlockOverflowAction.unblock,
      );
      expect(chatBlockOverflowValue(blockedByMe: true), 'unblock');
    });
  });

  group('ChatDetailScreen block toggle', () {
    testWidgets('not blocked -> Engelle / Block; never both', (tester) async {
      await tester.pumpWidget(
        _wrapChat(
          const ChatDetailScreen(
            threadId: 'a_b',
            otherUserId: 'b',
            seedBlockedByMe: false,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();

      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Unblock'), findsNothing);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Unmatch'), findsOneWidget);
    });

    testWidgets('blocked -> Engeli kaldır / Unblock; never both',
        (tester) async {
      await tester.pumpWidget(
        _wrapChat(
          const ChatDetailScreen(
            threadId: 'a_b',
            otherUserId: 'b',
            seedBlockedByMe: true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();

      expect(find.text('Unblock'), findsOneWidget);
      expect(find.text('Block'), findsNothing);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Unmatch'), findsOneWidget);
    });

    testWidgets('block handler fires exactly once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrapChat(
          ChatDetailScreen(
            threadId: 'a_b',
            otherUserId: 'b',
            seedBlockedByMe: false,
            blockUser: ({
              required String blockedUid,
              String? matchId,
              String? threadId,
            }) async {
              calls++;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.text('Block this user?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Block'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets('local menu state updates after unblock', (tester) async {
      var unblocks = 0;
      await tester.pumpWidget(
        _wrapChat(
          ChatDetailScreen(
            threadId: 'a_b',
            otherUserId: 'b',
            seedBlockedByMe: true,
            unblockUser: ({required String blockedUid}) async {
              unblocks++;
              expect(blockedUid, 'b');
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();
      expect(find.text('Unblock this user?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Unblock'));
      await tester.pumpAndSettle();
      expect(unblocks, 1);

      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Block'), findsOneWidget);
      expect(find.text('Unblock'), findsNothing);
    });
  });

  test('unblockUser deletes only owner block doc; no match/thread reopen', () {
    final src = File(
      'lib/features/safety/services/safety_service.dart',
    ).readAsStringSync();
    final start = src.indexOf('Future<void> unblockUser');
    expect(start, greaterThan(0));
    final body = src.substring(start);
    expect(body.contains('userBlockDoc(me.uid, target)'), isTrue);
    expect(body.contains('.delete()'), isTrue);
    expect(body.contains('closeRelationship'), isFalse);
    expect(body.contains('MatchCloseTarget'), isFalse);
    expect(body.contains('threadDoc'), isFalse);
    expect(body.contains("collection('messages')"), isFalse);
    expect(body.contains("'state': 'active'"), isFalse);
  });

  test('chat bootstrap loads hasBlockedUser; overflow has one block row', () {
    final screen = File(
      'lib/features/messages/screens/chat_detail_screen.dart',
    ).readAsStringSync();
    expect(screen.contains('hasBlockedUser'), isTrue);
    expect(screen.contains('_blockedByMe'), isTrue);
    expect(screen.contains('chatBlockOverflowValue'), isTrue);
    expect(screen.contains("case 'unblock':"), isTrue);
    expect(screen.contains('unblockUser'), isTrue);
  });
}

Widget _wrapChat(Widget home) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: home,
  );
}
