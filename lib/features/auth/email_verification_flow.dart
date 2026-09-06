import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';
import '../../core/services/email_verification_policy.dart';

/// Maps Firebase Auth verification errors to localized copy.
class EmailVerificationFlow {
  EmailVerificationFlow._();

  static Duration get resendCooldown => EmailVerificationPolicy.resendCooldown;

  /// Force-refresh the ID token so Firestore / callables see email_verified.
  static Future<String?> forceRefreshIdToken(User user) {
    return user.getIdToken(true);
  }

  static String mapAuthError(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'too-many-requests':
        return l10n.emailVerificationTooManyRequests;
      case 'network-request-failed':
        return l10n.emailVerificationNetworkError;
      case 'user-disabled':
        return l10n.emailVerificationUserDisabled;
      case 'requires-recent-login':
        return l10n.emailVerificationRequiresRecentLogin;
      default:
        return l10n.emailVerificationFailed;
    }
  }
}
