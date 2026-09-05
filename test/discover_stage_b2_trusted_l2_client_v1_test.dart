import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/services/discover_stage_b2_trusted_l2_client.dart';

void main() {
  setUp(() {
    DiscoverStageB2TrustedL2Client.debugUseUsCentral1 = false;
  });

  tearDown(() {
    DiscoverStageB2TrustedL2Client.debugUseUsCentral1 = false;
  });

  test('trusted L2 client maps L1 uids to public pair fields only', () async {
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        expect(name, DiscoverStageB2TrustedL2Client.euCallableName);
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

  test('default/release client uses europe-west1 compareStageB2StructuralEu',
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
    expect(client.usesEuropeWest1, isTrue);
    expect(client.resolvedCallableName, 'compareStageB2StructuralEu');
    expect(client.resolvedRegion, 'europe-west1');
    await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2StructuralEu');
    expect(seenName, isNot('compareStageB2Structural'));
  });

  test('debug rollback can call compareStageB2Structural in us-central1',
      () async {
    String? seenName;
    final client = DiscoverStageB2TrustedL2Client(
      useUsCentral1: true,
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
    expect(client.usesEuropeWest1, isFalse);
    expect(client.resolvedCallableName, 'compareStageB2Structural');
    expect(client.resolvedRegion, 'us-central1');
    final batch = await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2Structural');
    expect(batch.callableFailed, isFalse);
    expect(batch.returnedUids, ['c1']);
    expect(batch.pairs[0].structuralDistance, 0.1);
  });

  test(
      'debugUseUsCentral1 runtime flag rolls back to US without ranking changes',
      () async {
    DiscoverStageB2TrustedL2Client.debugUseUsCentral1 = true;
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
    expect(client.usesEuropeWest1, isFalse);
    final batch = await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seenName, 'compareStageB2Structural');
    expect(batch.pairs[0].structuralDistance, 0.42);
  });

  test(
      'default request omits V2 opt-in and ignores nested frequency_v2 if absent',
      () async {
    Map<String, dynamic>? seen;
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        seen = data;
        return {
          'candidate_uids': ['c1'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.11,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
            },
          ],
        };
      },
    );
    final batch = await client.compareForL1Batch(candidateUids: ['c1']);
    expect(seen!.keys, ['candidate_uids']);
    expect(seen!.containsKey('include_frequency_v2_diagnostics'), isFalse);
    expect(seen!.containsKey('include_compatibility_v2_diagnostics'), isFalse);
    expect(batch.pairs[0].frequencyV2, isNull);
    expect(batch.pairs[0].compatibilityV2, isNull);
    expect(batch.pairs[0].structuralDistance, 0.11);
  });

  test('opt-in parses aggregate V2 diagnostic and drops privacy fields',
      () async {
    Map<String, dynamic>? seen;
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        seen = data;
        return {
          'candidate_uids': ['c1'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.2,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
              'frequency_v2': {
                'available': true,
                'frequency_fit_index': 87.5,
                'overall_supported_fit': 0.875,
                'overall_pair_support': 0.9,
                'pair_fit_version': 'frequency_behavior_v2_pair_fit_v1',
                'normalized_behavior': 0.4,
                'x_a': 0.9,
                'session_id': 'secret',
                'contact_need': 0.1,
              },
            },
          ],
        };
      },
    );
    final batch = await client.compareForL1Batch(
      candidateUids: ['c1'],
      includeFrequencyV2Diagnostics: true,
    );
    expect(seen!['include_frequency_v2_diagnostics'], isTrue);
    expect(batch.pairs[0].structuralDistance, 0.2);
    expect(batch.pairs[0].frequencyV2!.available, isTrue);
    expect(batch.pairs[0].frequencyV2!.frequencyFitIndex, 87.5);
    expect(batch.pairs[0].frequencyV2!.overallSupportedFit, 0.875);
    expect(batch.pairs[0].frequencyV2!.overallPairSupport, 0.9);
    expect(
      batch.pairs[0].frequencyV2!.pairFitVersion,
      'frequency_behavior_v2_pair_fit_v1',
    );
  });

  test('production DiscoverService does not enable V2 diagnostics', () {
    final src = File(
      'lib/features/discover/services/discover_service.dart',
    ).readAsStringSync();
    expect(src.contains('includeFrequencyV2Diagnostics: true'), isFalse);
    expect(
      src.contains('include_frequency_v2_diagnostics'),
      isFalse,
    );
  });

  test('opt-in parses compatibility_v2 and drops privacy fields', () async {
    Map<String, dynamic>? seen;
    final client = DiscoverStageB2TrustedL2Client(
      call: (name, data) async {
        seen = data;
        return {
          'candidate_uids': ['c1'],
          'pairs': [
            {
              'available': true,
              'structural_distance': 0.2,
              'total_coverage': 1.0,
              'comparable_dimensions': 20,
              'compatibility_v2': {
                'available': true,
                'compatibility_index': 75.0,
                'policy_version': 'qmatch_compatibility_fusion_v2_policy_v1',
                'structural_fit': 1.0,
                'frequency_fit': 0.5,
                'structural_coverage': 1.0,
                'frequency_pair_support': 0.0,
                'logical_reasoning': 0.9,
                'normalized_behavior': 0.4,
                'session_id': 'secret',
                'contact_need': 0.1,
              },
            },
          ],
        };
      },
    );
    final batch = await client.compareForL1Batch(
      candidateUids: ['c1'],
      includeCompatibilityV2Diagnostics: true,
    );
    expect(seen!['include_compatibility_v2_diagnostics'], isTrue);
    expect(seen!.containsKey('include_frequency_v2_diagnostics'), isFalse);
    expect(batch.pairs[0].structuralDistance, 0.2);
    expect(batch.pairs[0].compatibilityV2!.available, isTrue);
    expect(batch.pairs[0].compatibilityV2!.compatibilityIndex, 75.0);
    expect(
      batch.pairs[0].compatibilityV2!.policyVersion,
      'qmatch_compatibility_fusion_v2_policy_v1',
    );
    expect(batch.pairs[0].compatibilityV2!.structuralFit, 1.0);
    expect(batch.pairs[0].compatibilityV2!.frequencyFit, 0.5);
  });

  test('production DiscoverService enables live compatibility fusion', () {
    final src = File(
      'lib/features/discover/services/discover_service.dart',
    ).readAsStringSync();
    expect(src.contains('includeCompatibilityV2Diagnostics: true'), isTrue);
    expect(src.contains('includeFrequencyV2Diagnostics: true'), isFalse);
  });
}
