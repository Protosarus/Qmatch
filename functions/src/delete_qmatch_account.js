/**
 * QMatch account deletion policy (`delete_qmatch_account_v1`).
 *
 * Pure helpers — no I/O. The callable/runner apply this matrix with Admin SDK.
 * Client-supplied targetUid is never used.
 */

'use strict';

const POLICY = 'delete_qmatch_account_v1';
const CALLABLE_NAME = 'deleteQMatchAccount';
const APPLE_PROVIDER = 'apple.com';

const CLASS = Object.freeze({
  DELETE: 'A_DELETE',
  DEIDENTIFY: 'B_DEIDENTIFY',
  RETAIN_SHARED: 'C_RETAIN_SHARED',
  RETAIN_LEGAL: 'D_RETAIN_LEGAL',
  UNKNOWN: 'E_UNKNOWN',
});

const STEPS = Object.freeze([
  'claim_request',
  'revoke_visibility',
  'delete_public_profile',
  'close_matches_threads',
  'deidentify_shared_threads',
  'delete_user_owned_data',
  'delete_owned_storage',
  'retain_entitlements',
  'delete_user_doc',
  'delete_auth_user',
  'finalize_request',
]);

/**
 * Explicit retention matrix. Do not invent extra deletes here.
 */
const DELETION_MATRIX = Object.freeze([
  { path: 'users/{uid}', action: CLASS.DELETE, note: 'After subcollections + media' },
  { path: 'users/{uid}/assessments/*', action: CLASS.DELETE },
  { path: 'users/{uid}/assessment_assignments/*', action: CLASS.DELETE },
  { path: 'users/{uid}/profiles/*', action: CLASS.DELETE },
  { path: 'users/{uid}/swipes/*', action: CLASS.DELETE },
  { path: 'users/{uid}/blocks/*', action: CLASS.DELETE, note: 'Owner graph only' },
  { path: 'users/{uid}/activity_feed/*', action: CLASS.DELETE },
  { path: 'users/{uid}/fcm_tokens/*', action: CLASS.DELETE },
  { path: 'users/{uid}/preferences/*', action: CLASS.DELETE },
  { path: 'public_profiles/{uid}', action: CLASS.DELETE },
  { path: 'profile_photos/{uid}/**', action: CLASS.DELETE },
  { path: 'firebase_auth/{uid}', action: CLASS.DELETE, note: 'Last' },
  {
    path: 'matches/{matchId}',
    action: CLASS.DEIDENTIFY,
    note: 'Close active; keep doc for counterpart',
  },
  {
    path: 'threads/{threadId}',
    action: CLASS.DEIDENTIFY,
    note: 'Close; redact preview if last sender is deleted uid',
  },
  {
    path: 'threads/{threadId}/messages/*',
    action: CLASS.RETAIN_SHARED,
    note: 'Do not delete counterpart history',
  },
  {
    path: 'chat_media/{threadId}/{uid}/**',
    action: CLASS.RETAIN_SHARED,
    note: 'Shared conversation media stays',
  },
  {
    path: 'users/{otherUid}/swipes/{uid}',
    action: CLASS.RETAIN_SHARED,
  },
  {
    path: 'users/{otherUid}/blocks/{uid}',
    action: CLASS.RETAIN_SHARED,
  },
  { path: 'reports/*', action: CLASS.RETAIN_LEGAL },
  { path: 'entitlements/{uid}', action: CLASS.RETAIN_LEGAL },
  { path: 'entitlements/{uid}/purchase_ledger/*', action: CLASS.RETAIN_LEGAL },
  { path: 'store_purchase_index/*', action: CLASS.RETAIN_LEGAL },
  { path: 'account_deletion_requests/{uid}', action: CLASS.RETAIN_LEGAL },
  { path: 'assessment_sets/*', action: CLASS.RETAIN_SHARED },
  { path: 'push_receipts/*', action: CLASS.RETAIN_LEGAL },
]);

const USER_OWNED_SUBCOLLECTIONS = Object.freeze([
  'assessments',
  'assessment_assignments',
  'profiles',
  'swipes',
  'blocks',
  'activity_feed',
  'fcm_tokens',
  'preferences',
]);

function requireAuthenticatedUid(request) {
  const uid = request && request.auth && request.auth.uid;
  if (!uid || typeof uid !== 'string' || !uid.trim()) {
    const err = new Error('unauthenticated');
    err.code = 'unauthenticated';
    throw err;
  }
  return uid.trim();
}

/**
 * Only request.auth.uid is deleted. Client targetUid is ignored.
 */
function resolveDeletionUid(request) {
  return requireAuthenticatedUid(request);
}

function appleLinkedFromProviderData(providerData) {
  if (!Array.isArray(providerData)) return false;
  return providerData.some((item) => {
    const id = item && (item.providerId || item.provider_id);
    return id === APPLE_PROVIDER;
  });
}

function requiresAppleRevocationSignal(authUser) {
  const data = authUser && (authUser.providerData || authUser.provider_data);
  return appleLinkedFromProviderData(data);
}

function appleRevocationAccepted(requestData) {
  const data = requestData && typeof requestData === 'object' ? requestData : {};
  return data.apple_revocation_completed === true;
}

function ownedStoragePrefixes(uid) {
  return [`profile_photos/${uid}/`];
}

function isUidOwnedStoragePath(uid, objectPath) {
  if (!uid || typeof objectPath !== 'string') return false;
  const path = objectPath.replace(/^\/+/, '');
  if (path.startsWith('chat_media/')) return false;
  return path === `profile_photos/${uid}` || path.startsWith(`profile_photos/${uid}/`);
}

function visibilityRevokeFields() {
  return {
    account_deletion_requested: true,
    discover_eligible: false,
    active: false,
  };
}

function requestClaimFields() {
  return {
    status: 'processing',
    policy: POLICY,
  };
}

function requestCompletedFields() {
  return {
    status: 'completed',
    policy: POLICY,
    final_deletion_status: 'completed',
  };
}

function threadDeidentifyPlan(threadData, uid) {
  const data = threadData && typeof threadData === 'object' ? threadData : {};
  const unread = data.unread_counts && typeof data.unread_counts === 'object'
    ? { ...data.unread_counts }
    : {};
  const clearPreview = data.last_message_sender === uid;
  return {
    status: 'closed',
    closed_reason: 'account_deletion_requested',
    last_message_preview: clearPreview ? '' : data.last_message_preview,
    unread_counts: { ...unread, [uid]: 0 },
    participants: Array.isArray(data.participants) ? data.participants : [],
  };
}

function entitlementRetainPatch(uid) {
  return {
    uid,
    account_deleted: true,
    resonance_access: false,
  };
}

function authDeleteIsLast(steps) {
  const authIndex = steps.indexOf('delete_auth_user');
  const dataSteps = steps.filter((s) => s !== 'delete_auth_user' && s !== 'finalize_request');
  return dataSteps.every((s) => steps.indexOf(s) < authIndex);
}

module.exports = {
  POLICY,
  CALLABLE_NAME,
  APPLE_PROVIDER,
  CLASS,
  STEPS,
  DELETION_MATRIX,
  USER_OWNED_SUBCOLLECTIONS,
  requireAuthenticatedUid,
  resolveDeletionUid,
  appleLinkedFromProviderData,
  requiresAppleRevocationSignal,
  appleRevocationAccepted,
  ownedStoragePrefixes,
  isUidOwnedStoragePath,
  visibilityRevokeFields,
  requestClaimFields,
  requestCompletedFields,
  threadDeidentifyPlan,
  entitlementRetainPatch,
  authDeleteIsLast,
};
