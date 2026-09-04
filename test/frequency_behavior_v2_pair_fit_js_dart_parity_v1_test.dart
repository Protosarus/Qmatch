import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

const _tol = 1e-9;

FrequencyBehaviorV2PairFitResult _fitFixtureUsers(
  Map<String, dynamic> userA,
  Map<String, dynamic> userB,
) {
  const pairs = FrequencyBehaviorV2PairRelationComputer();
  const fit = FrequencyBehaviorV2PairFitComputer();
  final nbA = Map<String, dynamic>.from(userA['normalized_behavior'] as Map);
  final pcA = Map<String, dynamic>.from(userA['provisional_confidence'] as Map);
  final ccA = Map<String, dynamic>.from(userA['confidence_completeness'] as Map);
  final nbB = Map<String, dynamic>.from(userB['normalized_behavior'] as Map);
  final pcB = Map<String, dynamic>.from(userB['provisional_confidence'] as Map);
  final ccB = Map<String, dynamic>.from(userB['confidence_completeness'] as Map);
  final dims = <FrequencyBehaviorV2PairDimensionRelation>[
    for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
      pairs.dimensionRelation(
        dimensionId: id,
        xA: (nbA[id] as num).toDouble(),
        xB: (nbB[id] as num).toDouble(),
        effectiveSupportA:
            (pcA[id] as num).toDouble() * (ccA[id] as num).toDouble(),
        effectiveSupportB:
            (pcB[id] as num).toDouble() * (ccB[id] as num).toDouble(),
      ),
  ];
  return fit.fitFromRelation(
    FrequencyBehaviorV2PairRelationResult(
      ok: true,
      pairModelVersion: FrequencyBehaviorV2Contract.pairRelationVersion,
      encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
      mixednessVersion: FrequencyBehaviorV2Contract.mixedDensityVersion,
      scorerVersion: FrequencyBehaviorV2Contract.scorerVersion,
      dimensions: dims,
    ),
  );
}

void main() {
  final fixtureFile = File(
    '${Directory.current.path}/test/fixtures/frequency_v2/pair_fit_js_dart_parity_v1.json',
  );

  test('Dart pair-fit matches JS/Dart parity fixtures within 1e-9', () {
    expect(fixtureFile.existsSync(), isTrue);
    final doc =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    expect(doc['fixture_count'], greaterThanOrEqualTo(12));
    expect(doc['tolerance'], 1e-9);
    expect(
      doc['pair_fit_version'],
      FrequencyBehaviorV2Contract.pairFitVersion,
    );
    expect(
      doc['pair_fit_policy_version'],
      FrequencyBehaviorV2Contract.pairFitPolicyVersion,
    );
    expect(
      doc['pair_relation_version'],
      FrequencyBehaviorV2Contract.pairRelationVersion,
    );
    final fixtures = doc['fixtures'] as List;
    for (final raw in fixtures) {
      final fixture = Map<String, dynamic>.from(raw as Map);
      final actual = _fitFixtureUsers(
        Map<String, dynamic>.from(fixture['user_a'] as Map),
        Map<String, dynamic>.from(fixture['user_b'] as Map),
      );
      expect(actual.ok, isTrue, reason: fixture['id'] as String);
      final expected = Map<String, dynamic>.from(fixture['expected'] as Map);
      expect(
        actual.overallRawFit,
        closeTo((expected['overall_raw_fit'] as num).toDouble(), _tol),
        reason: '${fixture['id']} overall_raw_fit',
      );
      expect(
        actual.overallSupportedFit,
        closeTo((expected['overall_supported_fit'] as num).toDouble(), _tol),
        reason: '${fixture['id']} overall_supported_fit',
      );
      expect(
        actual.overallPairSupport,
        closeTo((expected['overall_pair_support'] as num).toDouble(), _tol),
        reason: '${fixture['id']} overall_pair_support',
      );
      expect(
        actual.frequencyFitIndex,
        closeTo((expected['frequency_fit_index'] as num).toDouble(), _tol),
        reason: '${fixture['id']} frequency_fit_index',
      );
      final expectedDims = expected['dimensions'] as List;
      expect(actual.dimensions, hasLength(12));
      for (var i = 0; i < 12; i++) {
        final row = actual.dimensions[i];
        final exp = Map<String, dynamic>.from(expectedDims[i] as Map);
        expect(row.dimensionId, exp['dimension_id']);
        expect(row.policyType, exp['policy_type']);
        expect(
          row.rawFit,
          closeTo((exp['raw_fit'] as num).toDouble(), _tol),
          reason: '${fixture['id']} ${row.dimensionId} raw',
        );
        expect(
          row.supportedFit,
          closeTo((exp['supported_fit'] as num).toDouble(), _tol),
          reason: '${fixture['id']} ${row.dimensionId} supported',
        );
        expect(
          row.pairSupport,
          closeTo((exp['pair_support'] as num).toDouble(), _tol),
          reason: '${fixture['id']} ${row.dimensionId} support',
        );
      }
    }
  });

  test('sqrt clamp pair-support formula matches Dart relation computer', () {
    const pairs = FrequencyBehaviorV2PairRelationComputer();
    final rel = pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 0.4,
      xB: -0.2,
      effectiveSupportA: 0.25 * 0.8,
      effectiveSupportB: 0.25 * 0.8,
    );
    expect(rel.pairSupport, closeTo(math.sqrt(0.04), _tol));
  });
}
