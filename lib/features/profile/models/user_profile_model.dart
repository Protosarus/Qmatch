import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UserProfileModel {
  final String userId;
  final String name;
  final int age;
  final String gender;
  final GeoPoint? location; // Artık opsiyonel
  final String? locationText;
  final String education;
  final String bio;
  final List<String> interests;

  // Yaşam tarzı / work & education details
  final String? occupation;
  final String? company;
  final String? school;
  final String? educationField;
  final String? anthemTitle;
  final String? anthemArtist;
  final String? anthemExternalUrl;
  final String? drinking;
  final String? smoking;
  final String? pets;
  final String? children;
  final String? religion;
  final String? animalLove;

  // Ne arıyorum?
  final String lookingFor;
  final List<int> ageRange;
  final int distancePreference;

  // Fotoğraflar
  final List<String> photos;
  final String? profilePhotoUrl;

  // Test Results (sadece arketip gösterilecek, IQ/EQ skorları gizli)
  final String? archetype; // Arketip ismi (örn: "Vizyon Lideri")
  final String? category; // HH, HM, HL, MH, MM, ML, LH, LM, LL

  // Meta
  final bool profileCompleted;
  final bool verified;
  final DateTime? completedAt;

  const UserProfileModel({
    required this.userId,
    required this.name,
    required this.age,
    required this.gender,
    this.location,
    this.locationText,
    required this.education,
    required this.bio,
    required this.interests,
    this.occupation,
    this.company,
    this.school,
    this.educationField,
    this.anthemTitle,
    this.anthemArtist,
    this.anthemExternalUrl,
    this.drinking,
    this.smoking,
    this.pets,
    this.children,
    this.religion,
    this.animalLove,
    required this.lookingFor,
    required this.ageRange,
    required this.distancePreference,
    this.photos = const [],
    this.profilePhotoUrl,
    this.archetype,
    this.category,
    this.profileCompleted = false,
    this.verified = false,
    this.completedAt,
  });

  /// Non-empty trimmed photo URLs in [photos].
  static List<String> nonEmptyPhotoUrls(List<String> photos) {
    return [
      for (final p in photos)
        if (p.trim().isNotEmpty) p.trim(),
    ];
  }

  /// Primary photo field for Firestore merge writes.
  ///
  /// - Prefer non-empty [photos] (primary = [profilePhotoUrl] if still in list,
  ///   else first photo).
  /// - Else keep a non-empty [profilePhotoUrl] (legacy photo-only profiles).
  /// - Else write `''` so merge clears a stale primary URL when all photos
  ///   were removed (`photo_removal_eligibility_revoke_v1`).
  static String profilePhotoUrlForWrite({
    required List<String> photos,
    required String? profilePhotoUrl,
  }) {
    final validPhotos = nonEmptyPhotoUrls(photos);
    final primary = profilePhotoUrl?.trim() ?? '';
    if (validPhotos.isNotEmpty) {
      if (primary.isNotEmpty && validPhotos.contains(primary)) {
        return primary;
      }
      return validPhotos.first;
    }
    if (primary.isNotEmpty) return primary;
    return '';
  }

  /// Profile setup / edit payload for `users/{uid}`.
  ///
  /// P1B-1: optional nulls are **omitted** so merge writes cannot erase
  /// assessment-derived fields (`archetype`, `category`, persona mirrors, etc.).
  /// Explicit `false` / `0` values are still written.
  ///
  /// Photo fields are always written: empty [photos] + null/empty primary
  /// clears `profile_photo_url` to `''` so Discover eligibility can revoke.
  Map<String, dynamic> toFirestore() {
    // P2C-1C-4A: never merge-write an empty `name` (would erase the
    // canonical display name collected by DisplayNameService).
    final trimmedName = name.trim();
    return {
      if (trimmedName.isNotEmpty) 'name': trimmedName,
      'age': age,
      'gender': gender,
      if (location != null) 'location': location,
      if (locationText != null) 'location_text': locationText,
      'education': education,
      'bio': bio,
      'interests': interests,
      if (occupation != null) 'occupation': occupation,
      if (company != null) 'company': company,
      if (school != null) 'school': school,
      if (educationField != null) 'education_field': educationField,
      if (anthemTitle != null) 'anthem_title': anthemTitle,
      if (anthemArtist != null) 'anthem_artist': anthemArtist,
      if (anthemExternalUrl != null) 'anthem_external_url': anthemExternalUrl,
      if (drinking != null) 'drinking': drinking,
      if (smoking != null) 'smoking': smoking,
      if (pets != null) 'pets': pets,
      if (children != null) 'children': children,
      if (religion != null) 'religion': religion,
      if (animalLove != null) 'animal_love': animalLove,
      'looking_for': lookingFor,
      'age_range': ageRange,
      'distance_preference': distancePreference,
      'photos': photos,
      'profile_photo_url': profilePhotoUrlForWrite(
        photos: photos,
        profilePhotoUrl: profilePhotoUrl,
      ),
      // Assessment-derived legacy mirrors: never write null (omit instead).
      if (archetype != null) 'archetype': archetype,
      if (category != null) 'category': category,
      'profile_completed': profileCompleted,
      'verified': verified,
      if (completedAt != null) 'completed_at': completedAt,
    };
  }

  factory UserProfileModel.fromFirestore(
      Map<String, dynamic> data, String userId) {
    return UserProfileModel(
      userId: userId,
      name: data['name'] ?? '',
      age: data['age'] ?? 18,
      gender: data['gender'] ?? '',
      location: data['location'] as GeoPoint?,
      locationText: data['location_text'],
      education: data['education'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      occupation: data['occupation'],
      company: data['company'],
      school: data['school'],
      educationField: data['education_field'],
      anthemTitle: data['anthem_title'],
      anthemArtist: data['anthem_artist'],
      anthemExternalUrl: data['anthem_external_url'],
      drinking: data['drinking'],
      smoking: data['smoking'],
      pets: data['pets'],
      children: data['children'],
      religion: data['religion'],
      animalLove: data['animal_love'],
      lookingFor: data['looking_for'] ?? '',
      ageRange: List<int>.from(data['age_range'] ?? [18, 80]),
      distancePreference: data['distance_preference'] ?? 50,
      photos: List<String>.from(data['photos'] ?? []),
      profilePhotoUrl: data['profile_photo_url'],
      archetype: data['archetype'],
      category: data['category'],
      profileCompleted: data['profile_completed'] ?? false,
      verified: data['verified'] ?? false,
      completedAt: data['completed_at']?.toDate(),
    );
  }

  static GeoPoint fromPosition(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  static const Object _unset = Object();

  UserProfileModel copyWith({
    String? name,
    int? age,
    String? gender,
    GeoPoint? location,
    String? locationText,
    String? education,
    String? bio,
    List<String>? interests,
    String? occupation,
    String? company,
    String? school,
    String? educationField,
    String? anthemTitle,
    String? anthemArtist,
    String? anthemExternalUrl,
    String? drinking,
    String? smoking,
    String? pets,
    String? children,
    String? religion,
    String? animalLove,
    String? lookingFor,
    List<int>? ageRange,
    int? distancePreference,
    List<String>? photos,
    Object? profilePhotoUrl = _unset,
    String? archetype,
    String? category,
    bool? profileCompleted,
    bool? verified,
    DateTime? completedAt,
  }) {
    return UserProfileModel(
      userId: userId,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      locationText: locationText ?? this.locationText,
      education: education ?? this.education,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      school: school ?? this.school,
      educationField: educationField ?? this.educationField,
      anthemTitle: anthemTitle ?? this.anthemTitle,
      anthemArtist: anthemArtist ?? this.anthemArtist,
      anthemExternalUrl: anthemExternalUrl ?? this.anthemExternalUrl,
      drinking: drinking ?? this.drinking,
      smoking: smoking ?? this.smoking,
      pets: pets ?? this.pets,
      children: children ?? this.children,
      religion: religion ?? this.religion,
      animalLove: animalLove ?? this.animalLove,
      lookingFor: lookingFor ?? this.lookingFor,
      ageRange: ageRange ?? this.ageRange,
      distancePreference: distancePreference ?? this.distancePreference,
      photos: photos ?? this.photos,
      // Allow explicit null to clear primary after last-photo removal.
      profilePhotoUrl: identical(profilePhotoUrl, _unset)
          ? this.profilePhotoUrl
          : profilePhotoUrl as String?,
      archetype: archetype ?? this.archetype,
      category: category ?? this.category,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      verified: verified ?? this.verified,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
