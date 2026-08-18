import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/qmatch_glass_icon_button.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const swipeKey = Key('qmatch-discover-swipeable-card');
  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');

  Future<void> pumpHarness(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var feedback = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Expanded(
                    child: QMatchDiscoverSwipeableCard(
                      candidateId: 'cand-1',
                      dragThreshold: 80,
                      likeLabel: 'Like',
                      passLabel: 'Pass',
                      onLike: () {},
                      onPass: () {},
                      onSwipeFeedback: (value) =>
                          setState(() => feedback = value),
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
                    onPass: () {},
                    onLike: () {},
                    isActionLoading: false,
                    swipeFeedback: feedback,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

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

  testWidgets('right drag activates heart only', (tester) async {
    await pumpHarness(tester);

    final center = tester.getCenter(find.byKey(swipeKey));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();

    final like = decorationOf(tester, likeButton);
    final pass = decorationOf(tester, passButton);
    expect(isGlowing(like), isTrue);
    expect(isGlowing(pass), isFalse);
    expect(like.color, isNot(QMatchGlassIconButton.glassFill));
    expect(pass.color, QMatchGlassIconButton.glassFill);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('left drag activates X only', (tester) async {
    await pumpHarness(tester);

    final center = tester.getCenter(find.byKey(swipeKey));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    final like = decorationOf(tester, likeButton);
    final pass = decorationOf(tester, passButton);
    expect(isGlowing(pass), isTrue);
    expect(isGlowing(like), isFalse);
    expect(pass.color, isNot(QMatchGlassIconButton.glassFill));
    expect(like.color, QMatchGlassIconButton.glassFill);
    expect(pass.color, isNot(AppColors.resonanceViolet.withValues(alpha: 0.88)));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('neutral drag activates neither', (tester) async {
    await pumpHarness(tester);

    final center = tester.getCenter(find.byKey(swipeKey));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(12, 0));
    await tester.pump();

    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);

    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    expect(isGlowing(decorationOf(tester, likeButton)), isTrue);

    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(isGlowing(decorationOf(tester, likeButton)), isFalse);
    expect(isGlowing(decorationOf(tester, passButton)), isFalse);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
