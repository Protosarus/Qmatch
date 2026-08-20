import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/home_geography.dart';
import '../models/profile_read_result.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Discover eligibility is owned by the trusted Cloud Function
  /// (`trusted_discover_eligibility_authority_v1`).
  ///
  /// Clients must not self-grant `discover_eligible=true`. Profile / assessment
  /// completion writes the underlying fields; the backend recomputes the flag.
  /// Kept as a no-op so existing call sites do not fail under production rules.
  Future<void> refreshDiscoverEligibility(String uid) async {
    assert(uid.isNotEmpty);
    // No client write — Admin SDK CF is the sole true-grant authority.
  }

  Future<void> saveProfile(
    UserProfileModel profile, {
    HomeGeography? homeGeography,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      // Merge only profile payload. Assessment/persona fields are omitted when
      // null in [UserProfileModel.toFirestore], so setup cannot erase them.
      // Does not write discover_eligible — backend recomputes on this write.
      // Home geography is written only after an explicit location-share derive.
      final payload = <String, dynamic>{
        ...profile.toFirestore(),
        'profile_completed': true,
        'completed_at': FieldValue.serverTimestamp(),
      };
      if (homeGeography != null) {
        payload['home_country'] = homeGeography.country;
        payload['home_city'] = homeGeography.city;
        payload['home_geo_updated_at'] = FieldValue.serverTimestamp();
      }
      await _firestore.collection('users').doc(user.uid).set(
            payload,
            SetOptions(merge: true),
          );

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
