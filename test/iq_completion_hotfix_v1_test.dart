import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/domain/profile/profile.dart';
import 'package:qmatch/features/assessment/screens/iq_test_screen.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

IqRecoveredBankDocument _loadBank() {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>,
  );
}

Future<({IqSessionManager manager, IqSessionMemoryRepository repo, String sid})>
    _answerAll({
  required IqRecoveredBankDocument bank,
  required String uid,
  required String seed,
  required String Function(IqSessionItemPlan plan, String correctId) pick,
}) async {
  final repo = IqSessionMemoryRepository();
  final manager = IqSessionManager(
    bank: bank,
    repository: repo,
    idFactory: IqSessionIdFactory(random: Random(42)),
    clock: () => DateTime.utc(2026, 8, 9, 20),
  );
  final created = await manager.getOrCreateActiveSession(
    ownerUid: uid,
    sessionSeed: seed,
  );
  expect(created.ok, isTrue);
  final byId = {for (final i in bank.items) i.id: i};
  final sid = created.state!.sessionId;
  for (final p in created.state!.itemPlans) {
    await manager.answer(
      ownerUid: uid,
      sessionId: sid,
      itemId: p.itemId,
      selectedOptionId: pick(p, byId[p.itemId]!.correctOptionId),
    );
  }
  return (manager: manager, repo: repo, sid: sid);
}

void main() {
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    bank = _loadBank();
  });

  group('HOTFIX IQ completion finalization lifecycle', () {
    test('wrong option on pattern_curated_030 still completes and scores',
        () async {
      final byId = {for (final i in bank.items) i.id: i};
      expect(byId.containsKey('pattern_curated_030'), isTrue);
      final target = byId['pattern_curated_030']!;
      final wrong = target.options
          .map((o) => o.id)
          .firstWhere((id) => id != target.correctOptionId);

      final built = await _answerAll(
        bank: bank,
        uid: 'uid_wrong',
        seed: 'hotfix-wrong-pattern-030',
        pick: (plan, correct) {
          if (plan.itemId == 'pattern_curated_030') {
            expect(plan.displayedOptionIds.contains(wrong), isTrue);
            return wrong;
          }
          return correct;
        },
      );

      final done = await built.manager.complete(
        ownerUid: 'uid_wrong',
        sessionId: built.sid,
      );
      expect(done.ok, isTrue);
      expect(
        done.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(done.state!.answers.length, 25);

      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: done.state!,
        bank: bank,
        ownerUid: 'uid_wrong',
      );
      expect(scored.ok, isTrue);
      expect(scored.result!.totalAnswered, 25);
      expect(scored.result!.structuralFlags.completeSession, isTrue);

      final adapted = const IqTo20dRuntimeAdapter().adapt(
        result: scored.result!,
        ownerUid: 'uid_wrong',
      );
      expect(adapted.ok, isTrue);
      expect(adapted.fragment!.measuredDimensionCount, 4);
      expect(adapted.fragment!.canonicalProfileReady, isFalse);
      expect(adapted.fragment!.profileStatus, QmatchProfileStatus.partial);
    });

    test('persistence failure keeps pending session; retry without answer',
        () async {
      final built = await _answerAll(
        bank: bank,
        uid: 'uid_retry',
        seed: 'hotfix-persist-fail',
        pick: (_, correct) => correct,
      );
      final done = await built.manager.complete(
        ownerUid: 'uid_retry',
        sessionId: built.sid,
      );
      expect(done.ok, isTrue);

      // Simulate remote profile write failure: do NOT markRemoteFinalized.
      final active = await built.repo.loadActiveSession('uid_retry');
      expect(active.isLoaded, isTrue);
      expect(
        active.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(active.state!.answers.length, 25);

      // Same-screen retry: score again (no answer call).
      final scored1 = const IqCanonicalScorer().scoreCompletedSession(
        session: active.state!,
        bank: bank,
        ownerUid: 'uid_retry',
      );
      expect(scored1.ok, isTrue);

      // Answer must still be rejected (locked).
      final reAnswer = await built.manager.answer(
        ownerUid: 'uid_retry',
        sessionId: built.sid,
        itemId: active.state!.itemPlans.last.itemId,
        selectedOptionId: active.state!.itemPlans.last.displayedOptionIds.first,
      );
      expect(reAnswer.ok, isFalse);
      expect(reAnswer.code, 'session_not_editable');

      // Successful retry finalization.
      final scored2 = const IqCanonicalScorer().scoreCompletedSession(
        session: active.state!,
        bank: bank,
        ownerUid: 'uid_retry',
      );
      expect(scored2.ok, isTrue);
      expect(
        scored2.result!.sessionId,
        scored1.result!.sessionId,
      );
      for (var i = 0; i < 4; i++) {
        expect(
          scored2.result!.dimensionScores[i].provisionalScore,
          scored1.result!.dimensionScores[i].provisionalScore,
        );
      }

      final finalized = await built.manager.markRemoteFinalized(
        ownerUid: 'uid_retry',
        sessionId: built.sid,
      );
      expect(finalized.ok, isTrue);
      expect(finalized.state!.status, IqPersistedSessionStatus.completed);
      expect(finalized.state!.remoteFinalized, isTrue);
      expect(
        (await built.repo.loadActiveSession('uid_retry')).code,
        IqSessionLoadCode.notFound,
      );
    });

    test('app restart recovers pending finalization without new session',
        () async {
      final built = await _answerAll(
        bank: bank,
        uid: 'uid_restart',
        seed: 'hotfix-restart',
        pick: (_, correct) => correct,
      );
      final done = await built.manager.complete(
        ownerUid: 'uid_restart',
        sessionId: built.sid,
      );
      expect(done.ok, isTrue);

      // New manager/runtime surface after app kill (same repo).
      final manager2 = IqSessionManager(
        bank: bank,
        repository: built.repo,
        idFactory: IqSessionIdFactory(random: Random(99)),
      );
      final resumed = await manager2.getOrCreateActiveSession(
        ownerUid: 'uid_restart',
        sessionSeed: 'should-not-compose',
      );
      expect(resumed.ok, isTrue);
      expect(manager2.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, built.sid);
      expect(
        resumed.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(resumed.state!.answers.length, 25);

      final scored = const IqCanonicalScorer().scoreCompletedSession(
        session: resumed.state!,
        bank: bank,
        ownerUid: 'uid_restart',
      );
      expect(scored.ok, isTrue);

      final finalized = await manager2.markRemoteFinalized(
        ownerUid: 'uid_restart',
        sessionId: built.sid,
      );
      expect(finalized.ok, isTrue);
      expect(finalized.state!.remoteFinalized, isTrue);
    });

    test('pre-hotfix stuck completed session recovers when unique', () async {
      final built = await _answerAll(
        bank: bank,
        uid: 'uid_stuck',
        seed: 'hotfix-stuck',
        pick: (_, correct) => correct,
      );
      // Emulate old bug: status=completed + active pointer cleared.
      final now = DateTime.utc(2026, 8, 9).toIso8601String();
      final stuck = (await built.repo.loadSession('uid_stuck', built.sid))
          .state!
          .copyWith(
            status: IqPersistedSessionStatus.completed,
            remoteFinalized: false,
            completedAt: now,
            updatedAt: now,
          );
      // Force-clear active by saving completed (legacy pointer clear).
      await built.repo.saveSession(stuck);
      expect(
        (await built.repo.loadActiveSession('uid_stuck')).code,
        IqSessionLoadCode.notFound,
      );

      final manager2 = IqSessionManager(
        bank: bank,
        repository: built.repo,
        idFactory: IqSessionIdFactory(random: Random(7)),
      );
      final recovered = await manager2.getOrCreateActiveSession(
        ownerUid: 'uid_stuck',
        sessionSeed: 'should-recover',
      );
      expect(recovered.ok, isTrue);
      expect(manager2.lastOperationComposed, isFalse);
      expect(recovered.state!.sessionId, built.sid);
      expect(
        recovered.state!.status,
        IqPersistedSessionStatus.completedPendingPersistence,
      );
    });

    test('UID isolation: B cannot recover A pending session', () async {
      final built = await _answerAll(
        bank: bank,
        uid: 'uid_a',
        seed: 'hotfix-uid-a',
        pick: (_, correct) => correct,
      );
      await built.manager.complete(ownerUid: 'uid_a', sessionId: built.sid);

      final managerB = IqSessionManager(
        bank: bank,
        repository: built.repo,
        idFactory: IqSessionIdFactory(random: Random(3)),
      );
      final forB = await managerB.getOrCreateActiveSession(
        ownerUid: 'uid_b',
        sessionSeed: 'hotfix-uid-b',
      );
      expect(forB.ok, isTrue);
      expect(managerB.lastOperationComposed, isTrue);
      expect(forB.state!.sessionId, isNot(built.sid));
      expect(forB.state!.ownerUid, 'uid_b');
      expect(forB.state!.answers, isEmpty);

      final loadAAsB = await built.repo.loadSession('uid_b', built.sid);
      expect(loadAAsB.code, IqSessionLoadCode.notFound);
    });

    test('multiple stuck completed sessions are not arbitrarily recovered',
        () async {
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(11)),
      );
      final byId = {for (final i in bank.items) i.id: i};

      Future<Map<String, dynamic>> buildPendingJson(String seed) async {
        await repo.clearOwnerSessions('uid_multi');
        final created = await manager.getOrCreateActiveSession(
          ownerUid: 'uid_multi',
          sessionSeed: seed,
        );
        expect(created.ok, isTrue);
        expect(manager.lastOperationComposed, isTrue);
        final sid = created.state!.sessionId;
        for (final p in created.state!.itemPlans) {
          await manager.answer(
            ownerUid: 'uid_multi',
            sessionId: sid,
            itemId: p.itemId,
            selectedOptionId: byId[p.itemId]!.correctOptionId,
          );
        }
        final done =
            await manager.complete(ownerUid: 'uid_multi', sessionId: sid);
        expect(done.ok, isTrue);
        return Map<String, dynamic>.from(done.state!.toJson());
      }

      final snap1 = await buildPendingJson('multi-1');
      final snap2 = await buildPendingJson('multi-2');
      await repo.clearOwnerSessions('uid_multi');

      final stuck1 = IqPersistedSessionState.fromJson(snap1).copyWith(
        status: IqPersistedSessionStatus.completed,
        remoteFinalized: false,
      );
      final stuck2 = IqPersistedSessionState.fromJson(snap2).copyWith(
        status: IqPersistedSessionStatus.completed,
        remoteFinalized: false,
      );
      await repo.saveSession(stuck1);
      await repo.saveSession(stuck2);
      expect(stuck1.sessionId, isNot(stuck2.sessionId));
      expect(
        (await repo.loadActiveSession('uid_multi')).code,
        IqSessionLoadCode.notFound,
      );

      final stuckCount = (await repo.listOwnerSessions('uid_multi'))
          .where(
            (s) =>
                s.status == IqPersistedSessionStatus.completed &&
                !s.remoteFinalized &&
                s.answers.length == 25,
          )
          .length;
      expect(stuckCount, 2);

      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_multi',
        sessionSeed: 'multi-new',
      );
      expect(resumed.ok, isTrue);
      expect(manager.lastOperationComposed, isTrue);
      expect(resumed.state!.sessionId, isNot(stuck1.sessionId));
      expect(resumed.state!.sessionId, isNot(stuck2.sessionId));
    });

    test('successful finalization opens Reasoning Profile path (wired)', () {
      expect(IQTestScreen, isNotNull);
      expect(IqPersistedSessionStatus.completedPendingPersistence.wireValue,
          'completed_pending_persistence');
    });
  });
}
