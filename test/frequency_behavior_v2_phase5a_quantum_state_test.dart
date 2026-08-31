import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

const _tol = FrequencyBehaviorV2Contract.signedPoleNumericTolerance;

FrequencyBehaviorV2DimensionScore _dim({
  required String id,
  required double x,
  double provisionalConfidence = 0.4,
  double evidenceQuality = 0.5,
}) {
  return FrequencyBehaviorV2DimensionScore(
    dimensionId: id,
    rawSum: x,
    capacity: 1,
    normalizedBehavior: x,
    primaryQuestionCount: 4,
    nonzeroPrimarySignalCount: 4,
    zeroPrimarySignalCount: 0,
    absoluteSelectedSignal: x.abs(),
    eligibleCrossContextPairCount: 1,
    possibleCrossContextPairCount: 1,
    provisionalConfidence: provisionalConfidence,
    evidenceQuality: evidenceQuality,
    presentationPressure: 0.2,
    meanAmbiguity: 0.25,
    meanSocialDesirability: 0.3,
    crossContextConsistency: 0.8,
  );
}

FrequencyBehaviorV2ScoreResult _score(
  Map<String, double> x, {
  double confidence = 0.4,
  double evidence = 0.5,
}) {
  return FrequencyBehaviorV2ScoreResult(
    ok: true,
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    sessionId: 'phase5a-test',
    dimensionScores: [
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
        _dim(
          id: d,
          x: x[d]!,
          provisionalConfidence: confidence,
          evidenceQuality: evidence,
        ),
    ],
  );
}

bool _vectorsClose(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > _tol) return false;
  }
  return true;
}

bool _matricesClose(List<List<double>> a, List<List<double>> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_vectorsClose(a[i], b[i])) return false;
  }
  return true;
}

void _assertPure(FrequencyBehaviorV2SignedPoleState s) {
  expect(s.stateVector24d.length, 24);
  expect(s.poleAmplitudes24d.length, 24);
  expect(s.basisLabels.length, 24);
  expect(
    FrequencyBehaviorV2SignedPoleEncoder.vectorNorm(s.stateVector24d),
    closeTo(1.0, _tol),
  );
  var poleEnergy = 0.0;
  for (final a in s.poleAmplitudes24d) {
    poleEnergy += a * a;
  }
  expect(poleEnergy, closeTo(12.0, _tol));
  expect(s.trace, closeTo(1.0, _tol));
  expect(s.purity, closeTo(1.0, _tol));
  expect(
    FrequencyBehaviorV2RealMatrix.maxAbsAsymmetry(s.pureDensityMatrix),
    lessThan(_tol),
  );
  final rho2 = FrequencyBehaviorV2RealMatrix.multiply(
    s.pureDensityMatrix,
    s.pureDensityMatrix,
  );
  expect(
    FrequencyBehaviorV2RealMatrix.frobeniusNorm(
      FrequencyBehaviorV2RealMatrix.subtract(rho2, s.pureDensityMatrix),
    ),
    lessThan(1e-8),
  );
  final ev = FrequencyBehaviorV2RealMatrix.symmetricEigenvalues(
    s.pureDensityMatrix,
  );
  expect(ev.first, greaterThan(-1e-8));
  expect(ev.last, closeTo(1.0, 1e-8));
  for (var i = 0; i < ev.length - 1; i++) {
    expect(ev[i].abs(), lessThan(1e-7));
  }
}

void main() {
  const encoder = FrequencyBehaviorV2SignedPoleEncoder();

  test('signed poles match +1 / 0 / -1 examples', () {
    final p = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(1);
    expect(p.plus, closeTo(1.0, _tol));
    expect(p.minus, closeTo(0.0, _tol));
    final n = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(0);
    expect(n.plus, closeTo(math.sqrt(0.5), _tol));
    expect(n.minus, closeTo(math.sqrt(0.5), _tol));
    expect(n.plus, closeTo(n.minus, _tol));
    final m = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(-1);
    expect(m.plus, closeTo(0.0, _tol));
    expect(m.minus, closeTo(1.0, _tol));
  });

  test('all +1, all -1, all zero, and mixed vectors encode as pure states', () {
    final pos = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
    );
    final neg = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
    );
    final zero = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0),
    );
    final mixed = encoder.encode(behaviorVector12d: {
      'contact_need': 1.0,
      'closeness_pace': -1.0,
      'initiative': 0.5,
      'autonomy': -0.5,
      'reassurance_need': 0.0,
      'uncertainty_tolerance': 0.25,
      'disclosure_pace': -0.25,
      'boundary_firmness': 0.75,
      'repair_style': -0.75,
      'social_energy': 1.0,
      'structure_preference': 0.0,
      'adaptability': -1.0,
    });
    for (final s in [pos, neg, zero, mixed]) {
      _assertPure(s);
    }
    for (var i = 0; i < 24; i += 2) {
      expect(pos.poleAmplitudes24d[i], closeTo(1.0, _tol));
      expect(pos.poleAmplitudes24d[i + 1], closeTo(0.0, _tol));
      expect(neg.poleAmplitudes24d[i], closeTo(0.0, _tol));
      expect(neg.poleAmplitudes24d[i + 1], closeTo(1.0, _tol));
      expect(zero.poleAmplitudes24d[i],
          closeTo(zero.poleAmplitudes24d[i + 1], _tol));
    }
  });

  test('opposite profiles occupy distinct poles and are not density-identical',
      () {
    final a = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
    );
    final b = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
    );
    expect(_vectorsClose(a.stateVector24d, b.stateVector24d), isFalse);
    expect(_matricesClose(a.pureDensityMatrix, b.pureDensityMatrix), isFalse);
    final dot = FrequencyBehaviorV2SignedPoleEncoder.vectorDot(
      a.stateVector24d,
      b.stateVector24d,
    );
    final overlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
      a.pureDensityMatrix,
      b.pureDensityMatrix,
    );
    expect(dot.abs(), lessThan(_tol));
    expect(overlap.abs(), lessThan(_tol));
    expect(dot, isNot(closeTo(1.0, 0.01)));
    expect(overlap, isNot(closeTo(1.0, 0.01)));
  });

  test('one dimension +1 vs -1 uses distinct signed basis poles', () {
    final plus = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0);
    plus['contact_need'] = 1.0;
    final minus = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0);
    minus['contact_need'] = -1.0;
    final a = encoder.encode(behaviorVector12d: plus);
    final b = encoder.encode(behaviorVector12d: minus);
    expect(a.basisLabels[0], 'contact_need:+');
    expect(a.basisLabels[1], 'contact_need:-');
    expect(a.poleAmplitudes24d[0], closeTo(1.0, _tol));
    expect(a.poleAmplitudes24d[1], closeTo(0.0, _tol));
    expect(b.poleAmplitudes24d[0], closeTo(0.0, _tol));
    expect(b.poleAmplitudes24d[1], closeTo(1.0, _tol));
    expect(_vectorsClose(a.stateVector24d, b.stateVector24d), isFalse);
    final overlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
      a.pureDensityMatrix,
      b.pureDensityMatrix,
    );
    expect(overlap, isNot(closeTo(1.0, 0.01)));
  });

  test('x=0 is behavioral center, not missing', () {
    final s = encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0),
    );
    expect(
      () => encoder.encode(behaviorVector12d: const {'contact_need': 0.0}),
      throwsA(isA<StateError>()),
    );
    expect(s.behaviorVector12d.values.every((v) => v == 0.0), isTrue);
  });

  test('same 12D vector is deterministic; confidence does not change psi', () {
    final x = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.25);
    final a = encoder.encode(behaviorVector12d: x, sessionId: 's1');
    final b = encoder.encode(behaviorVector12d: x, sessionId: 's1');
    expect(jsonEncode(a.stateVector24d), jsonEncode(b.stateVector24d));
    final low = encoder.encodeFromScore(
      _score(x, confidence: 0.1, evidence: 0.1),
    );
    final high = encoder.encodeFromScore(
      _score(x, confidence: 0.95, evidence: 0.95),
    );
    expect(
      jsonEncode(low.stateVector24d),
      jsonEncode(high.stateVector24d),
    );
    expect(low.toJson()['pure_density_matrix_omitted'], isTrue);
    expect(low.toJson().containsKey('pure_density_matrix_24x24'), isFalse);
  });

  test('phase 5A audit report exists and V2 stays dormant', () {
    expect(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.quantumStateEncodingContractRelativePath}',
      ).existsSync(),
      isTrue,
    );
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase5aQuantumStateAuditRelativePath}',
    ).readAsStringSync();
    expect(report.contains('quantum-inspired mathematical representation'),
        isTrue);
    expect(report.contains('pair compatibility defined | **false**'), isTrue);
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 5A SIGNED 24D QUANTUM-INSPIRED BEHAVIORAL STATE READY — V2 STILL DORMANT',
      ),
      isTrue,
    );
    expect(
      FrequencyBehaviorV2DraftLoader.loadPool().runtimeSelectable,
      isFalse,
    );
  });
}
