/// Distance-only Persona handoff output (narrative prototype assignment).
///
/// Explicit non-goals: percentages, confidence, affinity, temperature, RVI,
/// quantum, Matching/Discover ranking keys.
class PersonaRuntimeHandoffResult {
  const PersonaRuntimeHandoffResult({
    required this.primaryPersonaId,
    required this.secondaryPersonaId,
    required this.rawDeltaD,
    required this.scoringVersion,
    required this.configVersion,
    required this.prototypeVersion,
    required this.policyVersion,
  });

  /// Nearest persona (argmin distance).
  final String primaryPersonaId;

  /// Second-nearest persona.
  final String secondaryPersonaId;

  /// Raw top-2 distance margin Δ_D ≥ 0 (telemetry only — not a % / confidence).
  final double rawDeltaD;

  final String scoringVersion;
  final String configVersion;
  final String prototypeVersion;
  final String policyVersion;

  /// Wire map for future persistence. Omits % / confidence / affinity fields.
  Map<String, dynamic> toWireMap() => {
        'primary_persona_id': primaryPersonaId,
        'secondary_persona_id': secondaryPersonaId,
        'raw_delta_d': rawDeltaD,
        'scoring_version': scoringVersion,
        'config_version': configVersion,
        'prototype_version': prototypeVersion,
        'policy_version': policyVersion,
        'shadow_only': true,
      };
}
