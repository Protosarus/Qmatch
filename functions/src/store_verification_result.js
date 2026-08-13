/**
 * Normalized store verification result helpers.
 * Repository writes are allowed only when isTrustedVerified(result).
 */

'use strict';

const { VERIFICATION_NOT_CONFIGURED } = require('./entitlement_schema');

/**
 * Fail-closed result when credentials / API verifier unavailable.
 * @param {string} platform
 * @param {string} [message]
 * @returns {Record<string, unknown>}
 */
function failClosedNotConfigured(platform, message) {
  return {
    ok: false,
    trusted: false,
    verified: false,
    can_grant: false,
    code: VERIFICATION_NOT_CONFIGURED,
    platform,
    granted: false,
    resonance_access: false,
    entitlement_changed: false,
    balances_changed: false,
    message:
      message ||
      'Store verification is not configured. Client purchase claims are not trusted.',
  };
}

/**
 * Generic fail-closed rejection (no grant).
 * @param {string} code
 * @param {object} [extra]
 * @returns {Record<string, unknown>}
 */
function failClosed(code, extra = {}) {
  return {
    ok: false,
    trusted: false,
    verified: false,
    can_grant: false,
    code,
    granted: false,
    resonance_access: false,
    entitlement_changed: false,
    balances_changed: false,
    ...extra,
  };
}

/**
 * Trusted verified success envelope. Still does not write Firestore by itself.
 * @param {object} payload
 * @returns {Record<string, unknown>}
 */
function trustedVerifiedResult(payload) {
  return {
    ok: true,
    trusted: true,
    verified: true,
    can_grant: true,
    code: 'verified',
    granted: false, // grant happens only after repository apply
    entitlement_changed: false,
    balances_changed: false,
    ...payload,
  };
}

/**
 * Gate for entitlement repository apply.
 * @param {Record<string, unknown>|null|undefined} result
 * @returns {boolean}
 */
function isTrustedVerified(result) {
  return !!(
    result &&
    result.ok === true &&
    result.trusted === true &&
    result.verified === true &&
    result.can_grant === true
  );
}

/**
 * Client claims / unverified payloads must never grant.
 * @param {Record<string, unknown>|null|undefined} clientClaims
 * @returns {boolean} always false — documents policy for tests
 */
function clientClaimsCanGrant(_clientClaims) {
  return false;
}

module.exports = {
  failClosedNotConfigured,
  failClosed,
  trustedVerifiedResult,
  isTrustedVerified,
  clientClaimsCanGrant,
};
