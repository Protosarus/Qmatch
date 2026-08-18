'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const {
  deriveDiscoverEligible,
  planDiscoverEligibleWrite,
} = require('./src/discover_eligibility');
const {
  shouldRunCloseAllOnUserWrite,
} = require('./src/deletion_close_all');
const {
  closeAllActiveMatchesForDeletion,
} = require('./src/deletion_close_all_runner');
const {
  handleVerifyAndApplyPurchase,
  handleRestorePurchases,
} = require('./src/entitlement_callables');
const entitlementAccess = require('./src/entitlement_access');
const entitlementRepository = require('./src/entitlement_repository');
const {
  appleAssnHttpHandler,
  playRtdnHttpHandler,
} = require('./src/store_notification_http');
const {
  APPLE_IAP_SECRETS,
  PLAY_IAP_SECRETS,
  STORE_IAP_SECRETS,
} = require('./src/store_iap_secrets');

initializeApp();

/**
 * Trusted Discover eligibility authority (`trusted_discover_eligibility_authority_v1`).
 *
 * Only this Admin SDK writer may grant `discover_eligible=true`.
 * Clients may still revoke to false (deletion); this function reconciles
 * whenever relevant user fields change and skips no-op writes to avoid loops.
 */
exports.recomputeDiscoverEligibleOnUserWrite = onDocumentWritten(
  {
    document: 'users/{uid}',
    region: 'us-central1',
  },
  async (event) => {
    const afterSnap = event.data && event.data.after;
    if (!afterSnap || !afterSnap.exists) {
      return null;
    }

    const beforeSnap = event.data && event.data.before;
    const beforeData = beforeSnap && beforeSnap.exists ? beforeSnap.data() : null;
    const afterData = afterSnap.data() || {};

    const plan = planDiscoverEligibleWrite(beforeData, afterData);
    if (!plan.shouldWrite) {
      return null;
    }

    // Write only the derived flag — do not touch updated_at (avoids extra churn).
    await getFirestore().doc(afterSnap.ref.path).update({
      discover_eligible: plan.derived,
    });

    return {
      uid: event.params.uid,
      discover_eligible: plan.derived,
      policy: 'trusted_discover_eligibility_authority_v1',
    };
  },
);

/**
 * Deletion close-all (`deletion_close_all_backend_v1`).
 *
 * On `account_deletion_requested` false → true: close every ACTIVE match for
 * the uid (match → unmatched, thread → closed). Preserve blocked/unmatched.
 * Never deletes messages. Never reactivates.
 */
exports.closeMatchesOnAccountDeletionRequested = onDocumentWritten(
  {
    document: 'users/{uid}',
    region: 'us-central1',
  },
  async (event) => {
    const afterSnap = event.data && event.data.after;
    if (!afterSnap || !afterSnap.exists) {
      return null;
    }

    const beforeSnap = event.data && event.data.before;
    const beforeData = beforeSnap && beforeSnap.exists ? beforeSnap.data() : null;
    const afterData = afterSnap.data() || {};

    if (!shouldRunCloseAllOnUserWrite(beforeData, afterData)) {
      return null;
    }

    const uid = event.params.uid;
    const summary = await closeAllActiveMatchesForDeletion(uid);
    return summary;
  },
);

/**
 * Entitlement purchase verify scaffold (`resonance_entitlement_firestore_schema_v1`).
 * Does not trust client claims; returns verification_not_configured until stores wired.
 * Secrets: Apple + Play (both platforms).
 */
exports.verifyAndApplyPurchase = onCall(
  { region: 'us-central1', secrets: [...STORE_IAP_SECRETS] },
  handleVerifyAndApplyPurchase,
);

/**
 * Entitlement restore — Apple iOS restore path.
 * Secrets: Apple + Play bound; Android restore remains fail-closed.
 */
exports.restorePurchases = onCall(
  { region: 'us-central1', secrets: [...STORE_IAP_SECRETS] },
  handleRestorePurchases,
);

/**
 * Apple App Store Server Notifications v2 HTTP endpoint (foundation).
 * Deploy separately when credentials + SKUs are ready — not activated here.
 * Secrets: Apple only (least privilege).
 */
exports.appStoreServerNotification = onRequest(
  { region: 'us-central1', secrets: [...APPLE_IAP_SECRETS] },
  (req, res) => appleAssnHttpHandler(req, res),
);

/**
 * Google Play RTDN Pub/Sub push endpoint (foundation).
 * Secrets: Play only (least privilege).
 */
exports.playRealtimeDeveloperNotification = onRequest(
  { region: 'us-central1', secrets: [...PLAY_IAP_SECRETS] },
  (req, res) => playRtdnHttpHandler(req, res),
);

// Re-export pure helpers for tests / tooling.
exports.deriveDiscoverEligible = deriveDiscoverEligible;
exports.planDiscoverEligibleWrite = planDiscoverEligibleWrite;
exports.shouldRunCloseAllOnUserWrite = shouldRunCloseAllOnUserWrite;
exports.closeAllActiveMatchesForDeletion = closeAllActiveMatchesForDeletion;
exports.deriveResonanceAccess = entitlementAccess.deriveResonanceAccess;
exports.defaultFreeSnapshot = entitlementAccess.defaultFreeSnapshot;
exports.normalizeSnapshot = entitlementAccess.normalizeSnapshot;
exports.applySubscriptionState = entitlementAccess.applySubscriptionState;
exports.getOrCreateEntitlementSnapshot =
  entitlementRepository.getOrCreateEntitlementSnapshot;
exports.creditConsumableIdempotent =
  entitlementRepository.creditConsumableIdempotent;
exports.spendSuperResonanceIdempotent =
  entitlementRepository.spendSuperResonanceIdempotent;
exports.debitBalance = entitlementAccess.debitBalance;
exports.creditBalance = entitlementAccess.creditBalance;

// Store verifier foundation exports (no ASSN/RTDN; no fake verify).
const storeProductMap = require('./src/store_product_map');
const storeVerifyApple = require('./src/store_verify_apple');
const storeVerifyPlay = require('./src/store_verify_play');
const storeVerificationResult = require('./src/store_verification_result');
exports.mapAppleProduct = storeProductMap.mapAppleProduct;
exports.mapPlayProduct = storeProductMap.mapPlayProduct;
exports.mapAppleSubscriptionStatus = storeProductMap.mapAppleSubscriptionStatus;
exports.mapPlaySubscriptionStatus = storeProductMap.mapPlaySubscriptionStatus;
exports.verifyApplePurchase = storeVerifyApple.verifyApplePurchase;
exports.verifyPlayPurchase = storeVerifyPlay.verifyPlayPurchase;
exports.isTrustedVerified = storeVerificationResult.isTrustedVerified;
exports.applyTrustedVerificationResult =
  require('./src/apply_trusted_verification').applyTrustedVerificationResult;
exports.loadAppleIapConfig = require('./src/apple_iap_config').loadAppleIapConfig;
exports.loadPlayIapConfig = require('./src/play_iap_config').loadPlayIapConfig;
exports.STORE_IAP_SECRET_NAMES =
  require('./src/store_iap_secrets').STORE_IAP_SECRET_NAMES;
exports.APPLE_IAP_SECRET_NAMES =
  require('./src/store_iap_secrets').APPLE_IAP_SECRET_NAMES;
exports.PLAY_IAP_SECRET_NAMES =
  require('./src/store_iap_secrets').PLAY_IAP_SECRET_NAMES;
exports.secretKeysFromFunction =
  require('./src/store_iap_secrets').secretKeysFromFunction;
exports.finalizePlayPurchaseSideEffects =
  require('./src/store_verify_play').finalizePlayPurchaseSideEffects;
exports.handleAppleAssnNotification =
  require('./src/store_notification_apple').handleAppleAssnNotification;
exports.verifyAssnSignedPayload =
  require('./src/store_notification_apple').verifyAssnSignedPayload;
exports.createDualAppleAssnClients =
  require('./src/apple_iap_clients').createDualAppleAssnClients;
exports.handlePlayRtdnNotification =
  require('./src/store_notification_play').handlePlayRtdnNotification;
const stageB2L2 = require('./src/stage_b2_l2_callable');
const canonical20dGroupNormalized = require('./src/canonical_20d_group_normalized_shadow');

/**
 * Stage B2 trusted L2 comparison (`canonical_20d_group_normalized_shadow_distance_v1`).
 * Admin-reads canonical_v1; Admin-omits reverse-blocked candidates.
 * Returns pair diagnostics + included candidate_uids only. Never block docs.
 * Client ranks Discover from the returned distances.
 */
exports.compareStageB2Structural = onCall(
  { region: 'us-central1' },
  (request) => stageB2L2.handleCompareStageB2Structural(request),
);
exports.handleCompareStageB2Structural = stageB2L2.handleCompareStageB2Structural;
exports.compareMeasuredPresenceGroupNormalized =
  canonical20dGroupNormalized.compareMeasuredPresence;
const likeAndMaybeCreateMatch = require('./src/like_and_maybe_create_match_callable');

/**
 * Trusted Like + match create (`like_match_atomicity_v1`).
 * Admin-reads swipes, blocks, users, and match. Returns public outcome only.
 */
exports.likeAndMaybeCreateMatch = onCall(
  { region: 'us-central1' },
  (request) => likeAndMaybeCreateMatch.handleLikeAndMaybeCreateMatch(request),
);
exports.handleLikeAndMaybeCreateMatch =
  likeAndMaybeCreateMatch.handleLikeAndMaybeCreateMatch;
const listWhoLikedYou = require('./src/list_who_liked_you_callable');

/**
 * Trusted Who Liked You list. Admin-reads inbound likes + entitlement.
 * Returns public cards only when resonance_access is true.
 */
exports.listWhoLikedYou = onCall(
  { region: 'us-central1' },
  (request) => listWhoLikedYou.handleListWhoLikedYou(request),
);
exports.handleListWhoLikedYou = listWhoLikedYou.handleListWhoLikedYou;
const sendSuperResonance = require('./src/send_super_resonance_callable');

/**
 * Trusted Super Resonance send. Debit + immutable pair signal in one transaction.
 * Never writes swipes/matches. Never returns block reasons.
 */
exports.sendSuperResonance = onCall(
  { region: 'us-central1' },
  (request) => sendSuperResonance.handleSendSuperResonance(request),
);
exports.handleSendSuperResonance = sendSuperResonance.handleSendSuperResonance;
const getSuperResonanceAvailability = require('./src/get_super_resonance_availability_callable');

/**
 * Trusted Super Resonance availability. Server UTC day only.
 * Read-only. Never spends. Never trusts a client clock.
 */
exports.getSuperResonanceAvailability = onCall(
  { region: 'us-central1' },
  (request) =>
    getSuperResonanceAvailability.handleGetSuperResonanceAvailability(request),
);
exports.handleGetSuperResonanceAvailability =
  getSuperResonanceAvailability.handleGetSuperResonanceAvailability;
const listSuperResonanceInbox = require('./src/list_super_resonance_inbox_callable');

/**
 * Trusted Super Resonance receiver inbox. Admin-queries inbound signals.
 * Public sender cards only. Visible to Free and Resonance. Never lists likes.
 */
exports.listSuperResonanceInbox = onCall(
  { region: 'us-central1' },
  (request) => listSuperResonanceInbox.handleListSuperResonanceInbox(request),
);
exports.handleListSuperResonanceInbox =
  listSuperResonanceInbox.handleListSuperResonanceInbox;
