import 'push_permission_state.dart';

/// Messaging operations used by [NotificationRegistrationService].
abstract class PushMessagingPort {
  Future<PushPermissionState> currentPermission();

  Future<PushPermissionState> requestPermission();

  Future<String?> getAPNSToken();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;
}
