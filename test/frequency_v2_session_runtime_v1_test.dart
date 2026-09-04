import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';

import 'support/frequency_v2_runtime_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Frequency V2 session runtime', () {
    test('creates a deterministic locked 50-item manifest', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final repoA = FrequencyV2SessionMemoryRepository();
      final repoB = FrequencyV2SessionMemoryRepository();
      final seed = 'v2-seed-alpha';
      final a = FrequencyV2SessionManager(
        bank: bank,
        repository: repoA,
        idFactory: FrequencyV2SessionIdFactory(random: Random(1)),
        clock: () => DateTime.utc(2026, 9, 4),
      );
      final b = FrequencyV2SessionManager(
        bank: bank,
        repository: repoB,
        idFactory: FrequencyV2SessionIdFactory(random: Random(2)),
        clock: () => DateTime.utc(2026, 9, 4),
      );
      final createdA = await a.getOrCreateActiveSession(
        ownerUid: 'u1',
        sessionSeed: seed,
      );
      final createdB = await b.getOrCreateActiveSession(
        ownerUid: 'u2',
        sessionSeed: seed,
      );
      expect(createdA.ok, isTrue);
      expect(createdB.ok, isTrue);
      expect(createdA.state!.itemPlans.length, 50);
      expect(
        createdA.state!.itemPlans.map((p) => p.itemId).toList(),
        createdB.state!.itemPlans.map((p) => p.itemId).toList(),
      );
      expect(
        createdA.state!.itemPlans.map((p) => p.presentedOptionOrder).toList(),
        createdB.state!.itemPlans.map((p) => p.presentedOptionOrder).toList(),
      );
      final rebuilt = a.composeManifest(
        sessionSeed: seed,
        sessionId: 'other',
      );
      expect(
        rebuilt.questionIds,
        createdA.state!.itemPlans.map((p) => p.itemId).toList(),
      );
    });

    test('persists answers, resumes, and locks completion', () async {
      final bank = await FrequencyV2RuntimeTestHarness.loadTr();
      final repo = FrequencyV2SessionMemoryRepository();
      final manager = FrequencyV2SessionManager(
        bank: bank,
        repository: repo,
        idFactory: FrequencyV2SessionIdFactory(random: Random(3)),
        clock: () => DateTime.utc(2026, 9, 4, 9),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'owner',
        sessionSeed: 'resume-seed',
      );
      final sid = created.state!.sessionId;
      final first = created.state!.itemPlans.first;
      await manager.answer(
        ownerUid: 'owner',
        sessionId: sid,
        itemId: first.itemId,
        selectedOptionId: first.presentedOptionOrder.first,
      );
      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'owner',
        sessionSeed: 'different-seed-must-not-recompose',
      );
      expect(resumed.state!.sessionId, sid);
      expect(resumed.state!.answers.length, 1);
      expect(manager.lastOperationComposed, isFalse);

      for (final plan in created.state!.itemPlans.skip(1)) {
        await manager.answer(
          ownerUid: 'owner',
          sessionId: sid,
          itemId: plan.itemId,
          selectedOptionId: plan.presentedOptionOrder.first,
        );
      }
      final locked = await manager.complete(ownerUid: 'owner', sessionId: sid);
      expect(
        locked.state!.status,
        FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      );
      final rejected = await manager.answer(
        ownerUid: 'owner',
        sessionId: sid,
        itemId: first.itemId,
        selectedOptionId: first.presentedOptionOrder.last,
      );
      expect(rejected.ok, isFalse);
      expect(rejected.code, 'session_not_editable');
    });

    test('does not use V1 Frequency session storage keys', () {
      expect(
        FrequencyV2SessionStorageKeys.prefix,
        isNot(contains('qmatch.frequency_session.v1')),
      );
      expect(
        FrequencyV2SessionStorageKeys.prefix,
        'qmatch.frequency_v2_session.v1',
      );
    });
  });
}
