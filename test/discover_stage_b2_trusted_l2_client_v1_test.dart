import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_dual_path_collector.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_trusted_l2_client.dart';

void main() {
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

    final pairs = await client.compareForL1Batch(candidateUids: ['c1', 'c2']);
    expect(pairs, hasLength(2));
    expect(pairs[0].available, isTrue);
    expect(pairs[0].structuralDistance, 0.12);
    expect(pairs[0].comparableDimensions, 20);
    expect(pairs[1].available, isFalse);
    expect(pairs[1].structuralDistance, isNull);
    expect(
      pairs[1].unavailableReason,
      'candidate_canonical_profile_missing',
    );
  });
}
