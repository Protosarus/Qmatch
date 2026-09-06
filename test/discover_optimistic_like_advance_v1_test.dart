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
      expect(likeBody.contains('_advanceDeck()'), isTrue);
      expect(likeBody.contains('await likeFuture'), isTrue);
      expect(likeBody.contains('unawaited'), isTrue);
      expect(
        likeBody.indexOf('likeUser(c.uid)') <
            likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration'),
        isTrue,
      );
      expect(
        likeBody.indexOf('QMatchDiscoverSwipeableCard.flyOffDuration') <
            likeBody.indexOf('_advanceDeck()'),
        isTrue,
      );
      // Match dialog waits only on callable — not on fly-off / _advance.
      expect(
        likeBody.indexOf('await likeFuture') <
            likeBody.indexOf('showQMatchDiscoverMatchDialog'),
        isTrue,
      );
      expect(likeBody.contains('match.dialog_show'), isTrue);
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
      final passIdx = src.indexOf('Future<void> _onPass() {');
      final likeIdx = src.indexOf('Future<void> _onLike() async {');
      expect(passIdx, greaterThanOrEqualTo(0));
      expect(likeIdx, greaterThan(passIdx));
      final passBody = src.substring(passIdx, likeIdx);
      expect(passBody.contains('_isActionLoading = true'), isTrue);
      expect(passBody.contains('_passUser(c.uid)'), isTrue);
      expect(
        passBody.indexOf('_passUser(c.uid)') <
            passBody.indexOf('_advanceDeck()'),
        isTrue,
      );
      expect(passBody.contains('likeUser'), isFalse);
    });

    test('fly-off duration is the swipeable card constant', () {
      expect(
        QMatchDiscoverSwipeableCard.flyOffDuration,
        const Duration(milliseconds: 100),
      );
    });
  });
}
