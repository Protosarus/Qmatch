/**
 * Apple IAP configuration from secrets/env.
 * Never commit real private keys.
 */

'use strict';

const { Environment } = require('@apple/app-store-server-library');

/**
 * Normalize PEM that may arrive with escaped newlines from Secret Manager / env.
 * @param {string} key
 * @returns {string}
 */
function normalizePrivateKey(key) {
  return String(key || '')
    .replace(/\\n/g, '\n')
    .trim();
}

/**
 * @param {string|undefined} value
 * @returns {import('@apple/app-store-server-library').Environment|null}
 */
function parseEnvironment(value) {
  const v = String(value || '')
    .trim()
    .toLowerCase();
  if (v === 'sandbox') return Environment.SANDBOX;
  if (v === 'production' || v === 'prod') return Environment.PRODUCTION;
  return null;
}

/**
 * Load Apple IAP config from process.env (or injected env map).
 *
 * Required:
 * - APPLE_IAP_ISSUER_ID
 * - APPLE_IAP_KEY_ID
 * - APPLE_IAP_PRIVATE_KEY
 * - APPLE_IAP_BUNDLE_ID
 * - APPLE_IAP_ENVIRONMENT (Sandbox|Production)
 * - APPLE_IAP_APP_APPLE_ID (required for Production; recommended always)
 *
 * @param {NodeJS.ProcessEnv|Record<string, string|undefined>} [env]
 * @returns {{ ok: true, config: object }|{ ok: false, code: string, missing: string[] }}
 */
function loadAppleIapConfig(env = process.env) {
  const issuerId = (env.APPLE_IAP_ISSUER_ID || '').trim();
  const keyId = (env.APPLE_IAP_KEY_ID || '').trim();
  const privateKey = normalizePrivateKey(env.APPLE_IAP_PRIVATE_KEY || '');
  const bundleId = (env.APPLE_IAP_BUNDLE_ID || '').trim();
  const environment = parseEnvironment(env.APPLE_IAP_ENVIRONMENT);
  const appAppleIdRaw = (env.APPLE_IAP_APP_APPLE_ID || '').trim();
  const appAppleId = appAppleIdRaw ? Number(appAppleIdRaw) : undefined;

  const missing = [];
  if (!issuerId) missing.push('APPLE_IAP_ISSUER_ID');
  if (!keyId) missing.push('APPLE_IAP_KEY_ID');
  if (!privateKey) missing.push('APPLE_IAP_PRIVATE_KEY');
  if (!bundleId) missing.push('APPLE_IAP_BUNDLE_ID');
  if (!environment) missing.push('APPLE_IAP_ENVIRONMENT');
  if (environment === Environment.PRODUCTION && !Number.isFinite(appAppleId)) {
    missing.push('APPLE_IAP_APP_APPLE_ID');
  }

  if (missing.length) {
    return { ok: false, code: 'verification_not_configured', missing };
  }

  return {
    ok: true,
    config: {
      issuerId,
      keyId,
      privateKey,
      bundleId,
      environment,
      appAppleId: Number.isFinite(appAppleId) ? appAppleId : undefined,
      enableOnlineChecks: env.APPLE_IAP_ENABLE_ONLINE_CHECKS !== 'false',
    },
  };
}

module.exports = {
  normalizePrivateKey,
  parseEnvironment,
  loadAppleIapConfig,
};
