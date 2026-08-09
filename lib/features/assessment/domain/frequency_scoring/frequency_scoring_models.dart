import '../frequency_bank/frequency_canonical_dimensions.dart';
import 'frequency_scoring_contract.dart';

/// Pure uncalibrated signed-evidence math (a_ij = 1).
///
/// z_j = mean(explicit deltas); x_j = (z_j + 1) / 2.
/// Missing / empty evidence is NOT treated as z=0 or x=0.5.
class FrequencySignedEvidenceMath {
  FrequencySignedEvidenceMath._();

  /// Returns null when [deltas] is empty (insufficient evidence).
  static ({double z, double x, int n})? meanSignedEvidence(
    Iterable<double> deltas,
  ) {
    final list = <double>[];
    for (final d in deltas) {
      if (d.isNaN || d.isInfinite) {
        throw ArgumentError('delta must be finite');
      }
      if (d < -1.0 || d > 1.0) {
        throw ArgumentError('delta out of [-1,1]: $d');
      }
      list.add(d);
    }
    if (list.isEmpty) return null;
    final z = list.reduce((a, b) => a + b) / list.length;
    final x = (z + 1.0) / 2.0;
    return (z: z, x: x, n: list.length);
  }
}

/// Per-dimension Frequency result.
class FrequencyDimensionScore {
  const FrequencyDimensionScore({
    required this.dimensionId,
    required this.evidenceStatus,
    required this.evidenceCount,
    required this.calibrationStatus,
    required this.reliabilityStatus,
    this.rawSignedEvidence,
    this.normalizedScore,
  });

  final String dimensionId;
  final FrequencyDimensionEvidenceStatus evidenceStatus;
  final int evidenceCount;
  final FrequencyCalibrationStatus calibrationStatus;
  final FrequencyReliabilityStatus reliabilityStatus;

  /// z_j ∈ [-1,1] when measured; null when insufficient.
  final double? rawSignedEvidence;

  /// x_j ∈ [0,1] when measured; null when insufficient.
  final double? normalizedScore;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'evidence_status': evidenceStatus.wireValue,
        'evidence_count': evidenceCount,
        'raw_signed_evidence': rawSignedEvidence,
        'normalized_score': normalizedScore,
        'calibration_status': calibrationStatus.wireValue,
        'reliability_status': reliabilityStatus.wireValue,
      };
}

class FrequencyScoringStructuralFlags {
  const FrequencyScoringStructuralFlags({
    required this.completeSession,
    required this.canonicalBankValid,
    required this.allDimensionsMeasured,
  });

  final bool completeSession;
  final bool canonicalBankValid;
  final bool allDimensionsMeasured;

  Map<String, dynamic> toJson() => {
        'complete_session': completeSession,
        'canonical_bank_valid': canonicalBankValid,
        'all_dimensions_measured': allDimensionsMeasured,
      };
}

/// Canonical 6D Frequency scoring result — no overall Frequency / percentile.
class FrequencyCanonicalScoringResult {
  const FrequencyCanonicalScoringResult({
    required this.schemaVersion,
    required this.bankVersion,
    required this.bankLocale,
    required this.scoringPolicyVersion,
    required this.dimensionScores,
    required this.totalAnswered,
    required this.createdAt,
    required this.calibrationStatus,
    required this.reliabilityStatus,
    required this.rviRuntimeGate,
    required this.structuralFlags,
  });

  final String schemaVersion;
  final String bankVersion;
  final String bankLocale;
  final String scoringPolicyVersion;
  final List<FrequencyDimensionScore> dimensionScores;
  final int totalAnswered;
  final String createdAt;
  final FrequencyCalibrationStatus calibrationStatus;
  final FrequencyReliabilityStatus reliabilityStatus;
  final String rviRuntimeGate;
  final FrequencyScoringStructuralFlags structuralFlags;

  FrequencyDimensionScore scoreFor(String dimensionId) =>
      dimensionScores.firstWhere((d) => d.dimensionId == dimensionId);

  Map<String, dynamic> toJson() {
    final byDim = {for (final d in dimensionScores) d.dimensionId: d};
    return {
      'schema_version': schemaVersion,
      'bank_version': bankVersion,
      'bank_locale': bankLocale,
      'scoring_policy_version': scoringPolicyVersion,
      'dimension_scores': [
        for (final id in FrequencyCanonicalDimensions.all)
          if (byDim.containsKey(id)) byDim[id]!.toJson(),
      ],
      'total_answered': totalAnswered,
      'created_at': createdAt,
      'calibration_status': calibrationStatus.wireValue,
      'reliability_status': reliabilityStatus.wireValue,
      'rvi_runtime_gate': rviRuntimeGate,
      'structural_flags': structuralFlags.toJson(),
      // Explicit absences — never fabricate:
      'overall_frequency_score': null,
      'percentile': null,
      'correct_count': null,
      'reliability_estimate': null,
      'cronbach_alpha': null,
    };
  }
}

enum FrequencyScoringFailureCode {
  incompleteSession,
  duplicateAnswer,
  unknownItem,
  unknownOption,
  optionNotInItem,
  deltaOutOfRange,
  unknownDimension,
  missingDimensionCoverage,
  incompatibleBank,
  incompatiblePolicy,
  incompatibleSchema,
  bankInvalid,
  resultInvalid,
  validationFailed,
}

class FrequencyScoringOutcome {
  const FrequencyScoringOutcome._({
    required this.ok,
    this.result,
    this.code,
    this.message,
  });

  const FrequencyScoringOutcome.ok(FrequencyCanonicalScoringResult result)
      : this._(ok: true, result: result);

  const FrequencyScoringOutcome.fail({
    required FrequencyScoringFailureCode code,
    required String message,
  }) : this._(ok: false, code: code, message: message);

  final bool ok;
  final FrequencyCanonicalScoringResult? result;
  final FrequencyScoringFailureCode? code;
  final String? message;
}
