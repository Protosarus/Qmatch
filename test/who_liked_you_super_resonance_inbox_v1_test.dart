import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/who_liked_you/domain/alignment_signal_merge.dart';
import 'package:qmatch/features/who_liked_you/domain/who_liked_you_card.dart';
import 'package:qmatch/features/who_liked_you/screens/who_liked_you_screen.dart';
import 'package:qmatch/features/who_liked_you/services/super_resonance_inbox_client.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('mergeAlignmentSignals', () {
    test('Super Resonance sorts above ordinary and wins duplicates', () {
      final merged = mergeAlignmentSignals(
        superResonance: [
          _card('super1', name: 'Ada', superResonance: true),
          _card('both', name: 'Both Super', superResonance: true),
        ],
        ordinary: [
          _card('like1', name: 'Maya'),
          _card('both', name: 'Both Like'),
        ],
      );
      expect(merged.map((c) => c.uid), ['super1', 'both', 'like1']);
      expect(merged[0].superResonance, isTrue);
      expect(merged[1].superResonance, isTrue);
      expect(merged[1].name, 'Both Super');
      expect(merged[2].superResonance, isFalse);
    });
  });

  group('SuperResonanceInboxClient', () {
    test('maps public cards and drops private fields', () async {
      String? called;
      final client = SuperResonanceInboxClient(
        call: (name, data) async {
          called = name;
          expect(data, isEmpty);
          return {
            'items': [
              _superPayload('a', name: 'Ada'),
              _superPayload('a', name: 'Dup'),
              {
                'uid': 'bad',
                'name': 'Teen',
                'age': 16,
                'super_resonance': true,
              },
            ],
          };
        },
      );
      final items = await client.list();
      expect(called, SuperResonanceInboxClient.callableName);
      expect(items.map((c) => c.uid), ['a']);
      expect(items.single.superResonance, isTrue);
      expect(items.single.name, 'Ada');
    });
  });

  group('Alignment Signals Super Resonance receiver UI', () {
    testWidgets('Free sees Super Resonance identity but no ordinary likes',
        (tester) async {
      await _pump(
        tester,
        ordinary: {
          'resonance_access': false,
          'items': [
            _ordinaryPayload('leaked', name: 'ShouldNotSee'),
          ],
        },
        superItems: [
          _superPayload('u1', name: 'Ada', age: 28),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qmatch-who-liked-you-list')), findsOneWidget);
      expect(find.text('Ada, 28'), findsOneWidget);
      expect(find.text('Super Resonance'), findsWidgets);
      expect(
        find.byKey(const Key('qmatch-who-liked-you-super-marker-u1')),
        findsOneWidget,
      );
      expect(find.text('ShouldNotSee'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byKey(const Key('qmatch-who-liked-you-free-discovery')),
          findsNothing);
      expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsNothing);
    });

    testWidgets('Resonance sees Super Resonance above ordinary likes',
        (tester) async {
      await _pump(
        tester,
        ordinary: {
          'resonance_access': true,
          'items': [
            _ordinaryPayload('u2', name: 'Maya', age: 31),
          ],
        },
        superItems: [
          _superPayload('u1', name: 'Ada', age: 28),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Ada, 28'), findsOneWidget);
      expect(find.text('Maya, 31'), findsOneWidget);
      final ada = tester.getTopLeft(find.text('Ada, 28'));
      final maya = tester.getTopLeft(find.text('Maya, 31'));
      expect(ada.dy < maya.dy, isTrue);
      expect(
        find.byKey(const Key('qmatch-who-liked-you-super-marker-u1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-who-liked-you-super-marker-u2')),
        findsNothing,
      );
    });

    testWidgets('duplicate sender collapses to one Super Resonance card',
        (tester) async {
      await _pump(
        tester,
        ordinary: {
          'resonance_access': true,
          'items': [
            _ordinaryPayload('u1', name: 'Ada Like', age: 28),
            _ordinaryPayload('u2', name: 'Maya', age: 31),
          ],
        },
        superItems: [
          _superPayload('u1', name: 'Ada Super', age: 28),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsOneWidget);
      expect(find.text('Ada Super, 28'), findsOneWidget);
      expect(find.text('Ada Like, 28'), findsNothing);
      expect(
        find.byKey(const Key('qmatch-who-liked-you-super-marker-u1')),
        findsOneWidget,
      );
      expect(find.text('Maya, 31'), findsOneWidget);
    });

    testWidgets('Like and Pass work on Super Resonance cards', (tester) async {
      final liked = <String>[];
      final passed = <String>[];
      await _pump(
        tester,
        ordinary: {
          'resonance_access': true,
          'items': [
            _ordinaryPayload('u2', name: 'Maya', age: 31),
          ],
        },
        superItems: [
          _superPayload('u1', name: 'Ada', age: 28),
        ],
        likeUser: (uid) async {
          liked.add(uid);
          return LikeMatchOutcome.noMatch;
        },
        passUser: (uid) async => passed.add(uid),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
      await tester.pumpAndSettle();
      expect(liked, ['u1']);
      expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsNothing);
      expect(find.byKey(const Key('qmatch-who-liked-you-card-u2')), findsOneWidget);

      await tester.tap(find.byKey(const Key('qmatch-who-liked-you-pass-u2')));
      await tester.pumpAndSettle();
      expect(passed, ['u2']);
      expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
    });

    testWidgets('Like match-success reuses Discover match UX', (tester) async {
      await _pump(
        tester,
        ordinary: {
          'resonance_access': false,
          'items': <Map<String, dynamic>>[],
        },
        superItems: [
          _superPayload('u1', name: 'Ada', age: 28),
        ],
        likeUser: (_) async => LikeMatchOutcome.createdNewMatch,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsOneWidget);
      expect(find.text("It's a match"), findsOneWidget);
      expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsNothing);

      await tester.tap(find.byKey(const Key('qmatch-discover-match-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
    });

    testWidgets('no private or scoring fields appear', (tester) async {
      await _pump(
        tester,
        ordinary: {
          'resonance_access': true,
          'items': [
            _ordinaryPayload('u2', name: 'Maya', age: 31),
          ],
        },
        superItems: [
          _superPayload('u1', name: 'Ada', age: 28),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('IQ'), findsNothing);
      expect(find.textContaining('EQ'), findsNothing);
      expect(find.textContaining('Frequency'), findsNothing);
      expect(find.textContaining('Persona'), findsNothing);
      expect(find.textContaining('canonical'), findsNothing);
      expect(find.text('secret@example.com'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });
  });
}

WhoLikedYouCard _card(
  String uid, {
  required String name,
  bool superResonance = false,
}) {
  return WhoLikedYouCard(
    uid: uid,
    name: name,
    age: 28,
    photos: const [],
    bio: '',
    interests: const [],
    superResonance: superResonance,
  );
}

Map<String, dynamic> _ordinaryPayload(
  String uid, {
  String name = 'Maya',
  int age = 31,
}) {
  return {
    'uid': uid,
    'name': name,
    'age': age,
    'photos': <String>[],
    'bio': 'Loves jazz',
    'interests': <String>['Müzik'],
    'iq': 140,
    'compatibility_percent': 87,
  };
}

Map<String, dynamic> _superPayload(
  String uid, {
  String name = 'Ada',
  int age = 28,
}) {
  return {
    'uid': uid,
    'name': name,
    'age': age,
    'photos': <String>[],
    'profile_photo_url': 'https://example.test/p.jpg',
    'bio': 'Loves jazz',
    'interests': <String>['Müzik'],
    'super_resonance': true,
    'created_at': 12,
    'iq': 140,
    'eq': 90,
    'frequency_type': 'secret',
    'persona': 'hidden',
    'canonical_v1': {'secret': true},
    'email': 'secret@example.com',
    'compatibility_percent': 99,
  };
}

Future<void> _pump(
  WidgetTester tester, {
  required Map<String, dynamic> ordinary,
  required List<Map<String, dynamic>> superItems,
  Future<LikeMatchOutcome> Function(String uid)? likeUser,
  Future<void> Function(String uid)? passUser,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WhoLikedYouScreen(
        client: WhoLikedYouClient(call: (_, __) async => ordinary),
        superResonanceInbox: SuperResonanceInboxClient(
          call: (_, __) async => {'items': superItems},
        ),
        likeUser: likeUser ?? ((_) async => LikeMatchOutcome.noMatch),
        passUser: passUser ?? ((_) async {}),
        onUnlock: () async {},
        currentUidProvider: () => 'me',
        animateBackground: false,
      ),
    ),
  );
  await tester.pump();
}
