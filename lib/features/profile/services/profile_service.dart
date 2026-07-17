import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> refreshDiscoverEligibility(String uid) async {
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

  Future<void> saveProfile(UserProfileModel profile) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      await _firestore.collection('users').doc(user.uid).set({
        ...profile.toFirestore(),
        'profile_completed': true,
        'completed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Safe MVP: recompute discover eligibility after profile save.
      await refreshDiscoverEligibility(user.uid);

      debugPrint('✅ Profile saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      rethrow;
    }
  }

  Future<UserProfileModel?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;

      return UserProfileModel.fromFirestore(doc.data()!, user.uid);
    } catch (e) {
      debugPrint('❌ Error getting profile: $e');
      return null;
    }
  }

  Future<bool> isProfileCompleted() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['profile_completed'] ?? false;
    } catch (e) {
      debugPrint('❌ Error checking profile status: $e');
      return false;
    }
  }
}
