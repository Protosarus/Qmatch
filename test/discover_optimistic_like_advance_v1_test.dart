import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_swipeable_card.dart';

void main() {
  group('Discover optimistic Like advance', () {
    test('Like starts callable, advances after fly-off, no global lock', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final likeIdx = src.indexOf('Future<void> _onLike() async {');
      final buildIdx = src.indexOf('Widget build(BuildContext context)');
      expect(likeIdx, greaterThanOrEqualTo(0));
      expect(buildIdx, greaterThan(likeIdx));
      final likeBody = src.substring(likeIdx, buildIdx);

      expect(likeBody.contains('_likeDispatchedUids.add(c.uid)'), isTrue);
      expect(likeBody.contains('likeUser(c.uid)'), isTrue);
      expect(
        likeBody.contains('QMatchDiscoverSwipeableCard.flyOffDuration'),
        isTrue,
      );
      expect(likeBody.contains('_advance()'), isTrue);
      expect(likeBody.contains('await likeFuture'), isTrue);
      expect(
        likeBody.indexOf('likeUser(c.uid)') <
            likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration'),
        isTrue,
      );
      expect(
        likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration') <
            likeBody.indexOf('_advance()'),
        isTrue,
      );
      expect(
        likeBody.indexOf('_advance()') < likeBody.indexOf('await likeFuture'),
        isTrue,
      );
      expect(likeBody.contains('_isActionLoading'), isFalse);
      expect(likeBody.contains('_loadCandidates'), isFalse);
      expect(likeBody.contains('rankL1Batch'), isFalse);
      expect(likeBody.contains('getCandidates'), isFalse);
      expect(likeBody.contains('LikeMatchOutcome.createdNewMatch'), isTrue);
      expect(likeBody.contains('showQMatchDiscoverMatchDialog'), isTrue);
      expect(likeBody.contains('discoverActionFailed'), isTrue);
    });

    test('Pass still awaits then advances under the action lock', () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final passIdx = src.indexOf('Future<void> _onPass() async {');
      final likeIdx = src.indexOf('Future<void> _onLike() async {');
      expect(passIdx, greaterThanOrEqualTo(0));
      expect(likeIdx, greaterThan(passIdx));
      final passBody = src.substring(passIdx, likeIdx);
      expect(passBody.contains('_isActionLoading = true'), isTrue);
      expect(passBody.contains('passUser(c.uid)'), isTrue);
      expect(
        passBody.indexOf('await _swipeService.passUser') <
            passBody.indexOf('_advance()'),
        isTrue,
      );
      expect(passBody.contains('likeUser'), isFalse);
    });

    test('fly-off duration is the swipeable card constant', () {
      expect(
        QMatchDiscoverSwipeableCard.flyOffDuration,
        const Duration(milliseconds: 220),
      );
    });
  });
}
