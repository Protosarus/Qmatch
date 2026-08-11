import 'persona_shadow_contract.dart';

/// Validates a persisted distance-only Persona doc for live reuse.
class PersonaRuntimeResultPolicy {
  PersonaRuntimeResultPolicy._();

  static const String assessmentType = 'persona';

  static const String scoringVersion = PersonaShadowContract.scoringVersion;
  static const String policyVersion =
      PersonaShadowContract.qualityPolicyVersion;
  static const String configVersion = 'persona_shadow_scoring_config_v1';
  static const String prototypeVersion = 'persona_profiles_v2_20d.0';

  /// True when the doc is a complete current-version distance-only result.
  static bool isCurrentValid(Map<String, dynamic>? doc) {
    if (doc == null) return false;
    final primary = doc['primary_persona_id']?.toString().trim() ?? '';
    final secondary = doc['secondary_persona_id']?.toString().trim() ?? '';
    if (primary.isEmpty || secondary.isEmpty || primary == secondary) {
      return false;
    }
    final delta = doc['raw_delta_d'];
    if (delta is! num || !delta.toDouble().isFinite || delta < 0) {
      return false;
    }
    if (doc['scoring_version']?.toString() != scoringVersion) return false;
    if (doc['config_version']?.toString() != configVersion) return false;
    if (doc['policy_version']?.toString() != policyVersion) return false;
    if (doc['prototype_version']?.toString() != prototypeVersion) {
      return false;
    }
    // Reject legacy affinity/confidence payloads even if versions match.
    if (doc.containsKey('confidence') ||
        doc.containsKey('confidence_score') ||
        doc.containsKey('primary_similarity') ||
        doc.containsKey('affinity')) {
      return false;
    }
    return true;
  }
}
