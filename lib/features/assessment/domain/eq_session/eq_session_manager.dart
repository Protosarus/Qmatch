import 'dart:math';

import '../eq_bank/eq_bank.dart';
import 'eq_persisted_session_state.dart';
import 'eq_session_contract.dart';
import 'eq_session_persistence_repository.dart';

/// Compose full 30-item EQ session + durable resume.
class EqSessionManager {
  EqSessionManager({
    required EqCanonicalBankDocument bank,
    required EqSessionPersistenceRepository repository,
    EqSessionIdFactory? idFactory,
    DateTime Function()? clock,
    Random? shuffleRandom,
  })  : _bank = bank,
        _repository = repository,
        _idFactory = idFactory ?? EqSessionIdFactory(),
        _clock = clock ?? DateTime.now,
        _shuffleRandom = shuffleRandom;

  final EqCanonicalBankDocument _bank;
  final EqSessionPersistenceRepository _repository;
  final EqSessionIdFactory _idFactory;
  final DateTime Function() _clock;
  final Random? _shuffleRandom;

  bool lastOperationComposed = false;

  String _nowIso() => _clock().toUtc().toIso8601String();

  Random _rngForSeed(String sessionSeed) {
    final override = _shuffleRandom;
    if (override != null) return override;
    return Random(sessionSeed.hashCode);
  }

  List<EqSessionItemPlan> _composePlans(String sessionSeed) {
    final bankCheck = const EqCanonicalBankValidator().validate(_bank);
    if (!bankCheck.ok) {
      throw StateError('Invalid EQ bank: ${bankCheck.issues.join('; ')}');
    }
    final items = [..._bank.items]
      ..sort((a, b) => a.itemId.compareTo(b.itemId));
    final rng = _rngForSeed(sessionSeed);
    return [
      for (final item in items)
        EqSessionItemPlan(
          itemId: item.itemId,
          primaryDimension: item.primaryDimension,
          displayedOptionIds: () {
            final ids = [for (final o in item.options) o.optionId];
            ids.shuffle(rng);
            return ids;
          }(),
        ),
    ];
  }

  Future<EqSessionWriteResult> getOrCreateActiveSession({
    required String ownerUid,
    required String sessionSeed,
  }) async {
    lastOperationComposed = false;
    if (ownerUid.trim().isEmpty) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }

    final existing = await _repository.loadActiveSession(ownerUid);
    if (existing.isLoaded) {
      final validated = EqPersistedSessionValidator.validate(
        state: existing.state!,
        bank: _bank,
        ownerUid: ownerUid,
      );
      if (validated.isLoaded &&
          validated.state!.status == EqPersistedSessionStatus.inProgress) {
        return EqSessionWriteResult(ok: true, state: validated.state);
      }
      if (validated.code == EqSessionLoadCode.incompatibleBank ||
          validated.code == EqSessionLoadCode.incompatiblePolicy ||
          validated.code == EqSessionLoadCode.incompatibleSchema ||
          validated.code == EqSessionLoadCode.corrupt ||
          validated.code == EqSessionLoadCode.ownerMismatch) {
        return EqSessionWriteResult(
          ok: false,
          code: validated.code.name,
          message: validated.message,
          state: existing.state,
        );
      }
    } else if (existing.code == EqSessionLoadCode.corrupt ||
        existing.code == EqSessionLoadCode.ownerMismatch) {
      return EqSessionWriteResult(
        ok: false,
        code: existing.code.name,
        message: existing.message,
      );
    }

    final plans = _composePlans(sessionSeed);
    final now = _nowIso();
    final state = EqPersistedSessionState(
      schemaVersion: EqSessionContract.persistedSchemaVersion,
      sessionId: _idFactory.next(),
      ownerUid: ownerUid,
      bankVersion: _bank.bankVersion,
      bankLocale: _bank.locale,
      selectionPolicyVersion: EqSessionContract.selectionPolicyVersion,
      scoringPolicyVersion: EqSessionContract.scoringPolicyVersion,
      sessionSeed: sessionSeed,
      itemPlans: plans,
      currentQuestionIndex: 0,
      answers: const [],
      startedAt: now,
      updatedAt: now,
      status: EqPersistedSessionStatus.inProgress,
    );
    final validated = EqPersistedSessionValidator.validate(
      state: state,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
      );
    }
    await _repository.saveSession(state);
    lastOperationComposed = true;
    return EqSessionWriteResult(ok: true, state: state);
  }

  Future<EqSessionWriteResult> _loadValidatedInProgress(
    String ownerUid,
    String sessionId,
  ) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = EqPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
      );
    }
    if (validated.state!.status != EqPersistedSessionStatus.inProgress) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'session_not_in_progress',
        message: 'Session is not in progress',
      );
    }
    return EqSessionWriteResult(ok: true, state: validated.state);
  }

  Future<EqSessionWriteResult> moveToIndex({
    required String ownerUid,
    required String sessionId,
    required int index,
  }) async {
    final loaded = await _loadValidatedInProgress(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (index < 0 || index >= state.itemPlans.length) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'invalid_index',
        message: 'Index outside session range',
      );
    }
    final next = state.copyWith(
      currentQuestionIndex: index,
      updatedAt: _nowIso(),
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }

  Future<EqSessionWriteResult> answer({
    required String ownerUid,
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final loaded = await _loadValidatedInProgress(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    EqSessionItemPlan? plan;
    for (final p in state.itemPlans) {
      if (p.itemId == itemId) {
        plan = p;
        break;
      }
    }
    if (plan == null) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'unknown_item',
        message: 'Item not in session plan',
      );
    }
    if (!plan.displayedOptionIds.contains(selectedOptionId)) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'unknown_option',
        message: 'Option not in displayed order',
      );
    }
    final byId = Map<String, EqSessionAnswer>.from(state.answersByItemId);
    byId[itemId] = EqSessionAnswer(
      itemId: itemId,
      selectedOptionId: selectedOptionId,
      answeredAt: _nowIso(),
    );
    final next = state.copyWith(
      answers: byId.values.toList(),
      updatedAt: _nowIso(),
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }

  Future<EqSessionWriteResult> complete({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _loadValidatedInProgress(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (state.answers.length != state.itemPlans.length) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'incomplete_session',
        message: 'Not all items answered',
      );
    }
    for (final p in state.itemPlans) {
      if (!state.answersByItemId.containsKey(p.itemId)) {
        return const EqSessionWriteResult(
          ok: false,
          code: 'incomplete_session',
          message: 'Missing answer for plan item',
        );
      }
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: EqPersistedSessionStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }
}
