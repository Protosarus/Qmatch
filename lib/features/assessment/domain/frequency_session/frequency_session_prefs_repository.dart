import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'frequency_persisted_session_state.dart';
import 'frequency_session_contract.dart';
import 'frequency_session_persistence_repository.dart';

/// SharedPreferences-backed durable Frequency session store (UID-namespaced).
class FrequencySessionPrefsRepository
    implements FrequencySessionPersistenceRepository {
  FrequencySessionPrefsRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveSession(FrequencyPersistedSessionState state) async {
    final prefs = await _ensure();
    final json = jsonEncode(state.toJson());
    await prefs.setString(
      FrequencySessionStorageKeys.session(state.ownerUid, state.sessionId),
      json,
    );
    final activeKey = FrequencySessionStorageKeys.activePointer(state.ownerUid);
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
  Future<FrequencySessionLoadResult> loadActiveSession(String ownerUid) async {
    if (ownerUid.trim().isEmpty) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final prefs = await _ensure();
    final sid =
        prefs.getString(FrequencySessionStorageKeys.activePointer(ownerUid));
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
    final prefs = await _ensure();
    final raw = prefs
        .getString(FrequencySessionStorageKeys.session(ownerUid, sessionId));
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
      if (state.schemaVersion !=
          FrequencySessionContract.persistedSchemaVersion) {
        return FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.incompatibleSchema,
          message: 'Unsupported schema ${state.schemaVersion}',
        );
      }
      return FrequencySessionLoadResult(
          code: FrequencySessionLoadCode.loaded, state: state);
    } catch (_) {
      return const FrequencySessionLoadResult(
        code: FrequencySessionLoadCode.corrupt,
        message: 'Malformed persisted session',
      );
    }
  }

  @override
  Future<void> deleteSession(String ownerUid, String sessionId) async {
    final prefs = await _ensure();
    await prefs
        .remove(FrequencySessionStorageKeys.session(ownerUid, sessionId));
    final activeKey = FrequencySessionStorageKeys.activePointer(ownerUid);
    if (prefs.getString(activeKey) == sessionId) {
      await prefs.remove(activeKey);
    }
  }

  @override
  Future<void> clearOwnerSessions(String ownerUid) async {
    final prefs = await _ensure();
    final prefixSession = FrequencySessionStorageKeys.sessionPrefix(ownerUid);
    final keys = prefs.getKeys().where(
          (k) =>
              k.startsWith(prefixSession) ||
              k == FrequencySessionStorageKeys.activePointer(ownerUid),
        );
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  @override
  Future<List<FrequencyPersistedSessionState>> listOwnerSessions(
    String ownerUid,
  ) async {
    if (ownerUid.trim().isEmpty) return const [];
    final prefs = await _ensure();
    final prefix = FrequencySessionStorageKeys.sessionPrefix(ownerUid);
    final out = <FrequencyPersistedSessionState>[];
    for (final k in prefs.getKeys()) {
      if (!k.startsWith(prefix)) continue;
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        final state = FrequencyPersistedSessionState.fromJson(
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
