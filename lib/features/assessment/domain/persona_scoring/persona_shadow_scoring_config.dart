import 'persona_shadow_contract.dart';

/// Versioned shadow scoring config (from persona_shadow_scoring_config_v1.json).
class PersonaShadowScoringConfig {
  const PersonaShadowScoringConfig({
    required this.configVersion,
    required this.scoringVersion,
    required this.qualityPolicyVersion,
    required this.personaProfileVersion,
    required this.dimensionRegistryVersion,
    required this.status,
    required this.iqWeight,
    required this.eqWeight,
    required this.frequencyWeight,
    required this.levelDistanceWeight,
    required this.shapeDistanceWeight,
    required this.antiTraitPenaltyWeight,
    required this.minimumEvidencePenaltyWeight,
    required this.evidenceNMin,
    required this.numericalEpsilon,
    required this.deterministicTieBreakPolicy,
    required this.alphaStatus,
    required this.antiTraitPolicy,
    required this.shadowQualityPolicy,
    required this.notes,
  });

  final String configVersion;
  final String scoringVersion;
  final String qualityPolicyVersion;
  final String personaProfileVersion;
  final String dimensionRegistryVersion;
  final String status;
  final double iqWeight;
  final double eqWeight;
  final double frequencyWeight;
  final double levelDistanceWeight;
  final double shapeDistanceWeight;
  final double antiTraitPenaltyWeight;
  final double minimumEvidencePenaltyWeight;
  final Map<String, int> evidenceNMin;
  final double numericalEpsilon;
  final String deterministicTieBreakPolicy;
  final String alphaStatus;
  final String antiTraitPolicy;
  final String shadowQualityPolicy;
  final Map<String, Object?> notes;

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

  int nMin(String dimensionId) {
    final v = evidenceNMin[dimensionId];
    if (v == null) {
      throw StateError('Missing n_min for $dimensionId');
    }
    return v;
  }

  /// Validates frozen Core Engine shadow coefficients.
  void assertCanonicalShadowCoefficients() {
    if ((iqWeight - PersonaShadowContract.iqGroupWeight).abs() > 1e-12 ||
        (eqWeight - PersonaShadowContract.eqGroupWeight).abs() > 1e-12 ||
        (frequencyWeight - PersonaShadowContract.frequencyGroupWeight).abs() >
            1e-12) {
      throw StateError('Shadow group weights must be 0.15/0.30/0.55');
    }
    if ((levelDistanceWeight - PersonaShadowContract.alpha).abs() > 1e-12) {
      throw StateError('Shadow alpha must be 0.65');
    }
    if ((antiTraitPenaltyWeight - PersonaShadowContract.gammaA).abs() > 1e-12 ||
        (minimumEvidencePenaltyWeight - PersonaShadowContract.gammaOmega)
                .abs() >
            1e-12) {
      throw StateError('Shadow gamma must be γ_A=0.10 γ_Ω=0.05');
    }
    // Guard against older additive policy values.
    if ((antiTraitPenaltyWeight - 0.12).abs() < 1e-12 ||
        (minimumEvidencePenaltyWeight - 0.18).abs() < 1e-12) {
      throw StateError('Old 0.12/0.18 penalty policy must not be active');
    }
  }
}
