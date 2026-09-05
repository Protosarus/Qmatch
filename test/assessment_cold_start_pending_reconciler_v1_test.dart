import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/navigation/assessment_progress_route_gate.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_v2_contract.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/screens/frequency_v2_test_screen.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';
import 'package:qmatch/features/assessment/services/assessment_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AssessmentProgressSnapshot _progress({
  required AssessmentFlowDestination destination,
  bool iqCompleted = false,
  bool eqCompleted = false,
  bool frequencyCompleted = false,
  bool assessmentFlowCompleted = false,
}) {
  return AssessmentProgressSnapshot(
    assessmentFlowVersion: AssessmentProgressSnapshot.flowVersionV2,
    iqStatus: iqCompleted
        ? AssessmentModuleStatus.completed
        : AssessmentModuleStatus.notStarted,
    eqStatus: eqCompleted
        ? AssessmentModuleStatus.completed
        : AssessmentModuleStatus.notStarted,
    frequencyStatus: frequencyCompleted
        ? AssessmentModuleStatus.completed
        : AssessmentModuleStatus.notStarted,
    frequencyCompleted: frequencyCompleted,
    frequencyIncomplete: false,
    iqCompleted: iqCompleted,
    eqCompleted: eqCompleted,
    allAssessmentsCompleted: iqCompleted && eqCompleted && frequencyCompleted,
    assessmentFlowCompleted: assessmentFlowCompleted,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: destination,
    resolutionSource: 'test',
    reason: null,
  );
}

AssessmentColdStartPendingReconciler _reconciler({
  IqSessionPersistenceRepository? iqRepository,
  EqSessionPersistenceRepository? eqRepository,
  FrequencySessionPersistenceRepository? frequencyRepository,
  FrequencyV2SessionPersistenceRepository? frequencyV2Repository,
  Future<EqCanonicalBankDocument> Function(String bankLocale)? loadEqBank,
  Future<FrequencyCanonicalBankDocument> Function(String bankLocale)?
      loadFrequencyBank,
}) {
  return AssessmentColdStartPendingReconciler(
    iqRepository: iqRepository ?? IqSessionMemoryRepository(),
    eqRepository: eqRepository ?? EqSessionMemoryRepository(),
    frequencyRepository:
        frequencyRepository ?? FrequencySessionMemoryRepository(),
    frequencyV2Repository:
        frequencyV2Repository ?? FrequencyV2SessionMemoryRepository(),
    loadEqBank: loadEqBank,
    loadFrequencyBank: loadFrequencyBank,
  );
}

FrequencyV2PersistedSessionState _v2Session({
  required String uid,
  required FrequencyV2PersistedSessionStatus status,
  String sessionId = 'frequency_v2_sess_test',
  bool remoteFinalized = false,
}) {
  return FrequencyV2PersistedSessionState(
    schemaVersion: FrequencyV2RuntimeContract.persistedSchemaVersion,
    sessionId: sessionId,
    ownerUid: uid,
    sessionSeed: 'cold-v2',
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    bankLocale: FrequencyBehaviorV2Contract.localeTr,
    selectionPolicyVersion: FrequencyBehaviorV2Contract.selectionPolicyVersion,
    selectorVersion: FrequencyBehaviorV2Contract.selectorVersion,
    itemPlans: const [],
    currentQuestionIndex: 0,
    answers: const [],
    startedAt: '2026-09-05T00:00:00.000Z',
    updatedAt: '2026-09-05T00:00:00.000Z',
    completedAt: '2026-09-05T00:00:00.000Z',
    status: status,
    remoteFinalized: remoteFinalized,
  );
}

Map<String, dynamic> _validFrequencyV2() {
  return {
    'schema_version': FrequencyV2ResultAuthority.resultSchemaVersion,
    'assessment_type': FrequencyV2ResultAuthority.assessmentType,
    'status': FrequencyV2ResultAuthority.resultStatus,
    'source': FrequencyV2ResultAuthority.resultSource,
    'dimensions': [
      for (final id in FrequencyBehaviorV2Contract.canonicalDimensions)
        {
          'dimension_id': id,
          'normalized_behavior': 0.1,
          'provisional_confidence': 1,
          'confidence_completeness': 1,
        },
    ],
  };
}

class _CorruptV2Repo implements FrequencyV2SessionPersistenceRepository {
  @override
  Future<void> saveSession(FrequencyV2PersistedSessionState state) async {}

  @override
  Future<FrequencyV2SessionLoadResult> loadActiveSession(
    String ownerUid,
  ) async {
    return const FrequencyV2SessionLoadResult(
      code: FrequencyV2SessionLoadCode.corrupt,
      message: 'Malformed persisted V2 session',
    );
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    return loadActiveSession(ownerUid);
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {}
}

void main() {
  group('AssessmentColdStartPendingReconciler.decide', () {
    test('no pending → preserves progress destination', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: false,
        eqPendingFinalization: false,
        frequencyPendingFinalization: false,
        progressDestination: AssessmentFlowDestination.eq,
      );
      expect(d.destination, AssessmentFlowDestination.eq);
      expect(d.openAssessmentTestScreen, isFalse);
      expect(d.reason, 'progress_routing');
    });

    test('IQ pending blocks EQ progress route', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: true,
        eqPendingFinalization: false,
        frequencyPendingFinalization: false,
        progressDestination: AssessmentFlowDestination.eq,
      );
      expect(d.destination, AssessmentFlowDestination.iq);
      expect(d.openAssessmentTestScreen, isTrue);
      expect(d.reason, 'iq_pending_finalization');
    });

    test('EQ pending blocks Frequency progress route', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: false,
        eqPendingFinalization: true,
        frequencyPendingFinalization: false,
        progressDestination: AssessmentFlowDestination.frequency,
      );
      expect(d.destination, AssessmentFlowDestination.eq);
      expect(d.openAssessmentTestScreen, isTrue);
    });

    test('stale V1 Frequency pending does not reopen Frequency', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: false,
        eqPendingFinalization: false,
        frequencyPendingFinalization: true,
        frequencyV2PendingFinalization: false,
        runtimeTrack: FrequencyRuntimeTrack.v2,
        progressDestination: AssessmentFlowDestination.profileSetup,
      );
      expect(d.destination, AssessmentFlowDestination.profileSetup);
      expect(d.openAssessmentTestScreen, isFalse);
      expect(d.reason, 'progress_routing');
    });

    test('V2 Frequency pending blocks profileSetup progress route', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: false,
        eqPendingFinalization: false,
        frequencyPendingFinalization: false,
        frequencyV2PendingFinalization: true,
        runtimeTrack: FrequencyRuntimeTrack.v2,
        progressDestination: AssessmentFlowDestination.profileSetup,
      );
      expect(d.destination, AssessmentFlowDestination.frequency);
      expect(d.openAssessmentTestScreen, isTrue);
      expect(d.reason, 'frequency_v2_pending_finalization');
    });
  });

  group('Cold-start crash-after-progress-before-local-finalize', () {
    late IqRecoveredBankDocument iqBank;
    late EqCanonicalBankDocument eqBank;
    late FrequencyCanonicalBankDocument frequencyBank;

    setUpAll(() {
      iqBank = IqRecoveredBankDocument.fromJson(
        jsonDecode(
          File('assets/data/assessment_v3/iq/iq_bank_tr_v1.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      eqBank = EqCanonicalBankDocument.fromJson(
        jsonDecode(File(EqBankContract.trAssetPath).readAsStringSync())
            as Map<String, dynamic>,
      );
      frequencyBank = FrequencyCanonicalBankDocument.fromJson(
        jsonDecode(File(FrequencyBankContract.trAssetPath).readAsStringSync())
            as Map<String, dynamic>,
      );
    });

    test(
        'IQ: remote iq_completed + local pending → hold IQ, do not local-finalize',
        () async {
      const uid = 'uid_cold_iq';
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: iqBank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(11)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-iq',
      );
      final sid = created.state!.sessionId;
      final byId = {for (final i in iqBank.items) i.id: i};
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: uid,
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: byId[p.itemId]!.correctOptionId,
        );
      }
      final pending = await manager.complete(ownerUid: uid, sessionId: sid);
      expect(
        pending.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );

      // Remote mirror may already be true (finalizeIq writes iq_completed).
      final progress = _progress(
        destination: AssessmentFlowDestination.eq,
        iqCompleted: true,
      );

      final eqRepo = EqSessionMemoryRepository();
      final freqRepo = FrequencySessionMemoryRepository();
      final reconciler = _reconciler(
        iqRepository: repo,
        eqRepository: eqRepo,
        frequencyRepository: freqRepo,
      );
      final decision = await reconciler.reconcile(uid: uid, progress: progress);

      final active = await repo.loadActiveSession(uid);
      expect(active.isLoaded, isTrue);
      expect(
        active.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(active.state!.sessionId, sid);
      expect(active.state!.remoteFinalized, isFalse);
      expect(active.state!.answers.length, 25);
      expect(decision.destination, AssessmentFlowDestination.iq);
      expect(decision.openAssessmentTestScreen, isTrue);
      expect(decision.reason, 'iq_pending_finalization');
    });

    test('EQ: remote progress complete + local pending → hold EQ test',
        () async {
      const uid = 'uid_cold_eq';
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: eqBank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(12)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-eq',
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
      await manager.complete(ownerUid: uid, sessionId: sid);

      final progress = _progress(
        destination: AssessmentFlowDestination.frequency,
        iqCompleted: true,
        eqCompleted: true,
      );

      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: repo,
        frequencyRepository: FrequencySessionMemoryRepository(),
        loadEqBank: (_) async => eqBank,
      ).reconcile(uid: uid, progress: progress);

      final active = await repo.loadActiveSession(uid);
      expect(active.isLoaded, isTrue);
      expect(
        active.state!.status,
        EqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(active.state!.sessionId, sid);
      expect(active.state!.remoteFinalized, isFalse);
      expect(active.state!.answers.length, 30);
      expect(decision.destination, AssessmentFlowDestination.eq);
      expect(decision.openAssessmentTestScreen, isTrue);
      expect(decision.reason, 'eq_pending_finalization');
    });

    test(
        'stale V1 Frequency pending is ignored even if remote frequency_completed',
        () async {
      const uid = 'uid_cold_freq';
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: frequencyBank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(13)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-freq',
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
      await manager.complete(ownerUid: uid, sessionId: sid);

      final progress = _progress(
        destination: AssessmentFlowDestination.profileSetup,
        iqCompleted: true,
        eqCompleted: true,
        frequencyCompleted: true,
        assessmentFlowCompleted: false,
      );

      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: repo,
        loadFrequencyBank: (_) async => frequencyBank,
      ).reconcile(uid: uid, progress: progress);

      final active = await repo.loadActiveSession(uid);
      expect(active.isLoaded, isTrue);
      expect(
        active.state!.status,
        FrequencyPersistedSessionStatus.completedPendingPersistence,
      );
      expect(active.state!.sessionId, sid);
      expect(active.state!.remoteFinalized, isFalse);
      expect(active.state!.answers.length, 50);
      expect(decision.destination, AssessmentFlowDestination.profileSetup);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test(
        'stale V1 Frequency pending is ignored even if assessment_flow_completed',
        () async {
      const uid = 'uid_cold_freq_flow';
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: frequencyBank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(17)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-freq-flow',
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
      await manager.complete(ownerUid: uid, sessionId: sid);

      final progress = _progress(
        destination: AssessmentFlowDestination.profileSetup,
        iqCompleted: true,
        eqCompleted: true,
        frequencyCompleted: false,
        assessmentFlowCompleted: true,
      );

      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: repo,
      ).reconcile(uid: uid, progress: progress);

      expect((await repo.loadActiveSession(uid)).isLoaded, isTrue);
      expect(
        (await repo.loadSession(uid, sid)).state!.remoteFinalized,
        isFalse,
      );
      expect(decision.destination, AssessmentFlowDestination.profileSetup);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test(
        'Frequency completed non-pending + remote flow complete → follow progress',
        () async {
      const uid = 'uid_cold_freq_done';
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: frequencyBank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(18)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-freq-done',
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
      await manager.complete(ownerUid: uid, sessionId: sid);
      await manager.markRemoteFinalized(ownerUid: uid, sessionId: sid);

      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: repo,
      ).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.profileSetup,
          iqCompleted: true,
          eqCompleted: true,
          frequencyCompleted: true,
          assessmentFlowCompleted: true,
        ),
      );

      expect((await repo.loadActiveSession(uid)).isLoaded, isFalse);
      expect(
        (await repo.loadSession(uid, sid)).state!.remoteFinalized,
        isTrue,
      );
      expect(decision.destination, AssessmentFlowDestination.profileSetup);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test('IQ pending without remote progress → hold on IQ test (do not skip)',
        () async {
      const uid = 'uid_cold_hold';
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: iqBank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(14)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-hold',
      );
      final sid = created.state!.sessionId;
      final byId = {for (final i in iqBank.items) i.id: i};
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: uid,
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: byId[p.itemId]!.correctOptionId,
        );
      }
      await manager.complete(ownerUid: uid, sessionId: sid);

      // Progress incorrectly already at EQ, but we treat incomplete remote
      // progress as false — hold path: pending + iqCompleted false.
      final progress = _progress(
        destination: AssessmentFlowDestination.eq,
        iqCompleted: false,
      );

      final decision = await _reconciler(
        iqRepository: repo,
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: FrequencySessionMemoryRepository(),
      ).reconcile(uid: uid, progress: progress);

      expect(
        (await repo.loadActiveSession(uid)).state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(decision.destination, AssessmentFlowDestination.iq);
      expect(decision.openAssessmentTestScreen, isTrue);
      expect(decision.reason, 'iq_pending_finalization');
    });

    test('finalize is idempotent when already remote-finalized', () async {
      const uid = 'uid_cold_idem';
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: iqBank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(15)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'cold-idem',
      );
      final sid = created.state!.sessionId;
      final byId = {for (final i in iqBank.items) i.id: i};
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: uid,
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: byId[p.itemId]!.correctOptionId,
        );
      }
      await manager.complete(ownerUid: uid, sessionId: sid);
      await manager.markRemoteFinalized(ownerUid: uid, sessionId: sid);

      final progress = _progress(
        destination: AssessmentFlowDestination.eq,
        iqCompleted: true,
      );
      final eqRepo = EqSessionMemoryRepository();
      final freqRepo = FrequencySessionMemoryRepository();
      final reconciler = _reconciler(
        iqRepository: repo,
        eqRepository: eqRepo,
        frequencyRepository: freqRepo,
      );
      final first = await reconciler.reconcile(uid: uid, progress: progress);
      final second = await reconciler.reconcile(uid: uid, progress: progress);
      expect(first.destination, AssessmentFlowDestination.eq);
      expect(second.destination, AssessmentFlowDestination.eq);
      expect((await repo.loadSession(uid, sid)).state!.remoteFinalized, isTrue);
    });

    test('no local pending IQ + remote iq_completed → follow progress, not IQ',
        () async {
      const uid = 'uid_old_user';
      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: FrequencySessionMemoryRepository(),
      ).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.eq,
          iqCompleted: true,
        ),
      );
      expect(decision.destination, AssessmentFlowDestination.eq);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test('no local pending EQ + remote eq_completed → follow progress, not EQ',
        () async {
      const uid = 'uid_old_eq_user';
      final decision = await _reconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: FrequencySessionMemoryRepository(),
      ).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.frequency,
          iqCompleted: true,
          eqCompleted: true,
        ),
      );
      expect(decision.destination, AssessmentFlowDestination.frequency);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });
  });

  group('Frequency V2 cold-start contract', () {
    test('A stale V1 pending never reopens V1 Frequency', () async {
      const uid = 'uid_v1_leftover';
      final v1 = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: FrequencyCanonicalBankDocument.fromJson(
          jsonDecode(File(FrequencyBankContract.trAssetPath).readAsStringSync())
              as Map<String, dynamic>,
        ),
        repository: v1,
        idFactory: FrequencySessionIdFactory(random: Random(21)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: 'leftover-v1',
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
      await manager.complete(ownerUid: uid, sessionId: sid);

      final decision = await _reconciler(frequencyRepository: v1).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.persona,
          iqCompleted: true,
          eqCompleted: true,
          frequencyCompleted: true,
        ),
      );
      expect((await v1.loadActiveSession(uid)).isLoaded, isTrue);
      expect(decision.destination, AssessmentFlowDestination.persona);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test('B unfinished V2 pending resumes V2 Frequency', () async {
      const uid = 'uid_v2_pending';
      final v2 = FrequencyV2SessionMemoryRepository();
      await v2.saveSession(
        _v2Session(
          uid: uid,
          status: FrequencyV2PersistedSessionStatus.completedPendingPersistence,
        ),
      );
      final decision = await _reconciler(frequencyV2Repository: v2).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.profileSetup,
          iqCompleted: true,
          eqCompleted: true,
          frequencyCompleted: true,
        ),
      );
      expect(decision.destination, AssessmentFlowDestination.frequency);
      expect(decision.openAssessmentTestScreen, isTrue);
      expect(decision.reason, 'frequency_v2_pending_finalization');
      expect(
        buildAssessmentDestination(decision),
        isA<FrequencyV2TestScreen>(),
      );
    });

    test('C finalized V2 without local pending skips Frequency', () async {
      final snap = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyV2Assessment: _validFrequencyV2(),
      );
      expect(snap.frequencyCompleted, isTrue);
      expect(snap.destination, AssessmentFlowDestination.persona);

      final decision = await _reconciler().reconcile(
        uid: 'uid_v2_final',
        progress: snap,
      );
      expect(decision.destination, AssessmentFlowDestination.persona);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test('D finalized V2 + missing Persona routes Persona', () {
      final snap = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyV2Assessment: _validFrequencyV2(),
      );
      expect(snap.canonicalPersonaAvailable, isFalse);
      expect(snap.destination, AssessmentFlowDestination.persona);
    });

    test('E existing Persona is reused and continues to ProfileSetup', () {
      final snap = AssessmentProgressService.resolveFromMaps(
        userDoc: {
          'assessment_flow_version': 2,
          'iq_completed': true,
          'eq_completed': true,
          'profile_completed': false,
        },
        iqAssessment: {'status': 'completed'},
        eqAssessment: {'status': 'completed'},
        frequencyV2Assessment: _validFrequencyV2(),
        personaAssessment: {
          'primary_persona_id': 'bagimsiz',
          'secondary_persona_id': 'analist',
          'raw_delta_d': 0.04,
          'scoring_version': PersonaV2Contract.scoringVersion,
          'config_version': PersonaV2Contract.configVersion,
          'policy_version': PersonaV2Contract.policyVersion,
          'prototype_version': PersonaV2Contract.prototypeVersion,
          'source': PersonaV2Contract.source,
        },
      );
      expect(snap.canonicalPersonaAvailable, isTrue);
      expect(snap.destination, AssessmentFlowDestination.profileSetup);
    });

    test(
        'F live cold-start Frequency path never constructs FrequencyTestScreen',
        () {
      final factory = File(
        'lib/features/assessment/domain/frequency_v2_runtime/frequency_runtime_test_screen_factory.dart',
      ).readAsStringSync();
      expect(factory.contains('FrequencyV2TestScreen'), isTrue);
      expect(factory.contains('FrequencyTestScreen('), isFalse);

      final gate = File(
        'lib/core/navigation/assessment_progress_route_gate.dart',
      ).readAsStringSync();
      expect(
          gate.contains('FrequencyRuntimeTestScreenFactory.build()'), isTrue);
      expect(gate.contains('FrequencyTestScreen('), isFalse);

      final built = FrequencyRuntimeTestScreenFactory.build();
      expect(built, isA<FrequencyV2TestScreen>());
    });

    test('G SharedPreferences V2 peek is deterministic with test binding',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      const uid = 'uid_v2_prefs';
      final prefsRepo = FrequencyV2SessionPrefsRepository();
      await prefsRepo.saveSession(
        _v2Session(
          uid: uid,
          status: FrequencyV2PersistedSessionStatus.completedPendingPersistence,
        ),
      );
      final loaded = await prefsRepo.loadActiveSession(uid);
      expect(loaded.isLoaded, isTrue);
      expect(
        loaded.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );

      final decision = await _reconciler(
        frequencyV2Repository: prefsRepo,
      ).reconcile(
        uid: uid,
        progress: _progress(
          destination: AssessmentFlowDestination.main,
          iqCompleted: true,
          eqCompleted: true,
          frequencyCompleted: true,
        ),
      );
      expect(decision.reason, 'frequency_v2_pending_finalization');
      expect(decision.openAssessmentTestScreen, isTrue);
    });

    test('H malformed V2 pending fails safely and follows progress', () async {
      final decision = await _reconciler(
        frequencyV2Repository: _CorruptV2Repo(),
      ).reconcile(
        uid: 'uid_v2_bad',
        progress: _progress(
          destination: AssessmentFlowDestination.frequency,
          iqCompleted: true,
          eqCompleted: true,
        ),
      );
      expect(decision.destination, AssessmentFlowDestination.frequency);
      expect(decision.openAssessmentTestScreen, isFalse);
      expect(decision.reason, 'progress_routing');
    });

    test('I reconciler does not mark a pending V2 session remote-finalized',
        () async {
      const uid = 'uid_v2_once';
      final v2 = FrequencyV2SessionMemoryRepository();
      await v2.saveSession(
        _v2Session(
          uid: uid,
          status: FrequencyV2PersistedSessionStatus.completedPendingPersistence,
        ),
      );
      final reconciler = _reconciler(frequencyV2Repository: v2);
      final progress = _progress(
        destination: AssessmentFlowDestination.persona,
        iqCompleted: true,
        eqCompleted: true,
        frequencyCompleted: true,
      );
      final first = await reconciler.reconcile(uid: uid, progress: progress);
      final second = await reconciler.reconcile(uid: uid, progress: progress);
      expect(first.reason, 'frequency_v2_pending_finalization');
      expect(second.reason, 'frequency_v2_pending_finalization');
      final active = await v2.loadActiveSession(uid);
      expect(active.isLoaded, isTrue);
      expect(active.state!.remoteFinalized, isFalse);
      expect(
        active.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
    });

    test('J reconciler never writes a V1 Frequency assessment record', () {
      final src = File(
        'lib/features/assessment/services/assessment_cold_start_pending_reconciler.dart',
      ).readAsStringSync();
      expect(src.contains("upsertCompletedAssessment"), isFalse);
      expect(src.contains("'frequency'"), isFalse);
      expect(src.contains('assessments/frequency'), isFalse);
      expect(src.contains('FrequencyTestScreen'), isFalse);
    });
  });
}
