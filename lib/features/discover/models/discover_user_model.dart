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
  final String? frequencyType;
  final double? frequencyScore;
  final List<String>? frequencyTags;
  final String? profilePhotoUrl;
  final List<String> photos;
  final List<String> interests;
  final Timestamp? lastActiveAt;
  final int? iqNormalized;
  final int? eqNormalized;
  final bool profileCompleted;
  final bool testCompleted;
  final bool active;

  final double? compatibilityScore; // 0..1
  final String? compatibilityLabel;
  final List<String>? compatibilityReasons;

  const DiscoverUserModel({
    required this.uid,
    required this.name,
    required this.age,
    this.bio = '',
    this.gender = '',
    this.lookingFor = '',
    this.archetype,
    this.category,
    this.frequencyType,
    this.frequencyScore,
    this.frequencyTags,
    this.profilePhotoUrl,
    this.photos = const [],
    this.interests = const [],
    this.lastActiveAt,
    this.iqNormalized,
    this.eqNormalized,
    this.profileCompleted = false,
    this.testCompleted = false,
    this.active = true,
    this.compatibilityScore,
    this.compatibilityLabel,
    this.compatibilityReasons,
  });

  DiscoverUserModel copyWith({
    String? uid,
    String? name,
    int? age,
    String? bio,
    String? gender,
    String? lookingFor,
    String? archetype,
    String? category,
    String? frequencyType,
    double? frequencyScore,
    List<String>? frequencyTags,
    String? profilePhotoUrl,
    List<String>? photos,
    List<String>? interests,
    Timestamp? lastActiveAt,
    int? iqNormalized,
    int? eqNormalized,
    bool? profileCompleted,
    bool? testCompleted,
    bool? active,
    double? compatibilityScore,
    String? compatibilityLabel,
    List<String>? compatibilityReasons,
  }) {
    return DiscoverUserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      archetype: archetype ?? this.archetype,
      category: category ?? this.category,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyScore: frequencyScore ?? this.frequencyScore,
      frequencyTags: frequencyTags ?? this.frequencyTags,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      iqNormalized: iqNormalized ?? this.iqNormalized,
      eqNormalized: eqNormalized ?? this.eqNormalized,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      testCompleted: testCompleted ?? this.testCompleted,
      active: active ?? this.active,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      compatibilityLabel: compatibilityLabel ?? this.compatibilityLabel,
      compatibilityReasons: compatibilityReasons ?? this.compatibilityReasons,
    );
  }

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
      frequencyType: data['frequency_type'] as String?,
      frequencyScore: (data['frequency_score'] as num?)?.toDouble(),
      frequencyTags: data['frequency_tags'] is List
          ? List<String>.from(data['frequency_tags'] as List)
          : null,
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
