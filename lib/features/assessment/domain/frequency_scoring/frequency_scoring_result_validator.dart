import '../frequency_bank/frequency_canonical_dimensions.dart';
import 'frequency_scoring_contract.dart';
import 'frequency_scoring_models.dart';

class FrequencyScoringResultValidation {
  const FrequencyScoringResultValidation({
    required this.ok,
    required this.issues,
  });

  final bool ok;
  final List<String> issues;
}

/// Hard validator for [FrequencyCanonicalScoringResult].
class FrequencyScoringResultValidator {
  static FrequencyScoringResultValidation validate(
    FrequencyCanonicalScoringResult result,
  ) {
    final issues = <String>[];
    void fail(String code) => issues.add(code);

    if (result.schemaVersion != FrequencyScoringContract.schemaVersion) {
      fail('schema_version');
    }
    if (result.scoringPolicyVersion !=
        FrequencyScoringContract.scoringPolicyVersion) {
      fail('scoring_policy_version');
    }
    if (result.dimensionScores.length !=
        FrequencyCanonicalDimensions.all.length) {
      fail('dimension_count');
    }
    for (var i = 0; i < result.dimensionScores.length; i++) {
      final d = result.dimensionScores[i];
      if (i < FrequencyCanonicalDimensions.all.length &&
          d.dimensionId != FrequencyCanonicalDimensions.all[i]) {
        fail('dimension_order');
      }
      if (!FrequencyCanonicalDimensions.isCanonical(d.dimensionId)) {
        fail('unknown_dimension');
      }
      if (d.evidenceStatus == FrequencyDimensionEvidenceStatus.measured) {
        final z = d.rawSignedEvidence;
        final x = d.normalizedScore;
        if (z == null || x == null) fail('measured_null_scores');
        if (z != null && (z < -1.0 || z > 1.0)) fail('z_range');
        if (x != null && (x < 0.0 || x > 1.0)) fail('x_range');
        if (d.evidenceCount <= 0) fail('evidence_count');
        if (z != null && x != null) {
          final expected = (z + 1.0) / 2.0;
          if ((x - expected).abs() > 1e-9) fail('x_formula');
        }
      } else {
        if (d.rawSignedEvidence != null || d.normalizedScore != null) {
          fail('insufficient_must_be_null');
        }
        if (d.evidenceCount != 0) fail('insufficient_evidence_count');
      }
      if (d.calibrationStatus != FrequencyCalibrationStatus.uncalibrated) {
        fail('calibration');
      }
      if (d.reliabilityStatus != FrequencyReliabilityStatus.notCalibrated) {
        fail('reliability');
      }
    }
    if (result.rviRuntimeGate != FrequencyScoringContract.rviRuntimeGate) {
      fail('rvi_gate');
    }
    return FrequencyScoringResultValidation(
      ok: issues.isEmpty,
      issues: issues,
    );
  }
}
