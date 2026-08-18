/// Public Who Liked You card from trusted `listWhoLikedYou`.
///
/// Only identity/profile fields the callable is allowed to return.
/// Never carries IQ/EQ/Frequency/Persona, swipe/block, or compatibility.
class WhoLikedYouCard {
  const WhoLikedYouCard({
    required this.uid,
    required this.name,
    required this.age,
    required this.photos,
    required this.bio,
    required this.interests,
    this.profilePhotoUrl,
    this.superResonance = false,
  });

  final String uid;
  final String name;
  final int age;
  final List<String> photos;
  final String? profilePhotoUrl;
  final String bio;
  final List<String> interests;
  final bool superResonance;

  String? get primaryPhotoUrl {
    final primary = profilePhotoUrl?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    for (final url in photos) {
      if (url.trim().isNotEmpty) return url.trim();
    }
    return null;
  }

  /// Fail-closed parse. Extra keys ignored. Invalid cards return null.
  static WhoLikedYouCard? fromPublicMap(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final uid = data['uid'];
    if (uid is! String || uid.trim().isEmpty) return null;
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final ageNum = data['age'] is num ? (data['age'] as num).toInt() : null;
    if (ageNum == null || ageNum < 18) return null;

    return WhoLikedYouCard(
      uid: uid.trim(),
      name: name.trim(),
      age: ageNum,
      photos: _stringList(data['photos']),
      profilePhotoUrl: data['profile_photo_url'] is String
          ? (data['profile_photo_url'] as String).trim()
          : null,
      bio: data['bio'] is String ? (data['bio'] as String).trim() : '',
      interests: _stringList(data['interests']),
      superResonance: data['super_resonance'] == true,
    );
  }

  WhoLikedYouCard copyWith({bool? superResonance}) {
    return WhoLikedYouCard(
      uid: uid,
      name: name,
      age: age,
      photos: photos,
      bio: bio,
      interests: interests,
      profilePhotoUrl: profilePhotoUrl,
      superResonance: superResonance ?? this.superResonance,
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

/// Trusted callable result. Free / forged access never includes identities.
class WhoLikedYouResult {
  const WhoLikedYouResult({
    required this.resonanceAccess,
    required this.items,
  });

  final bool resonanceAccess;
  final List<WhoLikedYouCard> items;

  static const locked = WhoLikedYouResult(
    resonanceAccess: false,
    items: [],
  );
}
