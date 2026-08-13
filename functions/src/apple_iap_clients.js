/**
 * Construct AppStoreServerAPIClient + SignedDataVerifier from config.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const {
  AppStoreServerAPIClient,
  SignedDataVerifier,
} = require('@apple/app-store-server-library');

const DEFAULT_ROOT_CA_DIR = path.join(__dirname, '..', 'certs', 'apple');

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
 * @returns {{ apiClient: AppStoreServerAPIClient, signedDataVerifier: SignedDataVerifier }}
 */
function createAppleIapClients(config, opts = {}) {
  if (!config) {
    throw new Error('apple_iap_config_required');
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
    config.environment,
  );

  const signedDataVerifier = new SignedDataVerifier(
    rootCertificates,
    config.enableOnlineChecks !== false,
    config.environment,
    config.bundleId,
    config.appAppleId,
  );

  return { apiClient, signedDataVerifier };
}

module.exports = {
  DEFAULT_ROOT_CA_DIR,
  loadAppleRootCertificates,
  createAppleIapClients,
};
