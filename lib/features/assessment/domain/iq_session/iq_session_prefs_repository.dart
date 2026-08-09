import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'iq_persisted_session_state.dart';
import 'iq_session_persistence_repository.dart';

/// SharedPreferences-backed durable IQ session store (UID-namespaced).
///
/// Offline / local-only. No Firestore schema.
class IqSessionPrefsRepository implements IqSessionPersistenceRepository {
  IqSessionPrefsRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(IqPersistedSessionState state) async {
    final prefs = await _ensure();
    final json = jsonEncode(state.toJson());
    await prefs.setString(
      IqSessionStorageKeys.session(state.ownerUid, state.sessionId),
      json,
    );
    final activeKey = IqSessionStorageKeys.activePointer(state.ownerUid);
    if (state.status.keepsActivePointer) {
      await prefs.setString(activeKey, state.sessionId);
    } else {
      final active = prefs.getString(activeKey);
      if (active == state.sessionId) {
        await prefs.remove(activeKey);
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
    final prefs = await _ensure();
    final sid = prefs.getString(IqSessionStorageKeys.activePointer(ownerUid));
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
    final prefs = await _ensure();
    final raw =
        prefs.getString(IqSessionStorageKeys.session(ownerUid, sessionId));
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
    } catch (_) {
      return const IqSessionLoadResult(
        code: IqSessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    final prefs = await _ensure();
    await prefs.remove(IqSessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = IqSessionStorageKeys.activePointer(ownerUid);
    if (prefs.getString(activeKey) == sessionId) {
      await prefs.remove(activeKey);
    }
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefs = await _ensure();
    final prefixSession = IqSessionStorageKeys.sessionPrefix(ownerUid);
    final keys = prefs.getKeys().where(
          (k) =>
              k.startsWith(prefixSession) ||
              k == IqSessionStorageKeys.activePointer(ownerUid),
        );
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  @override
  Future<List<IqPersistedSessionState>> listOwnerSessions(
    String ownerUid,
  ) async {
    if (ownerUid.trim().isEmpty) return const [];
    final prefs = await _ensure();
    final prefix = IqSessionStorageKeys.sessionPrefix(ownerUid);
    final out = <IqPersistedSessionState>[];
    for (final k in prefs.getKeys()) {
      if (!k.startsWith(prefix)) continue;
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        final state = IqPersistedSessionState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (state.ownerUid == ownerUid) out.add(state);
      } catch (_) {
        // Skip corrupt blobs during listing.
      }
    }
    return out;
  }
}
