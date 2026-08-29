#!/usr/bin/env node
/**
 * public_profiles backfill v1
 *
 * Default: DRY-RUN (reads only). Reuses live
 * functions/src/public_profiles_projection.js — no whitelist copy.
 *
 *   export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
 *   node tool/public_profiles_backfill_v1.js
 *
 * Execute is implemented but must not be used unless both flags are passed:
 *   node tool/public_profiles_backfill_v1.js --execute --confirm BACKFILL_PUBLIC_PROFILES
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const ROOT = path.resolve(__dirname, '..');
const PROJECT_ID = 'qmatch-53d62';
const CREDENTIALS_ENV = 'QMATCH_FIRESTORE_ADMIN_CREDENTIALS';
const EXECUTE_CONFIRM = 'BACKFILL_PUBLIC_PROFILES';
const USERS_COLLECTION = 'users';
const PUBLIC_COLLECTION = 'public_profiles';
const SAMPLE_LIMIT = 20;
const PROGRESS_EVERY = 500;
const POLICY = 'public_profiles_backfill_v1';

const requireFromFunctions = createRequire(
  path.join(ROOT, 'functions', 'package.json'),
);

const {
  buildPublicProfileProjection,
  projectionsEqual,
  PUBLIC_PROFILE_KEYS,
} = require(path.join(ROOT, 'functions', 'src', 'public_profiles_projection.js'));

const OPTIONAL_STRING_KEYS = Object.freeze([
  'home_country',
  'home_city',
  'name',
  'bio',
  'profile_photo_url',
  'occupation',
  'company',
  'education',
  'school',
  'education_field',
  'anthem_title',
  'anthem_artist',
]);

const ALWAYS_PRESENT_ARRAY_KEYS = Object.freeze(['photos', 'interests']);

const EXPLICIT_FORBIDDEN_KEYS = Object.freeze([
  'email',
  'phone_number',
  'auth_provider',
  'location',
  'location_text',
  'age_range',
  'distance_preference',
  'frequency_vector',
  'vector',
  'iq_score',
  'eq_score',
  'iq_normalized',
  'eq_normalized',
  'frequency_score',
  'frequency_tags',
  'frequency_type',
  'compatibility',
  'compat',
  'compatibility_score',
  'account_deletion_requested',
  'account_deletion_requested_at',
  'moderation_state',
  'moderation_status',
  'fcm_token',
  'fcm_tokens',
  'gender',
  'looking_for',
  'archetype',
  'category',
  'active',
  'profile_completed',
  'test_completed',
  'assessment_flow_completed',
  'last_active_at',
]);

const WHITELIST = new Set(PUBLIC_PROFILE_KEYS);

function abort(message) {
  console.error(`ERROR: ${message}`);
  process.exit(2);
}

function parseArgs(argv) {
  const args = argv.slice(2);
  const execute = args.includes('--execute');
  const confirmIdx = args.indexOf('--confirm');
  const confirm =
    confirmIdx >= 0 && args[confirmIdx + 1] && !args[confirmIdx + 1].startsWith('--')
      ? args[confirmIdx + 1]
      : '';

  if (confirm === 'YES') {
    abort('Never accept --confirm YES');
  }

  if (execute) {
    if (confirm !== EXECUTE_CONFIRM) {
      abort(
        `Execute refused. Required: --execute --confirm ${EXECUTE_CONFIRM}`,
      );
    }
    return { mode: 'execute' };
  }

  return { mode: 'dry-run' };
}

function loadServiceAccount() {
  const credPath = (process.env[CREDENTIALS_ENV] || '').trim();
  if (!credPath) {
    abort(`${CREDENTIALS_ENV} is not set`);
  }
  if (!path.isAbsolute(credPath)) {
    abort('credential path must be absolute');
  }
  if (!fs.existsSync(credPath) || !fs.statSync(credPath).isFile()) {
    abort('credential file not found');
  }

  let resolved;
  try {
    resolved = fs.realpathSync(credPath);
  } catch (_err) {
    abort('credential file not readable');
  }

  const repoRoot = fs.realpathSync(ROOT);
  const rel = path.relative(repoRoot, resolved);
  if (rel && !rel.startsWith('..') && !path.isAbsolute(rel)) {
    abort('credentials must live outside the repo');
  }

  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(resolved, 'utf8'));
  } catch (_err) {
    abort('credential file is not valid JSON');
  }

  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    abort('credential JSON must be an object');
  }
  if (parsed.project_id !== PROJECT_ID) {
    abort(`service account project_id is not ${PROJECT_ID}`);
  }

  return parsed;
}

function initFirestore(serviceAccount) {
  const { initializeApp, getApps, cert } = requireFromFunctions(
    'firebase-admin/app',
  );
  const { getFirestore } = requireFromFunctions('firebase-admin/firestore');

  if (getApps().length > 0) {
    abort('Firebase app already initialized; refusing to continue');
  }

  initializeApp({
    credential: cert(serviceAccount),
    projectId: PROJECT_ID,
  });

  return getFirestore();
}

function forbiddenKeyNames(data) {
  if (!data || typeof data !== 'object') return [];
  const found = [];
  for (const key of Object.keys(data)) {
    if (!WHITELIST.has(key)) found.push(key);
  }
  return found.sort();
}

function desiredInvariantErrors(desired) {
  const errors = [];
  if (!desired || typeof desired !== 'object') {
    return ['projection_not_object'];
  }
  for (const key of Object.keys(desired)) {
    if (!WHITELIST.has(key)) {
      errors.push(`non_whitelist_key:${key}`);
    }
  }
  for (const key of EXPLICIT_FORBIDDEN_KEYS) {
    if (Object.prototype.hasOwnProperty.call(desired, key)) {
      errors.push(`explicit_forbidden:${key}`);
    }
  }
  return errors;
}

function fingerprint(value) {
  if (value === undefined) return { kind: 'undefined' };
  if (value === null) return { kind: 'null' };
  if (Array.isArray(value)) {
    return { kind: 'array', json: JSON.stringify(value) };
  }
  if (value && typeof value === 'object') {
    const sorted = {};
    for (const key of Object.keys(value).sort()) {
      sorted[key] = value[key];
    }
    return { kind: 'object', json: JSON.stringify(sorted) };
  }
  return { kind: typeof value, json: JSON.stringify(value) };
}

function fingerprintsEqual(a, b) {
  return a.kind === b.kind && a.json === b.json;
}

function changedKeyNames(existing, desired) {
  const keys = new Set([
    ...Object.keys(existing || {}),
    ...Object.keys(desired || {}),
  ]);
  const changed = [];
  for (const key of [...keys].sort()) {
    const left = Object.prototype.hasOwnProperty.call(existing || {}, key)
      ? existing[key]
      : undefined;
    const right = Object.prototype.hasOwnProperty.call(desired || {}, key)
      ? desired[key]
      : undefined;
    if (!fingerprintsEqual(fingerprint(left), fingerprint(right))) {
      changed.push(key);
    }
  }
  return changed;
}

function unexpectedTypeFields(data) {
  const fields = [];
  const src = data && typeof data === 'object' ? data : {};

  if (typeof src.discover_eligible !== 'boolean') {
    fields.push('discover_eligible');
  }

  for (const key of OPTIONAL_STRING_KEYS) {
    if (Object.prototype.hasOwnProperty.call(src, key)) {
      const value = src[key];
      if (typeof value !== 'string' || !value.trim()) {
        fields.push(key);
      }
    }
  }

  if (Object.prototype.hasOwnProperty.call(src, 'age')) {
    const age = src.age;
    if (
      typeof age !== 'number' ||
      !Number.isFinite(age) ||
      !Number.isInteger(age)
    ) {
      fields.push('age');
    }
  }

  for (const key of ALWAYS_PRESENT_ARRAY_KEYS) {
    const value = src[key];
    if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
      fields.push(key);
    }
  }

  return fields;
}

function pushSample(list, item) {
  if (list.length < SAMPLE_LIMIT) list.push(item);
}

function printSample(title, rows) {
  console.log(`${title} (showing ${rows.length}, cap ${SAMPLE_LIMIT})`);
  if (rows.length === 0) {
    console.log('  (none)');
    return;
  }
  for (const row of rows) {
    if (typeof row === 'string') {
      console.log(`  ${row}`);
    } else {
      console.log(`  ${JSON.stringify(row)}`);
    }
  }
}

async function runDryRun(db) {
  const userIds = new Set();
  const counters = {
    processed_users: 0,
    create: 0,
    update: 0,
    skip: 0,
    errors: 0,
    existing_public_profiles: 0,
    forbidden_public_docs: 0,
    forbidden_keys_total: 0,
    discover_eligible_public_true_source_not_true: 0,
    unexpected_public_types: 0,
    orphan_public_profiles: 0,
    orphan_discoverable: 0,
  };

  const samples = {
    CREATE: [],
    UPDATE: [],
    FORBIDDEN: [],
    TYPE_ERROR: [],
    ELIGIBILITY_MISMATCH: [],
    ORPHAN: [],
  };

  const selectFields = [...PUBLIC_PROFILE_KEYS];
  const usersQuery = db.collection(USERS_COLLECTION).select(...selectFields);

  for await (const userDoc of usersQuery.stream()) {
    counters.processed_users += 1;
    const uid = userDoc.id;
    userIds.add(uid);

    try {
      const userData = userDoc.data() || {};
      const desired = buildPublicProfileProjection(userData);
      const invariant = desiredInvariantErrors(desired);
      if (invariant.length > 0) {
        throw new Error('desired_projection_invariant_failed');
      }

      const publicSnap = await db.collection(PUBLIC_COLLECTION).doc(uid).get();
      if (!publicSnap.exists) {
        counters.create += 1;
        pushSample(samples.CREATE, uid);
      } else {
        const existing = publicSnap.data() || {};
        if (projectionsEqual(existing, desired)) {
          counters.skip += 1;
        } else {
          counters.update += 1;
          pushSample(samples.UPDATE, {
            uid,
            changed_keys: changedKeyNames(existing, desired),
          });
        }

        if (
          existing.discover_eligible === true &&
          userData.discover_eligible !== true
        ) {
          counters.discover_eligible_public_true_source_not_true += 1;
          pushSample(samples.ELIGIBILITY_MISMATCH, uid);
        }
      }
    } catch (_err) {
      counters.errors += 1;
    }

    if (counters.processed_users % PROGRESS_EVERY === 0) {
      console.log(`… scanned ${counters.processed_users} users (progress)`);
    }
  }

  const publicQuery = db.collection(PUBLIC_COLLECTION);
  for await (const publicDoc of publicQuery.stream()) {
    counters.existing_public_profiles += 1;
    const uid = publicDoc.id;
    const existing = publicDoc.data() || {};

    const forbidden = forbiddenKeyNames(existing);
    if (forbidden.length > 0) {
      counters.forbidden_public_docs += 1;
      counters.forbidden_keys_total += forbidden.length;
      pushSample(samples.FORBIDDEN, {
        uid,
        forbidden_keys: forbidden,
      });
    }

    const typeFields = unexpectedTypeFields(existing);
    if (typeFields.length > 0) {
      counters.unexpected_public_types += 1;
      pushSample(samples.TYPE_ERROR, {
        uid,
        fields: typeFields,
      });
    }

    if (!userIds.has(uid)) {
      counters.orphan_public_profiles += 1;
      const isDiscoverable = existing.discover_eligible === true;
      if (isDiscoverable) counters.orphan_discoverable += 1;

      const nonBooleanEligible =
        typeof existing.discover_eligible !== 'boolean';
      let classLabel = 'EXPECTED_TOMBSTONE';
      if (isDiscoverable) {
        classLabel = 'HIGH_PRIORITY_DISCOVERABLE';
      } else if (nonBooleanEligible || forbidden.length > 0 || typeFields.length > 0) {
        classLabel = 'UNEXPECTED';
      } else if (existing.discover_eligible === false) {
        classLabel = 'EXPECTED_TOMBSTONE';
      }

      pushSample(samples.ORPHAN, { uid, class: classLabel });
    }
  }

  console.log(
    JSON.stringify(
      {
        policy: POLICY,
        project_id: PROJECT_ID,
        mode: 'dry_run_read_only',
        writes_performed: false,
        ...counters,
      },
      null,
      2,
    ),
  );

  printSample('CREATE', samples.CREATE);
  printSample('UPDATE', samples.UPDATE);
  printSample('FORBIDDEN', samples.FORBIDDEN);
  printSample('TYPE_ERROR', samples.TYPE_ERROR);
  printSample('ELIGIBILITY_MISMATCH', samples.ELIGIBILITY_MISMATCH);
  printSample('ORPHAN', samples.ORPHAN);

  console.log(
    '\nDRY-RUN complete. No Firestore writes. Execute was not invoked.',
  );
}

async function runExecute(db) {
  let processed = 0;
  let written = 0;
  let skipped = 0;
  let errors = 0;

  for await (const userDoc of db.collection(USERS_COLLECTION).stream()) {
    processed += 1;
    const uid = userDoc.id;
    const userRef = db.collection(USERS_COLLECTION).doc(uid);
    const publicRef = db.collection(PUBLIC_COLLECTION).doc(uid);

    try {
      const outcome = await db.runTransaction(async (tx) => {
        const currentUser = await tx.get(userRef);
        if (!currentUser.exists) {
          return 'skipped';
        }
        const desired = buildPublicProfileProjection(currentUser.data() || {});
        const invariant = desiredInvariantErrors(desired);
        if (invariant.length > 0) {
          throw new Error('desired_projection_invariant_failed');
        }
        const currentPublic = await tx.get(publicRef);
        const existing = currentPublic.exists ? currentPublic.data() || {} : null;
        if (existing && projectionsEqual(existing, desired)) {
          return 'skipped';
        }
        tx.set(publicRef, desired);
        return 'written';
      });
      if (outcome === 'written') written += 1;
      else skipped += 1;
    } catch (_err) {
      errors += 1;
    }

    if (processed % PROGRESS_EVERY === 0) {
      console.log(`… execute scanned ${processed} users (progress)`);
    }
  }

  console.log(
    JSON.stringify(
      {
        policy: POLICY,
        project_id: PROJECT_ID,
        mode: 'execute',
        processed_users: processed,
        written,
        skipped,
        errors,
      },
      null,
      2,
    ),
  );
}

async function main() {
  const { mode } = parseArgs(process.argv);
  console.log(`MODE: ${mode === 'execute' ? 'EXECUTE' : 'DRY-RUN'}`);

  const serviceAccount = loadServiceAccount();
  console.log(`Firebase project verified: ${PROJECT_ID}`);

  const db = initFirestore(serviceAccount);

  if (mode === 'execute') {
    await runExecute(db);
    return;
  }

  await runDryRun(db);
}

main().catch((err) => {
  abort(err && err.message ? 'dry-run failed' : 'dry-run failed');
});
