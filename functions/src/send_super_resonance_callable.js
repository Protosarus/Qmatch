/**
 * Trusted Super Resonance send (`sendSuperResonance`).
 *
 * One Admin transaction: optional debit + spend ledger + immutable pair signal.
 * Never writes swipes, matches, or ranking fields. Never leaks block reasons.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  normalizeSnapshot,
  defaultFreeSnapshot,
  debitBalance,
} = require('./entitlement_access');
const {
  BALANCE_FIELDS,
  CANONICAL_PRODUCT_KEYS,
  EFFECTS,
  EVENT_TYPES,
  SUPER_RESONANCE_DAILY,
} = require('./entitlement_schema');
const { spendLedgerId, buildLedgerDocument } = require('./entitlement_ledger');
const {
  resolveDailyAllowance,
  spendDailyAllowance,
  withDailyBucket,
} = require('./super_resonance_daily_allowance');
const {
  isValidLiveUser,
  deterministicMatchId,
} = require('./like_match_atomicity');
const {
  SCHEMA_VERSION,
  SPEND_PLATFORM,
  signalId,
  signalPath,
  isSafeRequestId,
  publicSendResult,
  buildSignalDocument,
} = require('./super_resonance_signal');

const CALLABLE_NAME = 'sendSuperResonance';
const PUBLIC_RESULT_KEYS = Object.freeze([
  'ok',
  'already_sent',
  'super_resonance_balance',
  'purchased_balance',
  'daily_remaining',
  'total_available',
  'signal_id',
]);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to send Super Resonance.',
    );
  }
  return uid;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function timestamp(deps) {
  if (deps && typeof deps.serverTimestamp === 'function') {
    return deps.serverTimestamp();
  }
  return require('firebase-admin/firestore').FieldValue.serverTimestamp();
}

function processedAt(deps) {
  if (deps && typeof deps.now === 'function') return deps.now();
  return new Date();
}

function refuseUnavailable() {
  throw new HttpsError(
    'failed-precondition',
    'Super Resonance is unavailable.',
  );
}

function refuseInsufficient() {
  throw new HttpsError(
    'failed-precondition',
    'Super Resonance is unavailable.',
    { code: 'insufficient_balance' },
  );
}

function targetIsSendable(exists, data) {
  if (!isValidLiveUser(exists, data)) return false;
  if (data && data.account_deletion_requested === true) return false;
  return true;
}

function senderPassedTarget(swipeSnap) {
  if (!swipeSnap || !swipeSnap.exists) return false;
  const data = swipeSnap.data() || {};
  return data.direction === 'pass';
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function, now?: Function }} [deps]
 */
async function handleSendSuperResonance(request, deps = {}) {
  const fromUid = requireAuthUid(request);
  const data = request.data && typeof request.data === 'object' ? request.data : {};
  const targetUid = data.target_uid;
  const requestIdRaw = data.request_id;

  if (typeof targetUid !== 'string' || targetUid.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'target_uid must be a non-empty string.',
    );
  }
  if (targetUid === fromUid) {
    throw new HttpsError(
      'invalid-argument',
      'Cannot send Super Resonance to yourself.',
    );
  }
  if (!isSafeRequestId(requestIdRaw)) {
    throw new HttpsError(
      'invalid-argument',
      'request_id must be a non-empty id.',
    );
  }
  const requestId = requestIdRaw.trim();
  const id = signalId(fromUid, targetUid);
  const ledgerId = spendLedgerId(SPEND_PLATFORM, fromUid, requestId);
  const matchId = deterministicMatchId(fromUid, targetUid);
  const db = resolveDb(deps);
  const createdAt = timestamp(deps);
  const at = processedAt(deps);

  const entitlementRef = db.doc(`entitlements/${fromUid}`);
  const ledgerRef = db.doc(
    `entitlements/${fromUid}/purchase_ledger/${ledgerId}`,
  );
  const signalRef = db.doc(signalPath(fromUid, targetUid));
  const viewerBlockRef = db.doc(`users/${fromUid}/blocks/${targetUid}`);
  const reverseBlockRef = db.doc(`users/${targetUid}/blocks/${fromUid}`);
  const senderUserRef = db.doc(`users/${fromUid}`);
  const targetUserRef = db.doc(`users/${targetUid}`);
  const matchRef = db.doc(`matches/${matchId}`);
  const senderSwipeRef = db.doc(`users/${fromUid}/swipes/${targetUid}`);

  return db.runTransaction(async (tx) => {
    const [
      entitlementSnap,
      ledgerSnap,
      signalSnap,
      viewerBlockSnap,
      reverseBlockSnap,
      senderUserSnap,
      targetUserSnap,
      matchSnap,
      senderSwipeSnap,
    ] = await Promise.all([
      tx.get(entitlementRef),
      tx.get(ledgerRef),
      tx.get(signalRef),
      tx.get(viewerBlockRef),
      tx.get(reverseBlockRef),
      tx.get(senderUserRef),
      tx.get(targetUserRef),
      tx.get(matchRef),
      tx.get(senderSwipeRef),
    ]);

    const snapshot = entitlementSnap.exists
      ? normalizeSnapshot(fromUid, entitlementSnap.data())
      : defaultFreeSnapshot(fromUid);
    const daily = resolveDailyAllowance(snapshot, at);

    if (signalSnap.exists) {
      return publicSendResult({
        alreadySent: true,
        daily,
        id,
      });
    }

    if (ledgerSnap.exists) {
      const prior = ledgerSnap.data() || {};
      const priorTarget =
        typeof prior.target_uid === 'string' && prior.target_uid
          ? prior.target_uid
          : targetUid;
      return publicSendResult({
        alreadySent: true,
        daily,
        id: signalId(fromUid, priorTarget),
      });
    }

    const blocked =
      !!(viewerBlockSnap && viewerBlockSnap.exists) ||
      !!(reverseBlockSnap && reverseBlockSnap.exists);
    if (blocked) refuseUnavailable();

    const targetData =
      targetUserSnap && targetUserSnap.exists ? targetUserSnap.data() : null;
    if (!targetIsSendable(!!(targetUserSnap && targetUserSnap.exists), targetData)) {
      refuseUnavailable();
    }

    if (matchSnap && matchSnap.exists) refuseUnavailable();
    if (senderPassedTarget(senderSwipeSnap)) refuseUnavailable();

    let nextSnapshot;
    let ledgerDoc;
    if (daily.remaining > 0) {
      nextSnapshot = spendDailyAllowance(snapshot, daily);
      ledgerDoc = buildLedgerDocument({
        uid: fromUid,
        ledgerId,
        storeTransactionId: requestId,
        platform: SPEND_PLATFORM,
        canonicalProductKey: SUPER_RESONANCE_DAILY.PRODUCT_KEY,
        productId: null,
        eventType: EVENT_TYPES.DAILY_ALLOWANCE_SPEND,
        effect: EFFECTS.SPEND_SUPER_RESONANCE_DAILY,
        subscriptionStateAfter: nextSnapshot.subscription_state,
        balanceDeltaSuperResonance: 0,
        balanceDeltaBoost: 0,
        verificationSource: 'spend',
        processedAt: at,
        targetUid,
      });
    } else if (daily.purchased >= 1) {
      nextSnapshot = withDailyBucket(
        debitBalance(snapshot, BALANCE_FIELDS.SUPER_RESONANCE, 1),
        daily,
      );
      ledgerDoc = buildLedgerDocument({
        uid: fromUid,
        ledgerId,
        storeTransactionId: requestId,
        platform: SPEND_PLATFORM,
        canonicalProductKey: CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1,
        productId: null,
        eventType: EVENT_TYPES.CONSUMABLE_SPEND,
        effect: EFFECTS.DEBIT_SUPER_RESONANCE,
        subscriptionStateAfter: nextSnapshot.subscription_state,
        balanceDeltaSuperResonance: -1,
        balanceDeltaBoost: 0,
        verificationSource: 'spend',
        processedAt: at,
        targetUid,
      });
    } else {
      refuseInsufficient();
    }

    tx.set(ledgerRef, ledgerDoc);
    tx.set(entitlementRef, nextSnapshot, { merge: true });
    tx.set(
      signalRef,
      buildSignalDocument({
        fromUid,
        toUid: targetUid,
        requestId,
        ledgerId,
        createdAt,
      }),
    );

    return publicSendResult({
      alreadySent: false,
      daily: resolveDailyAllowance(nextSnapshot, at),
      id,
    });
  });
}

module.exports = {
  CALLABLE_NAME,
  PUBLIC_RESULT_KEYS,
  SCHEMA_VERSION,
  handleSendSuperResonance,
  publicSendResult,
  signalId,
};
