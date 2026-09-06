import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../features/auth/apple_sign_in_flow.dart';
import '../../features/auth/google_sign_in_flow.dart';
import '../../features/auth/provider_link_flow.dart';
import '../notifications/notification_registration_service.dart';
import 'auth_provider_resolver.dart';
import 'email_verification_policy.dart';
import 'pending_provider_link.dart';
import 'user_document_ensure.dart';

typedef EmailPasswordCreate = Future<UserCredential> Function({
  required String email,
  required String password,
});

typedef GoogleAuthTokenPicker
    = Future<({String? idToken, String? accessToken})?> Function();

typedef FirebaseCredentialSignIn = Future<UserCredential> Function(
  AuthCredential credential,
);

typedef GoogleSessionSignOut = Future<void> Function();

typedef AppleNonceGenerator = String Function();

typedef AppleAuthorizationRequest = Future<AppleAuthorizationResult?> Function(
  String hashedNonce,
);

typedef AppleOAuthCredentialBuilder = AuthCredential Function({
  required String idToken,
  required String rawNonce,
});

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailPasswordCreate? createUserWithEmailAndPassword,
    GoogleAuthTokenPicker? pickGoogleAuthTokens,
    FirebaseCredentialSignIn? signInWithCredential,
    GoogleSessionSignOut? signOutGoogle,
    AppleNonceGenerator? generateAppleNonce,
    AppleAuthorizationRequest? requestAppleAuthorization,
    AppleOAuthCredentialBuilder? buildAppleCredential,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _createEmailUser = createUserWithEmailAndPassword,
        _pickGoogleAuthTokens = pickGoogleAuthTokens,
        _signInWithCredential = signInWithCredential,
        _signOutGoogle = signOutGoogle,
        _generateAppleNonce = generateAppleNonce,
        _requestAppleAuthorization = requestAppleAuthorization,
        _buildAppleCredential = buildAppleCredential;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final EmailPasswordCreate? _createEmailUser;
  final GoogleAuthTokenPicker? _pickGoogleAuthTokens;
  final FirebaseCredentialSignIn? _signInWithCredential;
  final GoogleSessionSignOut? _signOutGoogle;
  final AppleNonceGenerator? _generateAppleNonce;
  final AppleAuthorizationRequest? _requestAppleAuthorization;
  final AppleOAuthCredentialBuilder? _buildAppleCredential;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Masks middle digits so logs never include a full phone number.
  static String maskPhoneForLog(String phone) {
    final cleaned = phone.trim();
    if (cleaned.length <= 6) return '****';
    final prefixLen = cleaned.startsWith('+') ? 3 : 2;
    final prefix = cleaned.substring(0, prefixLen.clamp(0, cleaned.length));
    final suffix = cleaned.substring(cleaned.length - 4);
    return '$prefix******$suffix';
  }

  String _friendlyPhoneAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
        case 'missing-phone-number':
          return 'This phone number looks invalid.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait and try again.';
        case 'quota-exceeded':
          return 'SMS could not be sent. Please try again.';
        case 'operation-not-allowed':
        case 'admin-restricted-operation':
        case 'captcha-check-failed':
        case 'missing-client-identifier':
        case 'app-not-authorized':
          return 'Phone sign-in is not configured correctly.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'session-expired':
          return 'Verification expired. Please request a new code.';
        default:
          return 'SMS could not be sent. Please try again.';
      }
    }
    if (error is PlatformException) {
      final code = (error.code).toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      if (code.contains('network') || message.contains('network')) {
        return 'Network error. Please check your connection.';
      }
      if (code.contains('not-authorized') ||
          message.contains('not configured') ||
          message.contains('operation-not-allowed')) {
        return 'Phone sign-in is not configured correctly.';
      }
      return 'SMS could not be sent. Please try again.';
    }
    final raw = error.toString().toLowerCase();
    if (raw.contains('not configured') ||
        raw.contains('operation-not-allowed') ||
        raw.contains('app-not-authorized')) {
      return 'Phone sign-in is not configured correctly.';
    }
    return 'SMS could not be sent. Please try again.';
  }

  void _safeCallback(void Function() action, {required String label}) {
    try {
      action();
    } catch (e, st) {
      debugPrint('AuthService phone callback "$label" failed: $e\n$st');
    }
  }

  // Current user getter
  User? get currentUser => _auth.currentUser;

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onFailed,
    void Function()? onTimeout,
  }) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('+')) {
      _safeCallback(
        () => onFailed('Please enter a valid phone number.'),
        label: 'onFailed-invalid',
      );
      return;
    }

    debugPrint(
      'AuthService: verifying phone ${maskPhoneForLog(trimmed)}',
    );
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: trimmed,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            // Auto-verification on Android can complete without user input.
            await _auth.signInWithCredential(credential);
            final user = _auth.currentUser;
            if (user != null) {
              try {
                await ensureUserDocumentForPhoneUser(user);
              } catch (e) {
                debugPrint(
                    'ensureUserDocumentForPhoneUser after auto-verify: $e');
              }
            }
            _safeCallback(
              () => onAutoVerified(credential),
              label: 'onAutoVerified',
            );
          } catch (e) {
            _safeCallback(
              () => onFailed(_friendlyPhoneAuthError(e)),
              label: 'onFailed-auto',
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            'Phone verificationFailed: code=${e.code} message=${e.message}',
          );
          _safeCallback(
            () => onFailed(_friendlyPhoneAuthError(e)),
            label: 'onFailed-verification',
          );
        },
        codeSent: (verificationId, _) {
          debugPrint('AuthService: codeSent callback reached');
          if (verificationId.trim().isEmpty) {
            _safeCallback(
              () => onFailed('SMS could not be sent. Please try again.'),
              label: 'onFailed-empty-id',
            );
            return;
          }
          _safeCallback(
            () => onCodeSent(verificationId),
            label: 'onCodeSent',
          );
        },
        codeAutoRetrievalTimeout: (_) {
          _safeCallback(() => onTimeout?.call(), label: 'onTimeout');
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('startPhoneVerification FirebaseAuthException: ${e.code}');
      _safeCallback(
        () => onFailed(_friendlyPhoneAuthError(e)),
        label: 'onFailed-auth',
      );
    } on PlatformException catch (e) {
      debugPrint(
        'startPhoneVerification PlatformException: ${e.code} ${e.message}',
      );
      _safeCallback(
        () => onFailed(_friendlyPhoneAuthError(e)),
        label: 'onFailed-platform',
      );
    } catch (e, st) {
      debugPrint('startPhoneVerification error: $e\n$st');
      _safeCallback(
        () => onFailed(_friendlyPhoneAuthError(e)),
        label: 'onFailed-generic',
      );
    }
  }

  Future<UserCredential> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final id = verificationId.trim();
    final code = smsCode.trim();
    if (id.isEmpty) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Verification expired. Please request a new code.',
      );
    }
    if (code.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: 'Please enter the SMS code.',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await ensureUserDocumentForPhoneUser(user);
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown',
        message: _friendlyPhoneAuthError(e),
      );
    }
  }

  Future<void> ensureUserDocumentForPhoneUser(User user) async {
    await _ensureUserDocument(_ensureInputFor(user));
  }

  UserDocumentEnsureInput _ensureInputFor(
    User user, {
    String? nameOverride,
    String? emailOverride,
  }) {
    return UserDocumentEnsureInput(
      uid: user.uid,
      authProvider: AuthProviderResolver.resolveFromUser(user),
      phoneNumber: user.phoneNumber,
      email: emailOverride ?? user.email,
      displayName: nameOverride ?? user.displayName,
    );
  }

  Map<String, dynamic> _createdEnsureView(UserDocumentEnsureWrite write) {
    final name = write.fields['name'];
    if (name is! String || name.trim().isEmpty) return <String, dynamic>{};
    return <String, dynamic>{'name': name.trim()};
  }

  Future<void> _offerAuthDisplayNamePrefill(
      User user, String? candidate) async {
    final name = candidate?.trim() ?? '';
    if (name.isEmpty) return;
    final current = user.displayName?.trim() ?? '';
    if (current.isNotEmpty) return;
    try {
      await user.updateDisplayName(name);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _ensureUserDocument(
    UserDocumentEnsureInput input,
  ) async {
    final ref = _firestore.collection('users').doc(input.uid);
    return _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing = snap.data();
      final write = UserDocumentEnsure.decide(
        existing: existing,
        input: input,
        timestamp: FieldValue.serverTimestamp,
      );
      if (write.isCreate) {
        tx.set(ref, write.fields);
        return _createdEnsureView(write);
      }
      tx.set(ref, write.fields, SetOptions(merge: true));
      return existing;
    });
  }

  /// Sends a Firebase password-reset email.
  ///
  /// `user-not-found` is intentionally treated as success so account
  /// existence is not exposed through the recovery flow.
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        return;
      }
      rethrow;
    }
  }

  // Email ile kayıt. FirebaseAuthException stays typed for Phase 2 UI.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final create = _createEmailUser ?? _auth.createUserWithEmailAndPassword;
    final userCredential = await create(
      email: email,
      password: password,
    );

    await userCredential.user?.updateDisplayName(name);
    await userCredential.user?.sendEmailVerification();
    return userCredential;
  }

  // Firestore'a kullanıcı kaydet (signup sonrası).
  // Create-if-missing only — never resets an existing user document.
  Future<void> createUserInFirestore({
    required String uid,
    required String name,
    required String email,
  }) async {
    final user = _auth.currentUser;
    final input = user != null && user.uid == uid
        ? _ensureInputFor(user, nameOverride: name, emailOverride: email)
        : UserDocumentEnsureInput(
            uid: uid,
            authProvider: AuthProviderResolver.resolve(
              providerIds: const [AuthProviderResolver.passwordProviderId],
              phoneNumber: user?.phoneNumber,
            ),
            phoneNumber: user?.phoneNumber,
            email: email,
            displayName: name,
          );
    await _ensureUserDocument(input);
  }

  // Kullanıcı dokümanının var olduğundan emin ol.
  // Returns the existing user map (or a name-only map after create) so the
  // auth gate can skip a second `users/{uid}` GET.
  Future<Map<String, dynamic>?> ensureUserDocumentExists() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _ensureUserDocument(_ensureInputFor(user));
  }

  // Kullanıcı test durumunu kontrol et.
  //
  // Meaning: legacy Discover/onboarding gate. For flow v2 this is true only
  // after IQ+EQ+Frequency complete (`assessment_flow_completed`).
  Future<bool> hasCompletedTests() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      return doc.data()?['test_completed'] ?? false;
    } catch (e) {
      debugPrint('Error checking test status: $e');
      return false;
    }
  }

  // Kullanıcı profilini tamamlamış mı kontrol et
  Future<bool> hasCompletedProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      return doc.data()?['profile_completed'] ?? false;
    } catch (e) {
      debugPrint('Error checking profile status: $e');
      return false;
    }
  }

  // Test tamamlandığında güncelle (normalized skorlar ile).
  //
  // LEGACY helper — P1B-2A flow v2 must NOT call this from EQ.
  // New flow uses AssessmentProgressService.markEqCompleted /
  // markAssessmentFlowCompleted instead (no persona rewrite after EQ).
  //
  // P1B-1.1: when [writePersona] is false, do not overwrite archetype/category
  // (unknown IQ denominator must not fabricate a new HH…LL persona).
  // When [iqNormalized] is null, omit that key (do not write 0 as "Low").
  //
  // `test_completed` here still means legacy "IQ+EQ grid done". Prefer
  // AssessmentProgressService for flow v2 where `test_completed` is set only
  // after Frequency completes.
  Future<void> updateTestCompletion({
    String? archetype,
    String? category,
    required int iqScore,
    required int eqScore,
    int? iqNormalized,
    required int eqNormalized,
    bool writePersona = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final payload = <String, dynamic>{
        'test_completed': true,
        'iq_score': iqScore,
        'eq_score': eqScore,
        'eq_normalized': eqNormalized,
        'test_completed_at': FieldValue.serverTimestamp(),
      };
      if (writePersona &&
          archetype != null &&
          archetype.isNotEmpty &&
          category != null &&
          category.isNotEmpty) {
        payload['archetype'] = archetype;
        payload['category'] = category;
      }
      if (iqNormalized != null) {
        payload['iq_normalized'] = iqNormalized;
      }

      await _firestore.collection('users').doc(user.uid).update(payload);

      // discover_eligible is owned by trusted Cloud Function
      // (`trusted_discover_eligibility_authority_v1`) — no client self-grant.

      debugPrint(
          '✅ Test results saved: IQ=$iqScore($iqNormalized), EQ=$eqScore($eqNormalized), Category=$category writePersona=$writePersona');
    } catch (e) {
      debugPrint('Error updating test completion: $e');
      throw e.toString();
    }
  }

  /// Reads existing legacy persona mirrors without inventing defaults.
  Future<({String? archetype, String? category})>
      getStoredPersonaMirrors() async {
    final user = _auth.currentUser;
    if (user == null) return (archetype: null, category: null);
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return (archetype: null, category: null);
    final archetype = (data['archetype'] as String?)?.trim();
    final category = (data['category'] as String?)?.trim();
    return (
      archetype: (archetype == null || archetype.isEmpty) ? null : archetype,
      category: (category == null || category.isEmpty) ? null : category,
    );
  }

  // Email doğrulandı mı kontrol et
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Email doğrulama tekrar gönder
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Google account chooser → Firebase credential → idempotent user ensure.
  ///
  /// Cancellation returns [GoogleSignInAttempt.cancelled] and writes nothing.
  /// Collision captures a memory-only pending credential and never merges UIDs.
  Future<GoogleSignInAttempt> signInWithGoogle() async {
    ({String? idToken, String? accessToken})? tokens;
    try {
      tokens = await _obtainGoogleAuthTokens();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'cancelled') {
        return GoogleSignInAttempt.cancelled();
      }
      return GoogleSignInAttempt.failed(error);
    } on PlatformException catch (error) {
      final mapped = _googlePlatformError(error);
      if (mapped.code == 'cancelled') {
        return GoogleSignInAttempt.cancelled();
      }
      return GoogleSignInAttempt.failed(mapped);
    } catch (_) {
      return GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'unknown'),
      );
    }

    if (tokens == null) {
      return GoogleSignInAttempt.cancelled();
    }

    final idToken = tokens.idToken;
    final accessToken = tokens.accessToken;
    if ((idToken == null || idToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      await _signOutGoogleSession();
      return GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'invalid-credential'),
      );
    }

    try {
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );
      final signIn = _signInWithCredential ?? _auth.signInWithCredential;
      final userCredential = await signIn(credential);
      final user = userCredential.user;
      if (user != null) {
        SignInProviderMemory.remember(AuthProviderResolver.googleProviderId);
        await _ensureUserDocument(_ensureInputFor(user));
      }
      return GoogleSignInAttempt.success(userCredential);
    } on FirebaseAuthException catch (error) {
      await _signOutGoogleSession();
      if (error.code == 'account-exists-with-different-credential') {
        PendingProviderLinkStore.captureFromCollision(
          error,
          attemptedProvider: AuthProviderResolver.googleProviderId,
        );
        return GoogleSignInAttempt.collision(error);
      }
      return GoogleSignInAttempt.failed(error);
    } on PlatformException catch (error) {
      await _signOutGoogleSession();
      return GoogleSignInAttempt.failed(_googlePlatformError(error));
    } catch (_) {
      await _signOutGoogleSession();
      return GoogleSignInAttempt.failed(
        FirebaseAuthException(code: 'unknown'),
      );
    }
  }

  Future<({String? idToken, String? accessToken})?>
      _obtainGoogleAuthTokens() async {
    final pickGoogleAuthTokens = _pickGoogleAuthTokens;
    if (pickGoogleAuthTokens != null) {
      return pickGoogleAuthTokens();
    }
    final account = await GoogleSignInFlow.createClient().signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return (idToken: auth.idToken, accessToken: auth.accessToken);
  }

  FirebaseAuthException _googlePlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('network') || message.contains('network')) {
      return FirebaseAuthException(code: 'network-request-failed');
    }
    if (code.contains('canceled') ||
        code.contains('cancelled') ||
        message.contains('canceled') ||
        message.contains('cancelled')) {
      return FirebaseAuthException(code: 'cancelled');
    }
    return FirebaseAuthException(code: 'unknown');
  }

  Future<void> _signOutGoogleSession() async {
    try {
      final signOutGoogle = _signOutGoogle;
      if (signOutGoogle != null) {
        await signOutGoogle();
        return;
      }
      await GoogleSignInFlow.createClient().signOut();
    } catch (_) {}
  }

  /// Apple nonce flow → Firebase credential → idempotent user ensure.
  ///
  /// Cancellation returns [AppleSignInAttempt.cancelled] and writes nothing.
  /// Collision captures a memory-only pending credential and never merges UIDs.
  /// Normal sign-out never revokes Apple authorization.
  Future<AppleSignInAttempt> signInWithApple() async {
    final rawNonce =
        (_generateAppleNonce ?? AppleSignInFlow.generateRawNonce)();
    final hashedNonce = AppleSignInFlow.sha256Of(rawNonce);

    AppleAuthorizationResult? apple;
    try {
      apple = await _obtainAppleAuthorization(hashedNonce);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return AppleSignInAttempt.cancelled();
      }
      return AppleSignInAttempt.failed(
        AppleSignInFlow.mapAppleException(error),
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'cancelled') {
        return AppleSignInAttempt.cancelled();
      }
      return AppleSignInAttempt.failed(error);
    } catch (_) {
      return AppleSignInAttempt.failed(
        FirebaseAuthException(code: 'apple-unknown'),
      );
    }

    if (apple == null) {
      return AppleSignInAttempt.cancelled();
    }
    if (apple.identityToken.trim().isEmpty) {
      return AppleSignInAttempt.failed(
        FirebaseAuthException(code: 'invalid-credential'),
      );
    }

    try {
      final build = _buildAppleCredential ??
          ({required String idToken, required String rawNonce}) {
            return OAuthProvider('apple.com').credential(
              idToken: idToken,
              rawNonce: rawNonce,
            );
          };
      final credential = build(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
      );
      final signIn = _signInWithCredential ?? _auth.signInWithCredential;
      final userCredential = await signIn(credential);
      final user = userCredential.user;
      if (user != null) {
        SignInProviderMemory.remember(AuthProviderResolver.appleProviderId);
        final appleName = AppleSignInFlow.displayName(
          givenName: apple.givenName,
          familyName: apple.familyName,
        );
        await _offerAuthDisplayNamePrefill(
          user,
          appleName.isEmpty ? null : appleName,
        );
        await _ensureUserDocument(
          _ensureInputFor(
            user,
            nameOverride: appleName.isEmpty ? null : appleName,
            emailOverride:
                UserDocumentEnsure.isBlank(apple.email) ? null : apple.email,
          ),
        );
      }
      return AppleSignInAttempt.success(userCredential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'account-exists-with-different-credential') {
        PendingProviderLinkStore.captureFromCollision(
          error,
          attemptedProvider: AuthProviderResolver.appleProviderId,
        );
        return AppleSignInAttempt.collision(error);
      }
      return AppleSignInAttempt.failed(error);
    } catch (_) {
      return AppleSignInAttempt.failed(
        FirebaseAuthException(code: 'unknown'),
      );
    }
  }

  Future<AppleAuthorizationResult?> _obtainAppleAuthorization(
    String hashedNonce,
  ) async {
    final requestAppleAuthorization = _requestAppleAuthorization;
    if (requestAppleAuthorization != null) {
      return requestAppleAuthorization(hashedNonce);
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return AppleAuthorizationResult(
      identityToken: identityToken,
      authorizationCode: credential.authorizationCode,
      email: credential.email,
      givenName: credential.givenName,
      familyName: credential.familyName,
    );
  }

  // Çıkış yap
  Future<void> signOut() async {
    PendingProviderLinkStore.clear();
    SignInProviderMemory.clear();
    await unregisterPushTokenThenSignOut(
      unregister: () =>
          NotificationRegistrationService.instance.unregisterForLogout(),
      signOut: () async {
        await _auth.signOut();
        await _signOutGoogleSession();
      },
    );
  }

  /// Links a memory-only pending OAuth credential to the **current** user.
  ///
  /// Existing Firebase UID is authoritative. Never merges two UIDs, never
  /// copies Firestore data, and never links during an unverified password
  /// session (Phase 3 gate stays in force).
  Future<ProviderLinkAttempt> linkPendingCredential({
    String? existingUid,
    bool? emailVerified,
    String? currentSignInProvider,
    Future<String> Function(AuthCredential credential)? linkAndReturnUid,
    Future<void> Function(String uid)? ensureExistingUser,
  }) async {
    final pending = PendingProviderLinkStore.current;
    if (pending == null) {
      return const ProviderLinkAttempt.idle();
    }

    final user = existingUid == null ? _auth.currentUser : null;
    final uid = existingUid ?? user?.uid;
    if (uid == null || uid.isEmpty) {
      return ProviderLinkAttempt.failed(
        FirebaseAuthException(code: 'invalid-credential'),
      );
    }

    final provider =
        (currentSignInProvider ?? SignInProviderMemory.current ?? '').trim();
    final verified = emailVerified ?? user?.emailVerified ?? false;
    if (ProviderLinkFlow.shouldDeferUnverifiedPassword(
      currentSignInProvider: provider,
      emailVerified: verified,
    )) {
      return const ProviderLinkAttempt.deferred();
    }

    final linker = linkAndReturnUid ??
        (AuthCredential credential) async {
          final current = _auth.currentUser;
          if (current == null) {
            throw FirebaseAuthException(code: 'invalid-credential');
          }
          final result = await current.linkWithCredential(credential);
          return result.user?.uid ?? current.uid;
        };

    final attempt = await ProviderLinkFlow.linkToExistingUid(
      existingUid: uid,
      credential: pending.credential,
      linkAndReturnUid: linker,
    );

    if (attempt.isSuccess) {
      PendingProviderLinkStore.clear();
      final ensure = ensureExistingUser ??
          (String linkedUid) async {
            final current = _auth.currentUser;
            if (current != null && current.uid == linkedUid) {
              await _ensureUserDocument(_ensureInputFor(current));
            }
          };
      await ensure(uid);
      return attempt;
    }

    if (attempt.error != null &&
        ProviderLinkFlow.isUnrecoverableLinkError(attempt.error!.code)) {
      PendingProviderLinkStore.clear();
    }
    return attempt;
  }
}

/// Unregisters this device token, then signs out. Unregister failure is ignored.
@visibleForTesting
Future<void> unregisterPushTokenThenSignOut({
  required Future<void> Function() unregister,
  required Future<void> Function() signOut,
}) async {
  try {
    await unregister();
  } catch (_) {}
  await signOut();
}
