import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/who_liked_you/domain/who_liked_you_card.dart';
import 'package:qmatch/features/who_liked_you/screens/who_liked_you_screen.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows loading until the callable returns', (tester) async {
    final gate = Completer<Map<String, dynamic>>();
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(call: (_, __) => gate.future),
    );

    expect(
        find.byKey(const Key('qmatch-who-liked-you-loading')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-who-liked-you-list')), findsNothing);

    gate.complete({
      'resonance_access': true,
      'items': <Map<String, dynamic>>[],
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
  });

  testWidgets('locked state hides identities and shows Resonance unlock only',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': false,
          'items': [
            {
              'uid': 'leaked',
              'name': 'ShouldNotSee',
              'age': 29,
              'photos': <String>[],
              'bio': 'hidden bio',
              'interests': <String>['Müzik'],
            },
          ],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('qmatch-who-liked-you-locked')), findsOneWidget);
    expect(find.text('See who aligned with you'), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-unlock')), findsOneWidget);
    expect(find.text('Unlock with Resonance'), findsOneWidget);
    expect(find.text('ShouldNotSee'), findsNothing);
    expect(find.text('hidden bio'), findsNothing);
    expect(find.text('Music'), findsNothing);
    expect(find.text('Like'), findsNothing);
    expect(find.text('Pass'), findsNothing);
    expect(find.byKey(const Key('qmatch-who-liked-you-list')), findsNothing);
  });

  testWidgets('screen fail-closes leaked identities when access is false',
      (tester) async {
    await _pumpScreen(
      tester,
      client: _LeakyLockedClient(),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('qmatch-who-liked-you-locked')), findsOneWidget);
    expect(find.text('SecretName'), findsNothing);
    expect(find.text('hidden bio'), findsNothing);
  });

  testWidgets('entitled cards show photo, name, age, bio, interests only',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [_publicCard('u1', name: 'Ada', age: 28)],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-who-liked-you-list')), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsOneWidget);
    expect(find.text('Ada, 28'), findsOneWidget);
    expect(find.text('Loves jazz'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-like-u1')), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-pass-u1')), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('IQ'), findsNothing);
    expect(find.textContaining('EQ'), findsNothing);
    expect(find.textContaining('Frequency'), findsNothing);
    expect(find.textContaining('Persona'), findsNothing);
    expect(find.byKey(const Key('qmatch-who-liked-you-locked')), findsNothing);
  });

  testWidgets('entitled empty inbox shows empty state without unlock CTA',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': <Map<String, dynamic>>[],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
    expect(find.text('No one has liked you yet'), findsOneWidget);
    expect(find.byKey(const Key('qmatch-who-liked-you-unlock')), findsNothing);
    expect(find.text('Like'), findsNothing);
  });

  testWidgets('error state retries the callable', (tester) async {
    var calls = 0;
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async {
          calls++;
          if (calls == 1) throw StateError('boom');
          return {
            'resonance_access': true,
            'items': <Map<String, dynamic>>[],
          };
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-who-liked-you-error')), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
  });

  testWidgets('Pass uses injected flow and removes the card locally',
      (tester) async {
    final passed = <String>[];
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [
            _publicCard('u1'),
            _publicCard('u2', name: 'Maya', age: 31),
          ],
        },
      ),
      passUser: (uid) async => passed.add(uid),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-pass-u1')));
    await tester.pumpAndSettle();

    expect(passed, ['u1']);
    expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsNothing);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-card-u2')), findsOneWidget);
    expect(find.text('Maya, 31'), findsOneWidget);
  });

  testWidgets('Like without match removes the card and skips the match dialog',
      (tester) async {
    final liked = <String>[];
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [_publicCard('u1')],
        },
      ),
      likeUser: (uid) async {
        liked.add(uid);
        return LikeMatchOutcome.noMatch;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
    await tester.pumpAndSettle();

    expect(liked, ['u1']);
    expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsNothing);
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
  });

  testWidgets('Like that creates a match reuses Discover match-success UX',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [_publicCard('u1')],
        },
      ),
      likeUser: (_) async => LikeMatchOutcome.createdNewMatch,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('qmatch-discover-match-dialog')), findsOneWidget);
    expect(find.text("It's a match"), findsOneWidget);
    expect(find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsNothing);

    await tester.tap(find.byKey(const Key('qmatch-discover-match-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
  });

  testWidgets('existing active match does not show the success dialog',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [_publicCard('u1')],
        },
      ),
      likeUser: (_) async => LikeMatchOutcome.existingActiveMatch,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
  });

  testWidgets('failed Like keeps the card and shows the action error',
      (tester) async {
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => {
          'resonance_access': true,
          'items': [_publicCard('u1')],
        },
      ),
      likeUser: (_) async => throw StateError('like failed'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-like-u1')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('qmatch-who-liked-you-card-u1')), findsOneWidget);
    expect(
      find.text("That action couldn't be completed. Please try again."),
      findsOneWidget,
    );
  });

  testWidgets('unlock CTA reloads after the injected unlock completes',
      (tester) async {
    var entitled = false;
    var unlocked = 0;
    await _pumpScreen(
      tester,
      client: WhoLikedYouClient(
        call: (_, __) async => entitled
            ? {
                'resonance_access': true,
                'items': <Map<String, dynamic>>[],
              }
            : {
                'resonance_access': false,
                'items': <Map<String, dynamic>>[],
              },
      ),
      onUnlock: () async {
        unlocked++;
        entitled = true;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('qmatch-who-liked-you-unlock')));
    await tester.pumpAndSettle();

    expect(unlocked, 1);
    expect(find.byKey(const Key('qmatch-who-liked-you-empty')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-who-liked-you-locked')), findsNothing);
  });

  group('wiring (source)', () {
    test('Like/Pass and match-success reuse trusted Discover paths', () {
      final src = File(
        'lib/features/who_liked_you/screens/who_liked_you_screen.dart',
      ).readAsStringSync();
      expect(src.contains('SwipeService().likeUser'), isTrue);
      expect(src.contains('SwipeService().passUser'), isTrue);
      expect(src.contains('LikeMatchOutcome.createdNewMatch'), isTrue);
      expect(src.contains('showQMatchDiscoverMatchDialog'), isTrue);
      expect(src.contains('DiscoverMatchDialogAction.openChat'), isTrue);
      expect(src.contains('ChatDetailScreen'), isTrue);
      expect(src.contains('ResonancePaywallScreen.open'), isTrue);
      expect(src.contains('ResonancePaywallFeature.whoLikedYou'), isTrue);
      expect(src.contains('LikeMatchOutcome.existingActiveMatch'), isFalse);
      expect(src.contains('compatibility'), isFalse);
      expect(src.toLowerCase().contains('qmatchcandidatecard'), isFalse);
    });

    test('Who Liked You is not a bottom-nav tab', () {
      const paths = [
        'lib/core/navigation/main_navigation_screen.dart',
        'lib/core/navigation/qmatch_main_shell.dart',
      ];
      for (final path in paths) {
        expect(
          File(path).readAsStringSync().contains('WhoLikedYouScreen'),
          isFalse,
          reason: path,
        );
      }
    });
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required WhoLikedYouClient client,
  Future<LikeMatchOutcome> Function(String uid)? likeUser,
  Future<void> Function(String uid)? passUser,
  Future<void> Function()? onUnlock,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WhoLikedYouScreen(
        client: client,
        likeUser: likeUser ?? ((_) async => LikeMatchOutcome.noMatch),
        passUser: passUser ?? ((_) async {}),
        onUnlock: onUnlock ?? () async {},
        currentUidProvider: () => 'me',
        animateBackground: false,
      ),
    ),
  );
  await tester.pump();
}

Map<String, dynamic> _publicCard(
  String uid, {
  String name = 'Ada',
  int age = 28,
}) {
  return {
    'uid': uid,
    'name': name,
    'age': age,
    'photos': <String>[],
    'bio': 'Loves jazz',
    'interests': <String>['Müzik'],
    'iq': 140,
    'eq': 90,
    'compatibility_percent': 87,
  };
}

class _LeakyLockedClient extends WhoLikedYouClient {
  @override
  Future<WhoLikedYouResult> list() async {
    return const WhoLikedYouResult(
      resonanceAccess: false,
      items: [
        WhoLikedYouCard(
          uid: 'secret',
          name: 'SecretName',
          age: 29,
          photos: [],
          bio: 'hidden bio',
          interests: ['Müzik'],
        ),
      ],
    );
  }
}
