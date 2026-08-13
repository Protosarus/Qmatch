/**
 * Entitlement callable scaffolds.
 *
 * Until App Store / Play verification is configured, these NEVER grant
 * entitlement or consumable credits from client-supplied claims.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { VERIFICATION_NOT_CONFIGURED } = require('./entitlement_schema');

/**
 * Shared unauthenticated / not-configured response builder.
 * @param {string} uid
 * @param {string} operation
 * @returns {Record<string, unknown>}
 */
function verificationNotConfiguredResult(uid, operation) {
  return {
    ok: false,
    code: VERIFICATION_NOT_CONFIGURED,
    operation,
    uid,
    granted: false,
    resonance_access: false,
    entitlement_changed: false,
    balances_changed: false,
    message:
      'Store verification is not configured. Client purchase claims are not trusted.',
  };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @returns {string}
 */
function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required for entitlement operations.',
    );
  }
  return uid;
}

/**
 * verifyAndApplyPurchase — scaffold.
 * Does not trust client purchase payloads. Does not write entitlements.
 *
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 */
async function handleVerifyAndApplyPurchase(request) {
  const uid = requireAuthUid(request);
  // Intentionally ignore request.data purchase claims — no fake verification.
  return verificationNotConfiguredResult(uid, 'verifyAndApplyPurchase');
}

/**
 * restorePurchases — scaffold.
 * Does not trust client restore payloads. Does not write entitlements.
 *
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 */
async function handleRestorePurchases(request) {
  const uid = requireAuthUid(request);
  return verificationNotConfiguredResult(uid, 'restorePurchases');
}

module.exports = {
  requireAuthUid,
  verificationNotConfiguredResult,
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
};
