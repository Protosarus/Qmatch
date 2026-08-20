/// System notification permission for FCM registration.
enum PushPermissionState {
  authorized,
  provisional,
  denied,
  notDetermined,
}

extension PushPermissionStateX on PushPermissionState {
  bool get allowsTokenRegistration =>
      this == PushPermissionState.authorized ||
      this == PushPermissionState.provisional;
}
