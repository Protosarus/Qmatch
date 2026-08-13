/**
 * Google Play IAP configuration from secrets/env.
 * Never commit real service-account keys.
 *
 * On Cloud Functions, values are mounted via `defineSecret` bindings
 * (`store_iap_secrets.js`) into process.env with the same names. Missing
 * package + credentials → verification_not_configured (fail closed).
 */

'use strict';

/**
 * @param {string} key
 * @returns {string}
 */
function normalizePrivateKey(key) {
  return String(key || '')
    .replace(/\\n/g, '\n')
    .trim();
}

/**
 * Load Play IAP config from env.
 *
 * Required:
 * - PLAY_IAP_PACKAGE_NAME
 * - PLAY_IAP_CLIENT_EMAIL
 * - PLAY_IAP_PRIVATE_KEY
 *
 * Optional:
 * - GOOGLE_APPLICATION_CREDENTIALS (path) — alternative to inline key
 * - PLAY_IAP_REQUIRE_ACCOUNT_BINDING (default true)
 *
 * @param {NodeJS.ProcessEnv|Record<string, string|undefined>} [env]
 * @returns {{ ok: true, config: object }|{ ok: false, code: string, missing: string[] }}
 */
function loadPlayIapConfig(env = process.env) {
  const packageName = (env.PLAY_IAP_PACKAGE_NAME || '').trim();
  const clientEmail = (env.PLAY_IAP_CLIENT_EMAIL || '').trim();
  const privateKey = normalizePrivateKey(env.PLAY_IAP_PRIVATE_KEY || '');
  const credentialsPath = (env.GOOGLE_APPLICATION_CREDENTIALS || '').trim();

  const missing = [];
  if (!packageName) missing.push('PLAY_IAP_PACKAGE_NAME');

  const hasInline = !!(clientEmail && privateKey);
  const hasFile = !!credentialsPath;
  if (!hasInline && !hasFile) {
    missing.push('PLAY_IAP_CLIENT_EMAIL');
    missing.push('PLAY_IAP_PRIVATE_KEY');
  }

  if (missing.length) {
    return { ok: false, code: 'verification_not_configured', missing };
  }

  return {
    ok: true,
    config: {
      packageName,
      clientEmail: clientEmail || null,
      privateKey: privateKey || null,
      credentialsPath: credentialsPath || null,
      requireAccountBinding: env.PLAY_IAP_REQUIRE_ACCOUNT_BINDING !== 'false',
    },
  };
}

module.exports = {
  normalizePrivateKey,
  loadPlayIapConfig,
};
