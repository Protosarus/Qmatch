import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/who_liked_you/domain/who_liked_you_card.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';

void main() {
  group('WhoLikedYouCard.fromPublicMap', () {
    test('keeps public identity fields and ignores scoring extras', () {
      final card = WhoLikedYouCard.fromPublicMap({
        'uid': 'u1',
        'name': 'Ada',
        'age': 28,
        'photos': ['https://example.test/a.jpg', ''],
        'profile_photo_url': ' https://example.test/p.jpg ',
        'bio': '  Hello  ',
        'interests': ['Müzik', '', 1, 'Seyahat'],
        'iq': 140,
        'eq': 99,
        'frequency': 'alpha',
        'persona': 'hidden',
        'compatibility_percent': 87,
        'swipe_id': 'secret',
      });

      expect(card, isNotNull);
      expect(card!.uid, 'u1');
      expect(card.name, 'Ada');
      expect(card.age, 28);
      expect(card.photos, ['https://example.test/a.jpg']);
      expect(card.profilePhotoUrl, 'https://example.test/p.jpg');
      expect(card.primaryPhotoUrl, 'https://example.test/p.jpg');
      expect(card.bio, 'Hello');
      expect(card.interests, ['Müzik', 'Seyahat']);
    });

    test('fail-closes invalid identity rows', () {
      expect(WhoLikedYouCard.fromPublicMap(null), isNull);
      expect(WhoLikedYouCard.fromPublicMap('bad'), isNull);
      expect(
        WhoLikedYouCard.fromPublicMap({'uid': '', 'name': 'Ada', 'age': 28}),
        isNull,
      );
      expect(
        WhoLikedYouCard.fromPublicMap({'uid': 'u1', 'name': '  ', 'age': 28}),
        isNull,
      );
      expect(
        WhoLikedYouCard.fromPublicMap({'uid': 'u1', 'name': 'Ada', 'age': 17}),
        isNull,
      );
      expect(
        WhoLikedYouCard.fromPublicMap({'uid': 'u1', 'name': 'Ada'}),
        isNull,
      );
    });
  });

  group('WhoLikedYouClient', () {
    test('invokes listWhoLikedYou and maps entitled public cards', () async {
      String? called;
      final client = WhoLikedYouClient(
        call: (name, data) async {
          called = name;
          expect(data, isEmpty);
          return {
            'resonance_access': true,
            'items': [
              {
                'uid': 'a',
                'name': 'Ada',
                'age': 28,
                'photos': <String>[],
                'bio': 'Hi',
                'interests': <String>['Müzik'],
              },
              {
                'uid': 'a',
                'name': 'Dup',
                'age': 30,
                'photos': <String>[],
                'bio': '',
                'interests': <String>[],
              },
              {
                'uid': 'bad',
                'name': 'Teen',
                'age': 16,
                'photos': <String>[],
                'bio': '',
                'interests': <String>[],
              },
              {
                'uid': 'b',
                'name': 'Maya',
                'age': 31,
                'photos': <String>[],
                'bio': '',
                'interests': <String>[],
                'compatibility_percent': 92,
              },
            ],
          };
        },
      );

      final result = await client.list();
      expect(called, WhoLikedYouClient.callableName);
      expect(result.resonanceAccess, isTrue);
      expect(result.items.map((c) => c.uid), ['a', 'b']);
      expect(result.items.first.interests, ['Müzik']);
    });

    test('non-true resonance_access is locked and drops identities', () async {
      final client = WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': false,
          'items': [
            {
              'uid': 'leaked',
              'name': 'ShouldNotSee',
              'age': 29,
              'photos': <String>[],
              'bio': 'secret',
              'interests': <String>['Müzik'],
            },
          ],
        },
      );

      final result = await client.list();
      expect(result.resonanceAccess, isFalse);
      expect(result.items, isEmpty);
    });

    test('missing access flag is locked even if items are present', () async {
      final client = WhoLikedYouClient(
        call: (_, __) async => {
          'items': [
            {
              'uid': 'leaked',
              'name': 'ShouldNotSee',
              'age': 29,
              'photos': <String>[],
              'bio': '',
              'interests': <String>[],
            },
          ],
        },
      );

      final result = await client.list();
      expect(identical(result, WhoLikedYouResult.locked), isTrue);
      expect(result.items, isEmpty);
    });

    test('entitled non-list items becomes an empty inbox', () async {
      final client = WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': 'bad',
        },
      );

      final result = await client.list();
      expect(result.resonanceAccess, isTrue);
      expect(result.items, isEmpty);
    });
  });
}
