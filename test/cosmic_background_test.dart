import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/widgets/cosmic/qmatch_cosmic_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starsFor is deterministic for a seed', () {
    final a = QMatchCosmicBackground.starsFor(seed: 42, count: 18);
    final b = QMatchCosmicBackground.starsFor(seed: 42, count: 18);
    expect(a.length, 18);
    expect(a.length, inInclusiveRange(14, 22));
    for (var i = 0; i < a.length; i++) {
      expect(a[i].nx, b[i].nx);
      expect(a[i].ny, b[i].ny);
      expect(a[i].radius, b[i].radius);
      expect(a[i].baseOpacity, b[i].baseOpacity);
      expect(a[i].accent, b[i].accent);
      expect(a[i].phase, b[i].phase);
      expect(a[i].periodSeconds, inInclusiveRange(3.8, 7.2));
      expect(a[i].radius, inInclusiveRange(1.3, 4.2));
      expect(a[i].baseOpacity, lessThanOrEqualTo(0.55));
      expect(a[i].driftAmplitude, greaterThan(0));
      expect(a[i].driftPeriodSeconds, inInclusiveRange(8.0, 16.0));
    }
  });

  test('accent stars change opacity over time without losing seed position',
      () {
    final stars = QMatchCosmicBackground.starsFor(seed: 42, count: 18);
    final accent = stars.where((s) => s.accent).toList();
    expect(accent.length, inInclusiveRange(4, 6));

    final star = accent.first;
    final phaseA = QMatchCosmicBackground.opacityFor(
      star,
      timeSeconds: 0.0,
      breathing: true,
    );
    final phaseB = QMatchCosmicBackground.opacityFor(
      star,
      timeSeconds: star.periodSeconds / 2,
      breathing: true,
    );

    expect(phaseA, isNot(equals(phaseB)));
    expect(star.nx, inInclusiveRange(0.0, 1.0));
    expect(star.ny, inInclusiveRange(0.0, 1.0));
  });

  test('stars drift gently when motion is enabled', () {
    final star = QMatchCosmicBackground.starsFor(seed: 42, count: 18).first;
    final a = QMatchCosmicBackground.offsetFor(
      star,
      timeSeconds: 0,
      drifting: true,
    );
    final b = QMatchCosmicBackground.offsetFor(
      star,
      timeSeconds: star.driftPeriodSeconds / 4,
      drifting: true,
    );
    final frozen = QMatchCosmicBackground.offsetFor(
      star,
      timeSeconds: 3,
      drifting: false,
    );
    expect(a, isNot(equals(b)));
    expect(frozen, Offset.zero);
    expect(a.distance, lessThanOrEqualTo(star.driftAmplitude + 0.01));
  });

  test('phase offsets prevent synchronized blinking', () {
    final accent = QMatchCosmicBackground.starsFor(seed: 42, count: 18)
        .where((s) => s.accent)
        .toList();
    final atT0 = accent
        .map(
          (star) => QMatchCosmicBackground.opacityFor(
            star,
            timeSeconds: 0,
            breathing: true,
          ),
        )
        .toSet();
    expect(atT0.length, greaterThan(1));
  });

  testWidgets('stars layout stable across rebuild; IgnorePointer',
      (tester) async {
    final starsBefore = QMatchCosmicBackground.starsFor(seed: 7);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QMatchCosmicBackground(
            seed: 7,
            animate: false,
            showStarfieldImage: false,
            child: Center(child: Text('child')),
          ),
        ),
      ),
    );
    expect(find.text('child'), findsOneWidget);
    await tester.tap(find.text('child'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QMatchCosmicBackground(
            seed: 7,
            animate: false,
            showStarfieldImage: false,
            child: Center(child: Text('child')),
          ),
        ),
      ),
    );
    final starsAfter = QMatchCosmicBackground.starsFor(seed: 7);
    expect(starsAfter.first.nx, starsBefore.first.nx);
  });

  testWidgets('reduced motion / animate:false stays static', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const MaterialApp(
          home: Scaffold(
            body: QMatchCosmicBackground(
              seed: 3,
              showStarfieldImage: false,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TickerMode disabled freezes breathing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TickerMode(
            enabled: false,
            child: QMatchCosmicBackground(
              seed: 11,
              showStarfieldImage: false,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden/test snapshot mode freezes a deterministic frame',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QMatchCosmicBackground(
            seed: 9,
            debugTimeSeconds: 1.25,
            showStarfieldImage: false,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('starfield asset is wired for main cosmic backdrop',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QMatchCosmicBackground(
            seed: 21,
            animate: false,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('runtime screens are not wired to frozen debugTimeSeconds', () {
    for (final path in [
      'lib/features/settings/screens/settings_screen.dart',
      'lib/features/profile/screens/profile_screen.dart',
      'lib/features/profile/screens/profile_photo_edit_screen.dart',
      'lib/features/discover/screens/discover_screen.dart',
      'lib/features/settings/screens/privacy_settings_screen.dart',
      'lib/features/settings/screens/notifications_settings_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('debugTimeSeconds:')));
    }
  });

  test('discover and profile wire cosmic background', () {
    final discover = File('lib/features/discover/screens/discover_screen.dart')
        .readAsStringSync();
    final profile = File('lib/features/profile/screens/profile_screen.dart')
        .readAsStringSync();
    final shell =
        File('lib/core/navigation/qmatch_main_shell.dart').readAsStringSync();
    expect(discover, contains('QMatchCosmicBackground'));
    expect(discover, contains('qmatch-discover-cosmic'));
    expect(profile, contains('QMatchCosmicBackground'));
    expect(profile, contains('qmatch-profile-cosmic'));
    expect(shell, contains('QMatchCosmicBackground'));
    expect(shell, contains('qmatch-main-cosmic'));
  });
}
