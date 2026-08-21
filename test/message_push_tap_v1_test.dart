import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/notifications/message_push_tap_host.dart';
import 'package:qmatch/core/notifications/message_push_tap_router.dart';
import 'package:qmatch/core/notifications/push_messaging_port.dart';
import 'package:qmatch/core/notifications/push_permission_state.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';

Map<String, String> messagePayload({
  String type = 'message',
  String threadId = 'userA_userB',
  String otherUid = 'userB',
  String messageId = 'msg-1',
}) {
  return {
    'type': type,
    'thread_id': threadId,
    'other_uid': otherUid,
    'message_id': messageId,
  };
}

ChatThreadModel activeThread({
  String id = 'userA_userB',
  List<String> participants = const ['userA', 'userB'],
  ThreadStatus status = ThreadStatus.active,
}) {
  return ChatThreadModel(
    threadId: id,
    participants: participants,
    status: status,
  );
}

class _RecordingActions implements MessagePushTapActions {
  final opens = <Map<String, String>>[];
  int messagesTab = 0;

  @override
  void openChat({required String threadId, required String otherUserId}) {
    opens.add({'threadId': threadId, 'otherUserId': otherUserId});
  }

  @override
  void showMessagesTab() {
    messagesTab += 1;
  }
}

class _FakeMessaging implements PushMessagingPort {
  _FakeMessaging({this.initial});

  Map<String, String>? initial;
  final opened = StreamController<Map<String, String>>.broadcast();

  @override
  Future<PushPermissionState> currentPermission() async =>
      PushPermissionState.authorized;

  @override
  Future<PushPermissionState> requestPermission() async =>
      PushPermissionState.authorized;

  @override
  Future<String?> getAPNSToken() async => null;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, String>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, String>> get onNotificationOpened => opened.stream;

  @override
  Future<Map<String, String>?> getInitialMessage() async => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String read(String path) => File(path).readAsStringSync();

  late MessagePushTapRouter router;

  Future<MessagePushTapResult> handle(
    Map<String, String> data, {
    String? uid = 'userA',
    ChatThreadModel? thread,
    Set<String> blocked = const {},
  }) {
    return router.handle(
      data: data,
      currentUid: uid,
      loadThread: (id) async => thread,
      blockExists: (from, to) async => blocked.contains('$from->$to'),
    );
  }

  setUp(() {
    router = MessagePushTapRouter();
  });

  test('background/terminated payload opens the correct thread', () async {
    final result = await handle(
      messagePayload(),
      thread: activeThread(),
    );
    expect(result.outcome, MessagePushTapOutcome.openChat);
    expect(result.threadId, 'userA_userB');
    expect(result.otherUserId, 'userB');
    expect(result.messageId, 'msg-1');
  });

  test('signed out does not open chat', () async {
    final result = await handle(
      messagePayload(),
      uid: null,
      thread: activeThread(),
    );
    expect(result.outcome, MessagePushTapOutcome.ignore);
    expect(result.threadId, isNull);
  });

  test('missing thread falls back to Messages', () async {
    final result = await handle(messagePayload());
    expect(result.outcome, MessagePushTapOutcome.fallbackMessages);
  });

  test('closed thread falls back to Messages', () async {
    final result = await handle(
      messagePayload(),
      thread: activeThread(status: ThreadStatus.closed),
    );
    expect(result.outcome, MessagePushTapOutcome.fallbackMessages);
  });

  test('blocked pair falls back to Messages', () async {
    final blockedMe = await handle(
      messagePayload(),
      thread: activeThread(),
      blocked: {'userA->userB'},
    );
    expect(blockedMe.outcome, MessagePushTapOutcome.fallbackMessages);

    final router2 = MessagePushTapRouter();
    final blockedThem = await router2.handle(
      data: messagePayload(messageId: 'msg-2'),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      blockExists: (from, to) async => from == 'userB' && to == 'userA',
    );
    expect(blockedThem.outcome, MessagePushTapOutcome.fallbackMessages);
  });

  test('malformed payload falls back or is ignored', () async {
    final malformed = await handle({
      'type': 'message',
      'thread_id': '',
      'other_uid': 'userB',
      'message_id': 'msg-1',
    }, thread: activeThread());
    expect(malformed.outcome, MessagePushTapOutcome.fallbackMessages);

    final otherType = await handle(
      messagePayload(type: 'match'),
      thread: activeThread(),
    );
    expect(otherType.outcome, MessagePushTapOutcome.ignore);
  });

  test('duplicate tap of the same message_id navigates once', () async {
    final first = await handle(
      messagePayload(),
      thread: activeThread(),
    );
    final second = await handle(
      messagePayload(),
      thread: activeThread(),
    );
    expect(first.outcome, MessagePushTapOutcome.openChat);
    expect(second.outcome, MessagePushTapOutcome.ignore);
  });

  testWidgets('terminated tap waits for host then opens chat', (tester) async {
    final actions = _RecordingActions();
    final messaging = _FakeMessaging(initial: messagePayload());
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: MessagePushTapHost(
          messaging: messaging,
          currentUid: () => 'userA',
          loadThread: (_) async {
            await ready.future;
            return activeThread();
          },
          blockExists: (_, __) async => false,
          actions: actions,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(actions.opens, isEmpty);
    ready.complete();
    await tester.pump();
    expect(actions.opens, [
      {'threadId': 'userA_userB', 'otherUserId': 'userB'},
    ]);
    expect(actions.messagesTab, 0);
    await messaging.opened.close();
  });

  testWidgets('signed-out tap does not open chat', (tester) async {
    final actions = _RecordingActions();
    final messaging = _FakeMessaging(initial: messagePayload());
    await tester.pumpWidget(
      MaterialApp(
        home: MessagePushTapHost(
          messaging: messaging,
          currentUid: () => null,
          loadThread: (_) async => activeThread(),
          blockExists: (_, __) async => false,
          actions: actions,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    expect(actions.opens, isEmpty);
    expect(actions.messagesTab, 0);
    await messaging.opened.close();
  });

  testWidgets('background tap opens the correct thread once', (tester) async {
    final actions = _RecordingActions();
    final messaging = _FakeMessaging();
    await tester.pumpWidget(
      MaterialApp(
        home: MessagePushTapHost(
          messaging: messaging,
          currentUid: () => 'userA',
          loadThread: (_) async => activeThread(),
          blockExists: (_, __) async => false,
          actions: actions,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    messaging.opened.add(messagePayload());
    await tester.pump();
    messaging.opened.add(messagePayload());
    await tester.pump();
    expect(actions.opens, [
      {'threadId': 'userA_userB', 'otherUserId': 'userB'},
    ]);
    await messaging.opened.close();
  });

  test('tap routing is only wired after authenticated main', () {
    final dest = read(
      'lib/core/navigation/assessment_progress_route_gate.dart',
    );
    expect(dest.contains('MessagePushTapHost()'), isTrue);
    final wrapper = read('lib/core/navigation/auth_wrapper.dart');
    expect(wrapper.contains('MessagePushTapHost'), isFalse);
    final chat = read('lib/features/messages/services/chat_service.dart');
    expect(chat.contains('MessagePushTap'), isFalse);
    final send = read('functions/src/new_message_push.js');
    expect(send.contains('handleThreadMessageCreated'), isTrue);
  });
}
