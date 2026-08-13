'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onCall } = require('firebase-functions/v2/https');
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
 */
exports.verifyAndApplyPurchase = onCall(
  { region: 'us-central1' },
  handleVerifyAndApplyPurchase,
);

/**
 * Entitlement restore scaffold. Same not-configured contract as verify.
 */
exports.restorePurchases = onCall(
  { region: 'us-central1' },
  handleRestorePurchases,
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
exports.finalizePlayPurchaseSideEffects =
  require('./src/store_verify_play').finalizePlayPurchaseSideEffects;
