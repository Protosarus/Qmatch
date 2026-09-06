import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/services/auth_provider_resolver.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pending_provider_link.dart';
import '../../auth/apple_sign_in_flow.dart';
import '../../auth/google_sign_in_flow.dart';

enum AccountDeletionStage {
  cancelled,
  needsPassword,
  needsGoogle,
  needsPhone,
  needsApple,
  appleRevokeFailed,
  uidMismatch,
  failed,
  succeeded,
}

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.stage,
    this.errorCode,
  });

  final AccountDeletionStage stage;
  final String? errorCode;

  bool get isSuccess => stage == AccountDeletionStage.succeeded;
  bool get isCancelled => stage == AccountDeletionStage.cancelled;
}

/// In-app deletion: reauth → Apple revoke if linked → trusted callable → sign out.
///
/// Logout never uses this path. Authorization codes stay in memory only.
class AccountDeletionIdentity {
  const AccountDeletionIdentity({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.appleLinked = false,
    this.passwordLinked = false,
    this.googleLinked = false,
    this.phoneLinked = false,
  });

  final String uid;
  final String? email;
  final String? phoneNumber;
  final bool appleLinked;
  final bool passwordLinked;
  final bool googleLinked;
  final bool phoneLinked;
}

class AccountDeletionCoordinator {
  AccountDeletionCoordinator({
    this.debugIdentity,
    FirebaseAuth? auth,
    AuthService? authService,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> data)?
        callDelete,
    Future<void> Function(String authorizationCode)? revokeApple,
    Future<UserCredential> Function(AuthCredential credential)? reauthenticate,
    Future<String> Function(AuthCredential credential)? resolveReauthUid,
    Future<AppleAuthorizationResult?> Function(String hashedNonce)?
        requestAppleAuthorization,
    Future<({String? idToken, String? accessToken})?> Function()?
        pickGoogleAuthTokens,
    String Function()? generateAppleNonce,
    Future<void> Function()? signOut,
  })  : _authOverride = auth,
        _authServiceOverride = authService,
        _callDelete = callDelete,
        _revokeApple = revokeApple,
        _reauthenticate = reauthenticate,
        _resolveReauthUid = resolveReauthUid,
        _requestAppleAuthorization = requestAppleAuthorization,
        _pickGoogleAuthTokens = pickGoogleAuthTokens,
        _generateAppleNonce = generateAppleNonce,
        _signOut = signOut;

  static const String callableName = 'deleteQMatchAccount';
  static const String callableRegion = 'us-central1';

  final AccountDeletionIdentity? debugIdentity;
  final FirebaseAuth? _authOverride;
  final AuthService? _authServiceOverride;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  AuthService get _authService =>
      _authServiceOverride ?? AuthService(auth: _authOverride);
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> data)?
      _callDelete;
  final Future<void> Function(String authorizationCode)? _revokeApple;
  final Future<UserCredential> Function(AuthCredential credential)?
      _reauthenticate;
  final Future<String> Function(AuthCredential credential)? _resolveReauthUid;
  final Future<AppleAuthorizationResult?> Function(String hashedNonce)?
      _requestAppleAuthorization;
  final Future<({String? idToken, String? accessToken})?> Function()?
      _pickGoogleAuthTokens;
  final String Function()? _generateAppleNonce;
  final Future<void> Function()? _signOut;

  AccountDeletionIdentity? get _identity {
    if (debugIdentity != null) return debugIdentity;
    final user = _auth.currentUser;
    if (user == null) return null;
    return AccountDeletionIdentity(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      appleLinked: AuthProviderResolver.hasAppleLinked(user),
      passwordLinked: AuthProviderResolver.hasPasswordLinked(user),
      googleLinked: AuthProviderResolver.hasGoogleLinked(user),
      phoneLinked: AuthProviderResolver.hasPhoneLinked(user),
    );
  }

  bool isAppleLinked([User? user]) {
    if (debugIdentity != null) return debugIdentity!.appleLinked;
    try {
      final current = user ?? _auth.currentUser;
      if (current == null) return false;
      return AuthProviderResolver.hasAppleLinked(current);
    } catch (_) {
      return false;
    }
  }

  Future<AccountDeletionResult> deleteAccount({
    String? password,
    String? phoneCredentialVerificationId,
    String? phoneSmsCode,
  }) async {
    final identity = _identity;
    if (identity == null) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.failed,
        errorCode: 'not_signed_in',
      );
    }
    final expectedUid = identity.uid;
    var appleRevoked = false;

    try {
      if (identity.appleLinked) {
        final apple = await _revokeLinkedApple(expectedUid);
        if (apple.stage != AccountDeletionStage.succeeded) {
          return apple;
        }
        appleRevoked = true;
      } else if (identity.passwordLinked) {
        final passwordValue = password?.trim() ?? '';
        if (passwordValue.isEmpty) {
          return const AccountDeletionResult(
            stage: AccountDeletionStage.needsPassword,
          );
        }
        final reauth = await _reauthWithCredential(
          expectedUid,
          EmailAuthProvider.credential(
            email: identity.email ?? '',
            password: passwordValue,
          ),
        );
        if (reauth != null) return reauth;
      } else if (identity.googleLinked) {
        final google = await _reauthGoogle(expectedUid);
        if (google != null) return google;
      } else if (identity.phoneLinked) {
        final id = phoneCredentialVerificationId?.trim() ?? '';
        final code = phoneSmsCode?.trim() ?? '';
        if (id.isNotEmpty && code.isNotEmpty) {
          final reauth = await _reauthWithCredential(
            expectedUid,
            PhoneAuthProvider.credential(verificationId: id, smsCode: code),
          );
          if (reauth != null) return reauth;
        }
      }

      await _invokeDelete(appleRevoked: appleRevoked);
      PendingProviderLinkStore.clear();
      try {
        final signOut = _signOut;
        if (signOut != null) {
          await signOut();
        } else {
          await _authService.signOut();
        }
      } catch (error) {
        debugPrint(
            'Account deletion sign-out after wipe: ${error.runtimeType}');
      }
      return const AccountDeletionResult(
        stage: AccountDeletionStage.succeeded,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        if (identity.appleLinked) {
          return const AccountDeletionResult(
            stage: AccountDeletionStage.needsApple,
            errorCode: 'requires-recent-login',
          );
        }
        if (identity.passwordLinked) {
          return const AccountDeletionResult(
            stage: AccountDeletionStage.needsPassword,
            errorCode: 'requires-recent-login',
          );
        }
        if (identity.googleLinked) {
          return const AccountDeletionResult(
            stage: AccountDeletionStage.needsGoogle,
            errorCode: 'requires-recent-login',
          );
        }
        return const AccountDeletionResult(
          stage: AccountDeletionStage.needsPhone,
          errorCode: 'requires-recent-login',
        );
      }
      if (error.code == 'cancelled') {
        return const AccountDeletionResult(
          stage: AccountDeletionStage.cancelled,
        );
      }
      debugPrint('Account deletion failed: ${error.code}');
      return AccountDeletionResult(
        stage: AccountDeletionStage.failed,
        errorCode: error.code,
      );
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Account deletion callable failed: ${error.code}');
      return AccountDeletionResult(
        stage: error.code == 'failed-precondition'
            ? AccountDeletionStage.needsApple
            : AccountDeletionStage.failed,
        errorCode: error.code,
      );
    } catch (error) {
      debugPrint('Account deletion failed: ${error.runtimeType}');
      return const AccountDeletionResult(
        stage: AccountDeletionStage.failed,
        errorCode: 'unknown',
      );
    }
  }

  Future<AccountDeletionResult> _revokeLinkedApple(String expectedUid) async {
    final rawNonce =
        (_generateAppleNonce ?? AppleSignInFlow.generateRawNonce)();
    final hashedNonce = AppleSignInFlow.sha256Of(rawNonce);
    AppleAuthorizationResult? apple;
    try {
      final requestAppleAuthorization = _requestAppleAuthorization;
      apple = requestAppleAuthorization != null
          ? await requestAppleAuthorization(hashedNonce)
          : await _liveAppleAuthorization(hashedNonce);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const AccountDeletionResult(
          stage: AccountDeletionStage.cancelled,
        );
      }
      return const AccountDeletionResult(
        stage: AccountDeletionStage.appleRevokeFailed,
      );
    }
    if (apple == null) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.cancelled,
      );
    }
    final code = apple.authorizationCode?.trim() ?? '';
    if (apple.identityToken.trim().isEmpty || code.isEmpty) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.appleRevokeFailed,
      );
    }
    final credential =
        OAuthProvider(AuthProviderResolver.appleProviderId).credential(
      idToken: apple.identityToken,
      rawNonce: rawNonce,
    );
    final mismatch = await _reauthWithCredential(expectedUid, credential);
    if (mismatch != null) return mismatch;
    try {
      final revokeApple = _revokeApple;
      if (revokeApple != null) {
        await revokeApple(code);
      } else {
        await _auth.revokeTokenWithAuthorizationCode(code);
      }
    } catch (error) {
      debugPrint('Apple revoke failed: ${error.runtimeType}');
      return const AccountDeletionResult(
        stage: AccountDeletionStage.appleRevokeFailed,
      );
    }
    return const AccountDeletionResult(
      stage: AccountDeletionStage.succeeded,
    );
  }

  Future<AppleAuthorizationResult?> _liveAppleAuthorization(
    String hashedNonce,
  ) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    if (credential.identityToken == null || credential.identityToken!.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return AppleAuthorizationResult(
      identityToken: credential.identityToken!,
      authorizationCode: credential.authorizationCode,
    );
  }

  Future<AccountDeletionResult?> _reauthGoogle(String expectedUid) async {
    final pickGoogleAuthTokens = _pickGoogleAuthTokens;
    final tokens = pickGoogleAuthTokens != null
        ? await pickGoogleAuthTokens()
        : await GoogleSignInFlow.createClient().signIn().then((account) async {
            if (account == null) return null;
            final auth = await account.authentication;
            return (idToken: auth.idToken, accessToken: auth.accessToken);
          });
    if (tokens == null || (tokens.idToken ?? '').isEmpty) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.cancelled,
      );
    }
    return _reauthWithCredential(
      expectedUid,
      GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      ),
    );
  }

  Future<AccountDeletionResult?> _reauthWithCredential(
    String expectedUid,
    AuthCredential credential,
  ) async {
    final resolveReauthUid = _resolveReauthUid;
    if (resolveReauthUid != null) {
      final uid = await resolveReauthUid(credential);
      if (uid != expectedUid) {
        return const AccountDeletionResult(
          stage: AccountDeletionStage.uidMismatch,
        );
      }
      return null;
    }
    final current = _auth.currentUser;
    if (current == null) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.failed,
        errorCode: 'not_signed_in',
      );
    }
    final reauth = _reauthenticate ?? current.reauthenticateWithCredential;
    final result = await reauth(credential);
    final uid = result.user?.uid ?? _auth.currentUser?.uid;
    if (uid != expectedUid) {
      return const AccountDeletionResult(
        stage: AccountDeletionStage.uidMismatch,
      );
    }
    return null;
  }

  Future<void> _invokeDelete({required bool appleRevoked}) async {
    final payload = <String, dynamic>{
      if (appleRevoked) 'apple_revocation_completed': true,
    };
    final callDelete = _callDelete;
    if (callDelete != null) {
      await callDelete(payload);
      return;
    }
    final functions = FirebaseFunctions.instanceFor(region: callableRegion);
    await functions.httpsCallable(callableName).call(payload);
  }
}
