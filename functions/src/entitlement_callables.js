/**
 * Entitlement callable scaffolds + store verifier routing.
 *
 * Never grants from client claims. Never calls entitlement repository unless
 * isTrustedVerified(result). Without store credentials → fail closed.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const { VERIFICATION_NOT_CONFIGURED } = require('./entitlement_schema');
const { verifyApplePurchase } = require('./store_verify_apple');
const { verifyPlayPurchase } = require('./store_verify_play');
const {
  isTrustedVerified,
  clientClaimsCanGrant,
  failClosedNotConfigured,
} = require('./store_verification_result');

/**
 * Shared unauthenticated / not-configured response builder.
 * @param {string} uid
 * @param {string} operation
 * @returns {Record<string, unknown>}
 */
function verificationNotConfiguredResult(uid, operation) {
  return {
    ...failClosedNotConfigured('unknown'),
    operation,
    uid,
    code: VERIFICATION_NOT_CONFIGURED,
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
 * Apply trusted verification to repository — foundation gate only.
 * Returns false always until apply wiring is explicitly enabled with trusted result.
 * This step does not call the repository.
 *
 * @param {Record<string, unknown>} result
 * @param {object} [deps]
 * @returns {Promise<boolean>}
 */
async function maybeApplyVerifiedEntitlement(result, deps = {}) {
  if (!isTrustedVerified(result)) {
    return false;
  }
  if (typeof deps.applyTrusted !== 'function') {
    // Repository apply not wired in foundation v1 — still no grant side effects.
    return false;
  }
  await deps.applyTrusted(result);
  return true;
}

/**
 * verifyAndApplyPurchase — routes to Apple/Play verifier; fail closed without creds.
 * Does not trust client purchase claims. Does not grant without trusted verify.
 *
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {object} [deps] optional verifier opts for tests
 */
async function handleVerifyAndApplyPurchase(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = (request && request.data) || {};

  // Explicit policy: client claims never grant.
  if (clientClaimsCanGrant(data)) {
    return verificationNotConfiguredResult(uid, 'verifyAndApplyPurchase');
  }

  const platform = data.platform;
  let result;

  if (platform === 'ios') {
    result = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: data.signedTransaction,
        transactionId: data.transactionId,
      },
      deps.apple || {},
    );
  } else if (platform === 'android') {
    result = await verifyPlayPurchase(
      {
        callerUid: uid,
        purchaseToken: data.purchaseToken,
        productId: data.productId,
        packageName: data.packageName,
        kind: data.kind,
      },
      deps.play || {},
    );
  } else {
    // Missing/unknown platform: still fail closed (no client grant).
    result = verificationNotConfiguredResult(uid, 'verifyAndApplyPurchase');
  }

  const applied = await maybeApplyVerifiedEntitlement(result, deps);
  return {
    ...result,
    uid,
    operation: 'verifyAndApplyPurchase',
    repository_applied: applied,
    // Foundation: never report grant until repository apply is wired + succeeded.
    granted: false,
    entitlement_changed: false,
    balances_changed: false,
  };
}

/**
 * restorePurchases — scaffold. Same fail-closed contract; no ASSN/RTDN.
 *
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {object} [deps]
 */
async function handleRestorePurchases(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = (request && request.data) || {};
  void data;
  void deps;
  // Restore still requires store verification credentials — not configured.
  return {
    ...verificationNotConfiguredResult(uid, 'restorePurchases'),
    repository_applied: false,
  };
}

module.exports = {
  requireAuthUid,
  verificationNotConfiguredResult,
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
  maybeApplyVerifiedEntitlement,
  isTrustedVerified,
  clientClaimsCanGrant,
};
