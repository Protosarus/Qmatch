import 'dart:convert';
import 'dart:math';

import '../eq_bank/eq_bank.dart';
import 'eq_persisted_session_state.dart';
import 'eq_session_contract.dart';

class EqSessionIdFactory {
  EqSessionIdFactory({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String next() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'eq_sess_$hex';
  }
}

class EqSessionStorageKeys {
  EqSessionStorageKeys._();

  static const prefix = 'qmatch.eq_session.v1';

  static String activePointer(String uid) => '$prefix.active.$uid';

  static String session(String uid, String sessionId) =>
      '$prefix.session.$uid.$sessionId';

  static String sessionPrefix(String ownerUid) => '$prefix.session.$ownerUid.';
}

enum EqSessionLoadCode {
  loaded,
  notFound,
  corrupt,
  ownerMismatch,
  ownerUnavailable,
  incompatibleBank,
  incompatiblePolicy,
  incompatibleSchema,
}

class EqSessionLoadResult {
  const EqSessionLoadResult({
    required this.code,
    this.state,
    this.message = '',
  });

  final EqSessionLoadCode code;
  final EqPersistedSessionState? state;
  final String message;

  bool get isLoaded => code == EqSessionLoadCode.loaded && state != null;
}

class EqSessionWriteResult {
  const EqSessionWriteResult({
    required this.ok,
    this.state,
    this.code = '',
    this.message = '',
  });

  final bool ok;
  final EqPersistedSessionState? state;
  final String code;
  final String message;
}

abstract class EqSessionPersistenceRepository {
  Future<void> saveSession(EqPersistedSessionState state);
  Future<EqSessionLoadResult> loadActiveSession(String ownerUid);
  Future<EqSessionLoadResult> loadSession(String ownerUid, String sessionId);
  Future<void> deleteSession(String ownerUid, String sessionId);
  Future<void> clearOwnerSessions(String ownerUid);

  /// Lists durable session blobs for [ownerUid] (UID-scoped only).
  Future<List<EqPersistedSessionState>> listOwnerSessions(String ownerUid);
}

class EqSessionMemoryRepository implements EqSessionPersistenceRepository {
  final Map<String, String> _store = {};

  @override
  Future<void> saveSession(EqPersistedSessionState state) async {
    final key = EqSessionStorageKeys.session(state.ownerUid, state.sessionId);
    _store[key] = jsonEncode(state.toJson());
    final activeKey = EqSessionStorageKeys.activePointer(state.ownerUid);
    if (state.status.keepsActivePointer) {
      _store[activeKey] = state.sessionId;
    } else if (_store[activeKey] == state.sessionId) {
      _store.remove(activeKey);
    }
  }

  @override
  Future<EqSessionLoadResult> loadActiveSession(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final sid = _store[EqSessionStorageKeys.activePointer(ownerUid)];
    if (sid == null || sid.isEmpty) {
      return const EqSessionLoadResult(code: EqSessionLoadCode.notFound);
    }
    return loadSession(ownerUid, sid);
  }

  @override
  Future<EqSessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final raw = _store[EqSessionStorageKeys.session(ownerUid, sessionId)];
    if (raw == null) {
      return const EqSessionLoadResult(code: EqSessionLoadCode.notFound);
    }
    try {
      final state = EqPersistedSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (state.ownerUid != ownerUid) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.ownerMismatch,
          message: 'Owner mismatch',
        );
      }
      return EqSessionLoadResult(
        code: EqSessionLoadCode.loaded,
        state: state,
      );
    } catch (_) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    _store.remove(EqSessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = EqSessionStorageKeys.activePointer(ownerUid);
    if (_store[activeKey] == sessionId) _store.remove(activeKey);
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefix = EqSessionStorageKeys.sessionPrefix(ownerUid);
    _store.removeWhere(
      (k, _) =>
          k.startsWith(prefix) ||
          k == EqSessionStorageKeys.activePointer(ownerUid),
    );
  }

  @override
  Future<List<EqPersistedSessionState>> listOwnerSessions(
    String ownerUid,
  ) async {
    if (ownerUid.trim().isEmpty) return const [];
    final prefix = EqSessionStorageKeys.sessionPrefix(ownerUid);
    final out = <EqPersistedSessionState>[];
    for (final e in _store.entries) {
      if (!e.key.startsWith(prefix)) continue;
      try {
        final state = EqPersistedSessionState.fromJson(
          jsonDecode(e.value) as Map<String, dynamic>,
        );
        if (state.ownerUid == ownerUid) out.add(state);
      } catch (_) {
        // Skip corrupt blobs during listing.
      }
    }
    return out;
  }
}

class EqPersistedSessionValidator {
  EqPersistedSessionValidator._();

  static EqSessionLoadResult validate({
    required EqPersistedSessionState state,
    required EqCanonicalBankDocument bank,
    required String ownerUid,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    if (state.ownerUid != ownerUid) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.ownerMismatch,
        message: 'Owner mismatch',
      );
    }
    if (state.schemaVersion != EqSessionContract.persistedSchemaVersion) {
      return EqSessionLoadResult(
        code: EqSessionLoadCode.incompatibleSchema,
        message: 'Unsupported schema ${state.schemaVersion}',
      );
    }
    if (state.bankVersion != bank.bankVersion ||
        state.bankLocale != bank.locale) {
      return EqSessionLoadResult(
        code: EqSessionLoadCode.incompatibleBank,
        message: 'Bank mismatch',
      );
    }
    if (state.selectionPolicyVersion !=
            EqSessionContract.selectionPolicyVersion ||
        state.scoringPolicyVersion != EqSessionContract.scoringPolicyVersion) {
      return EqSessionLoadResult(
        code: EqSessionLoadCode.incompatiblePolicy,
        message: 'Policy mismatch',
      );
    }
    if (state.itemPlans.length != EqSessionContract.sessionItemCount) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.corrupt,
        message: 'Item plan count invalid',
      );
    }
    final bankById = bank.itemsById;
    final seen = <String>{};
    for (final p in state.itemPlans) {
      if (!seen.add(p.itemId)) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Duplicate plan item',
        );
      }
      final item = bankById[p.itemId];
      if (item == null) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Unknown plan item',
        );
      }
      if (p.primaryDimension != item.primaryDimension) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Plan dimension mismatch',
        );
      }
      final optIds = item.options.map((o) => o.optionId).toSet();
      if (p.displayedOptionIds.length != optIds.length ||
          !p.displayedOptionIds.every(optIds.contains)) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Displayed options mismatch',
        );
      }
    }
    final planById = {for (final p in state.itemPlans) p.itemId: p};
    for (final a in state.answers) {
      final plan = planById[a.itemId];
      if (plan == null) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Answer for unknown plan item',
        );
      }
      if (!plan.displayedOptionIds.contains(a.selectedOptionId)) {
        return const EqSessionLoadResult(
          code: EqSessionLoadCode.corrupt,
          message: 'Selected option not in displayed order',
        );
      }
    }
    if (state.currentQuestionIndex < 0 ||
        state.currentQuestionIndex >= state.itemPlans.length) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.corrupt,
        message: 'Invalid current index',
      );
    }
    return EqSessionLoadResult(code: EqSessionLoadCode.loaded, state: state);
  }
}
