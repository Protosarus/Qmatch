import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/models/assessment_progress.dart';
import 'package:qmatch/features/assessment/services/assessment_cold_start_pending_reconciler.dart';

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
    allAssessmentsCompleted:
        iqCompleted && eqCompleted && frequencyCompleted,
    assessmentFlowCompleted: assessmentFlowCompleted,
    canonicalPersonaAvailable: false,
    profileCompleted: false,
    destination: destination,
    resolutionSource: 'test',
    reason: null,
  );
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

    test('Frequency pending blocks profileSetup progress route', () {
      final d = AssessmentColdStartPendingReconciler.decide(
        iqPendingFinalization: false,
        eqPendingFinalization: false,
        frequencyPendingFinalization: true,
        progressDestination: AssessmentFlowDestination.profileSetup,
      );
      expect(d.destination, AssessmentFlowDestination.frequency);
      expect(d.openAssessmentTestScreen, isTrue);
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

    test('IQ: remote iq_completed + local pending → hold IQ, do not local-finalize',
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
      final reconciler = AssessmentColdStartPendingReconciler(
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

      final decision = await AssessmentColdStartPendingReconciler(
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
        'Frequency: remote flow complete + local pending → finalize, then profile',
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
        assessmentFlowCompleted: true,
      );

      final decision = await AssessmentColdStartPendingReconciler(
        iqRepository: IqSessionMemoryRepository(),
        eqRepository: EqSessionMemoryRepository(),
        frequencyRepository: repo,
        loadFrequencyBank: (_) async => frequencyBank,
      ).reconcile(uid: uid, progress: progress);

      expect((await repo.loadActiveSession(uid)).isLoaded, isFalse);
      expect((await repo.loadSession(uid, sid)).state!.remoteFinalized, isTrue);
      expect(decision.destination, AssessmentFlowDestination.profileSetup);
      expect(decision.openAssessmentTestScreen, isFalse);
    });

    test(
        'IQ pending without remote progress → hold on IQ test (do not skip)',
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

      final decision = await AssessmentColdStartPendingReconciler(
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
      final reconciler = AssessmentColdStartPendingReconciler(
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

    test(
        'no local pending IQ + remote iq_completed → follow progress, not IQ',
        () async {
      const uid = 'uid_old_user';
      final decision = await AssessmentColdStartPendingReconciler(
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

    test(
        'no local pending EQ + remote eq_completed → follow progress, not EQ',
        () async {
      const uid = 'uid_old_eq_user';
      final decision = await AssessmentColdStartPendingReconciler(
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
}
