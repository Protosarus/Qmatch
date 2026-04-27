import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _friendlyPhoneAuthError(Object error) {
    if (error is FirebaseAuthException) {
      // FirebaseAuthException.message is typically already user-friendly enough.
      return error.message ?? 'Phone verification failed. Please try again.';
    }
    return 'Phone verification failed. Please try again.';
  }

  Future<void> _refreshDiscoverEligibility(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    final testCompleted = data['test_completed'] as bool? ?? false;
    final profileCompleted = data['profile_completed'] as bool? ?? false;
    final active = data['active'] as bool? ?? true;
    final profilePhotoUrl = (data['profile_photo_url'] as String?)?.trim();
    final photos = (data['photos'] as List?)?.cast<String>() ?? const <String>[];
    final hasPhoto = (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) || photos.isNotEmpty;

    final eligible = active && testCompleted && profileCompleted && hasPhoto;

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
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          try {
            // Auto-verification on Android can complete without user input.
            await _auth.signInWithCredential(credential);
            onAutoVerified(credential);
          } catch (e) {
            onFailed(_friendlyPhoneAuthError(e));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onFailed(_friendlyPhoneAuthError(e));
        },
        codeSent: (verificationId, _) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {
          onTimeout?.call();
        },
      );
    } catch (e) {
      onFailed(_friendlyPhoneAuthError(e));
    }
  }

  Future<UserCredential> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user != null) {
      await ensureUserDocumentForPhoneUser(user);
    }
    return userCredential;
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
          'name': user.displayName,
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
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
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
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'auth_provider': 'email',
        'test_completed': false,
        'frequency_completed': false,
        'profile_completed': false,
        'discover_eligible': false,
        'active': true,
        'archetype': null,
        'category': null, // HH, HM, HL, MH, MM, ML, LH, LM, LL
        'iq_score': null, // Raw score (0-10)
        'eq_score': null, // Raw score (0-10)
        'iq_normalized': null, // Normalized (0-100)
        'eq_normalized': null, // Normalized (0-100)
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
          name: user.displayName ?? 'User',
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

  // Kullanıcı test durumunu kontrol et
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

  // Test tamamlandığında güncelle (normalized skorlar ile)
  Future<void> updateTestCompletion({
    required String archetype,
    required String category,
    required int iqScore,
    required int eqScore,
    required int iqNormalized,
    required int eqNormalized,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'test_completed': true,
        'archetype': archetype,
        'category': category,
        'iq_score': iqScore,
        'eq_score': eqScore,
        'iq_normalized': iqNormalized,
        'eq_normalized': eqNormalized,
        'test_completed_at': FieldValue.serverTimestamp(),
      });

      // Safe MVP: recompute discover eligibility after tests complete.
      await _refreshDiscoverEligibility(user.uid);
      
      debugPrint('✅ Test results saved: IQ=$iqScore($iqNormalized), EQ=$eqScore($eqNormalized), Category=$category');
    } catch (e) {
      debugPrint('Error updating test completion: $e');
      throw e.toString();
    }
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
