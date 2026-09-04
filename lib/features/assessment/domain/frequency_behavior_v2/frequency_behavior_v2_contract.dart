/// Dormant Frequency behavioral V2 pool contracts.
///
/// Not selected by live Frequency routing. Does not write canonical 6D or 20D
/// Frequency slots. Does not map 12D → 6D.
class FrequencyBehaviorV2Contract {
  FrequencyBehaviorV2Contract._();

  static const String schemaVersion = 'qmatch_frequency_behavior_pool_v2';
  static const String poolVersionTrDraft1 =
      'frequency_behavior_pool_tr_v2_draft1';
  static const String scoringPolicyVersion =
      'frequency_behavior_12d_signed_evidence_v2';
  static const String selectionPolicyVersion =
      'frequency_behavior_50_of_426_seeded_quota_v2_draft1';
  static const String selectorVersion = 'frequency_behavior_v2_selector_v1';
  static const String scorerVersion = 'frequency_behavior_v2_scorer_v1';
  static const String confidenceModelVersion =
      'frequency_behavior_v2_confidence_v1';
  static const String sessionManifestSchemaVersion =
      'qmatch_frequency_behavior_v2_session_manifest_v1';
  static const String sessionScoreSchemaVersion =
      'qmatch_frequency_behavior_v2_session_score_v1';
  static const String selectorRngAlgorithmVersion = 'xorshift32_fnv1a32_v1';
  static const int sessionBasePerDimension = 4;
  static const int sessionFlexSlots = 2;
  static const int maxConsecutiveSamePrimary = 2;

  /// Bounded unused-candidate window for preferring a different semantic
  /// cluster. Not a hard per-cluster quota. 0 would be rank-only.
  static const int softClusterLookahead = 2;
  static const String selectorContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_selector_v1_contract.md';
  static const String scorerContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_scorer_v1_contract.md';
  static const String confidenceContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_confidence_v1_contract.md';
  static const String phase3aSimulationReportRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase3a_selector_simulation.md';
  static const String phase3bSimulationReportRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase3b_selector_fairness_simulation.md';
  static const String phase3cSimulationReportRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase3c_soft_diversity_simulation.md';
  static const String phase4aScorerAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase4a_scorer_audit.md';
  static const String phase4bConfidenceAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase4b_confidence_audit.md';
  static const String telemetryResponseSchemaVersion =
      'qmatch_frequency_behavior_v2_response_telemetry_v1';
  static const String telemetrySessionSchemaVersion =
      'qmatch_frequency_behavior_v2_session_telemetry_v1';
  static const String calibrationAggregateSchemaVersion =
      'qmatch_frequency_behavior_v2_calibration_aggregate_v1';
  static const String telemetryContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_calibration_telemetry_v1_contract.md';
  static const String phase4cTelemetryAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase4c_calibration_telemetry_audit.md';
  static const String signedPoleEncodingVersion =
      'frequency_behavior_v2_signed_pole_state_v1';
  static const String signedPoleStateSchemaVersion =
      'qmatch_frequency_behavior_v2_signed_pole_state_v1';
  static const String quantumStateEncodingContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_quantum_state_encoding_v1_contract.md';
  static const String phase5aQuantumStateAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase5a_quantum_state_encoding_audit.md';
  static const int signedPoleAmplitudeCount = 24;
  static const double signedPolePairNormSquared = 1.0;
  static const double signedPoleGlobalNormSquared = 12.0;
  static const double signedPoleNumericTolerance = 1e-9;
  static const String mixedDensityVersion =
      'frequency_behavior_v2_mixed_density_v1';
  static const String mixedDensitySchemaVersion =
      'qmatch_frequency_behavior_v2_mixed_density_v1';
  static const String mixedDensityContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_mixed_density_v1_contract.md';
  static const String phase5bMixedDensityAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase5b_mixed_density_audit.md';
  static const double mixedDensityMaximallyMixedPurity = 1.0 / 24.0;
  static const String pairRelationVersion =
      'frequency_behavior_v2_pair_relation_v1';
  static const String pairRelationSchemaVersion =
      'qmatch_frequency_behavior_v2_pair_relation_v1';
  static const String pairRelationContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_pair_relation_v1_contract.md';
  static const String phase5cPairRelationAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase5c_pair_relation_audit.md';
  static const String pairFitPolicyVersion = 'frequency_pair_fit_policy_v1';
  static const String pairFitVersion = 'frequency_behavior_v2_pair_fit_v1';
  static const String pairFitSchemaVersion =
      'qmatch_frequency_behavior_v2_pair_fit_v1';
  static const String pairFitContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_pair_fit_v1_contract.md';
  static const String phase5dPairFitAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase5d_pair_fit_audit.md';
  static const String pairFitPolicySimilarityLinear = 'SIMILARITY_LINEAR';
  static const String pairFitPolicySimilarityTolerant = 'SIMILARITY_TOLERANT';
  static const List<String> pairFitLinearPolicyDimensions = [
    'contact_need',
    'closeness_pace',
    'autonomy',
    'reassurance_need',
    'uncertainty_tolerance',
    'disclosure_pace',
    'boundary_firmness',
    'repair_style',
  ];
  static const List<String> pairFitTolerantPolicyDimensions = [
    'initiative',
    'social_energy',
    'structure_preference',
    'adaptability',
  ];
  static const bool telemetryLiveCollectionEnabled = false;
  static const int telemetryMinCohortN = 100;
  static const int telemetryLatencyMinValidMs = 0;
  static const int telemetryLatencyMaxValidMs = 1800000;
  static const String telemetryRetentionPolicy = 'configurable';
  static const Set<String> telemetryForbiddenPayloadKeys = {
    'name',
    'email',
    'phone',
    'free_text_bio',
    'precise_gps',
    'latitude',
    'longitude',
    'advertising_id',
    'contacts',
    'photos',
    'date_of_birth',
    'employer_name',
  };
  static const String reviewMetadataSchemaVersion =
      'qmatch_frequency_behavior_pool_v2_review_metadata';
  static const String latentHandoffSchemaVersion =
      'qmatch_frequency_behavior_v2_latent_handoff_v1';

  static const String localeTr = 'tr-TR';
  static const String localeEn = 'en-US';
  static const String poolVersionEnDraft1 =
      'frequency_behavior_pool_en_v2_draft1';
  static const String translationVersionEnSemanticV1 =
      'frequency_v2_en_semantic_v1';
  static const String statusDraftNotRuntime = 'draft_not_runtime';

  /// Translation review statuses (separate from evidence review).
  static const String translationReviewPendingHuman = 'PENDING_HUMAN_REVIEW';
  static const String translationReviewReviewed = 'REVIEWED';
  static const String translationReviewCrossCultural =
      'CROSS_CULTURAL_REVIEW_REQUIRED';
  static const String translationReviewEvidenceParity =
      'EVIDENCE_PARITY_REVIEW_REQUIRED';

  static const int poolItemCount = 426;
  static const int optionsPerItem = 4;
  static const int poolOptionCount = 1704;
  static const int sessionItemCount = 50;
  static const int dimensionCount = 12;

  static const double weightMin = -2.0;
  static const double weightMax = 2.0;
  static const double evidenceMetaMin = 0.0;
  static const double evidenceMetaMax = 1.0;
  static const String evidenceMetaVersion = 'frequency_evidence_prior_v1';
  static const String evidenceCalibrationUncalibrated = 'uncalibrated';
  static const String evidenceReviewPending = 'pending';
  static const String evidenceReviewReviewed = 'reviewed';
  static const String evidenceContractRelativePath =
      'docs/assessment/frequency_v2/frequency_evidence_metadata_v1_contract.md';

  static const List<double> evidenceAllowedValues = [
    0.00,
    0.25,
    0.50,
    0.75,
    1.00,
  ];

  static const String draftPoolRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1.json';
  static const String draftReviewRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1_review_metadata.json';
  static const String draftPoolEnRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1.json';
  static const String draftReviewEnRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1_review_metadata.json';
  static const String runtimeAssetDirectory = 'assets/assessment/frequency_v2';
  static const String runtimePoolAssetPathTr =
      '$runtimeAssetDirectory/frequency_behavior_pool_tr_v2_draft1.json';
  static const String runtimeReviewAssetPathTr =
      '$runtimeAssetDirectory/frequency_behavior_pool_tr_v2_draft1_review_metadata.json';
  static const String runtimePoolAssetPathEn =
      '$runtimeAssetDirectory/frequency_behavior_pool_en_v2_draft1.json';
  static const String runtimeReviewAssetPathEn =
      '$runtimeAssetDirectory/frequency_behavior_pool_en_v2_draft1_review_metadata.json';
  static const String phase6aEnParityAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_v2_phase6a_en_parity_audit.md';
  static const String phase6aEnSemanticParityContractRelativePath =
      'docs/assessment/frequency_v2/frequency_v2_en_semantic_parity_v1_contract.md';
  static const String phase6aEnHumanReviewDirRelativePath =
      'tool/frequency_behavior_v2/out/en_human_review';
  static const String draftSelectorPlanRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1_selector_plan.json';
  static const String sourcePoolRelativePath =
      'docs/qmatch_frequency_v2_426_unique_source_pool_tr.txt';

  static const List<String> canonicalDimensions = [
    'contact_need',
    'closeness_pace',
    'initiative',
    'autonomy',
    'reassurance_need',
    'uncertainty_tolerance',
    'disclosure_pace',
    'boundary_firmness',
    'repair_style',
    'social_energy',
    'structure_preference',
    'adaptability',
  ];

  static const Set<String> canonicalDimensionSet = {
    ...canonicalDimensions,
  };

  static const Map<String, String> safeAliases = {
    'initiative_tendency': 'initiative',
    'autonomy_need': 'autonomy',
    'boundary_style': 'boundary_firmness',
    'rhythm_adaptation': 'adaptability',
  };

  /// Never auto-map. Not equivalent to [repair_style].
  static const Set<String> neverAutoMap = {
    'processing_style',
  };

  /// Legacy/unknown labels dropped in Phase 1C. Not 12D IDs.
  static const Set<String> droppedUnknownDimensionLabels = {
    'processing_style',
    'conflict_approach',
    'baseline',
    'reciprocity',
    'trust',
  };

  /// Behavioral pacing/engagement for [repair_style], not a moral or health score.
  /// Negative values are not unhealthy/toxic/bad.
  ///
  /// +2 immediate / active repair engagement
  /// +1 mildly active repair / constructive revisit
  /// -1 delayed / partial / mixed repair, often pause-then-return
  /// -2 blocked / withdrawn / shut-down repair with no explicit return
  static const Map<int, String> repairStyleOrientation = {
    2: 'immediate_active_repair_engagement',
    1: 'mildly_active_repair_constructive_revisit',
    -1: 'delayed_partial_mixed_repair_pause_then_return',
    -2: 'blocked_withdrawn_shutdown_repair_no_explicit_return',
  };

  static const String humanDecisionPhase1cFile =
      'docs/qmatch_frequency_v2_phase1b_human_decisions.txt';
  static const String humanDecisionPhase1fFile =
      'docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt';
  static const String humanDecisionPhase1gFile =
      'docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt';
  static const String humanDecisionPhase2eFile =
      'docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt';
  static const String humanDecisionPhase2fFile =
      'docs/qmatch_frequency_v2_phase2e_final_human_evidence_review.txt';

  static const int phase1fApprovedPrimaryCount = 54;
  static const int phase1fRewritePendingCount = 26;
  static const int phase1fDropFromSelectableCount = 18;
  static const int phase1fSelectableAfterExclusions = 382;
  static const int phase1gRewrittenQuestionCount = 26;
  static const int phase1gRewrittenOptionCount = 104;
  static const int phase1gSelectableAfterRewrites = 408;
  static const int phase2eRewrittenQuestionCount = 10;
  static const int phase2eRewrittenOptionCount = 40;
  static const int phase2eNewDropCount = 2;
  static const int phase2eDropFromSelectableTotal = 20;
  static const int phase2eSelectableAfterDrops = 406;
  static const int phase2eRevisedProposalQuestionCount = 396;
  static const int phase2eQuestionFieldCorrectionCount = 23;
  static const int phase2eDvTooLowCorrectionCount = 6;
  static const int phase2eDvJustifiedUnchangedCount = 4;
  static const int phase2fNewDropCount = 1;
  static const int phase2fDropFromSelectableTotal = 21;
  static const int phase2fSelectableAfterDrops = 405;
  static const int phase2fReviewedQuestionCount = 405;
  static const int phase2fReviewedOptionCount = 1620;
  static const int phase2fDropOptionCount = 84;
  static const int phase2fHumanOverrideFieldChangeCount = 33;
  static const int phase2fRetainedRewrittenQuestionCount = 9;
  static const int phase2bSelectableQuestionCount = 408;
  static const int phase2bSelectableOptionCount = 1632;
  static const int phase2bDropOptionCount = 72;
  static const String draftPhase2bProposalRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2b_evidence_prior_proposal.json';
  static const String draftPhase2bAuditRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2b_evidence_audit.md';
  static const int phase2cTriageQuestionCount = 408;
  static const int phase2cRealReviewRequiredCount = 29;
  static const int phase2cKeepFlagCount = 29;
  static const int phase2cClearFlagCount = 368;
  static const String draftPhase2cTriageJsonRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2c_evidence_triage.json';
  static const String draftPhase2cTriageMdRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2c_evidence_triage.md';
  static const int phase2dPacketQuestionCount = 29;
  static const int phase2dLeakageOptionCount = 10;
  static const String draftPhase2dPacketRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2d_human_evidence_decision_packet.md';
  static const String draftPhase2eRevisedProposalRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2e_evidence_prior_revised_proposal.json';
  static const String draftPhase2eRewritten10ProposalRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2e_rewritten_10_evidence_proposal.json';
  static const String draftPhase2eRewritten10ReviewRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2e_rewritten_10_evidence_review.md';
  static const String draftPhase2eApplyReportRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2e_apply_report.md';
  static const String draftPhase2fFinalEvidenceRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2f_final_evidence_prior.json';
  static const String draftPhase2fApplyReportRelativePath =
      'tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2f_final_evidence_apply_report.md';
  static const String draftPoolContentFingerprintSha256 =
      'd03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d';
  static const String draftPoolContentFingerprintSha256Phase2e =
      '6acb86e18f1567890ea1c112fa54c0ffcdde2d9cda11f1c61e2ca0164d170518';

  static const List<String> evidenceMetaKeys = [
    'social_desirability',
    'obviousness',
    'behavioral_plausibility',
    'self_presentation_risk',
    'diagnostic_value',
    'ambiguity',
  ];

  static const Set<String> evidenceMetaNotAuthored = {
    'discrimination_power',
    'response_time',
    'directness',
  };

  static const Set<String> forbiddenInferenceLabels = {
    'truth_score',
    'lie_score',
    'deception_score',
    'honesty_score',
  };

  /// Live V1 Frequency assets — V2 must never overwrite these paths.
  static const List<String> liveV1BankPaths = [
    'assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json',
    'assets/data/assessment_v3/frequency/frequency_bank_en_v1.json',
  ];

  /// Phase 4B provisional confidence — engineering heuristic, not a probability.
  static const double confidenceEvidenceWeight = 0.50;
  static const double confidenceObservabilityWeight = 0.30;
  static const double confidenceContextWeight = 0.20;
  static const double presentationPressureMaxDiscount = 0.20;
  static const double flagLowEvidenceQualityMax = 0.50;
  static const double flagHighPresentationPressureMin = 0.75;
  static const double flagLowPrimaryObservabilityMax = 0.50;
  static const double flagLimitedCrossContextCoverageMax = 0.50;
  static const double flagContextSensitiveConsistencyMax = 0.50;
  static const double flagContextSensitiveCoverageMin = 0.50;
  static const String flagLowEvidenceQuality = 'LOW_EVIDENCE_QUALITY';
  static const String flagHighPresentationPressure =
      'HIGH_PRESENTATION_PRESSURE';
  static const String flagLowPrimaryObservability = 'LOW_PRIMARY_OBSERVABILITY';
  static const String flagLimitedCrossContext = 'LIMITED_CROSS_CONTEXT';
  static const String flagContextSensitive = 'CONTEXT_SENSITIVE';

  static bool isCanonicalDimension(String id) =>
      canonicalDimensionSet.contains(id);

  static bool isAllowedEvidenceValue(double value) {
    for (final allowed in evidenceAllowedValues) {
      if ((value - allowed).abs() < 1e-9) return true;
    }
    return false;
  }

  static String? applySafeAlias(String raw) {
    final key = raw.trim();
    if (canonicalDimensionSet.contains(key)) return key;
    return safeAliases[key];
  }
}
