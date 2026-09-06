import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../l10n/app_localizations.dart';

enum AppleSignInOutcome { success, cancelled, failed, collision }

/// Result of an Apple → Firebase nonce credential attempt.
///
/// Cancellation is a normal no-op. `account-exists-with-different-credential`
/// is a [collision]: pending credential is captured in memory (when Firebase
/// supplies it) and the existing account must authenticate before linking.
/// This flow never merges Firebase UIDs.
class AppleSignInAttempt {
  const AppleSignInAttempt._({
    required this.outcome,
    this.userCredential,
    this.error,
  });

  factory AppleSignInAttempt.success([UserCredential? userCredential]) {
    return AppleSignInAttempt._(
      outcome: AppleSignInOutcome.success,
      userCredential: userCredential,
    );
  }

  factory AppleSignInAttempt.cancelled() {
    return const AppleSignInAttempt._(outcome: AppleSignInOutcome.cancelled);
  }

  factory AppleSignInAttempt.failed(FirebaseAuthException error) {
    return AppleSignInAttempt._(
      outcome: AppleSignInOutcome.failed,
      error: error,
    );
  }

  factory AppleSignInAttempt.collision(FirebaseAuthException error) {
    return AppleSignInAttempt._(
      outcome: AppleSignInOutcome.collision,
      error: error,
    );
  }

  final AppleSignInOutcome outcome;
  final UserCredential? userCredential;
  final FirebaseAuthException? error;

  bool get isSuccess => outcome == AppleSignInOutcome.success;
  bool get isCancelled => outcome == AppleSignInOutcome.cancelled;
  bool get isFailed => outcome == AppleSignInOutcome.failed;
  bool get isCollision => outcome == AppleSignInOutcome.collision;
}

class AppleAuthorizationResult {
  const AppleAuthorizationResult({
    required this.identityToken,
    this.authorizationCode,
    this.email,
    this.givenName,
    this.familyName,
  });

  final String identityToken;

  /// Fresh Apple authorization code. In-memory only. Never persist or log.
  final String? authorizationCode;
  final String? email;
  final String? givenName;
  final String? familyName;
}

class AppleSignInFlow {
  AppleSignInFlow._();

  static const int nonceLength = 32;
  static const String nonceCharset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

  /// Native Sign in with Apple only. Android web OAuth is out of scope.
  static bool get isNativeApplePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static String generateRawNonce([int length = nonceLength]) {
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => nonceCharset[random.nextInt(nonceCharset.length)],
    ).join();
  }

  static String sha256Of(String rawNonce) {
    return sha256.convert(utf8.encode(rawNonce)).toString();
  }

  static String displayName({String? givenName, String? familyName}) {
    return [givenName, familyName]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  static bool isPrivateRelayEmail(String? email) {
    final value = email?.trim().toLowerCase() ?? '';
    return value.endsWith('@privaterelay.appleid.com');
  }

  static FirebaseAuthException mapAppleException(
    SignInWithAppleAuthorizationException error,
  ) {
    switch (error.code) {
      case AuthorizationErrorCode.canceled:
        return FirebaseAuthException(code: 'cancelled');
      case AuthorizationErrorCode.failed:
        return FirebaseAuthException(code: 'apple-failed');
      case AuthorizationErrorCode.invalidResponse:
        return FirebaseAuthException(code: 'apple-invalid-response');
      case AuthorizationErrorCode.notHandled:
        return FirebaseAuthException(code: 'apple-not-handled');
      case AuthorizationErrorCode.unknown:
      case AuthorizationErrorCode.notInteractive:
      case AuthorizationErrorCode.credentialExport:
      case AuthorizationErrorCode.credentialImport:
      case AuthorizationErrorCode.matchedExcludedCredential:
        return FirebaseAuthException(code: 'apple-unknown');
    }
  }

  static String mapAuthError(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'network-request-failed':
        return l10n.appleSignInErrorNetwork;
      case 'too-many-requests':
        return l10n.appleSignInErrorTooManyRequests;
      case 'user-disabled':
        return l10n.appleSignInErrorUserDisabled;
      case 'operation-not-allowed':
        return l10n.appleSignInErrorNotAllowed;
      case 'invalid-credential':
        return l10n.appleSignInErrorInvalidCredential;
      case 'account-exists-with-different-credential':
        return l10n.appleSignInErrorAccountExistsDifferent;
      case 'credential-already-in-use':
        return l10n.appleSignInErrorCredentialInUse;
      case 'apple-failed':
        return l10n.appleSignInErrorAppleFailed;
      case 'apple-invalid-response':
        return l10n.appleSignInErrorInvalidResponse;
      case 'apple-not-handled':
        return l10n.appleSignInErrorNotHandled;
      case 'apple-unknown':
        return l10n.appleSignInErrorUnknown;
      default:
        return l10n.appleSignInErrorFailed;
    }
  }
}
