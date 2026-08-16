/// L4 v1 post-match temporal diagnostics — non-ranking, no fusion.
///
/// Spec: `qmatch_l4_temporal_diagnostics_contract_v1`.
/// Production diagnostics are cadence / burstiness / regularity / reply-turn /
/// participation counts from observed thread metadata only.
/// Class A circadian is conditional. Class B ω / phase_alignment stay research
/// shadow. Mixed-state QI is L5 v1. Multi-mode Wave-State is research-only,
/// not L5 v1.
class L4TemporalDiagnosticsContract {
  L4TemporalDiagnosticsContract._();

  static const String policyVersion = 'l4_temporal_diagnostics_contract_v1';
  static const String policyStatus = 'production_diagnostics_non_ranking_v1';

  /// True = not a Discover ranker.
  static const bool shadowOnly = true;
  static const bool affectsDiscoverRanking = false;
  static const bool fusesWithL2 = false;
  static const bool fusesWithL3 = false;
  static const bool isL1EligibilityGate = false;
  static const bool gatesCalibrated = false;
  static const bool realCohortExists = false;
  static const bool lastActiveAtIsL4Signal = false;
  static const bool preMatchInferenceAllowed = false;
  static const bool questionnairePhaseOmegaAllowed = false;
  static const bool imputationAllowed = false;

  /// Production L4 v1 diagnostics (post-match thread metadata).
  static const bool cadenceProductionPromoted = true;
  static const bool burstinessProductionPromoted = true;
  static const bool regularityProductionPromoted = true;
  static const bool replyTurnProductionPromoted = true;
  static const bool participationCountProductionPromoted = true;

  /// Class A circadian: only when valid timezone + evidence gates exist.
  static const bool circadianConditionalDiagnostic = true;
  static const bool circadianUnconditionalProductionPromoted = false;

  /// Research shadow — implemented, not L4 v1 production-promoted.
  static const bool classBOmegaProductionPromoted = false;
  static const bool periodicPhaseProductionPromoted = false;
  static const bool phaseAlignmentProductionPromoted = false;
  static const bool activityAmplitudeProductionPromoted = false;
  static const bool globalActivityOscillatorComparisonProductionPromoted =
      false;

  static const String scope = 'post_match_thread_metadata';
  static const String circadianOscillatorIdCanonical =
      'circadian_activity_24h';
  static const String circadianOscillatorIdAlias = 'circadian_24h';
}
