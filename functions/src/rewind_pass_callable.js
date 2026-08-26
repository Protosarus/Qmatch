'use strict';

const { HttpsError } = require('firebase-functions/v2/https');

const CALLABLE_NAME = 'rewindPass';
const PUBLIC_RESULT_KEYS = Object.freeze(['rewound']);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to Rewind.',
    );
  }
  return uid;
}

function requireTargetUid(request, viewerUid) {
  const data =
    request.data && typeof request.data === 'object'
      ? request.data
      : {};

  const targetUid = data.target_uid;

  if (typeof targetUid !== 'string' || targetUid.trim().length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'target_uid must be a non-empty string.',
    );
  }

  const normalized = targetUid.trim();

  if (normalized === viewerUid) {
    throw new HttpsError(
      'invalid-argument',
      'Cannot Rewind yourself.',
    );
  }

  return normalized;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

/**
 * Trusted Discover Pass Rewind.
 *
 * Deletes only the authenticated user's own Discover PASS.
 * Never deletes Like, Super Resonance, Match, Thread, or Message data.
 *
 * Firestore rules intentionally keep swipe deletion disabled for clients;
 * only this Admin callable may perform the delete.
 */
async function handleRewindPass(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const targetUid = requireTargetUid(request, viewerUid);
  const db = resolveDb(deps);

  const swipeRef = db.doc(
    `users/${viewerUid}/swipes/${targetUid}`,
  );

  return db.runTransaction(async (tx) => {
    const swipeSnap = await tx.get(swipeRef);

    if (!swipeSnap.exists) {
      throw new HttpsError(
        'failed-precondition',
        'No rewindable Discover Pass exists.',
      );
    }

    const swipe = swipeSnap.data() || {};

    const isOwnedPass =
      swipe.from_uid === viewerUid &&
      swipe.target_uid === targetUid &&
      swipe.direction === 'pass' &&
      swipe.source === 'discover';

    if (!isOwnedPass) {
      throw new HttpsError(
        'failed-precondition',
        'Only a Discover Pass can be rewound.',
      );
    }

    tx.delete(swipeRef);

    return {
      rewound: true,
    };
  });
}

module.exports = {
  CALLABLE_NAME,
  PUBLIC_RESULT_KEYS,
  handleRewindPass,
};
