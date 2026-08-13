/**
 * Store purchase ↔ QMatch uid binding validation.
 */

'use strict';

/**
 * Normalize account token / obfuscated account id for comparison.
 * @param {unknown} value
 * @returns {string|null}
 */
function normalizeAccountBinding(value) {
  if (value === null || value === undefined) return null;
  const s = String(value).trim();
  return s.length ? s : null;
}

/**
 * Validate store-reported account binding against authenticated Firebase uid.
 *
 * Policy (`store_purchase_verification_contract_v1`):
 * - If store binding is present, it MUST equal callerUid (or reject).
 * - If store binding is absent, v1 foundation allows proceed only when
 *   `requireBinding` is false (tests / transitional); production verifiers
 *   should set requireBinding=true once purchase flows always set tokens.
 *
 * @param {object} args
 * @param {string} args.callerUid
 * @param {unknown} args.storeAccountToken appAccountToken / obfuscatedExternalAccountId
 * @param {boolean} [args.requireBinding=true]
 * @returns {{ ok: true }|{ ok: false, code: string }}
 */
function validateUidBinding({
  callerUid,
  storeAccountToken,
  requireBinding = true,
}) {
  if (!callerUid || typeof callerUid !== 'string') {
    return { ok: false, code: 'uid_binding_mismatch' };
  }
  const bound = normalizeAccountBinding(storeAccountToken);
  if (!bound) {
    if (requireBinding) {
      return { ok: false, code: 'uid_binding_mismatch' };
    }
    return { ok: true };
  }
  if (bound !== callerUid) {
    return { ok: false, code: 'uid_binding_mismatch' };
  }
  return { ok: true };
}

module.exports = {
  normalizeAccountBinding,
  validateUidBinding,
};
