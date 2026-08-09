/// Immutable persona scoring config (from persona_scoring_config_v2.json).
class PersonaScoringConfig {
  final String configVersion;
  final String status;
  final String personaProfileVersion;
  final String dimensionRegistryVersion;
  final double iqWeight;
  final double eqWeight;
  final double frequencyWeight;
  final double levelDistanceWeight;
  final double shapeDistanceWeight;
  final double antiTraitPenaltyWeight;
  final double missingEvidencePenaltyWeight;
  final double similarityTemperature;
  final double top2MarginThreshold;
  final double lowConfidenceThreshold;
  final Map<String, double> minimumGroupCoverage;
  final double minimumTotalCoverage;
  final bool adaptiveSeparatorEnabled;
  final int adaptiveSeparatorMaxQuestions;
  final String deterministicTieBreakPolicy;
  final double numericalEpsilon;
  final Map<String, Object?> calibrationNotes;
  final bool allowPartialGroupRenormalization;

  const PersonaScoringConfig({
    required this.configVersion,
    required this.status,
    required this.personaProfileVersion,
    required this.dimensionRegistryVersion,
    required this.iqWeight,
    required this.eqWeight,
    required this.frequencyWeight,
    required this.levelDistanceWeight,
    required this.shapeDistanceWeight,
    required this.antiTraitPenaltyWeight,
    required this.missingEvidencePenaltyWeight,
    required this.similarityTemperature,
    required this.top2MarginThreshold,
    required this.lowConfidenceThreshold,
    required this.minimumGroupCoverage,
    required this.minimumTotalCoverage,
    required this.adaptiveSeparatorEnabled,
    required this.adaptiveSeparatorMaxQuestions,
    required this.deterministicTieBreakPolicy,
    required this.numericalEpsilon,
    required this.calibrationNotes,
    this.allowPartialGroupRenormalization = false,
  });

  double groupWeight(String group) {
    switch (group) {
      case 'iq':
        return iqWeight;
      case 'eq':
        return eqWeight;
      case 'frequency':
        return frequencyWeight;
      default:
        throw ArgumentError('Unknown group: $group');
    }
  }

  bool get isSyntheticValidationOnly {
    final notes = calibrationNotes;
    return notes['production_calibration_required'] == true ||
        notes['provisional'] == true ||
        status == 'provisional';
  }
}
