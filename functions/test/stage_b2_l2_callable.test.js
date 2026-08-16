'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleCompareStageB2Structural,
  PUBLIC_PAIR_KEYS,
  MAX_CANDIDATE_UIDS,
} = require('../src/stage_b2_l2_callable');
const {
  DIMENSION_IDS,
  IQ_IDS,
  EQ_IDS,
} = require('../src/canonical_20d_group_normalized_shadow');

function canonicalDoc(scores) {
  return {
    measured_dimensions: Object.entries(scores).map(([id, value]) => ({
      dimension_id: id,
      module: IQ_IDS.includes(id)
        ? 'iq'
        : EQ_IDS.includes(id)
          ? 'eq'
          : 'frequency',
      measurement_state: 'measured',
      value,
      reliability_status: 'not_calibrated',
    })),
    source_session_id: 'sess-secret',
    owner_uid: 'should-not-leak',
  };
}

function fill(ids, v) {
  const out = {};
  for (const id of ids) out[id] = v;
  return out;
}

function request(uid, candidateUids) {
  return {
    auth: uid ? { uid } : null,
    data: { candidate_uids: candidateUids },
  };
}

describe('compareStageB2Structural callable', () => {
  it('unauthenticated throws', async () => {
    await assert.rejects(
      () => handleCompareStageB2Structural(request(null, ['c1']), { db: new MemoryFirestore() }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('rejects non-array candidate_uids', async () => {
    await assert.rejects(
      () =>
        handleCompareStageB2Structural(
          { auth: { uid: 'v' }, data: { candidate_uids: 'c1' } },
          { db: new MemoryFirestore() },
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });

  it('Admin-reads canonical_v1 and returns public pair fields only', async () => {
    const db = new MemoryFirestore();
    const viewer = { ...fill(DIMENSION_IDS, 0.45) };
    const near = { ...fill(DIMENSION_IDS, 0.45) };
    const far = { ...fill(DIMENSION_IDS, 0.95) };
    await db.doc('users/viewer/profiles/canonical_v1').set(canonicalDoc(viewer));
    await db.doc('users/near/profiles/canonical_v1').set(canonicalDoc(near));
    await db.doc('users/far/profiles/canonical_v1').set(canonicalDoc(far));

    const res = await handleCompareStageB2Structural(
      request('viewer', ['near', 'far']),
      { db },
    );
    assert.strictEqual(res.pairs.length, 2);
    assert.strictEqual(res.pairs[0].available, true);
    assert.strictEqual(res.pairs[0].structural_distance, 0.0);
    assert.strictEqual(res.pairs[0].total_coverage, 1.0);
    assert.strictEqual(res.pairs[0].comparable_dimensions, 20);
    assert.strictEqual(res.pairs[1].available, true);
    assert.ok(res.pairs[1].structural_distance > 0);

    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('logical_reasoning'), false);
    assert.strictEqual(blob.includes('measured_dimensions'), false);
    assert.strictEqual(blob.includes('sess-secret'), false);
    assert.strictEqual(blob.includes('source_session_id'), false);
    assert.strictEqual(blob.includes('should-not-leak'), false);
    for (const pair of res.pairs) {
      for (const key of Object.keys(pair)) {
        assert.ok(PUBLIC_PAIR_KEYS.includes(key), key);
      }
    }
  });

  it('missing candidate canonical_v1 stays unavailable, never 0.5', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/viewer/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.5)));
    const res = await handleCompareStageB2Structural(
      request('viewer', ['missing']),
      { db },
    );
    assert.strictEqual(res.pairs[0].available, false);
    assert.strictEqual(res.pairs[0].structural_distance, undefined);
    assert.strictEqual(
      res.pairs[0].unavailable_reason,
      'candidate_canonical_profile_missing',
    );
    assert.strictEqual(res.pairs[0].total_coverage, 0.0);
  });

  it('preserves L1 candidate order', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/viewer/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/b/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.9)));
    await db
      .doc('users/a/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    const res = await handleCompareStageB2Structural(
      request('viewer', ['b', 'a']),
      { db },
    );
    assert.ok(res.pairs[0].structural_distance > res.pairs[1].structural_distance);
    assert.strictEqual(res.pairs[1].structural_distance, 0.0);
  });

  it('does not accept oversized batches', async () => {
    const tooMany = Array.from({ length: MAX_CANDIDATE_UIDS + 1 }, (_, i) => `u${i}`);
    await assert.rejects(
      () =>
        handleCompareStageB2Structural(request('viewer', tooMany), {
          db: new MemoryFirestore(),
        }),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });
});
