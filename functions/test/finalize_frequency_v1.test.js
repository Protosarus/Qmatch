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
  handleFinalizeFrequency,
} = require('../src/finalize_frequency_v1');
const { handleFinalizeIq } = require('../src/finalize_iq_v1');
const { handleFinalizeEq } = require('../src/finalize_eq_v1');
const {
  handleFinalizeFrequencyV2,
} = require('../src/finalize_frequency_v2_v1');

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

function buildFrequencyPayload(locale = 'en-US', overrides = {}) {
  const bank = bankFor('frequency', locale);
  return {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: `freq_v1_sess_${locale}`,
    owner_uid: 'userA',
    assessment_type: 'frequency',
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
    eq_completed: false,
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

function findByRole(bank, role) {
  return bank.items.find((item) => item.item_role === role);
}

function findCore(bank) {
  return bank.items.find((item) => item.item_role === 'core');
}

describe('finalizeFrequency callable', () => {
  it('callable name and region are frozen', () => {
    assert.strictEqual(CALLABLE_NAME, 'finalizeFrequency');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(SOURCE, 'admin_finalize_frequency_v1');
  });

  it('unauthenticated is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeFrequency(request(null, buildFrequencyPayload()), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
    assert.strictEqual(userData(db).frequency_completed, false);
  });

  it('owner_uid != auth.uid is denied', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request('userA', buildFrequencyPayload('en-US', { owner_uid: 'userB' })),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'permission-denied',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('missing user is not-found', async () => {
    const db = new MemoryFirestore();
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request('userA', buildFrequencyPayload()),
          deps(db),
        ),
      (err) => err instanceof HttpsError && err.code === 'not-found',
    );
  });

  it('valid EN Frequency V1 session writes trusted frequency proof', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload('en-US');
    const env = deps(db);
    const beforeFrozen = frozenSnapshot(userData(db));
    const res = await handleFinalizeFrequency(request('userA', payload), env);

    assert.deepStrictEqual(res, {
      ok: true,
      assessment_type: 'frequency',
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
    assert.strictEqual(trusted.frequency.status, 'verified');
    assert.strictEqual(trusted.frequency.source, SOURCE);
    assert.strictEqual(trusted.frequency.session_id, payload.session_id);
    assert.strictEqual(trusted.frequency.bank_version, payload.bank_version);
    assert.strictEqual(trusted.frequency.bank_locale, 'en-US');
    assert.strictEqual(trusted.frequency.catalog_version, CATALOG_VERSION);
    assert.strictEqual(
      trusted.frequency.selection_policy_version,
      payload.selection_policy_version,
    );
    assert.strictEqual(trusted.frequency.verified_at, 'TS1');
    assert.strictEqual(user.frequency_completed, true);
    assert.strictEqual(trusted.iq, undefined);
    assert.strictEqual(trusted.eq, undefined);
    assert.strictEqual(user.bio, 'hello');
    assert.deepStrictEqual(frozenSnapshot(user), beforeFrozen);
    assert.ok(!JSON.stringify(trusted).includes('item_plans'));
    assert.ok(!JSON.stringify(trusted).includes('selected_option_id'));
    assert.ok(!JSON.stringify(trusted).includes('displayed_option_ids'));
    assert.ok(!JSON.stringify(trusted).includes('frequency_v2'));
    for (const line of env.logs) {
      assert.doesNotMatch(line, /selected_option|item_plans|displayed_option/);
    }
  });

  it('valid TR Frequency V1 session is accepted', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload('tr-TR');
    const res = await handleFinalizeFrequency(
      request('userA', payload),
      deps(db),
    );
    assert.strictEqual(res.ok, true);
    assert.strictEqual(res.idempotent, false);
    const trusted = userData(db).assessment_verification_v1.frequency;
    assert.strictEqual(trusted.status, 'verified');
    assert.strictEqual(trusted.bank_locale, 'tr-TR');
    assert.strictEqual(trusted.bank_version, payload.bank_version);
    assert.strictEqual(userData(db).frequency_completed, true);
  });

  it('does not write global completion, Discover, scores, assessments, or canonical_v1', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      frequency_score: 12,
      dimension_scores: { social_energy: 0.5 },
    });
    const beforeScore = userData(db).frequency_score;
    const beforeDims = userData(db).dimension_scores;
    await handleFinalizeFrequency(
      request('userA', buildFrequencyPayload()),
      deps(db),
    );
    const user = userData(db);
    assert.strictEqual(user.test_completed, false);
    assert.strictEqual(user.test_completed_at, undefined);
    assert.strictEqual(user.assessment_flow_completed, false);
    assert.strictEqual(user.assessment_flow_version, undefined);
    assert.strictEqual(user.discover_eligible, false);
    assert.strictEqual(user.iq_completed, false);
    assert.strictEqual(user.eq_completed, false);
    assert.strictEqual(user.profile_completed, false);
    assert.strictEqual(user.frequency_score, beforeScore);
    assert.deepStrictEqual(user.dimension_scores, beforeDims);
    assert.strictEqual(deriveDiscoverEligible(user), false);
    const paths = storePaths(db);
    assert.ok(!paths.includes('users/userA/assessments/frequency'));
    assert.ok(!paths.includes('users/userA/assessments/frequency_v2'));
    assert.ok(!paths.includes('users/userA/profiles/canonical_v1'));
    assert.ok(!paths.some((p) => p.includes('/assessments/')));
    assert.ok(!paths.some((p) => p.includes('/profiles/')));
    assert.ok(!paths.some((p) => p.includes('public_profiles')));
  });

  it('frequency_completed and verification map do not grant Discover', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      active: true,
      profile_completed: true,
      profile_photo_url: 'https://example.com/p.jpg',
      test_completed: false,
      assessment_flow_completed: false,
    });
    await handleFinalizeFrequency(
      request('userA', buildFrequencyPayload()),
      deps(db),
    );
    const user = userData(db);
    assert.strictEqual(user.frequency_completed, true);
    assert.strictEqual(
      user.assessment_verification_v1.frequency.status,
      'verified',
    );
    assert.strictEqual(user.discover_eligible, false);
    assert.strictEqual(deriveDiscoverEligible(user), false);
  });

  it('preserves existing trusted IQ and EQ verification and derives complete', async () => {
    const db = new MemoryFirestore();
    const iq = {
      status: 'verified',
      source: 'admin_finalize_iq_v1',
      session_id: 'iq_keep',
    };
    const eq = {
      status: 'verified',
      source: 'admin_finalize_eq_v1',
      session_id: 'eq_keep',
    };
    await seedUser(db, {
      iq_completed: true,
      eq_completed: true,
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'iq_eq',
        grant_reason: 'admin_finalize_eq_v1',
        iq,
        eq,
      },
    });
    const res = await handleFinalizeFrequency(
      request('userA', buildFrequencyPayload()),
      deps(db),
    );
    assert.strictEqual(res.flow, 'complete');
    const trusted = userData(db).assessment_verification_v1;
    assert.deepStrictEqual(trusted.iq, iq);
    assert.deepStrictEqual(trusted.eq, eq);
    assert.strictEqual(trusted.frequency.status, 'verified');
    assert.strictEqual(trusted.frequency.source, SOURCE);
    assert.strictEqual(trusted.flow, 'complete');
    assert.strictEqual(userData(db).iq_completed, true);
    assert.strictEqual(userData(db).eq_completed, true);
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
          eq: { status: 'grandfathered', source: 'pre_c2', marker: 'eq' },
        },
      });
      const res = await handleFinalizeFrequency(
        request('userA', buildFrequencyPayload()),
        deps(db),
      );
      assert.strictEqual(res.ok, true);
      const expectedFlow = flow === 'legacy_iq_eq' ? 'complete' : flow;
      assert.strictEqual(res.flow, expectedFlow);
      const trusted = userData(db).assessment_verification_v1;
      assert.strictEqual(trusted.flow, expectedFlow);
      assert.strictEqual(trusted.grant_reason, 'preserved_grant');
      assert.strictEqual(trusted.frequency.status, 'verified');
      assert.deepStrictEqual(trusted.iq, {
        status: 'grandfathered',
        source: 'pre_c2',
        marker: 'iq',
      });
      assert.deepStrictEqual(trusted.eq, {
        status: 'grandfathered',
        source: 'pre_c2',
        marker: 'eq',
      });
    }
  });

  it('rejects a malformed session with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    payload.item_plans = 'not-an-array';
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_ITEM_PLANS',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
    assert.strictEqual(userData(db).frequency_completed, false);
  });

  it('rejects a wrong bank_version with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request(
            'userA',
            buildFrequencyPayload('en-US', { bank_version: 'frequency_bank_nope' }),
          ),
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

  it('rejects a wrong selection policy version with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request(
            'userA',
            buildFrequencyPayload('en-US', {
              selection_policy_version: 'frequency_wrong_policy',
            }),
          ),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_SELECTION_POLICY',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a duplicate plan item with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    payload.item_plans[1] = { ...payload.item_plans[0] };
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'DUPLICATE_PLAN_ITEM_ID',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a missing answer with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    payload.answers = payload.answers.slice(1);
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'PLAN_ANSWER_MISMATCH',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects an invalid selected option with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    payload.answers[0] = {
      ...payload.answers[0],
      selected_option_id: 'not_an_option',
    };
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_SELECTED_OPTION',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects invalid displayed options with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    payload.item_plans[0] = {
      ...payload.item_plans[0],
      displayed_option_ids: ['nope', 'nope2', 'nope3', 'nope4'],
    };
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_DISPLAYED_OPTIONS',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a Frequency blueprint violation with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const bank = bankFor('frequency', 'en-US');
    const core = findCore(bank);
    const otherDim = bank.canonical_dimensions.find(
      (dim) => dim !== core.dimension,
    );
    const payload = buildFrequencyPayload();
    const index = payload.item_plans.findIndex((p) => p.item_id === core.id);
    payload.item_plans[index] = {
      ...payload.item_plans[index],
      primary_dimension: otherDim,
    };
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_FREQUENCY_BLUEPRINT',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a forbidden score field with zero writes', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request(
            'userA',
            buildFrequencyPayload('en-US', {
              score: 99,
              frequency_score: 40,
            }),
          ),
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
      'frequency_completed',
      'test_completed',
      'assessment_flow_completed',
      'completed_at',
    ]) {
      await assert.rejects(
        () =>
          handleFinalizeFrequency(
            request('userA', buildFrequencyPayload('en-US', { [field]: true })),
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
    assert.strictEqual(user.frequency_completed, false);
    assert.strictEqual(user.test_completed, false);
  });

  it('same session retry is idempotent and keeps verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    const env = deps(db);
    const first = await handleFinalizeFrequency(request('userA', payload), env);
    const verifiedAt =
      userData(db).assessment_verification_v1.frequency.verified_at;
    const second = await handleFinalizeFrequency(request('userA', payload), env);
    assert.strictEqual(first.idempotent, false);
    assert.strictEqual(second.ok, true);
    assert.strictEqual(second.idempotent, true);
    assert.strictEqual(second.flow, 'none');
    assert.strictEqual(
      userData(db).assessment_verification_v1.frequency.verified_at,
      verifiedAt,
    );
    assert.strictEqual(verifiedAt, 'TS1');
    assert.strictEqual(userData(db).frequency_completed, true);
  });

  it('repairs frequency_completed on idempotent retry without changing verified_at', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    await handleFinalizeFrequency(request('userA', payload), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await db.doc('users/userA').set({
      ...userData(db),
      frequency_completed: false,
    });
    const res = await handleFinalizeFrequency(
      request('userA', payload),
      deps(db, { timestampStart: 9 }),
    );
    assert.strictEqual(res.idempotent, true);
    assert.strictEqual(userData(db).frequency_completed, true);
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('rejects a different session_id after verified', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const first = buildFrequencyPayload();
    await handleFinalizeFrequency(request('userA', first), deps(db));
    const trusted = userData(db).assessment_verification_v1;
    await assert.rejects(
      () =>
        handleFinalizeFrequency(
          request(
            'userA',
            buildFrequencyPayload('en-US', { session_id: 'freq_sess_other' }),
          ),
          deps(db),
        ),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'failed-precondition' &&
        err.details &&
        err.details.code === 'FREQUENCY_ALREADY_VERIFIED',
    );
    assert.deepStrictEqual(userData(db).assessment_verification_v1, trusted);
  });

  it('upgrades grandfathered Frequency only after a newly validated session', async () => {
    const db = new MemoryFirestore();
    await seedUser(db, {
      frequency_completed: true,
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'none',
        grant_reason: 'pre_c2',
        frequency: { status: 'grandfathered', source: 'pre_c2' },
      },
    });
    const res = await handleFinalizeFrequency(
      request('userA', buildFrequencyPayload()),
      deps(db),
    );
    assert.strictEqual(res.idempotent, false);
    const frequency = userData(db).assessment_verification_v1.frequency;
    assert.strictEqual(frequency.status, 'verified');
    assert.strictEqual(frequency.source, SOURCE);
    assert.strictEqual(frequency.session_id, 'freq_v1_sess_en-US');
  });

  it('does not falsely upgrade grandfathered Frequency on a malformed session', async () => {
    const db = new MemoryFirestore();
    const grandfathered = { status: 'grandfathered', source: 'pre_c2' };
    await seedUser(db, {
      frequency_completed: true,
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'none',
        grant_reason: 'pre_c2',
        frequency: grandfathered,
      },
    });
    const payload = buildFrequencyPayload();
    payload.item_plans = 'not-an-array';
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
    const trusted = userData(db).assessment_verification_v1;
    assert.deepStrictEqual(trusted.frequency, grandfathered);
    assert.strictEqual(trusted.frequency.status, 'grandfathered');
  });

  it('rejects a valid IQ session and does not write', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', buildIqPayload()), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_ASSESSMENT_TYPE',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('finalizeIq still rejects Frequency sessions after finalizeFrequency exists', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeIq(request('userA', buildFrequencyPayload()), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_ASSESSMENT_TYPE',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
    assert.strictEqual(userData(db).frequency_completed, false);
  });

  it('finalizeEq still rejects Frequency sessions after finalizeFrequency exists', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    await assert.rejects(
      () =>
        handleFinalizeEq(request('userA', buildFrequencyPayload()), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'UNSUPPORTED_ASSESSMENT_TYPE',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('core items use A/B/C/D and separator items use opt_* in a valid session', async () => {
    const bank = bankFor('frequency', 'en-US');
    const core = findCore(bank);
    const separator = findByRole(bank, 'separator');
    const quality = findByRole(bank, 'response_quality');
    assert.deepStrictEqual(core.option_ids, ['A', 'B', 'C', 'D']);
    assert.deepStrictEqual(separator.option_ids, [
      'opt_a',
      'opt_b',
      'opt_c',
      'opt_d',
    ]);
    assert.deepStrictEqual(quality.option_ids, [
      'opt_a',
      'opt_b',
      'opt_c',
      'opt_d',
    ]);

    const db = new MemoryFirestore();
    await seedUser(db);
    const payload = buildFrequencyPayload();
    const corePlan = payload.item_plans.find((p) => p.item_id === core.id);
    const sepPlan = payload.item_plans.find((p) => p.item_id === separator.id);
    assert.deepStrictEqual(corePlan.displayed_option_ids, ['A', 'B', 'C', 'D']);
    assert.deepStrictEqual(sepPlan.displayed_option_ids, [
      'opt_a',
      'opt_b',
      'opt_c',
      'opt_d',
    ]);
    const res = await handleFinalizeFrequency(
      request('userA', payload),
      deps(db),
    );
    assert.strictEqual(res.ok, true);
  });

  it('rejects a separator rewritten as A/B/C/D', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const bank = bankFor('frequency', 'en-US');
    const separator = findByRole(bank, 'separator');
    const payload = buildFrequencyPayload();
    const index = payload.item_plans.findIndex((p) => p.item_id === separator.id);
    payload.item_plans[index] = {
      ...payload.item_plans[index],
      displayed_option_ids: ['A', 'B', 'C', 'D'],
    };
    payload.answers = payload.answers.map((answer) =>
      answer.item_id === separator.id
        ? { ...answer, selected_option_id: 'A' }
        : answer,
    );
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_DISPLAYED_OPTIONS',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('rejects a core item rewritten as opt_a/opt_b/opt_c/opt_d', async () => {
    const db = new MemoryFirestore();
    await seedUser(db);
    const bank = bankFor('frequency', 'en-US');
    const core = findCore(bank);
    const payload = buildFrequencyPayload();
    const index = payload.item_plans.findIndex((p) => p.item_id === core.id);
    payload.item_plans[index] = {
      ...payload.item_plans[index],
      displayed_option_ids: ['opt_a', 'opt_b', 'opt_c', 'opt_d'],
    };
    payload.answers = payload.answers.map((answer) =>
      answer.item_id === core.id
        ? { ...answer, selected_option_id: 'opt_a' }
        : answer,
    );
    await assert.rejects(
      () => handleFinalizeFrequency(request('userA', payload), deps(db)),
      (err) =>
        err instanceof HttpsError &&
        err.code === 'invalid-argument' &&
        err.details &&
        err.details.code === 'INVALID_DISPLAYED_OPTIONS',
    );
    assert.strictEqual(userData(db).assessment_verification_v1, undefined);
  });

  it('index.js exports exactly one europe-west1 finalizeFrequency distinct from V2', () => {
    const index = fs.readFileSync(
      path.join(__dirname, '../index.js'),
      'utf8',
    );
    assert.ok(index.includes('exports.finalizeFrequency = onCall('));
    const start = index.indexOf('exports.finalizeFrequency = onCall(');
    const block = index.slice(start, start + 220);
    assert.ok(block.includes("region: 'europe-west1'"));
    assert.ok(!index.includes('finalizeFrequencyEu'));
    assert.ok(!index.includes('exports.handleFinalizeFrequency'));
    assert.ok(index.includes('exports.finalizeIq = onCall('));
    assert.ok(index.includes('exports.finalizeEq = onCall('));
    assert.ok(index.includes('exports.finalizeFrequencyV2 = onCall('));
    assert.notStrictEqual(
      index.indexOf('exports.finalizeFrequency = onCall('),
      index.indexOf('exports.finalizeFrequencyV2 = onCall('),
    );
    assert.strictEqual(typeof handleFinalizeFrequencyV2, 'function');
  });
});
