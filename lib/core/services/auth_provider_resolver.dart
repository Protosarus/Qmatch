import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth provider IDs to the existing `users.auth_provider` field.
///
/// `users.auth_provider` is a **bootstrap / last-known label only**. It is
/// never the security authority. After provider linking, a user may have
/// several Firebase `providerData` IDs; identity stays
/// `request.auth.uid` + ID-token `sign_in_provider` / `email_verified`.
///
/// Linking must not overwrite a populated `auth_provider`. [resolve] still
/// prefers password→email when several IDs are present so a *new* document
/// keeps a stable original label. That preference is not a provider graph.
class AuthProviderResolver {
  AuthProviderResolver._();

  static const String phone = 'phone';
  static const String email = 'email';
  static const String google = 'google';
  static const String apple = 'apple';

  static const String firebaseProviderId = 'firebase';
  static const String passwordProviderId = 'password';
  static const String phoneProviderId = 'phone';
  static const String googleProviderId = 'google.com';
  static const String appleProviderId = 'apple.com';

  static String resolve({
    required Iterable<String> providerIds,
    String? phoneNumber,
  }) {
    final ids = providerIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id != firebaseProviderId)
        .toSet();

    if (ids.contains(passwordProviderId)) return email;
    if (ids.contains(googleProviderId)) return google;
    if (ids.contains(appleProviderId)) return apple;
    if (ids.contains(phoneProviderId)) return phone;

    final trimmedPhone = phoneNumber?.trim() ?? '';
    if (trimmedPhone.isNotEmpty) return phone;
    return email;
  }

  static String resolveFromUser(User user) {
    return resolve(
      providerIds: user.providerData.map((info) => info.providerId),
      phoneNumber: user.phoneNumber,
    );
  }

  /// Linked Apple is read from Firebase providerData, not the current session.
  static bool hasAppleLinked(User user) {
    return user.providerData.any(
      (info) => info.providerId == appleProviderId,
    );
  }

  static bool hasPasswordLinked(User user) {
    return user.providerData.any(
      (info) => info.providerId == passwordProviderId,
    );
  }

  static bool hasGoogleLinked(User user) {
    return user.providerData.any(
      (info) => info.providerId == googleProviderId,
    );
  }

  static bool hasPhoneLinked(User user) {
    return user.providerData.any(
      (info) => info.providerId == phoneProviderId,
    );
  }
}
