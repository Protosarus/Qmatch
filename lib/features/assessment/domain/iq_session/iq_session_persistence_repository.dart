import 'dart:convert';
import 'dart:math';

import '../iq_bank/iq_recovered_bank_document.dart';
import 'iq_persisted_session_state.dart';
import 'iq_session_contract.dart';
import 'iq_session_plan_validator.dart';

/// Generates a stable opaque session id (no PII). Not used as composition seed.
class IqSessionIdFactory {
  IqSessionIdFactory({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String next() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'iq_sess_$hex';
  }
}

/// Validates a persisted session against the active bank before resume.
class IqPersistedSessionValidator {
  IqPersistedSessionValidator._();

  static IqSessionLoadResult validate({
    required IqPersistedSessionState state,
    required IqRecoveredBankDocument bank,
    required String ownerUid,
    String expectedPolicyVersion = IqSessionContract.selectionPolicyVersion,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    if (state.ownerUid != ownerUid) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.ownerMismatch,
        message: 'Owner mismatch',
      );
    }
    if (state.schemaVersion != IqPersistedSessionState.schemaVersionValue) {
      return IqSessionLoadResult(
        code: IqSessionLoadCode.incompatibleSchema,
        message: 'Unsupported schema ${state.schemaVersion}',
      );
    }
    if (state.bankVersion != bank.bankVersion) {
      return IqSessionLoadResult(
        code: IqSessionLoadCode.incompatibleBank,
        message:
            'Stored bank ${state.bankVersion} != active ${bank.bankVersion}',
      );
    }
    if (state.selectionPolicyVersion != expectedPolicyVersion) {
      return IqSessionLoadResult(
        code: IqSessionLoadCode.incompatiblePolicy,
        message:
            'Stored policy ${state.selectionPolicyVersion} != $expectedPolicyVersion',
      );
    }

    final correctByItem = {
      for (final i in bank.items) i.id: i.correctOptionId,
    };
    final hydrated = state.rehydrateDisplayedCorrectPositions(correctByItem);

    final planValidation = IqSessionPlanValidator.validate(
      plan: hydrated.toSessionPlan(),
      bank: bank,
    );
    if (!planValidation.ok) {
      return IqSessionLoadResult(
        code: IqSessionLoadCode.corrupt,
        message: planValidation.issues.map((e) => e.message).join('; '),
      );
    }

    if (state.currentQuestionIndex < 0 ||
        state.currentQuestionIndex >= state.itemPlans.length) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.corrupt,
        message: 'Invalid current_question_index',
      );
    }

    final planIds = hydrated.itemPlans.map((e) => e.itemId).toSet();
    final byId = {for (final i in bank.items) i.id: i};
    final seenAnswerItems = <String>{};
    for (final a in hydrated.answers) {
      if (!seenAnswerItems.add(a.itemId)) {
        return const IqSessionLoadResult(
          code: IqSessionLoadCode.corrupt,
          message: 'Duplicate answer item',
        );
      }
      if (!planIds.contains(a.itemId)) {
        return const IqSessionLoadResult(
          code: IqSessionLoadCode.corrupt,
          message: 'Answer for unknown item',
        );
      }
      final planItem =
          hydrated.itemPlans.firstWhere((p) => p.itemId == a.itemId);
      if (!planItem.displayedOptionIds.contains(a.selectedOptionId)) {
        return const IqSessionLoadResult(
          code: IqSessionLoadCode.corrupt,
          message: 'Answer option not in displayed options',
        );
      }
      final bankItem = byId[a.itemId];
      if (bankItem == null ||
          !bankItem.options.any((o) => o.id == a.selectedOptionId)) {
        return const IqSessionLoadResult(
          code: IqSessionLoadCode.corrupt,
          message: 'Answer option not in bank item',
        );
      }
    }

    return IqSessionLoadResult(code: IqSessionLoadCode.loaded, state: hydrated);
  }
}

/// Storage key helpers — UID namespaced; no email/phone.
class IqSessionStorageKeys {
  IqSessionStorageKeys._();

  static const prefix = 'qmatch.iq_session.v1';

  static String activePointer(String ownerUid) => '$prefix.active.$ownerUid';

  static String session(String ownerUid, String sessionId) =>
      '$prefix.session.$ownerUid.$sessionId';
}

/// Abstract durable store for IQ session drafts.
abstract class IqSessionPersistenceRepository {
  Future<void> saveSession(IqPersistedSessionState state);

  Future<IqSessionLoadResult> loadActiveSession(String ownerUid);

  Future<IqSessionLoadResult> loadSession(String ownerUid, String sessionId);

  Future<void> deleteSession(String ownerUid, String sessionId);

  Future<void> clearOwnerSessions(String ownerUid);
}

/// In-memory repository for tests / CLI (no Flutter binding).
class IqSessionMemoryRepository implements IqSessionPersistenceRepository {
  final Map<String, String> _kv = {};

  Map<String, String> get debugSnapshot => Map.unmodifiable(_kv);

  /// Test/CLI helper: write raw string without decode (corrupt injection).
  void putRaw(String key, String value) {
    _kv[key] = value;
  }

  @override
  Future<void> saveSession(IqPersistedSessionState state) async {
    final json = jsonEncode(state.toJson());
    _kv[IqSessionStorageKeys.session(state.ownerUid, state.sessionId)] = json;
    if (state.status == IqPersistedSessionStatus.inProgress) {
      _kv[IqSessionStorageKeys.activePointer(state.ownerUid)] = state.sessionId;
    } else {
      final activeKey = IqSessionStorageKeys.activePointer(state.ownerUid);
      if (_kv[activeKey] == state.sessionId) {
        _kv.remove(activeKey);
      }
    }
  }

  @override
  Future<IqSessionLoadResult> loadActiveSession(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final sid = _kv[IqSessionStorageKeys.activePointer(ownerUid)];
    if (sid == null || sid.isEmpty) {
      return const IqSessionLoadResult(code: IqSessionLoadCode.notFound);
    }
    return loadSession(ownerUid, sid);
  }

  @override
  Future<IqSessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final raw = _kv[IqSessionStorageKeys.session(ownerUid, sessionId)];
    if (raw == null) {
      return const IqSessionLoadResult(code: IqSessionLoadCode.notFound);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final state = IqPersistedSessionState.fromJson(map);
      if (state.ownerUid != ownerUid) {
        return const IqSessionLoadResult(
          code: IqSessionLoadCode.ownerMismatch,
          message: 'Owner mismatch',
        );
      }
      return IqSessionLoadResult(code: IqSessionLoadCode.loaded, state: state);
    } catch (e) {
      return IqSessionLoadResult(
        code: IqSessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    _kv.remove(IqSessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = IqSessionStorageKeys.activePointer(ownerUid);
    if (_kv[activeKey] == sessionId) {
      _kv.remove(activeKey);
    }
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefixSession = '${IqSessionStorageKeys.prefix}.session.$ownerUid.';
    final keys = _kv.keys
        .where(
          (k) =>
              k.startsWith(prefixSession) ||
              k == IqSessionStorageKeys.activePointer(ownerUid),
        )
        .toList();
    for (final k in keys) {
      _kv.remove(k);
    }
  }
}
