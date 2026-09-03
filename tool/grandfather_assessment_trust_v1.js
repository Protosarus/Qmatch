#!/usr/bin/env node
/**
 * Legacy assessment-trust grandfather migration v1
 *
 * Default: DRY-RUN (reads only). Never writes unless BOTH gates are passed:
 *
 *   node tool/grandfather_assessment_trust_v1.js \
 *     --apply --confirm=PRE_TRUST_MIGRATION_V1
 *
 * Phase 7G.1: implement and test the apply path. Do NOT run --apply against
 * production in this phase.
 *
 *   export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
 *   node tool/grandfather_assessment_trust_v1.js
 *
 * Reports aggregate counts only. Does not print emails, names, phones,
 * profile payloads, or assessment answers.
 */

'use strict';

const fs = require('fs');
const path = require('path');
const { createRequire } = require('module');

const ROOT = path.resolve(__dirname, '..');
const PROJECT_ID = 'qmatch-53d62';
const CREDENTIALS_ENV = 'QMATCH_FIRESTORE_ADMIN_CREDENTIALS';
const USERS_COLLECTION = 'users';
const PROGRESS_EVERY = 500;

const requireFromFunctions = createRequire(
  path.join(ROOT, 'functions', 'package.json'),
);

const {
  POLICY,
  APPLY_CONFIRM,
  parseGrandfatherCliArgs,
  runGrandfatherMigration,
  commitGrandfatherPage,
  publicCounts,
} = require(path.join(
  ROOT,
  'functions',
  'src',
  'assessment_trust_grandfather_v1.js',
));

function abort(message) {
  console.error(`ERROR: ${message}`);
  process.exit(2);
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

function createListUsersPage(db, FieldPath) {
  return async function listUsersPage({ startAfterId, pageSize }) {
    let query = db
      .collection(USERS_COLLECTION)
      .orderBy(FieldPath.documentId())
      .limit(pageSize);
    if (startAfterId) {
      query = query.startAfter(startAfterId);
    }
    const snap = await query.get();
    return snap.docs.map((doc) => ({
      uid: doc.id,
      data: doc.data() || {},
    }));
  };
}

async function main(argv = process.argv) {
  const parsed = parseGrandfatherCliArgs(argv);
  if (!parsed.ok) {
    if (parsed.error === 'never_yes') {
      abort('Never accept --confirm YES');
    }
    abort(
      `Apply refused. Required: --apply --confirm=${APPLY_CONFIRM}`,
    );
  }

  const modeLabel = parsed.writeEnabled ? 'APPLY' : 'DRY-RUN';
  console.log(`MODE: ${modeLabel}`);
  console.log(`policy: ${POLICY}`);

  const serviceAccount = loadServiceAccount();
  console.log(`Firebase project verified: ${PROJECT_ID}`);

  const db = initFirestore(serviceAccount);
  const { FieldPath } = requireFromFunctions('firebase-admin/firestore');

  let scannedSinceLog = 0;
  const listPage = async (args) => {
    const page = await createListUsersPage(db, FieldPath)(args);
    scannedSinceLog += page.length;
    if (scannedSinceLog >= PROGRESS_EVERY) {
      console.log(`… scanned progress checkpoint (${PROGRESS_EVERY} page rows)`);
      scannedSinceLog = 0;
    }
    return page;
  };

  const counts = await runGrandfatherMigration({
    listPage,
    pageSize: parsed.pageSize,
    writeEnabled: parsed.writeEnabled,
    commitPage: parsed.writeEnabled
      ? (writes) =>
          commitGrandfatherPage(db, writes, { writeEnabled: true })
      : undefined,
  });

  const report = {
    policy: POLICY,
    project_id: PROJECT_ID,
    mode: parsed.writeEnabled ? 'apply' : 'dry_run_read_only',
    writes_performed: parsed.writeEnabled ? counts.writes_performed : false,
    page_size: parsed.pageSize,
    ...publicCounts(counts),
  };
  if (!parsed.writeEnabled) {
    report.writes_performed = false;
    report.writes_performed_count = 0;
  }

  console.log(JSON.stringify(report, null, 2));

  if (!parsed.writeEnabled) {
    console.log(
      '\nDRY-RUN complete. No Firestore writes. Apply was not invoked.',
    );
  }
}

if (require.main === module) {
  main().catch((err) => {
    abort(err && err.message ? err.message : 'grandfather tool failed');
  });
}

module.exports = {
  parseGrandfatherCliArgs,
  APPLY_CONFIRM,
  main,
};
