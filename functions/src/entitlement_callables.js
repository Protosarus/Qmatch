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
  failClosed,
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
 * Normalize restore transaction inputs (iOS).
 * @param {Record<string, unknown>} data
 * @returns {{ signedTransaction?: string, transactionId?: string }[]}
 */
function normalizeAppleRestoreItems(data) {
  const items = [];
  if (Array.isArray(data.transactions)) {
    for (const row of data.transactions) {
      if (!row || typeof row !== 'object') continue;
      const signedTransaction =
        row.signedTransaction || row.signed_transaction || undefined;
      const transactionId =
        row.transactionId || row.transaction_id || undefined;
      if (signedTransaction || transactionId) {
        items.push({
          signedTransaction: signedTransaction
            ? String(signedTransaction)
            : undefined,
          transactionId: transactionId ? String(transactionId) : undefined,
        });
      }
    }
  }
  if (Array.isArray(data.signedTransactions)) {
    for (const signed of data.signedTransactions) {
      if (signed) items.push({ signedTransaction: String(signed) });
    }
  }
  if (data.signedTransaction || data.transactionId) {
    items.push({
      signedTransaction: data.signedTransaction
        ? String(data.signedTransaction)
        : undefined,
      transactionId: data.transactionId
        ? String(data.transactionId)
        : undefined,
    });
  }
  return items;
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
 * @param {string} uid
 * @param {string} operation
 * @param {Record<string, unknown>} result
 * @param {{ applied: boolean, applyResult?: object }} apply
 * @returns {Record<string, unknown>}
 */
function formatCallableApplyResponse(uid, operation, result, apply) {
  const { applied, applyResult } = apply;
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
    operation,
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

  const apply = await maybeApplyVerifiedEntitlement(uid, result, {
    ...deps,
    playFinalizeHelpers: deps.playFinalizeHelpers || playHelpers || null,
  });

  return formatCallableApplyResponse(
    uid,
    'verifyAndApplyPurchase',
    result,
    apply,
  );
}

/**
 * Apple restore (iOS only). Android remains fail-closed.
 *
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {object} [deps]
 */
async function handleRestorePurchases(request, deps = {}) {
  const uid = requireAuthUid(request);
  const data = (request && request.data) || {};

  if (clientClaimsCanGrant(data)) {
    return {
      ...verificationNotConfiguredResult(uid, 'restorePurchases'),
      repository_applied: false,
    };
  }

  const platform = data.platform;
  if (platform === 'android') {
    return {
      ...failClosedNotConfigured('android'),
      operation: 'restorePurchases',
      uid,
      code: VERIFICATION_NOT_CONFIGURED,
      repository_applied: false,
      granted: false,
    };
  }
  if (platform !== 'ios') {
    return {
      ...verificationNotConfiguredResult(uid, 'restorePurchases'),
      repository_applied: false,
    };
  }

  const items = normalizeAppleRestoreItems(data);
  if (!items.length) {
    return {
      ...failClosed('invalid_argument', { platform: 'ios' }),
      operation: 'restorePurchases',
      uid,
      repository_applied: false,
      granted: false,
    };
  }

  const results = [];
  let anyApplied = false;
  let anyGrant = false;
  let anyBalanceChanged = false;
  let anyEntitlementChanged = false;
  let latestResonanceAccess = false;

  for (const item of items) {
    const result = await verifyApplePurchase(
      {
        callerUid: uid,
        signedTransaction: item.signedTransaction,
        transactionId: item.transactionId,
      },
      deps.apple || {},
    );

    if (isTrustedVerified(result)) {
      result.verification_source = 'restore';
    }

    const apply = await maybeApplyVerifiedEntitlement(uid, result, deps);
    const formatted = formatCallableApplyResponse(
      uid,
      'restorePurchases',
      result,
      apply,
    );
    results.push(formatted);

    if (formatted.repository_applied) anyApplied = true;
    if (formatted.granted) anyGrant = true;
    if (formatted.balances_changed) anyBalanceChanged = true;
    if (formatted.entitlement_changed) anyEntitlementChanged = true;
    if (formatted.resonance_access) latestResonanceAccess = true;
  }

  const allTrusted = results.every((r) => r.trusted && r.verified);
  const restoredCount = results.filter((r) => r.trusted && r.verified).length;

  return {
    ok: restoredCount > 0,
    trusted: allTrusted,
    verified: restoredCount > 0,
    can_grant: results.some((r) => r.can_grant),
    operation: 'restorePurchases',
    uid,
    platform: 'ios',
    code: allTrusted
      ? 'restore_processed'
      : restoredCount > 0
        ? 'restore_partial'
        : results.length === 1
          ? results[0].code
          : 'restore_failed',
    results,
    repository_applied: anyApplied,
    granted: anyGrant,
    entitlement_changed: anyEntitlementChanged,
    balances_changed: anyBalanceChanged,
    resonance_access: latestResonanceAccess,
    restored_count: restoredCount,
  };
}

module.exports = {
  requireAuthUid,
  verificationNotConfiguredResult,
  normalizeAppleRestoreItems,
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
  maybeApplyVerifiedEntitlement,
  isTrustedVerified,
  clientClaimsCanGrant,
};
