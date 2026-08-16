import 'l5_mixed_state_qi_contract.dart';

/// Validated shadow research signal: mixed-state quantum-inspired matching v1.
///
/// Equal-window Class-B ensembles on one oscillator. Frozen after synthetic
/// stress: mixed QI adds information beyond mean-phase alignment; pure-state
/// QI must not be a separate Matching signal.
///
/// L5 v1 layer freeze: [L5MixedStateQiContract]
/// (`validated_shadow_not_live`). No Discover ranking, Persona, RVI, fusion
/// weights, or free \(\lambda\). Real-data validation still pending.
class QuantumMixedStateShadowContract {
  QuantumMixedStateShadowContract._();

  static const String scoringVersion = L5MixedStateQiContract.scoringVersion;
  static const String policyVersion =
      'quantum_mixed_state_shadow_policy_freeze_v1';
  static const String layerContractVersion =
      L5MixedStateQiContract.policyVersion;
  static const String policyStatus = L5MixedStateQiContract.policyStatus;

  static const bool shadowOnly = L5MixedStateQiContract.shadowOnly;
  static const bool validatedShadowResearchSignal =
      L5MixedStateQiContract.validatedShadowResearchSignal;
  static const bool specificationOnlyNotLive =
      L5MixedStateQiContract.specificationOnlyNotLive;
  static const bool realDataValidationPending =
      L5MixedStateQiContract.realDataValidationPending;
  static const bool gatesCalibrated = L5MixedStateQiContract.gatesCalibrated;
  static const bool liveDiscoverRanking =
      L5MixedStateQiContract.liveDiscoverRanking;
  static const bool personaEnabled = L5MixedStateQiContract.personaEnabled;
  static const bool rviEnabled = L5MixedStateQiContract.rviEnabled;
  static const bool densityMatrixEnabledForRanking = false;
  static const bool fusesWithStructural =
      L5MixedStateQiContract.fusesWithStructural;
  static const bool fusesWithPhaseAlignment =
      L5MixedStateQiContract.fusesWithPhaseAlignment;
  static const bool fusesWithActivityLevelGap =
      L5MixedStateQiContract.fusesWithActivityLevelGap;
  static const bool fusesWithL2 = L5MixedStateQiContract.fusesWithL2;
  static const bool fusesWithL3 = L5MixedStateQiContract.fusesWithL3;
  static const bool fusesWithL4 = L5MixedStateQiContract.fusesWithL4;
  static const bool questionnaireStatesAllowed =
      L5MixedStateQiContract.questionnairePhaseOmegaAllowed;
  static const bool freeLambdaAllowed =
      L5MixedStateQiContract.freeLambdaAllowed;
  static const bool rankingWeightsAllowed =
      L5MixedStateQiContract.rankingWeightsAllowed;
  static const bool pureStateQiAsSeparateSignal =
      L5MixedStateQiContract.pureStateQiAsSeparateSignal;
  static const bool fidelityIsCompatibilityPercentage =
      L5MixedStateQiContract.fidelityIsCompatibilityPercentage;
  static const bool fusedRWaveIsL5Score =
      L5MixedStateQiContract.fusedRWaveIsL5Score;
  static const bool multimodeWaveStateInProduction =
      L5MixedStateQiContract.multimodeWaveStateInProduction;
  static const bool copiesGlobalActivityPhaseToFrequency6d =
      L5MixedStateQiContract.copiesGlobalActivityPhaseToFrequency6d;

  /// Frozen weight policy for v1.
  static const String weightPolicyId = L5MixedStateQiContract.weightPolicyId;

  /// Frozen pairwise research fields (separate diagnostics; not fused).
  static const List<String> frozenWireFields = [
    ...L5MixedStateQiContract.retainedDiagnosticFields,
    'weight_policy_id',
    'ensemble_count_A',
    'ensemble_count_B',
    'bloch_A',
    'bloch_B',
  ];

  static const int minEnsembleSize =
      L5MixedStateQiContract.minAcceptedClassBWindows;
  static const double omegaRelativeTolerance = 1e-9;
  static const double periodRelativeTolerance = 1e-9;
  static const double rhoNumericalTolerance = 1e-9;

  static const String reasonInsufficientEnsemble = 'insufficient_ensemble';
  static const String reasonInconsistentEnsemble = 'inconsistent_ensemble';
  static const String reasonProvenanceMismatch = 'provenance_mismatch';
  static const String reasonInvalidRho = 'invalid_density_matrix';
  static const String reasonEmptyEnsemble = 'empty_ensemble';
}
