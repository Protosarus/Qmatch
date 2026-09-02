import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/iq_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/iq_pending_finalization_pipeline.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
}

Future<
    ({
      IqPersistedSessionState session,
      IqSessionManager manager,
      IqSessionMemoryRepository repo,
      String sid,
    })> _pending({
  required IqRecoveredBankDocument bank,
  required String uid,
  required String seed,
  int idSeed = 31,
}) async {
  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(idSeed)),
    clock: () => DateTime.utc(2026, 8, 29, 16),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  final sid = created.state!.sessionId;
  final byId = {for (final i in bank.items) i.id: i};
  for (final p in created.state!.itemPlans) {
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: byId[p.itemId]!.correctOptionId,
    );
  }
  final completed = await manager.complete(ownerUid: uid, sessionId: sid);
  expect(
    completed.state!.status,
    IqPersistedSessionStatus.completedPendingPersistence,
  );
  return (
    session: completed.state!,
    manager: manager,
    repo: repo,
    sid: sid,
  );
}

IqPendingFinalizationPipeline _pipeline({
  required IqRecoveredBankDocument bank,
  required IqSessionManager manager,
  required String uid,
  required IqFinalizeCallableClient client,
  Future<void> Function()? persist,
  Future<void> Function()? markCompleted,
}) {
  return IqPendingFinalizationPipeline(
    finalizeClient: client,
    scoreCompleted: (session) async {
      return const IqCanonicalScorer().scoreCompletedSession(
        session: session,
        bank: bank,
        ownerUid: uid,
      );
    },
    persistAssessmentAndCanonical: ({
      required result,
      required ownerUid,
      required locale,
      required language,
      startedAt,
    }) async {
      if (persist != null) await persist();
    },
    markIqCompleted: () async {
      if (markCompleted != null) await markCompleted();
    },
    markRemoteFinalized: (sessionId) {
      return manager.markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
    },
    currentUid: () => uid,
  );
}

AssessmentProgressSnapshot _eqProgress() {
  return const AssessmentProgressSnapshot(
    assessmentFlowVersion: AssessmentProgressSnapshot.flowVersionV2,
    iqStatus: AssessmentModuleStatus.completed,
    eqStatus: AssessmentModuleStatus.notStarted,
    frequencyStatus: AssessmentModuleStatus.notStarted,
    frequencyCompleted: false,
    frequencyIncomplete: false,
    iqCompleted: true,
    eqCompleted: false,
    allAssessmentsCompleted: false,
    assessmentFlowCompleted: false,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: AssessmentFlowDestination.eq,
    resolutionSource: 'test',
    reason: null,
  );
}

void main() {
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test('success order: finalizeIq then score/persist/mirrors then local finalize',
      () async {
    const uid = 'uid_ok';
    final built = await _pending(bank: bank, uid: uid, seed: 'ok-seed');
    final steps = <String>[];
    String? calledSession;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: IqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeIq');
          calledSession = data['session_id'] as String?;
          expect(data.containsKey('status'), isFalse);
          expect(data.containsKey('answered_at'), isFalse);
          expect(data.containsKey('score'), isFalse);
          expect(data.containsKey('iq_completed'), isFalse);
          steps.add('finalizeIq');
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'iq',
            'idempotent': false,
          };
        },
      ),
      persist: () async => steps.add('persist'),
      markCompleted: () async => steps.add('markIqCompleted'),
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );

    expect(calledSession, built.sid);
    expect(outcome.navigateToEq, isTrue);
    expect(outcome.finalize!.status, 'verified');
    expect(outcome.finalize!.idempotent, isFalse);
    expect(steps, ['finalizeIq', 'persist', 'markIqCompleted']);
    expect(outcome.completedSteps, [
      IqPendingPipelineStep.finalizeIq,
      IqPendingPipelineStep.score,
      IqPendingPipelineStep.persistAssessmentAndCanonical,
      IqPendingPipelineStep.markIqCompleted,
      IqPendingPipelineStep.markRemoteFinalized,
    ]);
    final stored = await built.repo.loadSession(uid, built.sid);
    expect(stored.state!.status, IqPersistedSessionStatus.completed);
    expect(stored.state!.remoteFinalized, isTrue);
    expect(stored.state!.sessionId, built.sid);
    expect((await built.repo.loadActiveSession(uid)).isLoaded, isFalse);
  });

  test('network failure: no score persist, session stays pending', () async {
    const uid = 'uid_net';
    final built = await _pending(bank: bank, uid: uid, seed: 'net-seed');
    var scored = false;
    var persisted = false;
    final pipeline = IqPendingFinalizationPipeline(
      finalizeClient: IqFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'timeout secret',
            code: 'deadline-exceeded',
          );
        },
      ),
      scoreCompleted: (session) async {
        scored = true;
        return const IqCanonicalScorer().scoreCompletedSession(
          session: session,
          bank: bank,
          ownerUid: uid,
        );
      },
      persistAssessmentAndCanonical: ({
        required result,
        required ownerUid,
        required locale,
        required language,
        startedAt,
      }) async {
        persisted = true;
      },
      markIqCompleted: () async => persisted = true,
      markRemoteFinalized: (sessionId) {
        return built.manager
            .markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
      },
      currentUid: () => uid,
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );

    expect(outcome.navigateToEq, isFalse);
    expect(outcome.failureKind, IqFinalizeFailureKind.retryable);
    expect(scored, isFalse);
    expect(persisted, isFalse);
    expect(outcome.completedSteps, isEmpty);
    final active = await built.repo.loadActiveSession(uid);
    expect(
      active.state!.status,
      IqPersistedSessionStatus.completedPendingPersistence,
    );
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 25);
    expect(active.state!.itemPlans.length, 25);
  });

  test('lost response then idempotent retry completes once', () async {
    const uid = 'uid_lost';
    final built = await _pending(bank: bank, uid: uid, seed: 'lost-seed');
    var calls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: IqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeIq');
          expect(data['session_id'], built.sid);
          calls++;
          if (calls == 1) {
            // ignore: invalid_use_of_protected_member
            throw FirebaseFunctionsException(
              message: 'deadline',
              code: 'deadline-exceeded',
            );
          }
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'iq',
            'idempotent': true,
          };
        },
      ),
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToEq, isFalse);
    final resumed = await built.manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: 'must-not-compose',
    );
    expect(resumed.state!.sessionId, built.sid);
    expect(built.manager.lastOperationComposed, isFalse);

    final second = await pipeline.run(
      session: resumed.state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(second.navigateToEq, isTrue);
    expect(second.finalize!.idempotent, isTrue);
    expect(calls, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.sessionId,
      built.sid,
    );
  });

  test(
      'finalizeIq success + persist fail: pending wins over iq_completed; retry same session',
      () async {
    const uid = 'uid_persist_fail';
    final built =
        await _pending(bank: bank, uid: uid, seed: 'persist-fail-seed');
    var persistAttempts = 0;
    var finalizeCalls = 0;
    final client = IqFinalizeCallableClient(
      call: (name, data) async {
        expect(name, 'finalizeIq');
        expect(data['session_id'], built.sid);
        finalizeCalls++;
        return {
          'ok': true,
          'status': 'verified',
          'flow': 'iq',
          'idempotent': finalizeCalls > 1,
        };
      },
    );
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: client,
      persist: () async {
        persistAttempts++;
        if (persistAttempts == 1) {
          throw StateError('canonical write failed');
        }
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToEq, isFalse);
    expect(first.completedSteps, [
      IqPendingPipelineStep.finalizeIq,
      IqPendingPipelineStep.score,
    ]);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      IqPersistedSessionStatus.completedPendingPersistence,
    );
    expect(
      (await built.repo.loadActiveSession(uid)).state!.sessionId,
      built.sid,
    );

    // Cold start: remote iq_completed is true (backend already wrote it).
    final decision = await AssessmentColdStartPendingReconciler(
      iqRepository: built.repo,
      eqRepository: EqSessionMemoryRepository(),
      frequencyRepository: FrequencySessionMemoryRepository(),
    ).reconcile(uid: uid, progress: _eqProgress());

    expect(decision.destination, AssessmentFlowDestination.iq);
    expect(decision.openAssessmentTestScreen, isTrue);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.remoteFinalized,
      isFalse,
    );
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      IqPersistedSessionStatus.completedPendingPersistence,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToEq, isTrue);
    expect(retry.finalize!.idempotent, isTrue);
    expect(finalizeCalls, 2);
    expect(persistAttempts, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.status,
      IqPersistedSessionStatus.completed,
    );
  });

  test('invalid-argument retains answers and does not advance', () async {
    const uid = 'uid_invalid';
    final built = await _pending(bank: bank, uid: uid, seed: 'invalid-seed');
    var persist = false;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: IqFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'structurally incomplete secret',
            code: 'invalid-argument',
          );
        },
      ),
      persist: () async => persist = true,
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(outcome.navigateToEq, isFalse);
    expect(outcome.failureKind, IqFinalizeFailureKind.nonRetryableSession);
    expect(persist, isFalse);
    final active = await built.repo.loadActiveSession(uid);
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 25);
    expect(
      active.state!.status,
      IqPersistedSessionStatus.completedPendingPersistence,
    );
  });

  test('IQ_ALREADY_VERIFIED retains evidence and does not retake', () async {
    const uid = 'uid_verified';
    final built = await _pending(bank: bank, uid: uid, seed: 'verified-seed');
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: IqFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'already verified secret',
            code: 'failed-precondition',
            details: {'code': 'IQ_ALREADY_VERIFIED'},
          );
        },
      ),
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(outcome.navigateToEq, isFalse);
    expect(outcome.failureKind, IqFinalizeFailureKind.accountInconsistency);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.sessionId,
      built.sid,
    );
    expect(
      (await built.repo.loadActiveSession(uid)).state!.answers.length,
      25,
    );
    final resumed = await built.manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: 'retake-must-not-happen',
    );
    expect(resumed.state!.sessionId, built.sid);
    expect(built.manager.lastOperationComposed, isFalse);
  });

  test('permission-denied and not-found keep pending session', () async {
    for (final code in ['permission-denied', 'not-found']) {
      const uid = 'uid_denied';
      final built = await _pending(
        bank: bank,
        uid: uid,
        seed: 'denied-$code',
        idSeed: code.hashCode,
      );
      final outcome = await _pipeline(
        bank: bank,
        manager: built.manager,
        uid: uid,
        client: IqFinalizeCallableClient(
          call: (_, __) async {
            // ignore: invalid_use_of_protected_member
            throw FirebaseFunctionsException(message: 'nope', code: code);
          },
        ),
      ).run(
        session: built.session,
        locale: 'en-US',
        language: 'en',
      );
      expect(outcome.navigateToEq, isFalse, reason: code);
      expect(
        outcome.failureKind,
        IqFinalizeFailureKind.accountInconsistency,
        reason: code,
      );
      expect(
        (await built.repo.loadActiveSession(uid)).state!.sessionId,
        built.sid,
      );
    }
  });

  test('IQTestScreen owns pending retry; EQ/Frequency screens unchanged', () {
    final iq = File('lib/features/assessment/screens/iq_test_screen.dart')
        .readAsStringSync();
    expect(iq.contains('_runPendingFinalizationPipeline'), isTrue);
    expect(iq.contains('_schedulePendingPipelineOnce'), isTrue);
    expect(iq.contains('_didAutoRetryPending'), isTrue);
    expect(iq.contains('IqPendingFinalizationPipeline'), isTrue);
    expect(iq.contains('EQTestIntroScreen'), isTrue);

    final eq = File('lib/features/assessment/screens/eq_test_screen.dart')
        .readAsStringSync();
    final freq =
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .readAsStringSync();
    expect(eq.contains('finalizeIq'), isFalse);
    expect(freq.contains('finalizeIq'), isFalse);
    expect(eq.contains('IqPendingFinalizationPipeline'), isFalse);
    expect(freq.contains('IqPendingFinalizationPipeline'), isFalse);

    final reconciler = File(
      'lib/features/assessment/services/assessment_cold_start_pending_reconciler.dart',
    ).readAsStringSync();
    expect(reconciler.contains('_tryFinalizeIq'), isFalse);
    expect(reconciler.contains('_tryFinalizeEq'), isFalse);
    expect(reconciler.contains('IqFinalizeCallableClient'), isFalse);
    expect(reconciler.contains("httpsCallable('finalizeIq')"), isFalse);
  });
}
