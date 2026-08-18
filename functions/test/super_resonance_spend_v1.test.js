'use strict';

const assert = require('assert');
const {
  defaultFreeSnapshot,
  applySubscriptionState,
  creditBalance,
  debitBalance,
} = require('../src/entitlement_access');
const { spendLedgerId } = require('../src/entitlement_ledger');
const {
  spendSuperResonanceIdempotent,
  getOrCreateEntitlementSnapshot,
} = require('../src/entitlement_repository');
const {
  BALANCE_FIELDS,
  CANONICAL_PRODUCT_KEYS,
  EFFECTS,
  EVENT_TYPES,
} = require('../src/entitlement_schema');
const { MemoryFirestore } = require('./memory_firestore');

function resonanceSnapshot(uid, extras = {}) {
  const base = applySubscriptionState(defaultFreeSnapshot(uid), {
    tier: 'resonance',
    subscription_state: 'active',
    platform: 'ios',
    canonical_product_key: 'resonance_monthly',
  });
  return {
    ...base,
    super_resonance_balance: 2,
    boost_balance: 5,
    ...extras,
  };
}

async function seed(db, uid, extras) {
  await db.doc(`entitlements/${uid}`).set(resonanceSnapshot(uid, extras));
}

describe('super_resonance_spend_v1', () => {
  describe('debitBalance helper', () => {
    it('debits super resonance without touching boost or access', () => {
      const snap = resonanceSnapshot('u1');
      const next = debitBalance(snap, BALANCE_FIELDS.SUPER_RESONANCE, 1);
      assert.strictEqual(next.super_resonance_balance, 1);
      assert.strictEqual(next.boost_balance, 5);
      assert.strictEqual(next.tier, 'resonance');
      assert.strictEqual(next.resonance_access, true);
    });

    it('rejects debit when balance is 0', () => {
      const snap = resonanceSnapshot('u1', { super_resonance_balance: 0 });
      assert.throws(
        () => debitBalance(snap, BALANCE_FIELDS.SUPER_RESONANCE, 1),
        (err) => err && err.message === 'insufficient_balance',
      );
    });
  });

  describe('spendSuperResonanceIdempotent', () => {
    it('balance 2 -> spend -> 1', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1');

      const result = await spendSuperResonanceIdempotent(
        {
          uid: 'u1',
          requestId: '11111111-1111-4111-8111-111111111111',
          platform: 'ios',
          targetUid: 'peer-1',
        },
        { db },
      );

      assert.strictEqual(result.ok, true);
      assert.strictEqual(result.status, 'applied');
      assert.strictEqual(result.super_resonance_balance, 1);

      const ledgerId = spendLedgerId(
        'ios',
        'u1',
        '11111111-1111-4111-8111-111111111111',
      );
      const ledger = await db
        .doc(`entitlements/u1/purchase_ledger/${ledgerId}`)
        .get();
      assert.strictEqual(ledger.exists, true);
      const row = ledger.data();
      assert.strictEqual(row.event_type, EVENT_TYPES.CONSUMABLE_SPEND);
      assert.strictEqual(row.effect, EFFECTS.DEBIT_SUPER_RESONANCE);
      assert.strictEqual(row.verification_source, 'spend');
      assert.strictEqual(row.balance_delta_super_resonance, -1);
      assert.strictEqual(row.balance_delta_boost, 0);
      assert.strictEqual(row.target_uid, 'peer-1');
      assert.strictEqual(
        row.canonical_product_key,
        CANONICAL_PRODUCT_KEYS.SUPER_RESONANCE_X1,
      );

      const signals = [];
      for (const path of db._store.keys()) {
        if (path.includes('super_resonance_signals')) signals.push(path);
      }
      assert.deepStrictEqual(signals, []);
    });

    it('balance 0 -> fail closed', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1', { super_resonance_balance: 0 });

      const result = await spendSuperResonanceIdempotent(
        {
          uid: 'u1',
          requestId: '22222222-2222-4222-8222-222222222222',
          platform: 'ios',
        },
        { db },
      );

      assert.strictEqual(result.ok, false);
      assert.strictEqual(result.status, 'failed');
      assert.strictEqual(result.code, 'insufficient_balance');
      assert.strictEqual(result.super_resonance_balance, 0);

      const { snapshot } = await getOrCreateEntitlementSnapshot('u1', { db });
      assert.strictEqual(snapshot.super_resonance_balance, 0);
      assert.strictEqual(snapshot.boost_balance, 5);

      const ledgerId = spendLedgerId(
        'ios',
        'u1',
        '22222222-2222-4222-8222-222222222222',
      );
      const ledger = await db
        .doc(`entitlements/u1/purchase_ledger/${ledgerId}`)
        .get();
      assert.strictEqual(ledger.exists, false);
    });

    it('duplicate request_id -> no second debit', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1');
      const args = {
        uid: 'u1',
        requestId: '33333333-3333-4333-8333-333333333333',
        platform: 'ios',
      };

      const first = await spendSuperResonanceIdempotent(args, { db });
      const second = await spendSuperResonanceIdempotent(args, { db });

      assert.strictEqual(first.ok, true);
      assert.strictEqual(first.status, 'applied');
      assert.strictEqual(first.super_resonance_balance, 1);
      assert.strictEqual(second.ok, true);
      assert.strictEqual(second.status, 'noop');
      assert.strictEqual(second.super_resonance_balance, 1);

      const { snapshot } = await getOrCreateEntitlementSnapshot('u1', { db });
      assert.strictEqual(snapshot.super_resonance_balance, 1);
    });

    it('resonance_access and tier unchanged', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1');

      const result = await spendSuperResonanceIdempotent(
        {
          uid: 'u1',
          requestId: '44444444-4444-4444-8444-444444444444',
          platform: 'ios',
        },
        { db },
      );

      assert.strictEqual(result.ok, true);
      assert.strictEqual(result.snapshot.tier, 'resonance');
      assert.strictEqual(result.snapshot.resonance_access, true);
      assert.strictEqual(result.snapshot.subscription_state, 'active');
    });

    it('boost_balance unchanged', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1', { boost_balance: 7 });

      const result = await spendSuperResonanceIdempotent(
        {
          uid: 'u1',
          requestId: '55555555-5555-4555-8555-555555555555',
          platform: 'ios',
        },
        { db },
      );

      assert.strictEqual(result.ok, true);
      assert.strictEqual(result.snapshot.boost_balance, 7);
      assert.strictEqual(result.super_resonance_balance, 1);
    });

    it('concurrent duplicate request_id debits once', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1');
      const args = {
        uid: 'u1',
        requestId: '66666666-6666-4666-8666-666666666666',
        platform: 'ios',
      };

      const [a, b] = await Promise.all([
        spendSuperResonanceIdempotent(args, { db }),
        spendSuperResonanceIdempotent(args, { db }),
      ]);

      const statuses = [a.status, b.status].sort();
      assert.deepStrictEqual(statuses, ['applied', 'noop']);
      assert.strictEqual(a.ok, true);
      assert.strictEqual(b.ok, true);
      assert.strictEqual(a.super_resonance_balance, 1);
      assert.strictEqual(b.super_resonance_balance, 1);

      const { snapshot } = await getOrCreateEntitlementSnapshot('u1', { db });
      assert.strictEqual(snapshot.super_resonance_balance, 1);
      assert.strictEqual(snapshot.boost_balance, 5);
      assert.ok(snapshot.super_resonance_balance >= 0);
    });

    it('concurrent distinct request_ids cannot drive balance below 0', async () => {
      const db = new MemoryFirestore();
      await seed(db, 'u1', { super_resonance_balance: 1 });

      const [a, b] = await Promise.all([
        spendSuperResonanceIdempotent(
          {
            uid: 'u1',
            requestId: '77777777-7777-4777-8777-777777777777',
            platform: 'ios',
          },
          { db },
        ),
        spendSuperResonanceIdempotent(
          {
            uid: 'u1',
            requestId: '88888888-8888-4888-8888-888888888888',
            platform: 'ios',
          },
          { db },
        ),
      ]);

      const applied = [a, b].filter((r) => r.status === 'applied');
      const failed = [a, b].filter((r) => r.status === 'failed');
      assert.strictEqual(applied.length, 1);
      assert.strictEqual(failed.length, 1);
      assert.strictEqual(applied[0].super_resonance_balance, 0);
      assert.strictEqual(failed[0].ok, false);
      assert.strictEqual(failed[0].code, 'insufficient_balance');

      const { snapshot } = await getOrCreateEntitlementSnapshot('u1', { db });
      assert.strictEqual(snapshot.super_resonance_balance, 0);
      assert.ok(snapshot.super_resonance_balance >= 0);
    });
  });

  describe('creditBalance still isolated', () => {
    it('credit helper remains available and does not spend', () => {
      const snap = resonanceSnapshot('u1', { super_resonance_balance: 0 });
      const next = creditBalance(snap, BALANCE_FIELDS.SUPER_RESONANCE, 1);
      assert.strictEqual(next.super_resonance_balance, 1);
      assert.strictEqual(next.resonance_access, true);
    });
  });
});
