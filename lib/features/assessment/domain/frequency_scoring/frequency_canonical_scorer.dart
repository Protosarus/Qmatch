import '../frequency_bank/frequency_bank.dart';
import 'frequency_scoring_contract.dart';
import 'frequency_scoring_models.dart';
import 'frequency_scoring_result_validator.dart';

/// Deterministic Firebase-independent canonical Frequency 6D scorer.
///
/// Policy: [FrequencyScoringContract.scoringPolicyVersion] with a_ij = 1.
/// Does not produce overall Frequency, percentiles, reliability, RVI gates,
/// Persona, matching, or quantum outputs.
///
/// Explicit signed `dimension_deltas` are scoring truth. `reverse_scored`
/// metadata must never double-invert already-signed deltas.
class CanonicalFrequencyScorer {
  const CanonicalFrequencyScorer({
    this.requireRuntimeCandidateBlueprint = false,
  });

  /// Runtime-candidate blueprint is optional so math fixtures and future
  /// partial banks can exercise the scorer offline. Production R2 should
  /// pass a bank that already passed the full blueprint validator.
  final bool requireRuntimeCandidateBlueprint;

  FrequencyScoringOutcome score({
    required FrequencyCanonicalBankDocument bank,
    required List<FrequencyCanonicalResponse> responses,
    String scoringPolicyVersion = FrequencyScoringContract.scoringPolicyVersion,
    DateTime Function()? clock,
  }) {
    if (bank.schemaVersion != FrequencyBankContract.schemaVersion) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.incompatibleSchema,
        message: 'Incompatible bank schema',
      );
    }
    if (bank.scoringPolicyVersion !=
            FrequencyBankContract.scoringPolicyVersion ||
        scoringPolicyVersion != FrequencyScoringContract.scoringPolicyVersion) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.incompatiblePolicy,
        message: 'Incompatible scoring policy',
      );
    }

    final bankCheck = FrequencyCanonicalBankValidator(
      requireRuntimeCandidateBlueprint: requireRuntimeCandidateBlueprint,
    ).validate(bank);
    if (!bankCheck.ok) {
      return FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.bankInvalid,
        message: bankCheck.issues.join('; '),
      );
    }

    if (responses.length != bank.items.length) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.incompleteSession,
        message: 'Incomplete required session',
      );
    }

    final byId = bank.itemsById;
    final seen = <String>{};
    final deltasByDim = <String, List<double>>{
      for (final d in FrequencyCanonicalDimensions.all) d: <double>[],
    };

    for (final r in responses) {
      if (!seen.add(r.itemId)) {
        return FrequencyScoringOutcome.fail(
          code: FrequencyScoringFailureCode.duplicateAnswer,
          message: 'Duplicate answer for ${r.itemId}',
        );
      }
      final item = byId[r.itemId];
      if (item == null) {
        return FrequencyScoringOutcome.fail(
          code: FrequencyScoringFailureCode.unknownItem,
          message: 'Unknown item ${r.itemId}',
        );
      }
      final option = item.optionById(r.optionId);
      if (option == null) {
        return FrequencyScoringOutcome.fail(
          code: FrequencyScoringFailureCode.optionNotInItem,
          message: 'Option ${r.optionId} not in ${r.itemId}',
        );
      }
      // Quality / non-trait protocol items never contribute Frequency evidence.
      if (!item.traitScoring ||
          item.itemRole == FrequencyBankContract.itemRoleQuality) {
        continue;
      }
      for (final e in option.dimensionDeltas.entries) {
        if (!FrequencyCanonicalDimensions.isCanonical(e.key)) {
          return FrequencyScoringOutcome.fail(
            code: FrequencyScoringFailureCode.unknownDimension,
            message: 'Unknown dimension ${e.key}',
          );
        }
        if (e.value.isNaN ||
            e.value.isInfinite ||
            e.value < -1.0 ||
            e.value > 1.0) {
          return FrequencyScoringOutcome.fail(
            code: FrequencyScoringFailureCode.deltaOutOfRange,
            message: 'Delta out of range for ${r.itemId}:${e.key}',
          );
        }
        deltasByDim[e.key]!.add(e.value);
      }
    }

    if (seen.length != bank.items.length ||
        !bank.items.every((i) => seen.contains(i.itemId))) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.incompleteSession,
        message: 'Session does not cover full bank item set',
      );
    }

    final dimensionScores = <FrequencyDimensionScore>[];
    var allMeasured = true;
    for (final dim in FrequencyCanonicalDimensions.all) {
      final math =
          FrequencySignedEvidenceMath.meanSignedEvidence(deltasByDim[dim]!);
      if (math == null) {
        allMeasured = false;
        dimensionScores.add(
          FrequencyDimensionScore(
            dimensionId: dim,
            evidenceStatus:
                FrequencyDimensionEvidenceStatus.insufficientEvidence,
            evidenceCount: 0,
            rawSignedEvidence: null,
            normalizedScore: null,
            calibrationStatus: FrequencyCalibrationStatus.uncalibrated,
            reliabilityStatus: FrequencyReliabilityStatus.notCalibrated,
          ),
        );
      } else {
        dimensionScores.add(
          FrequencyDimensionScore(
            dimensionId: dim,
            evidenceStatus: FrequencyDimensionEvidenceStatus.measured,
            evidenceCount: math.n,
            rawSignedEvidence: math.z,
            normalizedScore: math.x,
            calibrationStatus: FrequencyCalibrationStatus.uncalibrated,
            reliabilityStatus: FrequencyReliabilityStatus.notCalibrated,
          ),
        );
      }
    }

    if (!allMeasured) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.missingDimensionCoverage,
        message: 'Missing required canonical dimension coverage',
      );
    }

    final now = (clock ?? DateTime.now)().toUtc().toIso8601String();
    final result = FrequencyCanonicalScoringResult(
      schemaVersion: FrequencyScoringContract.schemaVersion,
      bankVersion: bank.bankVersion,
      bankLocale: bank.locale,
      scoringPolicyVersion: FrequencyScoringContract.scoringPolicyVersion,
      dimensionScores: dimensionScores,
      totalAnswered: responses.length,
      createdAt: now,
      calibrationStatus: FrequencyCalibrationStatus.uncalibrated,
      reliabilityStatus: FrequencyReliabilityStatus.notCalibrated,
      rviRuntimeGate: FrequencyScoringContract.rviRuntimeGate,
      structuralFlags: const FrequencyScoringStructuralFlags(
        completeSession: true,
        canonicalBankValid: true,
        allDimensionsMeasured: true,
      ),
    );

    final check = FrequencyScoringResultValidator.validate(result);
    if (!check.ok) {
      return FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.resultInvalid,
        message: check.issues.join('; '),
      );
    }
    return FrequencyScoringOutcome.ok(result);
  }

  /// Scores a single dimension from explicit deltas without requiring a full
  /// bank session — used for insufficient-evidence unit proofs.
  static FrequencyDimensionScore scoreDimensionFromDeltas({
    required String dimensionId,
    required Iterable<double> deltas,
  }) {
    if (!FrequencyCanonicalDimensions.isCanonical(dimensionId)) {
      throw ArgumentError('unknown dimension $dimensionId');
    }
    final math = FrequencySignedEvidenceMath.meanSignedEvidence(deltas);
    if (math == null) {
      return FrequencyDimensionScore(
        dimensionId: dimensionId,
        evidenceStatus: FrequencyDimensionEvidenceStatus.insufficientEvidence,
        evidenceCount: 0,
        rawSignedEvidence: null,
        normalizedScore: null,
        calibrationStatus: FrequencyCalibrationStatus.uncalibrated,
        reliabilityStatus: FrequencyReliabilityStatus.notCalibrated,
      );
    }
    return FrequencyDimensionScore(
      dimensionId: dimensionId,
      evidenceStatus: FrequencyDimensionEvidenceStatus.measured,
      evidenceCount: math.n,
      rawSignedEvidence: math.z,
      normalizedScore: math.x,
      calibrationStatus: FrequencyCalibrationStatus.uncalibrated,
      reliabilityStatus: FrequencyReliabilityStatus.notCalibrated,
    );
  }
}
