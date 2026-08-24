/// Relationship Profile v1 — separate from canonical 20D / Persona / Matching.
class RelationshipDimensionIds {
  RelationshipDimensionIds._();

  static const closenessNeed = 'closeness_need';
  static const autonomyNeed = 'autonomy_need';
  static const reassuranceNeed = 'reassurance_need';
  static const trustOrientation = 'trust_orientation';
  static const commitmentOrientation = 'commitment_orientation';
  static const relationshipPace = 'relationship_pace';
  static const affectionExpression = 'affection_expression';
  static const playfulness = 'playfulness';

  static const List<String> all = [
    closenessNeed,
    autonomyNeed,
    reassuranceNeed,
    trustOrientation,
    commitmentOrientation,
    relationshipPace,
    affectionExpression,
    playfulness,
  ];

  static const Set<String> allSet = {
    closenessNeed,
    autonomyNeed,
    reassuranceNeed,
    trustOrientation,
    commitmentOrientation,
    relationshipPace,
    affectionExpression,
    playfulness,
  };
}

class RelationshipAnalysisContract {
  RelationshipAnalysisContract._();

  static const assessmentType = 'relationship';
  static const schemaVersion = 'qmatch_relationship_analysis_bank_v1';
  static const bankVersion = 'relationship_analysis_v1';
  static const contentVersion = 'relationship-analysis-v1.2.1';
  static const scoringPolicyVersion = 'relationship_8d_signed_evidence_v1';

  /// Depth uses answered-question capability exposure (not selected-option deltas).
  static const analysisDepthPolicyVersion =
      'relationship_analysis_depth_capability_v1';
  static const dimensionRegistryVersion = 'relationship_dimension_registry_v1';
  static const liveResultSchemaVersion = 'qmatch_relationship_live_result_v1';
  static const assetPath = 'assets/data/relationship_analysis_v1.json';

  static const questionCount = 24;
  static const microScanSize = 4;
  static const minQuestionsPerDimension = 6;
  static const minAbsWeightPerDimension = 3.0;
  static const scoreBaseline = 0.5;
  static const scoreScale = 2.5;

  /// Proactive Activity card/badge suppressed this long after a completed batch.
  static const proactiveNudgeCooldown = Duration(hours: 24);
}
