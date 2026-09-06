import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/l10n/app_localizations_en.dart';
import 'package:qmatch/l10n/app_localizations_tr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const swipeKey = Key('qmatch-discover-swipeable-card');
  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');
  const detailsScroll = Key('qmatch-candidate-details-scroll');

  final l10nEn = AppLocalizationsEn();
  final l10nTr = AppLocalizationsTr();

  void configureView(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    addTearDown(tester.view.reset);
  }

  Future<void> pumpSwipeStack(
    WidgetTester tester, {
    required VoidCallback onLike,
    required VoidCallback onPass,
    bool showTutorial = false,
    bool enabled = true,
    Size size = const Size(390, 844),
    double? threshold = 80,
    Locale locale = const Locale('en'),
  }) async {
    configureView(tester, size: size);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    QMatchDiscoverSwipeableCard(
                      candidateId: 'cand-1',
                      enabled: enabled,
                      dragThreshold: threshold,
                      likeLabel: 'Like',
                      passLabel: 'Pass',
                      onLike: onLike,
                      onPass: onPass,
                      child: const ColoredBox(
                        color: Color(0xFF223355),
                        child: SizedBox.expand(
                          child: Center(child: Text('candidate')),
                        ),
                      ),
                    ),
                    if (showTutorial)
                      QMatchDiscoverGestureOnboarding(
                        swipeRightText:
                            l10nEn.discoverGestureOnboardingSwipeRight,
                        swipeLeftText:
                            l10nEn.discoverGestureOnboardingSwipeLeft,
                        gotItLabel: l10nEn.discoverGestureOnboardingGotIt,
                        onCompleted: () {},
                        animate: false,
                      ),
                  ],
                ),
              ),
              QMatchDiscoverActionBar(
                passLabel: 'Pass',
                likeLabel: 'Like',
                onPass: enabled ? onPass : null,
                onLike: enabled ? onLike : null,
                isActionLoading: !enabled,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('A–E swipe contract', () {
    testWidgets('A left drag past threshold invokes same Pass as button',
        (tester) async {
      var passes = 0;
      var likes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () => passes++,
      );
      await tester.drag(find.byKey(swipeKey), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(passes, 1);
      expect(likes, 0);

      await tester.tap(find.byKey(passButton));
      await tester.pump();
      expect(passes, 2);
    });

    testWidgets('B left drag below threshold does not Pass', (tester) async {
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () {},
        onPass: () => passes++,
      );
      await tester.drag(find.byKey(swipeKey), const Offset(-40, 0));
      await tester.pumpAndSettle();
      expect(passes, 0);
    });

    testWidgets('C right drag past threshold invokes same Like as button',
        (tester) async {
      var likes = 0;
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () => passes++,
      );
      await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
      await tester.pumpAndSettle();
      expect(likes, 1);
      expect(passes, 0);

      await tester.tap(find.byKey(likeButton));
      await tester.pump();
      expect(likes, 2);
    });

    testWidgets('D right drag below threshold does not Like', (tester) async {
      var likes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () {},
      );
      await tester.drag(find.byKey(swipeKey), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(likes, 0);
    });

    testWidgets('E vertical drag does not Pass or Like', (tester) async {
      var likes = 0;
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () => passes++,
      );
      await tester.drag(find.byKey(swipeKey), const Offset(0, 180));
      await tester.pumpAndSettle();
      expect(likes, 0);
      expect(passes, 0);
    });
  });

  group('F/G tutorial overlay and copy', () {
    testWidgets('F overlay does not block a horizontal Pass swipe',
        (tester) async {
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () {},
        onPass: () => passes++,
        showTutorial: true,
      );
      expect(find.byKey(QMatchDiscoverGestureOnboarding.overlayKey),
          findsOneWidget);
      await tester.drag(find.byKey(swipeKey), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(passes, 1);
    });

    test('G tutorial copy matches left=Pass and right=Like', () {
      expect(l10nEn.discoverGestureOnboardingSwipeLeft, 'Swipe left to pass.');
      expect(
          l10nEn.discoverGestureOnboardingSwipeRight, 'Swipe right to like.');
      expect(l10nTr.discoverGestureOnboardingSwipeLeft,
          'Geçmek için sola kaydır.');
      expect(
        l10nTr.discoverGestureOnboardingSwipeRight,
        'Beğenmek için sağa kaydır.',
      );
    });
  });

  group('H–N buttons and single-flight', () {
    testWidgets('H/I Pass and Like buttons still work', (tester) async {
      var likes = 0;
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () => passes++,
      );
      await tester.tap(find.byKey(passButton));
      await tester.tap(find.byKey(likeButton));
      await tester.pump();
      expect(passes, 1);
      expect(likes, 1);
    });

    testWidgets('L committed swipe fires once', (tester) async {
      var likes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () {},
      );
      await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
      await tester.pump();
      await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
      await tester.pumpAndSettle();
      expect(likes, 1);
    });

    testWidgets('M/N in-flight card ignores a second swipe', (tester) async {
      var likes = 0;
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () => passes++,
      );
      await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
      await tester.pump();
      await tester.drag(find.byKey(swipeKey), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(likes, 1);
      expect(passes, 0);
    });

    test('M/N screen disables buttons while an action is in flight', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(src.contains('_isActionLoading ||'), isTrue);
      expect(src.contains('_likeDispatchedUids.contains(c.uid)'), isTrue);
      expect(src.contains('if (c == null || _isActionLoading || _rewindBusy)'),
          isTrue);
      expect(src.contains('if (c == null || _rewindBusy || _isActionLoading)'),
          isTrue);
    });
  });

  group('P/Q/R source integrity', () {
    test('P failed Discover actions use QMatchFeedback', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(src.contains('QMatchFeedback.show'), isTrue);
      expect(src.contains('discoverActionFailed'), isTrue);
      expect(src.contains('SnackBar('), isFalse);
    });

    test('Q swipe and buttons share one Pass/Like pipeline', () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('onLike: _onLikeAction'), isTrue);
      expect(screen.contains('onPass: _onPassAction'), isTrue);
      expect(screen.contains(': _onPassAction'), isTrue);
      expect(screen.contains(': _onLikeAction'), isTrue);
      expect(screen.contains('unawaited(_onPass())'), isTrue);
      expect(screen.contains('unawaited(_onLike())'), isTrue);
      expect(screen.contains('_passUser(c.uid)'), isTrue);
      expect(screen.contains('likeUser(c.uid)'), isTrue);
      expect(screen.contains('rankL1Batch'), isFalse);
      expect(screen.contains('compatibility_v2'), isFalse);
    });

    test('Q swipeable card does not call backend itself', () {
      final card = File(
        'lib/features/discover/widgets/qmatch_discover_swipeable_card.dart',
      ).readAsStringSync();
      expect(card.contains('SwipeService'), isFalse);
      expect(card.contains('.passUser('), isFalse);
      expect(card.contains('.likeUser('), isFalse);
      expect(card.contains('widget.onLike()'), isTrue);
      expect(card.contains('widget.onPass()'), isTrue);
    });

    test('R Got it marks tutorial seen without Pass', () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final complete =
          screen.indexOf('Future<void> _completeGestureOnboarding()');
      final replay =
          screen.indexOf('Future<void> _debugReplayGestureOnboarding()');
      expect(complete, greaterThanOrEqualTo(0));
      expect(replay, greaterThan(complete));
      final body = screen.substring(complete, replay);
      expect(body.contains('markSeen()'), isTrue);
      expect(body.contains('_onPass'), isFalse);
      expect(body.contains('passUser'), isFalse);
      expect(body.contains('_onLike'), isFalse);
    });

    test('J/K Super Resonance and Rewind stay dedicated handlers', () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('onSuperResonance:'), isTrue);
      expect(screen.contains('_onSuperResonance'), isTrue);
      expect(screen.contains('_onRewindPressed'), isTrue);
      expect(screen.contains('rewindPass'), isTrue);
      expect(screen.contains('rewindLike'), isTrue);
    });
  });

  group('S/T viewports', () {
    testWidgets('S small iPhone viewport swipe still commits Pass',
        (tester) async {
      var passes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () {},
        onPass: () => passes++,
        size: const Size(375, 667),
      );
      await tester.drag(find.byKey(swipeKey), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(passes, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T modern iPhone viewport swipe still commits Like',
        (tester) async {
      var likes = 0;
      await pumpSwipeStack(
        tester,
        onLike: () => likes++,
        onPass: () {},
        size: const Size(430, 932),
      );
      await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
      await tester.pumpAndSettle();
      expect(likes, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('U details scroll key remains', () {
    test('U candidate details stay a vertical scroll view', () {
      final src = File(
        'lib/features/discover/widgets/qmatch_candidate_card.dart',
      ).readAsStringSync();
      expect(src.contains('SingleChildScrollView'), isTrue);
      expect(src.contains('qmatch-candidate-details-scroll'), isTrue);
      expect(detailsScroll, const Key('qmatch-candidate-details-scroll'));
    });
  });

  group('V overlay hit-test contract', () {
    test('V tutorial visuals are pointer-transparent except caption/Got it',
        () {
      final src = File(
        'lib/features/discover/widgets/qmatch_discover_gesture_onboarding.dart',
      ).readAsStringSync();
      expect(src.contains('IgnorePointer'), isTrue);
      expect(src.contains('captionKey'), isTrue);
      expect(src.contains('gotItKey'), isTrue);
      expect(src.contains('Positioned.fill'), isTrue);
      expect(src.contains('GestureDetector('), isTrue);
    });

    test('V Discover no longer disables swipe while the tutorial is visible',
        () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(
        src.contains('enabled: !_isActionLoading && !_rewindBusy'),
        isTrue,
      );
      expect(
        src.contains(
            'enabled: !_isActionLoading &&\n                      !_rewindBusy &&\n                      !_showGestureOnboarding'),
        isFalse,
      );
    });
  });
}
