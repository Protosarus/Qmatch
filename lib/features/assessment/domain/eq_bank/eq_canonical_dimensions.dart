/// Canonical EQ 10D taxonomy (language-independent).
///
/// Source: `docs/core_engine/canonical_dimension_registry_v1.md`.
class EqCanonicalDimensions {
  EqCanonicalDimensions._();

  static const List<String> all = [
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

  static const Set<String> allSet = {
    ...all,
  };

  /// Legacy / forbidden EQ taxonomies — must never appear in runtime banks.
  static const Set<String> forbiddenLegacy = {
    'autonomy',
    'adaptability',
    'intuitiveSensitivity',
  };

  static bool isCanonical(String id) => allSet.contains(id);

  static bool isForbiddenLegacy(String id) => forbiddenLegacy.contains(id);
}
