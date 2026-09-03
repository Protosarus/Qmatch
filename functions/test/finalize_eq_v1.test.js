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
const { deriveDiscoverEligible } = require('../src/discover_eligibility');
const {
  CALLABLE_NAME,
  REGION,
  SOURCE,
  VERIFICATION_SCHEMA,
  FROZEN_USER_KEYS,
  handleFinalizeEq,
} = require('../src/finalize_eq_v1');
const { handleFinalizeIq } = require('../src/finalize_iq_v1');

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

function buildEqPayload(overrides = {}) {
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
      primary_dimension: item.dimension,
    })),
    answers: bank.items.map((item) => ({
      item_id: item.id,
      selected_option_id: item.option_ids[0],
    })),
    ...overrides,
  };
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
    iq_completed: false,
    frequency_completed: false,
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

function storePaths(db) {
  return [...db._store.keys()];
}

describe('finalizeEq callable', () => {
  it('callable name and region are frozen', () => {
    assert.strictEqual(CALLABLE_NAME, 'finalizeEq');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(SOURCE, 'admin_finalize_eq_v1');
  });

  it('unauthenticated is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () => handleFinalizeEq(request(null, buildEqPayload()), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
    assert.strictEqual(userData(db).eq_completed, undefined);
  });

  it('owner_uid != auth.uid is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeEq(
          request('userA', buildEqPayload({ owner_uid: 'userB' })),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('missing user is not-found', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () => handleFinalizeEq(request('userA', buildEqPayload()), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'not-found',
    );
  });

  it('valid EQ session writes trusted eq proof and eq_completed mirror', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    const env = deps(db);
    const beforeFrozen = frozenSnapshot(userData(db));
    const res = await handleFinalizeEq(request('userA', payload), env);

    assert.deepStrictEqual(res, {
      ok: true,
      assessment_type: 'eq',
      status: 'verified',
      flow: 'none',
      idempotent: false,
    });

    const user = userData(db);
    const trusted = user.assessment_verification_v1;
    assert.strictEqual(trusted.schema_version, VERIFICATION_SCHEMA);
    assert.strictEqual(trusted.flow, 'none');
    assert.strictEqual(trusted.grant_reason, SOURCE);
    assert.strictEqual(trusted.catalog_version, CATALOG_VERSION);
    assert.strictEqual(trusted.eq.status, 'verified');
    assert.strictEqual(trusted.eq.source, SOURCE);
    assert.strictEqual(trusted.eq.session_id, payload.session_id);
    assert.strictEqual(trusted.eq.bank_version, payload.bank_version);
    assert.strictEqual(trusted.eq.bank_locale, payload.bank_locale);
    assert.strictEqual(trusted.eq.catalog_version, CATALOG_VERSION);
    assert.strictEqual(
      trusted.eq.selection_policy_version,
      payload.selection_policy_version,
    );
    assert.strictEqual(trusted.eq.verified_at, 'TS1');
    assert.strictEqual(user.eq_completed, true);
    assert.strictEqual(trusted.iq, undefined);
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

  it('does not write global completion, Discover, scores, assessments/eq, or canonical_v1', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      eq_score: 12,
      dimension_scores: { empathy: 0.5 },
    });
    const beforeScore = userData(db).eq_score;
    const beforeDims = userData(db).dimension_scores;
    await handleFinalizeEq(request('userA', buildEqPayload()), deps(db));
    const user = userData(db);
    assert.strictEqual(user.test_completed, false);
    assert.strictEqual(user.test_completed_at, undefined);
    assert.strictEqual(user.assessment_flow_completed, false);
    assert.strictEqual(user.assessment_flow_version, undefined);
    assert.strictEqual(user.discover_eligible, false);
    assert.strictEqual(user.iq_completed, false);
    assert.strictEqual(user.frequency_completed, false);
    assert.strictEqual(user.profile_completed, false);
    assert.strictEqual(user.eq_score, beforeScore);
    assert.deepStrictEqual(user.dimension_scores, beforeDims);
    assert.strictEqual(deriveDiscoverEligible(user), false);
    const paths = storePaths(db);
    assert.ok(!paths.includes('users/userA/assessments/eq'));
    assert.ok(!paths.includes('users/userA/profiles/canonical_v1'));
    assert.ok(!paths.some((p) => p.includes('/assessments/')));
    assert.ok(!paths.some((p) => p.includes('/profiles/')));
    assert.ok(!paths.some((p) => p.includes('public_profiles')));
  });

  it('eq_completed and verification map do not grant Discover', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      active: true,
      profile_completed: true,
      profile_photo_url: 'https://example.com/p.jpg',
      test_completed: false,
      assessment_flow_completed: false,
    });
    await handleFinalizeEq(request('userA', buildEqPayload()), deps(db));
    const user = userData(db);
    assert.strictEqual(user.eq_completed, true);
    assert.strictEqual(user.assessment_verification_v1.eq.status, 'verified');
    assert.strictEqual(user.discover_eligible, false);
    assert.strictEqual(deriveDiscoverEligible(user), false);
  });

  it('preserves existing trusted IQ verification and derives iq_eq', async () => {
    const db = new MemoryFirestore();
    const iq = {
      status: 'verified',
      source: 'admin_finalize_iq_v1',
      session_id: 'iq_keep',
    };
    await seedUser(db, {
      iq_completed: true,
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'iq',
        grant_reason: 'admin_finalize_iq_v1',
        iq,
      },
    });
    const res = await handleFinalizeEq(
      request('userA', buildEqPayload()),
      deps(db),
    );
    assert.strictEqual(res.flow, 'iq_eq');
    const trusted = userData(db).assessment_verification_v1;
    assert.deepStrictEqual(trusted.iq, iq);
    assert.strictEqual(trusted.eq.status, 'verified');
    assert.strictEqual(trusted.flow, 'iq_eq');
    assert.strictEqual(userData(db).iq_completed, true);
  });

  it('preserves existing Frequency V1 verification and does not treat it as V2', async () => {
    const db = new MemoryFirestore();
    const frequency = {
      status: 'grandfathered',
      source: 'pre_c2',
      session_id: 'freq_v1_keep',
    };
    const iq = { status: 'verified', session_id: 'iq_keep' };
    await seedUser(db, {
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'iq',
        iq,
        frequency,
      },
    });
    const res = await handleFinalizeEq(
      request('userA', buildEqPayload()),
      deps(db),
    );
    assert.strictEqual(res.flow, 'complete');
    const trusted = userData(db).assessment_verification_v1;
    assert.deepStrictEqual(trusted.frequency, frequency);
    assert.strictEqual(trusted.iq.session_id, 'iq_keep');
    assert.strictEqual(trusted.eq.status, 'verified');
    assert.ok(!JSON.stringify(trusted).includes('frequency_v2'));
    assert.ok(!storePaths(db).some((p) => p.endsWith('/assessments/frequency_v2')));
  });

  it('rejects a malformed session with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    payload.item_plans = 'not-an-array';
    await assert.rejects(
      () => handleFinalizeEq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_ITEM_PLANS',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
    assert.strictEqual(userData(db).eq_completed, undefined);
  });

  it('rejects a wrong bank_version with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeEq(
          request('userA', buildEqPayload({ bank_version: 'eq_bank_nope' })),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_BANK',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a duplicate plan item with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    payload.item_plans[1] = { ...payload.item_plans[0] };
    await assert.rejects(
      () => handleFinalizeEq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'DUPLICATE_PLAN_ITEM_ID',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects an invalid selected option with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    payload.answers[0] = {
      ...payload.answers[0],
      selected_option_id: 'not_an_option',
    };
    await assert.rejects(
      () => handleFinalizeEq(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_SELECTED_OPTION',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a forbidden score field with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeEq(
          request('userA', buildEqPayload({ score: 99, eq_score: 40 })),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'FORBIDDEN_AUTHORITY_FIELD',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects forbidden completion fields with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    for (const field of [
      'eq_completed',
      'test_completed',
      'assessment_flow_completed',
      'completed_at',
    ]) {
      await assert.rejects(
        () =>
          handleFinalizeEq(
            request('userA', buildEqPayload({ [field]: true })),
            deps(db),
          ),
        (err) =>
          err instanceof HttpsError &&
          err.code === 'invalid-argument' &&
          err.details &&
          err.details.code === 'FORBIDDEN_AUTHORITY_FIELD',
      );
    }
    const user = userData(db);
    assert.strictEqual(user.assessment_verification_v1, undefined);
    assert.strictEqual(user.eq_completed, undefined);
    assert.strictEqual(user.test_completed, false);
  });

  it('same session retry is idempotent and keeps verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    const env = deps(db);
    const first = await handleFinalizeEq(request('userA', payload), env);
    const verifiedAt = userData(db).assessment_verification_v1.eq.verified_at;
    const second = await handleFinalizeEq(request('userA', payload), env);
    assert.strictEqual(first.idempotent, false);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(second.idempotent, true);
    assert.strictEqual(second.flow, 'none');
    assert.strictEqual(
      userData(db).assessment_verification_v1.eq.verified_at,
      verifiedAt,
    );
    assert.strictEqual(verifiedAt, 'TS1');
    assert.strictEqual(userData(db).eq_completed, true);
  });

  it('repairs eq_completed on idempotent retry without changing verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildEqPayload();
    await handleFinalizeEq(request('userA', payload), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await db.doc('users/userA').set({
      ...userData(db),
      eq_completed: false,
    });
    const res = await handleFinalizeEq(
      request('userA', payload),
      deps(db, { timestampStart: 9 }),
    );
    assert.strictEqual(res.idempotent, true);
    assert.strictEqual(userData(db).eq_completed, true);
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('rejects a different session_id after verified', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const first = buildEqPayload();
    await handleFinalizeEq(request('userA', first), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await assert.rejects(
      () =>
        handleFinalizeEq(
          request('userA', buildEqPayload({ session_id: 'eq_sess_other' })),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'EQ_ALREADY_VERIFIED',
    );
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('upgrades grandfathered EQ to verified for a newly validated session', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'none',
        grant_reason: 'pre_c2',
        eq: { status: 'grandfathered', source: 'pre_c2' },
      },
    });
    const res = await handleFinalizeEq(
      request('userA', buildEqPayload()),
      deps(db),
    );
    assert.strictEqual(res.idempotent, false);
    const eq = userData(db).assessment_verification_v1.eq;
    assert.strictEqual(eq.status, 'verified');
    assert.strictEqual(eq.source, SOURCE);
    assert.strictEqual(eq.session_id, 'eq_sess_finalize_test');
  });

  it('does not downgrade legacy_iq_eq / pre_c2_preserved / complete', async () => {
    for (const flow of ['legacy_iq_eq', 'pre_c2_preserved', 'complete']) {
      const db = new MemoryFirestore();
      await seedUser(db, {
        assessment_verification_v1: {
          schema_version: VERIFICATION_SCHEMA,
          flow,
          grant_reason: 'preserved_grant',
          iq: { status: 'grandfathered', source: 'pre_c2', marker: 'iq' },
          frequency:
            flow === 'complete'
              ? { status: 'grandfathered', source: 'pre_c2', marker: 'freq' }
              : undefined,
        },
      });
      const res = await handleFinalizeEq(
        request('userA', buildEqPayload()),
        deps(db),
      );
      assert.strictEqual(res.ok, true);
      assert.strictEqual(res.flow, flow);
      const trusted = userData(db).assessment_verification_v1;
      assert.strictEqual(trusted.flow, flow);
      assert.strictEqual(trusted.grant_reason, 'preserved_grant');
      assert.strictEqual(trusted.eq.status, 'verified');
      assert.deepStrictEqual(trusted.iq, {
        status: 'grandfathered',
        source: 'pre_c2',
        marker: 'iq',
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

  it('rejects a valid IQ session and does not write', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () => handleFinalizeEq(request('userA', buildIqPayload()), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_ASSESSMENT_TYPE',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('finalizeIq still rejects EQ sessions after finalizeEq exists', async () => {
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
    assert.strictEqual(userData(db).eq_completed, undefined);
  });

    it('index.js exports exactly one europe-west1 finalizeEq distinct from Frequency V1/V2', () => {
    const index = fs.readFileSync(
      path.join(__dirname, '../index.js'),
      'utf8',
    );
    assert.ok(index.includes('exports.finalizeEq = onCall('));
    const start = index.indexOf('exports.finalizeEq = onCall(');
    const block = index.slice(start, start + 220);
    assert.ok(block.includes("region: 'europe-west1'"));
    assert.ok(!index.includes('finalizeEqEu'));
    assert.ok(index.includes('exports.finalizeFrequency = onCall('));
    assert.ok(!index.includes('exports.handleFinalizeEq'));
    assert.ok(index.includes('exports.finalizeIq = onCall('));
    assert.ok(index.includes('exports.finalizeFrequencyV2 = onCall('));
  });
});
