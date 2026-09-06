import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_provider_resolver.dart';

/// In-memory pending OAuth credential waiting to be linked to an existing UID.
///
/// NEVER persisted to Firestore, SharedPreferences, or secure storage.
/// NEVER logged or sent to analytics. Process death clears it.
class PendingProviderLink {
  const PendingProviderLink({
    required this.attemptedProvider,
    required this.credential,
    this.emailHint,
    required this.createdAt,
  });

  /// Firebase provider ID (`google.com` / `apple.com`).
  final String attemptedProvider;

  /// Held only in RAM. Do not serialize.
  final AuthCredential credential;

  /// Safe email hint supplied by Firebase. Never a token.
  final String? emailHint;

  final DateTime createdAt;
}

/// Process-wide pending-link coordinator. Memory only.
class PendingProviderLinkStore {
  PendingProviderLinkStore._();

  static PendingProviderLink? _pending;

  static PendingProviderLink? get current => _pending;

  static bool get hasPending => _pending != null;

  static void capture({
    required String attemptedProvider,
    required AuthCredential credential,
    String? emailHint,
    DateTime? now,
  }) {
    _pending = PendingProviderLink(
      attemptedProvider: attemptedProvider,
      credential: credential,
      emailHint: safeEmailHint(emailHint),
      createdAt: now ?? DateTime.now(),
    );
  }

  /// Captures from `account-exists-with-different-credential` when Firebase
  /// attached a usable credential. Returns whether pending state was stored.
  static bool captureFromCollision(
    FirebaseAuthException error, {
    required String attemptedProvider,
  }) {
    if (error.code != 'account-exists-with-different-credential') {
      return false;
    }
    final credential = error.credential;
    if (credential == null) return false;
    capture(
      attemptedProvider: attemptedProvider,
      credential: credential,
      emailHint: error.email,
    );
    return true;
  }

  static String? safeEmailHint(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty || !value.contains('@')) return null;
    return value;
  }

  static void clear() {
    _pending = null;
  }

  static bool isSupportedAttemptedProvider(String providerId) {
    return providerId == AuthProviderResolver.googleProviderId ||
        providerId == AuthProviderResolver.appleProviderId;
  }

  @visibleForTesting
  static void debugReset() {
    _pending = null;
  }
}
