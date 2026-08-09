/// P2C-2A-4 canonical 4D IQ scoring contracts (offline / runtime-neutral).
///
/// Result is uncalibrated multidimensional reasoning performance — not IQ.
class IqScoringContract {
  IqScoringContract._();

  static const String schemaVersion = 'qmatch_iq_canonical_scoring_result_v1';

  /// Uncalibrated accuracy scorer: provisionalScore = rawAccuracy = correct/itemCount.
  /// No difficulty weighting, IRT, norms, or percentiles.
  static const String scoringPolicyVersion = 'iq_4d_uncalibrated_accuracy_v1';

  static const String calibrationStatus = 'uncalibrated';
}

/// Explicit calibration label — never imply population IQ.
enum IqCalibrationStatus {
  uncalibrated('uncalibrated');

  const IqCalibrationStatus(this.wireValue);
  final String wireValue;

  static IqCalibrationStatus fromWire(String? raw) {
    final v = raw ?? IqScoringContract.calibrationStatus;
    for (final e in IqCalibrationStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return IqCalibrationStatus.uncalibrated;
  }
}
