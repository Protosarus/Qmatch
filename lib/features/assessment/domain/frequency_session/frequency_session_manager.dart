import 'dart:math';

import '../frequency_bank/frequency_bank.dart';
import 'frequency_persisted_session_state.dart';
import 'frequency_session_contract.dart';
import 'frequency_session_persistence_repository.dart';

/// Compose full 50-item Frequency session + durable resume.
///
/// HOTFIX: answer-complete locks answers as [completedPendingPersistence]
/// while keeping the active pointer until remote finalization succeeds.
class FrequencySessionManager {
  FrequencySessionManager({
    required FrequencyCanonicalBankDocument bank,
    required FrequencySessionPersistenceRepository repository,
    FrequencySessionIdFactory? idFactory,
    DateTime Function()? clock,
    Random? shuffleRandom,
  })  : _bank = bank,
        _repository = repository,
        _idFactory = idFactory ?? FrequencySessionIdFactory(),
        _clock = clock ?? DateTime.now,
        _shuffleRandom = shuffleRandom;

  final FrequencyCanonicalBankDocument _bank;
  final FrequencySessionPersistenceRepository _repository;
  final FrequencySessionIdFactory _idFactory;
  final DateTime Function() _clock;
  final Random? _shuffleRandom;

  bool lastOperationComposed = false;

  String _nowIso() => _clock().toUtc().toIso8601String();

  Random _rngForSeed(String sessionSeed) {
    final override = _shuffleRandom;
    if (override != null) return override;
    return Random(sessionSeed.hashCode);
  }

  List<FrequencySessionItemPlan> _composePlans(String sessionSeed) {
    final bankCheck = const FrequencyCanonicalBankValidator().validate(_bank);
    if (!bankCheck.ok) {
      throw StateError(
          'Invalid Frequency bank: ${bankCheck.issues.join('; ')}');
    }
    final items = [..._bank.items]
      ..sort((a, b) => a.itemId.compareTo(b.itemId));
    final rng = _rngForSeed(sessionSeed);
    return [
      for (final item in items)
        FrequencySessionItemPlan(
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

  /// Resume valid in-progress / pending-finalization draft, else compose new.
  Future<FrequencySessionWriteResult> getOrCreateActiveSession({
    required String ownerUid,
    required String sessionSeed,
  }) async {
    lastOperationComposed = false;
    if (ownerUid.trim().isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }

    final existing = await _repository.loadActiveSession(ownerUid);
    if (existing.isLoaded) {
      final validated = FrequencyPersistedSessionValidator.validate(
        state: existing.state!,
        bank: _bank,
        ownerUid: ownerUid,
      );
      if (validated.isLoaded) {
        final status = validated.state!.status;
        if (status == FrequencyPersistedSessionStatus.inProgress ||
            status ==
                FrequencyPersistedSessionStatus.completedPendingPersistence) {
          return FrequencySessionWriteResult(ok: true, state: validated.state);
        }
      }
      if (validated.code == FrequencySessionLoadCode.incompatibleBank ||
          validated.code == FrequencySessionLoadCode.incompatiblePolicy ||
          validated.code == FrequencySessionLoadCode.incompatibleSchema ||
          validated.code == FrequencySessionLoadCode.corrupt ||
          validated.code == FrequencySessionLoadCode.ownerMismatch) {
        return FrequencySessionWriteResult(
          ok: false,
          code: validated.code.name,
          message: validated.message,
          state: existing.state,
        );
      }
    } else if (existing.code == FrequencySessionLoadCode.corrupt ||
        existing.code == FrequencySessionLoadCode.ownerMismatch) {
      return FrequencySessionWriteResult(
        ok: false,
        code: existing.code.name,
        message: existing.message,
      );
    }

    // Conservative recovery for pre-hotfix stuck sessions:
    // exactly one non-finalized completed 50-answer blob for this UID+bank.
    final recovered = await _recoverUniqueStuckCompleted(ownerUid);
    if (recovered != null) {
      return recovered;
    }

    final plans = _composePlans(sessionSeed);
    final now = _nowIso();
    final state = FrequencyPersistedSessionState(
      schemaVersion: FrequencySessionContract.persistedSchemaVersion,
      sessionId: _idFactory.next(),
      ownerUid: ownerUid,
      bankVersion: _bank.bankVersion,
      bankLocale: _bank.locale,
      selectionPolicyVersion: FrequencySessionContract.selectionPolicyVersion,
      scoringPolicyVersion: FrequencySessionContract.scoringPolicyVersion,
      sessionSeed: sessionSeed,
      itemPlans: plans,
      currentQuestionIndex: 0,
      answers: const [],
      startedAt: now,
      updatedAt: now,
      status: FrequencyPersistedSessionStatus.inProgress,
    );
    final validated = FrequencyPersistedSessionValidator.validate(
      state: state,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
      );
    }
    await _repository.saveSession(state);
    lastOperationComposed = true;
    return FrequencySessionWriteResult(ok: true, state: state);
  }

  /// Promote a unique stuck pre-hotfix `completed` session into pending.
  Future<FrequencySessionWriteResult?> _recoverUniqueStuckCompleted(
    String ownerUid,
  ) async {
    final listed = await _repository.listOwnerSessions(ownerUid);
    final candidates = <FrequencyPersistedSessionState>[];
    for (final raw in listed) {
      if (raw.ownerUid != ownerUid) continue;
      if (raw.remoteFinalized) continue;
      if (raw.status != FrequencyPersistedSessionStatus.completed &&
          raw.status !=
              FrequencyPersistedSessionStatus.completedPendingPersistence) {
        continue;
      }
      if (raw.answers.length != FrequencySessionContract.sessionItemCount) {
        continue;
      }
      final validated = FrequencyPersistedSessionValidator.validate(
        state: raw,
        bank: _bank,
        ownerUid: ownerUid,
      );
      if (!validated.isLoaded) continue;
      candidates.add(validated.state!);
    }
    if (candidates.length != 1) {
      // 0 → compose new; >1 → unsafe, do not guess.
      return null;
    }
    final only = candidates.single;
    if (only.status ==
            FrequencyPersistedSessionStatus.completedPendingPersistence &&
        only.remoteFinalized == false) {
      // Re-attach active pointer if missing.
      await _repository.saveSession(only);
      return FrequencySessionWriteResult(ok: true, state: only);
    }
    final now = _nowIso();
    final pending = only.copyWith(
      status: FrequencyPersistedSessionStatus.completedPendingPersistence,
      remoteFinalized: false,
      updatedAt: now,
      completedAt: only.completedAt ?? now,
    );
    await _repository.saveSession(pending);
    return FrequencySessionWriteResult(ok: true, state: pending);
  }

  Future<FrequencySessionWriteResult> _loadValidatedEditable(
    String ownerUid,
    String sessionId,
  ) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = FrequencyPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
        state: loaded.state,
      );
    }
    if (!validated.state!.status.isAnswerEditable) {
      return FrequencySessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Session is ${validated.state!.status.name}',
        state: validated.state,
      );
    }
    return FrequencySessionWriteResult(ok: true, state: validated.state);
  }

  Future<FrequencySessionWriteResult> moveToIndex({
    required String ownerUid,
    required String sessionId,
    required int index,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (index < 0 || index >= state.itemPlans.length) {
      return const FrequencySessionWriteResult(
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
    return FrequencySessionWriteResult(ok: true, state: next);
  }

  Future<FrequencySessionWriteResult> answer({
    required String ownerUid,
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (!state.status.isAnswerEditable) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Completed/abandoned sessions reject answers',
      );
    }
    FrequencySessionItemPlan? plan;
    for (final p in state.itemPlans) {
      if (p.itemId == itemId) {
        plan = p;
        break;
      }
    }
    if (plan == null) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'unknown_item',
        message: 'Item not in session plan',
      );
    }
    if (!plan.displayedOptionIds.contains(selectedOptionId)) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'unknown_option',
        message: 'Option not in displayed order',
      );
    }
    final byId =
        Map<String, FrequencySessionAnswer>.from(state.answersByItemId);
    byId[itemId] = FrequencySessionAnswer(
      itemId: itemId,
      selectedOptionId: selectedOptionId,
      answeredAt: _nowIso(),
    );
    final next = state.copyWith(
      answers: byId.values.toList(),
      updatedAt: _nowIso(),
    );
    await _repository.saveSession(next);
    return FrequencySessionWriteResult(ok: true, state: next);
  }

  /// Lock the 50-answer set for scoring while keeping resume/finalization.
  ///
  /// Status becomes [FrequencyPersistedSessionStatus.completedPendingPersistence]
  /// (active pointer retained). Call [markRemoteFinalized] only after remote
  /// assessments/frequency + progress + canonical_v1 succeed.
  Future<FrequencySessionWriteResult> complete({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (state.itemPlans.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'invalid_plan',
        message: 'Session must contain 50 items',
      );
    }
    if (state.answers.length != FrequencySessionContract.sessionItemCount) {
      return FrequencySessionWriteResult(
        ok: false,
        code: 'incomplete_session',
        message:
            'Need ${FrequencySessionContract.sessionItemCount} answers, have ${state.answers.length}',
      );
    }
    for (final p in state.itemPlans) {
      if (!state.answersByItemId.containsKey(p.itemId)) {
        return const FrequencySessionWriteResult(
          ok: false,
          code: 'incomplete_session',
          message: 'Missing answer for plan item',
        );
      }
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: FrequencyPersistedSessionStatus.completedPendingPersistence,
      completedAt: now,
      updatedAt: now,
      remoteFinalized: false,
    );
    await _repository.saveSession(next);
    return FrequencySessionWriteResult(ok: true, state: next);
  }

  /// Marks remote pipeline success: scientific `completed` + clear active.
  Future<FrequencySessionWriteResult> markRemoteFinalized({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = FrequencyPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
        state: loaded.state,
      );
    }
    final state = validated.state!;
    if (!state.status.isScoreable &&
        state.status != FrequencyPersistedSessionStatus.completed) {
      return FrequencySessionWriteResult(
        ok: false,
        code: 'session_not_finalizable',
        message: 'Session is ${state.status.wireValue}',
        state: state,
      );
    }
    if (state.answers.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'incomplete_session',
        message: 'Cannot finalize incomplete session',
      );
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: FrequencyPersistedSessionStatus.completed,
      remoteFinalized: true,
      updatedAt: now,
      completedAt: state.completedAt ?? now,
    );
    await _repository.saveSession(next);
    return FrequencySessionWriteResult(ok: true, state: next);
  }
}
