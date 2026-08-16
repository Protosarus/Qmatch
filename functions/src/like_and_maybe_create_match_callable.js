/**
 * Trusted Like + match-create callable.
 *
 * Admin-reads match / swipes / both block docs / both user docs.
 * Returns public outcome only — never block existence or reason.
 */

'use strict';

const { HttpsError } = require('firebase-functions/v2/https');
const {
  isLikeDirection,
  isValidLiveUser,
  planLike,
  writeMatchArtifacts,
  outcomeFromDecision,
  sortedPair,
  deterministicMatchId,
  OUTCOME,
} = require('./like_match_atomicity');

const CALLABLE_NAME = 'likeAndMaybeCreateMatch';
const PUBLIC_OUTCOME_KEYS = Object.freeze(['outcome']);

function requireAuthUid(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Authentication required to Like.',
    );
  }
  return uid;
}

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return require('firebase-admin/firestore').getFirestore();
}

function timestamp(deps) {
  if (deps && typeof deps.serverTimestamp === 'function') {
    return deps.serverTimestamp();
  }
  return require('firebase-admin/firestore').FieldValue.serverTimestamp();
}

function nowMs(deps) {
  if (deps && typeof deps.nowMs === 'function') return deps.nowMs();
  return Date.now();
}

function publicOutcome(outcome) {
  return { outcome };
}

/**
 * @param {import('firebase-functions/v2/https').CallableRequest} request
 * @param {{ db?: object, serverTimestamp?: Function, nowMs?: Function }} [deps]
 */
async function handleLikeAndMaybeCreateMatch(request, deps = {}) {
  const viewerUid = requireAuthUid(request);
  const data = request.data && typeof request.data === 'object' ? request.data : {};
  const targetUid = data.target_uid;
  if (typeof targetUid !== 'string' || targetUid.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'target_uid must be a non-empty string.',
    );
  }
  if (targetUid === viewerUid) {
    throw new HttpsError('invalid-argument', 'Cannot Like yourself.');
  }

  const [userA, userB] = sortedPair(viewerUid, targetUid);
  const matchId = deterministicMatchId(viewerUid, targetUid);
  const threadId = matchId;
  const db = resolveDb(deps);
  const ts = timestamp(deps);

  const ownSwipeRef = db.doc(`users/${viewerUid}/swipes/${targetUid}`);
  const reverseSwipeRef = db.doc(`users/${targetUid}/swipes/${viewerUid}`);
  const viewerBlockRef = db.doc(`users/${viewerUid}/blocks/${targetUid}`);
  const reverseBlockRef = db.doc(`users/${targetUid}/blocks/${viewerUid}`);
  const viewerUserRef = db.doc(`users/${viewerUid}`);
  const targetUserRef = db.doc(`users/${targetUid}`);
  const matchRef = db.doc(`matches/${matchId}`);
  const threadRef = db.doc(`threads/${threadId}`);
  const messageRef = db.doc(`threads/${threadId}/messages/system_match_v1`);

  return db.runTransaction(async (tx) => {
    const matchSnap = await tx.get(matchRef);
    const ownSwipeSnap = await tx.get(ownSwipeRef);
    const reverseSwipeSnap = await tx.get(reverseSwipeRef);
    const viewerBlockSnap = await tx.get(viewerBlockRef);
    const reverseBlockSnap = await tx.get(reverseBlockRef);
    const viewerUserSnap = await tx.get(viewerUserRef);
    const targetUserSnap = await tx.get(targetUserRef);

    const plan = planLike({
      matchExists: matchSnap.exists,
      matchState: matchSnap.exists ? matchSnap.data().state : undefined,
      viewerBlockedCandidate: !!(viewerBlockSnap && viewerBlockSnap.exists),
      candidateBlockedViewer: !!(reverseBlockSnap && reverseBlockSnap.exists),
      viewerLikesCandidatePending: true,
      candidateLikesViewer: isLikeDirection(
        reverseSwipeSnap.exists ? reverseSwipeSnap.data().direction : undefined,
      ),
      viewerLiveEligible: isValidLiveUser(
        viewerUserSnap.exists,
        viewerUserSnap.exists ? viewerUserSnap.data() : null,
      ),
      targetLiveEligible: isValidLiveUser(
        targetUserSnap.exists,
        targetUserSnap.exists ? targetUserSnap.data() : null,
      ),
    });

    if (plan.persistOwnLike) {
      const likePayload = {
        from_uid: viewerUid,
        target_uid: targetUid,
        direction: 'like',
        source: 'discover',
      };
      if (!ownSwipeSnap.exists) {
        likePayload.created_at = ts;
      } else {
        likePayload.updated_at = ts;
      }
      tx.set(ownSwipeRef, likePayload, { merge: true });
    }

    if (plan.matchDecision === 'idempotentActiveSuccess') {
      return publicOutcome(OUTCOME.existingActiveMatch);
    }
    if (!writeMatchArtifacts(plan.matchDecision)) {
      return publicOutcome(OUTCOME.noMatch);
    }

    tx.set(matchRef, {
      match_id: matchId,
      user_a: userA,
      user_b: userB,
      users: [userA, userB],
      created_at: ts,
      created_by: 'system',
      thread_id: threadId,
      state: 'active',
      last_activity_at: ts,
      compat: {},
      reveal: {
        blur_level: 3,
        consent_a: false,
        consent_b: false,
        requested_by: null,
        requested_at: null,
        revealed_at: null,
      },
    });

    tx.set(
      threadRef,
      {
        thread_id: threadId,
        match_id: matchId,
        participants: [userA, userB],
        created_at: ts,
        last_message_at: ts,
        last_message_preview: 'You matched!',
        last_message_sender: 'system',
        unread_counts: { [userA]: 0, [userB]: 0 },
        text_count_total: 0,
        text_count_by_uid: { [userA]: 0, [userB]: 0 },
        status: 'active',
      },
      { merge: true },
    );

    tx.set(messageRef, {
      thread_id: threadId,
      sender_id: 'system',
      type: 'system',
      text: 'You matched!',
      created_at: ts,
      client_created_at: nowMs(deps),
      read_by: {},
      moderation: null,
    });

    return publicOutcome(outcomeFromDecision(plan.matchDecision));
  });
}

module.exports = {
  CALLABLE_NAME,
  PUBLIC_OUTCOME_KEYS,
  OUTCOME,
  handleLikeAndMaybeCreateMatch,
  publicOutcome,
};
