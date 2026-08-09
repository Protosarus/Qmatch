import '../eq_bank/eq_bank.dart';
import 'eq_scoring_contract.dart';
import 'eq_scoring_models.dart';
import 'eq_scoring_result_validator.dart';

/// Deterministic Firebase-independent canonical EQ 10D scorer.
///
/// Policy: [EqScoringContract.scoringPolicyVersion] with a_ij = 1.
/// Does not produce overall EQ, percentiles, reliability, RVI gates,
/// Persona, matching, or quantum outputs.
class CanonicalEqScorer {
  const CanonicalEqScorer();

  EqScoringOutcome score({
    required EqCanonicalBankDocument bank,
    required List<EqCanonicalResponse> responses,
    String scoringPolicyVersion = EqScoringContract.scoringPolicyVersion,
    DateTime Function()? clock,
  }) {
    if (bank.schemaVersion != EqBankContract.schemaVersion) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.incompatibleSchema,
        message: 'Incompatible bank schema',
      );
    }
    if (bank.scoringPolicyVersion != EqBankContract.scoringPolicyVersion ||
        scoringPolicyVersion != EqScoringContract.scoringPolicyVersion) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.incompatiblePolicy,
        message: 'Incompatible scoring policy',
      );
    }

    final bankCheck = const EqCanonicalBankValidator().validate(bank);
    if (!bankCheck.ok) {
      return EqScoringOutcome.fail(
        code: EqScoringFailureCode.bankInvalid,
        message: bankCheck.issues.join('; '),
      );
    }

    if (responses.length != bank.items.length) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.incompleteSession,
        message: 'Incomplete required session',
      );
    }

    final byId = bank.itemsById;
    final seen = <String>{};
    final deltasByDim = <String, List<double>>{
      for (final d in EqCanonicalDimensions.all) d: <double>[],
    };

    for (final r in responses) {
      if (!seen.add(r.itemId)) {
        return EqScoringOutcome.fail(
          code: EqScoringFailureCode.duplicateAnswer,
          message: 'Duplicate answer for ${r.itemId}',
        );
      }
      final item = byId[r.itemId];
      if (item == null) {
        return EqScoringOutcome.fail(
          code: EqScoringFailureCode.unknownItem,
          message: 'Unknown item ${r.itemId}',
        );
      }
      final option = item.optionById(r.optionId);
      if (option == null) {
        return EqScoringOutcome.fail(
          code: EqScoringFailureCode.optionNotInItem,
          message: 'Option ${r.optionId} not in ${r.itemId}',
        );
      }
      for (final e in option.dimensionDeltas.entries) {
        if (!EqCanonicalDimensions.isCanonical(e.key)) {
          return EqScoringOutcome.fail(
            code: EqScoringFailureCode.unknownDimension,
            message: 'Unknown dimension ${e.key}',
          );
        }
        if (e.value.isNaN ||
            e.value.isInfinite ||
            e.value < -1.0 ||
            e.value > 1.0) {
          return EqScoringOutcome.fail(
            code: EqScoringFailureCode.deltaOutOfRange,
            message: 'Delta out of range for ${r.itemId}:${e.key}',
          );
        }
        deltasByDim[e.key]!.add(e.value);
      }
    }

    // Every bank item must be answered exactly once.
    if (seen.length != bank.items.length ||
        !bank.items.every((i) => seen.contains(i.itemId))) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.incompleteSession,
        message: 'Session does not cover full bank item set',
      );
    }

    final dimensionScores = <EqDimensionScore>[];
    var allMeasured = true;
    for (final dim in EqCanonicalDimensions.all) {
      final math = EqSignedEvidenceMath.meanSignedEvidence(deltasByDim[dim]!);
      if (math == null) {
        allMeasured = false;
        dimensionScores.add(
          EqDimensionScore(
            dimensionId: dim,
            evidenceStatus: EqDimensionEvidenceStatus.insufficientEvidence,
            evidenceCount: 0,
            rawSignedEvidence: null,
            normalizedScore: null,
            calibrationStatus: EqCalibrationStatus.uncalibrated,
            reliabilityStatus: EqReliabilityStatus.notCalibrated,
          ),
        );
      } else {
        dimensionScores.add(
          EqDimensionScore(
            dimensionId: dim,
            evidenceStatus: EqDimensionEvidenceStatus.measured,
            evidenceCount: math.n,
            rawSignedEvidence: math.z,
            normalizedScore: math.x,
            calibrationStatus: EqCalibrationStatus.uncalibrated,
            reliabilityStatus: EqReliabilityStatus.notCalibrated,
          ),
        );
      }
    }

    if (!allMeasured) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.missingDimensionCoverage,
        message: 'Missing required canonical dimension coverage',
      );
    }

    final now = (clock ?? DateTime.now)().toUtc().toIso8601String();
    final result = EqCanonicalScoringResult(
      schemaVersion: EqScoringContract.schemaVersion,
      bankVersion: bank.bankVersion,
      bankLocale: bank.locale,
      scoringPolicyVersion: EqScoringContract.scoringPolicyVersion,
      dimensionScores: dimensionScores,
      totalAnswered: responses.length,
      createdAt: now,
      calibrationStatus: EqCalibrationStatus.uncalibrated,
      reliabilityStatus: EqReliabilityStatus.notCalibrated,
      rviRuntimeGate: EqScoringContract.rviRuntimeGate,
      structuralFlags: const EqScoringStructuralFlags(
        completeSession: true,
        canonicalBankValid: true,
        allDimensionsMeasured: true,
      ),
    );

    final check = EqScoringResultValidator.validate(result);
    if (!check.ok) {
      return EqScoringOutcome.fail(
        code: EqScoringFailureCode.resultInvalid,
        message: check.issues.join('; '),
      );
    }
    return EqScoringOutcome.ok(result);
  }
}
