import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/widgets/qmatch_glass_icon_button.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');

  BoxDecoration decorationOf(WidgetTester tester, Key key) {
    return tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
  }

  bool isGlowing(BoxDecoration deco) =>
      deco.boxShadow != null && deco.boxShadow!.isNotEmpty;

  Future<void> pumpBar(
    WidgetTester tester, {
    required VoidCallback? onLike,
    required VoidCallback? onPass,
    bool isActionLoading = false,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QMatchDiscoverActionBar(
            passLabel: 'Pass',
            likeLabel: 'Like',
            onPass: onPass,
            onLike: onLike,
            isActionLoading: isActionLoading,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('heart tap activates heart only', (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpBar(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.tap(find.byKey(likeButton));
    await tester.pump();

    expect(isGlowing(decorationOf(tester, likeButton)), isTrue);
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);
    expect(
      decorationOf(tester, likeButton).color,
      isNot(QMatchGlassIconButton.glassFill),
    );
    expect(
      decorationOf(tester, passButton).color,
      QMatchGlassIconButton.glassFill,
    );
    expect(likes, 1);
    expect(passes, 0);
  });

  testWidgets('X tap activates X only', (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpBar(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.tap(find.byKey(passButton));
    await tester.pump();

    expect(isGlowing(decorationOf(tester, passButton)), isTrue);
    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
    expect(
      decorationOf(tester, passButton).color,
      isNot(QMatchGlassIconButton.glassFill),
    );
    expect(
      decorationOf(tester, likeButton).color,
      QMatchGlassIconButton.glassFill,
    );
    expect(passes, 1);
    expect(likes, 0);
  });

  testWidgets('opposite button stays neutral during a tap pulse',
      (tester) async {
    await pumpBar(
      tester,
      onLike: () {},
      onPass: () {},
    );

    await tester.tap(find.byKey(likeButton));
    await tester.pump();
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);

    await tester.pump(QMatchDiscoverActionBar.tapFeedbackDuration);
    await tester.pump();

    await tester.tap(find.byKey(passButton));
    await tester.pump();
    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
  });

  testWidgets('feedback clears after the tap pulse', (tester) async {
    await pumpBar(
      tester,
      onLike: () {},
      onPass: () {},
    );

    await tester.tap(find.byKey(likeButton));
    await tester.pump();
    expect(isGlowing(decorationOf(tester, likeButton)), isTrue);

    await tester.pump(QMatchDiscoverActionBar.tapFeedbackDuration);
    await tester.pump();
    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);
    expect(
      decorationOf(tester, likeButton).color,
      QMatchGlassIconButton.glassFill,
    );
  });

  testWidgets('failed action does not leave feedback stuck', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var attempts = 0;
    var loading = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return QMatchDiscoverActionBar(
                passLabel: 'Pass',
                likeLabel: 'Like',
                onPass: loading
                    ? null
                    : () {
                        attempts++;
                        setState(() => loading = true);
                      },
                onLike: loading ? null : () {},
                isActionLoading: loading,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(passButton));
    await tester.pump();
    expect(attempts, 1);
    expect(isGlowing(decorationOf(tester, passButton)), isTrue);

    await tester.pump(QMatchDiscoverActionBar.tapFeedbackDuration);
    await tester.pump();
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);
    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
  });

  testWidgets('handlers still fire exactly once while a tap is committing',
      (tester) async {
    var likes = 0;
    var passes = 0;
    await pumpBar(
      tester,
      onLike: () => likes++,
      onPass: () => passes++,
    );

    await tester.tap(find.byKey(likeButton));
    await tester.tap(find.byKey(likeButton));
    await tester.pump();
    expect(likes, 1);
    expect(passes, 0);

    await tester.pump(QMatchDiscoverActionBar.tapFeedbackDuration);
    await tester.pump();

    await tester.tap(find.byKey(passButton));
    await tester.tap(find.byKey(passButton));
    await tester.pump();
    expect(passes, 1);
    expect(likes, 1);
  });

  test('tap pulse is shorter than card fly-off and reuses swipe activation',
      () {
    expect(
      QMatchDiscoverActionBar.tapFeedbackDuration,
      const Duration(milliseconds: 160),
    );
    expect(
      QMatchDiscoverActionBar.tapFeedbackDuration <
          QMatchDiscoverSwipeableCard.flyOffDuration,
      isTrue,
    );
  });

  test('Discover screen does not delay Like/Pass for the tap pulse', () {
    final src = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();
    expect(src.contains('onLike: _onLike,'), isTrue);
    expect(src.contains('onPass: _onPass,'), isTrue);
    expect(src.contains('_onLikeFromActionBar'), isTrue);
    expect(src.contains('tapFeedbackDuration'), isFalse);

    final likeIdx = src.indexOf('Future<void> _onLike() async {');
    final fromBarIdx = src.indexOf('void _onLikeFromActionBar()');
    expect(likeIdx, greaterThanOrEqualTo(0));
    expect(fromBarIdx, greaterThan(likeIdx));
    final likeBody = src.substring(likeIdx, fromBarIdx);
    expect(likeBody.contains('likeUser(c.uid)'), isTrue);
    expect(likeBody.contains('_likeDispatchedUids.add(c.uid)'), isTrue);
    expect(likeBody.contains('_startTapPulse'), isFalse);
    expect(likeBody.contains('_tapFeedback'), isFalse);
  });
}
