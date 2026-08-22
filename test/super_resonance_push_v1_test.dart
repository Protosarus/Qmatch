import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/notifications/message_push_tap_host.dart';
import 'package:qmatch/core/notifications/message_push_tap_router.dart';
import 'package:qmatch/core/notifications/push_messaging_port.dart';
import 'package:qmatch/core/notifications/push_permission_state.dart';

Map<String, String> srPayload({
  String signalId = 'userA_userB',
  String otherUid = 'userA',
}) {
  return {
    'type': 'super_resonance',
    'signal_id': signalId,
    'other_uid': otherUid,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MessagePushTapRouter router;

  setUp(() {
    router = MessagePushTapRouter();
  });

  test('super resonance tap opens Alignment Signals for the recipient',
      () async {
    final result = await router.handle(
      data: srPayload(),
      currentUid: 'userB',
      loadThread: (_) async => null,
      blockExists: (_, __) async => false,
    );
    expect(result.outcome, MessagePushTapOutcome.openAlignmentSignals);
    expect(result.signalId, 'userA_userB');
    expect(result.otherUserId, 'userA');
    expect(result.guard, 'open_alignment_signals');
  });

  test('invalid signal ownership still opens Alignment Signals safely',
      () async {
    final result = await router.handle(
      data: srPayload(signalId: 'userX_userY', otherUid: 'userA'),
      currentUid: 'userB',
      loadThread: (_) async => null,
      blockExists: (_, __) async => false,
    );
    expect(result.outcome, MessagePushTapOutcome.openAlignmentSignals);
    expect(result.guard, 'signal_not_for_recipient');
  });

  test('blocked pair still opens Alignment Signals safely', () async {
    final result = await router.handle(
      data: srPayload(),
      currentUid: 'userB',
      loadThread: (_) async => null,
      blockExists: (_, __) async => true,
    );
    expect(result.outcome, MessagePushTapOutcome.openAlignmentSignals);
    expect(result.guard, 'blocked_by_me');
  });

  test('duplicate super resonance tap is ignored', () async {
    final first = await router.handle(
      data: srPayload(),
      currentUid: 'userB',
      loadThread: (_) async => null,
      blockExists: (_, __) async => false,
    );
    final second = await router.handle(
      data: srPayload(),
      currentUid: 'userB',
      loadThread: (_) async => null,
      blockExists: (_, __) async => false,
    );
    expect(first.outcome, MessagePushTapOutcome.openAlignmentSignals);
    expect(second.outcome, MessagePushTapOutcome.ignore);
    expect(second.guard, 'duplicate');
  });

  test('signed out ignores super resonance tap', () async {
    final result = await router.handle(
      data: srPayload(),
      currentUid: null,
      loadThread: (_) async => null,
      blockExists: (_, __) async => false,
    );
    expect(result.outcome, MessagePushTapOutcome.ignore);
    expect(result.guard, 'signed_out');
  });

  test('trigger is europe-west1 on super_resonance_signals create', () {
    final src = File('functions/src/super_resonance_push.js').readAsStringSync();
    final idx = File('functions/index.js').readAsStringSync();
    expect(src.contains("REGION = 'europe-west1'"), isTrue);
    expect(
      src.contains("DOCUMENT_PATH = 'super_resonance_signals/{signalId}'"),
      isTrue,
    );
    expect(idx.contains('exports.sendSuperResonancePush'), isTrue);
    expect(idx.contains("document: 'super_resonance_signals/{signalId}'"), isTrue);
    expect(idx.contains("region: 'europe-west1'"), isTrue);
    // Push module must not spend credits / touch send callable internals.
    expect(src.contains('BALANCE_FIELDS'), isFalse);
    expect(src.contains('spendDailyAllowance'), isFalse);
    expect(src.contains('debitBalance'), isFalse);
    expect(src.contains("require('./send_super_resonance_callable')"), isFalse);
  });

  testWidgets('host routes super_resonance tap to Alignment Signals',
      (tester) async {
    final actions = _SrRecordingActions();
    final messaging = _SrFakeMessaging(
      initial: srPayload(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MessagePushTapHost(
          messaging: messaging,
          currentUid: () => 'userB',
          loadThread: (_) async => null,
          blockExists: (_, __) async => false,
          actions: actions,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(actions.alignmentSignals, 1);
    expect(actions.messagesTab, 0);
    expect(actions.opens, isEmpty);
  });

  testWidgets('host opens Alignment Signals for invalid signal ownership',
      (tester) async {
    final actions = _SrRecordingActions();
    final messaging = _SrFakeMessaging(
      initial: srPayload(signalId: 'bad_id', otherUid: 'userA'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MessagePushTapHost(
          messaging: messaging,
          currentUid: () => 'userB',
          loadThread: (_) async => null,
          blockExists: (_, __) async => false,
          actions: actions,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(actions.alignmentSignals, 1);
  });
}

class _SrRecordingActions implements MessagePushTapActions {
  final opens = <Map<String, String>>[];
  int messagesTab = 0;
  int alignmentSignals = 0;

  @override
  void openChat({required String threadId, required String otherUserId}) {
    opens.add({'threadId': threadId, 'otherUserId': otherUserId});
  }

  @override
  void showMessagesTab() {
    messagesTab += 1;
  }

  @override
  void openAlignmentSignals() {
    alignmentSignals += 1;
  }
}

class _SrFakeMessaging implements PushMessagingPort {
  _SrFakeMessaging({this.initial});

  Map<String, String>? initial;

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
  Future<Map<String, String>?> getInitialMessage() async => initial;

  @override
  Stream<Map<String, String>> get onNotificationOpened => const Stream.empty();

  @override
  Stream<Map<String, String>> get onForegroundMessage => const Stream.empty();
}
