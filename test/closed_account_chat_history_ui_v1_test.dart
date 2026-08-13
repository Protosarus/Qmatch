import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';
import 'package:qmatch/features/messages/utils/closed_account_chat_history.dart';
import 'package:qmatch/features/messages/widgets/chat_detail_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

ChatThreadModel _thread({
  required ThreadStatus status,
  String? closedReason,
  String id = 'a_b',
}) {
  return ChatThreadModel(
    threadId: id,
    participants: const ['a', 'b'],
    matchId: id,
    lastMessageAt: Timestamp.fromDate(DateTime(2026, 8, 1)),
    lastMessagePreview: 'hello',
    status: status,
    closedReason: closedReason,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClosedAccountChatHistory', () {
    test('active thread unchanged — included and sendable', () {
      final t = _thread(status: ThreadStatus.active);
      expect(ClosedAccountChatHistory.includeInMessagesList(t), isTrue);
      expect(ClosedAccountChatHistory.allowMessageHistoryRead(t), isTrue);
      expect(ClosedAccountChatHistory.allowSend(t), isTrue);
      expect(ClosedAccountChatHistory.isAccountDeletionClosed(t), isFalse);
    });

    test('deletion-closed thread appears in list; history yes; send no', () {
      final t = _thread(
        status: ThreadStatus.closed,
        closedReason: ClosedAccountChatHistory.closedReasonAccountDeletion,
      );
      expect(ClosedAccountChatHistory.includeInMessagesList(t), isTrue);
      expect(ClosedAccountChatHistory.allowMessageHistoryRead(t), isTrue);
      expect(ClosedAccountChatHistory.allowSend(t), isFalse);
      expect(ClosedAccountChatHistory.isAccountDeletionClosed(t), isTrue);
    });

    test('unmatched/blocked closed threads stay hidden', () {
      final unmatched = _thread(
        status: ThreadStatus.closed,
        closedReason: 'unmatched',
      );
      final blocked = _thread(
        status: ThreadStatus.closed,
        closedReason: 'blocked',
      );
      expect(ClosedAccountChatHistory.includeInMessagesList(unmatched), isFalse);
      expect(ClosedAccountChatHistory.includeInMessagesList(blocked), isFalse);
      expect(ClosedAccountChatHistory.allowMessageHistoryRead(unmatched), isFalse);
      expect(ClosedAccountChatHistory.allowSend(unmatched), isFalse);
    });

    test('fromFirestore preserves closed_reason', () {
      final t = ChatThreadModel.fromFirestore('a_b', {
        'participants': ['a', 'b'],
        'status': 'closed',
        'closed_reason': 'account_deletion_requested',
      });
      expect(t.closedReason, 'account_deletion_requested');
      expect(ClosedAccountChatHistory.isAccountDeletionClosed(t), isTrue);
    });
  });

  group('closed account chat UI widgets', () {
    testWidgets('inactive banner shows conversation no longer active',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return QMatchConversationInactiveBanner(
                  message: l10n.chatConversationNoLongerActive,
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-chat-inactive-banner')), findsOneWidget);
      expect(find.text('This conversation is no longer active.'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-chat-composer')), findsNothing);
    });

    testWidgets('composer disabled — send unavailable', (tester) async {
      final controller = TextEditingController(text: 'hi');
      final focus = FocusNode();
      var sent = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QMatchMessageComposer(
              controller: controller,
              focusNode: focus,
              hintText: 'Message…',
              enabled: false,
              onSend: () => sent = true,
            ),
          ),
        ),
      );
      expect(tester.widget<TextField>(
        find.byKey(const Key('qmatch-chat-composer-field')),
      ).enabled, isFalse);
      await tester.tap(find.byKey(const Key('qmatch-chat-composer-send')));
      await tester.pump();
      expect(sent, isFalse);
      controller.dispose();
      focus.dispose();
    });

    testWidgets('unavailable profile placeholder — no title tap navigation',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: QMatchConversationAppBar(
              title: 'Unavailable account',
              loading: false,
              photoUrl: null,
              onTitleTap: null,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      expect(find.text('Unavailable account'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-chat-app-bar-identity')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-chat-app-bar-identity')));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('normal profile navigation callback can fire when provided',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: QMatchConversationAppBar(
              title: 'Ada',
              loading: false,
              photoUrl: null,
              onTitleTap: () => tapped = true,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-chat-app-bar-identity')));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
