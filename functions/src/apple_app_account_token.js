/**
 * Deterministic Apple appAccountToken (UUID v5) from Firebase uid.
 *
 * Dart (`lib/features/iap/domain/apple_app_account_token.dart`) must produce
 * the identical string for the same uid. Never accept a client-supplied
 * "expected" token — always derive from authenticated uid.
 */

'use strict';

const crypto = require('crypto');

/**
 * Frozen namespace for QMatch Apple appAccountToken v1 (RFC 4122 UUID).
 * Do not change — breaks StoreKit ↔ backend binding parity.
 */
const APPLE_APP_ACCOUNT_TOKEN_NAMESPACE_V1 =
  'b3e1f9a0-7c4d-4e2b-9f1a-8d6c5b4a3e2f';

/**
 * @param {string} uuid
 * @returns {Buffer}
 */
function uuidToBytes(uuid) {
  const hex = String(uuid).replace(/-/g, '').toLowerCase();
  if (!/^[0-9a-f]{32}$/.test(hex)) {
    throw new Error('Invalid UUID namespace');
  }
  return Buffer.from(hex, 'hex');
}

/**
 * @param {Buffer} bytes length >= 16
 * @returns {string} lowercase UUID
 */
function bytesToUuid(bytes) {
  const h = Buffer.from(bytes.subarray(0, 16)).toString('hex');
  return (
    `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-` +
    `${h.slice(16, 20)}-${h.slice(20, 32)}`
  );
}

/**
 * RFC 4122 UUID version 5 (SHA-1 name-based).
 * @param {string} name UTF-8
 * @param {string} namespaceUuid
 * @returns {string} lowercase UUID
 */
function uuidV5(name, namespaceUuid) {
  const ns = uuidToBytes(namespaceUuid);
  const hash = crypto
    .createHash('sha1')
    .update(ns)
    .update(Buffer.from(String(name), 'utf8'))
    .digest();
  hash[6] = (hash[6] & 0x0f) | 0x50; // version 5
  hash[8] = (hash[8] & 0x3f) | 0x80; // RFC 4122 variant
  return bytesToUuid(hash);
}

/**
 * Expected Apple appAccountToken for an authenticated Firebase uid.
 * @param {string} uid
 * @returns {string} lowercase UUID
 */
function appleAppAccountTokenFromUid(uid) {
  if (!uid || typeof uid !== 'string') {
    throw new Error('uid required for Apple appAccountToken');
  }
  const trimmed = uid.trim();
  if (!trimmed) {
    throw new Error('uid required for Apple appAccountToken');
  }
  return uuidV5(trimmed, APPLE_APP_ACCOUNT_TOKEN_NAMESPACE_V1);
}

module.exports = {
  APPLE_APP_ACCOUNT_TOKEN_NAMESPACE_V1,
  appleAppAccountTokenFromUid,
  uuidV5,
};
