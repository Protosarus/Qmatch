'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const catalog = require('../src/frequency_behavior_v2_catalog_v1.generated');
const contract = require('../src/frequency_behavior_v2_contract');
const { composeManifest } = require('../src/frequency_behavior_v2_selector');
const { scoreSession } = require('../src/frequency_behavior_v2_scorer');
const {
  SCHEMA_VERSION,
  CATALOG_VERSION,
  ERROR_CODES,
} = require('../src/frequency_behavior_v2_session_validation');
const {
  canonicalJson,
  sha256Canonical,
} = require('../src/canonical_json_sha256_v1');
const {
  CALLABLE_NAME,
  REGION,
  SOURCE,
  RESULT_SCHEMA_VERSION,
  RESULT_DOC_ID,
  RESULT_STATUS,
  ERROR_SESSION_CONFLICT,
  ERROR_ALREADY_FINALIZED,
  PERSISTED_FORBIDDEN_RESULT_KEYS,
  handleFinalizeFrequencyV2,
  persistDimensions,
  buildIntegrity,
  resultDocPath,
} = require('../src/finalize_frequency_v2_v1');

const FIXTURE_PATH = path.join(
  __dirname,
  '../../test/fixtures/frequency_v2/phase7c_parity_fixtures.json',
);
const TOL = 1e-9;

function loadFixtures() {
  return JSON.parse(fs.readFileSync(FIXTURE_PATH, 'utf8'));
}

function fixtureById(id) {
  const found = loadFixtures().fixtures.find((row) => row.id === id);
  assert.ok(found, `missing fixture ${id}`);
  return found;
}

function payloadFromFixture(fixture, ownerUid = 'userA', overrides = {}) {
  const payload = {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: fixture.session_id,
    owner_uid: ownerUid,
    assessment_type: contract.ASSESSMENT_TYPE,
    bank_version: fixture.bank_version,
    bank_locale: fixture.bank_locale,
    selection_policy_version: contract.SELECTION_POLICY_VERSION,
    selector_version: contract.SELECTOR_VERSION,
    session_seed: fixture.session_seed,
    item_plans: fixture.item_plans.map((plan) => ({
      item_id: plan.item_id,
      presented_option_order: plan.presented_option_order.slice(),
    })),
    answers: fixture.answers.map((answer) => ({
      item_id: answer.item_id,
      selected_option_id: answer.selected_option_id,
    })),
  };
  if (fixture.bank_locale === contract.LOCALE_EN) {
    payload.translation_version = contract.TRANSLATION_VERSION_EN;
  }
  return Object.assign(payload, overrides);
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
    frequency_completed: false,
    frequency_v2_completed: false,
    iq_completed: false,
    eq_completed: false,
    bio: 'hello',
    ...overrides,
  };
}

function v1FrequencyDoc() {
  return {
    schema_version: 'frequency_v1_untouched',
    assessment_type: 'frequency',
    score: 0.1,
  };
}

function canonicalDoc() {
  return {
    schema_version: 'canonical_v1',
    frequency: { social_energy: 0.2 },
  };
}

function publicProfileDoc() {
  return {
    uid: 'userA',
    display_name: 'A',
    discover_eligible: false,
  };
}

async function seedIsolationDocs(db) {
  await db.doc('users/userA').set(baseUser());
  await db.doc('users/userA/assessments/frequency').set(v1FrequencyDoc());
  await db.doc('users/userA/profiles/canonical_v1').set(canonicalDoc());
  await db.doc('public_profiles/userA').set(publicProfileDoc());
}

function resultData(db, uid = 'userA') {
  return db._store.get(resultDocPath(uid));
}

function cloneStored(db, path) {
  const value = db._store.get(path);
  return value === undefined ? undefined : JSON.parse(JSON.stringify(value));
}

function nearEqual(a, b, tol) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return Math.abs(a - b) <= tol;
}

function collectKeys(value, out = new Set()) {
  if (value == null || typeof value !== 'object') return out;
  if (Array.isArray(value)) {
    for (const item of value) collectKeys(item, out);
    return out;
  }
  for (const [key, child] of Object.entries(value)) {
    out.add(key);
    collectKeys(child, out);
  }
  return out;
}

async function expectHttpsError(fn, httpsCode, detailsCode) {
  await assert.rejects(fn, (err) => {
    assert.ok(err instanceof HttpsError, `expected HttpsError, got ${err}`);
    assert.strictEqual(err.code, httpsCode, err.message);
    if (detailsCode) {
      assert.strictEqual(err.details && err.details.code, detailsCode);
    }
    return true;
  });
}

function expectedPersistedDimensions(fixture) {
  return persistDimensions(fixture.expected.dimensions);
}

describe('canonical_json_sha256_v1', () => {
  it('hashes equivalent logical objects identically regardless of key insertion order', () => {
    const a = {
      z: 1,
      nested: { c: [2, { y: 3, x: 4 }], a: 'keep-array-order' },
      b: true,
    };
    const b = {
      b: true,
      nested: { a: 'keep-array-order', c: [2, { x: 4, y: 3 }] },
      z: 1,
    };
    assert.strictEqual(canonicalJson(a), canonicalJson(b));
    assert.strictEqual(sha256Canonical(a), sha256Canonical(b));
  });

  it('preserves array order in the canonical form', () => {
    assert.notStrictEqual(
      sha256Canonical({ items: ['a', 'b'] }),
      sha256Canonical({ items: ['b', 'a'] }),
    );
  });
});

describe('finalizeFrequencyV2 callable', () => {
  it('callable name and region are frozen', () => {
    assert.strictEqual(CALLABLE_NAME, 'finalizeFrequencyV2');
    assert.strictEqual(REGION, 'europe-west1');
    assert.strictEqual(SOURCE, 'admin_finalize_frequency_v2_v1');
    assert.strictEqual(RESULT_DOC_ID, 'frequency_v2');
    assert.strictEqual(RESULT_SCHEMA_VERSION, 'qmatch_frequency_behavior_v2_result_v1');
  });

  it('index.js exports exactly one europe-west1 finalizeFrequencyV2', () => {
    const index = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');
    assert.ok(index.includes('exports.finalizeFrequencyV2 = onCall('));
    const start = index.indexOf('exports.finalizeFrequencyV2 = onCall(');
    const block = index.slice(start, start + 240);
    assert.ok(block.includes("region: 'europe-west1'"));
    assert.ok(index.includes('exports.finalizeFrequency = onCall('));
    assert.notStrictEqual(
      index.indexOf('exports.finalizeFrequency = onCall('),
      index.indexOf('exports.finalizeFrequencyV2 = onCall('),
    );
    assert.ok(!index.includes('exports.handleFinalizeFrequencyV2'));
  });

  it('unauthenticated is denied', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request(null, payload), deps(db)),
      'unauthenticated',
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('owner_uid != auth.uid is denied', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'), 'userB');
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'permission-denied',
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('valid TR session finalizes to assessments/frequency_v2', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const fixture = fixtureById('tr_standard_seed');
    const payload = payloadFromFixture(fixture);
    const out = await handleFinalizeFrequencyV2(
      request('userA', payload),
      deps(db),
    );
    assert.deepStrictEqual(out, {
      ok: true,
      assessment_type: 'frequency_v2',
      status: 'completed',
      session_id: fixture.session_id,
      idempotent: false,
    });
    const stored = resultData(db);
    assert.ok(stored);
    assert.strictEqual(stored.schema_version, RESULT_SCHEMA_VERSION);
    assert.strictEqual(stored.assessment_type, 'frequency_v2');
    assert.strictEqual(stored.status, RESULT_STATUS);
    assert.strictEqual(stored.source, SOURCE);
    assert.strictEqual(stored.session_id, fixture.session_id);
    assert.strictEqual(stored.session_proof.item_count, 50);
    assert.strictEqual(stored.session_proof.item_plans.length, 50);
    assert.strictEqual(stored.responses.length, 50);
    assert.strictEqual(stored.dimensions.length, 12);
    assert.deepStrictEqual(
      stored.dimensions.map((d) => d.dimension_id),
      contract.CANONICAL_DIMENSIONS,
    );
    assert.strictEqual(
      stored.version_pins.finalize_catalog_version,
      contract.CATALOG_VERSION,
    );
    assert.strictEqual(stored.version_pins.bank_locale, 'tr-TR');
    assert.strictEqual(stored.version_pins.translation_version, undefined);
    assert.strictEqual(stored.verified_at, 'TS1');
    assert.strictEqual(stored.created_at, 'TS1');
    assert.strictEqual(stored.updated_at, 'TS1');
    assert.ok(db._store.has('users/userA/assessments/frequency_v2'));
  });

  it('valid EN session finalizes with translation_version pin', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const fixture = fixtureById('en_locale_session');
    const payload = payloadFromFixture(fixture);
    const out = await handleFinalizeFrequencyV2(
      request('userA', payload),
      deps(db),
    );
    assert.strictEqual(out.ok, true);
    assert.strictEqual(out.idempotent, false);
    const stored = resultData(db);
    assert.strictEqual(stored.version_pins.bank_locale, 'en-US');
    assert.strictEqual(
      stored.version_pins.translation_version,
      contract.TRANSLATION_VERSION_EN,
    );
    assert.strictEqual(stored.version_pins.bank_version, fixture.bank_version);
    assert.strictEqual(stored.session_proof.item_count, 50);
  });

  it('persisted scores match Phase 7C fixture results including confidence', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const fixture = fixtureById('tr_standard_seed');
    await handleFinalizeFrequencyV2(
      request('userA', payloadFromFixture(fixture)),
      deps(db),
    );
    const stored = resultData(db);
    const expectedDims = expectedPersistedDimensions(fixture);
    assert.strictEqual(stored.dimensions.length, expectedDims.length);
    for (let i = 0; i < expectedDims.length; i++) {
      const actual = stored.dimensions[i];
      const expected = expectedDims[i];
      assert.strictEqual(actual.dimension_id, expected.dimension_id);
      assert.ok(
        nearEqual(actual.normalized_behavior, expected.normalized_behavior, TOL),
        actual.dimension_id,
      );
      assert.ok(
        nearEqual(
          actual.provisional_confidence,
          expected.provisional_confidence,
          TOL,
        ),
      );
      assert.deepStrictEqual(actual.confidence_flags, expected.confidence_flags);
      assert.ok(
        nearEqual(
          actual.cross_context_consistency,
          expected.cross_context_consistency,
          TOL,
        ),
      );
      assert.ok(
        nearEqual(
          actual.cross_context_coverage,
          expected.cross_context_coverage,
          TOL,
        ),
      );
      assert.ok(
        nearEqual(
          actual.confidence_completeness,
          expected.confidence_completeness,
          TOL,
        ),
      );
      assert.ok(
        nearEqual(
          actual.primary_signal_coverage,
          expected.primary_signal_coverage,
          TOL,
        ),
      );
      assert.strictEqual(actual.raw_sum, undefined);
      assert.strictEqual(actual.capacity, undefined);
    }
    assert.strictEqual(
      stored.summary.measured_dimension_count,
      fixture.expected.summary.measured_dimension_count,
    );
    assert.strictEqual(
      stored.summary.dimensions_with_behavior,
      fixture.expected.summary.dimensions_with_behavior,
    );
    assert.ok(
      nearEqual(
        stored.summary.global_support,
        fixture.expected.summary.global_support,
        TOL,
      ),
    );
  });

  it('rejects forbidden dimension score authority', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.dimensions = [{ dimension_id: 'contact_need', normalized_behavior: 1 }];
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects forbidden confidence authority', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.provisional_confidence = 0.99;
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects forbidden completion flags', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.frequency_v2_completed = true;
    payload.discover_eligible = true;
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects selector/session tampering', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    const tmp = payload.item_plans[0].item_id;
    payload.item_plans[0].item_id = payload.item_plans[1].item_id;
    payload.item_plans[1].item_id = tmp;
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects option tampering', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.item_plans[0].presented_option_order = payload.item_plans[0]
      .presented_option_order.slice()
      .reverse();
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH,
    );
    payload.item_plans[0].presented_option_order = fixtureById(
      'tr_standard_seed',
    ).item_plans[0].presented_option_order.slice();
    payload.answers[0].selected_option_id = 'not_an_option';
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.INVALID_SELECTED_OPTION,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects DROP questions through the Phase 7C validator', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.item_plans[0].item_id = 'frequency_v2_q0003';
    payload.item_plans[0].presented_option_order = [
      'frequency_v2_q0003_a',
      'frequency_v2_q0003_b',
      'frequency_v2_q0003_c',
      'frequency_v2_q0003_d',
    ];
    payload.answers[0].item_id = 'frequency_v2_q0003';
    payload.answers[0].selected_option_id = 'frequency_v2_q0003_a';
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.DROP_ITEM_IN_SESSION,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('rejects version spoof', async () => {
    const db = new MemoryFirestore();
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    payload.catalog_version = 'assessment_finalize_catalog_v1';
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.UNSUPPORTED_CATALOG_VERSION,
    );
    payload.catalog_version = CATALOG_VERSION;
    payload.selector_version = 'forged_selector';
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      'invalid-argument',
      ERROR_CODES.UNSUPPORTED_SELECTOR_VERSION,
    );
    assert.strictEqual(resultData(db), undefined);
  });

  it('same session retry is idempotent and preserves original timestamp', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    const first = await handleFinalizeFrequencyV2(
      request('userA', payload),
      deps(db),
    );
    const afterFirst = resultData(db);
    const second = await handleFinalizeFrequencyV2(
      request('userA', payload),
      deps(db, { timestampStart: 10 }),
    );
    assert.strictEqual(first.idempotent, false);
    assert.strictEqual(second.idempotent, true);
    const afterSecond = resultData(db);
    assert.strictEqual(afterSecond.verified_at, afterFirst.verified_at);
    assert.strictEqual(afterSecond.created_at, afterFirst.created_at);
    assert.strictEqual(afterSecond.updated_at, afterFirst.updated_at);
    assert.strictEqual(afterSecond.verified_at, 'TS1');
    assert.deepStrictEqual(afterSecond.integrity, afterFirst.integrity);
  });

  it('same session_id with changed responses is rejected', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const fixture = fixtureById('tr_standard_seed');
    const firstPayload = payloadFromFixture(fixture);
    await handleFinalizeFrequencyV2(request('userA', firstPayload), deps(db));
    const original = cloneStored(db, resultDocPath('userA'));
    const changed = payloadFromFixture(fixture);
    const order = changed.item_plans[0].presented_option_order;
    const current = changed.answers[0].selected_option_id;
    changed.answers[0].selected_option_id = order.find((id) => id !== current);
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', changed), deps(db)),
      'failed-precondition',
      ERROR_SESSION_CONFLICT,
    );
    assert.deepStrictEqual(resultData(db), original);
  });

  it('different session_id after completion is rejected', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    await handleFinalizeFrequencyV2(
      request('userA', payloadFromFixture(fixtureById('tr_standard_seed'))),
      deps(db),
    );
    const original = cloneStored(db, resultDocPath('userA'));
    const other = payloadFromFixture(fixtureById('tr_alternate_seed'));
    await expectHttpsError(
      () => handleFinalizeFrequencyV2(request('userA', other), deps(db)),
      'failed-precondition',
      ERROR_ALREADY_FINALIZED,
    );
    assert.deepStrictEqual(resultData(db), original);
  });

  it('does not mutate user, V1 frequency, canonical_v1, or public_profiles', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const userBefore = cloneStored(db, 'users/userA');
    const v1Before = cloneStored(db, 'users/userA/assessments/frequency');
    const canonicalBefore = cloneStored(db, 'users/userA/profiles/canonical_v1');
    const publicBefore = cloneStored(db, 'public_profiles/userA');
    await handleFinalizeFrequencyV2(
      request('userA', payloadFromFixture(fixtureById('tr_standard_seed'))),
      deps(db),
    );
    assert.deepStrictEqual(cloneStored(db, 'users/userA'), userBefore);
    assert.deepStrictEqual(
      cloneStored(db, 'users/userA/assessments/frequency'),
      v1Before,
    );
    assert.deepStrictEqual(
      cloneStored(db, 'users/userA/profiles/canonical_v1'),
      canonicalBefore,
    );
    assert.deepStrictEqual(
      cloneStored(db, 'public_profiles/userA'),
      publicBefore,
    );
    const user = cloneStored(db, 'users/userA');
    assert.strictEqual(user.frequency_completed, false);
    assert.strictEqual(user.frequency_v2_completed, false);
    assert.strictEqual(user.test_completed, false);
    assert.strictEqual(user.assessment_flow_completed, false);
    assert.strictEqual(user.discover_eligible, false);
    assert.strictEqual(user.assessment_verification_v1, undefined);
  });

  it('does not persist pair-fit, 24D, density, telemetry, or debug intermediates', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    await handleFinalizeFrequencyV2(
      request('userA', payloadFromFixture(fixtureById('tr_standard_seed'))),
      deps(db),
    );
    const keys = collectKeys(resultData(db));
    for (const forbidden of PERSISTED_FORBIDDEN_RESULT_KEYS) {
      assert.ok(!keys.has(forbidden), `persisted forbidden key ${forbidden}`);
    }
    assert.ok(!keys.has('mean_diagnostic_value'));
    assert.ok(!keys.has('presentation_pressure'));
    assert.ok(!keys.has('base_confidence'));
    assert.ok(!keys.has('question_ids'));
  });

  it('integrity hashes are deterministic and result_sha256 excludes timestamps/self', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    await handleFinalizeFrequencyV2(request('userA', payload), deps(db));
    const stored = resultData(db);
    const rebuilt = buildIntegrity({
      versionPins: stored.version_pins,
      sessionProof: stored.session_proof,
      responses: stored.responses,
      dimensions: stored.dimensions,
      summary: stored.summary,
    });
    assert.deepStrictEqual(stored.integrity, rebuilt);

    const reorderedPins = {
      scorer_version: stored.version_pins.scorer_version,
      bank_version: stored.version_pins.bank_version,
      finalize_catalog_version: stored.version_pins.finalize_catalog_version,
      bank_locale: stored.version_pins.bank_locale,
      selection_policy_version: stored.version_pins.selection_policy_version,
      selector_version: stored.version_pins.selector_version,
      scoring_policy_version: stored.version_pins.scoring_policy_version,
      confidence_model_version: stored.version_pins.confidence_model_version,
      session_manifest_schema_version:
        stored.version_pins.session_manifest_schema_version,
    };
    const reorderedSummary = {
      global_support: stored.summary.global_support,
      measured_dimension_count: stored.summary.measured_dimension_count,
      dimensions_with_behavior: stored.summary.dimensions_with_behavior,
    };
    assert.strictEqual(
      stored.integrity.result_sha256,
      sha256Canonical({
        version_pins: reorderedPins,
        dimensions: stored.dimensions,
        summary: reorderedSummary,
      }),
    );

    const withTimestamps = {
      version_pins: stored.version_pins,
      dimensions: stored.dimensions,
      summary: stored.summary,
      verified_at: stored.verified_at,
      created_at: stored.created_at,
      updated_at: stored.updated_at,
      result_sha256: stored.integrity.result_sha256,
    };
    assert.notStrictEqual(
      stored.integrity.result_sha256,
      sha256Canonical(withTimestamps),
    );
    assert.notStrictEqual(
      stored.integrity.session_proof_sha256,
      sha256Canonical({
        ...stored.session_proof,
        verified_at: stored.verified_at,
      }),
    );
  });

  it('concurrent identical finalize attempts do not create competing results', async () => {
    const db = new MemoryFirestore();
    await seedIsolationDocs(db);
    const payload = payloadFromFixture(fixtureById('tr_standard_seed'));
    const [a, b] = await Promise.all([
      handleFinalizeFrequencyV2(request('userA', payload), deps(db)),
      handleFinalizeFrequencyV2(
        request('userA', payload),
        deps(db, { timestampStart: 10 }),
      ),
    ]);
    const flags = [a.idempotent, b.idempotent].sort();
    assert.deepStrictEqual(flags, [false, true]);
    assert.strictEqual(a.ok, true);
    assert.strictEqual(b.ok, true);
    const stored = resultData(db);
    assert.strictEqual(stored.session_id, payload.session_id);
    assert.ok(stored.verified_at === 'TS1' || stored.verified_at === 'TS11');
  });

  it('runtime_selectable remains false on trusted catalog', () => {
    assert.strictEqual(catalog.runtime_selectable, false);
    assert.strictEqual(
      catalog.banks[contract.POOL_VERSION_TR].runtime_selectable,
      false,
    );
    assert.strictEqual(
      catalog.banks[contract.POOL_VERSION_EN].runtime_selectable,
      false,
    );
  });

  it('server score equals independent Phase 7C scorer output', () => {
    const fixture = fixtureById('tr_mixed_responses');
    const bank = catalog.banks[fixture.bank_version];
    const manifest = composeManifest({
      bank,
      sessionSeed: fixture.session_seed,
      sessionId: fixture.session_id,
    });
    const scored = scoreSession({
      bank,
      manifest,
      responses: fixture.answers.map((answer) => ({
        item_id: answer.item_id,
        selected_option_id: answer.selected_option_id,
      })),
    });
    assert.strictEqual(scored.ok, true);
    const expected = persistDimensions(fixture.expected.dimensions);
    const actual = persistDimensions(scored.dimensions);
    assert.strictEqual(actual.length, 12);
    for (let i = 0; i < 12; i++) {
      assert.strictEqual(actual[i].dimension_id, expected[i].dimension_id);
      assert.ok(
        nearEqual(
          actual[i].normalized_behavior,
          expected[i].normalized_behavior,
          TOL,
        ),
      );
    }
  });
});
