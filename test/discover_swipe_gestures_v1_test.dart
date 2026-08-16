import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const swipeKey = Key('qmatch-discover-swipeable-card');
  const likeOverlay = Key('qmatch-discover-swipe-like-overlay');
  const passOverlay = Key('qmatch-discover-swipe-pass-overlay');
  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');

  Future<void> pumpHarness(
    WidgetTester tester, {
    required VoidCallback onLike,
    required VoidCallback onPass,
    bool enabled = true,
    bool showSwipeStamps = true,
    String candidateId = 'cand-1',
    double threshold = 80,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: QMatchDiscoverSwipeableCard(
                  candidateId: candidateId,
                  enabled: enabled,
                  showSwipeStamps: showSwipeStamps,
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

  testWidgets('swipe right past threshold calls onLike once', (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpHarness(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(likes, 1);
    expect(passes, 0);
  });

  testWidgets('swipe left past threshold calls onPass once', (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpHarness(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.drag(find.byKey(swipeKey), const Offset(-140, 0));
    await tester.pumpAndSettle();

    expect(passes, 1);
    expect(likes, 0);
  });

  testWidgets('drag below threshold snaps back and does not act',
      (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpHarness(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.drag(find.byKey(swipeKey), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(likes, 0);
    expect(passes, 0);
  });

  testWidgets('Like/Pass buttons call the same handlers as swipes',
      (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpHarness(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.tap(find.byKey(likeButton));
    await tester.pump();
    expect(likes, 1);

    await tester.tap(find.byKey(passButton));
    await tester.pump();
    expect(passes, 1);
  });

  testWidgets('disabled card ignores swipe and buttons', (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpHarness(
      tester,
      enabled: false,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.drag(find.byKey(swipeKey), const Offset(160, 0));
    await tester.pump();
    await tester.tap(find.byKey(likeButton), warnIfMissed: false);
    await tester.tap(find.byKey(passButton), warnIfMissed: false);
    await tester.pump();

    expect(likes, 0);
    expect(passes, 0);
  });

  testWidgets('second swipe while first is processing is ignored',
      (tester) async {
    var likes = 0;
    await pumpHarness(
      tester,
      onLike: () => likes++,
      onPass: () {},
    );

    await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
    await tester.pump();
    expect(likes, 1);

    await tester.drag(find.byKey(swipeKey), const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(likes, 1);
  });

  testWidgets('drag right reveals Like overlay before release', (tester) async {
    await pumpHarness(
      tester,
      onLike: () {},
      onPass: () {},
    );

    final center = tester.getCenter(find.byKey(swipeKey));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();

    expect(find.byKey(likeOverlay), findsOneWidget);
    expect(find.text('LIKE'), findsOneWidget);

    await gesture.moveBy(const Offset(-180, 0));
    await tester.pump();
    expect(find.text('PASS'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('stamps stay hidden after first-three-swipes tutorial',
      (tester) async {
    await pumpHarness(
      tester,
      onLike: () {},
      onPass: () {},
      showSwipeStamps: false,
    );

    final center = tester.getCenter(find.byKey(swipeKey));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();

    expect(find.byKey(likeOverlay), findsNothing);
    expect(find.byKey(passOverlay), findsNothing);
    expect(find.text('LIKE'), findsNothing);
    expect(find.text('PASS'), findsNothing);

    await gesture.moveBy(const Offset(-180, 0));
    await tester.pump();
    expect(find.text('LIKE'), findsNothing);
    expect(find.text('PASS'), findsNothing);
    expect(find.byKey(swipeKey), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('action bar stays icon-only while card stamps can show',
      (tester) async {
    await pumpHarness(
      tester,
      onLike: () {},
      onPass: () {},
    );

    expect(find.byKey(likeButton), findsOneWidget);
    expect(find.byKey(passButton), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('Pass'), findsNothing);
    expect(find.text('Like'), findsNothing);
  });
}
