import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/widgets/qmatch_candidate_card.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';
import 'package:qmatch/features/profile/screens/profile_anthem_edit_screen.dart';
import 'package:qmatch/features/profile/screens/profile_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

UserProfileModel profileWithAnthem() {
  return const UserProfileModel(
    userId: 'u1',
    name: 'Ada',
    age: 26,
    gender: 'Kadın',
    education: 'Lisans',
    bio: 'Hello',
    interests: ['Müzik'],
    lookingFor: 'Ciddi İlişki',
    ageRange: [25, 35],
    distancePreference: 50,
    anthemTitle: 'Midnight City',
    anthemArtist: 'M83',
    anthemExternalUrl: 'https://example.com/song',
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  test('anthem fields serialize and round-trip', () {
    final map = profileWithAnthem().toFirestore();
    expect(map['anthem_title'], 'Midnight City');
    expect(map['anthem_artist'], 'M83');
    expect(map['anthem_external_url'], 'https://example.com/song');

    final restored = UserProfileModel.fromFirestore(map, 'u1');
    expect(restored.anthemTitle, 'Midnight City');
    expect(restored.anthemArtist, 'M83');
  });

  testWidgets('profile shows anthem section', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProfileScreen(
          debugProfile: profileWithAnthem(),
          debugResonanceAccess: false,
          animateBackground: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('qmatch-profile-anthem-section')), findsOneWidget);
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.text('M83'), findsOneWidget);
    expect(find.byKey(const Key('qmatch-profile-edit-anthem')), findsOneWidget);
  });

  testWidgets('anthem edit screen saves title and artist', (tester) async {
    UserProfileModel? saved;
    await tester.pumpWidget(
      wrap(
        ProfileAnthemEditScreen(
          profile: profileWithAnthem().copyWith(
            anthemTitle: '',
            anthemArtist: '',
            anthemExternalUrl: '',
          ),
          animateBackground: false,
          debugSaveProfile: (p) async => saved = p,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('qmatch-profile-anthem-song-title')),
      'Nightcall',
    );
    await tester.enterText(
      find.byKey(const Key('qmatch-profile-anthem-artist')),
      'Kavinsky',
    );
    await tester.tap(find.byKey(const Key('qmatch-profile-anthem-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.anthemTitle, 'Nightcall');
    expect(saved!.anthemArtist, 'Kavinsky');
  });

  testWidgets('candidate card shows anthem line', (tester) async {
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: SizedBox(
            height: 640,
            child: QMatchCandidateCard(
              candidate: const DiscoverUserModel(
                uid: 'u2',
                name: 'Ada',
                age: 27,
                anthemTitle: 'Midnight City',
                anthemArtist: 'M83',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qmatch-candidate-anthem')), findsOneWidget);
    expect(find.textContaining('Midnight City'), findsOneWidget);
  });
}
