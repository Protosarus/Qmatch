import 'package:firebase_auth/firebase_auth.dart';

import 'auth_provider_resolver.dart';

/// Process-memory hint for the current Firebase sign-in provider.
///
/// Never persisted. Cleared on logout. Token claims remain authority.
class SignInProviderMemory {
  SignInProviderMemory._();

  static String? current;

  static void remember(String? providerId) {
    final value = providerId?.trim() ?? '';
    current = value.isEmpty ? null : value;
  }

  static void clear() {
    current = null;
  }
}

/// Provider-aware email-verification gate.
///
/// Only an unverified **current password** sign-in is gated. Linked Google /
/// Apple / phone sessions are never blocked merely because `providerData`
/// also contains `password`.
class EmailVerificationPolicy {
  EmailVerificationPolicy._();

  static const Duration resendCooldown = Duration(seconds: 45);

  static Set<String> normalizeProviderIds(Iterable<String> providerIds) {
    return providerIds
        .map((id) => id.trim())
        .where((id) =>
            id.isNotEmpty && id != AuthProviderResolver.firebaseProviderId)
        .toSet();
  }

  /// True only for an unverified password session.
  ///
  /// [currentSignInProvider] is the Firebase token `sign_in_provider` (or a
  /// same-process memory hint). It is the identity authority for this gate.
  static bool requiresEmailVerification({
    required Iterable<String> providerIds,
    required bool emailVerified,
    String? currentSignInProvider,
  }) {
    final current = currentSignInProvider?.trim() ?? '';
    if (current == AuthProviderResolver.googleProviderId ||
        current == AuthProviderResolver.appleProviderId ||
        current == AuthProviderResolver.phoneProviderId) {
      return false;
    }
    if (current == AuthProviderResolver.passwordProviderId) {
      return !emailVerified;
    }

    final ids = normalizeProviderIds(providerIds);
    final hasPassword = ids.contains(AuthProviderResolver.passwordProviderId);
    final hasOauthOrPhone =
        ids.contains(AuthProviderResolver.googleProviderId) ||
            ids.contains(AuthProviderResolver.appleProviderId) ||
            ids.contains(AuthProviderResolver.phoneProviderId);
    if (hasPassword && !hasOauthOrPhone) {
      return !emailVerified;
    }
    return false;
  }

  /// Sync decision when the current provider is known, or the account is
  /// unambiguously password-only / non-password. Mixed linked accounts
  /// without a current provider return null so the caller can read the token.
  static bool? tryResolveSync({
    required Iterable<String> providerIds,
    required bool emailVerified,
    String? currentSignInProvider,
  }) {
    final current = currentSignInProvider?.trim() ?? '';
    if (current.isNotEmpty) {
      return requiresEmailVerification(
        providerIds: providerIds,
        emailVerified: emailVerified,
        currentSignInProvider: current,
      );
    }
    final ids = normalizeProviderIds(providerIds);
    final hasPassword = ids.contains(AuthProviderResolver.passwordProviderId);
    final hasOauthOrPhone =
        ids.contains(AuthProviderResolver.googleProviderId) ||
            ids.contains(AuthProviderResolver.appleProviderId) ||
            ids.contains(AuthProviderResolver.phoneProviderId);
    if (hasPassword && !hasOauthOrPhone) {
      return !emailVerified;
    }
    if (!hasPassword) {
      return false;
    }
    return null;
  }

  static bool requiresEmailVerificationForUser(
    User user, {
    String? currentSignInProvider,
  }) {
    return requiresEmailVerification(
      providerIds: user.providerData.map((info) => info.providerId),
      emailVerified: user.emailVerified,
      currentSignInProvider:
          currentSignInProvider ?? SignInProviderMemory.current,
    );
  }

  static Future<String?> readTokenSignInProvider(User user) async {
    try {
      final result = await user.getIdTokenResult();
      final provider = result.signInProvider?.trim() ?? '';
      if (provider.isNotEmpty) {
        SignInProviderMemory.remember(provider);
        return provider;
      }
    } catch (_) {}
    return SignInProviderMemory.current;
  }
}
