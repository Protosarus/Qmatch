import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_session/eq_session.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_session/frequency_session.dart';

void main() {
  group('HOTFIX2 EQ pending finalization lifecycle', () {
    late EqCanonicalBankDocument bank;

    setUpAll(() {
      bank = EqCanonicalBankDocument.fromJson(
        jsonDecode(
          File(EqBankContract.trAssetPath).readAsStringSync(),
        ) as Map<String, dynamic>,
      );
    });

    test('complete keeps active; finalize clears; restart recovers pending',
        () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(3)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_eq',
        sessionSeed: 'eq-pending-1',
      );
      expect(created.ok, isTrue);
      final sid = created.state!.sessionId;
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_eq',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      final done = await manager.complete(ownerUid: 'uid_eq', sessionId: sid);
      expect(done.ok, isTrue);
      expect(
        done.state!.status,
        EqPersistedSessionStatus.completedPendingPersistence,
      );
      expect(done.state!.remoteFinalized, isFalse);
      expect((await repo.loadActiveSession('uid_eq')).isLoaded, isTrue);

      final reAnswer = await manager.answer(
        ownerUid: 'uid_eq',
        sessionId: sid,
        itemId: created.state!.itemPlans.last.itemId,
        selectedOptionId: created.state!.itemPlans.last.displayedOptionIds.last,
      );
      expect(reAnswer.ok, isFalse);

      final manager2 = EqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(9)),
      );
      final resumed = await manager2.getOrCreateActiveSession(
        ownerUid: 'uid_eq',
        sessionSeed: 'should-not-compose',
      );
      expect(resumed.ok, isTrue);
      expect(manager2.lastOperationComposed, isFalse);
      expect(resumed.state!.sessionId, sid);

      final finalized = await manager2.markRemoteFinalized(
          ownerUid: 'uid_eq', sessionId: sid);
      expect(finalized.ok, isTrue);
      expect(finalized.state!.status, EqPersistedSessionStatus.completed);
      expect(finalized.state!.remoteFinalized, isTrue);
      expect((await repo.loadActiveSession('uid_eq')).isLoaded, isFalse);
    });

    test('stuck completed EQ session recovers when unique', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(5)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_stuck_eq',
        sessionSeed: 'eq-stuck',
      );
      final sid = created.state!.sessionId;
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_stuck_eq',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      final pending =
          await manager.complete(ownerUid: 'uid_stuck_eq', sessionId: sid);
      final stuck = pending.state!.copyWith(
        status: EqPersistedSessionStatus.completed,
        remoteFinalized: false,
      );
      await repo.saveSession(stuck);
      expect((await repo.loadActiveSession('uid_stuck_eq')).isLoaded, isFalse);

      final recovered = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_stuck_eq',
        sessionSeed: 'recover',
      );
      expect(recovered.ok, isTrue);
      expect(manager.lastOperationComposed, isFalse);
      expect(recovered.state!.sessionId, sid);
      expect(
        recovered.state!.status,
        EqPersistedSessionStatus.completedPendingPersistence,
      );
    });

    test('UID isolation for EQ pending', () async {
      final repo = EqSessionMemoryRepository();
      final manager = EqSessionManager(
        bank: bank,
        repository: repo,
        idFactory: EqSessionIdFactory(random: Random(2)),
      );
      final a = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_a',
        sessionSeed: 'a',
      );
      for (final p in a.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_a',
          sessionId: a.state!.sessionId,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      await manager.complete(
        ownerUid: 'uid_a',
        sessionId: a.state!.sessionId,
      );

      final b = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_b',
        sessionSeed: 'b',
      );
      expect(b.state!.sessionId, isNot(a.state!.sessionId));
      expect(b.state!.ownerUid, 'uid_b');
      expect(b.state!.answers, isEmpty);
    });
  });

  group('HOTFIX2 Frequency pending finalization lifecycle', () {
    late FrequencyCanonicalBankDocument bank;

    setUpAll(() {
      bank = FrequencyCanonicalBankDocument.fromJson(
        jsonDecode(
          File(FrequencyBankContract.trAssetPath).readAsStringSync(),
        ) as Map<String, dynamic>,
      );
    });

    test('complete keeps active; finalize clears; restart recovers', () async {
      final repo = FrequencySessionMemoryRepository();
      final manager = FrequencySessionManager(
        bank: bank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(4)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'uid_f',
        sessionSeed: 'f-pending',
      );
      final sid = created.state!.sessionId;
      for (final p in created.state!.itemPlans) {
        await manager.answer(
          ownerUid: 'uid_f',
          sessionId: sid,
          itemId: p.itemId,
          selectedOptionId: p.displayedOptionIds.first,
        );
      }
      final done = await manager.complete(ownerUid: 'uid_f', sessionId: sid);
      expect(
        done.state!.status,
        FrequencyPersistedSessionStatus.completedPendingPersistence,
      );
      expect((await repo.loadActiveSession('uid_f')).isLoaded, isTrue);

      final manager2 = FrequencySessionManager(
        bank: bank,
        repository: repo,
        idFactory: FrequencySessionIdFactory(random: Random(8)),
      );
      final resumed = await manager2.getOrCreateActiveSession(
        ownerUid: 'uid_f',
        sessionSeed: 'no',
      );
      expect(resumed.state!.sessionId, sid);
      expect(manager2.lastOperationComposed, isFalse);

      final finalized =
          await manager2.markRemoteFinalized(ownerUid: 'uid_f', sessionId: sid);
      expect(finalized.state!.remoteFinalized, isTrue);
      expect((await repo.loadActiveSession('uid_f')).isLoaded, isFalse);
    });
  });
}
