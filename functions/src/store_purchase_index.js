/**
 * Admin-only store purchase → uid index for ASSN/RTDN uid resolution.
 * Path: store_purchase_index/{indexId}
 */

'use strict';

const { getFirestore } = require('firebase-admin/firestore');
const {
  androidStoreTransactionIdFromToken,
} = require('./entitlement_ledger');

function appleOriginalIndexId(originalTransactionId) {
  return `ios:original:${originalTransactionId}`;
}

function androidTokenIndexId(purchaseToken) {
  const storeTxn = androidStoreTransactionIdFromToken(purchaseToken);
  return `android:${storeTxn}`;
}

function indexRef(db, indexId) {
  return db.doc(`store_purchase_index/${indexId}`);
}

/**
 * @param {string} indexId
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 * @returns {Promise<{ uid: string, platform: string }|null>}
 */
async function lookupPurchaseIndex(indexId, opts = {}) {
  if (!indexId) return null;
  const db = opts.db || getFirestore();
  const snap = await indexRef(db, indexId).get();
  if (!snap.exists) return null;
  const data = snap.data() || {};
  if (!data.uid) return null;
  return {
    uid: String(data.uid),
    platform: data.platform || null,
    canonical_product_key: data.canonical_product_key || null,
  };
}

/**
 * Upsert index entry (Admin only).
 * @param {object} args
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 */
async function upsertPurchaseIndex(args, opts = {}) {
  const {
    indexId,
    uid,
    platform,
    canonicalProductKey = null,
    storeTransactionId = null,
    originalTransactionId = null,
  } = args;
  if (!indexId || !uid || !platform) {
    throw new Error('purchase_index_args_incomplete');
  }
  const db = opts.db || getFirestore();
  await indexRef(db, indexId).set(
    {
      uid,
      platform,
      canonical_product_key: canonicalProductKey,
      store_transaction_id: storeTransactionId,
      original_transaction_id: originalTransactionId,
      updated_at: new Date().toISOString(),
      schema_version: 'store_purchase_index_v1',
    },
    { merge: true },
  );
}

/**
 * Index helpers derived from a trusted verification result.
 * @param {string} uid
 * @param {Record<string, unknown>} result
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 */
async function upsertIndexFromVerificationResult(uid, result, opts = {}) {
  if (!uid || !result) return;
  const platform = result.platform;
  if (platform === 'ios' && result.original_transaction_id) {
    await upsertPurchaseIndex(
      {
        indexId: appleOriginalIndexId(String(result.original_transaction_id)),
        uid,
        platform: 'ios',
        canonicalProductKey:
          result.mapping && result.mapping.canonical_product_key,
        storeTransactionId: result.store_transaction_id || null,
        originalTransactionId: result.original_transaction_id,
      },
      opts,
    );
  }
  if (platform === 'android' && result.purchase_token) {
    await upsertPurchaseIndex(
      {
        indexId: androidTokenIndexId(String(result.purchase_token)),
        uid,
        platform: 'android',
        canonicalProductKey:
          result.mapping && result.mapping.canonical_product_key,
        storeTransactionId: result.store_transaction_id || null,
        originalTransactionId: result.original_transaction_id || null,
      },
      opts,
    );
  }
}

module.exports = {
  appleOriginalIndexId,
  androidTokenIndexId,
  lookupPurchaseIndex,
  upsertPurchaseIndex,
  upsertIndexFromVerificationResult,
};
