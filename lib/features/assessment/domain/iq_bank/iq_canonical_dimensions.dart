/// Canonical IQ four-dimension freeze (P2C-2A-0).
///
/// Runtime-neutral constants. Does not alter live IQ screens or scoring.
class IqCanonicalDimensions {
  IqCanonicalDimensions._();

  static const String logicalReasoning = 'logical_reasoning';
  static const String patternReasoning = 'pattern_reasoning';
  static const String verbalReasoning = 'verbal_reasoning';
  static const String spatialReasoning = 'spatial_reasoning';

  /// Exact ordered set for contracts and validators.
  static const List<String> all = <String>[
    logicalReasoning,
    patternReasoning,
    verbalReasoning,
    spatialReasoning,
  ];

  static const Set<String> allSet = {
    logicalReasoning,
    patternReasoning,
    verbalReasoning,
    spatialReasoning,
  };

  /// Retired legacy domain — never silently remapped.
  static const String retiredNumerical = 'numerical';

  static const Set<String> retired = {retiredNumerical};

  static bool isCanonical(String id) => allSet.contains(id);

  static bool isRetired(String id) => retired.contains(id);
}
