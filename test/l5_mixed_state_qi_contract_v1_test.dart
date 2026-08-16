import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/l5_mixed_state_qi.dart';
import 'package:qmatch/features/matching/domain/periodic_wave_state_resonance_adapter_contract.dart';
import 'package:qmatch/features/matching/domain/wave_state_amplitude_semantics.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_contract.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_contract.dart';

void main() {
  group('L5 v1 research freeze', () {
    test('validated shadow, non-ranking, mixed-state only', () {
      expect(
        L5MixedStateQiContract.policyVersion,
        'l5_mixed_state_qi_contract_v1',
      );
      expect(
        L5MixedStateQiContract.policyStatus,
        'validated_shadow_not_live',
      );
      expect(L5MixedStateQiContract.retainedCandidate, 'mixed_state_qi');
      expect(L5MixedStateQiContract.scoringVersion, 'quantum_mixed_state_shadow_v1');
      expect(L5MixedStateQiContract.weightPolicyId, 'equal_window_v1');
      expect(L5MixedStateQiContract.shadowOnly, isTrue);
      expect(L5MixedStateQiContract.validatedShadowResearchSignal, isTrue);
      expect(L5MixedStateQiContract.specificationOnlyNotLive, isFalse);
      expect(L5MixedStateQiContract.affectsDiscoverRanking, isFalse);
      expect(L5MixedStateQiContract.liveDiscoverRanking, isFalse);
      expect(L5MixedStateQiContract.fusesWithL2, isFalse);
      expect(L5MixedStateQiContract.fusesWithL3, isFalse);
      expect(L5MixedStateQiContract.fusesWithL4, isFalse);
      expect(L5MixedStateQiContract.rankingWeightsAllowed, isFalse);
      expect(L5MixedStateQiContract.freeLambdaAllowed, isFalse);
      expect(L5MixedStateQiContract.imputationAllowed, isFalse);
      expect(L5MixedStateQiContract.gatesCalibrated, isFalse);
      expect(L5MixedStateQiContract.realMultiWindowCohortExists, isFalse);
      expect(L5MixedStateQiContract.realDataValidationPending, isTrue);
      expect(L5MixedStateQiContract.rankingRequiresSeparateRfc, isTrue);
      expect(L5MixedStateQiContract.minAcceptedClassBWindows, 2);
      expect(L5MixedStateQiContract.requiresSharedOscillatorProvenance, isTrue);
      expect(
        L5MixedStateQiContract.classBWindowsFromL4ProductionDiagnostics,
        isFalse,
      );
    });

    test('retained diagnostics stay separate', () {
      expect(
        L5MixedStateQiContract.retainedDiagnosticFields,
        ['purity_A', 'purity_B', 'qi_mixed_fidelity', 'qi_trace_distance'],
      );
      expect(
        L5MixedStateQiContract.fidelityIsCompatibilityPercentage,
        isFalse,
      );
    });

    test('rejected L5 signals stay prohibited', () {
      expect(L5MixedStateQiContract.pureStateQiAsSeparateSignal, isFalse);
      expect(L5MixedStateQiContract.multimodeWaveStateInProduction, isFalse);
      expect(L5MixedStateQiContract.fusedRWaveIsL5Score, isFalse);
      expect(
        L5MixedStateQiContract.copiesGlobalActivityPhaseToFrequency6d,
        isFalse,
      );
      expect(L5MixedStateQiContract.questionnairePhaseOmegaAllowed, isFalse);
      expect(L5MixedStateQiContract.personaEnabled, isFalse);
      expect(L5MixedStateQiContract.rviEnabled, isFalse);

      expect(WaveStateModalShadowContract.l5V1RetainedCandidate, isFalse);
      expect(WaveStateModalShadowV2Contract.l5V1RetainedCandidate, isFalse);
      expect(WaveStateModalShadowV2Contract.fusedRWaveIsL5Score, isFalse);
      expect(
        WaveStateAmplitudeSemanticsContract.tier2L5V1RetainedCandidate,
        isFalse,
      );
      expect(WaveStateAmplitudeSemanticsContract.fusedRWaveIsL5Score, isFalse);
      expect(
        PeriodicWaveStateResonanceAdapterContract.l5V1RetainedCandidate,
        isFalse,
      );
      expect(
        PeriodicWaveStateResonanceAdapterContract.fusedRWaveIsL5Score,
        isFalse,
      );
    });

    test('matcher wire map carries L5 v1 freeze flags', () {
      const matcher = QuantumMixedStateShadowMatcher();
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = 2 * math.pi / T;
      const epoch = '2024-01-01T00:00:00.000Z';
      QuantumMixedStatePhaseMember member(double phi) {
        return QuantumMixedStatePhaseMember(
          phaseRadians: phi,
          oscillatorId: osc,
          omega: omega,
          periodSeconds: T,
          referenceEpoch: epoch,
        );
      }

      final r = matcher.compare(
        ensembleA: [member(0.1), member(0.2)],
        ensembleB: [member(0.1), member(0.2)],
      );
      expect(r.available, isTrue);
      final wire = r.toWireMap();
      expect(wire['layer'], 'L5');
      expect(wire['layer_contract'], 'l5_mixed_state_qi_contract_v1');
      expect(wire['policy_status'], 'validated_shadow_not_live');
      expect(wire['affects_discover_ranking'], isFalse);
      expect(wire['fuses_with_l2'], isFalse);
      expect(wire['fuses_with_l3'], isFalse);
      expect(wire['fuses_with_l4'], isFalse);
      expect(wire['pure_state_qi_as_separate_signal'], isFalse);
      expect(wire['fidelity_is_compatibility_percentage'], isFalse);
      expect(wire['fused_r_wave_is_l5_score'], isFalse);
      expect(wire['multimode_wave_state_in_production'], isFalse);
      expect(wire['copies_global_activity_phase_to_frequency_6d'], isFalse);
      expect(wire['real_multi_window_cohort_exists'], isFalse);
      expect(wire['ranking_requires_separate_rfc'], isTrue);
      expect(wire['purity_A'], isNotNull);
      expect(wire['purity_B'], isNotNull);
      expect(wire['qi_mixed_fidelity'], isNotNull);
      expect(wire['qi_trace_distance'], isNotNull);
    });

    test('K < 2 remains unavailable', () {
      const matcher = QuantumMixedStateShadowMatcher();
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = 2 * math.pi / T;
      const epoch = '2024-01-01T00:00:00.000Z';
      final one = QuantumMixedStatePhaseMember(
        phaseRadians: 0.3,
        oscillatorId: osc,
        omega: omega,
        periodSeconds: T,
        referenceEpoch: epoch,
      );
      final two = [
        one,
        QuantumMixedStatePhaseMember(
          phaseRadians: 0.4,
          oscillatorId: osc,
          omega: omega,
          periodSeconds: T,
          referenceEpoch: epoch,
        ),
      ];
      final r = matcher.compare(ensembleA: [one], ensembleB: two);
      expect(r.available, isFalse);
      expect(
        r.unavailableReason,
        QuantumMixedStateShadowContract.reasonInsufficientEnsemble,
      );
      expect(QuantumMixedStateShadowContract.minEnsembleSize, 2);
      expect(
        QuantumMixedStateShadowContract.layerContractVersion,
        L5MixedStateQiContract.policyVersion,
      );
    });

    test('Discover isolation — no L5 ranker coupling', () {
      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(discover.contains('L5MixedStateQiContract'), isFalse);
      expect(discover.contains('QuantumMixedStateShadowMatcher'), isFalse);
      expect(discover.contains('WaveStateModalShadowMatcher'), isFalse);
      expect(discover.contains('PeriodicWaveStateResonanceAdapter'), isFalse);

      final matcher = File(
        'lib/features/matching/domain/quantum_mixed_state_shadow_matcher.dart',
      ).readAsStringSync();
      expect(matcher.contains('DiscoverService'), isFalse);
      expect(matcher.contains('features/discover'), isFalse);
    });
  });
}
