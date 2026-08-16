/// L5 v1 mixed-state QI — validated research shadow, non-ranking.
///
/// Spec: `qmatch_l5_mixed_state_qi_contract_v1`.
/// The only retained L5 v1 candidate is mixed-state QI on \(K\ge 2\)
/// accepted Class-B windows with shared oscillator provenance.
/// Purity, mixed fidelity, and trace distance stay separate diagnostics.
/// Pure-state QI, multi-mode Wave-State, and fused \(r_{\mathrm{wave}}\)
/// are not L5 v1 scores. No Discover ranking. No L2/L3/L4 fusion.
class L5MixedStateQiContract {
  L5MixedStateQiContract._();

  static const String policyVersion = 'l5_mixed_state_qi_contract_v1';
  static const String policyStatus = 'validated_shadow_not_live';
  static const String scoringVersion = 'quantum_mixed_state_shadow_v1';
  static const String weightPolicyId = 'equal_window_v1';
  static const String retainedCandidate = 'mixed_state_qi';

  /// True = not a Discover ranker.
  static const bool shadowOnly = true;
  static const bool validatedShadowResearchSignal = true;
  static const bool specificationOnlyNotLive = false;
  static const bool affectsDiscoverRanking = false;
  static const bool liveDiscoverRanking = false;

  static const bool fusesWithL2 = false;
  static const bool fusesWithL3 = false;
  static const bool fusesWithL4 = false;
  static const bool fusesWithStructural = false;
  static const bool fusesWithPhaseAlignment = false;
  static const bool fusesWithActivityLevelGap = false;

  static const bool rankingWeightsAllowed = false;
  static const bool freeLambdaAllowed = false;
  static const bool imputationAllowed = false;
  static const bool isL1EligibilityGate = false;

  static const bool gatesCalibrated = false;
  static const bool realMultiWindowCohortExists = false;
  static const bool realDataValidationPending = true;
  static const bool rankingRequiresSeparateRfc = true;

  /// \(K\ge 2\) accepted Class-B windows, same oscillator provenance.
  static const int minAcceptedClassBWindows = 2;
  static const bool requiresSharedOscillatorProvenance = true;
  static const bool classBWindowsFromL4ProductionDiagnostics = false;

  /// Frozen pairwise diagnostics (separate; not fused).
  static const List<String> retainedDiagnosticFields = [
    'purity_A',
    'purity_B',
    'qi_mixed_fidelity',
    'qi_trace_distance',
  ];

  static const bool fidelityIsCompatibilityPercentage = false;
  static const bool pureStateQiAsSeparateSignal = false;
  static const bool multimodeWaveStateInProduction = false;
  static const bool fusedRWaveIsL5Score = false;
  static const bool copiesGlobalActivityPhaseToFrequency6d = false;
  static const bool questionnairePhaseOmegaAllowed = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
}
