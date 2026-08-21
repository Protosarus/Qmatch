import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/notifications/notification_registration_service.dart';
import 'package:qmatch/core/notifications/push_messaging_port.dart';
import 'package:qmatch/core/notifications/push_permission_state.dart';

class _FakeMessaging implements PushMessagingPort {
  _FakeMessaging();

  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<Map<String, String>>.broadcast();

  @override
  Future<PushPermissionState> currentPermission() async =>
      PushPermissionState.authorized;

  @override
  Future<PushPermissionState> requestPermission() async =>
      PushPermissionState.authorized;

  @override
  Future<String?> getAPNSToken() async => 'apns';

  @override
  Future<String?> getToken() async => 'tok-1';

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Stream<Map<String, String>> get onForegroundMessage => foreground.stream;

  @override
  Stream<Map<String, String>> get onNotificationOpened => const Stream.empty();

  @override
  Future<Map<String, String>?> getInitialMessage() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String read(String path) => File(path).readAsStringSync();

  late _FakeMessaging messaging;
  late List<String> logs;
  late NotificationRegistrationService service;

  setUp(() {
    messaging = _FakeMessaging();
    logs = <String>[];
    service = NotificationRegistrationService(
      messaging: messaging,
      call: (_, __) async {},
      currentUid: () => 'userA',
      appId: () => 'app',
      isIOS: true,
      apnsEnv: 'sandbox',
      log: logs.add,
      delay: (_) async {},
    );
  });

  tearDown(() async {
    await messaging.refresh.close();
    await messaging.foreground.close();
  });

  test('foreground iOS receipt is logged without a local banner or text',
      () async {
    await service.startAfterAuthenticatedAppReady();
    messaging.foreground.add({
      'type': 'message',
      'thread_id': 'userA_userB',
      'other_uid': 'userB',
      'message_id': 'msg-1',
      'text': 'should-not-be-logged',
    });
    await Future<void>.delayed(Duration.zero);
    expect(logs, contains('qmatch.push message_received'));
    expect(
      logs.where((line) => line.contains('should-not-be-logged')),
      isEmpty,
    );
    expect(logs.where((line) => line.contains('userA_userB')), isEmpty);
  });

  test('trigger is europe-west1 onDocumentCreated and does not store text', () {
    final index = read('functions/index.js');
    final start =
        index.indexOf('exports.sendNewMessagePush = onDocumentCreated(');
    expect(start, greaterThan(0));
    final block = index.substring(start);
    expect(
      block.contains("document: 'threads/{threadId}/messages/{messageId}'"),
      isTrue,
    );
    expect(block.contains("region: 'europe-west1'"), isTrue);
    expect(block.contains('minInstances'), isFalse);

    final src = read('functions/src/new_message_push.js');
    expect(src.contains("type: PUSH_TYPE"), isTrue);
    expect(src.contains("thread_id: String(threadId)"), isTrue);
    expect(src.contains("other_uid: String(senderId)"), isTrue);
    expect(src.contains("message_id: String(messageId)"), isTrue);
    expect(src.contains('chat_message_id'), isTrue);
    expect(src.contains('...routing'), isTrue);
    expect(src.contains("data.text"), isFalse);
    expect(src.contains("unread_counts."), isFalse);
    expect(src.contains('FieldValue.increment'), isFalse);
    expect(src.contains('likeAndMaybeCreateMatch'), isFalse);
    expect(src.contains('sendSuperResonance'), isFalse);
    expect(src.contains('system_match_v1'), isTrue);
  });

  test('client does not add tap routing or local notifications', () {
    final adapter = read(
      'lib/core/notifications/firebase_push_messaging_adapter.dart',
    );
    final serviceSrc = read(
      'lib/core/notifications/notification_registration_service.dart',
    );
    final chat = read('lib/features/messages/services/chat_service.dart');
    expect(adapter.contains('setForegroundNotificationPresentationOptions'),
        isFalse);
    expect(adapter.contains('onMessageOpenedApp'), isTrue);
    expect(adapter.contains('getInitialMessage'), isTrue);
    expect(serviceSrc.contains('flutter_local_notifications'), isFalse);
    expect(serviceSrc.contains('qmatch.push message_received'), isTrue);
    expect(chat.contains('registerFcmToken'), isFalse);
    expect(chat.contains("type': 'text'"), isTrue);
  });
}
