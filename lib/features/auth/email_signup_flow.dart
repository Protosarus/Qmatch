import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Client validation + AuthService wiring for email registration.
///
/// Email verification is enforced by the root AuthWrapper, not here.
class EmailSignupFlow {
  EmailSignupFlow._();

  static const int minPasswordLength = 6;

  static bool isPlausibleEmail(String value) {
    final email = value.trim();
    final at = email.indexOf('@');
    if (at <= 0 || at != email.lastIndexOf('@')) return false;
    final domain = email.substring(at + 1);
    final dot = domain.lastIndexOf('.');
    return dot > 0 && dot < domain.length - 1;
  }

  static String? validateEmail(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.loginErrorEnterEmail;
    if (!isPlausibleEmail(email)) return l10n.loginErrorValidEmail;
    return null;
  }

  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.loginErrorEnterPassword;
    if (value.length < minPasswordLength) {
      return l10n.loginErrorPasswordMinLength;
    }
    return null;
  }

  static String? validateConfirmation(
    String? value,
    String password,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.emailSignupErrorConfirmPassword;
    }
    if (value != password) return l10n.emailSignupErrorPasswordMismatch;
    return null;
  }

  static String mapAuthError(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        // Existing Google/Apple (or password) account. Guidance only —
        // never capture the raw password for later linking.
        return l10n.emailSignupErrorEmailInUse;
      case 'invalid-email':
        return l10n.loginErrorValidEmailAddress;
      case 'weak-password':
        return l10n.emailSignupErrorWeakPassword;
      case 'operation-not-allowed':
        return l10n.emailSignupErrorOperationNotAllowed;
      case 'network-request-failed':
        return l10n.resetPasswordNetworkError;
      case 'too-many-requests':
        return l10n.resetPasswordTooManyRequests;
      default:
        return l10n.emailSignupErrorFailed;
    }
  }

  /// Creates the Firebase user, then ensures the Firestore document once.
  ///
  /// [AuthService.signUpWithEmail] does not write Firestore. Do not call
  /// [AuthService.createUserInFirestore] a second time from the UI.
  static Future<void> register({
    required AuthService authService,
    required String email,
    required String password,
  }) async {
    final credential = await authService.signUpWithEmail(
      email: email,
      password: password,
      name: '',
    );
    final user = credential.user;
    if (user == null) return;
    await authService.createUserInFirestore(
      uid: user.uid,
      name: '',
      email: email,
    );
  }
}
