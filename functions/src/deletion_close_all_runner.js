/**
 * Trusted Admin SDK close-all for account deletion
 * (`deletion_close_all_backend_v1`).
 */

'use strict';

const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const {
  CLOSE_REASON,
  POLICY,
  resolveThreadId,
  planDeletionMatchClose,
  matchClosePayloadFields,
  threadClosePayloadFields,
} = require('./deletion_close_all');

/**
 * Atomically close one ACTIVE match + its thread (if present).
 * Retry-safe / idempotent via planDeletionMatchClose.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {{ matchId: string, actorUid: string }} args
 * @returns {Promise<{ matchId: string, updatedMatch: boolean, updatedThread: boolean, idempotent: boolean, skipReason: string|null }>}
 */
async function closeOneMatchForDeletion(db, args) {
  const matchRef = db.collection('matches').doc(args.matchId);

  return db.runTransaction(async (tx) => {
    const matchSnap = await tx.get(matchRef);
    const matchExists = matchSnap.exists;
    const matchData = matchExists ? matchSnap.data() || {} : {};

    const threadId = resolveThreadId(
      args.matchId,
      matchData.thread_id,
    );
    const threadRef = db.collection('threads').doc(threadId);
    const threadSnap = await tx.get(threadRef);
    const threadExists = threadSnap.exists;
    const threadData = threadExists ? threadSnap.data() || {} : {};

    const plan = planDeletionMatchClose({
      matchExists,
      matchState: matchData.state,
      threadExists,
      threadStatus: threadData.status,
    });

    if (plan.updateMatch) {
      tx.set(
        matchRef,
        {
          ...matchClosePayloadFields({ actorUid: args.actorUid }),
          unmatched_at: FieldValue.serverTimestamp(),
          last_activity_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    if (plan.updateThread) {
      tx.set(
        threadRef,
        {
          ...threadClosePayloadFields({ actorUid: args.actorUid }),
          closed_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    return {
      matchId: args.matchId,
      threadId,
      updatedMatch: plan.updateMatch,
      updatedThread: plan.updateThread,
      idempotent: plan.idempotent,
      skipReason: plan.skipReason,
      closeReason: CLOSE_REASON,
    };
  });
}

/**
 * Close all ACTIVE matches for a uid. Does not delete messages. Never reopens.
 *
 * @param {string} uid
 * @param {{ db?: FirebaseFirestore.Firestore }} [opts]
 * @returns {Promise<object>}
 */
async function closeAllActiveMatchesForDeletion(uid, opts = {}) {
  if (!uid || typeof uid !== 'string') {
    throw new Error('uid is required');
  }
  const db = opts.db || getFirestore();

  // Active-only query; blocked/unmatched are never selected.
  const snap = await db
    .collection('matches')
    .where('users', 'array-contains', uid)
    .where('state', '==', 'active')
    .get();

  const results = [];
  for (const doc of snap.docs) {
    // Sequential transactions — each match+thread pair is atomic.
    // eslint-disable-next-line no-await-in-loop
    const result = await closeOneMatchForDeletion(db, {
      matchId: doc.id,
      actorUid: uid,
    });
    results.push(result);
  }

  return {
    policy: POLICY,
    uid,
    activeMatchesFound: snap.size,
    closed: results.filter((r) => r.updatedMatch || r.updatedThread).length,
    results,
    messagesDeleted: false,
    reopened: false,
    closeReason: CLOSE_REASON,
  };
}

module.exports = {
  closeOneMatchForDeletion,
  closeAllActiveMatchesForDeletion,
};
