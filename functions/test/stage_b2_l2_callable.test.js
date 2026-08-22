'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  handleCompareStageB2Structural,
  PUBLIC_PAIR_KEYS,
  MAX_CANDIDATE_UIDS,
  L2_TIMING_LOG_PREFIX,
  L2_TIMING_KEYS,
  GET_ALL_CHUNK_SIZE,
  toPublicPair,
  publicUnavailable,
} = require('../src/stage_b2_l2_callable');
const {
  DIMENSION_IDS,
  IQ_IDS,
  EQ_IDS,
  compareMeasuredPresence,
  measuredScoresFromCanonicalProfile,
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
    assert.deepStrictEqual(res.candidate_uids, ['near', 'far']);
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
    assert.strictEqual(blob.includes('omitted_uids'), false);
    assert.strictEqual(blob.includes('reverse_block'), false);
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

  it('omits reverse-blocked candidates without block fields or reasons', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/viewer/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/ok/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/blocked_me/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db.doc('users/blocked_me/blocks/viewer').set({
      blocked_uid: 'viewer',
      reason: 'secret-block-reason',
    });

    const res = await handleCompareStageB2Structural(
      request('viewer', ['blocked_me', 'ok']),
      { db },
    );
    assert.deepStrictEqual(res.candidate_uids, ['ok']);
    assert.strictEqual(res.pairs.length, 1);
    assert.strictEqual(res.pairs[0].available, true);
    assert.strictEqual(res.pairs[0].structural_distance, 0.0);

    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('blocked_me'), false);
    assert.strictEqual(blob.includes('secret-block-reason'), false);
    assert.strictEqual(blob.includes('omitted_uids'), false);
    assert.strictEqual(blob.includes('reverse_block'), false);
    assert.strictEqual(blob.includes('reason'), false);
    for (const pair of res.pairs) {
      for (const key of Object.keys(pair)) {
        assert.ok(PUBLIC_PAIR_KEYS.includes(key), key);
      }
    }
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

  it('Admin reverse-block check uses exists only — never block data()', () => {
    const fs = require('fs');
    const path = require('path');
    const src = fs.readFileSync(
      path.resolve(__dirname, '../src/stage_b2_l2_callable.js'),
      'utf8',
    );
    assert.ok(src.includes('reverseBlockSnaps[i].exists'));
    assert.strictEqual(src.includes('reverseBlockSnaps[i].data'), false);
    assert.strictEqual(src.includes('omitted_uids'), false);
  });

  it('keeps minInstances 1 on compareStageB2Structural only', () => {
    const fs = require('fs');
    const path = require('path');
    const index = fs.readFileSync(
      path.resolve(__dirname, '../index.js'),
      'utf8',
    );
    const start = index.indexOf('exports.compareStageB2Structural = onCall(');
    const end = index.indexOf('exports.handleCompareStageB2Structural');
    assert.ok(start >= 0 && end > start);
    const block = index.slice(start, end);
    assert.ok(block.includes("region: 'us-central1'"));
    assert.ok(block.includes('minInstances: 1'));
    assert.strictEqual(block.includes('memory'), false);
    assert.strictEqual(block.includes('cpu'), false);
    assert.strictEqual(block.includes('europe-west1'), false);

    function assertNoMinInstances(exportName) {
      const idx = index.indexOf(`exports.${exportName} = onCall(`);
      assert.ok(idx >= 0, exportName);
      const snippet = index.slice(idx, idx + 280);
      assert.strictEqual(
        snippet.includes('minInstances'),
        false,
        exportName,
      );
    }
    assertNoMinInstances('getSuperResonanceAvailability');
    assertNoMinInstances('listWhoLikedYou');
    assertNoMinInstances('listWhoLikedYouEu');
    assertNoMinInstances('listSuperResonanceInbox');
    assertNoMinInstances('listSuperResonanceInboxEu');
    assertNoMinInstances('likeAndMaybeCreateMatch');
    assertNoMinInstances('sendSuperResonance');
  });

  it('Alignment Signals EU callables reuse US handlers in europe-west1', () => {
    const fs = require('fs');
    const path = require('path');
    const index = fs.readFileSync(
      path.resolve(__dirname, '../index.js'),
      'utf8',
    );

    function exportBlock(exportName, nextExport) {
      const start = index.indexOf(`exports.${exportName} = onCall(`);
      assert.ok(start >= 0, exportName);
      const end = nextExport
        ? index.indexOf(`exports.${nextExport}`, start + 1)
        : index.length;
      assert.ok(end > start, `${exportName} end`);
      return index.slice(start, end);
    }

    const whoUs = exportBlock('listWhoLikedYou', 'listWhoLikedYouEu');
    const whoEu = exportBlock('listWhoLikedYouEu', 'handleListWhoLikedYou');
    assert.ok(whoUs.includes("region: 'us-central1'"));
    assert.ok(
      whoUs.includes('listWhoLikedYou.handleListWhoLikedYou(request)'),
    );
    assert.strictEqual(whoUs.includes('europe-west1'), false);
    assert.ok(whoEu.includes("region: 'europe-west1'"));
    assert.ok(
      whoEu.includes('listWhoLikedYou.handleListWhoLikedYou(request)'),
    );
    assert.strictEqual(whoEu.includes('us-central1'), false);
    assert.strictEqual(whoEu.includes('timingCallable'), false);

    const inboxUs = exportBlock(
      'listSuperResonanceInbox',
      'listSuperResonanceInboxEu',
    );
    const inboxEu = exportBlock(
      'listSuperResonanceInboxEu',
      'handleListSuperResonanceInbox',
    );
    assert.ok(inboxUs.includes("region: 'us-central1'"));
    assert.ok(
      inboxUs.includes(
        'listSuperResonanceInbox.handleListSuperResonanceInbox(request)',
      ),
    );
    assert.strictEqual(inboxUs.includes('europe-west1'), false);
    assert.ok(inboxEu.includes("region: 'europe-west1'"));
    assert.ok(
      inboxEu.includes(
        'listSuperResonanceInbox.handleListSuperResonanceInbox(request)',
      ),
    );
    assert.strictEqual(inboxEu.includes('us-central1'), false);
    assert.strictEqual(inboxEu.includes('timingCallable'), false);
  });

  it('EU A/B callable reuses the same handler in europe-west1', () => {
    const fs = require('fs');
    const path = require('path');
    const index = fs.readFileSync(
      path.resolve(__dirname, '../index.js'),
      'utf8',
    );
    const usStart = index.indexOf('exports.compareStageB2Structural = onCall(');
    const usEnd = index.indexOf('exports.handleCompareStageB2Structural');
    const euStart = index.indexOf('exports.compareStageB2StructuralEu = onCall(');
    const euEnd = index.indexOf(
      'exports.compareMeasuredPresenceGroupNormalized',
    );
    assert.ok(usStart >= 0 && usEnd > usStart);
    assert.ok(euStart > usEnd);
    assert.ok(euEnd > euStart);

    const usBlock = index.slice(usStart, usEnd);
    const euBlock = index.slice(euStart, euEnd);
    assert.ok(usBlock.includes("region: 'us-central1'"));
    assert.ok(usBlock.includes('minInstances: 1'));
    assert.ok(
      usBlock.includes('stageB2L2.handleCompareStageB2Structural(request)'),
    );
    assert.ok(euBlock.includes("region: 'europe-west1'"));
    assert.ok(euBlock.includes('minInstances: 1'));
    assert.ok(
      euBlock.includes('stageB2L2.handleCompareStageB2Structural(request)'),
    );
    assert.strictEqual(euBlock.includes('us-central1'), false);
    assert.strictEqual(
      index.includes('handleCompareStageB2StructuralEu'),
      false,
    );
  });

  it('server timings do not change public output or leak private data', async () => {
    const db = new MemoryFirestore();
    const viewer = { ...fill(DIMENSION_IDS, 0.45) };
    const near = { ...fill(DIMENSION_IDS, 0.45) };
    const far = { ...fill(DIMENSION_IDS, 0.95) };
    await db.doc('users/viewer/profiles/canonical_v1').set(canonicalDoc(viewer));
    await db.doc('users/near/profiles/canonical_v1').set(canonicalDoc(near));
    await db.doc('users/far/profiles/canonical_v1').set(canonicalDoc(far));

    const lines = [];
    const res = await handleCompareStageB2Structural(
      request('viewer', ['near', 'far']),
      { db, log: (line) => lines.push(String(line)) },
    );

    assert.deepStrictEqual(Object.keys(res).sort(), ['candidate_uids', 'pairs']);
    assert.deepStrictEqual(res.candidate_uids, ['near', 'far']);
    assert.strictEqual(res.pairs.length, 2);
    assert.strictEqual(res.pairs[0].available, true);
    assert.strictEqual(res.pairs[0].structural_distance, 0.0);
    assert.strictEqual(res.pairs[1].available, true);
    for (const pair of res.pairs) {
      for (const key of Object.keys(pair)) {
        assert.ok(PUBLIC_PAIR_KEYS.includes(key), key);
      }
    }

    assert.strictEqual(lines.length, 1);
    assert.ok(lines[0].startsWith(`${L2_TIMING_LOG_PREFIX} `));
    const payload = JSON.parse(lines[0].slice(L2_TIMING_LOG_PREFIX.length + 1));
    assert.deepStrictEqual(Object.keys(payload).sort(), [...L2_TIMING_KEYS].sort());
    assert.strictEqual(payload.candidate_count, 2);
    assert.ok(payload.total_handler_ms >= 0);
    // Batched IO is one round, reported under candidate_canonical_gets_ms.
    // Do not sum the three GET keys.
    assert.strictEqual(payload.viewer_canonical_get_ms, 0);
    assert.strictEqual(payload.reverse_block_gets_ms, 0);
    assert.ok(payload.candidate_canonical_gets_ms >= 0);

    const blob = `${JSON.stringify(res)}\n${lines.join('\n')}`;
    assert.strictEqual(blob.includes('logical_reasoning'), false);
    assert.strictEqual(blob.includes('measured_dimensions'), false);
    assert.strictEqual(blob.includes('sess-secret'), false);
    assert.strictEqual(blob.includes('source_session_id'), false);
    assert.strictEqual(blob.includes('should-not-leak'), false);
    assert.strictEqual(lines[0].includes('"viewer"'), false);
    assert.strictEqual(lines[0].includes('"near"'), false);
    assert.strictEqual(lines[0].includes('"far"'), false);
    assert.strictEqual(lines[0].includes('canonical_v1'), false);
    assert.strictEqual(payload.handler_ms, undefined);
  });

  it('batches viewer, candidate, and reverse-block reads in one getAll round', () => {
    const fs = require('fs');
    const path = require('path');
    const src = fs.readFileSync(
      path.resolve(__dirname, '../src/stage_b2_l2_callable.js'),
      'utf8',
    );
    assert.ok(src.includes('async function getAllSnaps'));
    assert.ok(src.includes('db.getAll('));
    assert.ok(src.includes('GET_ALL_CHUNK_SIZE'));
    assert.strictEqual(
      src.includes('const candidateSnaps = await Promise.all('),
      false,
    );
    assert.strictEqual(
      src.includes('const reverseBlockSnaps = await Promise.all('),
      false,
    );
    assert.ok(src.includes('reverseBlockSnaps[i].exists'));
    assert.strictEqual(src.includes('reverseBlockSnaps[i].data'), false);
  });

  it('does not add timing fields to the callable payload', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/viewer/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/ok/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    const res = await handleCompareStageB2Structural(
      request('viewer', ['ok']),
      { db, log: () => {} },
    );
    assert.strictEqual(Object.prototype.hasOwnProperty.call(res, 'timings'), false);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(res, 'total_handler_ms'), false);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(res, 'candidate_count'), false);
  });

  it('getAll reads viewer + N canonicals + N reverse blocks in request order', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/viewer/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/near/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    await db
      .doc('users/far/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.9)));
    await db.doc('users/far/blocks/viewer').set({ blocked_uid: 'viewer' });

    const orig = db.getAll.bind(db);
    let calls = 0;
    const seenPaths = [];
    db.getAll = async (...refs) => {
      calls += 1;
      for (const ref of refs) seenPaths.push(ref.path);
      return orig(...refs);
    };

    const res = await handleCompareStageB2Structural(
      request('viewer', ['near', 'far']),
      { db },
    );

    assert.strictEqual(calls, 1);
    assert.deepStrictEqual(seenPaths, [
      'users/viewer/profiles/canonical_v1',
      'users/near/profiles/canonical_v1',
      'users/far/profiles/canonical_v1',
      'users/near/blocks/viewer',
      'users/far/blocks/viewer',
    ]);
    assert.deepStrictEqual(res.candidate_uids, ['near']);
    assert.strictEqual(res.pairs.length, 1);
    assert.ok(GET_ALL_CHUNK_SIZE >= 100);
  });

  it('missing viewer canonical_v1 keeps included uids and marks pairs unavailable', async () => {
    const db = new MemoryFirestore();
    await db
      .doc('users/ok/profiles/canonical_v1')
      .set(canonicalDoc(fill(DIMENSION_IDS, 0.4)));
    const res = await handleCompareStageB2Structural(
      request('viewer', ['ok']),
      { db },
    );
    assert.deepStrictEqual(res.candidate_uids, ['ok']);
    assert.deepStrictEqual(res.pairs, [
      publicUnavailable('viewer_canonical_profile_missing'),
    ]);
  });

  it('keeps identical candidate_uids and pair outputs across blocked, missing, and scored', async () => {
    const db = new MemoryFirestore();
    const viewer = fill(DIMENSION_IDS, 0.45);
    const near = fill(DIMENSION_IDS, 0.45);
    const far = fill(DIMENSION_IDS, 0.95);
    await db.doc('users/viewer/profiles/canonical_v1').set(canonicalDoc(viewer));
    await db.doc('users/near/profiles/canonical_v1').set(canonicalDoc(near));
    await db.doc('users/far/profiles/canonical_v1').set(canonicalDoc(far));
    await db.doc('users/blocked_me/profiles/canonical_v1').set(
      canonicalDoc(fill(DIMENSION_IDS, 0.1)),
    );
    await db.doc('users/blocked_me/blocks/viewer').set({
      blocked_uid: 'viewer',
      reason: 'secret-block-reason',
      owner_uid: 'should-not-leak',
    });

    const res = await handleCompareStageB2Structural(
      request('viewer', ['blocked_me', 'missing', 'near', 'far']),
      { db },
    );

    const viewerScores = measuredScoresFromCanonicalProfile(canonicalDoc(viewer));
    const nearPair = toPublicPair(
      compareMeasuredPresence(
        viewerScores,
        measuredScoresFromCanonicalProfile(canonicalDoc(near)),
      ),
    );
    const farPair = toPublicPair(
      compareMeasuredPresence(
        viewerScores,
        measuredScoresFromCanonicalProfile(canonicalDoc(far)),
      ),
    );

    assert.deepStrictEqual(res.candidate_uids, ['missing', 'near', 'far']);
    assert.deepStrictEqual(res.pairs, [
      publicUnavailable('candidate_canonical_profile_missing'),
      nearPair,
      farPair,
    ]);
    assert.strictEqual(res.pairs[1].structural_distance, 0.0);
    assert.ok(res.pairs[2].structural_distance > 0);

    const blob = JSON.stringify(res);
    assert.strictEqual(blob.includes('blocked_me'), false);
    assert.strictEqual(blob.includes('secret-block-reason'), false);
    assert.strictEqual(blob.includes('measured_dimensions'), false);
    assert.strictEqual(blob.includes('owner_uid'), false);
    assert.strictEqual(blob.includes('should-not-leak'), false);
    assert.strictEqual(blob.includes('sess-secret'), false);
    for (const pair of res.pairs) {
      for (const key of Object.keys(pair)) {
        assert.ok(PUBLIC_PAIR_KEYS.includes(key), key);
      }
    }
  });

  it('MemoryFirestore getAll returns snapshots in request order', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/a/profiles/canonical_v1').set({ n: 1 });
    await db.doc('users/c/blocks/viewer').set({ n: 3 });
    const snaps = await db.getAll(
      db.doc('users/a/profiles/canonical_v1'),
      db.doc('users/b/profiles/canonical_v1'),
      db.doc('users/c/blocks/viewer'),
    );
    assert.strictEqual(snaps.length, 3);
    assert.strictEqual(snaps[0].exists, true);
    assert.strictEqual(snaps[0].data().n, 1);
    assert.strictEqual(snaps[1].exists, false);
    assert.strictEqual(snaps[2].exists, true);
    assert.strictEqual(snaps[2].data().n, 3);
  });
});
