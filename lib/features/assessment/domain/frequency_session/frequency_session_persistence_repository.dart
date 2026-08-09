import 'dart:convert';
import 'dart:math';

import '../frequency_bank/frequency_bank.dart';
import 'frequency_persisted_session_state.dart';
import 'frequency_session_contract.dart';

class FrequencySessionIdFactory {
  FrequencySessionIdFactory({Random? random})
      : _random = random ?? Random.secure();

  final Random _random;

  String next() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'frequency_sess_$hex';
  }
}

class FrequencySessionStorageKeys {
  FrequencySessionStorageKeys._();

  static const prefix = 'qmatch.frequency_session.v1';

  static String activePointer(String uid) => '$prefix.active.$uid';

  static String session(String uid, String sessionId) =>
      '$prefix.session.$uid.$sessionId';
}

enum FrequencySessionLoadCode {
  loaded,
  notFound,
  corrupt,
  ownerMismatch,
  ownerUnavailable,
  incompatibleBank,
  incompatiblePolicy,
  incompatibleSchema,
}

class FrequencySessionLoadResult {
  const FrequencySessionLoadResult({
    required this.code,
    this.state,
    this.message = '',
  });

  final FrequencySessionLoadCode code;
  final FrequencyPersistedSessionState? state;
  final String message;

  bool get isLoaded => code == FrequencySessionLoadCode.loaded && state != null;
}

class FrequencySessionWriteResult {
  const FrequencySessionWriteResult({
    required this.ok,
    this.state,
    this.code = '',
    this.message = '',
  });

  final bool ok;
  final FrequencyPersistedSessionState? state;
  final String code;
  final String message;
}

abstract class FrequencySessionPersistenceRepository {
  Future<void> saveSession(FrequencyPersistedSessionState state);
  Future<FrequencySessionLoadResult> loadActiveSession(String ownerUid);
  Future<FrequencySessionLoadResult> loadSession(
      String ownerUid, String sessionId);
  Future<void> deleteSession(String ownerUid, String sessionId);
  Future<void> clearOwnerSessions(String ownerUid);
}

class FrequencySessionMemoryRepository
    implements FrequencySessionPersistenceRepository {
  final Map<String, String> _store = {};

  @override
  Future<void> saveSession(FrequencyPersistedSessionState state) async {
    final key =
        FrequencySessionStorageKeys.session(state.ownerUid, state.sessionId);
    _store[key] = jsonEncode(state.toJson());
    final activeKey = FrequencySessionStorageKeys.activePointer(state.ownerUid);
    if (state.status == FrequencyPersistedSessionStatus.inProgress) {
      _store[activeKey] = state.sessionId;
    } else if (_store[activeKey] == state.sessionId) {
      _store.remove(activeKey);
    }
  }

  @override
  Future<FrequencySessionLoadResult> loadActiveSession(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final sid = _store[FrequencySessionStorageKeys.activePointer(ownerUid)];
    if (sid == null || sid.isEmpty) {
      return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.notFound);
    }
    return loadSession(ownerUid, sid);
  }

  @override
  Future<FrequencySessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final raw =
        _store[FrequencySessionStorageKeys.session(ownerUid, sessionId)];
    if (raw == null) {
      return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.notFound);
    }
    try {
      final state = FrequencyPersistedSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (state.ownerUid != ownerUid) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.ownerMismatch,
          message: 'Owner mismatch',
        );
      }
      return FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.loaded,
        state: state,
      );
    } catch (_) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    _store.remove(FrequencySessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = FrequencySessionStorageKeys.activePointer(ownerUid);
    if (_store[activeKey] == sessionId) _store.remove(activeKey);
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefix = '${FrequencySessionStorageKeys.prefix}.session.$ownerUid.';
    _store.removeWhere(
      (k, _) =>
          k.startsWith(prefix) ||
          k == FrequencySessionStorageKeys.activePointer(ownerUid),
    );
  }
}

class FrequencyPersistedSessionValidator {
  FrequencyPersistedSessionValidator._();

  static FrequencySessionLoadResult validate({
    required FrequencyPersistedSessionState state,
    required FrequencyCanonicalBankDocument bank,
    required String ownerUid,
  }) {
    if (ownerUid.trim().isEmpty) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    if (state.ownerUid != ownerUid) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.ownerMismatch,
        message: 'Owner mismatch',
      );
    }
    if (state.schemaVersion !=
        FrequencySessionContract.persistedSchemaVersion) {
      return FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.incompatibleSchema,
        message: 'Unsupported schema ${state.schemaVersion}',
      );
    }
    if (state.bankVersion != bank.bankVersion ||
        state.bankLocale != bank.locale) {
      return FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.incompatibleBank,
        message: 'Bank mismatch',
      );
    }
    if (state.selectionPolicyVersion !=
            FrequencySessionContract.selectionPolicyVersion ||
        state.scoringPolicyVersion !=
            FrequencySessionContract.scoringPolicyVersion) {
      return FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.incompatiblePolicy,
        message: 'Policy mismatch',
      );
    }
    if (state.itemPlans.length != FrequencySessionContract.sessionItemCount) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.corrupt,
        message: 'Item plan count invalid',
      );
    }
    final bankById = bank.itemsById;
    final seen = <String>{};
    for (final p in state.itemPlans) {
      if (!seen.add(p.itemId)) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Duplicate plan item',
        );
      }
      final item = bankById[p.itemId];
      if (item == null) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Unknown plan item',
        );
      }
      if (p.primaryDimension != item.primaryDimension) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Plan dimension mismatch',
        );
      }
      final optIds = item.options.map((o) => o.optionId).toSet();
      if (p.displayedOptionIds.length != optIds.length ||
          !p.displayedOptionIds.every(optIds.contains)) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Displayed options mismatch',
        );
      }
    }
    final planById = {for (final p in state.itemPlans) p.itemId: p};
    for (final a in state.answers) {
      final plan = planById[a.itemId];
      if (plan == null) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Answer for unknown plan item',
        );
      }
      if (!plan.displayedOptionIds.contains(a.selectedOptionId)) {
        return const FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.corrupt,
          message: 'Selected option not in displayed order',
        );
      }
    }
    if (state.currentQuestionIndex < 0 ||
        state.currentQuestionIndex >= state.itemPlans.length) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.corrupt,
        message: 'Invalid current index',
      );
    }
    return FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.loaded, state: state);
  }
}
