import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_scoring/frequency_scoring.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/frequency_finalize_callable_client.dart';
import 'package:qmatch/features/assessment/services/frequency_pending_finalization_pipeline.dart';

FrequencyCanonicalBankDocument _loadBank() {
  return FrequencyCanonicalBankDocument.fromJson(
    jsonDecode(File(FrequencyBankContract.trAssetPath).readAsStringSync())
        as Map<String, dynamic>,
  );
}

List<FrequencyCanonicalResponse> _responses(
  FrequencyPersistedSessionState session,
) {
  return [
    for (final p in session.itemPlans)
      FrequencyCanonicalResponse(
        itemId: p.itemId,
        optionId: session.answersByItemId[p.itemId]!.selectedOptionId,
      ),
  ];
}

Future<
    ({
      FrequencyPersistedSessionState session,
      FrequencySessionManager manager,
      FrequencySessionMemoryRepository repo,
      String sid,
    })> _pending({
  required FrequencyCanonicalBankDocument bank,
  required String uid,
  required String seed,
  int idSeed = 31,
}) async {
  final repo = FrequencySessionMemoryRepository();
  final manager = FrequencySessionManager(
    bank: bank,
    repository: repo,
    idFactory: FrequencySessionIdFactory(random: Random(idSeed)),
    shuffleRandom: Random(seed.hashCode),
    clock: () => DateTime.utc(2026, 9, 3, 16),
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
    FrequencyPersistedSessionStatus.completedPendingPersistence,
  );
  return (
    session: completed.state!,
    manager: manager,
    repo: repo,
    sid: sid,
  );
}

FrequencyPendingFinalizationPipeline _pipeline({
  required FrequencyCanonicalBankDocument bank,
  required FrequencySessionManager manager,
  required String uid,
  required FrequencyFinalizeCallableClient client,
  Future<void> Function()? persistAssessment,
  Future<void> Function()? persistCanonical,
  Future<FrequencySessionWriteResult> Function(String sessionId)?
      markRemoteFinalized,
  Future<FrequencyScoringOutcome> Function(FrequencyPersistedSessionState session)?
      score,
}) {
  return FrequencyPendingFinalizationPipeline(
    finalizeClient: client,
    scoreCompleted: score ??
        (session) async {
          return const CanonicalFrequencyScorer().score(
            bank: bank,
            responses: _responses(session),
            clock: () => DateTime.utc(2026, 9, 3, 16),
          );
        },
    persistAssessment: ({
      required result,
      required session,
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
    markRemoteFinalized: markRemoteFinalized ??
        (sessionId) {
          return manager.markRemoteFinalized(
            ownerUid: uid,
            sessionId: sessionId,
          );
        },
    currentUid: () => uid,
  );
}

AssessmentProgressSnapshot _completedProgress() {
  return const AssessmentProgressSnapshot(
    assessmentFlowVersion: AssessmentProgressSnapshot.flowVersionV2,
    iqStatus: AssessmentModuleStatus.completed,
    eqStatus: AssessmentModuleStatus.completed,
    frequencyStatus: AssessmentModuleStatus.completed,
    frequencyCompleted: true,
    frequencyIncomplete: false,
    iqCompleted: true,
    eqCompleted: true,
    allAssessmentsCompleted: true,
    assessmentFlowCompleted: true,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: AssessmentFlowDestination.profileSetup,
    resolutionSource: 'test',
    reason: null,
  );
}

void main() {
  late FrequencyCanonicalBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  test(
      'success order: finalizeFrequency then score, assessments/frequency, canonical, local finalize',
      () async {
    const uid = 'uid_freq_ok';
    final built = await _pending(bank: bank, uid: uid, seed: 'ok-seed');
    final steps = <String>[];
    String? calledSession;
    Map<String, dynamic>? capturedScore;
    final pipeline = FrequencyPendingFinalizationPipeline(
      finalizeClient: FrequencyFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeFrequency');
          calledSession = data['session_id'] as String?;
          expect(data['assessment_type'], 'frequency');
          expect(data.containsKey('status'), isFalse);
          expect(data.containsKey('answered_at'), isFalse);
          expect(data.containsKey('score'), isFalse);
          expect(data.containsKey('frequency_completed'), isFalse);
          expect(data.containsKey('test_completed'), isFalse);
          expect(data.containsKey('item_role'), isFalse);
          expect(steps, isEmpty);
          steps.add('finalizeFrequency');
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'frequency',
            'idempotent': false,
          };
        },
      ),
      scoreCompleted: (session) async {
        expect(steps, ['finalizeFrequency']);
        steps.add('score');
        final scored = const CanonicalFrequencyScorer().score(
          bank: bank,
          responses: _responses(session),
          clock: () => DateTime.utc(2026, 9, 3, 16),
        );
        capturedScore = scored.result!.toJson();
        return scored;
      },
      persistAssessment: ({
        required result,
        required session,
        required ownerUid,
        required sessionId,
        required locale,
        required language,
        startedAt,
      }) async {
        expect(steps, ['finalizeFrequency', 'score']);
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
        expect(steps, ['finalizeFrequency', 'score', 'persistAssessment']);
        expect(sessionId, built.sid);
        steps.add('persistCanonical');
      },
      markRemoteFinalized: (sessionId) {
        expect(
          steps,
          [
            'finalizeFrequency',
            'score',
            'persistAssessment',
            'persistCanonical',
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
    expect(outcome.navigateToPersona, isTrue);
    expect(outcome.finalize!.status, 'verified');
    expect(outcome.finalize!.idempotent, isFalse);
    expect(steps, [
      'finalizeFrequency',
      'score',
      'persistAssessment',
      'persistCanonical',
    ]);
    expect(outcome.completedSteps, [
      FrequencyPendingPipelineStep.finalizeFrequency,
      FrequencyPendingPipelineStep.score,
      FrequencyPendingPipelineStep.persistAssessment,
      FrequencyPendingPipelineStep.persistCanonical,
      FrequencyPendingPipelineStep.markRemoteFinalized,
    ]);

    final expected = const CanonicalFrequencyScorer()
        .score(
          bank: bank,
          responses: _responses(built.session),
          clock: () => DateTime.utc(2026, 9, 3, 16),
        )
        .result!
        .toJson();
    expect(capturedScore, expected);
    expect(expected['overall_frequency_score'], isNull);
    expect(expected['schema_version'], FrequencyScoringContract.schemaVersion);
    expect(
      expected['scoring_policy_version'],
      FrequencyScoringContract.scoringPolicyVersion,
    );
    final dimIds = [
      for (final d in expected['dimension_scores'] as List)
        (d as Map)['dimension_id'],
    ];
    expect(dimIds, FrequencyCanonicalDimensions.all);

    final stored = await built.repo.loadSession(uid, built.sid);
    expect(stored.state!.status, FrequencyPersistedSessionStatus.completed);
    expect(stored.state!.remoteFinalized, isTrue);
    expect(stored.state!.sessionId, built.sid);
    expect((await built.repo.loadActiveSession(uid)).isLoaded, isFalse);
  });

  test('network failure: no score persist, session stays pending', () async {
    const uid = 'uid_freq_net';
    final built = await _pending(bank: bank, uid: uid, seed: 'net-seed');
    var scored = false;
    var persisted = false;
    final pipeline = FrequencyPendingFinalizationPipeline(
      finalizeClient: FrequencyFinalizeCallableClient(
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
        return const CanonicalFrequencyScorer().score(
          bank: bank,
          responses: _responses(session),
        );
      },
      persistAssessment: ({
        required result,
        required session,
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

    expect(outcome.navigateToPersona, isFalse);
    expect(outcome.failureKind, FrequencyFinalizeFailureKind.retryable);
    expect(scored, isFalse);
    expect(persisted, isFalse);
    expect(outcome.completedSteps, isEmpty);
    final active = await built.repo.loadActiveSession(uid);
    expect(
      active.state!.status,
      FrequencyPersistedSessionStatus.completedPendingPersistence,
    );
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 50);
    expect(active.state!.itemPlans.length, 50);
    expect(active.state!.remoteFinalized, isFalse);
  });

  test('lost response then idempotent retry completes once', () async {
    const uid = 'uid_freq_lost';
    final built = await _pending(bank: bank, uid: uid, seed: 'lost-seed');
    var calls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeFrequency');
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
            'flow': 'frequency',
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
    expect(first.navigateToPersona, isFalse);
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
    expect(second.navigateToPersona, isTrue);
    expect(second.finalize!.idempotent, isTrue);
    expect(calls, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
  });

  test('CASE 1: server succeeds, scoring fails, retry scores same session',
      () async {
    const uid = 'uid_freq_crash_score';
    final built = await _pending(bank: bank, uid: uid, seed: 'crash-score');
    var scoreCalls = 0;
    var persistCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (_, data) async {
          expect(data['session_id'], built.sid);
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'frequency',
            'idempotent': scoreCalls > 0,
          };
        },
      ),
      persistAssessment: () async => persistCalls++,
      score: (session) async {
        scoreCalls++;
        if (scoreCalls == 1) {
          return const FrequencyScoringOutcome.fail(
            code: FrequencyScoringFailureCode.validationFailed,
            message: 'simulated crash before score persist',
          );
        }
        return const CanonicalFrequencyScorer().score(
          bank: bank,
          responses: _responses(session),
          clock: () => DateTime.utc(2026, 9, 3, 16),
        );
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToPersona, isFalse);
    expect(first.completedSteps, [FrequencyPendingPipelineStep.finalizeFrequency]);
    expect(persistCalls, 0);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      FrequencyPersistedSessionStatus.completedPendingPersistence,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToPersona, isTrue);
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
    const uid = 'uid_freq_partial';
    final built = await _pending(bank: bank, uid: uid, seed: 'partial-seed');
    var assessmentWrites = 0;
    var canonicalWrites = 0;
    var finalizeCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeFrequency');
          expect(data['session_id'], built.sid);
          finalizeCalls++;
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'frequency',
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
    expect(first.navigateToPersona, isFalse);
    expect(first.completedSteps, [
      FrequencyPendingPipelineStep.finalizeFrequency,
      FrequencyPendingPipelineStep.score,
      FrequencyPendingPipelineStep.persistAssessment,
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
    expect(retry.navigateToPersona, isTrue);
    expect(retry.finalize!.idempotent, isTrue);
    expect(assessmentWrites, 2);
    expect(canonicalWrites, 2);
    expect(finalizeCalls, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.status,
      FrequencyPersistedSessionStatus.completed,
    );
  });

  test(
      'CASE 4: pending wins over frequency_completed; retry same session then local finalize',
      () async {
    const uid = 'uid_freq_persist_fail';
    final built =
        await _pending(bank: bank, uid: uid, seed: 'persist-fail-seed');
    var persistAttempts = 0;
    var finalizeCalls = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (name, data) async {
          expect(name, 'finalizeFrequency');
          expect(data['session_id'], built.sid);
          finalizeCalls++;
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'frequency',
            'idempotent': finalizeCalls > 1,
          };
        },
      ),
      persistAssessment: () async {
        persistAttempts++;
        if (persistAttempts == 1) {
          throw StateError('assessments/frequency write failed');
        }
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToPersona, isFalse);
    expect(first.completedSteps, [
      FrequencyPendingPipelineStep.finalizeFrequency,
      FrequencyPendingPipelineStep.score,
    ]);

    final decision = await AssessmentColdStartPendingReconciler(
      iqRepository: IqSessionMemoryRepository(),
      eqRepository: EqSessionMemoryRepository(),
      frequencyRepository: built.repo,
    ).reconcile(uid: uid, progress: _completedProgress());

    expect(decision.destination, AssessmentFlowDestination.frequency);
    expect(decision.openAssessmentTestScreen, isTrue);
    expect(decision.reason, 'frequency_pending_finalization');
    expect(
      (await built.repo.loadActiveSession(uid)).state!.remoteFinalized,
      isFalse,
    );
    expect(
      (await built.repo.loadActiveSession(uid)).state!.status,
      FrequencyPersistedSessionStatus.completedPendingPersistence,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToPersona, isTrue);
    expect(retry.finalize!.idempotent, isTrue);
    expect(finalizeCalls, 2);
    expect(persistAttempts, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
    expect((await built.repo.loadActiveSession(uid)).isLoaded, isFalse);
  });

  test(
      'CASE 5: canonical persisted then markRemoteFinalized fails; pending remains',
      () async {
    const uid = 'uid_freq_local_fail';
    final built = await _pending(bank: bank, uid: uid, seed: 'local-fail');
    var localAttempts = 0;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (_, data) async {
          expect(data['session_id'], built.sid);
          return {
            'ok': true,
            'status': 'verified',
            'flow': 'frequency',
            'idempotent': localAttempts > 0,
          };
        },
      ),
      markRemoteFinalized: (sessionId) async {
        localAttempts++;
        if (localAttempts == 1) {
          return const FrequencySessionWriteResult(
            ok: false,
            code: 'simulated_crash',
            message: 'crash before local finalize',
          );
        }
        return built.manager.markRemoteFinalized(
          ownerUid: uid,
          sessionId: sessionId,
        );
      },
    );

    final first = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(first.navigateToPersona, isFalse);
    expect(first.completedSteps, [
      FrequencyPendingPipelineStep.finalizeFrequency,
      FrequencyPendingPipelineStep.score,
      FrequencyPendingPipelineStep.persistAssessment,
      FrequencyPendingPipelineStep.persistCanonical,
    ]);
    expect(
      (await built.repo.loadActiveSession(uid)).state!.remoteFinalized,
      isFalse,
    );

    final retry = await pipeline.run(
      session: (await built.repo.loadActiveSession(uid)).state!,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(retry.navigateToPersona, isTrue);
    expect(localAttempts, 2);
    expect(
      (await built.repo.loadSession(uid, built.sid)).state!.remoteFinalized,
      isTrue,
    );
  });

  test('invalid-argument retains answers and does not score', () async {
    const uid = 'uid_freq_invalid';
    final built = await _pending(bank: bank, uid: uid, seed: 'invalid-seed');
    var persist = false;
    var scored = false;
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
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
        return const CanonicalFrequencyScorer().score(
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
    expect(outcome.navigateToPersona, isFalse);
    expect(
      outcome.failureKind,
      FrequencyFinalizeFailureKind.nonRetryableSession,
    );
    expect(persist, isFalse);
    expect(scored, isFalse);
    final active = await built.repo.loadActiveSession(uid);
    expect(active.state!.sessionId, built.sid);
    expect(active.state!.answers.length, 50);
    expect(
      active.state!.status,
      FrequencyPersistedSessionStatus.completedPendingPersistence,
    );
  });

  test('FREQUENCY_ALREADY_VERIFIED retains evidence and does not retake',
      () async {
    const uid = 'uid_freq_verified';
    final built = await _pending(bank: bank, uid: uid, seed: 'verified-seed');
    final pipeline = _pipeline(
      bank: bank,
      manager: built.manager,
      uid: uid,
      client: FrequencyFinalizeCallableClient(
        call: (_, __) async {
          // ignore: invalid_use_of_protected_member
          throw FirebaseFunctionsException(
            message: 'already verified secret',
            code: 'failed-precondition',
            details: {'code': 'FREQUENCY_ALREADY_VERIFIED'},
          );
        },
      ),
    );

    final outcome = await pipeline.run(
      session: built.session,
      locale: 'tr-TR',
      language: 'tr',
    );
    expect(outcome.navigateToPersona, isFalse);
    expect(
      outcome.failureKind,
      FrequencyFinalizeFailureKind.accountInconsistency,
    );
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

  test(
      'FrequencyTestScreen owns pending retry; navigation, Discover, V2 unchanged',
      () {
    final freq =
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .readAsStringSync();
    expect(freq.contains('_runPendingFinalizationPipeline'), isTrue);
    expect(freq.contains('_schedulePendingPipelineOnce'), isTrue);
    expect(freq.contains('_didAutoRetryPending'), isTrue);
    expect(freq.contains('_pipelineInFlight'), isTrue);
    expect(freq.contains('FrequencyPendingFinalizationPipeline'), isTrue);
    expect(freq.contains('PersonaAssignmentGateScreen'), isTrue);
    expect(freq.contains('discover_eligible'), isTrue);
    expect(freq.contains("discover_eligible'"), isFalse);
    expect(freq.contains('_finalizeRemoteAndNavigate'), isFalse);
    expect(freq.contains('finalizeFrequencyV2'), isFalse);
    expect(freq.contains('AssessmentFlowCompleteScreen'), isFalse);

    final pipelineSrc = File(
      'lib/features/assessment/services/frequency_pending_finalization_pipeline.dart',
    ).readAsStringSync();
    expect(pipelineSrc.contains('scoreCompleted'), isTrue);
    expect(pipelineSrc.contains('markAssessmentFlowCompleted'), isFalse);
    expect(pipelineSrc.contains('FrequencyTo20dRuntimeAdapter'), isTrue);
    expect(pipelineSrc.contains('buildCanonicalFrequency6dPayload'), isTrue);
    expect(pipelineSrc.contains('ensureIq4AndEq10'), isTrue);
    expect(pipelineSrc.contains('discover_eligible'), isFalse);
    expect(pipelineSrc.contains('finalizeFrequencyV2'), isFalse);
    expect(pipelineSrc.contains('depth_preference'), isFalse);

    final mapperSrc = File(
      'lib/features/assessment/domain/frequency_session/frequency_finalize_request_mapper.dart',
    ).readAsStringSync();
    expect(mapperSrc.contains('displayedOptionIds'), isTrue);
    expect(mapperSrc.contains('selectedOptionId'), isTrue);
    expect(mapperSrc.contains("'item_role'"), isFalse);

    final reconciler = File(
      'lib/features/assessment/services/assessment_cold_start_pending_reconciler.dart',
    ).readAsStringSync();
    expect(reconciler.contains('_tryFinalizeFrequency'), isFalse);
    expect(reconciler.contains('FrequencyFinalizeCallableClient'), isFalse);

    final progress = File(
      'lib/features/assessment/services/assessment_progress_service.dart',
    ).readAsStringSync();
    expect(progress.contains('markAssessmentFlowCompleted'), isTrue);
    expect(progress.contains("'frequency_completed': true"), isTrue);
    expect(progress.contains("'assessment_flow_completed': true"), isFalse);
    expect(progress.contains("'test_completed': true"), isFalse);

    final adapter = File(
      'lib/features/assessment/domain/profile/frequency_to_20d_runtime_adapter.dart',
    ).readAsStringSync();
    expect(adapter.contains('FrequencyCanonicalDimensions.all'), isTrue);
    expect(adapter.contains('acceptedFrequencyScoringPolicies'), isTrue);

    final taxonomy = File(
      'lib/features/assessment/domain/frequency_bank/frequency_canonical_dimensions.dart',
    ).readAsStringSync();
    expect(taxonomy.contains("'depth_preference'"), isTrue);
    expect(taxonomy.contains("'social_energy'"), isTrue);
    expect(taxonomy.contains("'spontaneity'"), isTrue);
    expect(taxonomy.contains("'stability'"), isTrue);
    expect(taxonomy.contains("'disclosure_pace'"), isTrue);
    expect(taxonomy.contains("'communication_pace'"), isTrue);

    final discover = File('functions/src/discover_eligibility.js')
        .readAsStringSync();
    expect(discover.contains('discover_eligible'), isTrue);

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
