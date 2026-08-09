import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/profile_golden_fixtures.dart';
import 'support/profile_golden_scene.dart';

/// Deterministic Profile visual goldens (P2C-1C-4B). Synthetic fixtures only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryImage portrait;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    portrait = await ProfileGoldenFixtures.syntheticPortraitProvider();
  });

  Future<void> pumpScene(
    WidgetTester tester, {
    required ProfileGoldenScene scene,
    required Size size,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapProfileGolden(
        surfaceSize: size,
        textScale: textScale,
        child: TickerMode(enabled: false, child: scene),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  Future<void> expectGolden(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile/$name.png'),
    );
  }

  group('Profile goldens', () {
    testWidgets('full profile compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.full(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'full_compact_1_0');
    });

    testWidgets('name only compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.nameOnly(),
        ),
      );
      expect(find.text('Ada'), findsOneWidget);
      await expectGolden(tester, 'name_only_compact_1_0');
    });

    testWidgets('missing photo compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.missingPhoto(),
        ),
      );
      await expectGolden(tester, 'missing_photo_compact_1_0');
    });

    testWidgets('missing biography compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.missingBio(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'missing_bio_compact_1_0');
    });

    testWidgets('empty interests compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.emptyInterests(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'empty_interests_compact_1_0');
    });

    testWidgets('many interests compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.manyInterests(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'many_interests_compact_1_0');
    });

    testWidgets('long Turkish name compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.longTurkishName(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'long_turkish_name_compact_1_0');
    });

    testWidgets('long Cyrillic name compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.longCyrillicName(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'long_cyrillic_name_compact_1_0');
    });

    testWidgets('long biography compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.longBio(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'long_bio_compact_1_0');
    });

    testWidgets('loading compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: const ProfileGoldenScene(
          profile: null,
          forceLoading: true,
        ),
      );
      await expectGolden(tester, 'loading_compact_1_0');
    });

    testWidgets('error compact 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        scene: const ProfileGoldenScene(
          profile: null,
          forceError: true,
        ),
      );
      await expectGolden(tester, 'error_compact_1_0');
    });

    testWidgets('full standard 1.0', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.standardIphone,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.full(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'full_standard_1_0');
    });

    testWidgets('full compact textScale 1.3', (tester) async {
      await pumpScene(
        tester,
        size: ProfileGoldenFixtures.compactIphone,
        textScale: 1.3,
        scene: ProfileGoldenScene(
          profile: ProfileGoldenFixtures.full(),
          photoImageProvider: portrait,
        ),
      );
      await expectGolden(tester, 'full_compact_1_3');
    });
  });
}
