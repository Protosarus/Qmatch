import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/eq_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/eq_pending_finalization_pipeline.dart';

EqCanonicalBankDocument _loadBank() {
  return EqCanonicalBankDocument.fromJson(
    jsonDecode(File(EqBankContract.trAssetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
}

List<EqCanonicalResponse> _responses(EqPersistedSessionState session) {
  return [
    for (final p in session.itemPlans)
      EqCanonicalResponse(
        itemId: p.itemId,
        optionId: session.answersByItemId[p.itemId]!.selectedOptionId,
      ),
  ];
}

Future<
    ({
      EqPersistedSessionState session,
      EqSessionManager manager,
      EqSessionMemoryRepository repo,
      String sid,
    })> _pending({
  required EqCanonicalBankDocument bank,
  required String uid,
  required String seed,
  int idSeed = 31,
}) async {
  final repo = EqSessionMemoryRepository();
  final manager = EqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: EqSessionIdFactory(random: Random(idSeed)),
    shuffleRandom: Random(seed.hashCode),
    clock: () => DateTime.utc(2026, 9, 2, 16),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  final sid = created.state!.sessionId;
  for (final p in created.state!.itemPlans) {
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: p.displayedOptionIds.first,
    );
  }
  final completed = await manager.complete(ownerUid: uid, sessionId: sid);
  expect(
    completed.state!.status,
    EqPersistedSessionStatus.completedPendingPersistence,
  );
  return (
    session: completed.state!,
    manager: manager,
    repo: repo,
    sid: sid,
  );
}

EqPendingFinalizationPipeline _pipeline({
  required EqCanonicalBankDocument bank,
  required EqSessionManager manager,
  required String uid,
  required EqFinalizeCallableClient client,
  Future<void> Function()? persistAssessment,
  Future<void> Function()? persistCanonical,
  Future<void> Function()? markCompleted,
  Future<EqScoringOutcome> Function(EqPersistedSessionState session)? score,
}) {
  return EqPendingFinalizationPipeline(
    finalizeClient: client,
    scoreCompleted: score ??
        (session) async {
          return const CanonicalEqScorer().score(
            bank: bank,
            responses: _responses(session),
            clock: () => DateTime.utc(2026, 9, 2, 16),
          );
        },
    persistAssessment: ({
      required result,
      required ownerUid,
      required sessionId,
      required locale,
      required language,
      startedAt,
    }) async {
      if (persistAssessment != null) await persistAssessment();
    },
    persistCanonical: ({
      required result,
      required ownerUid,
      required sessionId,
      required locale,
      required language,
    }) async {
      if (persistCanonical != null) await persistCanonical();
    },
    markEqCompleted: () async {
      if (markCompleted != null) await markCompleted();
    },
    markRemoteFinalized: (sessionId) {
      return manager.markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
    },
    currentUid: () => uid,
  );
}

AssessmentProgressSnapshot _frequencyProgress() {
  return const AssessmentProgressSnapshot(
    assessmentFlowVersion: AssessmentProgressSnapshot.flowVersionV2,
    iqStatus: AssessmentModuleStatus.completed,
    eqStatus: AssessmentModuleStatus.completed,
    frequencyStatus: AssessmentModuleStatus.notStarted,
    frequencyCompleted: false,
    frequencyIncomplete: false,
    iqCompleted: true,
    eqCompleted: true,
    allAssessmentsCompleted: false,
    assessmentFlowCompleted: false,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: AssessmentFlowDestination.frequency,
    resolutionSource: 'test',
    reason: null,
  );
}

void main() {
  late EqCanonicalBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test(
      'success order: finalizeEq then score, assessments/eq, canonical, mirrors, local finalize',
      () async {
    const uid = 'uid_eq_ok';
    final built = await _pending(bank: bank, uid: uid, seed: 'ok-seed');
    final steps = <String>[];
    String? calledSession;
    Map<String, dynamic>? capturedScore;
    final pipeline = EqPendingFinalizationPipeline(
      finalizeClient: EqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeEq');
          calledSession = data['session_id'] as String?;
          expect(data['assessment_type'], 'eq');
          expect(data.containsKey('status'), isFalse);
          expect(data.containsKey('answered_at'), isFalse);
          expect(data.containsKey('score'), isFalse);
          expect(data.containsKey('eq_completed'), isFalse);
          expect(data.containsKey('test_completed'), isFalse);
          expect(steps, isEmpty);
          steps.add('finalizeEq');
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'eq',
            'idempotent': false,
          };
        },
      ),
      scoreCompleted: (session) async {
        expect(steps, ['finalizeEq']);
        steps.add('score');
        final scored = const CanonicalEqScorer().score(
          bank: bank,
          responses: _responses(session),
          clock: () => DateTime.utc(2026, 9, 2, 16),
        );
        capturedScore = scored.result!.toJson();
        return scored;
      },
      persistAssessment: ({
        required result,
        required ownerUid,
        required sessionId,
        required locale,
        required language,
        startedAt,
      }) async {
        expect(steps, ['finalizeEq', 'score']);
        expect(sessionId, built.sid);
        steps.add('persistAssessment');
      },
      persistCanonical: ({
        required result,
        required ownerUid,
        required sessionId,
        required locale,
        required language,
      }) async {
        expect(steps, ['finalizeEq', 'score', 'persistAssessment']);
        expect(sessionId, built.sid);
        steps.add('persistCanonical');
      },
      markEqCompleted: () async => steps.add('markEqCompleted'),
      markRemoteFinalized: (sessionId) {
        expect(
          steps,
          [
            'finalizeEq',
            'score',
            'persistAssessment',
            'persistCanonical',
            'markEqCompleted',
          ],
        );
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

    expect(calledSession, built.sid);
    expect(outcome.navigateToFrequency, isTrue);
    expect(outcome.finalize!.status, 'verified');
    expect(outcome.finalize!.idempotent, isFalse);
    expect(steps, [
      'finalizeEq',
      'score',
      'persistAssessment',
      'persistCanonical',
      'markEqCompleted',
    ]);
    expect(outcome.completedSteps, [
      EqPendingPipelineStep.finalizeEq,
      EqPendingPipelineStep.score,
      EqPendingPipelineStep.persistAssessment,
      EqPendingPipelineStep.persistCanonical,
      EqPendingPipelineStep.markEqCompleted,
      EqPendingPipelineStep.markRemoteFinalized,
    ]);

    final expected = const CanonicalEqScorer()
        .score(
          bank: bank,
          responses: _responses(built.session),
          clock: () => DateTime.utc(2026, 9, 2, 16),
        )
        .result!
        .toJson();
    expect(capturedScore, expected);
    expect(expected['overall_eq_score'], isNull);
    expect(expected['schema_version'], EqScoringContract.schemaVersion);

    final stored = await built.repo.loadSession(uid, built.sid);
    expect(stored.state!.status, EqPersistedSessionStatus.completed);
    expect(stored.state!.remoteFinalized, isTrue);
    expect(stored.state!.sessionId, built.sid);
    expect((await built.repo.loadActiveSession(uid)).isLoaded, isFalse);
  });

  test('network failure: no score persist, session stays pending', () async {
    const uid = 'uid_eq_net';
    final built = await _pending(bank: bank, uid: uid, seed: 'net-seed');
    var scored = false;
    var persisted = false;
    final pipeline = EqPendingFinalizationPipeline(
      finalizeClient: EqFinalizeCallableClient(
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
        return const CanonicalEqScorer().score(
          bank: bank,
          responses: _responses(session),
        );
      },
      persistAssessment: ({
        required result,
        required ownerUid,
        required sessionId,
        required locale,
        required language,
        startedAt,
      }) async {
        persisted = true;
      },
      persistCanonical: ({
        required result,
        required ownerUid,
        required sessionId,
        required locale,
        required language,
      }) async {
        persisted = true;
      },
      markEqCompleted: () async => persisted = true,
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

    expect(outcome.navigateToFrequency, isFalse);
    expect(outcome.failureKind, EqFinalizeFailureKind.retryable);
    expect(scored, isFalse);
    expect(persisted, isFalse);
    expect(outcome.completedSteps, isEmpty);
    final active = await built.repo.loadActiveSession(uid);
    expect(
      active.state!.status,
      EqPersistedSessionStatus.completedPendingPersistence,
    );
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 30);
    expect(active.state!.itemPlans.length, 30);
    expect(active.state!.remoteFinalized, isFalse);
  });

  test('lost response then idempotent retry completes once', () async {
    const uid = 'uid_eq_lost';
    final built = await _pending(bank: bank, uid: uid, seed: 'lost-seed');
    var calls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeEq');
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
            'flow': 'eq',
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
    expect(first.navigateToFrequency, isFalse);
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
    expect(second.navigateToFrequency, isTrue);
    expect(second.finalize!.idempotent, isTrue);
    expect(calls, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
  });

  test('CASE 1: server succeeds, scoring fails, retry scores same session',
      () async {
    const uid = 'uid_eq_crash_score';
    final built = await _pending(bank: bank, uid: uid, seed: 'crash-score');
    var scoreCalls = 0;
    var persistCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (_, data) async {
          expect(data['session_id'], built.sid);
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'eq',
            'idempotent': scoreCalls > 0,
          };
        },
      ),
      persistAssessment: () async => persistCalls++,
      score: (session) async {
        scoreCalls++;
        if (scoreCalls == 1) {
          return const EqScoringOutcome.fail(
            code: EqScoringFailureCode.validationFailed,
            message: 'simulated crash before score persist',
          );
        }
        return const CanonicalEqScorer().score(
          bank: bank,
          responses: _responses(session),
          clock: () => DateTime.utc(2026, 9, 2, 16),
        );
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToFrequency, isFalse);
    expect(first.completedSteps, [EqPendingPipelineStep.finalizeEq]);
    expect(persistCalls, 0);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      EqPersistedSessionStatus.completedPendingPersistence,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToFrequency, isTrue);
    expect(scoreCalls, 2);
    expect(persistCalls, 1);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
  });

  test(
      'CASE 2/3: persist assessment then canonical crash; replay is safe',
      () async {
    const uid = 'uid_eq_partial';
    final built = await _pending(bank: bank, uid: uid, seed: 'partial-seed');
    var assessmentWrites = 0;
    var canonicalWrites = 0;
    var finalizeCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeEq');
          expect(data['session_id'], built.sid);
          finalizeCalls++;
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'eq',
            'idempotent': finalizeCalls > 1,
          };
        },
      ),
      persistAssessment: () async => assessmentWrites++,
      persistCanonical: () async {
        canonicalWrites++;
        if (canonicalWrites == 1) {
          throw StateError('canonical write failed');
        }
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToFrequency, isFalse);
    expect(first.completedSteps, [
      EqPendingPipelineStep.finalizeEq,
      EqPendingPipelineStep.score,
      EqPendingPipelineStep.persistAssessment,
    ]);
    expect(assessmentWrites, 1);
    expect(canonicalWrites, 1);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.remoteFinalized,
      isFalse,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToFrequency, isTrue);
    expect(retry.finalize!.idempotent, isTrue);
    expect(assessmentWrites, 2);
    expect(canonicalWrites, 2);
    expect(finalizeCalls, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.status,
      EqPersistedSessionStatus.completed,
    );
  });

  test(
      'CASE 4: pending wins over eq_completed; retry same session then local finalize',
      () async {
    const uid = 'uid_eq_persist_fail';
    final built =
        await _pending(bank: bank, uid: uid, seed: 'persist-fail-seed');
    var persistAttempts = 0;
    var finalizeCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeEq');
          expect(data['session_id'], built.sid);
          finalizeCalls++;
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'eq',
            'idempotent': finalizeCalls > 1,
          };
        },
      ),
      persistAssessment: () async {
        persistAttempts++;
        if (persistAttempts == 1) {
          throw StateError('assessments/eq write failed');
        }
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToFrequency, isFalse);
    expect(first.completedSteps, [
      EqPendingPipelineStep.finalizeEq,
      EqPendingPipelineStep.score,
    ]);

    final decision = await AssessmentColdStartPendingReconciler(
      iqRepository: IqSessionMemoryRepository(),
      eqRepository: built.repo,
      frequencyRepository: FrequencySessionMemoryRepository(),
    ).reconcile(uid: uid, progress: _frequencyProgress());

    expect(decision.destination, AssessmentFlowDestination.eq);
    expect(decision.openAssessmentTestScreen, isTrue);
    expect(decision.reason, 'eq_pending_finalization');
    expect(
      (await built.repo.loadActiveSession(uid)).state!.remoteFinalized,
      isFalse,
    );
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      EqPersistedSessionStatus.completedPendingPersistence,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToFrequency, isTrue);
    expect(retry.finalize!.idempotent, isTrue);
    expect(finalizeCalls, 2);
    expect(persistAttempts, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
    expect((await built.repo.loadActiveSession(uid)).isLoaded, isFalse);
  });

  test('invalid-argument retains answers and does not score', () async {
    const uid = 'uid_eq_invalid';
    final built = await _pending(bank: bank, uid: uid, seed: 'invalid-seed');
    var persist = false;
    var scored = false;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'structurally incomplete secret',
            code: 'invalid-argument',
          );
        },
      ),
      persistAssessment: () async => persist = true,
      score: (session) async {
        scored = true;
        return const CanonicalEqScorer().score(
          bank: bank,
          responses: _responses(session),
        );
      },
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(outcome.navigateToFrequency, isFalse);
    expect(outcome.failureKind, EqFinalizeFailureKind.nonRetryableSession);
    expect(persist, isFalse);
    expect(scored, isFalse);
    final active = await built.repo.loadActiveSession(uid);
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 30);
    expect(
      active.state!.status,
      EqPersistedSessionStatus.completedPendingPersistence,
    );
  });

  test('EQ_ALREADY_VERIFIED retains evidence and does not retake', () async {
    const uid = 'uid_eq_verified';
    final built = await _pending(bank: bank, uid: uid, seed: 'verified-seed');
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: EqFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'already verified secret',
            code: 'failed-precondition',
            details: {'code': 'EQ_ALREADY_VERIFIED'},
          );
        },
      ),
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(outcome.navigateToFrequency, isFalse);
    expect(outcome.failureKind, EqFinalizeFailureKind.accountInconsistency);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.sessionId,
      built.sid,
    );
    final resumed = await built.manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: 'retake-must-not-happen',
    );
    expect(resumed.state!.sessionId, built.sid);
    expect(built.manager.lastOperationComposed, isFalse);
  });

  test('EQTestScreen owns pending retry; navigation and Discover stay unchanged',
      () {
    final eq = File('lib/features/assessment/screens/eq_test_screen.dart')
        .readAsStringSync();
    expect(eq.contains('_runPendingFinalizationPipeline'), isTrue);
    expect(eq.contains('_schedulePendingPipelineOnce'), isTrue);
    expect(eq.contains('_didAutoRetryPending'), isTrue);
    expect(eq.contains('_pipelineInFlight'), isTrue);
    expect(eq.contains('EqPendingFinalizationPipeline'), isTrue);
    expect(eq.contains('FrequencyIntroScreen'), isTrue);
    expect(eq.contains('test_completed'), isFalse);
    expect(eq.contains('assessment_flow_completed'), isFalse);
    expect(eq.contains('discover_eligible'), isFalse);
    expect(eq.contains('_finalizeRemoteAndNavigate'), isFalse);

    final pipelineSrc = File(
      'lib/features/assessment/services/eq_pending_finalization_pipeline.dart',
    ).readAsStringSync();
    expect(pipelineSrc.contains('scoreCompleted'), isTrue);
    expect(pipelineSrc.contains('markEqCompleted'), isTrue);
    expect(pipelineSrc.contains('EqTo20dRuntimeAdapter'), isTrue);
    expect(pipelineSrc.contains('test_completed'), isFalse);
    expect(pipelineSrc.contains('assessment_flow_completed'), isFalse);
    expect(pipelineSrc.contains('discover_eligible'), isFalse);
    expect(pipelineSrc.contains('finalizeFrequencyV2'), isFalse);

    final freq =
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .readAsStringSync();
    expect(freq.contains('finalizeEq'), isFalse);
    expect(freq.contains('EqPendingFinalizationPipeline'), isFalse);

    final reconciler = File(
      'lib/features/assessment/services/assessment_cold_start_pending_reconciler.dart',
    ).readAsStringSync();
    expect(reconciler.contains('_tryFinalizeEq'), isFalse);
    expect(reconciler.contains('EqFinalizeCallableClient'), isFalse);

    final v2Head = File(
      'functions/src/frequency_behavior_v2_catalog_v1.generated.js',
    ).openSync();
    try {
      final head = String.fromCharCodes(v2Head.readSync(512));
      expect(head.contains('"runtime_selectable": false'), isTrue);
      expect(head.contains('"runtime_selectable": true'), isFalse);
    } finally {
      v2Head.closeSync();
    }
  });
}
