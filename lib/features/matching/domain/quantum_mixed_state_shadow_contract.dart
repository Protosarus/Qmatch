/// Validated shadow research signal: mixed-state quantum-inspired matching v1.
///
/// Equal-window Class-B ensembles on one oscillator. Frozen after synthetic
/// stress: mixed QI adds information beyond mean-phase alignment; pure-state
/// QI must not be a separate Matching signal.
///
/// Status: [policyStatus] = `validated_shadow_not_live`.
/// No Discover ranking, Persona, RVI, fusion weights, or free \(\lambda\).
/// Real-data validation still pending.
class QuantumMixedStateShadowContract {
  QuantumMixedStateShadowContract._();

  static const String scoringVersion = 'quantum_mixed_state_shadow_v1';
  static const String policyVersion =
      'quantum_mixed_state_shadow_policy_freeze_v1';
  static const String policyStatus = 'validated_shadow_not_live';

  static const bool shadowOnly = true;
  static const bool validatedShadowResearchSignal = true;
  static const bool specificationOnlyNotLive = false;
  static const bool realDataValidationPending = true;
  static const bool gatesCalibrated = false;
  static const bool liveDiscoverRanking = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
  static const bool densityMatrixEnabledForRanking = false;
  static const bool fusesWithStructural = false;
  static const bool fusesWithPhaseAlignment = false;
  static const bool fusesWithActivityLevelGap = false;
  static const bool questionnaireStatesAllowed = false;
  static const bool freeLambdaAllowed = false;
  static const bool rankingWeightsAllowed = false;
  static const bool pureStateQiAsSeparateSignal = false;

  /// Frozen weight policy for v1.
  static const String weightPolicyId = 'equal_window_v1';

  /// Frozen pairwise research fields (separate diagnostics; not fused).
  static const List<String> frozenWireFields = [
    'purity_A',
    'purity_B',
    'qi_mixed_fidelity',
    'qi_trace_distance',
    'weight_policy_id',
    'ensemble_count_A',
    'ensemble_count_B',
    'bloch_A',
    'bloch_B',
  ];

  static const int minEnsembleSize = 2;
  static const double omegaRelativeTolerance = 1e-9;
  static const double periodRelativeTolerance = 1e-9;
  static const double rhoNumericalTolerance = 1e-9;

  static const String reasonInsufficientEnsemble = 'insufficient_ensemble';
  static const String reasonInconsistentEnsemble = 'inconsistent_ensemble';
  static const String reasonProvenanceMismatch = 'provenance_mismatch';
  static const String reasonInvalidRho = 'invalid_density_matrix';
  static const String reasonEmptyEnsemble = 'empty_ensemble';
}
