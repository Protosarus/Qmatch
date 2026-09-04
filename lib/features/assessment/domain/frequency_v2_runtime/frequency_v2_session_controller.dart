import '../frequency_behavior_v2/frequency_behavior_v2.dart';
import 'frequency_v2_bank_loader.dart';
import 'frequency_v2_persisted_session_state.dart';
import 'frequency_v2_runtime_contract.dart';
import 'frequency_v2_session_manager.dart';
import 'frequency_v2_session_repository.dart';

/// Dormant V2 presentation controller. Not used by live Frequency routing.
class FrequencyV2SessionController {
  FrequencyV2SessionController({
    required FrequencyV2LoadedBank bank,
    required FrequencyV2SessionManager manager,
  })  : _bank = bank,
        _manager = manager;

  final FrequencyV2LoadedBank _bank;
  final FrequencyV2SessionManager _manager;

  FrequencyV2PersistedSessionState? session;

  FrequencyV2LoadedBank get bank => _bank;

  FrequencyV2SessionManager get manager => _manager;

  FrequencyV2SessionItemPlan? get currentPlan {
    final state = session;
    if (state == null || state.itemPlans.isEmpty) return null;
    final i = state.currentQuestionIndex.clamp(0, state.itemPlans.length - 1);
    return state.itemPlans[i];
  }

  FrequencyBehaviorV2Item? get currentItem {
    final plan = currentPlan;
    if (plan == null) return null;
    return _bank.pool.itemsById[plan.itemId];
  }

  int get progressIndex {
    final state = session;
    if (state == null) return 0;
    return state.currentQuestionIndex.clamp(0, state.itemPlans.length - 1) + 1;
  }

  int get progressTotal => FrequencyV2RuntimeContract.sessionItemCount;

  String? optionText(String optionId) {
    final item = currentItem;
    if (item == null) return null;
    for (final o in item.options) {
      if (o.optionId == optionId) return o.text;
    }
    return null;
  }

  Future<FrequencyV2SessionWriteResult> start({
    required String ownerUid,
    required String sessionSeed,
  }) async {
    final result = await _manager.getOrCreateActiveSession(
      ownerUid: ownerUid,
      sessionSeed: sessionSeed,
    );
    session = result.state;
    return result;
  }

  Future<FrequencyV2SessionWriteResult> selectOption(String optionId) async {
    final state = session;
    final plan = currentPlan;
    if (state == null || plan == null) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'no_session',
      );
    }
    final result = await _manager.answer(
      ownerUid: state.ownerUid,
      sessionId: state.sessionId,
      itemId: plan.itemId,
      selectedOptionId: optionId,
    );
    session = result.state ?? session;
    return result;
  }

  Future<FrequencyV2SessionWriteResult> lockIfComplete() async {
    final state = session;
    if (state == null) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'no_session',
      );
    }
    if (state.answersByItemId.length !=
        FrequencyV2RuntimeContract.sessionItemCount) {
      return FrequencyV2SessionWriteResult(ok: true, state: state);
    }
    final result = await _manager.complete(
      ownerUid: state.ownerUid,
      sessionId: state.sessionId,
    );
    session = result.state ?? session;
    return result;
  }
}
