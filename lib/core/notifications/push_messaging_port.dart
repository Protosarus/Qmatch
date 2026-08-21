import 'push_permission_state.dart';

/// Messaging operations used by [NotificationRegistrationService].
abstract class PushMessagingPort {
  Future<PushPermissionState> currentPermission();

  Future<PushPermissionState> requestPermission();

  Future<String?> getAPNSToken();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  /// Foreground FCM envelopes. iOS does not show an OS banner for these.
  Stream<Map<String, String>> get onForegroundMessage;

  /// Background notification taps while the app is alive.
  Stream<Map<String, String>> get onNotificationOpened;

  /// Terminated-launch notification, if the app was opened from a tap.
  Future<Map<String, String>?> getInitialMessage();
}
