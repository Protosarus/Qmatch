'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const catalog = require('../src/assessment_finalize_catalog_v1.generated');
const {
  SCHEMA_VERSION,
  CATALOG_VERSION,
} = require('../src/assessment_finalize_validation_v1');
const {
  CALLABLE_NAME,
  REGION,
  SOURCE,
  VERIFICATION_SCHEMA,
  FROZEN_USER_KEYS,
  handleFinalizeIq,
} = require('../src/finalize_iq_v1');

function bankFor(assessmentType, locale) {
  return catalog.banks.find(
    (bank) =>
      bank.assessment_type === assessmentType && bank.bank_locale === locale,
  );
}

function pickIqItems(bank) {
  const remaining = { ...bank.dimension_quotas };
  const usedFamilies = new Set();
  const picked = [];
  for (const item of bank.items) {
    if ((remaining[item.dimension] || 0) <= 0) continue;
    if (usedFamilies.has(item.template_family_id)) continue;
    picked.push(item);
    usedFamilies.add(item.template_family_id);
    remaining[item.dimension] -= 1;
  }
  assert.strictEqual(picked.length, 25);
  return picked;
}

function buildIqPayload(overrides = {}) {
  const bank = bankFor('iq', 'en-US');
  const items = pickIqItems(bank);
  return {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: 'iq_sess_finalize_test',
    owner_uid: 'userA',
    assessment_type: 'iq',
    bank_version: bank.bank_version,
    bank_locale: bank.bank_locale,
    selection_policy_version: bank.selection_policy_version,
    item_plans: items.map((item) => ({
      item_id: item.id,
      displayed_option_ids: [...item.option_ids],
    })),
    answers: items.map((item) => ({
      item_id: item.id,
      selected_option_id: item.option_ids[0],
    })),
    ...overrides,
  };
}

function buildEqPayload() {
  const bank = bankFor('eq', 'en-US');
  return {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: 'eq_sess_finalize_test',
    owner_uid: 'userA',
    assessment_type: 'eq',
    bank_version: bank.bank_version,
    bank_locale: bank.bank_locale,
    selection_policy_version: bank.selection_policy_version,
    item_plans: bank.items.map((item) => ({
      item_id: item.id,
      displayed_option_ids: [...item.option_ids],
    })),
    answers: bank.items.map((item) => ({
      item_id: item.id,
      selected_option_id: item.option_ids[0],
    })),
  };
}

function request(uid, data) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

function deps(db, extras = {}) {
  const logs = extras.logs || [];
  let n = extras.timestampStart || 0;
  return {
    db,
    serverTimestamp: () => {
      n += 1;
      return `TS${n}`;
    },
    log: (line) => logs.push(line),
    logs,
  };
}

function baseUser(overrides = {}) {
  return {
    uid: 'userA',
    active: true,
    discover_eligible: false,
    profile_completed: false,
    test_completed: false,
    assessment_flow_completed: false,
    account_deletion_requested: false,
    bio: 'hello',
    ...overrides,
  };
}

async function seedUser(db, overrides = {}) {
  await db.doc('users/userA').set(baseUser(overrides));
}

function userData(db) {
  return db._store.get('users/userA');
}

function frozenSnapshot(data) {
  const out = {};
  for (const key of FROZEN_USER_KEYS) out[key] = data[key];
  return out;
}

describe('finalizeIq callable', () => {
  it('callable name and region are frozen', () => {
    assert.strictEqual(CALLABLE_NAME, 'finalizeIq');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(SOURCE, 'admin_finalize_iq_v1');
  });

  it('unauthenticated is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () => handleFinalizeIq(request(null, buildIqPayload()), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('owner_uid != auth.uid is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeIq(
          request('userA', buildIqPayload({ owner_uid: 'userB' })),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('missing user is not-found', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () => handleFinalizeIq(request('userA', buildIqPayload()), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'not-found',
    );
  });

  it('valid IQ session succeeds and writes trusted IQ state', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    const env = deps(db);
    const beforeFrozen = frozenSnapshot(userData(db));
    const res = await handleFinalizeIq(request('userA', payload), env);

    assert.deepStrictEqual(res, {
      ok: true,
      assessment_type: 'iq',
      status: 'verified',
      flow: 'iq',
      idempotent: false,
    });

    const user = userData(db);
    const trusted = user.assessment_verification_v1;
    assert.strictEqual(trusted.schema_version, VERIFICATION_SCHEMA);
    assert.strictEqual(trusted.flow, 'iq');
    assert.strictEqual(trusted.grant_reason, SOURCE);
    assert.strictEqual(trusted.catalog_version, CATALOG_VERSION);
    assert.strictEqual(trusted.iq.status, 'verified');
    assert.strictEqual(trusted.iq.source, SOURCE);
    assert.strictEqual(trusted.iq.session_id, payload.session_id);
    assert.strictEqual(trusted.iq.bank_version, payload.bank_version);
    assert.strictEqual(trusted.iq.bank_locale, payload.bank_locale);
    assert.strictEqual(trusted.iq.catalog_version, CATALOG_VERSION);
    assert.strictEqual(
      trusted.iq.selection_policy_version,
      payload.selection_policy_version,
    );
    assert.strictEqual(trusted.iq.verified_at, 'TS1');
    assert.strictEqual(user.iq_completed, true);
    assert.strictEqual(trusted.eq, undefined);
    assert.strictEqual(trusted.frequency, undefined);
    assert.strictEqual(user.bio, 'hello');
    assert.deepStrictEqual(frozenSnapshot(user), beforeFrozen);
    assert.ok(!JSON.stringify(trusted).includes('item_plans'));
    assert.ok(!JSON.stringify(trusted).includes('selected_option_id'));
    assert.ok(!JSON.stringify(trusted).includes('displayed_option_ids'));
    for (const line of env.logs) {
      assert.doesNotMatch(line, /selected_option|item_plans|displayed_option/);
    }
  });

  it('rejects a 24-item session with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    payload.item_plans = payload.item_plans.slice(1);
    payload.answers = payload.answers.slice(1);
    await assert.rejects(
      () => handleFinalizeIq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_ITEM_COUNT',
    );
    const user = userData(db);
    assert.strictEqual(user.assessment_verification_v1, undefined);
    assert.strictEqual(user.iq_completed, undefined);
  });

  it('rejects a duplicate plan item with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    payload.item_plans[1] = { ...payload.item_plans[0] };
    await assert.rejects(
      () => handleFinalizeIq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'DUPLICATE_PLAN_ITEM_ID',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects an unknown selected option with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    payload.answers[0] = {
      ...payload.answers[0],
      selected_option_id: 'not_an_option',
    };
    await assert.rejects(
      () => handleFinalizeIq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_SELECTED_OPTION',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects forged completion/score fields with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    for (const field of ['completed', 'test_completed', 'score']) {
      const payload = buildIqPayload({ [field]: true });
      await assert.rejects(
        () => handleFinalizeIq(request('userA', payload), deps(db)),
        (err) =>
          err instanceof HttpsError &&
          err.code === 'invalid-argument' &&
          err.details &&
          err.details.code === 'FORBIDDEN_AUTHORITY_FIELD',
      );
    }
    const user = userData(db);
    assert.strictEqual(user.assessment_verification_v1, undefined);
    assert.strictEqual(user.iq_completed, undefined);
    assert.strictEqual(user.test_completed, false);
  });

  it('rejects a valid EQ session and does not write', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () => handleFinalizeIq(request('userA', buildEqPayload()), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_ASSESSMENT_TYPE',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('same session retry is idempotent and keeps verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    const env = deps(db);
    const first = await handleFinalizeIq(request('userA', payload), env);
    const verifiedAt = userData(db).assessment_verification_v1.iq.verified_at;
    const second = await handleFinalizeIq(request('userA', payload), env);
    assert.strictEqual(first.idempotent, false);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(second.idempotent, true);
    assert.strictEqual(second.flow, 'iq');
    assert.strictEqual(
      userData(db).assessment_verification_v1.iq.verified_at,
      verifiedAt,
    );
    assert.strictEqual(verifiedAt, 'TS1');
  });

  it('repairs iq_completed on idempotent retry without changing verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    await handleFinalizeIq(request('userA', payload), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await db.doc('users/userA').set({
      ...userData(db),
      iq_completed: false,
    });
    const res = await handleFinalizeIq(request('userA', payload), deps(db, { timestampStart: 9 }));
    assert.strictEqual(res.idempotent, true);
    assert.strictEqual(userData(db).iq_completed, true);
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('rejects a different session_id after verified', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const first = buildIqPayload();
    await handleFinalizeIq(request('userA', first), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await assert.rejects(
      () =>
        handleFinalizeIq(
          request('userA', buildIqPayload({ session_id: 'iq_sess_other' })),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'IQ_ALREADY_VERIFIED',
    );
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('upgrades grandfathered IQ to verified', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'iq',
        grant_reason: 'pre_c2',
        iq: { status: 'grandfathered', source: 'pre_c2' },
      },
    });
    const res = await handleFinalizeIq(request('userA', buildIqPayload()), deps(db));
    assert.strictEqual(res.idempotent, false);
    assert.strictEqual(res.flow, 'iq');
    const iq = userData(db).assessment_verification_v1.iq;
    assert.strictEqual(iq.status, 'verified');
    assert.strictEqual(iq.source, SOURCE);
    assert.strictEqual(iq.session_id, 'iq_sess_finalize_test');
  });

  it('does not downgrade legacy_iq_eq / pre_c2_preserved / complete', async () => {
    for (const flow of ['legacy_iq_eq', 'pre_c2_preserved', 'complete']) {
      const db = new MemoryFirestore();
      await seedUser(db, {
        assessment_verification_v1: {
          schema_version: VERIFICATION_SCHEMA,
          flow,
          grant_reason: 'preserved_grant',
          eq: { status: 'grandfathered', source: 'pre_c2', marker: 'eq' },
          frequency:
            flow === 'complete'
              ? { status: 'grandfathered', source: 'pre_c2', marker: 'freq' }
              : undefined,
        },
      });
      const res = await handleFinalizeIq(
        request('userA', buildIqPayload()),
        deps(db),
      );
      assert.strictEqual(res.ok, true);
      assert.strictEqual(res.flow, flow);
      const trusted = userData(db).assessment_verification_v1;
      assert.strictEqual(trusted.flow, flow);
      assert.strictEqual(trusted.grant_reason, 'preserved_grant');
      assert.strictEqual(trusted.iq.status, 'verified');
      assert.deepStrictEqual(trusted.eq, {
        status: 'grandfathered',
        source: 'pre_c2',
        marker: 'eq',
      });
      if (flow === 'complete') {
        assert.deepStrictEqual(trusted.frequency, {
          status: 'grandfathered',
          source: 'pre_c2',
          marker: 'freq',
        });
      } else {
        assert.strictEqual(trusted.frequency, undefined);
      }
    }
  });

  it('preserves existing trusted EQ/Frequency submaps', async () => {
    const db = new MemoryFirestore();
    const eq = { status: 'verified', session_id: 'eq_keep' };
    const frequency = { status: 'grandfathered', session_id: 'freq_keep' };
    await seedUser(db, {
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'none',
        eq,
        frequency,
      },
    });
    const res = await handleFinalizeIq(request('userA', buildIqPayload()), deps(db));
    assert.strictEqual(res.flow, 'complete');
    const trusted = userData(db).assessment_verification_v1;
    assert.deepStrictEqual(trusted.eq, eq);
    assert.deepStrictEqual(trusted.frequency, frequency);
    assert.strictEqual(trusted.iq.status, 'verified');
  });

  it('concurrent identical finalizeIq attempts do not corrupt trusted state', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildIqPayload();
    const [a, b] = await Promise.all([
      handleFinalizeIq(request('userA', payload), deps(db)),
      handleFinalizeIq(request('userA', payload), deps(db, { timestampStart: 10 })),
    ]);
    const idempotentFlags = [a.idempotent, b.idempotent].sort();
    assert.deepStrictEqual(idempotentFlags, [false, true]);
    assert.strictEqual(a.ok, true);
    assert.strictEqual(b.ok, true);
    const trusted = userData(db).assessment_verification_v1;
    assert.strictEqual(trusted.iq.status, 'verified');
    assert.strictEqual(trusted.iq.session_id, payload.session_id);
    assert.strictEqual(trusted.flow, 'iq');
    assert.strictEqual(userData(db).iq_completed, true);
  });

  it('index.js exports exactly one europe-west1 finalizeIq and no Frequency V1 twin', () => {
    const index = fs.readFileSync(
      path.join(__dirname, '../index.js'),
      'utf8',
    );
    assert.ok(index.includes("exports.finalizeIq = onCall("));
    const start = index.indexOf('exports.finalizeIq = onCall(');
    const block = index.slice(start, start + 220);
    assert.ok(block.includes("region: 'europe-west1'"));
    assert.ok(!index.includes('finalizeIqEu'));
    assert.ok(index.includes('exports.finalizeEq = onCall('));
    assert.ok(!/\bexports\.finalizeFrequency\s*=/.test(index));
    assert.ok(!index.includes('exports.handleFinalizeIq'));
  });
});
