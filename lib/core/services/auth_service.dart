import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<void> _refreshDiscoverEligibility(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    final testCompleted = data['test_completed'] as bool? ?? false;
    final flowCompleted = data['assessment_flow_completed'] as bool? ?? false;
    final assessmentsDone = testCompleted || flowCompleted;
    final profileCompleted = data['profile_completed'] as bool? ?? false;
    final active = data['active'] as bool? ?? true;
    final profilePhotoUrl = (data['profile_photo_url'] as String?)?.trim();
    final photos =
        (data['photos'] as List?)?.cast<String>() ?? const <String>[];
    final hasPhoto = (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) ||
        photos.isNotEmpty;

    final eligible = active && assessmentsDone && profileCompleted && hasPhoto;

    await _firestore.collection('users').doc(uid).set(
      {
        'discover_eligible': eligible,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();

    final phoneNumber = user.phoneNumber;

    if (!doc.exists) {
      await ref.set(
        {
          'uid': user.uid,
          'phone_number': phoneNumber,
          // Do not seed null Auth displayName into canonical `name`.
          // Display-name gate collects and writes a validated value.
          if (user.displayName != null && user.displayName!.trim().isNotEmpty)
            'name': user.displayName!.trim(),
          'email': user.email,
          'auth_provider': 'phone',
          'test_completed': false,
          'frequency_completed': false,
          'profile_completed': false,
          'discover_eligible': false,
          'active': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_active_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    // Existing doc: only merge safe fields.
    await ref.set(
      {
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
        'auth_provider': 'phone',
        'updated_at': FieldValue.serverTimestamp(),
        'last_active_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Email ile kayıt
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Display name güncelle
      await userCredential.user?.updateDisplayName(name);

      // Email verification gönder
      await userCredential.user?.sendEmailVerification();

      return userCredential;
    } catch (e) {
      throw e.toString();
    }
  }

  // Firestore'a kullanıcı kaydet (signup sonrası)
  Future<void> createUserInFirestore({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      // P1B-1: omit optional assessment mirrors (never write null keys that
      // would erase valid scores if this path is reused on an existing uid).
      // P2C-1C-4A: never seed a placeholder like "User"; omit `name` when empty
      // so the display-name gate collects a real value.
      final trimmedName = name.trim();
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        if (trimmedName.isNotEmpty) 'name': trimmedName,
        'email': email,
        'auth_provider': 'email',
        'test_completed': false,
        'frequency_completed': false,
        'profile_completed': false,
        'discover_eligible': false,
        'active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_active_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user in Firestore: $e');
      throw e.toString();
    }
  }

  // Kullanıcı dokümanının var olduğundan emin ol
  Future<void> ensureUserDocumentExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // If signed in with phone, create a phone-first doc.
      if ((user.phoneNumber ?? '').isNotEmpty) {
        await ensureUserDocumentForPhoneUser(user);
      } else {
        await createUserInFirestore(
          uid: user.uid,
          name: user.displayName?.trim() ?? '',
          email: user.email ?? '',
        );
      }
    } else {
      // Keep last active fresh without overwriting onboarding fields.
      await _firestore.collection('users').doc(user.uid).set(
        {
          'updated_at': FieldValue.serverTimestamp(),
          'last_active_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
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

      // Safe MVP: recompute discover eligibility after tests complete.
      await _refreshDiscoverEligibility(user.uid);

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
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw 'Failed to send verification email';
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
