'use strict';

const assert = require('assert');
const { MemoryFirestore } = require('./memory_firestore');
const contract = require('../src/frequency_behavior_v2_contract');
const {
  handleRecomputeDiscoverEligibleOnUserWrite,
  handleRecomputeDiscoverEligibleOnFrequencyV2Write,
  frequencyV2Path,
} = require('../src/recompute_discover_eligible_authority');

function trustedBattery() {
  return {
    schema_version: 'assessment_verification_v1',
    flow: 'complete',
    grant_reason: 'admin_finalize_frequency_v1',
    iq: { status: 'verified' },
    eq: { status: 'verified' },
    frequency: { status: 'verified' },
  };
}

function iqEqOnly() {
  return {
    schema_version: 'assessment_verification_v1',
    iq: { status: 'verified' },
    eq: { status: 'verified' },
    frequency: { status: 'none' },
  };
}

function grandfatherGrant() {
  return {
    schema_version: 'assessment_verification_v1',
    flow: 'pre_c2_preserved',
    grant_reason: 'pre_trust_migration_preserved',
  };
}

function userDoc(overrides = {}) {
  return {
    active: true,
    profile_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    account_deletion_requested: false,
    discover_eligible: false,
    assessment_verification_v1: trustedBattery(),
    ...overrides,
  };
}

function validV2Doc(overrides = {}) {
  return {
    schema_version: contract.RESULT_SCHEMA_VERSION,
    assessment_type: contract.ASSESSMENT_TYPE,
    status: contract.RESULT_STATUS,
    source: contract.RESULT_SOURCE,
    session_id: 'frequency_v2_sess_secret',
    dimensions: contract.CANONICAL_DIMENSIONS.map((id) => ({
      dimension_id: id,
      normalized_behavior: 0.2,
      provisional_confidence: 1,
      confidence_completeness: 1,
    })),
    ...overrides,
  };
}

function snap(path, data) {
  return {
    exists: data != null,
    data: () => data,
    ref: { path },
  };
}

function userEvent(uid, { before, after }) {
  return {
    params: { uid },
    data: {
      before: snap(`users/${uid}`, before),
      after: snap(`users/${uid}`, after),
    },
  };
}

function v2Event(uid, { before, after }) {
  return {
    params: { uid },
    data: {
      before: snap(frequencyV2Path(uid), before),
      after: snap(frequencyV2Path(uid), after),
    },
  };
}

describe('recompute discover eligible authority (V2-aware, source-only)', () => {
  it('V1 user write still grants without reading Frequency V2', async () => {
    const db = new MemoryFirestore();
    const after = userDoc({ discover_eligible: false });
    await db.doc('users/u1').set(after);
    const res = await handleRecomputeDiscoverEligibleOnUserWrite(
      userEvent('u1', { before: null, after }),
      { db },
    );
    assert.strictEqual(res.discover_eligible, true);
    assert.strictEqual(
      (await db.doc('users/u1').get()).data().discover_eligible,
      true,
    );
    assert.strictEqual((await db.doc(frequencyV2Path('u1')).get()).exists, false);
  });

  it('photo change for V2-only user Admin-reads V2 and keeps eligibility', async () => {
    const db = new MemoryFirestore();
    const after = userDoc({
      assessment_verification_v1: iqEqOnly(),
      discover_eligible: true,
      profile_photo_url: 'https://example.com/new.jpg',
    });
    await db.doc('users/u2').set(after);
    await db.doc(frequencyV2Path('u2')).set(validV2Doc());
    const res = await handleRecomputeDiscoverEligibleOnUserWrite(
      userEvent('u2', {
        before: userDoc({
          assessment_verification_v1: iqEqOnly(),
          discover_eligible: true,
        }),
        after,
      }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual(
      (await db.doc('users/u2').get()).data().discover_eligible,
      true,
    );
  });

  it('IQ+EQ user write without V2 does not grant', async () => {
    const db = new MemoryFirestore();
    const after = userDoc({
      assessment_verification_v1: iqEqOnly(),
      discover_eligible: false,
    });
    await db.doc('users/u3').set(after);
    const res = await handleRecomputeDiscoverEligibleOnUserWrite(
      userEvent('u3', { before: null, after }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual(
      (await db.doc('users/u3').get()).data().discover_eligible,
      false,
    );
  });

  it('grandfather user write does not require V2', async () => {
    const db = new MemoryFirestore();
    const after = userDoc({
      assessment_verification_v1: grandfatherGrant(),
      discover_eligible: false,
    });
    await db.doc('users/u4').set(after);
    const res = await handleRecomputeDiscoverEligibleOnUserWrite(
      userEvent('u4', { before: null, after }),
      { db },
    );
    assert.strictEqual(res.discover_eligible, true);
  });

  it('V2 result write grants IQ+EQ user and writes only discover_eligible', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u5').set(
      userDoc({
        assessment_verification_v1: iqEqOnly(),
        discover_eligible: false,
        bio: 'keep-me',
      }),
    );
    const afterV2 = validV2Doc();
    await db.doc(frequencyV2Path('u5')).set(afterV2);
    const res = await handleRecomputeDiscoverEligibleOnFrequencyV2Write(
      v2Event('u5', { before: null, after: afterV2 }),
      { db },
    );
    assert.strictEqual(res.discover_eligible, true);
    const user = (await db.doc('users/u5').get()).data();
    assert.strictEqual(user.discover_eligible, true);
    assert.strictEqual(user.bio, 'keep-me');
    assert.deepStrictEqual(user.assessment_verification_v1.frequency, {
      status: 'none',
    });
    assert.strictEqual(user.frequency_completed, undefined);
    const blob = JSON.stringify(user);
    assert.strictEqual(blob.includes('frequency_v2_sess_secret'), false);
  });

  it('malformed V2 result write does not grant IQ+EQ user', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u6').set(
      userDoc({
        assessment_verification_v1: iqEqOnly(),
        discover_eligible: false,
      }),
    );
    const bad = validV2Doc({ source: 'client_write' });
    await db.doc(frequencyV2Path('u6')).set(bad);
    const res = await handleRecomputeDiscoverEligibleOnFrequencyV2Write(
      v2Event('u6', { before: null, after: bad }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual(
      (await db.doc('users/u6').get()).data().discover_eligible,
      false,
    );
  });

  it('malformed V2 result does not revoke grandfather eligibility', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u7').set(
      userDoc({
        assessment_verification_v1: grandfatherGrant(),
        discover_eligible: true,
      }),
    );
    const bad = validV2Doc({ source: 'client_write' });
    const res = await handleRecomputeDiscoverEligibleOnFrequencyV2Write(
      v2Event('u7', { before: null, after: bad }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual(
      (await db.doc('users/u7').get()).data().discover_eligible,
      true,
    );
  });

  it('unrelated user field change does not rewrite eligibility', async () => {
    const db = new MemoryFirestore();
    const after = {
      ...userDoc({
        assessment_verification_v1: iqEqOnly(),
        discover_eligible: true,
      }),
      bio: 'changed',
    };
    await db.doc('users/u_bio').set(after);
    await db.doc(frequencyV2Path('u_bio')).set(validV2Doc());
    const res = await handleRecomputeDiscoverEligibleOnUserWrite(
      userEvent('u_bio', {
        before: userDoc({
          assessment_verification_v1: iqEqOnly(),
          discover_eligible: true,
        }),
        after,
      }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual(
      (await db.doc('users/u_bio').get()).data().discover_eligible,
      true,
    );
  });

  it('no-op V2 write does not churn updated_at or rewrite eligibility', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u8').set(
      userDoc({
        assessment_verification_v1: iqEqOnly(),
        discover_eligible: true,
        updated_at: 123,
      }),
    );
    const doc = validV2Doc();
    const res = await handleRecomputeDiscoverEligibleOnFrequencyV2Write(
      v2Event('u8', { before: doc, after: doc }),
      { db },
    );
    assert.strictEqual(res, null);
    assert.strictEqual((await db.doc('users/u8').get()).data().updated_at, 123);
  });
});
