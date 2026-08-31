import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

const _tol = FrequencyBehaviorV2Contract.signedPoleNumericTolerance;
const _encoder = FrequencyBehaviorV2SignedPoleEncoder();
const _mixer = FrequencyBehaviorV2MixedDensityMixer();
const _pairs = FrequencyBehaviorV2PairRelationComputer();
const _fit = FrequencyBehaviorV2PairFitComputer();

Map<String, double> _unit(double v) => {
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: v,
    };

FrequencyBehaviorV2MixedStateResult _user({
  required Map<String, double> x,
  required double confidence,
  double completeness = 1,
  required String sessionId,
}) {
  final pure = _encoder.encode(
    behaviorVector12d: x,
    sessionId: sessionId,
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
  );
  return _mixer.mix(
    pure: pure,
    provisionalConfidence: _unit(confidence),
    confidenceCompleteness: _unit(completeness),
  );
}

FrequencyBehaviorV2PairFitResult _fitUsers(
  FrequencyBehaviorV2MixedStateResult a,
  FrequencyBehaviorV2MixedStateResult b,
) =>
    _fit.fitFromUsers(a, b);

void main() {
  test('IDENTICAL + FULL SUPPORT => raw=1 supported=1 index=100', () {
    final x = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.6);
    final r = _fitUsers(
      _user(x: x, confidence: 1, sessionId: 'a'),
      _user(x: x, confidence: 1, sessionId: 'b'),
    );
    expect(r.ok, isTrue);
    for (final d in r.dimensions) {
      expect(d.rawFit, closeTo(1.0, _tol));
      expect(d.supportedFit, closeTo(1.0, _tol));
    }
    expect(r.overallRawFit, closeTo(1.0, _tol));
    expect(r.overallSupportedFit, closeTo(1.0, _tol));
    expect(r.frequencyFitIndex, closeTo(100.0, _tol));
  });

  test('IDENTICAL + ZERO SUPPORT => raw=1 supported=0.5 index=50', () {
    final x = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-0.3);
    final r = _fitUsers(
      _user(x: x, confidence: 0, sessionId: 'a'),
      _user(x: x, confidence: 0, sessionId: 'b'),
    );
    expect(r.overallRawFit, closeTo(1.0, _tol));
    expect(r.overallSupportedFit, closeTo(0.5, _tol));
    expect(r.frequencyFitIndex, closeTo(50.0, _tol));
    for (final d in r.dimensions) {
      expect(d.supportedFit, closeTo(0.5, _tol));
    }
  });

  test('OPPOSITE EXTREMES + FULL SUPPORT => raw=0 supported=0', () {
    final r = _fitUsers(
      _user(
        x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
        confidence: 1,
        sessionId: 'a',
      ),
      _user(
        x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
        confidence: 1,
        sessionId: 'b',
      ),
    );
    for (final d in r.dimensions) {
      expect(d.delta, closeTo(2.0, _tol));
      expect(d.rawFit, closeTo(0.0, _tol));
      expect(d.supportedFit, closeTo(0.0, _tol));
    }
    expect(r.frequencyFitIndex, closeTo(0.0, _tol));
  });

  test('MODERATE delta=0.5: linear=0.75 tolerant=0.9375', () {
    expect(
      FrequencyBehaviorV2PairFitComputer.rawFitForPolicy(
        delta: 0.5,
        policyType: FrequencyBehaviorV2Contract.pairFitPolicySimilarityLinear,
      ),
      closeTo(0.75, _tol),
    );
    expect(
      FrequencyBehaviorV2PairFitComputer.rawFitForPolicy(
        delta: 0.5,
        policyType: FrequencyBehaviorV2Contract.pairFitPolicySimilarityTolerant,
      ),
      closeTo(0.9375, _tol),
    );
    final linearRel = _pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 0.25,
      xB: 0.75,
      effectiveSupportA: 1,
      effectiveSupportB: 1,
    );
    final tolerantRel = _pairs.dimensionRelation(
      dimensionId: 'initiative',
      xA: 0.25,
      xB: 0.75,
      effectiveSupportA: 1,
      effectiveSupportB: 1,
    );
    expect(_fit.dimensionFit(linearRel).rawFit, closeTo(0.75, _tol));
    expect(_fit.dimensionFit(tolerantRel).rawFit, closeTo(0.9375, _tol));
    expect(
      _fit.dimensionFit(tolerantRel).rawFit,
      greaterThan(_fit.dimensionFit(linearRel).rawFit),
    );
  });

  test('zero pair_support yields supported_fit exactly 0.5', () {
    final rel = _pairs.dimensionRelation(
      dimensionId: 'contact_need',
      xA: 1,
      xB: -1,
      effectiveSupportA: 0,
      effectiveSupportB: 0,
    );
    final row = _fit.dimensionFit(rel);
    expect(row.rawFit, closeTo(0.0, _tol));
    expect(row.supportedFit, closeTo(0.5, _tol));
  });

  test('A/B swap is symmetric', () {
    final a = _user(
      x: {
        'contact_need': 1.0,
        'closeness_pace': -0.5,
        'initiative': 0.25,
        'autonomy': 0.0,
        'reassurance_need': 0.5,
        'uncertainty_tolerance': -0.25,
        'disclosure_pace': 0.75,
        'boundary_firmness': -0.75,
        'repair_style': 0.1,
        'social_energy': -0.1,
        'structure_preference': 0.4,
        'adaptability': -0.4,
      },
      confidence: 0.7,
      sessionId: 'sym-a',
    );
    final b = _user(
      x: {
        'contact_need': 0.2,
        'closeness_pace': 0.8,
        'initiative': -0.6,
        'autonomy': 0.3,
        'reassurance_need': -0.2,
        'uncertainty_tolerance': 0.6,
        'disclosure_pace': -0.1,
        'boundary_firmness': 0.5,
        'repair_style': -0.5,
        'social_energy': 0.9,
        'structure_preference': -0.3,
        'adaptability': 0.15,
      },
      confidence: 0.55,
      sessionId: 'sym-b',
    );
    final ab = _fitUsers(a, b);
    final ba = _fitUsers(b, a);
    expect(ab.overallRawFit, closeTo(ba.overallRawFit!, _tol));
    expect(ab.overallSupportedFit, closeTo(ba.overallSupportedFit!, _tol));
    expect(ab.frequencyFitIndex, closeTo(ba.frequencyFitIndex!, _tol));
    expect(ab.overallPairSupport, closeTo(ba.overallPairSupport!, _tol));
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final r = ab.forDimension(d)!;
      final s = ba.forDimension(d)!;
      expect(r.rawFit, closeTo(s.rawFit, _tol));
      expect(r.supportedFit, closeTo(s.supportedFit, _tol));
      expect(r.delta, closeTo(s.delta, _tol));
      expect(r.pairSupport, closeTo(s.pairSupport, _tol));
    }
  });

  test('density overlap changes do not change fit when behavior/support fixed',
      () {
    final x = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.35);
    final highSupport = _user(x: x, confidence: 1, sessionId: 'hs-a');
    final lowSupport = _user(x: x, confidence: 0.2, sessionId: 'ls-b');
    final r1 = _fitUsers(highSupport, lowSupport);
    final relation = _pairs.relate(highSupport, lowSupport);
    final mutated = FrequencyBehaviorV2PairRelationResult(
      ok: relation.ok,
      pairModelVersion: relation.pairModelVersion,
      encodingVersion: relation.encodingVersion,
      mixednessVersion: relation.mixednessVersion,
      scorerVersion: relation.scorerVersion,
      userASessionId: relation.userASessionId,
      userBSessionId: relation.userBSessionId,
      dimensions: relation.dimensions,
      pureBehaviorOverlap: 0.42,
      mixedHilbertSchmidtOverlap: 0.08,
    );
    final r2 = _fit.fitFromRelation(mutated);
    expect(jsonEncode(r1.toJson()), jsonEncode(r2.toJson()));
    expect(r1.frequencyFitIndex, isNotNull);
    expect(
      r1.toJson().containsKey('pure_behavior_overlap'),
      isFalse,
    );
  });

  test('alignment/gap strengths do not re-enter score; audit exists', () {
    final r = _fitUsers(
      _user(
        x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.5),
        confidence: 0.8,
        sessionId: 'rank-a',
      ),
      _user(
        x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.5),
        confidence: 0.8,
        sessionId: 'rank-b',
      ),
    );
    expect(r.topAlignmentDimensions, isNotEmpty);
    expect(r.topGapDimensions, isNotEmpty);
    expect(
      r.frequencyFitIndex,
      closeTo(100 * r.overallSupportedFit!, _tol),
    );
    expect(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.pairFitContractRelativePath}',
      ).existsSync(),
      isTrue,
    );
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase5dPairFitAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('frequency_pair_fit_policy_v1'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 5D PROVISIONAL RELATIONSHIP FIT MODEL READY — NO LIVE MATCHING — V2 STILL DORMANT',
      ),
      isTrue,
    );
    expect(
      FrequencyBehaviorV2DraftLoader.loadPool().runtimeSelectable,
      isFalse,
    );
  });
}
