/**
 * Store purchase ↔ QMatch uid binding validation.
 */

'use strict';

const {
  appleAppAccountTokenFromUid,
} = require('./apple_app_account_token');

/**
 * Normalize account token / obfuscated account id for comparison.
 * @param {unknown} value
 * @returns {string|null}
 */
function normalizeAccountBinding(value) {
  if (value === null || value === undefined) return null;
  const s = String(value).trim().toLowerCase();
  return s.length ? s : null;
}

/**
 * Expected store binding token for a caller uid.
 *
 * - `apple`: deterministic UUID v5 derived from uid (never client-supplied)
 * - `raw`: callerUid itself (Play obfuscatedExternalAccountId until Android IAP)
 *
 * @param {string} callerUid
 * @param {'apple'|'raw'} [mode='raw']
 * @returns {string|null}
 */
function expectedStoreAccountToken(callerUid, mode = 'raw') {
  if (!callerUid || typeof callerUid !== 'string') return null;
  if (mode === 'apple') {
    return appleAppAccountTokenFromUid(callerUid).toLowerCase();
  }
  return String(callerUid).trim().toLowerCase() || null;
}

/**
 * Validate store-reported account binding against authenticated Firebase uid.
 *
 * Policy:
 * - Expected token is derived server-side from `callerUid` only.
 * - Never trust a client-echoed expected token.
 * - If store binding is present, it MUST equal the expected token or reject.
 * - If store binding is absent, proceed only when `requireBinding` is false.
 *
 * @param {object} args
 * @param {string} args.callerUid
 * @param {unknown} args.storeAccountToken appAccountToken / obfuscatedExternalAccountId
 * @param {boolean} [args.requireBinding=true]
 * @param {'apple'|'raw'} [args.bindingMode='raw']
 * @returns {{ ok: true }|{ ok: false, code: string }}
 */
function validateUidBinding({
  callerUid,
  storeAccountToken,
  requireBinding = true,
  bindingMode = 'raw',
}) {
  if (!callerUid || typeof callerUid !== 'string') {
    return { ok: false, code: 'uid_binding_mismatch' };
  }
  const expected = expectedStoreAccountToken(callerUid, bindingMode);
  if (!expected) {
    return { ok: false, code: 'uid_binding_mismatch' };
  }
  const bound = normalizeAccountBinding(storeAccountToken);
  if (!bound) {
    if (requireBinding) {
      return { ok: false, code: 'uid_binding_mismatch' };
    }
    return { ok: true };
  }
  if (bound !== expected) {
    return { ok: false, code: 'uid_binding_mismatch' };
  }
  return { ok: true };
}

module.exports = {
  normalizeAccountBinding,
  expectedStoreAccountToken,
  validateUidBinding,
};
