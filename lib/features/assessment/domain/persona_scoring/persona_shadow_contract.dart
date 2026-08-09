/// Frozen Persona shadow-distance contracts (P2C-3A-2).
///
/// Offline / shadow only. Not production reveal. Not Firestore-wired.
class PersonaShadowContract {
  PersonaShadowContract._();

  static const String scoringVersion = 'persona_20d_shadow_distance_v1';
  static const String qualityPolicyVersion = 'persona_shadow_evidence_only_v1';
  static const String configAssetPath =
      'assets/data/persona_shadow_scoring_config_v1.json';
  static const String prototypeAssetPath =
      'assets/data/persona_profiles_v2_20d.json';

  static const double iqGroupWeight = 0.15;
  static const double eqGroupWeight = 0.30;
  static const double frequencyGroupWeight = 0.55;

  static const double alpha = 0.65;
  static const double gammaA = 0.10;
  static const double gammaOmega = 0.05;

  /// Core weight = 1 - γ_A - γ_Ω.
  static const double coreWeight = 0.85;

  static const Map<String, int> evidenceNMin = {
    'logical_reasoning': 7,
    'pattern_reasoning': 6,
    'verbal_reasoning': 6,
    'spatial_reasoning': 6,
    'empathy': 3,
    'perspective_taking': 3,
    'self_awareness': 3,
    'emotion_regulation': 3,
    'emotional_openness': 3,
    'boundary_setting': 3,
    'assertiveness': 3,
    'conflict_approach': 3,
    'repair_orientation': 3,
    'social_awareness': 3,
    'depth_preference': 5,
    'social_energy': 5,
    'spontaneity': 5,
    'stability': 5,
    'disclosure_pace': 5,
    'communication_pace': 5,
  };
}
