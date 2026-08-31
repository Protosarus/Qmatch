import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

import 'support/frequency_behavior_v2_helpers.dart';

const _tol = FrequencyBehaviorV2Contract.signedPoleNumericTolerance;
const _mixer = FrequencyBehaviorV2MixedDensityMixer();
const _encoder = FrequencyBehaviorV2SignedPoleEncoder();

Map<String, double> _unit(double v) => {
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: v,
    };

FrequencyBehaviorV2SignedPoleState _pure([double x = 0.25]) => _encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(x),
      sessionId: 'phase5b-test',
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    );

FrequencyBehaviorV2DimensionScore _dim({
  required String id,
  required double x,
  double? provisionalConfidence,
  double? confidenceCompleteness,
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
    confidenceCompleteness: confidenceCompleteness,
  );
}

FrequencyBehaviorV2ScoreResult _score({
  required Map<String, double> x,
  Map<String, double>? confidence,
  Map<String, double>? completeness,
}) {
  return FrequencyBehaviorV2ScoreResult(
    ok: true,
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    sessionId: 'phase5b-score',
    dimensionScores: [
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
        _dim(
          id: d,
          x: x[d]!,
          provisionalConfidence: confidence?[d],
          confidenceCompleteness: completeness?[d],
        ),
    ],
  );
}

void _assertValidMixed(FrequencyBehaviorV2MixedStateResult r) {
  expect(r.ok, isTrue);
  expect(r.rhoUser, isNotNull);
  expect(r.rhoBehavior, isNotNull);
  expect(r.trace, closeTo(1.0, _tol));
  expect(
    FrequencyBehaviorV2RealMatrix.maxAbsAsymmetry(r.rhoUser!),
    lessThan(_tol),
  );
  final ev = FrequencyBehaviorV2RealMatrix.symmetricEigenvalues(r.rhoUser!);
  expect(ev.first, greaterThan(-1e-8));
  expect(
    r.mixedStatePurity,
    closeTo(r.analyticMixedPurity!, 1e-10),
  );
  expect(
    r.mixedStatePurity,
    closeTo(
      FrequencyBehaviorV2MixedDensityMixer.analyticPurity(r.lambda!),
      1e-10,
    ),
  );
}

void main() {
  test('support=1 => lambda=0, rho_user = rho_behavior, purity=1', () {
    final pure = _pure(1);
    final r = _mixer.mix(
      pure: pure,
      provisionalConfidence: _unit(1),
      confidenceCompleteness: _unit(1),
    );
    _assertValidMixed(r);
    expect(r.globalSupport, closeTo(1.0, _tol));
    expect(r.lambda, closeTo(0.0, _tol));
    expect(r.mixedStatePurity, closeTo(1.0, 1e-10));
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        r.rhoUser!,
        r.rhoBehavior!,
      ),
      lessThan(_tol),
    );
  });

  test('support=0 => lambda=1, rho_user = I/24, purity=1/24', () {
    final r = _mixer.mix(
      pure: _pure(-1),
      provisionalConfidence: _unit(0),
      confidenceCompleteness: _unit(1),
    );
    _assertValidMixed(r);
    expect(r.lambda, closeTo(1.0, _tol));
    expect(
      r.mixedStatePurity,
      closeTo(
          FrequencyBehaviorV2Contract.mixedDensityMaximallyMixedPurity, 1e-10),
    );
    final ident = FrequencyBehaviorV2RealMatrix.scaled(
      FrequencyBehaviorV2RealMatrix.identity(24),
      1 / 24,
    );
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(r.rhoUser!, ident),
      lessThan(_tol),
    );
  });

  test('intermediate support and completeness change lambda only', () {
    final pure = _pure(0.5);
    final mid = _mixer.mix(
      pure: pure,
      provisionalConfidence: _unit(0.5),
      confidenceCompleteness: _unit(1),
    );
    final completeHalf = _mixer.mix(
      pure: pure,
      provisionalConfidence: _unit(1),
      confidenceCompleteness: _unit(0.5),
    );
    _assertValidMixed(mid);
    _assertValidMixed(completeHalf);
    expect(mid.lambda, closeTo(0.5, _tol));
    expect(completeHalf.lambda, closeTo(0.5, _tol));
    expect(mid.mixedStatePurity! < 1.0, isTrue);
    expect(
      mid.mixedStatePurity! >
          FrequencyBehaviorV2Contract.mixedDensityMaximallyMixedPurity,
      isTrue,
    );
    expect(jsonEncode(mid.stateVector24d), jsonEncode(pure.stateVector24d));
    expect(
        jsonEncode(mid.behaviorVector12d), jsonEncode(pure.behaviorVector12d));
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        mid.rhoBehavior!,
        pure.pureDensityMatrix,
      ),
      lessThan(_tol),
    );
  });

  test('same behavior, different confidence: psi and rho_behavior identical',
      () {
    final x = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.4);
    final high = _mixer.mix(
      pure: _encoder.encode(behaviorVector12d: x, sessionId: 'same'),
      provisionalConfidence: _unit(0.9),
      confidenceCompleteness: _unit(1),
    );
    final low = _mixer.mix(
      pure: _encoder.encode(behaviorVector12d: x, sessionId: 'same'),
      provisionalConfidence: _unit(0.2),
      confidenceCompleteness: _unit(0.5),
    );
    _assertValidMixed(high);
    _assertValidMixed(low);
    expect(jsonEncode(high.stateVector24d), jsonEncode(low.stateVector24d));
    expect(
      jsonEncode(high.behaviorVector12d),
      jsonEncode(low.behaviorVector12d),
    );
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        high.rhoBehavior!,
        low.rhoBehavior!,
      ),
      lessThan(_tol),
    );
    expect(high.lambda! < low.lambda!, isTrue);
    expect(high.mixedStatePurity! > low.mixedStatePurity!, isTrue);
  });

  test('all +1 vs all -1 stay distinct when lambda<1 and collide at lambda=1',
      () {
    final pos = _encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
    );
    final neg = _encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
    );
    final posM = _mixer.mix(
      pure: pos,
      provisionalConfidence: _unit(0.7),
      confidenceCompleteness: _unit(1),
    );
    final negM = _mixer.mix(
      pure: neg,
      provisionalConfidence: _unit(0.7),
      confidenceCompleteness: _unit(1),
    );
    _assertValidMixed(posM);
    _assertValidMixed(negM);
    expect(posM.lambda! < 1, isTrue);
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        posM.rhoUser!,
        negM.rhoUser!,
      ),
      greaterThan(1e-6),
    );
    final overlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
      posM.rhoUser!,
      negM.rhoUser!,
    );
    expect(overlap, isNot(closeTo(1.0, 0.01)));

    final posMax = _mixer.mix(
      pure: pos,
      provisionalConfidence: _unit(0),
      confidenceCompleteness: _unit(0),
    );
    final negMax = _mixer.mix(
      pure: neg,
      provisionalConfidence: _unit(0),
      confidenceCompleteness: _unit(0),
    );
    expect(posMax.lambda, closeTo(1.0, _tol));
    expect(
      FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        posMax.rhoUser!,
        negMax.rhoUser!,
      ),
      lessThan(_tol),
    );
  });

  test('missing confidence does not construct rho_user or fabricate values',
      () {
    final pure = _pure();
    final missingPc = _mixer.mix(
      pure: pure,
      provisionalConfidence: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          if (d != 'adaptability') d: 0.8,
      },
      confidenceCompleteness: _unit(1),
    );
    expect(missingPc.ok, isFalse);
    expect(missingPc.rhoUser, isNull);
    expect(missingPc.lambda, isNull);
    expect(missingPc.message, 'incomplete_confidence:adaptability');

    final missingCc = _mixer.mixFromScore(
      _score(
        x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.2),
        confidence: _unit(0.8),
        completeness: null,
      ),
    );
    expect(missingCc.ok, isFalse);
    expect(missingCc.rhoUser, isNull);
    expect(missingCc.message, contains('incomplete_completeness'));
  });

  test('deterministic mix; default JSON omits matrices; V2 stays dormant', () {
    final pure = _pure(0.1);
    final a = _mixer.mix(
      pure: pure,
      provisionalConfidence: _unit(0.6),
      confidenceCompleteness: _unit(0.8),
    );
    final b = _mixer.mix(
      pure: pure,
      provisionalConfidence: _unit(0.6),
      confidenceCompleteness: _unit(0.8),
    );
    expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
    expect(a.toJson()['density_matrices_omitted'], isTrue);
    expect(a.toJson().containsKey('rho_user'), isFalse);
    expect(
      File(
        '${Directory.current.path}/${FrequencyBehaviorV2Contract.mixedDensityContractRelativePath}',
      ).existsSync(),
      isTrue,
    );
    final report = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.phase5bMixedDensityAuditRelativePath}',
    ).readAsStringSync();
    expect(
      report.contains('quantum-inspired mixed-state representation'),
      isTrue,
    );
    expect(
      report.contains(
        'FREQUENCY V2 PHASE 5B CONFIDENCE-AWARE MIXED DENSITY MATRIX READY — V2 STILL DORMANT',
      ),
      isTrue,
    );
    expect(
      FrequencyBehaviorV2DraftLoader.loadPool().runtimeSelectable,
      isFalse,
    );
  });
}
