import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/auth_provider_resolver.dart';
import '../../l10n/app_localizations.dart';

enum ProviderLinkOutcome {
  idle,
  linked,
  alreadyLinked,
  deferred,
  failed,
}

/// Result of linking a pending OAuth credential to the current Firebase user.
///
/// Never merges two Firebase UIDs. Never copies Firestore data.
class ProviderLinkAttempt {
  const ProviderLinkAttempt._({
    required this.outcome,
    this.uid,
    this.error,
  });

  const ProviderLinkAttempt.idle() : this._(outcome: ProviderLinkOutcome.idle);

  const ProviderLinkAttempt.deferred()
      : this._(outcome: ProviderLinkOutcome.deferred);

  factory ProviderLinkAttempt.linked(String uid) {
    return ProviderLinkAttempt._(
      outcome: ProviderLinkOutcome.linked,
      uid: uid,
    );
  }

  factory ProviderLinkAttempt.alreadyLinked(String uid) {
    return ProviderLinkAttempt._(
      outcome: ProviderLinkOutcome.alreadyLinked,
      uid: uid,
    );
  }

  factory ProviderLinkAttempt.failed(FirebaseAuthException error) {
    return ProviderLinkAttempt._(
      outcome: ProviderLinkOutcome.failed,
      error: error,
    );
  }

  final ProviderLinkOutcome outcome;
  final String? uid;
  final FirebaseAuthException? error;

  bool get isIdle => outcome == ProviderLinkOutcome.idle;
  bool get isLinked => outcome == ProviderLinkOutcome.linked;
  bool get isAlreadyLinked => outcome == ProviderLinkOutcome.alreadyLinked;
  bool get isDeferred => outcome == ProviderLinkOutcome.deferred;
  bool get isFailed => outcome == ProviderLinkOutcome.failed;
  bool get isSuccess => isLinked || isAlreadyLinked;
}

class ProviderLinkFlow {
  ProviderLinkFlow._();

  static const Set<String> unrecoverableCodes = {
    'invalid-credential',
    'credential-already-in-use',
    'email-already-in-use',
    'user-disabled',
    'operation-not-allowed',
    'provider-already-linked',
  };

  /// Unverified password sessions must not link. That would bypass Phase 3.
  static bool shouldDeferUnverifiedPassword({
    required String? currentSignInProvider,
    required bool emailVerified,
  }) {
    return currentSignInProvider == AuthProviderResolver.passwordProviderId &&
        !emailVerified;
  }

  static bool isUnrecoverableLinkError(String code) {
    return unrecoverableCodes.contains(code);
  }

  /// Link [credential] to [existingUid]. Fails closed if the UID changes.
  static Future<ProviderLinkAttempt> linkToExistingUid({
    required String existingUid,
    required AuthCredential credential,
    required Future<String> Function(AuthCredential credential)
        linkAndReturnUid,
  }) async {
    try {
      final afterUid = await linkAndReturnUid(credential);
      if (afterUid != existingUid) {
        return ProviderLinkAttempt.failed(
          FirebaseAuthException(code: 'credential-already-in-use'),
        );
      }
      return ProviderLinkAttempt.linked(existingUid);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') {
        return ProviderLinkAttempt.alreadyLinked(existingUid);
      }
      return ProviderLinkAttempt.failed(error);
    }
  }

  static String mapAuthError(
    AppLocalizations l10n,
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'provider-already-linked':
        return l10n.providerLinkErrorProviderAlreadyLinked;
      case 'credential-already-in-use':
        return l10n.providerLinkErrorCredentialInUse;
      case 'email-already-in-use':
        return l10n.providerLinkErrorEmailInUse;
      case 'invalid-credential':
        return l10n.providerLinkErrorInvalidCredential;
      case 'requires-recent-login':
        return l10n.providerLinkErrorRequiresRecentLogin;
      case 'network-request-failed':
        return l10n.providerLinkErrorNetwork;
      case 'too-many-requests':
        return l10n.providerLinkErrorTooManyRequests;
      case 'user-disabled':
        return l10n.providerLinkErrorUserDisabled;
      case 'operation-not-allowed':
        return l10n.providerLinkErrorNotAllowed;
      default:
        return l10n.providerLinkErrorFailed;
    }
  }
}
