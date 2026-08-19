import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_trusted_l2_client.dart';

void main() {
  setUp(() {
    DiscoverStageB2TrustedL2Client.debugUseEuropeWest1 = false;
  });

  tearDown(() {
    DiscoverStageB2TrustedL2Client.debugUseEuropeWest1 = false;
  });

  test('trusted L2 client maps L1 uids to public pair fields only', () async {
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        expect(name, DiscoverStageB2TrustedL2Client.callableName);
        expect(data['candidate_uids'], ['c1', 'c2']);
        return {
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.12,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
              'measured_dimensions': [
                {'dimension_id': 'empathy', 'value': 0.9},
              ],
              'logical_reasoning': 0.4,
            },
            {
              'available': false,
              'total_coverage': 0.0,
              'comparable_dimensions': 0,
              'unavailable_reason': 'candidate_canonical_profile_missing',
            },
          ],
        };
      },
    );

    final batch = await client.compareForL1Batch(candidateUids: ['c1', 'c2']);
    expect(batch.callableFailed, isFalse);
    expect(batch.returnedUids, ['c1', 'c2']);
    expect(batch.pairs, hasLength(2));
    expect(batch.pairs[0].available, isTrue);
    expect(batch.pairs[0].structuralDistance, 0.12);
    expect(batch.pairs[0].comparableDimensions, 20);
    expect(batch.pairs[1].available, isFalse);
    expect(batch.pairs[1].structuralDistance, isNull);
    expect(
      batch.pairs[1].unavailableReason,
      'candidate_canonical_profile_missing',
    );
  });

  test('omitted candidate_uids drop reverse-blocked UIDs without block fields',
      () async {
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        expect(data['candidate_uids'], ['ok', 'blocked_me']);
        return {
          'candidate_uids': ['ok'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.08,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
              'reason': 'secret-block-reason',
              'omitted_uids': ['blocked_me'],
            },
          ],
        };
      },
    );

    final batch = await client.compareForL1Batch(
      candidateUids: ['ok', 'blocked_me'],
    );
    expect(batch.returnedUids, ['ok']);
    expect(batch.pairs, hasLength(1));
    expect(batch.pairsByUid.keys, ['ok']);
    expect(batch.pairs[0].unavailableReason, isNull);
  });

  test('non-list pairs is callableFailed and must fail-close membership',
      () async {
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async => {'pairs': 'bad'},
    );
    final batch = await client.compareForL1Batch(
      candidateUids: ['a', 'b'],
    );
    expect(batch.callableFailed, isTrue);
    expect(batch.returnedUids, ['a', 'b']);
  });

  test('default debug path stays on us-central1 compareStageB2Structural',
      () async {
    String? seenName;
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        seenName = name;
        return {
          'candidate_uids': data['candidate_uids'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.1,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
            },
          ],
        };
      },
    );
    expect(client.usesEuropeWest1, isFalse);
    expect(client.resolvedCallableName, 'compareStageB2Structural');
    expect(client.resolvedRegion, 'us-central1');
    await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2Structural');
  });

  test('debug switch can call compareStageB2StructuralEu in europe-west1',
      () async {
    String? seenName;
    final client = DiscoverStageB2TrustedL2Client(
      useEuropeWest1: true,
      call: (name, data) async {
        seenName = name;
        expect(data['candidate_uids'], ['c1']);
        return {
          'candidate_uids': ['c1'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.1,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
            },
          ],
        };
      },
    );
    expect(client.usesEuropeWest1, isTrue);
    expect(client.resolvedCallableName, 'compareStageB2StructuralEu');
    expect(client.resolvedRegion, 'europe-west1');
    final batch = await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2StructuralEu');
    expect(batch.callableFailed, isFalse);
    expect(batch.returnedUids, ['c1']);
    expect(batch.pairs[0].structuralDistance, 0.1);
  });

  test('debugUseEuropeWest1 runtime flag selects EU without ranking changes',
      () async {
    DiscoverStageB2TrustedL2Client.debugUseEuropeWest1 = true;
    String? seenName;
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, _) async {
        seenName = name;
        return {
          'candidate_uids': ['c1'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.42,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
            },
          ],
        };
      },
    );
    expect(client.usesEuropeWest1, isTrue);
    final batch = await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2StructuralEu');
    expect(batch.pairs[0].structuralDistance, 0.42);
  });
}
