/// Shadow-only mixed-state quantum-inspired matching contract v1.
///
/// Data-backed ensemble of accepted Class-B phases on the **same** oscillator.
/// Equal-window weights only in this implementation. No free \(\lambda\),
/// questionnaire states, Discover, Persona, or RVI.
class QuantumMixedStateShadowContract {
  QuantumMixedStateShadowContract._();

  static const String scoringVersion = 'quantum_mixed_state_shadow_v1';
  static const String policyVersion =
      'quantum_mixed_state_shadow_contract_v1';
  static const String policyStatus = 'shadow_only_not_live';

  static const bool shadowOnly = true;
  static const bool specificationOnlyNotLive = true;
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

  /// First implementation weight policy.
  static const String weightPolicyId = 'equal_window_v1';

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
