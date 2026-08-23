import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/main_navigation_screen.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';
import 'package:qmatch/features/messages/utils/unread_conversation_badge.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  ChatThreadModel thread({
    required String id,
    required Map<String, int> unread,
  }) {
    return ChatThreadModel(
      threadId: id,
      participants: const ['me', 'other'],
      unreadCounts: unread,
    );
  }

  group('unreadConversationCount / badge label', () {
    test('0 unread conversations => no badge', () {
      expect(
        unreadConversationCount(threads: const [], currentUid: 'me'),
        0,
      );
      expect(
        unreadConversationCount(
          threads: [
            thread(id: 'a', unread: const {'me': 0, 'other': 4}),
          ],
          currentUid: 'me',
        ),
        0,
      );
      expect(unreadConversationBadgeLabel(0), isNull);
    });

    test('1 unread conversation => 1', () {
      expect(
        unreadConversationCount(
          threads: [
            thread(id: 'a', unread: const {'me': 1})
          ],
          currentUid: 'me',
        ),
        1,
      );
      expect(unreadConversationBadgeLabel(1), '1');
    });

    test('multiple unread messages in one thread still count as 1', () {
      expect(
        unreadConversationCount(
          threads: [
            thread(id: 'a', unread: const {'me': 12})
          ],
          currentUid: 'me',
        ),
        1,
      );
      expect(unreadConversationBadgeLabel(1), '1');
    });

    test('two unread threads => 2', () {
      expect(
        unreadConversationCount(
          threads: [
            thread(id: 'a', unread: const {'me': 3}),
            thread(id: 'b', unread: const {'me': 1}),
            thread(id: 'c', unread: const {'me': 0}),
          ],
          currentUid: 'me',
        ),
        2,
      );
      expect(unreadConversationBadgeLabel(2), '2');
    });

    test('>9 unread conversations => 9+', () {
      final threads = [
        for (var i = 0; i < 10; i++) thread(id: 't$i', unread: const {'me': 1}),
      ];
      expect(
        unreadConversationCount(threads: threads, currentUid: 'me'),
        10,
      );
      expect(unreadConversationBadgeLabel(10), '9+');
    });
  });

  group('Messages tab live badge', () {
    StreamController<List<ChatThreadModel>> liveController() {
      final controller = StreamController<List<ChatThreadModel>>(sync: true);
      addTearDown(controller.close);
      return controller;
    }

    testWidgets('0 unread conversations => no badge', (tester) async {
      final controller = liveController();
      await tester.pumpWidget(_wrapNav(controller.stream));
      controller.add([
        thread(id: 'a', unread: const {'me': 0})
      ]);
      await tester.pump();
      expect(find.byKey(const Key('qmatch-nav-unread-badge-2')), findsNothing);
    });

    testWidgets('1 unread conversation => 1', (tester) async {
      final controller = liveController();
      await tester.pumpWidget(_wrapNav(controller.stream));
      controller.add([
        thread(id: 'a', unread: const {'me': 2})
      ]);
      await tester.pump();
      expect(
          find.byKey(const Key('qmatch-nav-unread-badge-2')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('qmatch-nav-unread-badge-2')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(find.text('2'), findsNothing);
    });

    testWidgets('two unread threads => 2; mark read removes badge',
        (tester) async {
      final controller = liveController();
      await tester.pumpWidget(_wrapNav(controller.stream));
      controller.add([
        thread(id: 'a', unread: const {'me': 4}),
        thread(id: 'b', unread: const {'me': 1}),
      ]);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('qmatch-nav-unread-badge-2')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      controller.add([
        thread(id: 'a', unread: const {'me': 0}),
        thread(id: 'b', unread: const {'me': 0}),
      ]);
      await tester.pump();
      expect(find.byKey(const Key('qmatch-nav-unread-badge-2')), findsNothing);
    });

    testWidgets('>9 unread conversations => 9+', (tester) async {
      final controller = liveController();
      await tester.pumpWidget(_wrapNav(controller.stream));
      controller.add([
        for (var i = 0; i < 11; i++) thread(id: 't$i', unread: const {'me': 1}),
      ]);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('qmatch-nav-unread-badge-2')),
          matching: find.text('9+'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('badge fill is lilac/violet, not red', (tester) async {
      final controller = liveController();
      await tester.pumpWidget(_wrapNav(controller.stream));
      controller.add([
        thread(id: 'a', unread: const {'me': 1})
      ]);
      await tester.pump();
      final box = tester.widget<Container>(
        find.byKey(const Key('qmatch-nav-unread-badge-2')),
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, isNot(AppColors.danger));
      expect(decoration.color, isNot(const Color(0xFFFF0000)));
      expect(
        decoration.color,
        AppColors.resonanceViolet.withValues(alpha: 0.95),
      );
    });
  });

  test('tab badge reuses thread unread_counts; no messages subcollection', () {
    final nav = File(
      'lib/core/navigation/main_navigation_screen.dart',
    ).readAsStringSync();
    expect(nav.contains('getMyThreadsStream()'), isTrue);
    expect(nav.contains('unreadConversationCount'), isTrue);
    expect(nav.contains('threadMessages'), isFalse);
    expect(nav.contains("collection('messages')"), isFalse);

    final svc = File(
      'lib/features/messages/services/chat_service.dart',
    ).readAsStringSync();
    expect(svc.contains("unread_counts.\$otherUid"), isTrue);
    expect(svc.contains("unread_counts.\${me.uid}"), isTrue);
  });
}

Widget _wrapNav(Stream<List<ChatThreadModel>> stream) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MainNavigationScreen(
      currentUid: 'me',
      threadsStream: stream,
      screens: const [
        SizedBox.expand(),
        SizedBox.expand(),
        SizedBox.expand(),
        SizedBox.expand(),
      ],
    ),
  );
}
