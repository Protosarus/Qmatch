'use strict';

const assert = require('assert');
const {
  deriveResonanceAccess,
  defaultFreeSnapshot,
  normalizeSnapshot,
  applySubscriptionState,
  creditBalance,
} = require('../src/entitlement_access');
const {
  purchaseLedgerId,
  spendLedgerId,
  planLedgerApply,
  buildLedgerDocument,
} = require('../src/entitlement_ledger');
const {
  getOrCreateEntitlementSnapshot,
  creditConsumableIdempotent,
  applySubscriptionLedgerEvent,
} = require('../src/entitlement_repository');
const {
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
  verificationNotConfiguredResult,
} = require('../src/entitlement_callables');
const {
  CANONICAL_PRODUCT_KEYS,
  STORE_PRODUCT_IDS,
  EFFECTS,
  EVENT_TYPES,
  VERIFICATION_NOT_CONFIGURED,
  BALANCE_FIELDS,
} = require('../src/entitlement_schema');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');

describe('resonance_entitlement_backend_scaffold_v1', () => {
  describe('resonance_access derivation', () => {
    it('grants only for resonance + active|grace|billing_retry', () => {
      assert.strictEqual(deriveResonanceAccess('resonance', 'active'), true);
      assert.strictEqual(deriveResonanceAccess('resonance', 'grace'), true);
      assert.strictEqual(
        deriveResonanceAccess('resonance', 'billing_retry'),
        true,
      );
      assert.strictEqual(deriveResonanceAccess('resonance', 'expired'), false);
      assert.strictEqual(deriveResonanceAccess('resonance', 'revoked'), false);
      assert.strictEqual(deriveResonanceAccess('resonance', 'none'), false);
      assert.strictEqual(deriveResonanceAccess('free', 'active'), false);
    });

    it('normalizeSnapshot always re-derives access; ignores client true', () => {
      const n = normalizeSnapshot('u1', {
        tier: 'free',
        subscription_state: 'none',
        resonance_access: true,
        super_resonance_balance: 2,
      });
      assert.strictEqual(n.resonance_access, false);
      assert.strictEqual(n.super_resonance_balance, 2);
    });
  });

  describe('subscription apply', () => {
    it('applies active resonance and derives access; balances untouched', () => {
      const base = defaultFreeSnapshot('u1');
      base.super_resonance_balance = 3;
      const next = applySubscriptionState(base, {
        tier: 'resonance',
        subscription_state: 'active',
        canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_MONTHLY,
        product_id: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
        platform: 'ios',
      });
      assert.strictEqual(next.resonance_access, true);
      assert.strictEqual(next.tier, 'resonance');
      assert.strictEqual(next.super_resonance_balance, 3);
    });

    it('revoke forces free + no access', () => {
      const active = applySubscriptionState(defaultFreeSnapshot('u1'), {
        tier: 'resonance',
        subscription_state: 'active',
      });
      const revoked = applySubscriptionState(active, {
        subscription_state: 'revoked',
      });
      assert.strictEqual(revoked.tier, 'free');
      assert.strictEqual(revoked.resonance_access, false);
    });
  });

  describe('idempotent ledger + atomic consumable credit', () => {
    it('credits once; duplicate ledger is noop', async () => {
      const db = new MemoryFirestore();
      const args = {
        uid: 'u1',
        platform: 'ios',
        storeTransactionId: 'txn-100',
        canonicalProductKey: CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1,
        productId: STORE_PRODUCT_IDS.SUPER_RESONANCE_X1,
      };

      const first = await creditConsumableIdempotent(args, { db });
      assert.strictEqual(first.status, 'applied');
      assert.strictEqual(first.snapshot.super_resonance_balance, 1);
      assert.strictEqual(first.snapshot.resonance_access, false);
      assert.strictEqual(first.snapshot.tier, 'free');

      const second = await creditConsumableIdempotent(args, { db });
      assert.strictEqual(second.status, 'noop');
      assert.strictEqual(second.snapshot.super_resonance_balance, 1);

      const { snapshot } = await getOrCreateEntitlementSnapshot('u1', { db });
      assert.strictEqual(snapshot.super_resonance_balance, 1);
      assert.strictEqual(snapshot.boost_balance, 0);
      assert.strictEqual(snapshot.resonance_access, false);
    });

    it('boost credit does not grant resonance', async () => {
      const db = new MemoryFirestore();
      const r = await creditConsumableIdempotent(
        {
          uid: 'u2',
          platform: 'android',
          storeTransactionId: 'GPA.1',
          canonicalProductKey: CANONICAL_PRODUCT_KEYS.BOOST_X1,
          productId: STORE_PRODUCT_IDS.BOOST_X1,
        },
        { db },
      );
      assert.strictEqual(r.status, 'applied');
      assert.strictEqual(r.snapshot.boost_balance, 1);
      assert.strictEqual(r.snapshot.resonance_access, false);
    });

    it('duplicate subscription ledger event is noop', async () => {
      const db = new MemoryFirestore();
      const ledgerId = purchaseLedgerId('ios', 'sub-txn-1');
      const args = {
        uid: 'u3',
        ledgerId,
        storeTransactionId: 'sub-txn-1',
        platform: 'ios',
        canonicalProductKey: CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
        productId: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
        eventType: EVENT_TYPES.SUBSCRIPTION_PURCHASE,
        effect: EFFECTS.GRANT_RESONANCE,
        subscriptionPatch: {
          tier: 'resonance',
          subscription_state: 'active',
          platform: 'ios',
          canonical_product_key: CANONICAL_PRODUCT_KEYS.RESONANCE_ANNUAL,
          product_id: STORE_PRODUCT_IDS.IOS_RESONANCE_ANNUAL,
        },
        verificationSource: 'app_store',
      };

      const first = await applySubscriptionLedgerEvent(args, { db });
      assert.strictEqual(first.status, 'applied');
      assert.strictEqual(first.snapshot.resonance_access, true);

      const second = await applySubscriptionLedgerEvent(args, { db });
      assert.strictEqual(second.status, 'noop');
      assert.strictEqual(second.snapshot.resonance_access, true);
    });

    it('planLedgerApply returns noop when ledger exists', () => {
      const snap = defaultFreeSnapshot('u');
      const ledger = buildLedgerDocument({
        uid: 'u',
        ledgerId: 'ios:1',
        storeTransactionId: '1',
        platform: 'ios',
        canonicalProductKey: CANONICAL_PRODUCT_KEYS.BOOST_X1,
        eventType: EVENT_TYPES.CONSUMABLE_PURCHASE,
        effect: EFFECTS.CREDIT_BOOST,
        verificationSource: 'purchase',
        processedAt: new Date(),
      });
      const planned = planLedgerApply({
        existingLedger: ledger,
        snapshot: snap,
        ledgerDoc: ledger,
        nextSnapshot: creditBalance(snap, BALANCE_FIELDS.BOOST, 1),
      });
      assert.strictEqual(planned.status, 'noop');
      assert.strictEqual(planned.snapshot.boost_balance, 0);
    });
  });

  describe('getOrCreate snapshot', () => {
    it('creates free default once', async () => {
      const db = new MemoryFirestore();
      const a = await getOrCreateEntitlementSnapshot('u9', { db });
      assert.strictEqual(a.created, true);
      assert.strictEqual(a.snapshot.tier, 'free');
      assert.strictEqual(a.snapshot.resonance_access, false);
      const b = await getOrCreateEntitlementSnapshot('u9', { db });
      assert.strictEqual(b.created, false);
    });
  });

  describe('callable scaffolds — unverified cannot grant', () => {
    it('verifyAndApplyPurchase returns verification_not_configured', async () => {
      const result = await handleVerifyAndApplyPurchase({
        auth: { uid: 'u1' },
        data: {
          // Client claim must be ignored
          product_id: STORE_PRODUCT_IDS.IOS_RESONANCE_MONTHLY,
          grant: true,
          resonance_access: true,
        },
      });
      assert.strictEqual(result.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(result.granted, false);
      assert.strictEqual(result.resonance_access, false);
      assert.strictEqual(result.entitlement_changed, false);
      assert.strictEqual(result.balances_changed, false);
    });

    it('restorePurchases returns verification_not_configured', async () => {
      const result = await handleRestorePurchases({
        auth: { uid: 'u1' },
        data: { transactions: [{ id: 'x' }] },
      });
      assert.strictEqual(result.code, VERIFICATION_NOT_CONFIGURED);
      assert.strictEqual(result.granted, false);
    });

    it('unauthenticated callable throws', async () => {
      await assert.rejects(
        () => handleVerifyAndApplyPurchase({ auth: null, data: {} }),
        (err) => err instanceof HttpsError && err.code === 'unauthenticated',
      );
    });

    it('verificationNotConfiguredResult never grants', () => {
      const r = verificationNotConfiguredResult('u', 'x');
      assert.strictEqual(r.ok, false);
      assert.strictEqual(r.granted, false);
      assert.strictEqual(r.resonance_access, false);
    });
  });

  describe('ledger ids', () => {
    it('purchase and spend ids', () => {
      assert.strictEqual(purchaseLedgerId('ios', 'abc'), 'ios:abc');
      assert.strictEqual(
        spendLedgerId('ios', 'u1', 'req-1'),
        'ios:spend:u1:req-1',
      );
    });
  });
});
