/// Offline adapter plan from TraitScoringService results → Core Method v2
/// DimensionMeasurement contracts.
///
/// This is documentation-as-code only. It is not production-wired and must not
/// be invoked from assessment screens, QuestionService, Discover, or matching.
class TraitScoringToDimensionMeasurementAdapterPlan {
  static const String planId =
      'trait_scoring_to_dimension_measurement_adapter_plan_v1';
  static const String status = 'planned_not_wired';
  static const bool productionWired = false;

  /// Mapping sketch (not executed):
  /// - TraitScoringResult.moduleTraitResults[*].dimensionScores[*]
  ///   → DimensionMeasurement
  /// - DimensionScoreResult.normalizedScore → normalizedScore only when
  ///   publicationStatus == published; otherwise null
  /// - DimensionScoreResult.confidence → confidence
  /// - DimensionScoreResult.uncertainty → uncertainty (do not invent 1-confidence)
  /// - evidence counts → primary/secondary/independentContextCount
  /// - publishability / publicationStatus preserved without fabricating scores
  /// - sourceContentVersions from assessment form content_version
  /// - scoringContractVersion from trait scoring config version
  /// - registryVersion from canonical_dimension_registry_v1
  static const Map<String, String> fieldMapping = {
    'dimension_id': 'DimensionScoreResult.dimensionId',
    'module': 'ModuleTraitResult.module / AssessmentModuleId',
    'normalized_score':
        'DimensionScoreResult.normalizedScore iff published else null',
    'confidence': 'DimensionScoreResult.confidence',
    'uncertainty': 'DimensionScoreResult.uncertainty',
    'primary_evidence_count': 'DimensionScoreResult.primaryEvidenceCount',
    'secondary_evidence_count': 'DimensionScoreResult.secondaryEvidenceCount',
    'independent_context_count': 'DimensionScoreResult.independentContextCount',
    'publication_status': 'DimensionScoreResult.publicationStatus',
    'publishability': 'DimensionScoreResult.publishability',
  };

  static Map<String, Object?> toJson() => {
        'plan_id': planId,
        'status': status,
        'production_wired': productionWired,
        'field_mapping': fieldMapping,
        'notes': [
          'Do not silently change TraitScoringService behavior.',
          'Do not connect persona scoring to compatibility.',
          'Adapter execution belongs to a later offline wiring phase.',
        ],
      };
}
