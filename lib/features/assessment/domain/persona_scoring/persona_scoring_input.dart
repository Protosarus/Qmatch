import 'persona_scoring_status.dart';

/// How evidence sufficiency is supplied to [PersonaScoringService].
///
/// Canonical path: [PersonaEvidenceSufficiencyMode.explicit] with
/// per-dimension values from the trait-scoring engine.
///
/// Deprecated offline-only path: [PersonaEvidenceSufficiencyMode.deprecatedGlobalDenominator]
/// reconstructs `min(1, evidenceCount / 3)` for legacy synthetic inputs.
enum PersonaEvidenceSufficiencyMode {
  /// Caller supplied [PersonaScoringInput.dimensionEvidenceSufficiency].
  explicit,

  /// Temporary adapter: `min(1, evidenceCount / 3)` when evidence > 0.
  /// Offline tests / simulator compatibility only. Not the canonical path.
  deprecatedGlobalDenominator,
}

/// Pure scoring input. Trait scores are separate from labels / matching.
class PersonaScoringInput {
  /// Present dimension scores in [0,1]. Missing dims must be absent.
  final Map<String, double> dimensionScores;

  /// Evidence counts per dimension (>=0). Missing/zero => no evidence.
  final Map<String, int> dimensionEvidenceCounts;

  /// Dimension-specific evidence sufficiency in [0,1].
  ///
  /// Required for [PersonaEvidenceSufficiencyMode.explicit].
  /// Ignored when using the deprecated global denominator adapter.
  final Map<String, double> dimensionEvidenceSufficiency;

  /// Reliability in [0,1]. Defaults applied by service when omitted.
  final Map<String, double> dimensionReliability;

  /// Explicit missing dimension IDs (unioned with absent scores).
  final Set<String> missingDimensions;

  /// Assessment completion statuses by group or assessment id.
  final Map<String, String> assessmentStatuses;

  final ResponseValidityStatus responseValidityStatus;
  final String dimensionRegistryVersion;
  final String personaProfileVersion;
  final String personaScoringVersion;

  /// Which sufficiency path the service must use.
  final PersonaEvidenceSufficiencyMode evidenceSufficiencyMode;

  const PersonaScoringInput({
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    this.dimensionEvidenceSufficiency = const {},
    this.dimensionReliability = const {},
    this.missingDimensions = const {},
    this.assessmentStatuses = const {},
    this.responseValidityStatus = ResponseValidityStatus.unknown,
    required this.dimensionRegistryVersion,
    required this.personaProfileVersion,
    required this.personaScoringVersion,
    this.evidenceSufficiencyMode = PersonaEvidenceSufficiencyMode.explicit,
  });

  /// Full-evidence helper for offline tools/tests.
  ///
  /// Sets evidence counts to 3 and **explicit** sufficiency to 1.0
  /// (canonical path — does not use the global `/3` adapter).
  factory PersonaScoringInput.fullEvidence({
    required Map<String, double> dimensionScores,
    required List<String> dimensionOrder,
    required String dimensionRegistryVersion,
    required String personaProfileVersion,
    required String personaScoringVersion,
    ResponseValidityStatus responseValidityStatus =
        ResponseValidityStatus.valid,
  }) {
    final present = [
      for (final d in dimensionOrder)
        if (dimensionScores.containsKey(d)) d,
    ];
    return PersonaScoringInput(
      dimensionScores: Map<String, double>.from(dimensionScores),
      dimensionEvidenceCounts: {for (final d in present) d: 3},
      dimensionEvidenceSufficiency: {for (final d in present) d: 1.0},
      dimensionReliability: {for (final d in present) d: 1.0},
      missingDimensions: {
        for (final d in dimensionOrder)
          if (!dimensionScores.containsKey(d)) d,
      },
      assessmentStatuses: const {
        'iq': 'complete',
        'eq': 'complete',
        'frequency': 'complete',
      },
      responseValidityStatus: responseValidityStatus,
      dimensionRegistryVersion: dimensionRegistryVersion,
      personaProfileVersion: personaProfileVersion,
      personaScoringVersion: personaScoringVersion,
      evidenceSufficiencyMode: PersonaEvidenceSufficiencyMode.explicit,
    );
  }

  /// Offline compatibility adapter for synthetic inputs that only have
  /// evidence counts (pre-P2A-2A). Uses `min(1, evidenceCount / 3)`.
  ///
  /// Do not use for canonical trait→persona handoff.
  factory PersonaScoringInput.withDeprecatedGlobalEvidenceDenominator({
    required Map<String, double> dimensionScores,
    required Map<String, int> dimensionEvidenceCounts,
    Map<String, double> dimensionReliability = const {},
    Set<String> missingDimensions = const {},
    Map<String, String> assessmentStatuses = const {},
    ResponseValidityStatus responseValidityStatus =
        ResponseValidityStatus.unknown,
    required String dimensionRegistryVersion,
    required String personaProfileVersion,
    required String personaScoringVersion,
  }) {
    return PersonaScoringInput(
      dimensionScores: Map<String, double>.from(dimensionScores),
      dimensionEvidenceCounts: Map<String, int>.from(dimensionEvidenceCounts),
      dimensionEvidenceSufficiency: const {},
      dimensionReliability: Map<String, double>.from(dimensionReliability),
      missingDimensions: Set<String>.from(missingDimensions),
      assessmentStatuses: Map<String, String>.from(assessmentStatuses),
      responseValidityStatus: responseValidityStatus,
      dimensionRegistryVersion: dimensionRegistryVersion,
      personaProfileVersion: personaProfileVersion,
      personaScoringVersion: personaScoringVersion,
      evidenceSufficiencyMode:
          PersonaEvidenceSufficiencyMode.deprecatedGlobalDenominator,
    );
  }
}
