import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/widgets/qmatch_candidate_card.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/who_liked_you/screens/who_liked_you_screen.dart';
import 'package:qmatch/features/who_liked_you/services/super_resonance_inbox_client.dart';
import 'package:qmatch/features/who_liked_you/services/who_liked_you_client.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const lilac = Color(0xFFDAC8ED);

  test('EN/TR Who Liked You copy uses alignment-signal language', () {
    final en = AppLocalizationsEn();
    final tr = AppLocalizationsTr();

    expect(en.whoLikedYouTitle, 'Alignment Signals');
    expect(en.whoLikedYouEmptyTitle, 'New alignment signals will appear here');
    expect(
      en.whoLikedYouEmptyBody,
      'When a new alignment forms around you, you can discover it here.',
    );

    expect(tr.whoLikedYouTitle, 'Uyum Sinyalleri');
    expect(tr.whoLikedYouEmptyTitle, 'Yeni uyum sinyalleri burada görünecek');
    expect(
      tr.whoLikedYouEmptyBody,
      'Sana yönelik yeni bir uyum oluştuğunda burada keşfedebilirsin.',
    );
  });

  test('Who Liked You feature strings drop like/beğeni phrasing', () {
    final en = AppLocalizationsEn();
    final tr = AppLocalizationsTr();
    final featureCopy = [
      en.whoLikedYouTitle,
      en.whoLikedYouEmptyTitle,
      en.whoLikedYouEmptyBody,
      en.whoLikedYouErrorTitle,
      en.whoLikedYouLockedBody,
      en.whoLikedYouFreeDiscoveryTitle,
      en.whoLikedYouFreeDiscoveryBody,
      tr.whoLikedYouTitle,
      tr.whoLikedYouEmptyTitle,
      tr.whoLikedYouEmptyBody,
      tr.whoLikedYouErrorTitle,
      tr.whoLikedYouLockedBody,
    ].join('\n').toLowerCase();

    expect(featureCopy.contains('who liked you'), isFalse);
    expect(featureCopy.contains('no one has liked you yet'), isFalse);
    expect(featureCopy.contains('when someone likes you'), isFalse);
    expect(featureCopy.contains('henüz kimse seni beğenmedi'), isFalse);
    expect(featureCopy.contains('biri seni beğendiğinde'), isFalse);
    expect(featureCopy.contains('seni beğenenler'), isFalse);
  });

  testWidgets('EN empty inbox shows alignment-signal copy', (tester) async {
    await _pumpWhoLikedYou(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Alignment Signals'), findsOneWidget);
    expect(
      find.text('New alignment signals will appear here'),
      findsOneWidget,
    );
    expect(
      find.text(
        'When a new alignment forms around you, you can discover it here.',
      ),
      findsOneWidget,
    );
    expect(find.text('No one has liked you yet'), findsNothing);
  });

  testWidgets('TR empty inbox shows uyum sinyali copy', (tester) async {
    await _pumpWhoLikedYou(tester, locale: const Locale('tr'));
    await tester.pumpAndSettle();

    expect(find.text('Uyum Sinyalleri'), findsOneWidget);
    expect(
      find.text('Yeni uyum sinyalleri burada görünecek'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Sana yönelik yeni bir uyum oluştuğunda burada keşfedebilirsin.',
      ),
      findsOneWidget,
    );
    expect(find.text('Henüz kimse seni beğenmedi'), findsNothing);
    expect(find.text('Seni beğenenler'), findsNothing);
  });

  testWidgets('Who Liked You loading spinner uses Discover lilac, not gold',
      (tester) async {
    final gate = Completer<Map<String, dynamic>>();
    await _pumpWhoLikedYou(
      tester,
      client: WhoLikedYouClient(call: (_, __) => gate.future),
    );

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byKey(const Key('qmatch-who-liked-you-loading')),
    );
    expect(indicator.color, isNot(AppColors.softGold));
    expect(
      (indicator.valueColor as AlwaysStoppedAnimation<Color>?)?.value,
      lilac,
    );

    gate.complete({
      'resonance_access': true,
      'items': <Map<String, dynamic>>[],
    });
    await tester.pumpAndSettle();
  });

  testWidgets('Discover interests heading uses light lilac, not gold',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 640,
            child: QMatchCandidateCard(
              candidate: DiscoverUserModel(
                uid: 'u1',
                name: 'Ada',
                age: 28,
                interests: const ['science'],
              ),
            ),
          ),
        ),
      ),
    );

    final heading = tester.widget<Text>(
      find.byKey(const Key('qmatch-candidate-interests-heading')),
    );
    expect(heading.data, 'Interests');
    expect(heading.style?.color, lilac);
    expect(heading.style?.color, isNot(AppColors.softGold));
  });

  test('Who Liked You spinner source no longer uses softGold', () {
    final src = File(
      'lib/features/who_liked_you/screens/who_liked_you_screen.dart',
    ).readAsStringSync();
    expect(src.contains('AppColors.softGold'), isFalse);
    expect(src.contains('0xFFDAC8ED'), isTrue);

    final card = File(
      'lib/features/discover/widgets/qmatch_candidate_card.dart',
    ).readAsStringSync();
    expect(card.contains('color: AppColors.softGold'), isFalse);
    expect(card.contains('qmatch-candidate-interests-heading'), isTrue);
  });
}

Future<void> _pumpWhoLikedYou(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  WhoLikedYouClient? client,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WhoLikedYouScreen(
        client: client ??
            WhoLikedYouClient(
              call: (_, __) async => {
                'resonance_access': true,
                'items': <Map<String, dynamic>>[],
              },
            ),
        superResonanceInbox: SuperResonanceInboxClient(
          call: (_, __) async => {
            'items': <Map<String, dynamic>>[],
          },
        ),
        likeUser: (_) async => LikeMatchOutcome.noMatch,
        passUser: (_) async {},
        onUnlock: () async {},
        currentUidProvider: () => 'me',
        animateBackground: false,
      ),
    ),
  );
}
