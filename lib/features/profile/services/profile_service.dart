import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveProfile(UserProfileModel profile) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';
    
    try {
      await _firestore.collection('users').doc(user.uid).set({
        ...profile.toFirestore(),
        'profile_completed': true,
        'completed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
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
