import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/services/match_live_user_validity_gate.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';

UserProfileModel _base({
  List<String> photos = const [],
  String? profilePhotoUrl,
}) {
  return UserProfileModel(
    userId: 'u1',
    name: 'Ada',
    age: 28,
    gender: 'female',
    education: 'uni',
    bio: 'hi',
    interests: const ['art'],
    lookingFor: 'serious',
    ageRange: const [24, 35],
    distancePreference: 40,
    photos: photos,
    profilePhotoUrl: profilePhotoUrl,
    profileCompleted: true,
  );
}

void main() {
  group('photo_removal_eligibility_revoke_v1', () {
    test('remove last photo clears primary URL in merge payload', () {
      final withPhoto = _base(
        photos: const ['https://example.com/a.jpg'],
        profilePhotoUrl: 'https://example.com/a.jpg',
      );
      // Mirrors profile_photo_edit_screen._savePhotos after deleting last.
      final cleared = withPhoto.copyWith(photos: const [], profilePhotoUrl: null);
      expect(cleared.profilePhotoUrl, isNull);
      expect(cleared.photos, isEmpty);

      final map = cleared.toFirestore();
      expect(map['photos'], isEmpty);
      expect(map['profile_photo_url'], '');
    });

    test('explicit empty photos + null primary writes empty string (not omit)',
        () {
      final map = _base(photos: const [], profilePhotoUrl: null).toFirestore();
      expect(map.containsKey('profile_photo_url'), isTrue);
      expect(map['profile_photo_url'], '');
    });

    test('empty photos + stale primary in model would still write URL — '
        'copyWith null is required to clear', () {
      // Demonstrates why copyWith must accept explicit null.
      final staleKept = _base(
        photos: const ['https://example.com/a.jpg'],
        profilePhotoUrl: 'https://example.com/a.jpg',
      ).copyWith(photos: const []);
      // Without explicit null, primary is preserved by copyWith.
      expect(staleKept.profilePhotoUrl, 'https://example.com/a.jpg');

      final cleared = _base(
        photos: const ['https://example.com/a.jpg'],
        profilePhotoUrl: 'https://example.com/a.jpg',
      ).copyWith(photos: const [], profilePhotoUrl: null);
      expect(cleared.toFirestore()['profile_photo_url'], '');
    });

    test('replace primary photo updates profile_photo_url', () {
      final replaced = _base(
        photos: const [
          'https://example.com/new.jpg',
          'https://example.com/old.jpg',
        ],
        profilePhotoUrl: 'https://example.com/new.jpg',
      );
      final map = replaced.toFirestore();
      expect(map['profile_photo_url'], 'https://example.com/new.jpg');
      expect((map['photos'] as List).length, 2);
      expect(
        MatchLiveUserValidityGate.hasValidPhoto(map),
        isTrue,
      );
    });

    test('remove one of multiple photos keeps hasPhoto', () {
      final remaining = _base(
        photos: const ['https://example.com/b.jpg'],
        profilePhotoUrl: 'https://example.com/b.jpg',
      ).toFirestore();
      expect(MatchLiveUserValidityGate.hasValidPhoto(remaining), isTrue);
      expect(remaining['photos'], ['https://example.com/b.jpg']);
      expect(remaining['profile_photo_url'], 'https://example.com/b.jpg');
    });

    test('legacy valid photo-only profile keeps primary URL', () {
      final legacy = _base(
        photos: const [],
        profilePhotoUrl: 'https://example.com/legacy.jpg',
      ).toFirestore();
      expect(legacy['photos'], isEmpty);
      expect(legacy['profile_photo_url'], 'https://example.com/legacy.jpg');
      expect(MatchLiveUserValidityGate.hasValidPhoto(legacy), isTrue);
    });

    test('eligibility revoke after last-photo removal (live gate + CF inputs)',
        () {
      final afterClear = <String, dynamic>{
        'discover_eligible': true,
        'active': true,
        'profile_completed': true,
        'test_completed': true,
        'assessment_flow_completed': true,
        'photos': <String>[],
        'profile_photo_url': '',
      };
      expect(MatchLiveUserValidityGate.hasValidPhoto(afterClear), isFalse);
      // Live match gate also requires discover_eligible; CF would set false.
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: afterClear,
        ),
        isFalse,
      );
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: {
            ...afterClear,
            'discover_eligible': false,
          },
        ),
        isFalse,
      );
    });
  });
}
