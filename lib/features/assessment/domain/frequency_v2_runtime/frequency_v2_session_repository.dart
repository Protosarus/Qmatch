import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'frequency_v2_persisted_session_state.dart';
import 'frequency_v2_runtime_contract.dart';

class FrequencyV2SessionIdFactory {
  FrequencyV2SessionIdFactory({Random? random})
      : _random = random ?? Random.secure();

  final Random _random;

  String next() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'frequency_v2_sess_$hex';
  }
}

class FrequencyV2SessionStorageKeys {
  FrequencyV2SessionStorageKeys._();

  static const prefix = FrequencyV2RuntimeContract.storagePrefix;

  static String activePointer(String uid) => '$prefix.active.$uid';

  static String session(String uid, String sessionId) =>
      '$prefix.session.$uid.$sessionId';

  static String sessionPrefix(String ownerUid) => '$prefix.session.$ownerUid.';
}

enum FrequencyV2SessionLoadCode {
  loaded,
  notFound,
  corrupt,
  ownerMismatch,
  ownerUnavailable,
  incompatibleSchema,
}

class FrequencyV2SessionLoadResult {
  const FrequencyV2SessionLoadResult({
    required this.code,
    this.state,
    this.message = '',
  });

  final FrequencyV2SessionLoadCode code;
  final FrequencyV2PersistedSessionState? state;
  final String message;

  bool get isLoaded =>
      code == FrequencyV2SessionLoadCode.loaded && state != null;
}

class FrequencyV2SessionWriteResult {
  const FrequencyV2SessionWriteResult({
    required this.ok,
    this.state,
    this.code = '',
    this.message = '',
  });

  final bool ok;
  final FrequencyV2PersistedSessionState? state;
  final String code;
  final String message;
}

abstract class FrequencyV2SessionPersistenceRepository {
  Future<void> saveSession(FrequencyV2PersistedSessionState state);
  Future<FrequencyV2SessionLoadResult> loadActiveSession(String ownerUid);
  Future<FrequencyV2SessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  );
  Future<void> deleteSession(String ownerUid, String sessionId);
}

class FrequencyV2SessionMemoryRepository
    implements FrequencyV2SessionPersistenceRepository {
  final Map<String, String> _store = {};

  @override
  Future<void> saveSession(FrequencyV2PersistedSessionState state) async {
    final key =
        FrequencyV2SessionStorageKeys.session(state.ownerUid, state.sessionId);
    _store[key] = jsonEncode(state.toJson());
    final activeKey =
        FrequencyV2SessionStorageKeys.activePointer(state.ownerUid);
    if (state.status.keepsActivePointer) {
      _store[activeKey] = state.sessionId;
    } else if (_store[activeKey] == state.sessionId) {
      _store.remove(activeKey);
    }
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadActiveSession(
    String ownerUid,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final sid = _store[FrequencyV2SessionStorageKeys.activePointer(ownerUid)];
    if (sid == null || sid.isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.notFound,
      );
    }
    return loadSession(ownerUid, sid);
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final raw =
        _store[FrequencyV2SessionStorageKeys.session(ownerUid, sessionId)];
    if (raw == null) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.notFound,
      );
    }
    return _decode(raw, ownerUid);
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    _store.remove(FrequencyV2SessionStorageKeys.session(ownerUid, sessionId));
    final active = FrequencyV2SessionStorageKeys.activePointer(ownerUid);
    if (_store[active] == sessionId) _store.remove(active);
  }

  FrequencyV2SessionLoadResult _decode(String raw, String ownerUid) {
    try {
      final state = FrequencyV2PersistedSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (state.ownerUid != ownerUid) {
        return const FrequencyV2SessionLoadResult(
          code: FrequencyV2SessionLoadCode.ownerMismatch,
          message: 'Owner mismatch',
        );
      }
      if (state.schemaVersion !=
          FrequencyV2RuntimeContract.persistedSchemaVersion) {
        return FrequencyV2SessionLoadResult(
          code: FrequencyV2SessionLoadCode.incompatibleSchema,
          message: 'Unsupported schema ${state.schemaVersion}',
        );
      }
      return FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.loaded,
        state: state,
      );
    } catch (_) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.corrupt,
        message: 'Malformed persisted V2 session',
      );
    }
  }
}

class FrequencyV2SessionPrefsRepository
    implements FrequencyV2SessionPersistenceRepository {
  FrequencyV2SessionPrefsRepository({SharedPreferences? prefs})
      : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(FrequencyV2PersistedSessionState state) async {
    final prefs = await _ensure();
    await prefs.setString(
      FrequencyV2SessionStorageKeys.session(state.ownerUid, state.sessionId),
      jsonEncode(state.toJson()),
    );
    final activeKey =
        FrequencyV2SessionStorageKeys.activePointer(state.ownerUid);
    if (state.status.keepsActivePointer) {
      await prefs.setString(activeKey, state.sessionId);
    } else {
      final active = prefs.getString(activeKey);
      if (active == state.sessionId) await prefs.remove(activeKey);
    }
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadActiveSession(
    String ownerUid,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final prefs = await _ensure();
    final sid =
        prefs.getString(FrequencyV2SessionStorageKeys.activePointer(ownerUid));
    if (sid == null || sid.isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.notFound,
      );
    }
    return loadSession(ownerUid, sid);
  }

  @override
  Future<FrequencyV2SessionLoadResult> loadSession(
    String ownerUid,
    String sessionId,
  ) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final prefs = await _ensure();
    final raw = prefs.getString(
      FrequencyV2SessionStorageKeys.session(ownerUid, sessionId),
    );
    if (raw == null) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.notFound,
      );
    }
    try {
      final state = FrequencyV2PersistedSessionState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (state.ownerUid != ownerUid) {
        return const FrequencyV2SessionLoadResult(
          code: FrequencyV2SessionLoadCode.ownerMismatch,
          message: 'Owner mismatch',
        );
      }
      if (state.schemaVersion !=
          FrequencyV2RuntimeContract.persistedSchemaVersion) {
        return FrequencyV2SessionLoadResult(
          code: FrequencyV2SessionLoadCode.incompatibleSchema,
          message: 'Unsupported schema ${state.schemaVersion}',
        );
      }
      return FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.loaded,
        state: state,
      );
    } catch (_) {
      return const FrequencyV2SessionLoadResult(
        code: FrequencyV2SessionLoadCode.corrupt,
        message: 'Malformed persisted V2 session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    final prefs = await _ensure();
    await prefs.remove(
      FrequencyV2SessionStorageKeys.session(ownerUid, sessionId),
    );
    final activeKey = FrequencyV2SessionStorageKeys.activePointer(ownerUid);
    if (prefs.getString(activeKey) == sessionId) {
      await prefs.remove(activeKey);
    }
  }
}
