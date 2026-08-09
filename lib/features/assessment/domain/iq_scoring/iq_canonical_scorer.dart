import '../iq_bank/iq_canonical_dimensions.dart';
import '../iq_bank/iq_recovered_bank_document.dart';
import '../iq_session/iq_persisted_session_state.dart';
import '../iq_session/iq_session_contract.dart';
import '../iq_session/iq_session_persistence_repository.dart';
import 'iq_scoring_contract.dart';
import 'iq_scoring_models.dart';
import 'iq_scoring_result_validator.dart';

/// Canonical 4D uncalibrated accuracy scorer (P2C-2A-4).
///
/// Correctness = selectedOptionId == bank correct_option_id.
/// Does not produce IQ / percentile / reliability numbers.
/// Not wired to IQTestScreen, Firestore, or live trait-scoring services.
class IqCanonicalScorer {
  const IqCanonicalScorer();

  IqScoringOutcome scoreCompletedSession({
    required IqPersistedSessionState session,
    required IqRecoveredBankDocument bank,
    required String ownerUid,
    DateTime Function()? clock,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const IqScoringOutcome.fail(
        code: IqScoringFailureCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }

    if (!session.status.isScoreable) {
      if (session.status == IqPersistedSessionStatus.inProgress &&
          session.answers.length < IqSessionContract.sessionItemCount) {
        return const IqScoringOutcome.fail(
          code: IqScoringFailureCode.sessionIncomplete,
          message: 'Session incomplete',
        );
      }
      return IqScoringOutcome.fail(
        code: IqScoringFailureCode.sessionNotCompleted,
        message: 'Session status is ${session.status.wireValue}',
      );
    }

    final validated = IqPersistedSessionValidator.validate(
      state: session,
      bank: bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return IqScoringOutcome.fail(
        code: _mapLoadCode(validated.code),
        message: validated.message,
      );
    }
    final state = validated.state!;

    if (state.itemPlans.length != IqSessionContract.sessionItemCount ||
        state.answers.length != IqSessionContract.sessionItemCount) {
      return const IqScoringOutcome.fail(
        code: IqScoringFailureCode.sessionIncomplete,
        message: 'Completed session must have 25 answers',
      );
    }

    final byId = {for (final i in bank.items) i.id: i};
    final answersByItem = state.answersByItemId;

    final correctByDim = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final incorrectByDim = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final answeredByDim = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };

    for (final plan in state.itemPlans) {
      final answer = answersByItem[plan.itemId];
      if (answer == null) {
        return const IqScoringOutcome.fail(
          code: IqScoringFailureCode.sessionIncomplete,
          message: 'Missing answer for plan item',
        );
      }
      final bankItem = byId[plan.itemId];
      if (bankItem == null) {
        return const IqScoringOutcome.fail(
          code: IqScoringFailureCode.corrupt,
          message: 'Plan item missing from bank',
        );
      }
      // Dimension from canonical bank field (not ID prefix).
      final dim = bankItem.dimension;
      if (!IqCanonicalDimensions.isCanonical(dim) ||
          IqCanonicalDimensions.isRetired(dim)) {
        return const IqScoringOutcome.fail(
          code: IqScoringFailureCode.corrupt,
          message: 'Non-canonical or retired dimension',
        );
      }
      if (plan.dimension != dim) {
        return const IqScoringOutcome.fail(
          code: IqScoringFailureCode.corrupt,
          message: 'Plan dimension mismatch vs bank',
        );
      }

      final isCorrect = answer.selectedOptionId == bankItem.correctOptionId;
      answeredByDim[dim] = (answeredByDim[dim] ?? 0) + 1;
      if (isCorrect) {
        correctByDim[dim] = (correctByDim[dim] ?? 0) + 1;
      } else {
        incorrectByDim[dim] = (incorrectByDim[dim] ?? 0) + 1;
      }
    }

    for (final e in IqSessionContract.dimensionQuotas.entries) {
      if (answeredByDim[e.key] != e.value) {
        return IqScoringOutcome.fail(
          code: IqScoringFailureCode.corrupt,
          message: 'Quota mismatch for ${e.key}',
        );
      }
    }

    final dimensionScores = <IqDimensionScore>[];
    for (final dim in IqCanonicalDimensions.all) {
      final itemCount = IqSessionContract.dimensionQuotas[dim]!;
      final correct = correctByDim[dim]!;
      final incorrect = incorrectByDim[dim]!;
      final answered = answeredByDim[dim]!;
      final raw = itemCount == 0 ? 0.0 : correct / itemCount;
      dimensionScores.add(
        IqDimensionScore(
          dimension: dim,
          correctCount: correct,
          incorrectCount: incorrect,
          answeredCount: answered,
          itemCount: itemCount,
          rawAccuracy: raw,
          provisionalScore: raw, // iq_4d_uncalibrated_accuracy_v1
          calibrationStatus: IqCalibrationStatus.uncalibrated,
        ),
      );
    }

    final now = (clock ?? DateTime.now)().toUtc().toIso8601String();
    final result = IqCanonicalScoringResult(
      schemaVersion: IqScoringContract.schemaVersion,
      bankVersion: state.bankVersion,
      bankLocale: state.bankLocale,
      selectionPolicyVersion: state.selectionPolicyVersion,
      scoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
      sessionId: state.sessionId,
      dimensionScores: dimensionScores,
      totalAnswered: state.answers.length,
      createdAt: now,
      calibrationStatus: IqCalibrationStatus.uncalibrated,
      structuralFlags: const IqScoringStructuralFlags(
        completeSession: true,
        quotaValid: true,
        canonicalBankValid: true,
      ),
    );

    final resultCheck = IqScoringResultValidator.validate(result);
    if (!resultCheck.ok) {
      return IqScoringOutcome.fail(
        code: IqScoringFailureCode.resultInvalid,
        message: resultCheck.issues.join('; '),
      );
    }

    return IqScoringOutcome.ok(result);
  }

  static IqScoringFailureCode _mapLoadCode(IqSessionLoadCode code) {
    switch (code) {
      case IqSessionLoadCode.incompatibleBank:
        return IqScoringFailureCode.incompatibleBank;
      case IqSessionLoadCode.incompatiblePolicy:
        return IqScoringFailureCode.incompatiblePolicy;
      case IqSessionLoadCode.incompatibleSchema:
        return IqScoringFailureCode.incompatibleSchema;
      case IqSessionLoadCode.corrupt:
        return IqScoringFailureCode.corrupt;
      case IqSessionLoadCode.ownerMismatch:
        return IqScoringFailureCode.ownerMismatch;
      case IqSessionLoadCode.ownerUnavailable:
        return IqScoringFailureCode.ownerUnavailable;
      case IqSessionLoadCode.notFound:
      case IqSessionLoadCode.loaded:
        return IqScoringFailureCode.validationFailed;
    }
  }
}
