import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../notifications/notification_registration_service.dart';
import 'auth_provider_resolver.dart';
import 'user_document_ensure.dart';

typedef EmailPasswordCreate = Future<UserCredential> Function({
  required String email,
  required String password,
});

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    EmailPasswordCreate? createUserWithEmailAndPassword,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _createEmailUser = createUserWithEmailAndPassword;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final EmailPasswordCreate? _createEmailUser;

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

  Map<String, dynamic> _createdEnsureView(UserDocumentEnsureInput input) {
    final seededName = input.displayName?.trim() ?? '';
    if (seededName.isEmpty) return <String, dynamic>{};
    return <String, dynamic>{'name': seededName};
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
        return _createdEnsureView(input);
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

  // Çıkış yap
  Future<void> signOut() async {
    await unregisterPushTokenThenSignOut(
      unregister: () =>
          NotificationRegistrationService.instance.unregisterForLogout(),
      signOut: () => _auth.signOut(),
    );
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
