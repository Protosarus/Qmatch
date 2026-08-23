import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/who_liked_you/domain/who_liked_you_card.dart';
import 'package:qmatch/features/who_liked_you/screens/who_liked_you_screen.dart';
import 'package:qmatch/features/who_liked_you/services/super_resonance_inbox_client.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';

class _FakeWhoLikedYouClient extends WhoLikedYouClient {
  _FakeWhoLikedYouClient(this.result);
  final WhoLikedYouResult result;

  @override
  Future<WhoLikedYouResult> list() async => result;
}

class _FakeSrInbox extends SuperResonanceInboxClient {
  @override
  Future<List<WhoLikedYouCard>> list() async => const [];
}

void main() {
  testWidgets('alignment signals list shows polish caption and cue',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WhoLikedYouScreen(
          animateBackground: false,
          client: _FakeWhoLikedYouClient(
            const WhoLikedYouResult(
              resonanceAccess: true,
              items: [
                WhoLikedYouCard(
                  uid: 'u2',
                  name: 'Bora',
                  age: 29,
                  photos: const [],
                  bio: 'Hello there',
                  interests: ['Müzik'],
                ),
              ],
            ),
          ),
          superResonanceInbox: _FakeSrInbox(),
          likeUser: (_) async => LikeMatchOutcome.noMatch,
          passUser: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('qmatch-who-liked-you-list-caption')),
      findsOneWidget,
    );
    expect(
        find.byKey(const Key('qmatch-who-liked-you-cue-u2')), findsOneWidget);
    expect(find.text('Aligned with you'), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-who-liked-you-name-u2')), findsOneWidget);
  });
}
