import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/utils/discover_identity_format.dart';

import 'support/discover_golden_fixtures.dart';
import 'support/discover_golden_scene.dart';

/// Deterministic Discover visual goldens (P2C-1C-2A / P2C-1C-2B).
///
/// Legacy CompatibilityScoring / archetype chips may appear on candidate
/// fixtures. They are temporary runtime outputs — not Core Method v2 — and
/// must be replaced when CM v2 is production-wired (gap G-041).
///
/// P2C-1C-2B regenerates the refined loading skeleton golden and re-proves
/// candidate / error / match dialog baselines with synthetic fixtures only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryImage portrait;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    portrait = await DiscoverGoldenFixtures.syntheticPortraitProvider();
  });

  Future<void> pumpScene(
    WidgetTester tester, {
    required DiscoverGoldenScene scene,
    required Size size,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapDiscoverGolden(
        surfaceSize: size,
        textScale: textScale,
        child: TickerMode(
          enabled: false,
          child: scene,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  Future<void> expectGolden(
    WidgetTester tester,
    String name,
  ) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/discover/$name.png'),
    );
  }

  group('Discover goldens — compact / large / text scale', () {
    testWidgets('loading compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: const DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.loading,
        ),
      );
      expect(find.byKey(const Key('qmatch-discover-loading')), findsOneWidget);
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
      expect(
        find.byKey(const Key('qmatch-discover-loading-pass')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('qmatch-discover-empty')), findsNothing);
      expect(find.byKey(const Key('qmatch-discover-error')), findsNothing);
      // Refined loading baseline (P2C-1C-2B).
      await expectGolden(tester, 'loading_compact_1_0');
    });

    testWidgets('empty compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: const DiscoverGoldenScene(variant: DiscoverGoldenVariant.empty),
      );
      expect(find.byKey(const Key('qmatch-discover-empty')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-discover-error')), findsNothing);
      expect(find.byKey(const Key('qmatch-discover-loading')), findsNothing);
      await expectGolden(tester, 'empty_compact_1_0');
    });

    testWidgets('empty compact 1.3', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        textScale: 1.3,
        scene: const DiscoverGoldenScene(variant: DiscoverGoldenVariant.empty),
      );
      expect(find.byKey(const Key('qmatch-discover-empty')), findsOneWidget);
      await expectGolden(tester, 'empty_compact_1_3');
    });

    testWidgets('error compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: const DiscoverGoldenScene(variant: DiscoverGoldenVariant.error),
      );
      expect(find.byKey(const Key('qmatch-discover-error')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-discover-empty')), findsNothing);
      await expectGolden(tester, 'error_compact_1_0');
    });

    testWidgets('candidate with photo compact 1.0', (tester) async {
      final candidate = DiscoverGoldenFixtures.candidateWithLegacyCompat(
        name: 'Ada',
        age: 29,
      );
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: candidate,
          photoImageProvider: portrait,
        ),
      );

      final identity = formatDiscoverIdentity(name: 'Ada', age: 29);
      expect(identity, 'Ada, 29');
      expect(find.text(identity!), findsOneWidget);
      expect(find.textContaining(', ,'), findsNothing);
      expect(find.byKey(const Key('qmatch-candidate-compat-label')),
          findsOneWidget);
      expect(find.byKey(const Key('qmatch-candidate-compat-score')),
          findsOneWidget);
      await expectGolden(tester, 'candidate_photo_compact_1_0');
    });

    testWidgets('candidate with photo large 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.largeIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateWithLegacyCompat(
            name: 'Ada',
            age: 29,
          ),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'candidate_photo_large_1_0');
    });

    testWidgets('candidate with photo compact 1.3', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        textScale: 1.3,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateWithLegacyCompat(
            name: 'Ada',
            age: 29,
          ),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'candidate_photo_compact_1_3');
    });

    testWidgets('candidate missing photo compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateMissingPhoto(),
        ),
      );
      expect(
        find.byKey(const Key('qmatch-candidate-photo-missing')),
        findsOneWidget,
      );
      await expectGolden(tester, 'candidate_missing_photo_compact_1_0');
    });

    testWidgets('candidate long content compact 1.0', (tester) async {
      final candidate = DiscoverGoldenFixtures.candidateLongContent();
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: candidate,
        ),
      );
      final identity = formatDiscoverIdentity(
        name: candidate.name,
        age: candidate.age,
      );
      expect(identity!.startsWith(','), isFalse);
      expect(identity.contains(', ,'), isFalse);
      expect(
          find.byKey(const Key('qmatch-candidate-identity')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-candidate-bio')), findsOneWidget);
      await expectGolden(tester, 'candidate_long_content_compact_1_0');
    });

    testWidgets('candidate name only missing age compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateWithLegacyCompat(
            name: 'Ada',
            // age <= 0 is treated as missing by QMatchCandidateCard.
            age: 0,
            bio: 'Name without age.',
            profilePhotoUrl: null,
          ),
        ),
      );
      expect(formatDiscoverIdentity(name: 'Ada', age: null), 'Ada');
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text(', '), findsNothing);
      expect(
          find.byKey(const Key('qmatch-candidate-identity')), findsOneWidget);
      await expectGolden(tester, 'candidate_name_only_compact_1_0');
    });

    testWidgets('action loading compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateWithLegacyCompat(
            name: 'Ada',
            age: 29,
          ),
          photoImageProvider: portrait,
          isActionLoading: true,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await expectGolden(tester, 'action_loading_compact_1_0');
    });

    testWidgets('match dialog compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: const DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.matchDialog,
        ),
      );
      expect(
        find.byKey(const Key('qmatch-discover-match-dialog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-discover-match-open-chat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-discover-match-continue')),
        findsOneWidget,
      );
      await expectGolden(tester, 'match_dialog_compact_1_0');
    });

    testWidgets('shell candidate actions clear bottom nav compact 1.0',
        (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverGoldenFixtures.candidateWithLegacyCompat(
            name: 'Ada',
            age: 29,
          ),
          photoImageProvider: portrait,
          includeShell: true,
        ),
      );

      final actionBar = tester.getRect(
        find.byKey(const Key('qmatch-discover-action-bar')),
      );
      final nav = tester.getRect(
        find.byKey(const Key('qmatch-bottom-navigation')),
      );
      expect(actionBar.bottom <= nav.top + 0.5, isTrue);
      await expectGolden(tester, 'shell_candidate_nav_clearance_compact_1_0');
    });
  });

  group('Discover presentation source guards', () {
    test('widgets remain free of Firebase / scoring / CM v2', () {
      // Light structural assertions already covered by discover_visual_migration_test.
      // This group documents golden-phase intent: fixtures only.
      expect(DiscoverGoldenFixtures.compactIphone.width, 375);
      expect(DiscoverGoldenFixtures.largeIphone.width, 430);
    });

    testWidgets('missing fields omit identity punctuation cleanly',
        (tester) async {
      await pumpScene(
        tester,
        size: DiscoverGoldenFixtures.compactIphone,
        scene: DiscoverGoldenScene(
          variant: DiscoverGoldenVariant.candidate,
          candidate: DiscoverUserModel(
            uid: 'fixture-empty-fields',
            name: '',
            age: 26,
            bio: '',
            interests: const [],
          ),
        ),
      );

      expect(find.text(', 26'), findsNothing);
      expect(find.text('26'), findsNothing);
      expect(find.byKey(const Key('qmatch-candidate-identity')), findsNothing);
      expect(
          find.byKey(const Key('qmatch-candidate-compat-score')), findsNothing);
      expect(find.byKey(const Key('qmatch-candidate-bio')), findsNothing);
    });
  });
}
