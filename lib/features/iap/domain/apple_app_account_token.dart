import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Deterministic Apple `appAccountToken` (UUID v5) from Firebase uid.
///
/// Must match Functions `appleAppAccountTokenFromUid` exactly
/// (`functions/src/apple_app_account_token.js`).
abstract final class AppleAppAccountToken {
  /// Frozen namespace for QMatch Apple appAccountToken v1 (RFC 4122 UUID).
  /// Do not change — breaks StoreKit ↔ backend binding parity.
  static const namespaceV1 = 'b3e1f9a0-7c4d-4e2b-9f1a-8d6c5b4a3e2f';

  /// Expected StoreKit `applicationUserName` / Apple `appAccountToken`.
  ///
  /// Derived only from the authenticated Firebase uid. Never trust a
  /// client-supplied token as the expected value.
  static String fromUid(String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('uid required for Apple appAccountToken');
    }
    return uuidV5(trimmed, namespaceV1);
  }

  /// RFC 4122 UUID version 5 (SHA-1 name-based), lowercase.
  static String uuidV5(String name, String namespaceUuid) {
    final ns = _uuidToBytes(namespaceUuid);
    final hash = sha1.convert([...ns, ...utf8.encode(name)]).bytes;
    hash[6] = (hash[6] & 0x0f) | 0x50; // version 5
    hash[8] = (hash[8] & 0x3f) | 0x80; // RFC 4122 variant
    return _bytesToUuid(hash);
  }

  static List<int> _uuidToBytes(String uuid) {
    final hex = uuid.replaceAll('-', '').toLowerCase();
    if (hex.length != 32 || !RegExp(r'^[0-9a-f]+$').hasMatch(hex)) {
      throw ArgumentError('Invalid UUID namespace');
    }
    final out = List<int>.filled(16, 0);
    for (var i = 0; i < 16; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static String _bytesToUuid(List<int> bytes) {
    final h = bytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}
