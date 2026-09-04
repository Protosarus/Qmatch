import '../domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'frequency_v2_finalize_callable_client.dart';

enum FrequencyV2PendingPipelineStep {
  finalizeFrequencyV2,
  markRemoteFinalized,
}

enum FrequencyV2PendingPipelineDestination {
  dormantCompletion,
  stayOnSession,
}

class FrequencyV2PendingPipelineResult {
  const FrequencyV2PendingPipelineResult({
    required this.destination,
    required this.completedSteps,
    this.session,
    this.uiErrorCode,
    this.failureKind,
    this.finalize,
  });

  final FrequencyV2PendingPipelineDestination destination;
  final List<FrequencyV2PendingPipelineStep> completedSteps;
  final FrequencyV2PersistedSessionState? session;
  final String? uiErrorCode;
  final FrequencyV2FinalizeFailureKind? failureKind;
  final FrequencyV2FinalizeResult? finalize;
}

/// Crash-safe V2 pipeline:
/// locked session → finalizeFrequencyV2 → confirm success →
/// mark LOCAL V2 session remotely finalized → dormant completion.
///
/// The callable writes `users/{uid}/assessments/frequency_v2`.
/// This pipeline must not write that document, V1 Frequency results,
/// `canonical_v1`, completion flags, Discover, or verification maps.
class FrequencyV2PendingFinalizationPipeline {
  FrequencyV2PendingFinalizationPipeline({
    required FrequencyV2FinalizeCallableClient finalizeClient,
    required Future<FrequencyV2SessionWriteResult> Function({
      required String ownerUid,
      required String sessionId,
    }) markRemoteFinalized,
    String? Function()? currentUid,
  })  : _finalizeClient = finalizeClient,
        _markRemoteFinalized = markRemoteFinalized,
        _currentUid = currentUid;

  final FrequencyV2FinalizeCallableClient _finalizeClient;
  final Future<FrequencyV2SessionWriteResult> Function({
    required String ownerUid,
    required String sessionId,
  }) _markRemoteFinalized;
  final String? Function()? _currentUid;

  Future<FrequencyV2PendingPipelineResult> run({
    required FrequencyV2PersistedSessionState session,
  }) async {
    final steps = <FrequencyV2PendingPipelineStep>[];
    final ownerUid = (_currentUid?.call() ?? session.ownerUid).trim();
    final mapped = FrequencyV2FinalizeRequestMapper.mapLockedSession(
      session: session,
      ownerUid: ownerUid.isEmpty ? session.ownerUid : ownerUid,
    );
    if (!mapped.ok || mapped.payload == null) {
      return FrequencyV2PendingPipelineResult(
        destination: FrequencyV2PendingPipelineDestination.stayOnSession,
        completedSteps: steps,
        session: session,
        uiErrorCode: mapped.code,
        failureKind: mapped.code == 'owner_mismatch'
            ? FrequencyV2FinalizeFailureKind.accountInconsistency
            : FrequencyV2FinalizeFailureKind.nonRetryableSession,
      );
    }

    final FrequencyV2FinalizeResult finalizeResult;
    try {
      finalizeResult = await _finalizeClient.finalize(mapped.payload!);
    } on FrequencyV2FinalizeException catch (e) {
      return FrequencyV2PendingPipelineResult(
        destination: FrequencyV2PendingPipelineDestination.stayOnSession,
        completedSteps: steps,
        session: session,
        uiErrorCode: e.code,
        failureKind: e.kind,
      );
    }
    steps.add(FrequencyV2PendingPipelineStep.finalizeFrequencyV2);

    final marked = await _markRemoteFinalized(
      ownerUid: session.ownerUid,
      sessionId: session.sessionId,
    );
    if (!marked.ok) {
      return FrequencyV2PendingPipelineResult(
        destination: FrequencyV2PendingPipelineDestination.stayOnSession,
        completedSteps: steps,
        session: marked.state ?? session,
        uiErrorCode: marked.code,
        failureKind: FrequencyV2FinalizeFailureKind.retryable,
        finalize: finalizeResult,
      );
    }
    steps.add(FrequencyV2PendingPipelineStep.markRemoteFinalized);

    return FrequencyV2PendingPipelineResult(
      destination: FrequencyV2PendingPipelineDestination.dormantCompletion,
      completedSteps: steps,
      session: marked.state,
      finalize: finalizeResult,
    );
  }
}
