import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

const _tol = FrequencyBehaviorV2Contract.signedPoleNumericTolerance;
const _encoder = FrequencyBehaviorV2SignedPoleEncoder();
const _mixer = FrequencyBehaviorV2MixedDensityMixer();
const _pairs = FrequencyBehaviorV2PairRelationComputer();

Map<String, double> _unit(double v) => {
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: v,
    };

FrequencyBehaviorV2MixedStateResult _user({
  required Map<String, double> x,
  required double support,
  required String sessionId,
}) {
  final pure = _encoder.encode(
    behaviorVector12d: x,
    sessionId: sessionId,
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
  );
  return _mixer.mix(
    pure: pure,
    provisionalConfidence: _unit(support),
    confidenceCompleteness: _unit(1),
  );
}

void main() {
  test('operator same-pole matches analytic (1 + xA xB)/2', () {
    const samples = [
      [1.0, 1.0],
      [1.0, -1.0],
      [0.0, 0.0],
      [0.5, 0.5],
      [0.5, -0.5],
      [1.0, 0.0],
      [-0.25, 0.8],
    ];
    for (final s in samples) {
      final op =
          FrequencyBehaviorV2PairRelationComputer.samePoleOperatorExpectation(
              s[0], s[1]);
      final an =
          FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(s[0], s[1]);
      final opp = FrequencyBehaviorV2PairRelationComputer
          .oppositePoleOperatorExpectation(s[0], s[1]);
      expect(op, closeTo(an, _tol));
      expect(op + opp, closeTo(1.0, _tol));
    }
  });

  test('IDENTICAL +1/+1, OPPOSITE +1/-1, NEUTRAL 0/0, moderate and asymmetric',
      () {
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(1, 1),
      closeTo(1.0, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.axisFidelity(1, 1),
      closeTo(1.0, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(1, -1),
      closeTo(0.0, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.axisFidelity(1, -1),
      closeTo(0.0, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(0, 0),
      closeTo(0.5, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.axisFidelity(0, 0),
      closeTo(1.0, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(0.5, 0.5),
      closeTo(0.625, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(0.5, -0.5),
      closeTo(0.375, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(1, 0),
      closeTo(0.5, _tol),
    );
    expect(
      FrequencyBehaviorV2PairRelationComputer.axisFidelity(1, 0),
      closeTo(0.5, _tol),
    );
  });

  test('low and zero support leave behavior primitives, shrink supported pole',
      () {
    final high = _pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 1,
      xB: 1,
      effectiveSupportA: 1,
      effectiveSupportB: 1,
    );
    final low = _pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 1,
      xB: 1,
      effectiveSupportA: 0.1,
      effectiveSupportB: 0.1,
    );
    final zero = _pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 1,
      xB: 1,
      effectiveSupportA: 0,
      effectiveSupportB: 0,
    );
    expect(low.samePoleExpectation, closeTo(high.samePoleExpectation, _tol));
    expect(low.axisFidelity, closeTo(high.axisFidelity, _tol));
    expect(low.oppositePoleExpectation, closeTo(0.0, _tol));
    expect(low.supportedSamePole, closeTo(0.5 + 0.1 * 0.5, _tol));
    expect(low.supportedSamePole, lessThan(high.supportedSamePole));
    expect(zero.supportedSamePole, closeTo(0.5, _tol));
    expect(zero.samePoleExpectation, closeTo(1.0, _tol));
    expect(
      high.supportedSamePole + high.supportedOppositePole,
      closeTo(1.0, _tol),
    );
    expect(
      low.supportedSamePole + low.supportedOppositePole,
      closeTo(1.0, _tol),
    );
  });

  test('A/B swap is symmetric; mixed overlap is diagnostic; no compatibility',
      () {
    final a = _user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.4),
      support: 0.8,
      sessionId: 'u-a',
    );
    final b = _user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-0.2),
      support: 0.5,
      sessionId: 'u-b',
    );
    final ab = _pairs.relate(a, b);
    final ba = _pairs.relate(b, a);
    expect(ab.ok, isTrue);
    expect(ba.ok, isTrue);
    expect(ab.toJson().containsKey('compatibility'), isFalse);
    expect(ab.toJson().containsKey('compatibility_score'), isFalse);
    expect(ab.pureBehaviorOverlap, closeTo(ba.pureBehaviorOverlap!, _tol));
    expect(
      ab.mixedHilbertSchmidtOverlap,
      closeTo(ba.mixedHilbertSchmidtOverlap!, _tol),
    );
    final psiDot = FrequencyBehaviorV2SignedPoleEncoder.vectorDot(
      a.stateVector24d!,
      b.stateVector24d!,
    );
    expect(ab.pureBehaviorOverlap, closeTo(psiDot * psiDot, 1e-10));
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final r = ab.forDimension(d)!;
      final s = ba.forDimension(d)!;
      expect(r.axisFidelity, closeTo(s.axisFidelity, _tol));
      expect(r.samePoleExpectation, closeTo(s.samePoleExpectation, _tol));
      expect(r.pairSupport, closeTo(s.pairSupport, _tol));
      expect(r.supportedSamePole, closeTo(s.supportedSamePole, _tol));
      expect(r.xA, closeTo(s.xB, _tol));
      expect(r.xB, closeTo(s.xA, _tol));
    }
    final before = jsonEncode(a.rhoUser);
    _pairs.relate(a, b);
    expect(jsonEncode(a.rhoUser), before);
  });

  test('incomplete mixed user does not build pair rows', () {
    final a = _user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      support: 1,
      sessionId: 'ok',
    );
    const incomplete = FrequencyBehaviorV2MixedStateResult(
      ok: false,
      mixednessVersion: FrequencyBehaviorV2Contract.mixedDensityVersion,
      encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
      confidenceVersion: FrequencyBehaviorV2Contract.confidenceModelVersion,
      scorerVersion: FrequencyBehaviorV2Contract.scorerVersion,
      message: 'incomplete_confidence:adaptability',
    );
    final r = _pairs.relate(a, incomplete);
    expect(r.ok, isFalse);
    expect(r.dimensions, isEmpty);
    expect(r.pureBehaviorOverlap, isNull);
  });

  test('phase 5C audit exists and V2 stays dormant', () {
    expect(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.pairRelationContractRelativePath}',
      ).existsSync(),
      isTrue,
    );
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase5cPairRelationAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('fidelity=1 but same_pole=0.5'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 5C QUANTUM-INSPIRED PAIR RELATION PRIMITIVES READY — NO COMPATIBILITY SCORE YET — V2 STILL DORMANT',
      ),
      isTrue,
    );
    expect(
      FrequencyBehaviorV2DraftLoader.loadPool().runtimeSelectable,
      isFalse,
    );
  });
}
