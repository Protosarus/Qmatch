import 'package:firebase_messaging/firebase_messaging.dart';

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
      FirebaseMessaging.onMessage.map(_dataOf);

  @override
  Stream<Map<String, String>> get onNotificationOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(_dataOf);

  @override
  Future<Map<String, String>?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return _dataOf(message);
  }

  Map<String, String> _dataOf(RemoteMessage message) {
    final data = <String, String>{};
    message.data.forEach((key, value) {
      data[key] = value.toString();
    });
    return data;
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
