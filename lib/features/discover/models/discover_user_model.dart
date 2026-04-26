import 'package:cloud_firestore/cloud_firestore.dart';

/// Read model for Discover feed — maps `users/{uid}` documents in this project.
class DiscoverUserModel {
  final String uid;
  final String name;
  final int age;
  final String bio;
  final String gender;
  final String lookingFor;
  final String? archetype;
  final String? category;
  final String? profilePhotoUrl;
  final List<String> photos;
  final List<String> interests;
  final Timestamp? lastActiveAt;
  final int? iqNormalized;
  final int? eqNormalized;
  final bool profileCompleted;
  final bool testCompleted;
  final bool active;

  const DiscoverUserModel({
    required this.uid,
    required this.name,
    required this.age,
    this.bio = '',
    this.gender = '',
    this.lookingFor = '',
    this.archetype,
    this.category,
    this.profilePhotoUrl,
    this.photos = const [],
    this.interests = const [],
    this.lastActiveAt,
    this.iqNormalized,
    this.eqNormalized,
    this.profileCompleted = false,
    this.testCompleted = false,
    this.active = true,
  });

  /// Primary photo URL for display (first usable URL).
  String? get primaryPhotoUrl {
    if (profilePhotoUrl != null && profilePhotoUrl!.trim().isNotEmpty) {
      return profilePhotoUrl;
    }
    for (final url in photos) {
      if (url.trim().isNotEmpty) return url;
    }
    return null;
  }

  bool get hasPhoto => primaryPhotoUrl != null;

  String get displayName {
    final n = name.trim();
    return n.isEmpty ? 'Member' : n;
  }

  /// Compatibility hint labels (no raw IQ/EQ scores in UI).
  String get compatibilityHint {
    if (category != null && category!.isNotEmpty) {
      return 'Category $category';
    }
    if (archetype != null && archetype!.isNotEmpty) {
      return 'Archetype match';
    }
    if (iqNormalized != null || eqNormalized != null) {
      return 'Mindset-aligned';
    }
    return 'Compatible profile';
  }

  factory DiscoverUserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final photosList = List<String>.from(data['photos'] ?? const []);
    return DiscoverUserModel(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      age: (data['age'] as num?)?.toInt() ?? 18,
      bio: (data['bio'] as String?)?.trim() ?? '',
      gender: (data['gender'] as String?)?.trim() ?? '',
      lookingFor: (data['looking_for'] as String?)?.trim() ?? '',
      archetype: data['archetype'] as String?,
      category: data['category'] as String?,
      profilePhotoUrl: data['profile_photo_url'] as String?,
      photos: photosList,
      interests: List<String>.from(data['interests'] ?? const []),
      lastActiveAt: data['last_active_at'] as Timestamp?,
      iqNormalized: (data['iq_normalized'] as num?)?.toInt(),
      eqNormalized: (data['eq_normalized'] as num?)?.toInt(),
      profileCompleted: data['profile_completed'] as bool? ?? false,
      testCompleted: data['test_completed'] as bool? ?? false,
      active: data['active'] as bool? ?? true,
    );
  }
}
