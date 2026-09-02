import '../domain/eq_scoring/eq_scoring.dart';
import '../domain/eq_session/eq_session.dart';
import '../domain/profile/profile.dart';
import 'assessment_progress_service.dart';
import 'canonical_assessment_persistence.dart';
import 'canonical_assessment_profile_reconciler.dart';
import 'eq_canonical_runtime_service.dart';
import 'eq_finalize_callable_client.dart';

/// Ordered steps of the EQ pending-finalization pipeline.
enum EqPendingPipelineStep {
  finalizeEq,
  score,
  persistAssessment,
  persistCanonical,
  markEqCompleted,
  markRemoteFinalized,
}

class EqPendingPipelineResult {
  const EqPendingPipelineResult({
    required this.navigateToFrequency,
    required this.completedSteps,
    this.session,
    this.uiErrorCode,
    this.failureKind,
    this.finalize,
  });

  final bool navigateToFrequency;
  final List<EqPendingPipelineStep> completedSteps;
  final EqPersistedSessionState? session;
  final String? uiErrorCode;
  final EqFinalizeFailureKind? failureKind;
  final EqFinalizeResult? finalize;
}

/// Single owner of:
/// finalizeEq → client score → assessments/eq → canonical_v1 →
/// markEqCompleted → markRemoteFinalized.
///
/// `finalizeEq` success does **not** complete local persistence.
/// Scoring is never a substitute for a failed server finalize.
///
/// Release order: deploy backend `finalizeEq` before a Flutter release
/// that requires this pipeline.
class EqPendingFinalizationPipeline {
  EqPendingFinalizationPipeline({
    required EqFinalizeCallableClient finalizeClient,
    required Future<EqScoringOutcome> Function(EqPersistedSessionState session)
        scoreCompleted,
    required Future<void> Function({
      required EqCanonicalScoringResult result,
      required String ownerUid,
      required String sessionId,
      required String locale,
      required String language,
      DateTime? startedAt,
    }) persistAssessment,
    required Future<void> Function({
      required EqCanonicalScoringResult result,
      required String ownerUid,
      required String sessionId,
      required String locale,
      required String language,
    }) persistCanonical,
    required Future<void> Function() markEqCompleted,
    required Future<EqSessionWriteResult> Function(String sessionId)
        markRemoteFinalized,
    String? Function()? currentUid,
  })  : _finalizeClient = finalizeClient,
        _scoreCompleted = scoreCompleted,
        _persistAssessment = persistAssessment,
        _persistCanonical = persistCanonical,
        _markEqCompleted = markEqCompleted,
        _markRemoteFinalized = markRemoteFinalized,
        _currentUid = currentUid;

  factory EqPendingFinalizationPipeline.live({
    EqFinalizeCallableClient? finalizeClient,
    EqCanonicalRuntimeService? runtime,
    CanonicalAssessmentPersistence? persistence,
    CanonicalAssessmentProfileReconciler? reconciler,
    AssessmentProgressService? progress,
  }) {
    final rt = runtime ?? EqCanonicalRuntimeService();
    final persist = persistence ?? CanonicalAssessmentPersistence();
    final repair = reconciler ?? CanonicalAssessmentProfileReconciler();
    final prog = progress ?? AssessmentProgressService();
    return EqPendingFinalizationPipeline(
      finalizeClient: finalizeClient ?? EqFinalizeCallableClient(),
      scoreCompleted: rt.scoreCompleted,
      persistAssessment: ({
        required EqCanonicalScoringResult result,
        required String ownerUid,
        required String sessionId,
        required String locale,
        required String language,
        DateTime? startedAt,
      }) async {
        await persist.upsertCompletedAssessment(
          assessmentType: 'eq',
          fields: persist.buildCanonicalEq10dPayload(
            result: result,
            sessionId: sessionId,
            locale: locale,
            languageUsed: language,
            startedAt: startedAt,
          ),
        );
      },
      persistCanonical: ({
        required EqCanonicalScoringResult result,
        required String ownerUid,
        required String sessionId,
        required String locale,
        required String language,
      }) async {
        final iq4 = await repair.ensureIq4(ownerUid: ownerUid);
        if (!iq4.ok) {
          throw StateError(iq4.message ?? iq4.code.name);
        }
        final existingProfile =
            await persist.getCanonicalProfile(uid: ownerUid);
        final existingIq = repair.measuredOfModule(existingProfile, 'iq');
        final adapted = const EqTo20dRuntimeAdapter().adapt(
          result: result,
          ownerUid: ownerUid,
          sessionId: sessionId,
          existingIqDimensions: existingIq,
        );
        if (!adapted.ok || adapted.fragment == null) {
          throw StateError(adapted.message ?? 'EQ→20D adapt failed');
        }
        await persist.upsertCanonicalProfileFragment(adapted.fragment!);
      },
      markEqCompleted: prog.markEqCompleted,
      markRemoteFinalized: (sessionId) =>
          rt.markRemoteFinalized(sessionId: sessionId),
      currentUid: () => rt.currentUid,
    );
  }

  final EqFinalizeCallableClient _finalizeClient;
  final Future<EqScoringOutcome> Function(EqPersistedSessionState session)
      _scoreCompleted;
  final Future<void> Function({
    required EqCanonicalScoringResult result,
    required String ownerUid,
    required String sessionId,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) _persistAssessment;
  final Future<void> Function({
    required EqCanonicalScoringResult result,
    required String ownerUid,
    required String sessionId,
    required String locale,
    required String language,
  }) _persistCanonical;
  final Future<void> Function() _markEqCompleted;
  final Future<EqSessionWriteResult> Function(String sessionId)
      _markRemoteFinalized;
  final String? Function()? _currentUid;

  /// Runs the full pending pipeline. Never deletes local session data.
  Future<EqPendingPipelineResult> run({
    required EqPersistedSessionState session,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) async {
    final steps = <EqPendingPipelineStep>[];
    final ownerUid = (_currentUid?.call() ?? session.ownerUid).trim();
    final mapped = EqFinalizeRequestMapper.mapLockedSession(
      session: session,
      ownerUid: ownerUid.isEmpty ? session.ownerUid : ownerUid,
    );
    if (!mapped.ok || mapped.payload == null) {
      return EqPendingPipelineResult(
        navigateToFrequency: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: mapped.code == 'owner_mismatch'
            ? EqFinalizeFailureKind.accountInconsistency
            : EqFinalizeFailureKind.nonRetryableSession,
      );
    }

    final EqFinalizeResult finalizeResult;
    try {
      finalizeResult = await _finalizeClient.finalize(mapped.payload!);
      steps.add(EqPendingPipelineStep.finalizeEq);
    } on EqFinalizeException catch (e) {
      return EqPendingPipelineResult(
        navigateToFrequency: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: e.kind,
      );
    }

    final scored = await _scoreCompleted(session);
    if (!scored.ok || scored.result == null) {
      return EqPendingPipelineResult(
        navigateToFrequency: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: scored.code?.name ?? 'score_failed',
        failureKind: EqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(EqPendingPipelineStep.score);

    try {
      await _persistAssessment(
        result: scored.result!,
        ownerUid: session.ownerUid,
        sessionId: session.sessionId,
        locale: locale,
        language: language,
        startedAt: startedAt,
      );
      steps.add(EqPendingPipelineStep.persistAssessment);
      await _persistCanonical(
        result: scored.result!,
        ownerUid: session.ownerUid,
        sessionId: session.sessionId,
        locale: locale,
        language: language,
      );
      steps.add(EqPendingPipelineStep.persistCanonical);
      await _markEqCompleted();
      steps.add(EqPendingPipelineStep.markEqCompleted);
    } catch (_) {
      return EqPendingPipelineResult(
        navigateToFrequency: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: EqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }

    final finalized = await _markRemoteFinalized(session.sessionId);
    if (!finalized.ok || finalized.state == null) {
      return EqPendingPipelineResult(
        navigateToFrequency: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: finalized.code.isNotEmpty
            ? finalized.code
            : 'finalize_failed',
        failureKind: EqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(EqPendingPipelineStep.markRemoteFinalized);

    return EqPendingPipelineResult(
      navigateToFrequency: true,
      completedSteps: steps,
      session: finalized.state,
      finalize: finalizeResult,
    );
  }
}
