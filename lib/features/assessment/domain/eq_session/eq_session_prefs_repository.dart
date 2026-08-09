import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'eq_persisted_session_state.dart';
import 'eq_session_contract.dart';
import 'eq_session_persistence_repository.dart';

/// SharedPreferences-backed durable EQ session store (UID-namespaced).
class EqSessionPrefsRepository implements EqSessionPersistenceRepository {
  EqSessionPrefsRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(EqPersistedSessionState state) async {
    final prefs = await _ensure();
    final json = jsonEncode(state.toJson());
    await prefs.setString(
      EqSessionStorageKeys.session(state.ownerUid, state.sessionId),
      json,
    );
    final activeKey = EqSessionStorageKeys.activePointer(state.ownerUid);
    if (state.status == EqPersistedSessionStatus.inProgress) {
      await prefs.setString(activeKey, state.sessionId);
    } else {
      final active = prefs.getString(activeKey);
      if (active == state.sessionId) {
        await prefs.remove(activeKey);
      }
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
    final prefs = await _ensure();
    final sid = prefs.getString(EqSessionStorageKeys.activePointer(ownerUid));
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
    final prefs = await _ensure();
    final raw =
        prefs.getString(EqSessionStorageKeys.session(ownerUid, sessionId));
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
      if (state.schemaVersion != EqSessionContract.persistedSchemaVersion) {
        return EqSessionLoadResult(
          code: EqSessionLoadCode.incompatibleSchema,
          message: 'Unsupported schema ${state.schemaVersion}',
        );
      }
      return EqSessionLoadResult(code: EqSessionLoadCode.loaded, state: state);
    } catch (_) {
      return const EqSessionLoadResult(
        code: EqSessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    final prefs = await _ensure();
    await prefs.remove(EqSessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = EqSessionStorageKeys.activePointer(ownerUid);
    if (prefs.getString(activeKey) == sessionId) {
      await prefs.remove(activeKey);
    }
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefs = await _ensure();
    final prefixSession = '${EqSessionStorageKeys.prefix}.session.$ownerUid.';
    final keys = prefs.getKeys().where(
          (k) =>
              k.startsWith(prefixSession) ||
              k == EqSessionStorageKeys.activePointer(ownerUid),
        );
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
