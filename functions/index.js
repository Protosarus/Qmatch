'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
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

// Re-export pure helpers for tests / tooling.
exports.deriveDiscoverEligible = deriveDiscoverEligible;
exports.planDiscoverEligibleWrite = planDiscoverEligibleWrite;
exports.shouldRunCloseAllOnUserWrite = shouldRunCloseAllOnUserWrite;
exports.closeAllActiveMatchesForDeletion = closeAllActiveMatchesForDeletion;
