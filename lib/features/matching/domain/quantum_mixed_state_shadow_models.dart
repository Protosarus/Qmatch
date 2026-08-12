import 'quantum_mixed_state_shadow_contract.dart';

/// One accepted Class-B phase estimate (one temporal window / member).
class QuantumMixedStatePhaseMember {
  const QuantumMixedStatePhaseMember({
    required this.phaseRadians,
    required this.oscillatorId,
    required this.omega,
    required this.periodSeconds,
    required this.referenceEpoch,
  });

  final double phaseRadians;
  final String oscillatorId;
  final double omega;
  final double periodSeconds;

  /// Absolute epoch string (Class B). Ensemble members must share the same
  /// epoch policy value for v1 (identical string).
  final String referenceEpoch;
}

/// Equatorial Bloch vector \(r=(r_x,r_y,0)\).
class QuantumMixedStateBlochVector {
  const QuantumMixedStateBlochVector({
    required this.rx,
    required this.ry,
  });

  final double rx;
  final double ry;

  double get normSquared => rx * rx + ry * ry;

  Map<String, dynamic> toWireMap() => {
        'r_x': rx,
        'r_y': ry,
        'r_z': 0.0,
        'norm_squared': normSquared,
      };
}

/// Shadow-only pairwise mixed-state QI result.
class QuantumMixedStateShadowResult {
  const QuantumMixedStateShadowResult({
    required this.available,
    required this.unavailableReason,
    required this.purityA,
    required this.purityB,
    required this.qiMixedFidelity,
    required this.qiTraceDistance,
    required this.blochA,
    required this.blochB,
    required this.ensembleCountA,
    required this.ensembleCountB,
    required this.oscillatorId,
    required this.periodSeconds,
    required this.omega,
    required this.referenceEpoch,
    required this.weightPolicyId,
  });

  final bool available;
  final String? unavailableReason;

  final double? purityA;
  final double? purityB;
  final double? qiMixedFidelity;
  final double? qiTraceDistance;

  final QuantumMixedStateBlochVector? blochA;
  final QuantumMixedStateBlochVector? blochB;

  final int ensembleCountA;
  final int ensembleCountB;

  final String? oscillatorId;
  final double? periodSeconds;
  final double? omega;
  final String? referenceEpoch;
  final String weightPolicyId;

  Map<String, dynamic> toWireMap() => {
        'scoring_version': QuantumMixedStateShadowContract.scoringVersion,
        'policy_version': QuantumMixedStateShadowContract.policyVersion,
        'policy_status': QuantumMixedStateShadowContract.policyStatus,
        'shadow_only': QuantumMixedStateShadowContract.shadowOnly,
        'validated_shadow_research_signal':
            QuantumMixedStateShadowContract.validatedShadowResearchSignal,
        'specification_only_not_live':
            QuantumMixedStateShadowContract.specificationOnlyNotLive,
        'real_data_validation_pending':
            QuantumMixedStateShadowContract.realDataValidationPending,
        'gates_calibrated': QuantumMixedStateShadowContract.gatesCalibrated,
        'live_discover_ranking':
            QuantumMixedStateShadowContract.liveDiscoverRanking,
        'persona_enabled': QuantumMixedStateShadowContract.personaEnabled,
        'rvi_enabled': QuantumMixedStateShadowContract.rviEnabled,
        'density_matrix_enabled_for_ranking': QuantumMixedStateShadowContract
            .densityMatrixEnabledForRanking,
        'fuses_with_structural':
            QuantumMixedStateShadowContract.fusesWithStructural,
        'fuses_with_phase_alignment':
            QuantumMixedStateShadowContract.fusesWithPhaseAlignment,
        'fuses_with_activity_level_gap':
            QuantumMixedStateShadowContract.fusesWithActivityLevelGap,
        'questionnaire_states_allowed':
            QuantumMixedStateShadowContract.questionnaireStatesAllowed,
        'free_lambda_allowed':
            QuantumMixedStateShadowContract.freeLambdaAllowed,
        'ranking_weights_allowed':
            QuantumMixedStateShadowContract.rankingWeightsAllowed,
        'pure_state_qi_as_separate_signal':
            QuantumMixedStateShadowContract.pureStateQiAsSeparateSignal,
        'weight_policy_id': weightPolicyId,
        'available': available,
        if (unavailableReason != null) 'unavailable_reason': unavailableReason,
        if (purityA != null) 'purity_A': purityA,
        if (purityB != null) 'purity_B': purityB,
        if (qiMixedFidelity != null) 'qi_mixed_fidelity': qiMixedFidelity,
        if (qiTraceDistance != null) 'qi_trace_distance': qiTraceDistance,
        if (blochA != null) 'bloch_A': blochA!.toWireMap(),
        if (blochB != null) 'bloch_B': blochB!.toWireMap(),
        'ensemble_count_A': ensembleCountA,
        'ensemble_count_B': ensembleCountB,
        if (oscillatorId != null) 'oscillator_id': oscillatorId,
        if (periodSeconds != null) 'period_seconds': periodSeconds,
        if (omega != null) 'omega': omega,
        if (referenceEpoch != null) 'reference_epoch': referenceEpoch,
      };
}
