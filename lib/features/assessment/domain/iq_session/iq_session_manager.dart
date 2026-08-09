import '../iq_bank/iq_recovered_bank_document.dart';
import 'iq_persisted_session_state.dart';
import 'iq_session_composer.dart';
import 'iq_session_contract.dart';
import 'iq_session_models.dart';
import 'iq_session_persistence_repository.dart';

/// Runtime-neutral orchestration for compose + durable resume (P2C-2A-3).
///
/// HOTFIX: answer-complete locks answers as [completedPendingPersistence]
/// while keeping the active pointer until remote finalization succeeds.
class IqSessionManager {
  IqSessionManager({
    required IqRecoveredBankDocument bank,
    required IqSessionPersistenceRepository repository,
    IqSessionComposer composer = const IqSessionComposer(),
    IqSessionIdFactory? idFactory,
    DateTime Function()? clock,
  })  : _bank = bank,
        _repository = repository,
        _composer = composer,
        _idFactory = idFactory ?? IqSessionIdFactory(),
        _clock = clock ?? DateTime.now;

  final IqRecoveredBankDocument _bank;
  final IqSessionPersistenceRepository _repository;
  final IqSessionComposer _composer;
  final IqSessionIdFactory _idFactory;
  final DateTime Function() _clock;

  /// Test/observability: set when a fresh compose ran.
  bool lastOperationComposed = false;

  String _nowIso() => _clock().toUtc().toIso8601String();

  /// Resume valid in-progress / pending-finalization draft, else compose new.
  Future<IqSessionWriteResult> getOrCreateActiveSession({
    required String ownerUid,
    required String sessionSeed,
    IqSessionConfig? composeConfig,
  }) async {
    lastOperationComposed = false;
    if (ownerUid.trim().isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }

    final existing = await _repository.loadActiveSession(ownerUid);
    if (existing.isLoaded) {
      final validated = IqPersistedSessionValidator.validate(
        state: existing.state!,
        bank: _bank,
        ownerUid: ownerUid,
      );
      if (validated.isLoaded) {
        final status = validated.state!.status;
        if (status == IqPersistedSessionStatus.inProgress ||
            status == IqPersistedSessionStatus.completedPendingPersistence) {
          return IqSessionWriteResult(ok: true, state: validated.state);
        }
      }
      if (validated.code == IqSessionLoadCode.incompatibleBank ||
          validated.code == IqSessionLoadCode.incompatiblePolicy ||
          validated.code == IqSessionLoadCode.incompatibleSchema ||
          validated.code == IqSessionLoadCode.corrupt ||
          validated.code == IqSessionLoadCode.ownerMismatch) {
        // Do not silently regenerate or delete.
        return IqSessionWriteResult(
          ok: false,
          code: validated.code.name,
          message: validated.message,
          state: existing.state,
        );
      }
    } else if (existing.code == IqSessionLoadCode.corrupt ||
        existing.code == IqSessionLoadCode.ownerMismatch) {
      return IqSessionWriteResult(
        ok: false,
        code: existing.code.name,
        message: existing.message,
      );
    }

    // Conservative recovery for pre-hotfix stuck sessions:
    // exactly one non-finalized completed 25-answer blob for this UID+bank.
    final recovered = await _recoverUniqueStuckCompleted(ownerUid);
    if (recovered != null) {
      return recovered;
    }

    final config = composeConfig ??
        IqSessionConfig(
          sessionSeed: sessionSeed,
        );
    final composed = _composer.compose(bank: _bank, config: config);
    if (composed is! IqSessionCompositionSuccess) {
      final fail = composed as IqSessionCompositionFailure;
      return IqSessionWriteResult(
        ok: false,
        code: fail.code,
        message: fail.message,
      );
    }
    final plan = composed.plan;
    final now = _nowIso();
    final state = IqPersistedSessionState(
      schemaVersion: IqPersistedSessionState.schemaVersionValue,
      sessionId: _idFactory.next(),
      ownerUid: ownerUid,
      bankVersion: plan.bankVersion,
      bankLocale: plan.bankLocale,
      selectionPolicyVersion: plan.selectionPolicyVersion,
      sessionSeed: plan.sessionSeed,
      itemPlans: plan.itemPlans,
      currentQuestionIndex: 0,
      answers: const [],
      startedAt: now,
      updatedAt: now,
      status: IqPersistedSessionStatus.inProgress,
      eligibilityMode: plan.eligibilityMode,
      freshnessMode: plan.freshnessMode,
      balanceDisplayedCorrectPositions: plan.balanceDisplayedCorrectPositions,
      createdFromBankItemCount: plan.createdFromBankItemCount,
    );

    final validated = IqPersistedSessionValidator.validate(
      state: state,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
      );
    }

    await _repository.saveSession(state);
    lastOperationComposed = true;
    return IqSessionWriteResult(ok: true, state: state);
  }

  /// Promote a unique stuck pre-hotfix `completed` session into pending.
  Future<IqSessionWriteResult?> _recoverUniqueStuckCompleted(
    String ownerUid,
  ) async {
    final listed = await _repository.listOwnerSessions(ownerUid);
    final candidates = <IqPersistedSessionState>[];
    for (final raw in listed) {
      if (raw.ownerUid != ownerUid) continue;
      if (raw.remoteFinalized) continue;
      if (raw.status != IqPersistedSessionStatus.completed &&
          raw.status != IqPersistedSessionStatus.completedPendingPersistence) {
        continue;
      }
      if (raw.answers.length != IqSessionContract.sessionItemCount) continue;
      final validated = IqPersistedSessionValidator.validate(
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
    if (only.status == IqPersistedSessionStatus.completedPendingPersistence &&
        only.remoteFinalized == false) {
      // Re-attach active pointer if missing.
      await _repository.saveSession(only);
      return IqSessionWriteResult(ok: true, state: only);
    }
    final now = _nowIso();
    final pending = only.copyWith(
      status: IqPersistedSessionStatus.completedPendingPersistence,
      remoteFinalized: false,
      updatedAt: now,
      completedAt: only.completedAt ?? now,
    );
    await _repository.saveSession(pending);
    return IqSessionWriteResult(ok: true, state: pending);
  }

  /// Forward-only cursor: [index] must be >= currentQuestionIndex.
  Future<IqSessionWriteResult> moveToIndex({
    required String ownerUid,
    required String sessionId,
    required int index,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (index < 0 || index >= state.itemPlans.length) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'invalid_index',
        message: 'Index outside 0..24',
      );
    }
    if (index < state.currentQuestionIndex) {
      return const IqSessionWriteResult(
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
    return IqSessionWriteResult(ok: true, state: next);
  }

  Future<IqSessionWriteResult> answer({
    required String ownerUid,
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (!state.status.isAnswerEditable) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Completed/abandoned sessions reject answers',
      );
    }

    IqSessionItemPlan? planItem;
    for (final p in state.itemPlans) {
      if (p.itemId == itemId) {
        planItem = p;
        break;
      }
    }
    if (planItem == null) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'invalid_item',
        message: 'Item not in session',
      );
    }
    if (!planItem.displayedOptionIds.contains(selectedOptionId)) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'invalid_option',
        message: 'Option not in displayed options',
      );
    }

    final byId = state.answersByItemId;
    final existing = byId[itemId];
    if (existing != null) {
      if (existing.selectedOptionId == selectedOptionId) {
        return IqSessionWriteResult(ok: true, state: state);
      }
      return const IqSessionWriteResult(
        ok: false,
        code: 'answer_already_committed',
        message: 'Committed assessment responses are immutable',
      );
    }
    byId[itemId] = IqSessionAnswer(
      itemId: itemId,
      selectedOptionId: selectedOptionId,
      answeredAt: _nowIso(),
    );
    // Rebuild answers in plan order.
    final ordered = <IqSessionAnswer>[
      for (final p in state.itemPlans)
        if (byId.containsKey(p.itemId)) byId[p.itemId]!,
    ];
    final next = state.copyWith(answers: ordered, updatedAt: _nowIso());
    await _repository.saveSession(next);
    return IqSessionWriteResult(ok: true, state: next);
  }

  /// Lock the 25-answer set for scoring while keeping resume/finalization.
  ///
  /// Status becomes [IqPersistedSessionStatus.completedPendingPersistence]
  /// (active pointer retained). Call [markRemoteFinalized] only after remote
  /// assessments/iq + progress + canonical_v1 succeed.
  Future<IqSessionWriteResult> complete({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _loadValidatedEditable(ownerUid, sessionId);
    if (!loaded.ok) return loaded;
    final state = loaded.state!;
    if (state.itemPlans.length != IqSessionContract.sessionItemCount) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'invalid_plan',
        message: 'Session must contain 25 items',
      );
    }
    if (state.answers.length != IqSessionContract.sessionItemCount) {
      return IqSessionWriteResult(
        ok: false,
        code: 'incomplete_answers',
        message:
            'Need ${IqSessionContract.sessionItemCount} answers, have ${state.answers.length}',
      );
    }
    for (final p in state.itemPlans) {
      if (!state.answersByItemId.containsKey(p.itemId)) {
        return const IqSessionWriteResult(
          ok: false,
          code: 'incomplete_answers',
          message: 'Missing answer for an item',
        );
      }
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: IqPersistedSessionStatus.completedPendingPersistence,
      completedAt: now,
      updatedAt: now,
      remoteFinalized: false,
    );
    await _repository.saveSession(next);
    return IqSessionWriteResult(ok: true, state: next);
  }

  /// Marks remote pipeline success: scientific `completed` + clear active.
  Future<IqSessionWriteResult> markRemoteFinalized({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = IqPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
        state: loaded.state,
      );
    }
    final state = validated.state!;
    if (!state.status.isScoreable &&
        state.status != IqPersistedSessionStatus.completed) {
      return IqSessionWriteResult(
        ok: false,
        code: 'session_not_finalizable',
        message: 'Session is ${state.status.wireValue}',
        state: state,
      );
    }
    if (state.answers.length != IqSessionContract.sessionItemCount) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'incomplete_answers',
        message: 'Cannot finalize incomplete session',
      );
    }
    final now = _nowIso();
    final next = state.copyWith(
      status: IqPersistedSessionStatus.completed,
      remoteFinalized: true,
      updatedAt: now,
      completedAt: state.completedAt ?? now,
    );
    await _repository.saveSession(next);
    return IqSessionWriteResult(ok: true, state: next);
  }

  Future<IqSessionWriteResult> abandon({
    required String ownerUid,
    required String sessionId,
  }) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = IqPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
      );
    }
    final now = _nowIso();
    final next = validated.state!.copyWith(
      status: IqPersistedSessionStatus.abandoned,
      updatedAt: now,
    );
    await _repository.saveSession(next);
    return IqSessionWriteResult(ok: true, state: next);
  }

  Future<IqSessionWriteResult> _loadValidatedEditable(
    String ownerUid,
    String sessionId,
  ) async {
    final loaded = await _repository.loadSession(ownerUid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final validated = IqPersistedSessionValidator.validate(
      state: loaded.state!,
      bank: _bank,
      ownerUid: ownerUid,
    );
    if (!validated.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: validated.code.name,
        message: validated.message,
        state: loaded.state,
      );
    }
    if (!validated.state!.status.isAnswerEditable) {
      return IqSessionWriteResult(
        ok: false,
        code: 'session_not_editable',
        message: 'Session is ${validated.state!.status.name}',
        state: validated.state,
      );
    }
    return IqSessionWriteResult(ok: true, state: validated.state);
  }
}
