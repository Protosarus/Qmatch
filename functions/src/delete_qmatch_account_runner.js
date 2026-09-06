/**
 * Admin SDK runner for deleteQMatchAccount.
 *
 * Operates only on the authenticated uid. Idempotent. Auth delete is last.
 */

'use strict';

const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');
const { closeAllActiveMatchesForDeletion } = require('./deletion_close_all_runner');
const {
  POLICY,
  STEPS,
  USER_OWNED_SUBCOLLECTIONS,
  requiresAppleRevocationSignal,
  appleRevocationAccepted,
  ownedStoragePrefixes,
  isUidOwnedStoragePath,
  visibilityRevokeFields,
  requestClaimFields,
  requestCompletedFields,
  threadDeidentifyPlan,
  entitlementRetainPatch,
} = require('./delete_qmatch_account');

function resolveDb(deps) {
  if (deps && deps.db) return deps.db;
  return getFirestore();
}

function timestamp(deps) {
  if (deps && typeof deps.serverTimestamp === 'function') {
    return deps.serverTimestamp();
  }
  return FieldValue.serverTimestamp();
}

async function deleteCollectionDocs(db, collectionRef) {
  const snap = await collectionRef.get();
  if (!snap.size) return 0;
  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();
  return snap.size;
}

async function listOwnedStoragePaths(deps, uid) {
  if (deps && typeof deps.listOwnedStorage === 'function') {
    return deps.listOwnedStorage(uid);
  }
  const prefixes = ownedStoragePrefixes(uid);
  let bucket = deps && deps.bucket;
  if (!bucket) {
    try {
      bucket = getStorage().bucket();
    } catch (_) {
      return [];
    }
  }
  const paths = [];
  for (const prefix of prefixes) {
    // eslint-disable-next-line no-await-in-loop
    const [files] = await bucket.getFiles({ prefix });
    for (const file of files) {
      if (file && file.name && isUidOwnedStoragePath(uid, file.name)) {
        paths.push(file.name);
      }
    }
  }
  return paths;
}

async function deleteOwnedStorage(deps, uid) {
  const paths = await listOwnedStoragePaths(deps, uid);
  if (!paths.length) return 0;
  if (deps && typeof deps.deleteStoragePath === 'function') {
    for (const path of paths) {
      // eslint-disable-next-line no-await-in-loop
      await deps.deleteStoragePath(path);
    }
    return paths.length;
  }
  const bucket = deps && deps.bucket
    ? deps.bucket
    : getStorage().bucket();
  for (const path of paths) {
    try {
      // eslint-disable-next-line no-await-in-loop
      await bucket.file(path).delete({ ignoreNotFound: true });
    } catch (err) {
      if (!err || err.code !== 404) throw err;
    }
  }
  return paths.length;
}

async function loadAuthUser(deps, uid) {
  if (deps && typeof deps.getUser === 'function') {
    return deps.getUser(uid);
  }
  try {
    return await getAuth().getUser(uid);
  } catch (err) {
    if (err && (err.code === 'auth/user-not-found' || err.code === 'user-not-found')) {
      return null;
    }
    throw err;
  }
}

async function deleteAuthUser(deps, uid) {
  if (deps && typeof deps.deleteUser === 'function') {
    return deps.deleteUser(uid);
  }
  try {
    await getAuth().deleteUser(uid);
    return true;
  } catch (err) {
    if (err && (err.code === 'auth/user-not-found' || err.code === 'user-not-found')) {
      return false;
    }
    throw err;
  }
}

async function deidentifySharedThreads(db, uid, deps) {
  const matches = await db
    .collection('matches')
    .where('users', 'array-contains', uid)
    .get();
  let updated = 0;
  for (const matchDoc of matches.docs) {
    const data = matchDoc.data() || {};
    const threadId = (data.thread_id && String(data.thread_id).trim())
      || matchDoc.id;
    const threadRef = db.collection('threads').doc(threadId);
    // eslint-disable-next-line no-await-in-loop
    const threadSnap = await threadRef.get();
    if (!threadSnap.exists) continue;
    const plan = threadDeidentifyPlan(threadSnap.data(), uid);
    // eslint-disable-next-line no-await-in-loop
    await threadRef.set(
      {
        status: plan.status,
        closed_reason: plan.closed_reason,
        last_message_preview: plan.last_message_preview,
        unread_counts: plan.unread_counts,
        updated_at: timestamp(deps),
      },
      { merge: true },
    );
    updated += 1;
  }
  return updated;
}

/**
 * @param {string} uid
 * @param {{
 *   db?,
 *   serverTimestamp?,
 *   getUser?,
 *   deleteUser?,
 *   listOwnedStorage?,
 *   deleteStoragePath?,
 *   closeMatches?,
 *   requestData?,
 * }} [deps]
 */
async function runDeleteQMatchAccount(uid, deps = {}) {
  if (!uid || typeof uid !== 'string') {
    const err = new Error('uid is required');
    err.code = 'invalid-argument';
    throw err;
  }
  const db = resolveDb(deps);
  const completed = [];
  const authUser = await loadAuthUser(deps, uid);
  if (authUser && requiresAppleRevocationSignal(authUser)
      && !appleRevocationAccepted(deps.requestData)) {
    const err = new Error('apple_revocation_required');
    err.code = 'failed-precondition';
    err.details = { code: 'apple_revocation_required' };
    throw err;
  }

  const requestRef = db.collection('account_deletion_requests').doc(uid);
  const userRef = db.collection('users').doc(uid);
  const publicRef = db.collection('public_profiles').doc(uid);
  const entitlementRef = db.collection('entitlements').doc(uid);

  await requestRef.set(
    {
      uid,
      ...requestClaimFields(),
      processing_started_at: timestamp(deps),
      updated_at: timestamp(deps),
    },
    { merge: true },
  );
  completed.push('claim_request');

  await userRef.set(
    {
      ...visibilityRevokeFields(),
      account_deletion_requested_at: timestamp(deps),
      updated_at: timestamp(deps),
    },
    { merge: true },
  );
  completed.push('revoke_visibility');

  const publicSnap = await publicRef.get();
  if (publicSnap.exists) {
    await publicRef.delete();
  }
  completed.push('delete_public_profile');

  const close = deps.closeMatches
    || closeAllActiveMatchesForDeletion;
  await close(uid, { db });
  completed.push('close_matches_threads');

  await deidentifySharedThreads(db, uid, deps);
  completed.push('deidentify_shared_threads');

  let ownedDeletes = 0;
  for (const name of USER_OWNED_SUBCOLLECTIONS) {
    // eslint-disable-next-line no-await-in-loop
    ownedDeletes += await deleteCollectionDocs(
      db,
      db.collection(`users/${uid}/${name}`),
    );
  }
  completed.push('delete_user_owned_data');

  const storageDeleted = await deleteOwnedStorage(deps, uid);
  completed.push('delete_owned_storage');

  const entitlementSnap = await entitlementRef.get();
  if (entitlementSnap.exists) {
    await entitlementRef.set(
      {
        ...entitlementRetainPatch(uid),
        updated_at: timestamp(deps),
      },
      { merge: true },
    );
  }
  completed.push('retain_entitlements');

  const userSnap = await userRef.get();
  if (userSnap.exists) {
    await userRef.delete();
  }
  completed.push('delete_user_doc');

  const authDeleted = await deleteAuthUser(deps, uid);
  completed.push('delete_auth_user');

  await requestRef.set(
    {
      uid,
      ...requestCompletedFields(),
      processed_at: timestamp(deps),
      updated_at: timestamp(deps),
      owned_docs_deleted: ownedDeletes,
      storage_objects_deleted: storageDeleted,
      auth_deleted: authDeleted !== false,
      completed_steps: STEPS,
    },
    { merge: true },
  );
  completed.push('finalize_request');

  return {
    ok: true,
    policy: POLICY,
    uid,
    completed_steps: completed,
    auth_deleted: authDeleted !== false,
    messages_deleted: false,
    chat_media_deleted: false,
    entitlements_deleted: false,
    reports_deleted: false,
  };
}

module.exports = {
  runDeleteQMatchAccount,
};
