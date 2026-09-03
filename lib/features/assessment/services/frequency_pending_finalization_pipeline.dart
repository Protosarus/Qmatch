import '../domain/frequency_scoring/frequency_scoring.dart';
import '../domain/frequency_session/frequency_session.dart';
import '../domain/profile/profile.dart';
import 'assessment_progress_service.dart';
import 'canonical_assessment_persistence.dart';
import 'canonical_assessment_profile_reconciler.dart';
import 'frequency_canonical_runtime_service.dart';
import 'frequency_finalize_callable_client.dart';

/// Ordered steps of the Frequency V1 pending-finalization pipeline.
enum FrequencyPendingPipelineStep {
  finalizeFrequency,
  score,
  persistAssessment,
  persistCanonical,
  markAssessmentFlowCompleted,
  markRemoteFinalized,
}

class FrequencyPendingPipelineResult {
  const FrequencyPendingPipelineResult({
    required this.navigateToPersona,
    required this.completedSteps,
    this.session,
    this.uiErrorCode,
    this.failureKind,
    this.finalize,
  });

  final bool navigateToPersona;
  final List<FrequencyPendingPipelineStep> completedSteps;
  final FrequencyPersistedSessionState? session;
  final String? uiErrorCode;
  final FrequencyFinalizeFailureKind? failureKind;
  final FrequencyFinalizeResult? finalize;
}

/// Single owner of:
/// finalizeFrequency → existing client Frequency V1 score →
/// assessments/frequency → canonical_v1 Frequency 6D fragment →
/// markAssessmentFlowCompleted → markRemoteFinalized.
///
/// `finalizeFrequency` success (including `frequency_completed=true`) does
/// **not** complete local persistence. Scoring is never a substitute for a
/// failed server finalize.
///
/// Release order: deploy backend `finalizeEq`, then `finalizeFrequency`,
/// before a Flutter release that requires this pipeline.
class FrequencyPendingFinalizationPipeline {
  FrequencyPendingFinalizationPipeline({
    required FrequencyFinalizeCallableClient finalizeClient,
    required Future<FrequencyScoringOutcome> Function(
      FrequencyPersistedSessionState session,
    ) scoreCompleted,
    required Future<void> Function({
      required FrequencyCanonicalScoringResult result,
      required FrequencyPersistedSessionState session,
      required String ownerUid,
      required String sessionId,
      required String locale,
      required String language,
      DateTime? startedAt,
    }) persistAssessment,
    required Future<void> Function({
      required FrequencyCanonicalScoringResult result,
      required String ownerUid,
      required String sessionId,
      required String locale,
      required String language,
    }) persistCanonical,
    required Future<void> Function() markAssessmentFlowCompleted,
    required Future<FrequencySessionWriteResult> Function(String sessionId)
        markRemoteFinalized,
    String? Function()? currentUid,
  })  : _finalizeClient = finalizeClient,
        _scoreCompleted = scoreCompleted,
        _persistAssessment = persistAssessment,
        _persistCanonical = persistCanonical,
        _markAssessmentFlowCompleted = markAssessmentFlowCompleted,
        _markRemoteFinalized = markRemoteFinalized,
        _currentUid = currentUid;

  factory FrequencyPendingFinalizationPipeline.live({
    FrequencyFinalizeCallableClient? finalizeClient,
    FrequencyCanonicalRuntimeService? runtime,
    CanonicalAssessmentPersistence? persistence,
    CanonicalAssessmentProfileReconciler? reconciler,
    AssessmentProgressService? progress,
  }) {
    final rt = runtime ?? FrequencyCanonicalRuntimeService();
    final persist = persistence ?? CanonicalAssessmentPersistence();
    final repair = reconciler ?? CanonicalAssessmentProfileReconciler();
    final prog = progress ?? AssessmentProgressService();
    return FrequencyPendingFinalizationPipeline(
      finalizeClient: finalizeClient ?? FrequencyFinalizeCallableClient(),
      scoreCompleted: rt.scoreCompleted,
      persistAssessment: ({
        required FrequencyCanonicalScoringResult result,
        required FrequencyPersistedSessionState session,
        required String ownerUid,
        required String sessionId,
        required String locale,
        required String language,
        DateTime? startedAt,
      }) async {
        final bank = await rt.loadBankForLocale(session.bankLocale);
        final qualitySignals =
            FrequencyCanonicalRuntimeService.deriveQualitySignals(
          bank: bank,
          session: session,
        );
        await persist.upsertCompletedAssessment(
          assessmentType: 'frequency',
          fields: persist.buildCanonicalFrequency6dPayload(
            result: result,
            sessionId: sessionId,
            locale: locale,
            languageUsed: language,
            qualitySignals: qualitySignals,
            startedAt: startedAt,
          ),
        );
      },
      persistCanonical: ({
        required FrequencyCanonicalScoringResult result,
        required String ownerUid,
        required String sessionId,
        required String locale,
        required String language,
      }) async {
        final iqEq = await repair.ensureIq4AndEq10(ownerUid: ownerUid);
        if (!iqEq.ok) {
          throw StateError(iqEq.message ?? iqEq.code.name);
        }
        final existingProfile =
            await persist.getCanonicalProfile(uid: ownerUid);
        final existingIq = repair.measuredOfModule(existingProfile, 'iq');
        final existingEq = repair.measuredOfModule(existingProfile, 'eq');
        final adapted = const FrequencyTo20dRuntimeAdapter().adapt(
          result: result,
          ownerUid: ownerUid,
          sessionId: sessionId,
          existingIqDimensions: existingIq,
          existingEqDimensions: existingEq,
        );
        if (!adapted.ok || adapted.fragment == null) {
          throw StateError(adapted.message ?? 'Frequency→20D adapt failed');
        }
        await persist.upsertCanonicalProfileFragment(adapted.fragment!);
      },
      markAssessmentFlowCompleted: prog.markAssessmentFlowCompleted,
      markRemoteFinalized: (sessionId) =>
          rt.markRemoteFinalized(sessionId: sessionId),
      currentUid: () => rt.currentUid,
    );
  }

  final FrequencyFinalizeCallableClient _finalizeClient;
  final Future<FrequencyScoringOutcome> Function(
    FrequencyPersistedSessionState session,
  ) _scoreCompleted;
  final Future<void> Function({
    required FrequencyCanonicalScoringResult result,
    required FrequencyPersistedSessionState session,
    required String ownerUid,
    required String sessionId,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) _persistAssessment;
  final Future<void> Function({
    required FrequencyCanonicalScoringResult result,
    required String ownerUid,
    required String sessionId,
    required String locale,
    required String language,
  }) _persistCanonical;
  final Future<void> Function() _markAssessmentFlowCompleted;
  final Future<FrequencySessionWriteResult> Function(String sessionId)
      _markRemoteFinalized;
  final String? Function()? _currentUid;

  /// Runs the full pending pipeline. Never deletes local session data.
  Future<FrequencyPendingPipelineResult> run({
    required FrequencyPersistedSessionState session,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) async {
    final steps = <FrequencyPendingPipelineStep>[];
    final ownerUid = (_currentUid?.call() ?? session.ownerUid).trim();
    final mapped = FrequencyFinalizeRequestMapper.mapLockedSession(
      session: session,
      ownerUid: ownerUid.isEmpty ? session.ownerUid : ownerUid,
    );
    if (!mapped.ok || mapped.payload == null) {
      return FrequencyPendingPipelineResult(
        navigateToPersona: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: mapped.code == 'owner_mismatch'
            ? FrequencyFinalizeFailureKind.accountInconsistency
            : FrequencyFinalizeFailureKind.nonRetryableSession,
      );
    }

    final FrequencyFinalizeResult finalizeResult;
    try {
      finalizeResult = await _finalizeClient.finalize(mapped.payload!);
      steps.add(FrequencyPendingPipelineStep.finalizeFrequency);
    } on FrequencyFinalizeException catch (e) {
      return FrequencyPendingPipelineResult(
        navigateToPersona: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: e.kind,
      );
    }

    final scored = await _scoreCompleted(session);
    if (!scored.ok || scored.result == null) {
      return FrequencyPendingPipelineResult(
        navigateToPersona: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: scored.code?.name ?? 'score_failed',
        failureKind: FrequencyFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(FrequencyPendingPipelineStep.score);

    try {
      await _persistAssessment(
        result: scored.result!,
        session: session,
        ownerUid: session.ownerUid,
        sessionId: session.sessionId,
        locale: locale,
        language: language,
        startedAt: startedAt,
      );
      steps.add(FrequencyPendingPipelineStep.persistAssessment);
      await _persistCanonical(
        result: scored.result!,
        ownerUid: session.ownerUid,
        sessionId: session.sessionId,
        locale: locale,
        language: language,
      );
      steps.add(FrequencyPendingPipelineStep.persistCanonical);
      await _markAssessmentFlowCompleted();
      steps.add(FrequencyPendingPipelineStep.markAssessmentFlowCompleted);
    } catch (_) {
      return FrequencyPendingPipelineResult(
        navigateToPersona: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: FrequencyFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }

    final finalized = await _markRemoteFinalized(session.sessionId);
    if (!finalized.ok || finalized.state == null) {
      return FrequencyPendingPipelineResult(
        navigateToPersona: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: finalized.code.isNotEmpty
            ? finalized.code
            : 'finalize_failed',
        failureKind: FrequencyFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(FrequencyPendingPipelineStep.markRemoteFinalized);

    return FrequencyPendingPipelineResult(
      navigateToPersona: true,
      completedSteps: steps,
      session: finalized.state,
      finalize: finalizeResult,
    );
  }
}
