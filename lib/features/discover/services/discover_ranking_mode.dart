/// Discover ranking cutover switch.
///
/// Active production mode is [structuralL2V1]. [legacyV1] keeps
/// [CompatibilityScoring] as a rollback-only path.
enum DiscoverRankingMode {
  legacyV1('legacy_v1'),
  structuralL2V1('structural_l2_v1');

  const DiscoverRankingMode(this.wireValue);

  final String wireValue;

  /// App default. Rollback by constructing DiscoverService with [legacyV1].
  static const DiscoverRankingMode active = structuralL2V1;

  bool get usesTrustedStructuralL2 => this == structuralL2V1;

  bool get usesLegacyCompatibilityScoring => this == legacyV1;

  static DiscoverRankingMode? fromWire(String? raw) {
    switch (raw) {
      case 'legacy_v1':
        return legacyV1;
      case 'structural_l2_v1':
        return structuralL2V1;
      default:
        return null;
    }
  }
}
