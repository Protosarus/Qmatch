import 'package:flutter/services.dart';

import '../domain/eq_bank/eq_bank.dart';
import '../domain/eq_session/eq_session.dart';
import '../domain/eq_session/eq_session_prefs_repository.dart';
import '../domain/frequency_bank/frequency_bank.dart';
import '../domain/frequency_session/frequency_session.dart';
import '../domain/iq_session/iq_session.dart';
import '../domain/iq_session/iq_session_prefs_repository.dart';
import '../models/assessment_progress.dart';

/// Cold-start gate: local `completedPendingPersistence` must not be skipped
/// when AuthWrapper routes by remote progress alone.
///
/// IQ: a durable local pending session always wins over `users.iq_completed`.
/// Recovery owner is IQTestScreen (full pipeline including idempotent
/// `finalizeIq`). This reconciler must **not** call markRemoteFinalized
/// for IQ merely because the remote mirror is true — that mirror is also
/// written by `finalizeIq` before client canonical persistence.
///
/// EQ: same crash-window rule as IQ. `finalizeEq` writes `eq_completed`
/// before client score / assessments/eq / canonical_v1. Recovery owner is
/// EQTestScreen (`EqPendingFinalizationPipeline`). This reconciler must
/// **not** call markRemoteFinalized for EQ merely because the remote mirror
/// is true.
///
/// Frequency: same crash-window rule as IQ/EQ. `finalizeFrequency` writes
/// `frequency_completed=true` before client score / assessments/frequency /
/// canonical_v1 / progress. Recovery owner is FrequencyTestScreen
/// (`FrequencyPendingFinalizationPipeline`). This reconciler must **not**
/// call markRemoteFinalized for Frequency merely because remote
/// `frequency_completed` or `assessment_flow_completed` is true.
class AssessmentColdStartPendingReconciler {
  AssessmentColdStartPendingReconciler({
    IqSessionPersistenceRepository? iqRepository,
    EqSessionPersistenceRepository? eqRepository,
    FrequencySessionPersistenceRepository? frequencyRepository,
    AssetBundle? bundle,
    Future<EqCanonicalBankDocument> Function(String bankLocale)? loadEqBank,
    Future<FrequencyCanonicalBankDocument> Function(String bankLocale)?
        loadFrequencyBank,
  })  : _iqRepo = iqRepository ?? IqSessionPrefsRepository(),
        _eqRepo = eqRepository ?? EqSessionPrefsRepository(),
        _frequencyRepo =
            frequencyRepository ?? FrequencySessionPrefsRepository() {
    // loadEqBank / loadFrequencyBank / bundle are retained for constructor
    // compatibility. IQ, EQ, and Frequency pending are never locally
    // finalized here (server mirrors are written before client persistence).
    assert(loadEqBank == null || true);
    assert(loadFrequencyBank == null || true);
    assert(bundle == null || true);
  }

  final IqSessionPersistenceRepository _iqRepo;
  final EqSessionPersistenceRepository _eqRepo;
  final FrequencySessionPersistenceRepository _frequencyRepo;

  /// Pure routing decision after optional local finalize attempts.
  static AssessmentColdStartDecision decide({
    required bool iqPendingFinalization,
    required bool eqPendingFinalization,
    required bool frequencyPendingFinalization,
    required AssessmentFlowDestination progressDestination,
  }) {
    if (iqPendingFinalization) {
      return const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.iq,
        openAssessmentTestScreen: true,
        reason: 'iq_pending_finalization',
      );
    }
    if (eqPendingFinalization) {
      return const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.eq,
        openAssessmentTestScreen: true,
        reason: 'eq_pending_finalization',
      );
    }
    if (frequencyPendingFinalization) {
      return const AssessmentColdStartDecision(
        destination: AssessmentFlowDestination.frequency,
        openAssessmentTestScreen: true,
        reason: 'frequency_pending_finalization',
      );
    }
    return AssessmentColdStartDecision(
      destination: progressDestination,
      openAssessmentTestScreen: false,
      reason: 'progress_routing',
    );
  }

  /// Decide routing (hold on any still-pending module). Does not locally
  /// mark pending sessions remote-finalized from remote progress mirrors.
  Future<AssessmentColdStartDecision> reconcile({
    required String uid,
    required AssessmentProgressSnapshot progress,
  }) async {
    if (uid.trim().isEmpty) {
      return decide(
        iqPendingFinalization: false,
        eqPendingFinalization: false,
        frequencyPendingFinalization: false,
        progressDestination: progress.destination,
      );
    }

    await finalizeWhereRemoteProgressAlreadyComplete(
      uid: uid,
      progress: progress,
    );

    final pending = await peekPendingFinalization(uid: uid);
    return decide(
      iqPendingFinalization: pending.iq,
      eqPendingFinalization: pending.eq,
      frequencyPendingFinalization: pending.frequency,
      progressDestination: progress.destination,
    );
  }

  Future<({bool iq, bool eq, bool frequency})> peekPendingFinalization({
    required String uid,
  }) async {
    final iq = await _iqRepo.loadActiveSession(uid);
    final eq = await _eqRepo.loadActiveSession(uid);
    final frequency = await _frequencyRepo.loadActiveSession(uid);
    return (
      iq: iq.isLoaded &&
          iq.state!.status ==
              IqPersistedSessionStatus.completedPendingPersistence,
      eq: eq.isLoaded &&
          eq.state!.status ==
              EqPersistedSessionStatus.completedPendingPersistence,
      frequency: frequency.isLoaded &&
          frequency.state!.status ==
              FrequencyPersistedSessionStatus.completedPendingPersistence,
    );
  }

  /// No-op. IQ, EQ, and Frequency pending sessions are recovered by their
  /// test-screen pipelines. Remote `*_completed` mirrors are not proof that
  /// client scoring / result / canonical / progress writes finished.
  Future<void> finalizeWhereRemoteProgressAlreadyComplete({
    required String uid,
    required AssessmentProgressSnapshot progress,
  }) async {}
}

class AssessmentColdStartDecision {
  const AssessmentColdStartDecision({
    required this.destination,
    required this.openAssessmentTestScreen,
    required this.reason,
  });

  final AssessmentFlowDestination destination;

  /// When true, open IQ/EQ/Frequency *test* screen (pending retry), not intro.
  final bool openAssessmentTestScreen;

  final String reason;
}
