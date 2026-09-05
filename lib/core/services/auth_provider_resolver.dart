import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth provider IDs to the existing `users.auth_provider` field.
///
/// Does not link accounts or store a provider graph. When several IDs are
/// present, the first match in [resolve] wins so a future Google/Apple user
/// is never stamped as `email` merely because they have an email address.
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
}
