/**
 * Construct AppStoreServerAPIClient + SignedDataVerifier from config.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const {
  AppStoreServerAPIClient,
  SignedDataVerifier,
  Environment,
} = require('@apple/app-store-server-library');

const DEFAULT_ROOT_CA_DIR = path.join(__dirname, '..', 'certs', 'apple');

/** Known StoreKit API hosts (for tests / diagnostics; not secrets). */
const APPLE_STOREKIT_API_HOST = Object.freeze({
  [Environment.SANDBOX]: 'https://api.storekit-sandbox.itunes.apple.com',
  [Environment.PRODUCTION]: 'https://api.storekit.itunes.apple.com',
});

/**
 * Load Apple root CA DER buffers.
 * @param {object} [opts]
 * @param {string} [opts.rootCaDir]
 * @param {string[]} [opts.rootCaBase64] optional base64 DER list from env
 * @returns {Buffer[]}
 */
function loadAppleRootCertificates(opts = {}) {
  if (Array.isArray(opts.rootCaBase64) && opts.rootCaBase64.length) {
    return opts.rootCaBase64.map((b64) => Buffer.from(String(b64), 'base64'));
  }
  const dir = opts.rootCaDir || DEFAULT_ROOT_CA_DIR;
  const files = [
    'AppleIncRootCertificate.cer',
    'AppleRootCA-G3.cer',
  ];
  const certs = [];
  for (const name of files) {
    const p = path.join(dir, name);
    if (fs.existsSync(p)) {
      certs.push(fs.readFileSync(p));
    }
  }
  return certs;
}

/**
 * @param {object} config from loadAppleIapConfig().config
 * @param {object} [opts]
 * @param {import('@apple/app-store-server-library').Environment} [opts.environment]
 * @returns {{
 *   apiClient: AppStoreServerAPIClient,
 *   signedDataVerifier: SignedDataVerifier,
 *   environment: import('@apple/app-store-server-library').Environment,
 *   apiHost: string,
 * }}
 */
function createAppleIapClients(config, opts = {}) {
  if (!config) {
    throw new Error('apple_iap_config_required');
  }
  const environment = opts.environment || config.environment;
  if (!environment) {
    throw new Error('apple_iap_environment_required');
  }
  if (
    environment === Environment.PRODUCTION &&
    !Number.isFinite(config.appAppleId)
  ) {
    throw new Error('apple_iap_app_apple_id_required_for_production');
  }

  const rootCertificates =
    opts.rootCertificates || loadAppleRootCertificates(opts);
  if (!rootCertificates.length) {
    throw new Error('apple_root_certificates_missing');
  }

  const apiClient = new AppStoreServerAPIClient(
    config.privateKey,
    config.keyId,
    config.issuerId,
    config.bundleId,
    environment,
  );

  const signedDataVerifier = new SignedDataVerifier(
    rootCertificates,
    config.enableOnlineChecks !== false,
    environment,
    config.bundleId,
    config.appAppleId,
  );

  return {
    apiClient,
    signedDataVerifier,
    environment,
    apiHost: APPLE_STOREKIT_API_HOST[environment] || null,
  };
}

/**
 * Build separate Sandbox + Production clients/verifiers for ASSN dual verify.
 * Production requires config.appAppleId.
 *
 * @param {object} config
 * @param {object} [opts]
 * @returns {{
 *   ok: true,
 *   sandbox: object,
 *   production: object,
 * }|{ ok: false, code: string, missing?: string[] }}
 */
function createDualAppleAssnClients(config, opts = {}) {
  if (!config) {
    return { ok: false, code: 'verification_not_configured' };
  }
  if (!Number.isFinite(config.appAppleId)) {
    return {
      ok: false,
      code: 'verification_not_configured',
      missing: ['APPLE_IAP_APP_APPLE_ID'],
    };
  }

  try {
    const sandbox = createAppleIapClients(config, {
      ...opts,
      environment: Environment.SANDBOX,
    });
    const production = createAppleIapClients(config, {
      ...opts,
      environment: Environment.PRODUCTION,
    });
    return { ok: true, sandbox, production };
  } catch (_err) {
    return { ok: false, code: 'verification_not_configured' };
  }
}

module.exports = {
  DEFAULT_ROOT_CA_DIR,
  APPLE_STOREKIT_API_HOST,
  loadAppleRootCertificates,
  createAppleIapClients,
  createDualAppleAssnClients,
};
