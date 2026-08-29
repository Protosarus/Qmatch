import 'package:cloud_firestore/cloud_firestore.dart';

import '../../assessment/utils/assessment_result_display_resolver.dart';

/// Read model for Discover feed — maps `public_profiles/{uid}` snapshots.
/// Private `users/{uid}` account/assessment fields are absent on this path.
class DiscoverUserModel {
  final String uid;
  final String name;
  final int age;
  final String bio;
  final String gender;
  final String lookingFor;
  final String education;
  final String? occupation;
  final String? company;
  final String? school;
  final String? educationField;
  final String? anthemTitle;
  final String? anthemArtist;
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

  /// Flow-v2 assessment battery completion (existing flag; not a new gate).
  final bool assessmentFlowCompleted;
  final bool active;

  /// Backend-authored public eligibility. Missing/non-true is false.
  final bool discoverEligible;

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
    this.education = '',
    this.occupation,
    this.company,
    this.school,
    this.educationField,
    this.anthemTitle,
    this.anthemArtist,
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
    this.assessmentFlowCompleted = false,
    this.active = true,
    this.discoverEligible = false,
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
    String? education,
    String? occupation,
    String? company,
    String? school,
    String? educationField,
    String? anthemTitle,
    String? anthemArtist,
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
    bool? assessmentFlowCompleted,
    bool? active,
    bool? discoverEligible,
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
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      school: school ?? this.school,
      educationField: educationField ?? this.educationField,
      anthemTitle: anthemTitle ?? this.anthemTitle,
      anthemArtist: anthemArtist ?? this.anthemArtist,
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
      assessmentFlowCompleted:
          assessmentFlowCompleted ?? this.assessmentFlowCompleted,
      active: active ?? this.active,
      discoverEligible: discoverEligible ?? this.discoverEligible,
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

  /// Compatibility hint labels (no raw IQ/EQ category codes in UI).
  String get compatibilityHint {
    if (category != null && category!.isNotEmpty) {
      return AssessmentResultDisplayResolver.resolveIqEqLevel(
        category!,
        languageCode: 'en',
      ).title;
    }
    if (archetype != null && archetype!.isNotEmpty) {
      return AssessmentResultDisplayResolver.resolveArchetypeLabel(
        archetype!,
        languageCode: 'en',
      ).title;
    }
    if (iqNormalized != null || eqNormalized != null) {
      return 'Mindset-aligned';
    }
    return 'Compatible profile';
  }

  /// Localized compatibility hint for UI.
  String compatibilityHintLocalized(String? languageCode) {
    if (category != null && category!.isNotEmpty) {
      return AssessmentResultDisplayResolver.resolveIqEqLevel(
        category!,
        languageCode: languageCode,
      ).title;
    }
    if (archetype != null && archetype!.isNotEmpty) {
      return AssessmentResultDisplayResolver.resolveArchetypeLabel(
        archetype!,
        languageCode: languageCode,
      ).title;
    }
    final lang = (languageCode ?? 'en').toLowerCase();
    if (iqNormalized != null || eqNormalized != null) {
      return lang == 'tr' ? 'Zihin uyumu' : 'Mindset-aligned';
    }
    return lang == 'tr' ? 'Uyumlu profil' : 'Compatible profile';
  }

  factory DiscoverUserModel.fromFirestore(
      String uid, Map<String, dynamic> data) {
    final photosList = List<String>.from(data['photos'] ?? const []);
    return DiscoverUserModel(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      age: (data['age'] as num?)?.toInt() ?? 18,
      bio: (data['bio'] as String?)?.trim() ?? '',
      gender: (data['gender'] as String?)?.trim() ?? '',
      lookingFor: (data['looking_for'] as String?)?.trim() ?? '',
      education: (data['education'] as String?)?.trim() ?? '',
      occupation: (data['occupation'] as String?)?.trim(),
      company: (data['company'] as String?)?.trim(),
      school: (data['school'] as String?)?.trim(),
      educationField: (data['education_field'] as String?)?.trim(),
      anthemTitle: (data['anthem_title'] as String?)?.trim(),
      anthemArtist: (data['anthem_artist'] as String?)?.trim(),
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
      assessmentFlowCompleted:
          data['assessment_flow_completed'] as bool? ?? false,
      active: data['active'] as bool? ?? true,
      discoverEligible: data['discover_eligible'] == true,
    );
  }
}
