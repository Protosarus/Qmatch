import '../frequency_behavior_v2/frequency_behavior_v2.dart';
import 'frequency_v2_bank_loader.dart';
import 'frequency_v2_persisted_session_state.dart';
import 'frequency_v2_runtime_contract.dart';
import 'frequency_v2_session_repository.dart';

/// Creates and mutates a locked Frequency V2 session using the existing
/// [FrequencyBehaviorV2SessionComposer]. Manifest is persisted before answers.
class FrequencyV2SessionManager {
  FrequencyV2SessionManager({
    required FrequencyV2LoadedBank bank,
    required FrequencyV2SessionPersistenceRepository repository,
    FrequencyV2SessionIdFactory? idFactory,
    DateTime Function()? clock,
  })  : _bank = bank,
        _repository = repository,
        _idFactory = idFactory ?? FrequencyV2SessionIdFactory(),
        _clock = clock ?? DateTime.now;

  final FrequencyV2LoadedBank _bank;
  final FrequencyV2SessionPersistenceRepository _repository;
  final FrequencyV2SessionIdFactory _idFactory;
  final DateTime Function() _clock;

  bool lastOperationComposed = false;

  String _nowIso() => _clock().toUtc().toIso8601String();

  FrequencyBehaviorV2SessionManifest composeManifest({
    required String sessionSeed,
    required String sessionId,
  }) {
    return const FrequencyBehaviorV2SessionComposer().composeManifest(
      pool: _bank.pool,
      sessionSeed: sessionSeed,
      reviewByItemId: _bank.reviewByItemId,
      nearDuplicateClusters: _bank.nearDuplicateClusters,
      excludeUnresolvedReview: true,
      sessionId: sessionId,
      createdAt: _nowIso(),
    );
  }

  List<FrequencyV2SessionItemPlan> _plansFromManifest(
    FrequencyBehaviorV2SessionManifest manifest,
  ) {
    return [
      for (final q in manifest.questions)
        FrequencyV2SessionItemPlan(
          itemId: q.questionId,
          primaryDimension: q.primaryDimension,
          presentedOptionOrder: List<String>.from(q.presentedOptionOrder),
        ),
    ];
  }

  Future<FrequencyV2SessionWriteResult> getOrCreateActiveSession({
    required String ownerUid,
    required String sessionSeed,
  }) async {
    lastOperationComposed = false;
    if (ownerUid.trim().isEmpty) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    if (sessionSeed.trim().isEmpty) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'missing_session_seed',
        message: 'session_seed required',
      );
    }

    final existing = await _repository.loadActiveSession(ownerUid);
    if (existing.isLoaded) {
      final state = existing.state!;
      if (state.status == FrequencyV2PersistedSessionStatus.inProgress ||
          state.status ==
              FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
        return FrequencyV2SessionWriteResult(ok: true, state: state);
      }
    } else if (existing.code == FrequencyV2SessionLoadCode.corrupt ||
        existing.code == FrequencyV2SessionLoadCode.ownerMismatch ||
        existing.code == FrequencyV2SessionLoadCode.incompatibleSchema) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: existing.code.name,
        message: existing.message,
      );
    }

    final sessionId = _idFactory.next();
    final manifest = composeManifest(
      sessionSeed: sessionSeed,
      sessionId: sessionId,
    );
    if (manifest.questions.length !=
        FrequencyV2RuntimeContract.sessionItemCount) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: 'item_plan_count',
        message: 'Selector produced ${manifest.questions.length} items',
      );
    }
    final now = _nowIso();
    final state = FrequencyV2PersistedSessionState(
      schemaVersion: FrequencyV2RuntimeContract.persistedSchemaVersion,
      sessionId: sessionId,
      ownerUid: ownerUid,
      sessionSeed: sessionSeed,
      bankVersion: _bank.poolVersion,
      bankLocale: _bank.locale,
      translationVersion: _bank.translationVersion,
      selectionPolicyVersion:
          FrequencyBehaviorV2Contract.selectionPolicyVersion,
      selectorVersion: FrequencyBehaviorV2Contract.selectorVersion,
      itemPlans: _plansFromManifest(manifest),
      currentQuestionIndex: 0,
      answers: const [],
      startedAt: now,
      updatedAt: now,
      status: FrequencyV2PersistedSessionStatus.inProgress,
    );
    await _repository.saveSession(state);
    lastOperationComposed = true;
    return FrequencyV2SessionWriteResult(ok: true, state: state);
  }

  Future<FrequencyV2SessionWriteResult> _loadEditable(
    String ownerUid,
    String sessionId,
  ) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final state = loaded.state!;
    if (!state.status.isAnswerEditable) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Session is ${state.status.wireValue}',
        state: state,
      );
    }
    return FrequencyV2SessionWriteResult(ok: true, state: state);
  }

  Future<FrequencyV2SessionWriteResult> answer({
    required String ownerUid,
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final loaded = await _loadEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    FrequencyV2SessionItemPlan? plan;
    for (final p in state.itemPlans) {
      if (p.itemId == itemId) {
        plan = p;
        break;
      }
    }
    if (plan == null) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'unknown_item',
        message: 'Item not in locked V2 manifest',
      );
    }
    if (!plan.presentedOptionOrder.contains(selectedOptionId)) {
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'unknown_option',
        message: 'Option not in presented order',
      );
    }
    final byId =
        Map<String, FrequencyV2SessionAnswer>.from(state.answersByItemId);
    final existing = byId[itemId];
    if (existing != null) {
      if (existing.selectedOptionId == selectedOptionId) {
        return FrequencyV2SessionWriteResult(ok: true, state: state);
      }
      return const FrequencyV2SessionWriteResult(
        ok: false,
        code: 'answer_already_committed',
        message: 'Locked V2 answers cannot be silently changed',
      );
    }
    byId[itemId] = FrequencyV2SessionAnswer(
      itemId: itemId,
      selectedOptionId: selectedOptionId,
      answeredAt: _nowIso(),
    );
    final unanswered = () {
      for (var i = 0; i < state.itemPlans.length; i++) {
        if (!byId.containsKey(state.itemPlans[i].itemId)) return i;
      }
      return state.itemPlans.length;
    }();
    final cursor = unanswered >= state.itemPlans.length
        ? state.itemPlans.length - 1
        : unanswered;
    final next = state.copyWith(
      answers: byId.values.toList(),
      currentQuestionIndex: cursor,
      updatedAt: _nowIso(),
    );
    await _repository.saveSession(next);
    return FrequencyV2SessionWriteResult(ok: true, state: next);
  }

  Future<FrequencyV2SessionWriteResult> complete({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final state = loaded.state!;
    if (state.status ==
        FrequencyV2PersistedSessionStatus.completedPendingPersistence) {
      return FrequencyV2SessionWriteResult(ok: true, state: state);
    }
    if (!state.status.isAnswerEditable) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Session is ${state.status.wireValue}',
        state: state,
      );
    }
    if (state.answersByItemId.length !=
        FrequencyV2RuntimeContract.sessionItemCount) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: 'answer_count',
        message: 'Need 50 answers before lock',
        state: state,
      );
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: FrequencyV2PersistedSessionStatus.completedPendingPersistence,
      completedAt: now,
      updatedAt: now,
    );
    await _repository.saveSession(next);
    return FrequencyV2SessionWriteResult(ok: true, state: next);
  }

  Future<FrequencyV2SessionWriteResult> markRemoteFinalized({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencyV2SessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final state = loaded.state!;
    final now = _nowIso();
    final next = state.copyWith(
      status: FrequencyV2PersistedSessionStatus.completed,
      remoteFinalized: true,
      updatedAt: now,
      completedAt: state.completedAt ?? now,
    );
    await _repository.saveSession(next);
    return FrequencyV2SessionWriteResult(ok: true, state: next);
  }
}
