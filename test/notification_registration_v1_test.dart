import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/core/notifications/fcm_token_id.dart';
import 'package:qmatch/core/notifications/notification_registration_host.dart';
import 'package:qmatch/core/notifications/notification_registration_service.dart';
import 'package:qmatch/core/notifications/push_messaging_port.dart';
import 'package:qmatch/core/notifications/push_permission_state.dart';
import 'package:qmatch/core/services/auth_service.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';

class _FakeMessaging implements PushMessagingPort {
  _FakeMessaging({
    this.current = PushPermissionState.notDetermined,
    this.afterRequest = PushPermissionState.authorized,
    this.apnsToken = 'apns-secret-token',
    this.fcmToken = 'tok-1',
  });

  PushPermissionState current;
  PushPermissionState afterRequest;
  String? apnsToken;
  String? fcmToken;
  int requestCount = 0;
  int getTokenCount = 0;
  int apnsCount = 0;
  final StreamController<String> refresh = StreamController<String>.broadcast();

  @override
  Future<PushPermissionState> currentPermission() async => current;

  @override
  Future<PushPermissionState> requestPermission() async {
    requestCount += 1;
    current = afterRequest;
    return current;
  }

  @override
  Future<String?> getAPNSToken() async {
    apnsCount += 1;
    return apnsToken;
  }

  @override
  Future<String?> getToken() async {
    getTokenCount += 1;
    return fcmToken;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
}

class _CallableSpy {
  final calls = <Map<String, dynamic>>[];

  Future<void> call(String name, Map<String, dynamic> data) async {
    calls.add({'name': name, 'data': Map<String, dynamic>.from(data)});
  }

  List<Map<String, dynamic>> named(String name) =>
      calls.where((c) => c['name'] == name).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String read(String path) => File(path).readAsStringSync();

  _FakeMessaging? messaging;
  late _CallableSpy spy;
  late List<String> logs;
  late NotificationRegistrationService service;

  NotificationRegistrationService buildService({
    _FakeMessaging? port,
    bool isIOS = true,
    Future<void> Function(String name, Map<String, dynamic> data)? call,
  }) {
    messaging = port ?? _FakeMessaging();
    spy = _CallableSpy();
    logs = <String>[];
    service = NotificationRegistrationService(
      messaging: messaging,
      call: call ?? spy.call,
      currentUid: () => 'userA',
      appId: () => '1:55490039374:ios:523d1a173f0ba32ac7fd1f',
      isIOS: isIOS,
      apnsEnv: isIOS ? 'sandbox' : null,
      log: logs.add,
      delay: (_) async {},
    );
    return service;
  }

  tearDown(() async {
    await messaging?.refresh.close();
    messaging = null;
  });

  test('SHA-256 token id matches backend golden', () {
    expect(
      fcmTokenDocId('tok-1'),
      '65dcf16ea3dfa49069628089eb4a75483070f5584b2a21ee64912b5f621f12da',
    );
  });

  test('authorized registers once and does not re-prompt', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
    );
    await service.startAfterAuthenticatedAppReady();
    await service.startAfterAuthenticatedAppReady();
    expect(messaging!.requestCount, 0);
    expect(spy.named('registerFcmToken'), hasLength(1));
    final payload =
        spy.named('registerFcmToken').single['data'] as Map<String, dynamic>;
    expect(payload['token'], 'tok-1');
    expect(payload['platform'], 'ios');
    expect(payload['app_id'], '1:55490039374:ios:523d1a173f0ba32ac7fd1f');
    expect(payload['apns_env'], 'sandbox');
    expect(payload.containsKey('uid'), isFalse);
    expect(logs, contains('qmatch.push permission=authorized'));
    expect(logs, contains('qmatch.push token_registered'));
  });

  test('provisional registers without a second prompt', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.provisional),
    );
    await service.startAfterAuthenticatedAppReady();
    expect(messaging!.requestCount, 0);
    expect(spy.named('registerFcmToken'), hasLength(1));
    expect(logs, contains('qmatch.push permission=provisional'));
  });

  test('denied does not request again or register a token', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.denied),
    );
    await service.startAfterAuthenticatedAppReady();
    await service.startAfterAuthenticatedAppReady();
    expect(messaging!.requestCount, 0);
    expect(messaging!.getTokenCount, 0);
    expect(spy.calls, isEmpty);
    expect(logs, contains('qmatch.push permission=denied'));
  });

  test('notDetermined then denied does not register', () async {
    buildService(
      port: _FakeMessaging(
        current: PushPermissionState.notDetermined,
        afterRequest: PushPermissionState.denied,
      ),
    );
    await service.startAfterAuthenticatedAppReady();
    expect(messaging!.requestCount, 1);
    expect(spy.named('registerFcmToken'), isEmpty);
  });

  test('token refresh re-registers the new token', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
    );
    await service.startAfterAuthenticatedAppReady();
    messaging!.refresh.add('tok-2');
    await Future<void>.delayed(Duration.zero);
    expect(spy.named('registerFcmToken'), hasLength(2));
    expect(
      (spy.named('registerFcmToken').last['data']
          as Map<String, dynamic>)['token'],
      'tok-2',
    );
    expect(logs, contains('qmatch.push token_refreshed'));
  });

  test('logout unregisters only the current device token', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
    );
    await service.startAfterAuthenticatedAppReady();
    await service.unregisterForLogout();
    expect(spy.named('unregisterFcmToken'), hasLength(1));
    expect(
      (spy.named('unregisterFcmToken').single['data']
          as Map<String, dynamic>)['token'],
      'tok-1',
    );
    expect(service.debugCurrentToken, isNull);
    expect(logs, contains('qmatch.push token_unregistered'));
  });

  test('unregister failure does not throw from the service', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
      call: (name, data) async {
        await spy.call(name, data);
        if (name == 'unregisterFcmToken') {
          throw Exception('network');
        }
      },
    );
    await service.startAfterAuthenticatedAppReady();
    await expectLater(service.unregisterForLogout(), completes);
  });

  test('unregister failure does not block logout', () async {
    final order = <String>[];
    await unregisterPushTokenThenSignOut(
      unregister: () async {
        order.add('unregister');
        throw Exception('network');
      },
      signOut: () async => order.add('signOut'),
    );
    expect(order, ['unregister', 'signOut']);
  });

  test('logs never include raw FCM or APNs tokens', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
    );
    await service.startAfterAuthenticatedAppReady();
    messaging!.refresh.add('tok-2');
    await Future<void>.delayed(Duration.zero);
    await service.unregisterForLogout();
    const allowed = {
      'qmatch.push permission=authorized',
      'qmatch.push token_registered',
      'qmatch.push token_refreshed',
      'qmatch.push token_unregistered',
    };
    expect(logs.toSet(), allowed);
    for (final line in logs) {
      expect(line.contains('tok-1'), isFalse);
      expect(line.contains('tok-2'), isFalse);
      expect(line.contains('apns-secret-token'), isFalse);
    }
  });

  test('android payload omits apns_env', () async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
      isIOS: false,
    );
    await service.startAfterAuthenticatedAppReady();
    expect(messaging!.apnsCount, 0);
    final payload =
        spy.named('registerFcmToken').single['data'] as Map<String, dynamic>;
    expect(payload['platform'], 'android');
    expect(payload.containsKey('apns_env'), isFalse);
  });

  testWidgets('host starts registration once after the first frame',
      (tester) async {
    buildService(
      port: _FakeMessaging(current: PushPermissionState.authorized),
    );
    await tester.pumpWidget(
      NotificationRegistrationHost(
        service: service,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    expect(spy.named('registerFcmToken'), hasLength(1));
    await tester.pump();
    expect(spy.named('registerFcmToken'), hasLength(1));
  });

  test('callables are europe-west1 and auth-only in source', () {
    final index = read('functions/index.js');
    final registerAt = index.indexOf('exports.registerFcmToken = onCall(');
    final unregisterAt = index.indexOf('exports.unregisterFcmToken = onCall(');
    expect(registerAt, greaterThan(0));
    expect(unregisterAt, greaterThan(registerAt));
    final registerBlock = index.substring(registerAt, unregisterAt);
    final unregisterBlock = index.substring(unregisterAt);
    expect(registerBlock.contains("region: 'europe-west1'"), isTrue);
    expect(registerBlock.contains('minInstances'), isFalse);
    expect(unregisterBlock.contains("region: 'europe-west1'"), isTrue);

    final callable = read('functions/src/fcm_token_callable.js');
    expect(callable.contains('request.auth && request.auth.uid'), isTrue);
    expect(callable.contains('data.uid'), isFalse);
    expect(callable.contains('tokenHash(token)'), isTrue);
    expect(callable.contains(r'users/${uid}/fcm_tokens/'), isTrue);
  });

  test('rules deny client fcm_tokens access', () {
    final rules = read('firestore.rules');
    expect(rules.contains('match /fcm_tokens/{tokenId}'), isTrue);
    expect(rules.contains('allow read, write: if false;'), isTrue);
  });

  test('client lib never writes fcm_tokens to Firestore', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final src = file.readAsStringSync();
      expect(
        src.contains("collection('fcm_tokens')"),
        isFalse,
        reason: file.path,
      );
    }
    final serviceSrc = read(
      'lib/core/notifications/notification_registration_service.dart',
    );
    expect(serviceSrc.contains('cloud_firestore'), isFalse);
    expect(serviceSrc.contains('FirebaseMessaging.onMessage'), isFalse);
    expect(serviceSrc.contains('flutter_local_notifications'), isFalse);
  });

  test('permission is requested from the authenticated main shell', () {
    final dest = read(
      'lib/core/navigation/assessment_progress_route_gate.dart',
    );
    expect(dest.contains('NotificationRegistrationHost('), isTrue);
    expect(
      dest.contains('child: MainNavigationScreen()'),
      isTrue,
    );
    final wrapper = read('lib/core/navigation/auth_wrapper.dart');
    expect(wrapper.contains('WelcomeScreen()'), isTrue);
    expect(wrapper.contains('NotificationRegistrationHost'), isFalse);
    expect(
      wrapper.contains('AuthAssessmentLoadingScaffold()'),
      isTrue,
    );
    final auth = read('lib/core/services/auth_service.dart');
    expect(
      auth.indexOf('unregisterForLogout') < auth.indexOf('_auth.signOut()'),
      isTrue,
    );
  });

  test('main destination still builds the host around navigation', () {
    const decision = AssessmentColdStartDecision(
      destination: AssessmentFlowDestination.main,
      openAssessmentTestScreen: false,
      reason: 'test',
    );
    final widget = buildAssessmentDestination(decision);
    expect(widget, isA<NotificationRegistrationHost>());
  });
}
