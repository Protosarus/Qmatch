'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten, onDocumentCreated } = require('firebase-functions/v2/firestore');
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
  { region: 'us-central1', minInstances: 1 },
  (request) => stageB2L2.handleCompareStageB2Structural(request),
);
exports.handleCompareStageB2Structural = stageB2L2.handleCompareStageB2Structural;

/**
 * Debug/internal A/B only. Same handler, auth, payload, membership,
 * ranking I/O, and security as compareStageB2Structural. No new writes.
 * Does not replace the live us-central1 callable.
 */
exports.compareStageB2StructuralEu = onCall(
  { region: 'europe-west1', minInstances: 1 },
  (request) => stageB2L2.handleCompareStageB2Structural(request),
);
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

/**
 * EU-colocated Like + match create.
 * Same trusted handler/payload as the legacy us-central1 callable.
 * Firestore is europe-west1, so new clients should prefer this endpoint.
 */
exports.likeAndMaybeCreateMatchEu = onCall(
  { region: 'europe-west1' },
  (request) => likeAndMaybeCreateMatch.handleLikeAndMaybeCreateMatch(request),
);
const rewindPass = require('./src/rewind_pass_callable');

/**
 * Trusted Discover Pass Rewind.
 * Deletes only the authenticated user's own Discover Pass.
 * Never rewinds Like, Super Resonance, Match, Thread, or Message data.
 */
exports.rewindPass = onCall(
  { region: 'us-central1' },
  (request) => rewindPass.handleRewindPass(request),
);

/**
 * EU-colocated Rewind Pass endpoint for current clients.
 * Legacy us-central1 endpoint remains live for older app versions.
 */
exports.rewindPassEu = onCall(
  { region: 'europe-west1' },
  (request) => rewindPass.handleRewindPass(request),
);
exports.handleRewindPass = rewindPass.handleRewindPass;

const rewindLike = require('./src/rewind_like_callable');

/**
 * Trusted Discover Like Rewind.
 * Deletes only an authenticated user's own one-sided Discover Like.
 * Refuses when Match, Thread, or match-system-message artifacts exist.
 */
exports.rewindLike = onCall(
  { region: 'us-central1' },
  (request) => rewindLike.handleRewindLike(request),
);

/**
 * EU-colocated Rewind Like endpoint for current clients.
 * Legacy us-central1 endpoint remains live for older app versions.
 */
exports.rewindLikeEu = onCall(
  { region: 'europe-west1' },
  (request) => rewindLike.handleRewindLike(request),
);
exports.handleRewindLike = rewindLike.handleRewindLike;

const listWhoLikedYou = require('./src/list_who_liked_you_callable');

/**
 * Trusted Who Liked You list. Admin-reads inbound likes + entitlement.
 * Returns public cards only when resonance_access is true.
 */
exports.listWhoLikedYou = onCall(
  { region: 'us-central1' },
  (request) => listWhoLikedYou.handleListWhoLikedYou(request),
);
/**
 * Zero-downtime EU colocation. Same handler/auth/payload as listWhoLikedYou.
 * Does not replace the live us-central1 callable.
 */
exports.listWhoLikedYouEu = onCall(
  { region: 'europe-west1' },
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

/**
 * EU-colocated Super Resonance send endpoint for current clients.
 * Legacy us-central1 endpoint remains live for older app versions.
 */
exports.sendSuperResonanceEu = onCall(
  { region: 'europe-west1' },
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

/**
 * EU-colocated Super Resonance availability endpoint for current clients.
 * Legacy us-central1 endpoint remains live for older app versions.
 */
exports.getSuperResonanceAvailabilityEu = onCall(
  { region: 'europe-west1' },
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
/**
 * Zero-downtime EU colocation. Same handler/auth/payload as
 * listSuperResonanceInbox. Does not replace the live us-central1 callable.
 */
exports.listSuperResonanceInboxEu = onCall(
  { region: 'europe-west1' },
  (request) => listSuperResonanceInbox.handleListSuperResonanceInbox(request),
);
exports.handleListSuperResonanceInbox =
  listSuperResonanceInbox.handleListSuperResonanceInbox;
const discoverPassport = require('./src/discover_passport_callable');

/**
 * Trusted Discover Passport preference. Resonance-gated set; Free may disable
 * and may read saved destination metadata with effective enabled=false.
 * Admin writes users/{uid}/preferences/discover_passport_v1 only.
 */
exports.getDiscoverPassport = onCall(
  { region: 'us-central1' },
  (request) => discoverPassport.handleGetDiscoverPassport(request),
);
exports.setDiscoverPassport = onCall(
  { region: 'us-central1' },
  (request) => discoverPassport.handleSetDiscoverPassport(request),
);
exports.disableDiscoverPassport = onCall(
  { region: 'us-central1' },
  (request) => discoverPassport.handleDisableDiscoverPassport(request),
);

/**
 * EU-colocated Discover Passport endpoints for current clients.
 * Legacy us-central1 endpoints remain live for older app versions.
 */
exports.getDiscoverPassportEu = onCall(
  { region: 'europe-west1' },
  (request) => discoverPassport.handleGetDiscoverPassport(request),
);
exports.setDiscoverPassportEu = onCall(
  { region: 'europe-west1' },
  (request) => discoverPassport.handleSetDiscoverPassport(request),
);
exports.disableDiscoverPassportEu = onCall(
  { region: 'europe-west1' },
  (request) => discoverPassport.handleDisableDiscoverPassport(request),
);
exports.handleGetDiscoverPassport = discoverPassport.handleGetDiscoverPassport;
exports.handleSetDiscoverPassport = discoverPassport.handleSetDiscoverPassport;
exports.handleDisableDiscoverPassport =
  discoverPassport.handleDisableDiscoverPassport;
const fcmTokens = require('./src/fcm_token_callable');

/**
 * Trusted FCM device-token registration. Auth required. Writes only
 * users/{auth.uid}/fcm_tokens/{sha256(token)}. Never client-writable.
 * Does not send notifications.
 */
exports.registerFcmToken = onCall(
  { region: 'europe-west1' },
  (request) => fcmTokens.handleRegisterFcmToken(request),
);
exports.unregisterFcmToken = onCall(
  { region: 'europe-west1' },
  (request) => fcmTokens.handleUnregisterFcmToken(request),
);
exports.handleRegisterFcmToken = fcmTokens.handleRegisterFcmToken;
exports.handleUnregisterFcmToken = fcmTokens.handleUnregisterFcmToken;
const notificationPrefs = require('./src/notification_prefs_callable');

/**
 * Trusted notification preferences. Auth required. Admin writes
 * users/{uid}/preferences/notification_prefs_v1 only. Missing doc = all on.
 */
exports.getNotificationPrefs = onCall(
  { region: 'europe-west1' },
  (request) => notificationPrefs.handleGetNotificationPrefs(request),
);
exports.setNotificationPrefs = onCall(
  { region: 'europe-west1' },
  (request) => notificationPrefs.handleSetNotificationPrefs(request),
);
exports.handleGetNotificationPrefs =
  notificationPrefs.handleGetNotificationPrefs;
exports.handleSetNotificationPrefs =
  notificationPrefs.handleSetNotificationPrefs;
const finalizeIq = require('./src/finalize_iq_v1');

/**
 * Trusted IQ session finalize (`admin_finalize_iq_v1`).
 * Auth required. Structurally validates a locked 25-item IQ session and
 * Admin-writes users/{uid}.assessment_verification_v1.iq.
 * Does not score, store answers, grant Discover, or finalize EQ/Frequency.
 * europe-west1 only: Firestore is EU-colocated; no US twin in C2-T2B.
 */
exports.finalizeIq = onCall(
  { region: 'europe-west1' },
  (request) => finalizeIq.handleFinalizeIq(request),
);
const finalizeEq = require('./src/finalize_eq_v1');

/**
 * Trusted EQ session finalize (`admin_finalize_eq_v1`).
 * Auth required. Structurally validates a locked 30-item EQ session and
 * Admin-writes users/{uid}.assessment_verification_v1.eq plus eq_completed.
 * Does not score, store answers, grant Discover, or finalize IQ/Frequency.
 * Registered locally; not client-wired. europe-west1 only.
 */
exports.finalizeEq = onCall(
  { region: 'europe-west1' },
  (request) => finalizeEq.handleFinalizeEq(request),
);
const finalizeFrequency = require('./src/finalize_frequency_v1');

/**
 * Trusted Frequency V1 session finalize (`admin_finalize_frequency_v1`).
 * Auth required. Structurally validates a locked 50-item Frequency V1 session
 * and Admin-writes users/{uid}.assessment_verification_v1.frequency plus
 * frequency_completed. Does not score, store answers, grant Discover, or
 * finalize IQ/EQ/V2. Registered locally; not client-wired. europe-west1 only.
 */
exports.finalizeFrequency = onCall(
  { region: 'europe-west1' },
  (request) => finalizeFrequency.handleFinalizeFrequency(request),
);
const finalizeFrequencyV2 = require('./src/finalize_frequency_v2_v1');

/**
 * Trusted Frequency V2 session finalize (`admin_finalize_frequency_v2_v1`).
 * Auth required. Validates a locked 50-item V2 session, scores server-side,
 * and Admin-writes users/{uid}/assessments/frequency_v2 only.
 * Does not write users/{uid}, V1 frequency, canonical_v1, Discover, matching,
 * or completion flags. Registered locally; not client-wired. V2 stays dormant.
 * europe-west1 only.
 */
exports.finalizeFrequencyV2 = onCall(
  { region: 'europe-west1' },
  (request) => finalizeFrequencyV2.handleFinalizeFrequencyV2(request),
);
const newMessagePush = require('./src/new_message_push');

/**
 * New-message push. Auth is the Firestore create itself.
 * Sends only for active-thread text messages to the other participant.
 * Does not send notifications for system_match_v1 or closed threads.
 */
exports.sendNewMessagePush = onDocumentCreated(
  {
    document: 'threads/{threadId}/messages/{messageId}',
    region: 'europe-west1',
  },
  (event) => newMessagePush.handleThreadMessageCreated(event),
);
exports.handleThreadMessageCreated = newMessagePush.handleThreadMessageCreated;
const newMatchPush = require('./src/new_match_push');

/**
 * New-match push. Auth is the Firestore create itself.
 * Notifies only the non-actor participant of a newly created active match.
 * Does not change likeAndMaybeCreateMatch or match creation semantics.
 */
exports.sendNewMatchPush = onDocumentCreated(
  {
    document: 'matches/{matchId}',
    region: 'europe-west1',
  },
  (event) => newMatchPush.handleMatchCreated(event),
);
exports.handleMatchCreated = newMatchPush.handleMatchCreated;
const superResonancePush = require('./src/super_resonance_push');

/**
 * Super Resonance push. Auth is the Firestore create itself.
 * Notifies only to_uid for a newly created active signal.
 * Does not change sendSuperResonance or credit spending.
 */
exports.sendSuperResonancePush = onDocumentCreated(
  {
    document: 'super_resonance_signals/{signalId}',
    region: 'europe-west1',
  },
  (event) => superResonancePush.handleSuperResonanceSignalCreated(event),
);
exports.handleSuperResonanceSignalCreated =
  superResonancePush.handleSuperResonanceSignalCreated;

const activityFeed = require('./src/activity_feed');
const publicProfilesProjection = require('./src/public_profiles_projection');

/**
 * Server-owned public profile projection (`public_profiles/{uid}`).
 * Whitelist copy from users/{uid}. Never writes users/{uid}.
 * Never grants discover_eligible — copies the stored boolean only.
 */
exports.syncPublicProfileOnUserWrite = onDocumentWritten(
  {
    document: 'users/{uid}',
    region: 'europe-west1',
  },
  (event) => publicProfilesProjection.handlePublicProfileUserWritten(event),
);
exports.handlePublicProfileUserWritten =
  publicProfilesProjection.handlePublicProfileUserWritten;

exports.createActivityFromProfileUpdate = onDocumentWritten(
  {
    document: 'users/{uid}',
    region: 'europe-west1',
  },
  (event) => activityFeed.handleProfileActivityWritten(event),
);

exports.createActivityFromMatch = onDocumentCreated(
  {
    document: 'matches/{matchId}',
    region: 'europe-west1',
  },
  (event) => activityFeed.handleMatchActivityCreated(event),
);

exports.createActivityFromSuperResonance = onDocumentCreated(
  {
    document: 'super_resonance_signals/{signalId}',
    region: 'europe-west1',
  },
  (event) => activityFeed.handleSuperResonanceActivityCreated(event),
);

exports.handleProfileActivityWritten =
  activityFeed.handleProfileActivityWritten;
exports.handleMatchActivityCreated =
  activityFeed.handleMatchActivityCreated;
exports.handleSuperResonanceActivityCreated =
  activityFeed.handleSuperResonanceActivityCreated;
