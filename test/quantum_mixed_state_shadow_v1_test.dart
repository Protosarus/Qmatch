import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/quantum_mixed_state_shadow.dart';

void main() {
  const matcher = QuantumMixedStateShadowMatcher();

  const osc = 'activity_spectral_global_activity_t43200s';
  const T = 43200.0;
  final omega = 2 * math.pi / T;
  const epoch = '2024-01-01T00:00:00.000Z';

  QuantumMixedStatePhaseMember member(double phi, {String oscillatorId = osc}) {
    return QuantumMixedStatePhaseMember(
      phaseRadians: phi,
      oscillatorId: oscillatorId,
      omega: omega,
      periodSeconds: T,
      referenceEpoch: epoch,
    );
  }

  List<QuantumMixedStatePhaseMember> ensemble(List<double> phis) =>
      [for (final p in phis) member(p)];

  group('QuantumMixedStateShadowMatcher', () {
    test('identical coherent ensembles → purity≈1, fidelity≈1, D_tr≈0', () {
      final e = ensemble([0.4, 0.4, 0.4]);
      final r = matcher.compare(ensembleA: e, ensembleB: e);
      expect(r.available, isTrue);
      expect(r.purityA, closeTo(1.0, 1e-12));
      expect(r.purityB, closeTo(1.0, 1e-12));
      expect(r.qiMixedFidelity, closeTo(1.0, 1e-12));
      expect(r.qiTraceDistance, closeTo(0.0, 1e-12));
      expect(r.weightPolicyId, 'equal_window_v1');
      expect(r.ensembleCountA, 3);
      expect(r.toWireMap()['layer'], 'L5');
      expect(r.toWireMap()['layer_contract'], 'l5_mixed_state_qi_contract_v1');
      expect(r.toWireMap()['shadow_only'], isTrue);
      expect(r.toWireMap()['policy_status'], 'validated_shadow_not_live');
      expect(r.toWireMap()['validated_shadow_research_signal'], isTrue);
      expect(r.toWireMap()['specification_only_not_live'], isFalse);
      expect(r.toWireMap()['real_data_validation_pending'], isTrue);
      expect(r.toWireMap()['fuses_with_structural'], isFalse);
      expect(r.toWireMap()['free_lambda_allowed'], isFalse);
      expect(r.toWireMap()['pure_state_qi_as_separate_signal'], isFalse);
      expect(r.toWireMap()['ranking_weights_allowed'], isFalse);
    });

    test('identical dispersed ensembles → low purity, fidelity≈1, D_tr≈0', () {
      // Opposite phases cancel → |r|≈0.
      final e = ensemble([0.0, math.pi]);
      final r = matcher.compare(ensembleA: e, ensembleB: List.of(e));
      expect(r.available, isTrue);
      expect(r.purityA, closeTo(0.5, 1e-12));
      expect(r.purityB, closeTo(0.5, 1e-12));
      expect(r.qiMixedFidelity, closeTo(1.0, 1e-12));
      expect(r.qiTraceDistance, closeTo(0.0, 1e-12));
      expect(r.blochA!.normSquared, closeTo(0.0, 1e-12));
    });

    test('same mean phase but different phase spread → fidelity < 1', () {
      final sharp = ensemble([0.0, 0.0, 0.0, 0.0]);
      final wide = ensemble([-1.0, -0.3, 0.3, 1.0]);
      final r = matcher.compare(ensembleA: sharp, ensembleB: wide);
      expect(r.available, isTrue);
      expect(r.purityA!, greaterThan(r.purityB!));
      expect(r.qiMixedFidelity!, lessThan(1.0));
      expect(r.qiMixedFidelity!, greaterThan(0.0));
      // Independent of single-phase cos: mixed geometry differs.
      expect(r.qiTraceDistance!, greaterThan(0.0));
    });

    test('opposite phase ensembles → low fidelity', () {
      final a = ensemble([0.0, 0.0]);
      final b = ensemble([math.pi, math.pi]);
      final r = matcher.compare(ensembleA: a, ensembleB: b);
      expect(r.available, isTrue);
      expect(r.purityA, closeTo(1.0, 1e-12));
      expect(r.purityB, closeTo(1.0, 1e-12));
      expect(r.qiMixedFidelity, closeTo(0.0, 1e-12));
      expect(r.qiTraceDistance, closeTo(1.0, 1e-12));
    });

    test('low vs high purity diagnostics', () {
      final high = QuantumMixedStateShadowMatcher.buildEnsemble(
        ensemble([0.7, 0.7]),
      );
      final low = QuantumMixedStateShadowMatcher.buildEnsemble(
        ensemble([0.0, 2 * math.pi / 3, 4 * math.pi / 3]),
      );
      expect(high.error, isNull);
      expect(low.error, isNull);
      expect(high.purity!, greaterThan(0.99));
      expect(low.purity!, lessThan(0.55));
    });

    test('oscillator / provenance mismatch → unavailable', () {
      final a = ensemble([0.1, 0.2]);
      final bFixed = [
        QuantumMixedStatePhaseMember(
          phaseRadians: 0.1,
          oscillatorId: 'activity_spectral_global_activity_t36000s',
          omega: 2 * math.pi / 36000,
          periodSeconds: 36000,
          referenceEpoch: epoch,
        ),
        QuantumMixedStatePhaseMember(
          phaseRadians: 0.2,
          oscillatorId: 'activity_spectral_global_activity_t36000s',
          omega: 2 * math.pi / 36000,
          periodSeconds: 36000,
          referenceEpoch: epoch,
        ),
      ];
      final r = matcher.compare(ensembleA: a, ensembleB: bFixed);
      expect(r.available, isFalse);
      expect(
        r.unavailableReason,
        QuantumMixedStateShadowContract.reasonProvenanceMismatch,
      );
      expect(r.qiMixedFidelity, isNull);

      // Inconsistent within ensemble.
      final bad = matcher.compare(
        ensembleA: [...a, bFixed.first],
        ensembleB: a,
      );
      expect(bad.available, isFalse);
      expect(
        bad.unavailableReason,
        QuantumMixedStateShadowContract.reasonInconsistentEnsemble,
      );
    });

    test('K < 2 → unavailable', () {
      final r = matcher.compare(
        ensembleA: [member(0.3)],
        ensembleB: ensemble([0.3, 0.3]),
      );
      expect(r.available, isFalse);
      expect(
        r.unavailableReason,
        QuantumMixedStateShadowContract.reasonInsufficientEnsemble,
      );
    });

    test('symmetry: compare(A,B) == compare(B,A)', () {
      final a = ensemble([0.0, 0.5, 1.0]);
      final b = ensemble([-0.2, 0.8]);
      final ab = matcher.compare(ensembleA: a, ensembleB: b);
      final ba = matcher.compare(ensembleA: b, ensembleB: a);
      expect(ab.available && ba.available, isTrue);
      expect(ab.qiMixedFidelity, closeTo(ba.qiMixedFidelity!, 1e-12));
      expect(ab.qiTraceDistance, closeTo(ba.qiTraceDistance!, 1e-12));
      expect(ab.purityA, closeTo(ba.purityB!, 1e-12));
      expect(ab.purityB, closeTo(ba.purityA!, 1e-12));
    });

    test('fidelity / trace distance bounds', () {
      final rng = math.Random(5);
      for (var i = 0; i < 40; i++) {
        final a = ensemble([
          for (var k = 0; k < 2 + rng.nextInt(4); k++)
            rng.nextDouble() * 2 * math.pi - math.pi,
        ]);
        final b = ensemble([
          for (var k = 0; k < 2 + rng.nextInt(4); k++)
            rng.nextDouble() * 2 * math.pi - math.pi,
        ]);
        final r = matcher.compare(ensembleA: a, ensembleB: b);
        expect(r.available, isTrue);
        expect(r.qiMixedFidelity!, inInclusiveRange(0.0, 1.0));
        expect(r.qiTraceDistance!, inInclusiveRange(0.0, 1.0));
        expect(r.purityA!, inInclusiveRange(0.5, 1.0));
        expect(r.purityB!, inInclusiveRange(0.5, 1.0));
        // Pure opposite → F + D_tr relation soft-check for near-pure cases.
        if (r.purityA! > 0.999 && r.purityB! > 0.999) {
          expect(
            r.qiTraceDistance!,
            closeTo(math.sqrt(1.0 - r.qiMixedFidelity!), 1e-9),
          );
        }
      }
    });

    test('contract freezes validated shadow / no Discover / Persona / pure QI', () {
      expect(
        QuantumMixedStateShadowContract.policyStatus,
        'validated_shadow_not_live',
      );
      expect(QuantumMixedStateShadowContract.validatedShadowResearchSignal, isTrue);
      expect(QuantumMixedStateShadowContract.specificationOnlyNotLive, isFalse);
      expect(QuantumMixedStateShadowContract.realDataValidationPending, isTrue);
      expect(QuantumMixedStateShadowContract.liveDiscoverRanking, isFalse);
      expect(QuantumMixedStateShadowContract.personaEnabled, isFalse);
      expect(QuantumMixedStateShadowContract.rviEnabled, isFalse);
      expect(QuantumMixedStateShadowContract.questionnaireStatesAllowed, isFalse);
      expect(QuantumMixedStateShadowContract.freeLambdaAllowed, isFalse);
      expect(QuantumMixedStateShadowContract.rankingWeightsAllowed, isFalse);
      expect(QuantumMixedStateShadowContract.pureStateQiAsSeparateSignal, isFalse);
      expect(
        QuantumMixedStateShadowContract.fidelityIsCompatibilityPercentage,
        isFalse,
      );
      expect(QuantumMixedStateShadowContract.fusedRWaveIsL5Score, isFalse);
      expect(
        QuantumMixedStateShadowContract.multimodeWaveStateInProduction,
        isFalse,
      );
      expect(
        QuantumMixedStateShadowContract.layerContractVersion,
        'l5_mixed_state_qi_contract_v1',
      );
      expect(QuantumMixedStateShadowContract.weightPolicyId, 'equal_window_v1');
      expect(
        QuantumMixedStateShadowContract.frozenWireFields,
        containsAll([
          'purity_A',
          'purity_B',
          'qi_mixed_fidelity',
          'qi_trace_distance',
        ]),
      );
      final paths = [
        'lib/features/matching/domain/quantum_mixed_state_shadow_matcher.dart',
        'lib/features/matching/domain/quantum_mixed_state_shadow_contract.dart',
        'lib/features/matching/domain/quantum_mixed_state_shadow_models.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('depth_preference')), reason: path);
      }
    });
  });
}
