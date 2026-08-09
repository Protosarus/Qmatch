import 'dart:convert';

import 'persona_shadow_scoring_config.dart';

class PersonaShadowConfigParseException implements Exception {
  PersonaShadowConfigParseException(this.message);
  final String message;
  @override
  String toString() => 'PersonaShadowConfigParseException: $message';
}

class PersonaShadowConfigParser {
  PersonaShadowConfigParser._();

  static PersonaShadowScoringConfig parseJson(String jsonText) {
    final root = jsonDecode(jsonText);
    if (root is! Map) {
      throw PersonaShadowConfigParseException('Root must be object');
    }
    return parseMap(Map<String, dynamic>.from(root));
  }

  static PersonaShadowScoringConfig parseMap(Map<String, dynamic> j) {
    final gw = Map<String, dynamic>.from(j['group_weights'] as Map);
    final nMinRaw = Map<String, dynamic>.from(j['evidence_n_min'] as Map);
    final nMin = <String, int>{
      for (final e in nMinRaw.entries) e.key: (e.value as num).toInt(),
    };
    final notesRaw = j['notes'];
    final notes = notesRaw is Map
        ? Map<String, Object?>.from(notesRaw)
        : <String, Object?>{};

    final cfg = PersonaShadowScoringConfig(
      configVersion: j['config_version'] as String,
      scoringVersion: j['scoring_version'] as String,
      qualityPolicyVersion: j['quality_policy_version'] as String,
      personaProfileVersion: j['persona_profile_version'] as String,
      dimensionRegistryVersion: j['dimension_registry_version'] as String,
      status: j['status'] as String,
      iqWeight: (gw['iq'] as num).toDouble(),
      eqWeight: (gw['eq'] as num).toDouble(),
      frequencyWeight: (gw['frequency'] as num).toDouble(),
      levelDistanceWeight: (j['level_distance_weight'] as num).toDouble(),
      shapeDistanceWeight: (j['shape_distance_weight'] as num).toDouble(),
      antiTraitPenaltyWeight:
          (j['anti_trait_penalty_weight'] as num).toDouble(),
      minimumEvidencePenaltyWeight:
          (j['minimum_evidence_penalty_weight'] as num).toDouble(),
      evidenceNMin: Map.unmodifiable(nMin),
      numericalEpsilon: (j['numerical_epsilon'] as num).toDouble(),
      deterministicTieBreakPolicy:
          j['deterministic_tie_break_policy'] as String,
      alphaStatus: j['alpha_status'] as String,
      antiTraitPolicy: j['anti_trait_policy'] as String,
      shadowQualityPolicy: j['shadow_quality_policy'] as String,
      notes: Map.unmodifiable(notes),
    );
    cfg.assertCanonicalShadowCoefficients();
    return cfg;
  }
}
