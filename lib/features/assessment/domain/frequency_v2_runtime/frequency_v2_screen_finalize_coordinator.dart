import '../../services/frequency_v2_pending_finalization_pipeline.dart';
import 'frequency_v2_persisted_session_state.dart';

/// One-flight finalize gate for [FrequencyV2TestScreen].
///
/// The screen owns the pipeline. This coordinator only prevents duplicate
/// callable invocations and extra automatic bootstrap retries.
class FrequencyV2ScreenFinalizeCoordinator {
  FrequencyV2ScreenFinalizeCoordinator({
    required FrequencyV2PendingFinalizationPipeline pipeline,
  }) : _pipeline = pipeline;

  final FrequencyV2PendingFinalizationPipeline _pipeline;

  bool pipelineInFlight = false;
  bool didAutoRetryPending = false;

  bool get isBusy => pipelineInFlight;

  FrequencyV2PendingFinalizationPipeline get pipeline => _pipeline;

  /// One automatic pending retry per screen/coordinator lifetime.
  bool tryClaimBootstrapRetry() {
    if (didAutoRetryPending) return false;
    didAutoRetryPending = true;
    return true;
  }

  Future<FrequencyV2PendingPipelineResult?> runIfPending(
    FrequencyV2PersistedSessionState? session,
  ) async {
    if (session == null) return null;
    if (session.status !=
        FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
      return null;
    }
    if (pipelineInFlight) return null;
    pipelineInFlight = true;
    try {
      return await _pipeline.run(session: session);
    } finally {
      pipelineInFlight = false;
    }
  }
}
