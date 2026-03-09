import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;

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
        'name': name,
        'email': email,
        'test_completed': false,
        'profile_completed': false,
        'archetype': null,
        'category': null, // HH, HM, HL, MH, MM, ML, LH, LM, LL
        'iq_score': null, // Raw score (0-10)
        'eq_score': null, // Raw score (0-10)
        'iq_normalized': null, // Normalized (0-100)
        'eq_normalized': null, // Normalized (0-100)
        'created_at': FieldValue.serverTimestamp(),
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
      await createUserInFirestore(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
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
