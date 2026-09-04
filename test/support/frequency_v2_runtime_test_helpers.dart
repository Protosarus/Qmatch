import 'dart:math';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';
import 'package:qmatch/features/assessment/domain/frequency_v2_runtime/frequency_v2_runtime.dart';

class FrequencyV2RuntimeTestHarness {
  FrequencyV2RuntimeTestHarness._();

  static FrequencyV2BankLoader loader() => FrequencyV2BankLoader();

  static Future<FrequencyV2LoadedBank> loadTr() {
    return loader().load(
      poolVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
      locale: FrequencyBehaviorV2Contract.localeTr,
    );
  }

  static Future<FrequencyV2LoadedBank> loadEn() {
    return loader().load(
      poolVersion: FrequencyBehaviorV2Contract.poolVersionEnDraft1,
      locale: FrequencyBehaviorV2Contract.localeEn,
    );
  }

  static Future<
      ({
        FrequencyV2PersistedSessionState session,
        FrequencyV2SessionManager manager,
        FrequencyV2SessionMemoryRepository repo,
      })> pendingSession({
    required FrequencyV2LoadedBank bank,
    required String uid,
    required String seed,
    int idSeed = 7,
  }) async {
    final repo = FrequencyV2SessionMemoryRepository();
    final manager = FrequencyV2SessionManager(
      bank: bank,
      repository: repo,
      idFactory: FrequencyV2SessionIdFactory(random: Random(idSeed)),
      clock: () => DateTime.utc(2026, 9, 4, 8),
    );
    final created = await manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: seed,
    );
    final sid = created.state!.sessionId;
    for (final plan in created.state!.itemPlans) {
      await manager.answer(
        ownerUid: uid,
        sessionId: sid,
        itemId: plan.itemId,
        selectedOptionId: plan.presentedOptionOrder.first,
      );
    }
    final locked = await manager.complete(ownerUid: uid, sessionId: sid);
    return (
      session: locked.state!,
      manager: manager,
      repo: repo,
    );
  }
}
