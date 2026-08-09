import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_read_result.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> refreshDiscoverEligibility(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    // Prefer full assessment battery: flow v2 sets both; legacy used
    // test_completed after EQ-only.
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

  Future<void> saveProfile(UserProfileModel profile) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      // Merge only profile payload. Assessment/persona fields are omitted when
      // null in [UserProfileModel.toFirestore], so setup cannot erase them.
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

  /// Same Firestore path as [getProfile], with explicit missing vs failure.
  Future<ProfileReadResult> readOwnProfile() async {
    final user = _auth.currentUser;
    if (user == null) return const ProfileReadResult.unauthenticated();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return const ProfileReadResult.missing();
      return ProfileReadResult.loaded(
        UserProfileModel.fromFirestore(doc.data()!, user.uid),
      );
    } catch (e) {
      debugPrint('❌ Error reading profile: $e');
      return const ProfileReadResult.failed();
    }
  }

  Future<UserProfileModel?> getProfile() async {
    final result = await readOwnProfile();
    return result.profile;
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
