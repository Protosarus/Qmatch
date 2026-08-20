import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_trusted_l2_client.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  String getCandidatesBody() {
    final src = read('lib/features/discover/services/discover_service.dart');
    final start = src.indexOf(
      'Future<List<DiscoverUserModel>> getCandidates({int limit = 30}) async {',
    );
    final end = src.indexOf(
      'Future<void> _hydrateViewerLegacyFrequencyMirrors({',
    );
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    return src.substring(start, end);
  }

  String firestoreBatchWait() {
    final body = getCandidatesBody();
    final start = body.indexOf("QmatchPerf.trace('discover.firestore_batch'");
    final end = body.indexOf('final meDoc = started[0]');
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    return body.substring(start, end);
  }

  test('four Discover read timers wrap the existing Future.wait legs only', () {
    final wait = firestoreBatchWait();
    expect(
        wait.contains("where('discover_eligible', isEqualTo: true)"), isTrue);
    expect(wait.contains('.limit(batchSize)'), isTrue);
    expect(wait.contains('orderBy'), isFalse);
    expect(wait.contains('startAfter'), isFalse);
    expect(wait.contains('FirestorePaths.userDoc(currentUid).get()'), isTrue);
    expect(wait.contains('_swipeService.getMySwipedUserIds()'), isTrue);
    expect(wait.contains('_loadBlockedByMe()'), isTrue);

    final me = wait.indexOf("'discover.me_get'");
    final swipes = wait.indexOf("'discover.swipes_get'");
    final blocks = wait.indexOf("'discover.blocks_get'");
    final eligible = wait.indexOf("'discover.eligible_query'");
    final meGet = wait.indexOf('FirestorePaths.userDoc(currentUid).get()');
    final swipesGet = wait.indexOf('_swipeService.getMySwipedUserIds()');
    final blocksGet = wait.indexOf('_loadBlockedByMe()');
    final eligibleGet = wait.indexOf('.limit(batchSize)');
    expect(me, greaterThanOrEqualTo(0));
    expect(swipes, greaterThan(me));
    expect(blocks, greaterThan(swipes));
    expect(eligible, greaterThan(blocks));
    expect(meGet, greaterThan(me));
    expect(meGet, lessThan(swipes));
    expect(swipesGet, greaterThan(swipes));
    expect(swipesGet, lessThan(blocks));
    expect(blocksGet, greaterThan(blocks));
    expect(blocksGet, lessThan(eligible));
    expect(eligibleGet, greaterThan(eligible));
  });

  test('L1-L5 and trusted L2 ranking path are unchanged', () {
    final body = getCandidatesBody();
    expect(body.contains('DiscoverL1EligibilityGate'), isTrue);
    expect(body.contains('applyTrustedMembership'), isTrue);
    expect(body.contains('DiscoverStructuralL2Ranking.rankL1Batch'), isTrue);
    expect(body.contains("QmatchPerf.trace(\n      'discover.l2_callable'"),
        isTrue);
    expect(body.contains('_trustedL2Batch('), isTrue);
    expect(body.contains('compareDiscoverCandidates'), isTrue);

    final service =
        read('lib/features/discover/services/discover_service.dart');
    expect(
      service.contains('DiscoverStageB2TrustedL2Client()'),
      isTrue,
    );
    expect(service.contains('useEuropeWest1: true'), isFalse);
    expect(service.contains('useUsCentral1: true'), isFalse);
    expect(service.contains('DiscoverStageB2TrustedL2Client('), isTrue);

    final screen = read('lib/features/discover/screens/discover_screen.dart');
    expect(screen.contains('DiscoverService()'), isTrue);
  });

  test('release/default path uses europe-west1 compareStageB2StructuralEu', () {
    final src = read(
      'lib/features/discover/services/discover_stage_b2_trusted_l2_client.dart',
    );
    expect(src.contains("callableName = 'compareStageB2Structural'"), isTrue);
    expect(
      src.contains("euCallableName = 'compareStageB2StructuralEu'"),
      isTrue,
    );
    expect(src.contains("usRegion = 'us-central1'"), isTrue);
    expect(src.contains("euRegion = 'europe-west1'"), isTrue);
    expect(src.contains('if (!kDebugMode) return true;'), isTrue);
    expect(
      src.contains('FirebaseFunctions.instanceFor(region: region)'),
      isTrue,
    );
    expect(src.contains('FirebaseFunctions.instance;'), isFalse);
    expect(src.contains("'discover.l2_us'"), isTrue);
    expect(src.contains("'discover.l2_eu'"), isTrue);
    expect(src.contains('candidate_uids'), isTrue);
    expect(RegExp(r'debugPrint\([^)]*uid').hasMatch(src), isFalse);

    final client = DiscoverStageB2TrustedL2Client();
    expect(client.resolvedCallableName, 'compareStageB2StructuralEu');
    expect(client.resolvedRegion, 'europe-west1');
    expect(client.usesEuropeWest1, isTrue);
  });

  test('debug rollback path to us-central1 still exists', () {
    final src = read(
      'lib/features/discover/services/discover_stage_b2_trusted_l2_client.dart',
    );
    expect(src.contains('debugUseUsCentral1'), isTrue);
    expect(src.contains('QMATCH_DISCOVER_L2_US'), isTrue);
    expect(src.contains('useUsCentral1'), isTrue);

    final rollback = DiscoverStageB2TrustedL2Client(useUsCentral1: true);
    expect(rollback.usesEuropeWest1, isFalse);
    expect(rollback.resolvedCallableName, 'compareStageB2Structural');
    expect(rollback.resolvedRegion, 'us-central1');
  });
}
