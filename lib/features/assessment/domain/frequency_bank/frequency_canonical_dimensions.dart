/// Canonical Frequency 6D taxonomy (language-independent).
///
/// Source: `docs/core_engine/canonical_dimension_registry_v1.md` and
/// [CanonicalDimensions.frequency].
class FrequencyCanonicalDimensions {
  FrequencyCanonicalDimensions._();

  static const List<String> all = [
    'depth_preference',
    'social_energy',
    'spontaneity',
    'stability',
    'disclosure_pace',
    'communication_pace',
  ];

  static const Set<String> allSet = {
    ...all,
  };

  /// Historical / legacy Frequency aliases — must never be used as canonical IDs.
  static const Set<String> forbiddenLegacy = {
    'depth',
    'socialEnergy',
    'emotionalOpenness',
    'conversationPace',
    'openingRhythm',
    'communicationTempo',
    'communication_tempo',
  };

  static bool isCanonical(String id) => allSet.contains(id);

  static bool isForbiddenLegacy(String id) => forbiddenLegacy.contains(id);
}
