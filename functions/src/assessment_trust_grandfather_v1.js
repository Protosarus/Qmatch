'use strict';

/**
 * Legacy assessment-trust grandfather planner (`assessment_trust_grandfather_v1`).
 *
 * Grandfathering is FLOW / Discover-eligibility continuity only:
 *   assessment_verification_v1.flow = pre_c2_preserved
 *   assessment_verification_v1.grant_reason = pre_trust_migration_preserved
 *
 * It is not server-verified IQ/EQ/Frequency completion. This module does not
 * invent module `grandfathered` statuses. Frequency V2 is out of scope.
 *
 * Pure: no Firebase I/O.
 */

const { deriveDiscoverEligible } = require('./discover_eligibility');
const { moduleIsTrusted } = require('./assessment_verification_flow_v1');

const POLICY = 'assessment_trust_grandfather_v1';
const VERIFICATION_SCHEMA = 'assessment_verification_v1';
const DEFAULT_CATALOG_VERSION = 'assessment_finalize_catalog_v1';
const PRESERVED_FLOW = 'pre_c2_preserved';
const MIGRATION_GRANT_REASON = 'pre_trust_migration_preserved';
const TRUSTED_COMPLETE_FLOW = 'complete';
const APPLY_CONFIRM = 'PRE_TRUST_MIGRATION_V1';
const DEFAULT_PAGE_SIZE = 200;
const MAX_PAGE_SIZE = 400;
const FIRESTORE_BATCH_LIMIT = 400;

const CLASSIFICATIONS = Object.freeze({
  grandfatherCandidate: 'grandfather_candidate',
  alreadyTrustedComplete: 'already_trusted_complete',
  alreadyPreC2Preserved: 'already_pre_c2_preserved',
  storedEligibleButFormulaFalse: 'stored_eligible_but_formula_false',
  formulaTrueButStoredFalse: 'formula_true_but_stored_false',
  notEligible: 'not_eligible',
  malformedVerification: 'malformed_verification',
});

const COUNT_KEYS = Object.freeze({
  [CLASSIFICATIONS.grandfatherCandidate]: 'grandfather_candidates',
  [CLASSIFICATIONS.alreadyTrustedComplete]: 'already_trusted_complete',
  [CLASSIFICATIONS.alreadyPreC2Preserved]: 'already_pre_c2_preserved',
  [CLASSIFICATIONS.storedEligibleButFormulaFalse]:
    'stored_eligible_but_formula_false',
  [CLASSIFICATIONS.formulaTrueButStoredFalse]: 'formula_true_but_stored_false',
  [CLASSIFICATIONS.notEligible]: 'not_eligible',
  [CLASSIFICATIONS.malformedVerification]: 'malformed_verification',
});

const FROZEN_USER_KEYS = Object.freeze([
  'discover_eligible',
  'test_completed',
  'assessment_flow_completed',
  'assessment_flow_version',
  'iq_completed',
  'eq_completed',
  'frequency_completed',
  'profile_completed',
  'active',
  'account_deletion_requested',
  'photos',
  'profile_photo_url',
]);

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function copyModule(mod) {
  if (!isPlainObject(mod)) return undefined;
  return { ...mod };
}

function moduleSlotMalformed(verification) {
  if (!isPlainObject(verification)) return false;
  for (const key of ['iq', 'eq', 'frequency']) {
    if (
      Object.prototype.hasOwnProperty.call(verification, key) &&
      verification[key] != null &&
      !isPlainObject(verification[key])
    ) {
      return true;
    }
  }
  return false;
}

function isGenuinelyTrustedComplete(verification) {
  return (
    isPlainObject(verification) &&
    moduleIsTrusted(verification.iq) &&
    moduleIsTrusted(verification.eq) &&
    moduleIsTrusted(verification.frequency)
  );
}

function existingCatalogVersion(verification) {
  if (!isPlainObject(verification)) return DEFAULT_CATALOG_VERSION;
  const raw = verification.catalog_version;
  if (typeof raw === 'string' && raw.trim() !== '') return raw;
  return DEFAULT_CATALOG_VERSION;
}

function emptyCounts() {
  return {
    total_scanned: 0,
    grandfather_candidates: 0,
    already_trusted_complete: 0,
    already_pre_c2_preserved: 0,
    stored_eligible_but_formula_false: 0,
    formula_true_but_stored_false: 0,
    not_eligible: 0,
    malformed_verification: 0,
    planned_writes: 0,
    writes_performed: 0,
  };
}

/**
 * @param {Record<string, unknown>|null|undefined} userData
 * @returns {string}
 */
function classifyGrandfatherCandidate(userData) {
  const data = isPlainObject(userData) ? userData : {};
  const verification = data.assessment_verification_v1;
  if (verification != null && !isPlainObject(verification)) {
    return CLASSIFICATIONS.malformedVerification;
  }
  if (
    isPlainObject(verification) &&
    verification.flow != null &&
    typeof verification.flow !== 'string'
  ) {
    return CLASSIFICATIONS.malformedVerification;
  }
  if (moduleSlotMalformed(verification)) {
    return CLASSIFICATIONS.malformedVerification;
  }

  const storedEligible = data.discover_eligible === true;
  const formulaEligible = deriveDiscoverEligible(data);

  if (storedEligible && !formulaEligible) {
    return CLASSIFICATIONS.storedEligibleButFormulaFalse;
  }
  if (!storedEligible && formulaEligible) {
    return CLASSIFICATIONS.formulaTrueButStoredFalse;
  }
  if (!storedEligible && !formulaEligible) {
    return CLASSIFICATIONS.notEligible;
  }

  if (isGenuinelyTrustedComplete(verification)) {
    return CLASSIFICATIONS.alreadyTrustedComplete;
  }

  const flow =
    isPlainObject(verification) && typeof verification.flow === 'string'
      ? verification.flow
      : '';
  if (flow === PRESERVED_FLOW) {
    return CLASSIFICATIONS.alreadyPreC2Preserved;
  }
  return CLASSIFICATIONS.grandfatherCandidate;
}

/**
 * @param {Record<string, unknown>|null|undefined} userData
 * @returns {{
 *   classification: string,
 *   write: { assessment_verification_v1: Record<string, unknown> } | null
 * }}
 */
function planGrandfatherWrite(userData) {
  const classification = classifyGrandfatherCandidate(userData);
  if (classification !== CLASSIFICATIONS.grandfatherCandidate) {
    return { classification, write: null };
  }

  const existing = isPlainObject(userData)
    ? userData.assessment_verification_v1
    : null;
  const next = isPlainObject(existing) ? { ...existing } : {};
  delete next.frequency_v2;
  next.schema_version = VERIFICATION_SCHEMA;
  next.flow = PRESERVED_FLOW;
  next.grant_reason = MIGRATION_GRANT_REASON;
  next.catalog_version = existingCatalogVersion(existing);
  const iq = copyModule(existing && existing.iq);
  const eq = copyModule(existing && existing.eq);
  const frequency = copyModule(existing && existing.frequency);
  if (iq) next.iq = iq;
  else delete next.iq;
  if (eq) next.eq = eq;
  else delete next.eq;
  if (frequency) next.frequency = frequency;
  else delete next.frequency;

  return {
    classification,
    write: { assessment_verification_v1: next },
  };
}

function incrementCount(counts, classification) {
  const key = COUNT_KEYS[classification];
  if (key && Object.prototype.hasOwnProperty.call(counts, key)) {
    counts[key] += 1;
  }
}

function normalizeArgv(argv) {
  const args = Array.isArray(argv) ? [...argv] : [];
  while (args.length > 0 && !String(args[0]).startsWith('-')) {
    args.shift();
  }
  return args;
}

function readIntFlag(args, name, fallback) {
  const eqPrefix = `${name}=`;
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg.startsWith(eqPrefix)) {
      const n = Number.parseInt(arg.slice(eqPrefix.length), 10);
      return Number.isFinite(n) ? n : fallback;
    }
    if (arg === name) {
      const next = args[i + 1];
      if (next && !next.startsWith('--')) {
        const n = Number.parseInt(next, 10);
        return Number.isFinite(n) ? n : fallback;
      }
    }
  }
  return fallback;
}

function readConfirm(args) {
  let confirm = '';
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg.startsWith('--confirm=')) {
      confirm = arg.slice('--confirm='.length);
    } else if (arg === '--confirm') {
      const next = args[i + 1];
      if (next && !next.startsWith('--')) confirm = next;
    }
  }
  return confirm;
}

function clampPageSize(n) {
  if (!Number.isFinite(n) || n < 1) return DEFAULT_PAGE_SIZE;
  return Math.min(Math.floor(n), MAX_PAGE_SIZE);
}

/**
 * CLI gate. Default is dry-run. Writes require --apply AND the exact confirm.
 *
 * @param {string[]} argv
 * @returns {{
 *   ok: boolean,
 *   mode: 'dry-run' | 'apply',
 *   writeEnabled: boolean,
 *   pageSize: number,
 *   error: string|null
 * }}
 */
function parseGrandfatherCliArgs(argv) {
  const args = normalizeArgv(argv);
  const apply = args.includes('--apply');
  const confirm = readConfirm(args);
  const pageSize = clampPageSize(
    readIntFlag(args, '--page-size', DEFAULT_PAGE_SIZE),
  );

  if (confirm === 'YES') {
    return {
      ok: false,
      mode: 'dry-run',
      writeEnabled: false,
      pageSize,
      error: 'never_yes',
    };
  }

  if (apply && confirm !== APPLY_CONFIRM) {
    return {
      ok: false,
      mode: 'dry-run',
      writeEnabled: false,
      pageSize,
      error: 'apply_refused',
    };
  }

  if (apply && confirm === APPLY_CONFIRM) {
    return {
      ok: true,
      mode: 'apply',
      writeEnabled: true,
      pageSize,
      error: null,
    };
  }

  return {
    ok: true,
    mode: 'dry-run',
    writeEnabled: false,
    pageSize,
    error: null,
  };
}

function assertVerificationOnlyWrite(write) {
  if (!isPlainObject(write)) {
    throw new Error('grandfather write must be an object');
  }
  const keys = Object.keys(write);
  if (keys.length !== 1 || keys[0] !== 'assessment_verification_v1') {
    throw new Error('grandfather write must only set assessment_verification_v1');
  }
  for (const frozen of FROZEN_USER_KEYS) {
    if (Object.prototype.hasOwnProperty.call(write, frozen)) {
      throw new Error(`grandfather write must not include ${frozen}`);
    }
  }
}

/**
 * @param {{
 *   listPage: (args: { startAfterId: string|null, pageSize: number }) =>
 *     Promise<Array<{ uid: string, data: Record<string, unknown> }>>,
 *   pageSize?: number,
 *   writeEnabled?: boolean,
 *   commitPage?: (writes: Array<{ uid: string, write: object }>) => Promise<number>,
 * }} opts
 */
async function runGrandfatherMigration(opts) {
  const listPage = opts && opts.listPage;
  if (typeof listPage !== 'function') {
    throw new Error('listPage is required');
  }
  const pageSize = clampPageSize(
    opts.pageSize == null ? DEFAULT_PAGE_SIZE : opts.pageSize,
  );
  const writeEnabled = opts.writeEnabled === true;
  const commitPage = opts.commitPage;
  const counts = emptyCounts();
  let startAfterId = null;

  for (;;) {
    const page = await listPage({ startAfterId, pageSize });
    if (!Array.isArray(page) || page.length === 0) break;

    const pageWrites = [];
    for (const row of page) {
      const uid = row && row.uid;
      const data = row && row.data;
      if (typeof uid !== 'string' || uid.trim() === '') continue;
      counts.total_scanned += 1;
      const planned = planGrandfatherWrite(data);
      incrementCount(counts, planned.classification);
      if (planned.write) {
        assertVerificationOnlyWrite(planned.write);
        counts.planned_writes += 1;
        pageWrites.push({ uid, write: planned.write });
      }
    }

    if (writeEnabled) {
      if (typeof commitPage !== 'function') {
        throw new Error('commitPage is required when writeEnabled');
      }
      if (pageWrites.length > 0) {
        const written = await commitPage(pageWrites);
        counts.writes_performed += Number(written) || 0;
      }
    }

    startAfterId = page[page.length - 1].uid;
    if (page.length < pageSize) break;
  }

  return counts;
}

/**
 * Applies verification-only updates. Never executed by Phase 7G.1 against
 * production; present so apply-path tests and a later gated run can share code.
 *
 * @param {{ batch: Function, doc?: Function, collection?: Function }} db
 * @param {Array<{ uid: string, write: object }>} pageWrites
 * @param {{ batchLimit?: number }} [opts]
 */
async function commitGrandfatherPage(db, pageWrites, opts = {}) {
  if (!writeEnabledGuard(opts)) {
    return 0;
  }
  if (!Array.isArray(pageWrites) || pageWrites.length === 0) return 0;
  const batchLimit = Math.min(
    Math.max(1, opts.batchLimit || FIRESTORE_BATCH_LIMIT),
    FIRESTORE_BATCH_LIMIT,
  );
  let written = 0;
  for (let i = 0; i < pageWrites.length; i += batchLimit) {
    const chunk = pageWrites.slice(i, i + batchLimit);
    const batch = db.batch();
    for (const item of chunk) {
      assertVerificationOnlyWrite(item.write);
      const ref =
        typeof db.doc === 'function'
          ? db.doc(`users/${item.uid}`)
          : db.collection('users').doc(item.uid);
      batch.update(ref, item.write);
    }
    await batch.commit();
    written += chunk.length;
  }
  return written;
}

/**
 * Extra belt-and-suspenders: commitGrandfatherPage refuses to write unless
 * the caller passes writeEnabled:true. The CLI only does that after the
 * apply+confirm gate.
 */
function writeEnabledGuard(opts) {
  return !!(opts && opts.writeEnabled === true);
}

function publicCounts(counts) {
  return {
    total_scanned: counts.total_scanned,
    grandfather_candidates: counts.grandfather_candidates,
    already_trusted_complete: counts.already_trusted_complete,
    already_pre_c2_preserved: counts.already_pre_c2_preserved,
    stored_eligible_but_formula_false: counts.stored_eligible_but_formula_false,
    formula_true_but_stored_false: counts.formula_true_but_stored_false,
    not_eligible: counts.not_eligible,
    malformed_verification: counts.malformed_verification,
    planned_writes: counts.planned_writes,
    writes_performed: counts.writes_performed,
  };
}

module.exports = {
  POLICY,
  VERIFICATION_SCHEMA,
  DEFAULT_CATALOG_VERSION,
  PRESERVED_FLOW,
  MIGRATION_GRANT_REASON,
  TRUSTED_COMPLETE_FLOW,
  APPLY_CONFIRM,
  DEFAULT_PAGE_SIZE,
  MAX_PAGE_SIZE,
  FIRESTORE_BATCH_LIMIT,
  CLASSIFICATIONS,
  FROZEN_USER_KEYS,
  classifyGrandfatherCandidate,
  planGrandfatherWrite,
  parseGrandfatherCliArgs,
  emptyCounts,
  runGrandfatherMigration,
  commitGrandfatherPage,
  publicCounts,
  isPlainObject,
};
