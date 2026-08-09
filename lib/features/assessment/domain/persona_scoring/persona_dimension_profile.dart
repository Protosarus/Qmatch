/// Canonical 20D dimension registry constants for persona scoring.
///
/// Source of truth: `docs/core_engine/canonical_dimension_registry_v1.md`.
class PersonaDimensionIds {
  PersonaDimensionIds._();

  static const List<String> iq = [
    'logical_reasoning',
    'pattern_reasoning',
    'verbal_reasoning',
    'spatial_reasoning',
  ];

  static const List<String> eq = [
    'empathy',
    'perspective_taking',
    'self_awareness',
    'emotion_regulation',
    'emotional_openness',
    'boundary_setting',
    'assertiveness',
    'conflict_approach',
    'repair_orientation',
    'social_awareness',
  ];

  static const List<String> frequency = [
    'depth_preference',
    'social_energy',
    'spontaneity',
    'stability',
    'disclosure_pace',
    'communication_pace',
  ];

  static const List<String> all = [...iq, ...eq, ...frequency];

  static const Set<String> allSet = {
    ...iq,
    ...eq,
    ...frequency,
  };

  static const Set<String> forbiddenAliases = {
    'numerical',
    'autonomy',
    'adaptability',
    'intuitiveSensitivity',
    'logic',
    'pattern',
    'verbal',
    'spatial',
    'selfAwareness',
    'emotionalRegulation',
    'boundaries',
    'perspectiveTaking',
    'repairOrientation',
    'depth',
    'socialEnergy',
    'conversationPace',
    'emotionalOpenness',
  };

  static const Set<String> forbiddenLegacyGridIds = {
    'HH',
    'HM',
    'HL',
    'MH',
    'MM',
    'ML',
    'LH',
    'LM',
    'LL',
  };

  static const Set<String> forbiddenFrequencyTypes = {
    'Deep Connector',
    'Social Spark',
    'Balanced Frequency',
    'Steady Presence',
    'Quiet Anchor',
    'Expressive Wave',
  };

  static String groupOf(String dimensionId) {
    if (iq.contains(dimensionId)) return 'iq';
    if (frequency.contains(dimensionId)) return 'frequency';
    if (eq.contains(dimensionId)) return 'eq';
    throw ArgumentError('Unknown dimension: $dimensionId');
  }

  static List<String> dimsOf(String group) {
    switch (group) {
      case 'iq':
        return iq;
      case 'eq':
        return eq;
      case 'frequency':
        return frequency;
      default:
        throw ArgumentError('Unknown group: $group');
    }
  }
}

/// Per-dimension quality inputs used to form q_j.
class PersonaDimensionQuality {
  final double reliability;
  final double evidenceSufficiency;
  final double qualityWeight;

  const PersonaDimensionQuality({
    required this.reliability,
    required this.evidenceSufficiency,
    required this.qualityWeight,
  });
}
