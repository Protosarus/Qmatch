'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleSendSuperResonance,
} = require('../src/send_super_resonance_callable');
const {
  handleGetSuperResonanceAvailability,
  CALLABLE_NAME: AVAILABILITY_NAME,
} = require('../src/get_super_resonance_availability_callable');
const {
  DAILY_LIMIT,
  resolveDailyAllowance,
} = require('../src/super_resonance_daily_allowance');
const { normalizeSnapshot } = require('../src/entitlement_access');

const DAY_1 = '2026-08-17T12:00:00.000Z';
const DAY_2 = '2026-08-18T00:00:00.000Z';

function eligibleUser(overrides = {}) {
  return {
    discover_eligible: true,
    active: true,
    profile_completed: true,
    test_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    name: 'Ada',
    ...overrides,
  };
}

function entitlement(uid, extras = {}) {
  return {
    uid,
    tier: 'resonance',
    subscription_state: 'active',
    resonance_access: true,
    canonical_product_key: 'resonance_monthly',
    super_resonance_balance: 0,
    boost_balance: 0,
    schema_version: 'resonance_entitlement_firestore_schema_v1',
    ...extras,
  };
}

function request(uid, targetUid, requestId) {
  return {
    auth: uid ? { uid } : null,
    data: { target_uid: targetUid, request_id: requestId },
  };
}

function deps(db, nowIso = DAY_1) {
  return {
    db,
    serverTimestamp: () => 'TS',
    now: () => new Date(nowIso),
  };
}

async function seedReady(db, extras = {}) {
  const from = extras.from || 'userA';
  const to = extras.to || 'userB';
  await db.doc(`users/${from}`).set(eligibleUser({ name: from }));
  await db.doc(`users/${to}`).set(eligibleUser({ name: to }));
  await db.doc(`entitlements/${from}`).set(
    entitlement(from, extras.entitlement || {}),
  );
  return { from, to };
}

function reqId(n) {
  return `${String(n).padStart(8, '0')}-aaaa-4aaa-8aaa-aaaaaaaaaaaa`;
}

describe('super_resonance_daily_allowance_v1', () => {
  it('availability callable name is getSuperResonanceAvailability', () => {
    assert.strictEqual(AVAILABILITY_NAME, 'getSuperResonanceAvailability');
  });

  it('1. active monthly starts day with 2', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { canonical_product_key: 'resonance_monthly' },
    });
    const res = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db),
    );
    assert.strictEqual(res.daily_remaining, 2);
    assert.strictEqual(res.daily_limit, DAILY_LIMIT);
    assert.strictEqual(res.purchased_balance, 0);
    assert.strictEqual(res.total_available, 2);
    assert.strictEqual(res.super_resonance_balance, 0);
  });

  it('2. active annual starts day with 2', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { canonical_product_key: 'resonance_annual' },
    });
    const res = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db),
    );
    assert.strictEqual(res.daily_remaining, 2);
    assert.strictEqual(res.total_available, 2);
  });

  it('3. Free gets 0 daily', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: {
        tier: 'free',
        subscription_state: 'none',
        resonance_access: false,
        canonical_product_key: null,
        super_resonance_balance: 4,
      },
    });
    const res = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db),
    );
    assert.strictEqual(res.daily_remaining, 0);
    assert.strictEqual(res.daily_limit, 0);
    assert.strictEqual(res.purchased_balance, 4);
    assert.strictEqual(res.total_available, 4);
  });

  it('4. first send -> 1 daily remaining', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db, {
      entitlement: { super_resonance_balance: 5 },
    });
    const res = await handleSendSuperResonance(
      request(from, to, reqId(1)),
      deps(db),
    );
    assert.strictEqual(res.already_sent, false);
    assert.strictEqual(res.daily_remaining, 1);
    assert.strictEqual(res.purchased_balance, 5);
    assert.strictEqual(res.total_available, 6);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 5);
    assert.strictEqual(ent.super_resonance_daily_used, 1);
    assert.strictEqual(ent.super_resonance_daily_utc_date, '2026-08-17');
  });

  it('5. second send -> 0 daily remaining', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { super_resonance_balance: 5 },
    });
    await db.doc('users/userC').set(eligibleUser({ name: 'userC' }));
    const first = await handleSendSuperResonance(
      request(from, 'userB', reqId(1)),
      deps(db),
    );
    const second = await handleSendSuperResonance(
      request(from, 'userC', reqId(2)),
      deps(db),
    );
    assert.strictEqual(first.daily_remaining, 1);
    assert.strictEqual(second.daily_remaining, 0);
    assert.strictEqual(second.purchased_balance, 5);
    assert.strictEqual(second.total_available, 5);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 5);
    assert.strictEqual(ent.super_resonance_daily_used, 2);
  });

  it('6. third send uses purchased balance', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { super_resonance_balance: 5 },
    });
    await db.doc('users/userC').set(eligibleUser({ name: 'userC' }));
    await db.doc('users/userD').set(eligibleUser({ name: 'userD' }));
    await handleSendSuperResonance(request(from, 'userB', reqId(1)), deps(db));
    await handleSendSuperResonance(request(from, 'userC', reqId(2)), deps(db));
    const third = await handleSendSuperResonance(
      request(from, 'userD', reqId(3)),
      deps(db),
    );
    assert.strictEqual(third.daily_remaining, 0);
    assert.strictEqual(third.purchased_balance, 4);
    assert.strictEqual(third.super_resonance_balance, 4);
    assert.strictEqual(third.total_available, 4);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 4);
    assert.strictEqual(ent.super_resonance_daily_used, 2);
  });

  it('7. no purchased balance -> insufficient', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db, {
      entitlement: {
        super_resonance_balance: 0,
        super_resonance_daily_utc_date: '2026-08-17',
        super_resonance_daily_used: 2,
      },
    });
    await assert.rejects(
      () => handleSendSuperResonance(request(from, to, reqId(7)), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'insufficient_balance',
    );
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 0);
    assert.strictEqual(ent.super_resonance_daily_used, 2);
    assert.strictEqual(
      (await db.doc(`super_resonance_signals/${from}_${to}`).get()).exists,
      false,
    );
  });

  it('8. next trusted UTC day resets daily allowance to 2', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { super_resonance_balance: 3 },
    });
    await db.doc('users/userC').set(eligibleUser({ name: 'userC' }));
    await db.doc('users/userD').set(eligibleUser({ name: 'userD' }));
    await handleSendSuperResonance(request(from, 'userB', reqId(1)), deps(db, DAY_1));
    await handleSendSuperResonance(request(from, 'userC', reqId(2)), deps(db, DAY_1));
    const day1 = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(day1.super_resonance_daily_used, 2);
    assert.strictEqual(day1.super_resonance_balance, 3);

    const peek = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db, DAY_2),
    );
    assert.strictEqual(peek.daily_remaining, 2);
    assert.strictEqual(peek.purchased_balance, 3);
    assert.strictEqual(peek.total_available, 5);

    const next = await handleSendSuperResonance(
      request(from, 'userD', reqId(8)),
      deps(db, DAY_2),
    );
    assert.strictEqual(next.daily_remaining, 1);
    assert.strictEqual(next.purchased_balance, 3);
    const day2 = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(day2.super_resonance_daily_utc_date, '2026-08-18');
    assert.strictEqual(day2.super_resonance_daily_used, 1);
    assert.strictEqual(day2.super_resonance_balance, 3);
  });

  it('9. unused allowance does not accumulate', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: {
        super_resonance_balance: 1,
        super_resonance_daily_utc_date: '2026-08-17',
        super_resonance_daily_used: 0,
      },
    });
    const peek = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db, DAY_2),
    );
    assert.strictEqual(peek.daily_remaining, 2);
    assert.strictEqual(peek.total_available, 3);

    const resolved = resolveDailyAllowance(
      normalizeSnapshot(from, {
        tier: 'resonance',
        subscription_state: 'active',
        resonance_access: true,
        super_resonance_balance: 1,
        super_resonance_daily_utc_date: '2026-08-17',
        super_resonance_daily_used: 1,
      }),
      new Date(DAY_2),
    );
    assert.strictEqual(resolved.remaining, 2);
    assert.strictEqual(resolved.used, 0);
    assert.strictEqual(resolved.purchased, 1);
  });

  it('10. duplicate request_id / duplicate pair does not consume allowance twice', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db, {
      entitlement: { super_resonance_balance: 9 },
    });
    const first = await handleSendSuperResonance(
      request(from, to, reqId(10)),
      deps(db),
    );
    const dupReq = await handleSendSuperResonance(
      request(from, to, reqId(10)),
      deps(db),
    );
    const dupPair = await handleSendSuperResonance(
      request(from, to, reqId(11)),
      deps(db),
    );
    assert.strictEqual(first.already_sent, false);
    assert.strictEqual(first.daily_remaining, 1);
    assert.strictEqual(dupReq.already_sent, true);
    assert.strictEqual(dupReq.daily_remaining, 1);
    assert.strictEqual(dupReq.purchased_balance, 9);
    assert.strictEqual(dupPair.already_sent, true);
    assert.strictEqual(dupPair.daily_remaining, 1);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_daily_used, 1);
    assert.strictEqual(ent.super_resonance_balance, 9);
  });

  it('11. expired Resonance gets 0 daily', async () => {
    const db = new MemoryFirestore();
    const { from, to } = await seedReady(db, {
      entitlement: {
        tier: 'resonance',
        subscription_state: 'expired',
        resonance_access: true,
        super_resonance_balance: 2,
      },
    });
    const peek = await handleGetSuperResonanceAvailability(
      { auth: { uid: from }, data: {} },
      deps(db),
    );
    assert.strictEqual(peek.daily_remaining, 0);
    assert.strictEqual(peek.daily_limit, 0);
    assert.strictEqual(peek.purchased_balance, 2);
    assert.strictEqual(peek.total_available, 2);

    const sent = await handleSendSuperResonance(
      request(from, to, reqId(11)),
      deps(db),
    );
    assert.strictEqual(sent.daily_remaining, 0);
    assert.strictEqual(sent.purchased_balance, 1);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 1);
    assert.strictEqual(ent.resonance_access, false);
  });

  it('12. purchased balance remains untouched until daily allowance exhausted', async () => {
    const db = new MemoryFirestore();
    const { from } = await seedReady(db, {
      entitlement: { super_resonance_balance: 7 },
    });
    await db.doc('users/userC').set(eligibleUser({ name: 'userC' }));
    const first = await handleSendSuperResonance(
      request(from, 'userB', reqId(12)),
      deps(db),
    );
    const second = await handleSendSuperResonance(
      request(from, 'userC', reqId(13)),
      deps(db),
    );
    assert.strictEqual(first.purchased_balance, 7);
    assert.strictEqual(second.purchased_balance, 7);
    const ent = (await db.doc(`entitlements/${from}`).get()).data();
    assert.strictEqual(ent.super_resonance_balance, 7);
    assert.strictEqual(ent.super_resonance_daily_used, 2);
  });

  it('does not trust a client clock or request now', () => {
    const sendSrc = fs.readFileSync(
      path.join(__dirname, '../src/send_super_resonance_callable.js'),
      'utf8',
    );
    const getSrc = fs.readFileSync(
      path.join(__dirname, '../src/get_super_resonance_availability_callable.js'),
      'utf8',
    );
    assert.strictEqual(sendSrc.includes('data.now'), false);
    assert.strictEqual(sendSrc.includes('request.data.now'), false);
    assert.strictEqual(getSrc.includes('data.now'), false);
    assert.strictEqual(sendSrc.includes('Date.now()'), false);
    assert.ok(sendSrc.includes('resolveDailyAllowance'));
    assert.ok(sendSrc.includes('spendDailyAllowance'));
  });

  it('availability is unauthenticated without auth', async () => {
    await assert.rejects(
      () =>
        handleGetSuperResonanceAvailability(
          { auth: null, data: {} },
          deps(new MemoryFirestore()),
        ),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });
});
