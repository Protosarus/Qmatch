import 'dart:math';

import '../eq_bank/eq_bank.dart';
import 'eq_persisted_session_state.dart';
import 'eq_session_contract.dart';
import 'eq_session_persistence_repository.dart';

/// Compose full 30-item EQ session + durable resume.
///
/// HOTFIX: answer-complete locks answers as [completedPendingPersistence]
/// while keeping the active pointer until remote finalization succeeds.
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

  /// Resume valid in-progress / pending-finalization draft, else compose new.
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
      if (validated.isLoaded) {
        final status = validated.state!.status;
        if (status == EqPersistedSessionStatus.inProgress ||
            status == EqPersistedSessionStatus.completedPendingPersistence) {
          final reconciled = await reconcileCursorToFirstUnanswered(
            ownerUid: ownerUid,
            sessionId: validated.state!.sessionId,
          );
          if (reconciled.ok && reconciled.state != null) {
            return reconciled;
          }
          return EqSessionWriteResult(ok: true, state: validated.state);
        }
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

    // Conservative recovery for pre-hotfix stuck sessions:
    // exactly one non-finalized completed 30-answer blob for this UID+bank.
    final recovered = await _recoverUniqueStuckCompleted(ownerUid);
    if (recovered != null) {
      return recovered;
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

  /// Promote a unique stuck pre-hotfix `completed` session into pending.
  Future<EqSessionWriteResult?> _recoverUniqueStuckCompleted(
    String ownerUid,
  ) async {
    final listed = await _repository.listOwnerSessions(ownerUid);
    final candidates = <EqPersistedSessionState>[];
    for (final raw in listed) {
      if (raw.ownerUid != ownerUid) continue;
      if (raw.remoteFinalized) continue;
      if (raw.status != EqPersistedSessionStatus.completed &&
          raw.status != EqPersistedSessionStatus.completedPendingPersistence) {
        continue;
      }
      if (raw.answers.length != EqSessionContract.sessionItemCount) continue;
      final validated = EqPersistedSessionValidator.validate(
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
    if (only.status == EqPersistedSessionStatus.completedPendingPersistence &&
        only.remoteFinalized == false) {
      // Re-attach active pointer if missing.
      await _repository.saveSession(only);
      return EqSessionWriteResult(ok: true, state: only);
    }
    final now = _nowIso();
    final pending = only.copyWith(
      status: EqPersistedSessionStatus.completedPendingPersistence,
      remoteFinalized: false,
      updatedAt: now,
      completedAt: only.completedAt ?? now,
    );
    await _repository.saveSession(pending);
    return EqSessionWriteResult(ok: true, state: pending);
  }

  Future<EqSessionWriteResult> _loadValidatedEditable(
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
        state: loaded.state,
      );
    }
    if (!validated.state!.status.isAnswerEditable) {
      return EqSessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Session is ${validated.state!.status.name}',
        state: validated.state,
      );
    }
    return EqSessionWriteResult(ok: true, state: validated.state);
  }

  /// Forward-only cursor: [index] must be >= currentQuestionIndex.
  Future<EqSessionWriteResult> moveToIndex({
    required String ownerUid,
    required String sessionId,
    required int index,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (index < 0 || index >= state.itemPlans.length) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'invalid_index',
        message: 'Index outside session range',
      );
    }
    if (index < state.currentQuestionIndex) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'cursor_not_forward',
        message: 'Assessment cursor is forward-only',
      );
    }
    final next = state.copyWith(
      currentQuestionIndex: index,
      updatedAt: _nowIso(),
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }

  /// Recovery: if the cursor sits on an already-committed item, advance it to
  /// the first unanswered index. Bypasses forward-only user navigation rules.
  Future<EqSessionWriteResult> reconcileCursorToFirstUnanswered({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final state = loaded.state!;
    if (state.status == EqPersistedSessionStatus.completedPendingPersistence ||
        state.status == EqPersistedSessionStatus.completed) {
      return EqSessionWriteResult(ok: true, state: state);
    }
    if (!state.status.isAnswerEditable) {
      return EqSessionWriteResult(ok: true, state: state);
    }
    final raw = state.firstUnansweredIndex;
    final target =
        raw >= state.itemPlans.length ? state.itemPlans.length - 1 : raw;
    if (target == state.currentQuestionIndex) {
      return EqSessionWriteResult(ok: true, state: state);
    }
    final next = state.copyWith(
      currentQuestionIndex: target,
      updatedAt: _nowIso(),
    );
    final validated = EqPersistedSessionValidator.validate(
      state: next,
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
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }

  Future<EqSessionWriteResult> answer({
    required String ownerUid,
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (!state.status.isAnswerEditable) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Completed/abandoned sessions reject answers',
      );
    }
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
    final existing = byId[itemId];
    if (existing != null) {
      if (existing.selectedOptionId == selectedOptionId) {
        return EqSessionWriteResult(ok: true, state: state);
      }
      return const EqSessionWriteResult(
        ok: false,
        code: 'answer_already_committed',
        message: 'Committed assessment responses are immutable',
      );
    }
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

  /// Lock the 30-answer set for scoring while keeping resume/finalization.
  ///
  /// Status becomes [EqPersistedSessionStatus.completedPendingPersistence]
  /// (active pointer retained). Call [markRemoteFinalized] only after remote
  /// assessments/eq + progress + canonical_v1 succeed.
  Future<EqSessionWriteResult> complete({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (state.itemPlans.length != EqSessionContract.sessionItemCount) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'invalid_plan',
        message: 'Session must contain 30 items',
      );
    }
    if (state.answers.length != EqSessionContract.sessionItemCount) {
      return EqSessionWriteResult(
        ok: false,
        code: 'incomplete_session',
        message:
            'Need ${EqSessionContract.sessionItemCount} answers, have ${state.answers.length}',
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
      status: EqPersistedSessionStatus.completedPendingPersistence,
      completedAt: now,
      updatedAt: now,
      remoteFinalized: false,
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }

  /// Marks remote pipeline success: scientific `completed` + clear active.
  Future<EqSessionWriteResult> markRemoteFinalized({
    required String ownerUid,
    required String sessionId,
  }) async {
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
        state: loaded.state,
      );
    }
    final state = validated.state!;
    if (!state.status.isScoreable &&
        state.status != EqPersistedSessionStatus.completed) {
      return EqSessionWriteResult(
        ok: false,
        code: 'session_not_finalizable',
        message: 'Session is ${state.status.wireValue}',
        state: state,
      );
    }
    if (state.answers.length != EqSessionContract.sessionItemCount) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'incomplete_session',
        message: 'Cannot finalize incomplete session',
      );
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: EqPersistedSessionStatus.completed,
      remoteFinalized: true,
      updatedAt: now,
      completedAt: state.completedAt ?? now,
    );
    await _repository.saveSession(next);
    return EqSessionWriteResult(ok: true, state: next);
  }
}
