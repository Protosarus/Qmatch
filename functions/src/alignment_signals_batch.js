/**
 * Shared Firestore BatchGet helpers for Alignment Signals enrichment.
 */

'use strict';

/**
 * Admin BatchGetDocuments is one RPC per chunk. Chunks run in parallel.
 * Conservative 100-doc slices (same as Stage B2 L2).
 */
const GET_ALL_CHUNK_SIZE = 100;

/**
 * Missing / failed individual docs become non-existent snaps so one bad
 * candidate cannot hide the rest (prior fan-out try/catch semantics).
 * @param {{ get: () => Promise<object> }} ref
 */
async function getSnapOrMissing(ref) {
  try {
    return await ref.get();
  } catch (_) {
    return {
      exists: false,
      data: () => null,
    };
  }
}

/**
 * @param {{ getAll?: Function }} db
 * @param {Array<{ get: () => Promise<object> }>} refs
 * @returns {Promise<object[]>}
 */
async function getAllSnaps(db, refs) {
  if (!refs.length) return [];
  if (typeof db.getAll === 'function') {
    if (refs.length <= GET_ALL_CHUNK_SIZE) {
      return db.getAll(...refs);
    }
    const groups = [];
    for (let i = 0; i < refs.length; i += GET_ALL_CHUNK_SIZE) {
      groups.push(db.getAll(...refs.slice(i, i + GET_ALL_CHUNK_SIZE)));
    }
    const parts = await Promise.all(groups);
    return parts.flat();
  }
  return Promise.all(refs.map((ref) => ref.get()));
}

/**
 * Batched enrichment reads. On batch failure, fall back to per-ref gets so
 * one unavailable doc still isolates to that candidate.
 * @param {{ getAll?: Function }} db
 * @param {Array<{ get: () => Promise<object> }>} refs
 * @returns {Promise<object[]>}
 */
async function getAllSnapsIsolating(db, refs) {
  if (!refs.length) return [];
  try {
    return await getAllSnaps(db, refs);
  } catch (_) {
    return Promise.all(refs.map((ref) => getSnapOrMissing(ref)));
  }
}

module.exports = {
  GET_ALL_CHUNK_SIZE,
  getAllSnaps,
  getAllSnapsIsolating,
};
