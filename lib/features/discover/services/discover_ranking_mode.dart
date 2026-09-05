/// Discover ranking cutover switch.
///
/// Active production mode is [compatibilityFusionV2]. [structuralL2V1]
/// remains a rollback-only IQ+EQ distance order. [legacyV1] keeps
/// [CompatibilityScoring] as a last-resort order path. All modes
/// require trusted callable `candidate_uids` membership first.
enum DiscoverRankingMode {
  legacyV1('legacy_v1'),
  structuralL2V1('structural_l2_v1'),
  compatibilityFusionV2('compatibility_fusion_v2');

  const DiscoverRankingMode(this.wireValue);

  final String wireValue;

  /// App default. Live order is Frequency V2 fusion with structural fallback.
  static const DiscoverRankingMode active = compatibilityFusionV2;

  bool get usesTrustedStructuralL2 =>
      this == structuralL2V1 || this == compatibilityFusionV2;

  bool get usesCompatibilityFusionV2 => this == compatibilityFusionV2;

  bool get usesLegacyCompatibilityScoring => this == legacyV1;

  static DiscoverRankingMode? fromWire(String? raw) {
    switch (raw) {
      case 'legacy_v1':
        return legacyV1;
      case 'structural_l2_v1':
        return structuralL2V1;
      case 'compatibility_fusion_v2':
        return compatibilityFusionV2;
      default:
        return null;
    }
  }
}
