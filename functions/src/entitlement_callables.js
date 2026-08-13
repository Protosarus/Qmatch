/**
 * Entitlement callable scaffolds + Apple/Play verification wiring.
 *
 * Apply to repository only when isTrustedVerified(result).
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
const {
  applyTrustedVerificationResult,
} = require('./apply_trusted_verification');

/**
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
 * @param {string} uid
 * @param {Record<string, unknown>} result
 * @param {object} [deps]
 * @returns {Promise<{ applied: boolean, applyResult?: object }>}
 */
async function maybeApplyVerifiedEntitlement(uid, result, deps = {}) {
  if (!isTrustedVerified(result)) {
    return { applied: false };
  }
  if (typeof deps.applyTrusted === 'function') {
    const applyResult = await deps.applyTrusted(result);
    return { applied: true, applyResult };
  }
  const applyResult = await applyTrustedVerificationResult(uid, result, {
    db: deps.db,
    playFinalizeHelpers: deps.playFinalizeHelpers,
  });
  return { applied: !!applyResult.applied, applyResult };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {object} [deps]
 */
async function handleVerifyAndApplyPurchase(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = (request && request.data) || {};

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
    result = verificationNotConfiguredResult(uid, 'verifyAndApplyPurchase');
  }

  const playHelpers = result && result._play_helpers;
  if (result && result._play_helpers) {
    delete result._play_helpers;
  }

  const { applied, applyResult } = await maybeApplyVerifiedEntitlement(
    uid,
    result,
    {
      ...deps,
      playFinalizeHelpers: deps.playFinalizeHelpers || playHelpers || null,
    },
  );

  const snapshot = applyResult && applyResult.snapshot;
  const accessGranted = !!(
    applied &&
    snapshot &&
    snapshot.resonance_access === true
  );
  const balanceChanged = !!(
    applied &&
    applyResult &&
    applyResult.status === 'applied' &&
    result.kind === 'consumable'
  );

  return {
    ...result,
    uid,
    operation: 'verifyAndApplyPurchase',
    repository_applied: applied,
    apply_status: applyResult ? applyResult.status : null,
    granted: accessGranted,
    entitlement_changed: !!(
      applied &&
      applyResult &&
      applyResult.status === 'applied' &&
      result.kind === 'subscription'
    ),
    balances_changed: balanceChanged,
    resonance_access: snapshot
      ? !!snapshot.resonance_access
      : !!result.resonance_access && accessGranted,
    acknowledged: !!(applyResult && applyResult.acknowledged),
    consumed: !!(applyResult && applyResult.consumed),
  };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {object} [deps]
 */
async function handleRestorePurchases(request, deps = {}) {
  const uid = requireAuthUid(request);
  void request;
  void deps;
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
