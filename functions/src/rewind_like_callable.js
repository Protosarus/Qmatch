'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  deterministicMatchId,
} = require('./like_match_atomicity');

const CALLABLE_NAME = 'rewindLike';
const PUBLIC_RESULT_KEYS = Object.freeze(['rewound']);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to Rewind a Like.',
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
 * Trusted Discover Like Rewind.
 *
 * Deletes only the authenticated user's own one-sided Discover Like.
 *
 * Safety wall:
 * - Match exists       -> refuse
 * - Thread exists      -> refuse
 * - system match msg   -> refuse
 *
 * Never deletes reverse Like, Match, Thread, Message,
 * Super Resonance, or any other relationship artifact.
 */
async function handleRewindLike(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const targetUid = requireTargetUid(request, viewerUid);
  const db = resolveDb(deps);

  const matchId = deterministicMatchId(viewerUid, targetUid);
  const threadId = matchId;

  const swipeRef = db.doc(
    `users/${viewerUid}/swipes/${targetUid}`,
  );
  const matchRef = db.doc(`matches/${matchId}`);
  const threadRef = db.doc(`threads/${threadId}`);
  const systemMessageRef = db.doc(
    `threads/${threadId}/messages/system_match_v1`,
  );

  return db.runTransaction(async (tx) => {
    const [
      swipeSnap,
      matchSnap,
      threadSnap,
      systemMessageSnap,
    ] = await Promise.all([
      tx.get(swipeRef),
      tx.get(matchRef),
      tx.get(threadRef),
      tx.get(systemMessageRef),
    ]);

    if (!swipeSnap.exists) {
      throw new HttpsError(
        'failed-precondition',
        'No rewindable Discover Like exists.',
      );
    }

    const swipe = swipeSnap.data() || {};

    const isOwnedLike =
      swipe.from_uid === viewerUid &&
      swipe.target_uid === targetUid &&
      swipe.direction === 'like' &&
      swipe.source === 'discover';

    if (!isOwnedLike) {
      throw new HttpsError(
        'failed-precondition',
        'Only an owned Discover Like can be rewound.',
      );
    }

    // Once matching artifacts exist, Like becomes irreversible through Rewind.
    if (
      matchSnap.exists ||
      threadSnap.exists ||
      systemMessageSnap.exists
    ) {
      throw new HttpsError(
        'failed-precondition',
        'This Like already produced matching artifacts.',
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
  handleRewindLike,
};
