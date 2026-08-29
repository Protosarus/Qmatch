import 'dart:convert';

import 'package:flutter/foundation.dart';
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
/// EQ / Frequency: unchanged. Crash window covered by local finalize when
/// remote progress already says that module is complete.
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
            frequencyRepository ?? FrequencySessionPrefsRepository(),
        _bundle = bundle ?? rootBundle,
        _loadEqBank = loadEqBank,
        _loadFrequencyBank = loadFrequencyBank;

  final IqSessionPersistenceRepository _iqRepo;
  final EqSessionPersistenceRepository _eqRepo;
  final FrequencySessionPersistenceRepository _frequencyRepo;
  final AssetBundle _bundle;
  final Future<EqCanonicalBankDocument> Function(String bankLocale)?
      _loadEqBank;
  final Future<FrequencyCanonicalBankDocument> Function(String bankLocale)?
      _loadFrequencyBank;

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

  /// Finalize pending locals whose remote progress mirrors are already set,
  /// then decide routing (hold on any still-pending module).
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

  /// Finalize pending EQ/Frequency locals whose remote progress mirrors are
  /// already set. IQ pending is never locally finalized here.
  Future<void> finalizeWhereRemoteProgressAlreadyComplete({
    required String uid,
    required AssessmentProgressSnapshot progress,
  }) async {
    if (progress.eqCompleted) {
      await _tryFinalizeEq(uid);
    }
    if (progress.frequencyCompleted || progress.assessmentFlowCompleted) {
      await _tryFinalizeFrequency(uid);
    }
  }

  Future<void> _tryFinalizeEq(String uid) async {
    final loaded = await _eqRepo.loadActiveSession(uid);
    if (!loaded.isLoaded) return;
    final session = loaded.state!;
    if (session.status !=
        EqPersistedSessionStatus.completedPendingPersistence) {
      return;
    }
    try {
      final bank = await _eqBankFor(session.bankLocale);
      final manager = EqSessionManager(bank: bank, repository: _eqRepo);
      final result = await manager.markRemoteFinalized(
        ownerUid: uid,
        sessionId: session.sessionId,
      );
      if (!result.ok) {
        debugPrint(
          'Cold-start EQ pending finalize failed: ${result.code} ${result.message}',
        );
      }
    } catch (e) {
      debugPrint('Cold-start EQ pending finalize error: $e');
    }
  }

  Future<void> _tryFinalizeFrequency(String uid) async {
    final loaded = await _frequencyRepo.loadActiveSession(uid);
    if (!loaded.isLoaded) return;
    final session = loaded.state!;
    if (session.status !=
        FrequencyPersistedSessionStatus.completedPendingPersistence) {
      return;
    }
    try {
      final bank = await _frequencyBankFor(session.bankLocale);
      final manager =
          FrequencySessionManager(bank: bank, repository: _frequencyRepo);
      final result = await manager.markRemoteFinalized(
        ownerUid: uid,
        sessionId: session.sessionId,
      );
      if (!result.ok) {
        debugPrint(
          'Cold-start Frequency pending finalize failed: ${result.code} ${result.message}',
        );
      }
    } catch (e) {
      debugPrint('Cold-start Frequency pending finalize error: $e');
    }
  }

  Future<EqCanonicalBankDocument> _eqBankFor(String bankLocale) async {
    final loader = _loadEqBank;
    if (loader != null) return loader(bankLocale);
    final path = switch (bankLocale) {
      'tr-TR' => EqBankContract.trAssetPath,
      'en-US' => EqBankContract.enAssetPath,
      _ => EqBankContract.trAssetPath,
    };
    final raw = await _bundle.loadString(path);
    return EqCanonicalBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<FrequencyCanonicalBankDocument> _frequencyBankFor(
    String bankLocale,
  ) async {
    final loader = _loadFrequencyBank;
    if (loader != null) return loader(bankLocale);
    final path = switch (bankLocale) {
      'tr-TR' => FrequencyBankContract.trAssetPath,
      'en-US' => FrequencyBankContract.enAssetPath,
      _ => FrequencyBankContract.trAssetPath,
    };
    final raw = await _bundle.loadString(path);
    return FrequencyCanonicalBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
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
