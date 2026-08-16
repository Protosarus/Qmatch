import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/qmatch_main_shell.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/utils/discover_identity_format.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatDiscoverIdentity', () {
    test('formats name and age without malformed punctuation', () {
      expect(formatDiscoverIdentity(name: 'Ada', age: 26), 'Ada, 26');
      expect(formatDiscoverIdentity(name: '  Ada  ', age: 26), 'Ada, 26');
    });

    test('missing name does not render a leading comma or age-only identity',
        () {
      expect(formatDiscoverIdentity(name: '', age: 26), isNull);
      expect(formatDiscoverIdentity(name: '   ', age: 26), isNull);
      expect(formatDiscoverIdentity(name: '', age: 26), isNot(equals(', 26')));
    });

    test('missing age does not render a trailing comma', () {
      expect(formatDiscoverIdentity(name: 'Ada', age: null), 'Ada');
      expect(formatDiscoverIdentity(name: 'Ada', age: 0), 'Ada');
    });

    test('missing name and age returns null', () {
      expect(formatDiscoverIdentity(name: '', age: null), isNull);
    });
  });

  group('Discover presentation states', () {
    testWidgets('loading state renders card-shaped skeleton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: QMatchDiscoverLoadingState(message: 'Finding people…'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('qmatch-discover-loading')), findsOneWidget);
      expect(find.text('Finding people…'), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-discover-loading-identity')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-discover-loading-bio-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-discover-loading-chip-1')),
        findsOneWidget,
      );
    });

    testWidgets('empty state renders and retry is called', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchDiscoverEmptyState(
              title: 'No profiles',
              body: 'Try later',
              retryLabel: 'Retry',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-discover-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-discover-empty-retry')));
      expect(retries, 1);
    });

    testWidgets('error state renders and retry is called', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchDiscoverErrorState(
              title: 'Could not load',
              body: 'Please retry',
              retryLabel: 'Retry',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-discover-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-discover-error-retry')));
      expect(retries, 1);
    });

    testWidgets('candidate state renders without fabricated score',
        (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Scaffold(
            body: QMatchCandidateCard(
              candidate: DiscoverUserModel(
                uid: 'u1',
                name: 'Ada Lovelace',
                age: 36,
                bio: 'Mathematician',
                interests: const ['science'],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('qmatch-candidate-card')), findsOneWidget);
      expect(find.text('Ada Lovelace, 36'), findsOneWidget);
      expect(
          find.byKey(const Key('qmatch-candidate-compat-score')), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('Core Method'), findsNothing);
    });

    testWidgets('missing photo renders safe placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: SizedBox(
              height: 240,
              child: QMatchCandidatePhoto(
                photoUrl: null,
                semanticLabel: 'Photo',
                missingPhotoLabel: 'No photo',
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-candidate-photo-missing')),
        findsOneWidget,
      );
    });

    testWidgets('long display name does not overflow', (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 640,
              child: QMatchCandidateCard(
                candidate: DiscoverUserModel(
                  uid: 'u1',
                  name:
                      'Very Long Display Name That Should Ellipsize Gracefully Without Overflowing The Card Layout',
                  age: 29,
                  bio: 'Short bio',
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(const Key('qmatch-candidate-identity')), findsOneWidget);
    });

    testWidgets('long bio does not overflow', (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 640,
              child: QMatchCandidateCard(
                candidate: DiscoverUserModel(
                  uid: 'u1',
                  name: 'Ada',
                  age: 30,
                  bio: List.filled(40, 'Long bio sentence.').join(' '),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('qmatch-candidate-bio')), findsOneWidget);
    });

    testWidgets('like and pass handlers are preserved', (tester) async {
      var likes = 0;
      var passes = 0;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchDiscoverActionBar(
              passLabel: 'Pass',
              likeLabel: 'Like',
              onPass: () => passes++,
              onLike: () => likes++,
              isActionLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qmatch-discover-pass')));
      await tester.tap(find.byKey(const Key('qmatch-discover-like')));
      expect(passes, 1);
      expect(likes, 1);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.textContaining('Super'), findsNothing);
      expect(find.textContaining('Rewind'), findsNothing);
    });

    testWidgets('action bar disables controls while loading', (tester) async {
      var likes = 0;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: QMatchDiscoverActionBar(
              passLabel: 'Pass',
              likeLabel: 'Like',
              onPass: null,
              onLike: null,
              isActionLoading: true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-discover-like')));
      expect(likes, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('localized discover strings are used by empty/error surfaces',
        (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    QMatchDiscoverHeader(title: l10n.discoverTitle),
                    Expanded(
                      child: QMatchDiscoverEmptyState(
                        title: l10n.discoverEmptyTitle,
                        body: l10n.discoverEmptySubtitle,
                        retryLabel: l10n.discoverEmptyRetry,
                        onRetry: () {},
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('No new profiles for now'), findsOneWidget);
      expect(
          find.text('New match candidates will appear here as they arrive.'),
          findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });

    testWidgets('bottom navigation does not cover Discover content inset',
        (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
              size: Size(390, 844),
            ),
            child: QMatchMainShell(
              currentIndex: 0,
              onTabSelected: (_) {},
              pages: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      const QMatchDiscoverHeader(title: 'Discover'),
                      Expanded(
                        child: QMatchCandidateCard(
                          candidate: DiscoverUserModel(
                            uid: 'u1',
                            name: 'Ada',
                            age: 30,
                            bio: 'Bio',
                          ),
                        ),
                      ),
                      QMatchDiscoverActionBar(
                        passLabel: 'Pass',
                        likeLabel: 'Like',
                        onPass: () {},
                        onLike: () {},
                        isActionLoading: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
              items: const [
                QMatchBottomNavigationItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                ),
                QMatchBottomNavigationItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                ),
                QMatchBottomNavigationItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );

      final actionBar = tester.getRect(
        find.byKey(const Key('qmatch-discover-action-bar')),
      );
      final nav = tester.getRect(
        find.byKey(const Key('qmatch-bottom-navigation')),
      );
      expect(actionBar.bottom <= nav.top + 0.5, isTrue);
    });
  });

  group('Discover source guards', () {
    test('screen keeps DiscoverService and SwipeService wiring', () {
      final source = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();

      expect(source.contains('DiscoverService'), isTrue);
      expect(source.contains('getCandidates'), isTrue);
      expect(source.contains('likeUser'), isTrue);
      expect(source.contains('passUser'), isTrue);
      expect(source.contains('showQMatchDiscoverMatchDialog'), isTrue);
      expect(source.contains('core_method'), isFalse);
      expect(source.contains('TraitScoring'), isFalse);
      expect(source.contains('compatibility_scoring'), isFalse);
      expect(source.contains('calculateCompatibility'), isFalse);
    });

    test('presentation widgets do not duplicate Firebase queries', () {
      final widgetDir = Directory('lib/features/discover/widgets');
      for (final entity in widgetDir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(source.contains('cloud_firestore'), isFalse,
            reason: entity.path);
        expect(source.contains('FirebaseFirestore'), isFalse,
            reason: entity.path);
        expect(source.contains('getCandidates'), isFalse, reason: entity.path);
        expect(source.contains('core_method'), isFalse, reason: entity.path);
        expect(source.contains('TraitScoring'), isFalse, reason: entity.path);
      }
    });

    test('candidate source service remains the Discover query owner', () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(service.contains('CompatibilityScoring.calculateCompatibility'),
          isTrue);
      expect(service.contains('discover_eligible'), isTrue);
      expect(service.contains('core_method'), isFalse);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
  );
}

Widget _wrapLocalized(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}
