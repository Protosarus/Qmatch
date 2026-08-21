import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_messaging_port.dart';
import 'push_permission_state.dart';

/// firebase_messaging adapter. Does not send or route notifications.
class FirebasePushMessagingAdapter implements PushMessagingPort {
  FirebasePushMessagingAdapter({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<PushPermissionState> currentPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return _map(settings.authorizationStatus);
  }

  @override
  Future<PushPermissionState> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return _map(settings.authorizationStatus);
  }

  @override
  Future<String?> getAPNSToken() => _messaging.getAPNSToken();

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, String>> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map((message) {
        _logRawRemote('onMessage', message);
        final mapped = _dataOf(message);
        _logMapped('onMessage', mapped);
        return mapped;
      });

  @override
  Stream<Map<String, String>> get onNotificationOpened =>
      FirebaseMessaging.onMessageOpenedApp.map((message) {
        _logRawRemote('onMessageOpenedApp', message);
        final mapped = _dataOf(message);
        _logMapped('onMessageOpenedApp', mapped);
        return mapped;
      });

  @override
  Future<Map<String, String>?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    _logRawRemote('getInitialMessage', message);
    final mapped = _dataOf(message);
    _logMapped('getInitialMessage', mapped);
    return mapped;
  }

  Map<String, String> _dataOf(RemoteMessage message) {
    final data = <String, String>{};
    message.data.forEach((key, value) {
      data[key] = value.toString();
    });
    return data;
  }

  /// TEMP: keys + presence only. No ids, text, or tokens.
  void _logRawRemote(String source, RemoteMessage message) {
    if (kReleaseMode) return;
    final keys = message.data.keys.toList()..sort();
    final d = message.data;
    debugPrint(
      'qmatch.push raw_remote'
      ' source=$source'
      ' data_keys=${keys.isEmpty ? '-' : keys.join(',')}'
      ' has_type=${_has(d, 'type')}'
      ' has_thread_id=${_has(d, 'thread_id')}'
      ' has_other_uid=${_has(d, 'other_uid')}'
      ' has_message_id=${_has(d, 'message_id')}'
      ' has_chat_message_id=${_has(d, 'chat_message_id')}'
      ' notificationPresent=${message.notification != null}',
    );
  }

  /// TEMP: adapter output after Map conversion.
  void _logMapped(String source, Map<String, String> data) {
    if (kReleaseMode) return;
    final keys = data.keys.toList()..sort();
    debugPrint(
      'qmatch.push adapter_out'
      ' source=$source'
      ' keys=${keys.isEmpty ? '-' : keys.join(',')}'
      ' has_type=${_has(data, 'type')}'
      ' has_thread_id=${_has(data, 'thread_id')}'
      ' has_other_uid=${_has(data, 'other_uid')}'
      ' has_message_id=${_has(data, 'message_id')}'
      ' has_chat_message_id=${_has(data, 'chat_message_id')}',
    );
  }

  bool _has(Map data, String key) {
    final value = data[key];
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  PushPermissionState _map(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return PushPermissionState.authorized;
      case AuthorizationStatus.provisional:
        return PushPermissionState.provisional;
      case AuthorizationStatus.denied:
        return PushPermissionState.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermissionState.notDetermined;
    }
  }
}
