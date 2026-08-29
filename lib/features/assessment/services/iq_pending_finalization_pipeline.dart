import '../domain/iq_scoring/iq_scoring.dart';
import '../domain/iq_session/iq_session.dart';
import '../domain/profile/profile.dart';
import 'assessment_progress_service.dart';
import 'canonical_assessment_persistence.dart';
import 'iq_canonical_runtime_service.dart';
import 'iq_finalize_callable_client.dart';

/// Ordered steps of the IQ pending-finalization pipeline.
enum IqPendingPipelineStep {
  finalizeIq,
  score,
  persistAssessmentAndCanonical,
  markIqCompleted,
  markRemoteFinalized,
}

class IqPendingPipelineResult {
  const IqPendingPipelineResult({
    required this.navigateToEq,
    required this.completedSteps,
    this.session,
    this.uiErrorCode,
    this.failureKind,
    this.finalize,
  });

  final bool navigateToEq;
  final List<IqPendingPipelineStep> completedSteps;
  final IqPersistedSessionState? session;
  final String? uiErrorCode;
  final IqFinalizeFailureKind? failureKind;
  final IqFinalizeResult? finalize;
}

/// Single owner of:
/// finalizeIq → client score → assessments/iq → canonical_v1 →
/// markIqCompleted → markRemoteFinalized.
///
/// `finalizeIq` success does **not** complete local persistence.
class IqPendingFinalizationPipeline {
  IqPendingFinalizationPipeline({
    required IqFinalizeCallableClient finalizeClient,
    required Future<IqScoringOutcome> Function(IqPersistedSessionState session)
        scoreCompleted,
    required Future<void> Function({
      required IqCanonicalScoringResult result,
      required String ownerUid,
      required String locale,
      required String language,
      DateTime? startedAt,
    }) persistAssessmentAndCanonical,
    required Future<void> Function() markIqCompleted,
    required Future<IqSessionWriteResult> Function(String sessionId)
        markRemoteFinalized,
    String? Function()? currentUid,
  })  : _finalizeClient = finalizeClient,
        _scoreCompleted = scoreCompleted,
        _persistAssessmentAndCanonical = persistAssessmentAndCanonical,
        _markIqCompleted = markIqCompleted,
        _markRemoteFinalized = markRemoteFinalized,
        _currentUid = currentUid;

  factory IqPendingFinalizationPipeline.live({
    IqFinalizeCallableClient? finalizeClient,
    IqCanonicalRuntimeService? runtime,
    CanonicalAssessmentPersistence? persistence,
    AssessmentProgressService? progress,
  }) {
    final rt = runtime ?? IqCanonicalRuntimeService();
    final persist = persistence ?? CanonicalAssessmentPersistence();
    final prog = progress ?? AssessmentProgressService();
    return IqPendingFinalizationPipeline(
      finalizeClient: finalizeClient ?? IqFinalizeCallableClient(),
      scoreCompleted: rt.scoreCompleted,
      persistAssessmentAndCanonical: ({
        required IqCanonicalScoringResult result,
        required String ownerUid,
        required String locale,
        required String language,
        DateTime? startedAt,
      }) async {
        await persist.upsertCompletedAssessment(
          assessmentType: 'iq',
          fields: persist.buildCanonicalIq4dPayload(
            result: result,
            locale: locale,
            languageUsed: language,
            startedAt: startedAt,
          ),
        );
        final adapted = const IqTo20dRuntimeAdapter().adapt(
          result: result,
          ownerUid: ownerUid,
        );
        if (!adapted.ok || adapted.fragment == null) {
          throw StateError(
            adapted.message ?? adapted.code?.name ?? 'adapt_failed',
          );
        }
        // Profile before progress mirror — downstream must not see iq_completed
        // without IQ4 on canonical_v1 from this client pipeline.
        await persist.upsertCanonicalProfileFragment(adapted.fragment!);
      },
      markIqCompleted: () => prog.markIqCompleted(rawScore: null),
      markRemoteFinalized: (sessionId) =>
          rt.markRemoteFinalized(sessionId: sessionId),
      currentUid: () => rt.currentUid,
    );
  }

  final IqFinalizeCallableClient _finalizeClient;
  final Future<IqScoringOutcome> Function(IqPersistedSessionState session)
      _scoreCompleted;
  final Future<void> Function({
    required IqCanonicalScoringResult result,
    required String ownerUid,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) _persistAssessmentAndCanonical;
  final Future<void> Function() _markIqCompleted;
  final Future<IqSessionWriteResult> Function(String sessionId)
      _markRemoteFinalized;
  final String? Function()? _currentUid;

  /// Runs the full pending pipeline. Never deletes local session data.
  Future<IqPendingPipelineResult> run({
    required IqPersistedSessionState session,
    required String locale,
    required String language,
    DateTime? startedAt,
  }) async {
    final steps = <IqPendingPipelineStep>[];
    final ownerUid = (_currentUid?.call() ?? session.ownerUid).trim();
    final mapped = IqFinalizeRequestMapper.mapLockedSession(
      session: session,
      ownerUid: ownerUid.isEmpty ? session.ownerUid : ownerUid,
    );
    if (!mapped.ok || mapped.payload == null) {
      return IqPendingPipelineResult(
        navigateToEq: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: mapped.code == 'owner_mismatch'
            ? IqFinalizeFailureKind.accountInconsistency
            : IqFinalizeFailureKind.nonRetryableSession,
      );
    }

    final IqFinalizeResult finalizeResult;
    try {
      finalizeResult = await _finalizeClient.finalize(mapped.payload!);
      steps.add(IqPendingPipelineStep.finalizeIq);
    } on IqFinalizeException catch (e) {
      return IqPendingPipelineResult(
        navigateToEq: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: e.kind,
      );
    }

    final scored = await _scoreCompleted(session);
    if (!scored.ok || scored.result == null) {
      return IqPendingPipelineResult(
        navigateToEq: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: scored.code?.name ?? 'score_failed',
        failureKind: IqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(IqPendingPipelineStep.score);

    try {
      await _persistAssessmentAndCanonical(
        result: scored.result!,
        ownerUid: session.ownerUid,
        locale: locale,
        language: language,
        startedAt: startedAt,
      );
      steps.add(IqPendingPipelineStep.persistAssessmentAndCanonical);
      await _markIqCompleted();
      steps.add(IqPendingPipelineStep.markIqCompleted);
    } catch (_) {
      return IqPendingPipelineResult(
        navigateToEq: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: 'persist_failed',
        failureKind: IqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }

    final finalized = await _markRemoteFinalized(session.sessionId);
    if (!finalized.ok || finalized.state == null) {
      return IqPendingPipelineResult(
        navigateToEq: false,
        completedSteps: steps,
        session: session,
        uiErrorCode: finalized.code ?? 'finalize_failed',
        failureKind: IqFinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(IqPendingPipelineStep.markRemoteFinalized);

    return IqPendingPipelineResult(
      navigateToEq: true,
      completedSteps: steps,
      session: finalized.state,
      finalize: finalizeResult,
    );
  }
}
