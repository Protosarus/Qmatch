import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/qmatch_main_shell.dart';
import 'package:qmatch/features/messages/utils/conversation_identity_format.dart';
import 'package:qmatch/features/messages/utils/conversation_timestamp_format.dart';
import 'package:qmatch/features/messages/widgets/messages_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatConversationIdentity', () {
    test('avoids malformed punctuation', () {
      expect(formatConversationIdentity(name: 'Ada', age: 30), 'Ada, 30');
      expect(formatConversationIdentity(name: '', age: 30), isNull);
      expect(formatConversationIdentity(name: 'Ada', age: null), 'Ada');
      expect(formatConversationIdentity(name: '', age: null), isNull);
    });
  });

  group('formatConversationTimestamp', () {
    test('formats today and older days; null-safe', () {
      expect(formatConversationTimestamp(null), isNull);
      final today = Timestamp.fromDate(DateTime(2026, 7, 27, 14, 5));
      expect(
        formatConversationTimestamp(
          today,
          now: DateTime(2026, 7, 27, 18, 0),
          localeCode: 'en',
        ),
        '14:05',
      );
      final earlier = Timestamp.fromDate(DateTime(2026, 7, 20, 9, 0));
      expect(
        formatConversationTimestamp(
          earlier,
          now: DateTime(2026, 7, 27),
        ),
        '20.07',
      );
    });
  });

  group('Messages presentation states', () {
    testWidgets('loading state renders', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: QMatchMessagesLoadingState(message: 'Loading…'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('qmatch-messages-loading')), findsOneWidget);
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('empty state renders', (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: QMatchMessagesEmptyState(
                  title: l10n.messagesEmptyTitle,
                  body: l10n.messagesEmptySubtitle,
                ),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-messages-empty')), findsOneWidget);
      expect(find.text('No conversations yet'), findsOneWidget);
    });

    testWidgets('error state renders and retry is called', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchMessagesErrorState(
              title: 'Error',
              body: 'Try again',
              retryLabel: 'Retry',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-messages-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-messages-error-retry')));
      expect(retries, 1);
    });

    testWidgets('populated list and tap callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrapLocalized(
          Scaffold(
            body: QMatchConversationTile(
              displayName: 'Ada',
              age: 30,
              previewText: 'Hello',
              timestampText: '14:00',
              onTap: () => taps++,
            ),
          ),
        ),
      );
      expect(find.text('Ada, 30'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-conversation-tile')));
      expect(taps, 1);
      expect(find.textContaining('online'), findsNothing);
      expect(find.textContaining('typing'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('Core Method'), findsNothing);
    });

    testWidgets('missing avatar placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: Center(
              child: QMatchConversationAvatar(
                photoUrl: null,
                semanticLabel: 'Photo',
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-conversation-avatar-missing')),
        findsOneWidget,
      );
    });

    testWidgets('missing display name is safe', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchConversationTile(
              displayName: 'Conversation',
              age: null,
              previewText: 'Hi',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text(', '), findsNothing);
      expect(find.textContaining(', ,'), findsNothing);
      expect(find.text('Conversation'), findsOneWidget);
    });

    testWidgets('deleted counterpart uses fallback name safely',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchConversationTile(
              displayName: 'Conversation',
              previewText: 'Say hi',
              photoUrl: null,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('uid'), findsNothing);
      expect(find.textContaining('@'), findsNothing);
      expect(
        find.byKey(const Key('qmatch-conversation-avatar-missing')),
        findsOneWidget,
      );
    });

    testWidgets('long name and preview do not overflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: SizedBox(
              width: 320,
              child: QMatchConversationTile(
                displayName:
                    'Very Long Display Name That Must Ellipsize Across The Row',
                previewText: List.filled(20, 'long preview').join(' '),
                timestampText: '14:22',
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('missing preview is safe', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchConversationTile(
              displayName: 'Ada',
              previewText: 'Say hi',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(
          find.byKey(const Key('qmatch-conversation-preview')), findsOneWidget);
    });

    testWidgets('missing timestamp omits timestamp widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchConversationTile(
              displayName: 'Ada',
              previewText: 'Hi',
              timestampText: null,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(
          find.byKey(const Key('qmatch-conversation-timestamp')), findsNothing);
    });

    testWidgets('unread style only when unreadCount > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Column(
              children: [
                QMatchConversationTile(
                  displayName: 'Read',
                  previewText: 'Hi',
                  unreadCount: 0,
                  onTap: () {},
                ),
                QMatchConversationTile(
                  displayName: 'Unread',
                  previewText: 'Hello',
                  unreadCount: 3,
                  unreadSemanticLabel: '3 unread',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(
          find.byKey(const Key('qmatch-conversation-unread')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // Unread marker includes gold dot + count (not color-only).
      expect(find.byType(QMatchUnreadIndicator), findsOneWidget);
    });

    testWidgets('bottom navigation does not cover final row', (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: QMatchMainShell(
              currentIndex: 1,
              onTabSelected: (_) {},
              pages: [
                const SizedBox.shrink(),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      const QMatchMessagesHeader(title: 'Messages'),
                      Expanded(
                        child: ListView(
                          children: [
                            QMatchConversationTile(
                              displayName: 'Ada',
                              previewText: 'Hi',
                              onTap: () {},
                            ),
                            QMatchConversationTile(
                              key: const Key('last-row'),
                              displayName: 'Grace',
                              previewText: 'Hey',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox.shrink(),
              ],
              items: const [
                QMatchBottomNavigationItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                ),
                QMatchBottomNavigationItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                ),
                QMatchBottomNavigationItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );

      final last = tester.getRect(find.byKey(const Key('last-row')));
      final nav = tester.getRect(
        find.byKey(const Key('qmatch-bottom-navigation')),
      );
      expect(last.bottom <= nav.top + 0.5, isTrue);
    });
  });

  group('Messages source guards', () {
    test('screen keeps ChatService stream and chat navigation', () {
      final source = File(
        'lib/features/messages/screens/messages_screen.dart',
      ).readAsStringSync();
      expect(source.contains('ChatService'), isTrue);
      expect(source.contains('getMyThreadsStream'), isTrue);
      expect(source.contains('ChatDetailScreen'), isTrue);
      expect(source.contains('core_method'), isFalse);
      expect(source.contains('TraitScoring'), isFalse);
      expect(source.contains('CompatibilityScoring'), isFalse);
    });

    test('presentation widgets have no Firestore / writes / CM v2', () {
      final dir = Directory('lib/features/messages/widgets');
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(source.contains('cloud_firestore'), isFalse,
            reason: entity.path);
        expect(source.contains('FirebaseFirestore'), isFalse,
            reason: entity.path);
        expect(source.contains('.set('), isFalse, reason: entity.path);
        expect(source.contains('.update('), isFalse, reason: entity.path);
        expect(source.contains('core_method'), isFalse, reason: entity.path);
        expect(source.contains('TraitScoring'), isFalse, reason: entity.path);
        expect(source.contains('getMyThreadsStream'), isFalse,
            reason: entity.path);
      }
    });

    test('chat service remains thread query owner', () {
      final service = File(
        'lib/features/messages/services/chat_service.dart',
      ).readAsStringSync();
      expect(service.contains('getMyThreadsStream'), isTrue);
      expect(service.contains("arrayContains: me.uid"), isTrue);
      expect(service.contains('core_method'), isFalse);
    });
  });
}

Widget _wrap(Widget child) => MaterialApp(home: child);

Widget _wrapLocalized(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}
