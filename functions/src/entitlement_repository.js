/**
 * Trusted entitlement repository (Admin SDK).
 * Sole writer for entitlements/{uid} + purchase_ledger.
 *
 * Callables must NOT invoke grant/credit paths without store verification.
 */

'use strict';

const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const {
  BALANCE_FIELDS,
  CANONICAL_PRODUCT_KEYS,
  EFFECTS,
  EVENT_TYPES,
  SCHEMA_VERSION,
} = require('./entitlement_schema');
const {
  defaultFreeSnapshot,
  normalizeSnapshot,
  applySubscriptionState,
  creditBalance,
  deriveResonanceAccess,
} = require('./entitlement_access');
const {
  purchaseLedgerId,
  buildLedgerDocument,
  planLedgerApply,
} = require('./entitlement_ledger');

function entitlementRef(db, uid) {
  return db.doc(`entitlements/${uid}`);
}

function ledgerRef(db, uid, ledgerId) {
  return db.doc(`entitlements/${uid}/purchase_ledger/${ledgerId}`);
}

/**
 * Read snapshot; create normalized free default if missing.
 * @param {string} uid
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 * @returns {Promise<{ created: boolean, snapshot: Record<string, unknown> }>}
 */
async function getOrCreateEntitlementSnapshot(uid, opts = {}) {
  if (!uid || typeof uid !== 'string') {
    throw new Error('uid_required');
  }
  const db = opts.db || getFirestore();
  const ref = entitlementRef(db, uid);
  const snap = await ref.get();
  if (snap.exists) {
    return {
      created: false,
      snapshot: normalizeSnapshot(uid, snap.data()),
    };
  }
  const created = defaultFreeSnapshot(uid);
  await ref.set(created);
  return { created: true, snapshot: created };
}

/**
 * Apply subscription state patch with derived resonance_access (Admin only).
 * Does not touch consumable balances.
 * @param {string} uid
 * @param {object} patch
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 */
async function applySubscriptionStateForUid(uid, patch, opts = {}) {
  const db = opts.db || getFirestore();
  const ref = entitlementRef(db, uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = snap.exists
      ? normalizeSnapshot(uid, snap.data())
      : defaultFreeSnapshot(uid);
    const next = applySubscriptionState(current, patch);
    tx.set(ref, next, { merge: true });
  });
  const after = await ref.get();
  return normalizeSnapshot(uid, after.data());
}

/**
 * Idempotent consumable credit + ledger row in one transaction.
 * Never grants resonance_access.
 *
 * @param {object} args
 * @param {string} args.uid
 * @param {string} args.platform
 * @param {string} args.storeTransactionId
 * @param {'super_resonance_x1'|'boost_x1'} args.canonicalProductKey
 * @param {string|null} [args.productId]
 * @param {string} [args.eventType]
 * @param {string} [args.verificationSource]
 * @param {{ db?: FirebaseFirestore.Firestore, now?: () => Date }} [opts]
 * @returns {Promise<{ status: 'applied'|'noop', ledgerId: string, snapshot: Record<string, unknown>, ledger: Record<string, unknown> }>}
 */
async function creditConsumableIdempotent(args, opts = {}) {
  const {
    uid,
    platform,
    storeTransactionId,
    canonicalProductKey,
    productId = null,
    eventType = EVENT_TYPES.CONSUMABLE_PURCHASE,
    verificationSource = 'purchase',
  } = args;

  if (!uid || !platform || !storeTransactionId || !canonicalProductKey) {
    throw new Error('credit_args_incomplete');
  }

  let balanceField;
  let effect;
  let deltaSuper = 0;
  let deltaBoost = 0;
  if (canonicalProductKey === CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1) {
    balanceField = BALANCE_FIELDS.SUPER_RESONANCE;
    effect = EFFECTS.CREDIT_SUPER_RESONANCE;
    deltaSuper = 1;
  } else if (canonicalProductKey === CANONICAL_PRODUCT_KEYS.BOOST_X1) {
    balanceField = BALANCE_FIELDS.BOOST;
    effect = EFFECTS.CREDIT_BOOST;
    deltaBoost = 1;
  } else {
    throw new Error(`not_a_consumable:${canonicalProductKey}`);
  }

  const ledgerId = purchaseLedgerId(platform, storeTransactionId);
  const db = opts.db || getFirestore();
  const now = opts.now ? opts.now() : new Date();
  const processedAt =
    typeof Timestamp !== 'undefined' && Timestamp.fromDate
      ? Timestamp.fromDate(now)
      : now;

  const eRef = entitlementRef(db, uid);
  const lRef = ledgerRef(db, uid, ledgerId);

  const result = await db.runTransaction(async (tx) => {
    const [ledgerSnap, entSnap] = await Promise.all([
      tx.get(lRef),
      tx.get(eRef),
    ]);

    const existingLedger = ledgerSnap.exists ? ledgerSnap.data() : null;
    const current = entSnap.exists
      ? normalizeSnapshot(uid, entSnap.data())
      : defaultFreeSnapshot(uid);

    if (existingLedger) {
      return planLedgerApply({
        existingLedger,
        snapshot: current,
        ledgerDoc: existingLedger,
        nextSnapshot: current,
      });
    }

    const nextSnapshot = creditBalance(current, balanceField, 1);
    const ledgerDoc = buildLedgerDocument({
      uid,
      ledgerId,
      storeTransactionId,
      platform,
      canonicalProductKey,
      productId,
      eventType,
      effect,
      subscriptionStateAfter: nextSnapshot.subscription_state,
      balanceDeltaSuperResonance: deltaSuper,
      balanceDeltaBoost: deltaBoost,
      verificationSource,
      processedAt,
    });

    const planned = planLedgerApply({
      existingLedger: null,
      snapshot: current,
      ledgerDoc,
      nextSnapshot,
    });

    tx.set(lRef, planned.ledger);
    tx.set(eRef, planned.snapshot, { merge: true });
    return planned;
  });

  return {
    status: result.status,
    ledgerId,
    snapshot: result.snapshot,
    ledger: result.ledger,
  };
}

/**
 * Idempotent subscription ledger + snapshot update (Admin / verified only).
 * Scaffold helper — callables must not call this without store verification.
 */
async function applySubscriptionLedgerEvent(args, opts = {}) {
  const {
    uid,
    ledgerId,
    storeTransactionId,
    platform,
    canonicalProductKey,
    productId = null,
    basePlanId = null,
    eventType,
    effect,
    subscriptionPatch,
    verificationSource,
  } = args;

  if (!uid || !ledgerId || !platform || !eventType || !effect) {
    throw new Error('subscription_ledger_args_incomplete');
  }

  const db = opts.db || getFirestore();
  const now = opts.now ? opts.now() : new Date();
  const processedAt =
    typeof Timestamp !== 'undefined' && Timestamp.fromDate
      ? Timestamp.fromDate(now)
      : now;

  const eRef = entitlementRef(db, uid);
  const lRef = ledgerRef(db, uid, ledgerId);

  const result = await db.runTransaction(async (tx) => {
    const [ledgerSnap, entSnap] = await Promise.all([
      tx.get(lRef),
      tx.get(eRef),
    ]);
    const existingLedger = ledgerSnap.exists ? ledgerSnap.data() : null;
    const current = entSnap.exists
      ? normalizeSnapshot(uid, entSnap.data())
      : defaultFreeSnapshot(uid);

    if (existingLedger) {
      return planLedgerApply({
        existingLedger,
        snapshot: current,
        ledgerDoc: existingLedger,
        nextSnapshot: current,
      });
    }

    const nextSnapshot = applySubscriptionState(current, {
      ...subscriptionPatch,
      last_verified_at: processedAt,
      verification_source: verificationSource,
    });

    const ledgerDoc = buildLedgerDocument({
      uid,
      ledgerId,
      storeTransactionId: storeTransactionId || ledgerId,
      platform,
      canonicalProductKey: canonicalProductKey || 'none',
      productId,
      basePlanId,
      eventType,
      effect,
      subscriptionStateAfter: nextSnapshot.subscription_state,
      verificationSource,
      processedAt,
    });

    const planned = planLedgerApply({
      existingLedger: null,
      snapshot: current,
      ledgerDoc,
      nextSnapshot,
    });

    tx.set(lRef, planned.ledger);
    tx.set(eRef, planned.snapshot, { merge: true });
    return planned;
  });

  return {
    status: result.status,
    ledgerId,
    snapshot: result.snapshot,
    ledger: result.ledger,
  };
}

module.exports = {
  SCHEMA_VERSION,
  FieldValue,
  deriveResonanceAccess,
  defaultFreeSnapshot,
  normalizeSnapshot,
  applySubscriptionState,
  getOrCreateEntitlementSnapshot,
  applySubscriptionStateForUid,
  creditConsumableIdempotent,
  applySubscriptionLedgerEvent,
  entitlementRef,
  ledgerRef,
};
