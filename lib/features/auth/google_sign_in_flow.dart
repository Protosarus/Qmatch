import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/app_localizations.dart';

enum GoogleSignInOutcome { success, cancelled, failed, collision }

/// Result of a Google → Firebase credential attempt.
///
/// Cancellation is a normal no-op. `account-exists-with-different-credential`
/// is a [collision]: pending credential is captured in memory (when Firebase
/// supplies it) and the existing account must authenticate before linking.
/// This flow never merges Firebase UIDs.
class GoogleSignInAttempt {
  const GoogleSignInAttempt._({
    required this.outcome,
    this.userCredential,
    this.error,
  });

  factory GoogleSignInAttempt.success([UserCredential? userCredential]) {
    return GoogleSignInAttempt._(
      outcome: GoogleSignInOutcome.success,
      userCredential: userCredential,
    );
  }

  factory GoogleSignInAttempt.cancelled() {
    return const GoogleSignInAttempt._(outcome: GoogleSignInOutcome.cancelled);
  }

  factory GoogleSignInAttempt.failed(FirebaseAuthException error) {
    return GoogleSignInAttempt._(
      outcome: GoogleSignInOutcome.failed,
      error: error,
    );
  }

  factory GoogleSignInAttempt.collision(FirebaseAuthException error) {
    return GoogleSignInAttempt._(
      outcome: GoogleSignInOutcome.collision,
      error: error,
    );
  }

  final GoogleSignInOutcome outcome;
  final UserCredential? userCredential;
  final FirebaseAuthException? error;

  bool get isSuccess => outcome == GoogleSignInOutcome.success;
  bool get isCancelled => outcome == GoogleSignInOutcome.cancelled;
  bool get isFailed => outcome == GoogleSignInOutcome.failed;
  bool get isCollision => outcome == GoogleSignInOutcome.collision;
}

class GoogleSignInFlow {
  GoogleSignInFlow._();

  /// Web OAuth client from the existing Android `google-services.json`
  /// (`oauth_client` / `client_type` 3). Required for Android ID tokens.
  /// Do not invent a different client ID.
  static const String webClientId =
      '55490039374-q70ifo47t03rgem5t7631otno0pr5jd5.apps.googleusercontent.com';

  static GoogleSignIn createClient() {
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: webClientId,
    );
  }

  static String mapAuthError(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'network-request-failed':
        return l10n.googleSignInErrorNetwork;
      case 'too-many-requests':
        return l10n.googleSignInErrorTooManyRequests;
      case 'user-disabled':
        return l10n.googleSignInErrorUserDisabled;
      case 'operation-not-allowed':
        return l10n.googleSignInErrorNotAllowed;
      case 'invalid-credential':
      case 'invalid-verification-id':
      case 'invalid-verification-code':
        return l10n.googleSignInErrorInvalidCredential;
      case 'account-exists-with-different-credential':
        return l10n.googleSignInErrorAccountExistsDifferent;
      case 'credential-already-in-use':
        return l10n.googleSignInErrorCredentialInUse;
      default:
        return l10n.googleSignInErrorFailed;
    }
  }
}
