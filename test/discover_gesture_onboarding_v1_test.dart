import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/services/discover_gesture_onboarding_store.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const overlay = Key('qmatch-discover-gesture-onboarding');
  const stepLike = Key('qmatch-discover-gesture-onboarding-step-like');
  const stepPass = Key('qmatch-discover-gesture-onboarding-step-pass');
  const heart = Key('qmatch-discover-gesture-onboarding-heart');
  const passIcon = Key('qmatch-discover-gesture-onboarding-pass-icon');
  const gotIt = Key('qmatch-discover-gesture-onboarding-got-it');

  group('icon-only Discover action bar', () {
    testWidgets('shows X and heart without Pass/Like text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QMatchDiscoverActionBar(
              passLabel: 'Pass',
              likeLabel: 'Like',
              onPass: () {},
              onLike: () {},
              isActionLoading: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('qmatch-discover-pass')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-discover-like')), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('Pass'), findsNothing);
      expect(find.text('Like'), findsNothing);
      expect(find.text('Geç'), findsNothing);
      expect(find.text('Beğen'), findsNothing);
    });
  });

  group('gesture onboarding overlay', () {
    Future<void> pumpOverlay(
      WidgetTester tester, {
      required VoidCallback onCompleted,
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return QMatchDiscoverGestureOnboarding(
                  swipeRightText: l10n.discoverGestureOnboardingSwipeRight,
                  swipeLeftText: l10n.discoverGestureOnboardingSwipeLeft,
                  gotItLabel: l10n.discoverGestureOnboardingGotIt,
                  onCompleted: onCompleted,
                  animate: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('step 1 is right-swipe with heart cue', (tester) async {
      await pumpOverlay(tester, onCompleted: () {});

      expect(find.byKey(overlay), findsOneWidget);
      expect(find.byKey(stepLike), findsOneWidget);
      expect(find.byKey(heart), findsOneWidget);
      expect(find.byKey(stepPass), findsNothing);
      expect(find.byKey(gotIt), findsNothing);
      expect(find.text('Swipe right to like.'), findsOneWidget);
      expect(find.text('Swipe left to pass.'), findsNothing);
    });

    testWidgets('step 2 is left-swipe with X cue and Got it', (tester) async {
      var completed = 0;
      await pumpOverlay(tester, onCompleted: () => completed++);

      await tester.tap(find.byKey(overlay));
      await tester.pump();

      expect(find.byKey(stepPass), findsOneWidget);
      expect(find.byKey(passIcon), findsOneWidget);
      expect(find.byKey(heart), findsNothing);
      expect(find.byKey(gotIt), findsOneWidget);
      expect(find.text('Swipe left to pass.'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      await tester.tap(find.byKey(gotIt));
      await tester.pump();
      expect(completed, 1);
    });

    testWidgets('TR copy is used for both steps', (tester) async {
      await pumpOverlay(
        tester,
        onCompleted: () {},
        locale: const Locale('tr'),
      );

      expect(find.text('Beğenmek için sağa kaydır.'), findsOneWidget);
      await tester.tap(find.byKey(overlay));
      await tester.pump();
      expect(find.text('Geçmek için sola kaydır.'), findsOneWidget);
      expect(find.text('Anladım'), findsOneWidget);
    });
  });

  group('gesture onboarding persistence', () {
    test('markSeen is local SharedPreferences and per viewer', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
      expect(await store.hasSeen(), isFalse);
      await store.markSeen();
      expect(await store.hasSeen(), isTrue);
      expect(
        store.storageKey,
        'qmatch_discover_gesture_onboarding_seen_v1_viewer-a',
      );

      final other = DiscoverGestureOnboardingStore(viewerUid: 'viewer-b');
      expect(await other.hasSeen(), isFalse);
    });

    test('clearSeen resets the local flag', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
      await store.markSeen();
      expect(await store.hasSeen(), isTrue);
      await store.clearSeen();
      expect(await store.hasSeen(), isFalse);
    });

    test('committed swipe count is local SharedPreferences and per viewer',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
      expect(await store.committedSwipeCount(), 0);
      expect(DiscoverGestureOnboardingStore.showSwipeStamps(0), isTrue);
      expect(DiscoverGestureOnboardingStore.showSwipeStamps(2), isTrue);
      expect(DiscoverGestureOnboardingStore.showSwipeStamps(3), isFalse);

      expect(await store.recordCommittedSwipe(), 1);
      expect(await store.recordCommittedSwipe(), 2);
      expect(await store.recordCommittedSwipe(), 3);
      expect(await store.committedSwipeCount(), 3);
      expect(
        DiscoverGestureOnboardingStore.showSwipeStamps(
          await store.committedSwipeCount(),
        ),
        isFalse,
      );
      expect(
        store.swipeCountStorageKey,
        'qmatch_discover_first_swipe_stamps_count_v1_viewer-a',
      );

      final other = DiscoverGestureOnboardingStore(viewerUid: 'viewer-b');
      expect(await other.committedSwipeCount(), 0);
      expect(
        DiscoverGestureOnboardingStore.showSwipeStamps(
          await other.committedSwipeCount(),
        ),
        isTrue,
      );
    });

    test('resetFirstUseGuidance clears seen flag and swipe count', () async {
      SharedPreferences.setMockInitialValues({});
      final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
      await store.markSeen();
      await store.recordCommittedSwipe();
      await store.recordCommittedSwipe();
      await store.recordCommittedSwipe();
      expect(await store.hasSeen(), isTrue);
      expect(await store.committedSwipeCount(), 3);

      await store.resetFirstUseGuidance();
      expect(await store.hasSeen(), isFalse);
      expect(await store.committedSwipeCount(), 0);
      expect(
        DiscoverGestureOnboardingStore.showSwipeStamps(
          await store.committedSwipeCount(),
        ),
        isTrue,
      );
    });
  });

  group('first visit after candidates load', () {
    testWidgets(
      'overlay stays hidden while loading then appears once a card is ready',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
        expect(await store.hasSeen(), isFalse);

        await tester.pumpWidget(
          _DiscoverPostLoadGuidanceHarness(store: store),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsNothing);
        expect(find.byKey(const Key('test-discover-loading')), findsOneWidget);

        await tester.tap(find.byKey(const Key('test-finish-load')));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsOneWidget);
        expect(find.text('Swipe right to like.'), findsOneWidget);
      },
    );

    testWidgets(
      'overlay stays hidden after load when the tutorial was already seen',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'qmatch_discover_gesture_onboarding_seen_v1_viewer-a': true,
        });
        final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');

        await tester.pumpWidget(
          _DiscoverPostLoadGuidanceHarness(store: store),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('test-finish-load')));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsNothing);
      },
    );
  });

  group('IndexedStack tutorial replay', () {
    testWidgets(
      'debug reset then return to Discover shows holographic overlay',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'qmatch_discover_gesture_onboarding_seen_v1_viewer-a': true,
          'qmatch_discover_first_swipe_stamps_count_v1_viewer-a': 3,
        });
        final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');
        expect(await store.hasSeen(), isTrue);
        expect(await store.committedSwipeCount(), 3);

        await tester.pumpWidget(_IndexedDiscoverReplayHarness(store: store));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsNothing);

        await tester.tap(find.byKey(const Key('test-go-other')));
        await tester.pump();

        await store.resetFirstUseGuidance();
        expect(await store.hasSeen(), isFalse);
        expect(await store.committedSwipeCount(), 0);

        await tester.tap(find.byKey(const Key('test-go-discover')));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsOneWidget);
        expect(find.text('Swipe right to like.'), findsOneWidget);
      },
    );

    testWidgets(
      'debug reset forces overlay while Discover stays selected',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'qmatch_discover_gesture_onboarding_seen_v1_viewer-a': true,
        });
        final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');

        await tester.pumpWidget(_IndexedDiscoverReplayHarness(store: store));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(overlay), findsNothing);

        await store.resetFirstUseGuidance();
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsOneWidget);
      },
    );

    testWidgets(
      'return to Discover keeps overlay hidden when already seen',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'qmatch_discover_gesture_onboarding_seen_v1_viewer-a': true,
        });
        final store = DiscoverGestureOnboardingStore(viewerUid: 'viewer-a');

        await tester.pumpWidget(_IndexedDiscoverReplayHarness(store: store));
        await tester.pump();
        await tester.pump();
        expect(find.byKey(overlay), findsNothing);

        await tester.tap(find.byKey(const Key('test-go-other')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('test-go-discover')));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(overlay), findsNothing);
      },
    );
  });

  group('Discover screen wiring (source)', () {
    test('first visit overlay is wired and persisted on Got it', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(src.contains('QMatchDiscoverGestureOnboarding'), isTrue);
      expect(src.contains('DiscoverGestureOnboardingStore'), isTrue);
      expect(src.contains('DiscoverGestureOnboardingTabSync'), isTrue);
      expect(src.contains('_completeGestureOnboarding'), isTrue);
      expect(src.contains('markSeen()'), isTrue);
      expect(src.contains('discoverGestureOnboardingGotIt'), isTrue);
      expect(src.contains('subdued: _showGestureOnboarding'), isTrue);
      expect(src.contains('_debugReplayGestureOnboarding'), isTrue);
      expect(src.contains('kDebugMode'), isTrue);
      expect(src.contains('likeUser'), isTrue);
      expect(src.contains('passUser'), isTrue);
      expect(src.contains('_syncFirstUseGuidanceFromStore()'), isTrue);
      expect(src.contains('guidanceRevision'), isTrue);
      expect(src.contains('resetFirstUseGuidance()'), isTrue);
      expect(src.contains('recordCommittedSwipe()'), isTrue);
      expect(src.contains('showSwipeStamps:'), isTrue);
    });

    test('IndexedStack tab return re-reads seen flag without remounting', () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final sync = File(
        'lib/features/discover/widgets/discover_gesture_onboarding_tab_sync.dart',
      ).readAsStringSync();
      final nav = File(
        'lib/core/navigation/main_navigation_screen.dart',
      ).readAsStringSync();
      expect(nav.contains('DiscoverScreen()'), isTrue);
      expect(screen.contains('DiscoverGestureOnboardingTabSync'), isTrue);
      expect(sync.contains('Visibility.of(context)'), isTrue);
      expect(sync.contains('hasSeen()'), isTrue);
      expect(sync.contains('onShowChanged(!seen)'), isTrue);
    });

    test('post-load re-check does not depend only on IndexedStack visibility',
        () {
      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(
          screen.contains('await _syncFirstUseGuidanceFromStore();'), isTrue);
      expect(screen.contains('_isLoading = false;'), isTrue);
      expect(screen.contains('_currentCandidate != null'), isTrue);
      expect(screen.contains('guidanceRevision'), isTrue);
    });

    test('debug hub can reset tutorial only behind kDebugMode', () {
      final debug = File(
        'lib/features/debug/debug_home_screen.dart',
      ).readAsStringSync();
      expect(debug.contains('if (!kDebugMode)'), isTrue);
      expect(debug.contains('debugReplayDiscoverTutorial'), isTrue);
      expect(debug.contains('resetFirstUseGuidance()'), isTrue);
      expect(debug.contains('qmatch-debug-replay-discover-tutorial'), isTrue);
    });

    test('holographic overlay uses tilted card and direction cues', () {
      final src = File(
        'lib/features/discover/widgets/qmatch_discover_gesture_onboarding.dart',
      ).readAsStringSync();
      expect(src.contains('_HolographicGhostCard'), isTrue);
      expect(src.contains('Transform.rotate'), isTrue);
      expect(src.contains('_TranslucentFinger'), isFalse);
      expect(src.contains('_GlowCue'), isTrue);
    });

    test('action bar remains icon-only in production widget', () {
      final src = File(
        'lib/features/discover/widgets/qmatch_discover_action_bar.dart',
      ).readAsStringSync();
      expect(src.contains('Icons.close_rounded'), isTrue);
      expect(src.contains('Icons.favorite_rounded'), isTrue);
      expect(src.contains('child: Text('), isFalse);
      expect(src.contains('passLabel,'), isTrue);
      expect(src.contains('likeLabel,'), isTrue);
      expect(src.contains('subdued'), isTrue);
      expect(src.contains('Ink('), isFalse);
      expect(src.contains('InkWell'), isFalse);
      expect(src.contains('Material('), isFalse);
      expect(src.contains('BoxShape.circle'), isTrue);
    });
  });
}

class _IndexedDiscoverReplayHarness extends StatefulWidget {
  const _IndexedDiscoverReplayHarness({required this.store});

  final DiscoverGestureOnboardingStore store;

  @override
  State<_IndexedDiscoverReplayHarness> createState() =>
      _IndexedDiscoverReplayHarnessState();
}

class _IndexedDiscoverReplayHarnessState
    extends State<_IndexedDiscoverReplayHarness> {
  int _index = 0;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    DiscoverGestureOnboardingStore.guidanceRevision.addListener(_syncFromStore);
  }

  @override
  void dispose() {
    DiscoverGestureOnboardingStore.guidanceRevision
        .removeListener(_syncFromStore);
    super.dispose();
  }

  Future<void> _syncFromStore() async {
    final seen = await widget.store.hasSeen();
    if (!mounted) return;
    if (_show == !seen) return;
    setState(() => _show = !seen);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  DiscoverGestureOnboardingTabSync(
                    store: widget.store,
                    onShowChanged: (show) {
                      if (_show == show) return;
                      setState(() => _show = show);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(
                          color: Colors.black,
                          child: Center(child: Text('card')),
                        ),
                        if (_show)
                          QMatchDiscoverGestureOnboarding(
                            swipeRightText: 'Swipe right to like.',
                            swipeLeftText: 'Swipe left to pass.',
                            gotItLabel: 'Got it',
                            onCompleted: () {},
                            animate: false,
                          ),
                      ],
                    ),
                  ),
                  const Center(child: Text('other tab')),
                ],
              ),
            ),
            TextButton(
              key: const Key('test-go-other'),
              onPressed: () => setState(() => _index = 1),
              child: const Text('Other'),
            ),
            TextButton(
              key: const Key('test-go-discover'),
              onPressed: () => setState(() => _index = 0),
              child: const Text('Discover'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors DiscoverScreen: TabSync may fire while loading, overlay only after
/// the first candidate is available and prefs are re-read.
class _DiscoverPostLoadGuidanceHarness extends StatefulWidget {
  const _DiscoverPostLoadGuidanceHarness({required this.store});

  final DiscoverGestureOnboardingStore store;

  @override
  State<_DiscoverPostLoadGuidanceHarness> createState() =>
      _DiscoverPostLoadGuidanceHarnessState();
}

class _DiscoverPostLoadGuidanceHarnessState
    extends State<_DiscoverPostLoadGuidanceHarness> {
  bool _isLoading = true;
  bool _hasCandidate = false;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    DiscoverGestureOnboardingStore.guidanceRevision.addListener(_syncFromStore);
  }

  @override
  void dispose() {
    DiscoverGestureOnboardingStore.guidanceRevision
        .removeListener(_syncFromStore);
    super.dispose();
  }

  Future<void> _syncFromStore() async {
    final seen = await widget.store.hasSeen();
    if (!mounted) return;
    final show = !seen && !_isLoading && _hasCandidate;
    if (_show == show) return;
    setState(() => _show = show);
  }

  Future<void> _finishLoad() async {
    setState(() {
      _isLoading = false;
      _hasCandidate = true;
    });
    await _syncFromStore();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: DiscoverGestureOnboardingTabSync(
                store: widget.store,
                onShowChanged: (_) {
                  _syncFromStore();
                },
                child: _isLoading
                    ? const Center(
                        key: Key('test-discover-loading'),
                        child: CircularProgressIndicator(),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(
                            color: Colors.black,
                            child: Center(child: Text('card')),
                          ),
                          if (_show)
                            QMatchDiscoverGestureOnboarding(
                              swipeRightText: 'Swipe right to like.',
                              swipeLeftText: 'Swipe left to pass.',
                              gotItLabel: 'Got it',
                              onCompleted: () {},
                              animate: false,
                            ),
                        ],
                      ),
              ),
            ),
            TextButton(
              key: const Key('test-finish-load'),
              onPressed: _finishLoad,
              child: const Text('Finish load'),
            ),
          ],
        ),
      ),
    );
  }
}
