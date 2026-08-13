/**
 * Firebase Functions v2 secret bindings for store verification / notifications.
 *
 * Secret *values* live in Secret Manager (never in git). At runtime, bound
 * secrets appear as process.env[<name>] for loadAppleIapConfig / loadPlayIapConfig.
 *
 * Least privilege:
 * - Apple ASSN → Apple secrets only
 * - Play RTDN → Play secrets only
 * - verify / restore callables → Apple + Play (both platforms)
 * - Discover / deletion Functions → no store secrets
 */

'use strict';

const { defineSecret } = require('firebase-functions/params');

/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_ISSUER_ID = defineSecret('APPLE_IAP_ISSUER_ID');
/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_KEY_ID = defineSecret('APPLE_IAP_KEY_ID');
/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_PRIVATE_KEY = defineSecret('APPLE_IAP_PRIVATE_KEY');
/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_BUNDLE_ID = defineSecret('APPLE_IAP_BUNDLE_ID');
/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_ENVIRONMENT = defineSecret('APPLE_IAP_ENVIRONMENT');
/** @type {import('firebase-functions/params').SecretParam} */
const APPLE_IAP_APP_APPLE_ID = defineSecret('APPLE_IAP_APP_APPLE_ID');

/** @type {import('firebase-functions/params').SecretParam} */
const PLAY_IAP_PACKAGE_NAME = defineSecret('PLAY_IAP_PACKAGE_NAME');
/** @type {import('firebase-functions/params').SecretParam} */
const PLAY_IAP_CLIENT_EMAIL = defineSecret('PLAY_IAP_CLIENT_EMAIL');
/** @type {import('firebase-functions/params').SecretParam} */
const PLAY_IAP_PRIVATE_KEY = defineSecret('PLAY_IAP_PRIVATE_KEY');

const APPLE_IAP_SECRETS = Object.freeze([
  APPLE_IAP_ISSUER_ID,
  APPLE_IAP_KEY_ID,
  APPLE_IAP_PRIVATE_KEY,
  APPLE_IAP_BUNDLE_ID,
  APPLE_IAP_ENVIRONMENT,
  APPLE_IAP_APP_APPLE_ID,
]);

const PLAY_IAP_SECRETS = Object.freeze([
  PLAY_IAP_PACKAGE_NAME,
  PLAY_IAP_CLIENT_EMAIL,
  PLAY_IAP_PRIVATE_KEY,
]);

/** Both platforms — for verifyAndApplyPurchase / restorePurchases. */
const STORE_IAP_SECRETS = Object.freeze([
  ...APPLE_IAP_SECRETS,
  ...PLAY_IAP_SECRETS,
]);

const APPLE_IAP_SECRET_NAMES = Object.freeze(
  APPLE_IAP_SECRETS.map((s) => s.name),
);
const PLAY_IAP_SECRET_NAMES = Object.freeze(
  PLAY_IAP_SECRETS.map((s) => s.name),
);
const STORE_IAP_SECRET_NAMES = Object.freeze(
  STORE_IAP_SECRETS.map((s) => s.name),
);

/**
 * Collect secret env keys declared on a Cloud Function export.
 * @param {object} cloudFunction
 * @returns {string[]}
 */
function secretKeysFromFunction(cloudFunction) {
  const endpoint = cloudFunction && cloudFunction.__endpoint;
  const list =
    (endpoint && endpoint.secretEnvironmentVariables) ||
    (cloudFunction &&
      cloudFunction.__trigger &&
      cloudFunction.__trigger.secrets &&
      cloudFunction.__trigger.secrets.map((s) =>
        typeof s === 'string' ? s : s.name,
      )) ||
    [];
  if (Array.isArray(list) && list.length && typeof list[0] === 'object') {
    return list.map((row) => row.key || row.name).filter(Boolean);
  }
  return Array.isArray(list) ? list.filter(Boolean) : [];
}

module.exports = {
  APPLE_IAP_ISSUER_ID,
  APPLE_IAP_KEY_ID,
  APPLE_IAP_PRIVATE_KEY,
  APPLE_IAP_BUNDLE_ID,
  APPLE_IAP_ENVIRONMENT,
  APPLE_IAP_APP_APPLE_ID,
  PLAY_IAP_PACKAGE_NAME,
  PLAY_IAP_CLIENT_EMAIL,
  PLAY_IAP_PRIVATE_KEY,
  APPLE_IAP_SECRETS,
  PLAY_IAP_SECRETS,
  STORE_IAP_SECRETS,
  APPLE_IAP_SECRET_NAMES,
  PLAY_IAP_SECRET_NAMES,
  STORE_IAP_SECRET_NAMES,
  secretKeysFromFunction,
};
