'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const {
  deriveDiscoverEligible,
  hasTrustedAssessmentDiscoverGrant,
} = require('../src/discover_eligibility');
const {
  hasTrustedV1Battery,
  hasPreTrustMigrationGrant,
} = require('../src/assessment_verification_flow_v1');

const ROOT = path.resolve(__dirname, '../..');
const DRY_RUN = path.join(ROOT, 'tool/trusted_discover_cutover_dry_run_v1.py');
const POLICY_PY = path.join(ROOT, 'tool/trusted_discover_cutover_policy_v1.py');
const FIXTURES = path.join(
  __dirname,
  'fixtures/trusted_discover_cutover_v1.json',
);

const PII_KEYS = [
  'uid',
  'email',
  'name',
  'display_name',
  'phone',
  'phone_number',
  'photos',
  'profile_photo_url',
  'answers',
];

const EXPECTED_COUNTS = [
  'total_users_scanned',
  'stored_true_derived_true',
  'stored_false_derived_false',
  'stored_true_derived_false',
  'stored_false_derived_true',
  'trusted_v1_eligible',
  'grandfather_eligible',
  'derived_eligible_total',
  'mismatches_total',
];

function spawnPython(script, args, opts = {}) {
  return spawnSync('python3', [script, ...args], {
    cwd: ROOT,
    encoding: 'utf8',
    input: opts.input,
    env: { ...process.env, ...opts.env },
  });
}

function jsonLines(stdout) {
  const trimmed = String(stdout || '').trim();
  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start < 0 || end < start) return null;
  return JSON.parse(trimmed.slice(start, end + 1));
}

function jsCase(row) {
  const user = row.user;
  const derived = deriveDiscoverEligible(user);
  const verification = user && user.assessment_verification_v1;
  return {
    id: row.id,
    derived,
    trusted_v1: derived && hasTrustedV1Battery(verification),
    grandfather: derived && hasPreTrustMigrationGrant(verification),
  };
}

describe('trusted_discover_cutover Python tool safety', () => {
  const drySrc = fs.readFileSync(DRY_RUN, 'utf8');

  it('dry-run default does not connect or write', () => {
    const result = spawnPython(DRY_RUN, []);
    assert.strictEqual(result.status, 0, result.stderr);
    assert.match(result.stdout, /DRY RUN ONLY/);
    assert.doesNotMatch(result.stdout, /scanned_at_utc/);
    assert.doesNotMatch(result.stderr, /firebase_admin/);
    assert.doesNotMatch(drySrc, /^import firebase_admin/m);
    assert.match(drySrc, /if not args\.execute_dry_run/);
  });

  it('dry-run implementation contains no mutation calls', () => {
    const result = spawnPython(DRY_RUN, ['--self-check-only']);
    assert.strictEqual(result.status, 0, result.stderr);
    const body = jsonLines(result.stdout);
    assert.strictEqual(body.mutation_calls, false);
    assert.match(drySrc, /FORBIDDEN_CALL_ATTRS/);
    assert.match(drySrc, /assert_no_mutation_calls/);
    for (const attr of ['delete', 'update', 'set', 'commit']) {
      assert.doesNotMatch(
        drySrc,
        new RegExp(`\\.${attr}\\(`),
        `dry-run must not call .${attr}(`,
      );
    }
  });

  it('no PII in aggregate report schema', () => {
    const result = spawnSync(
      'python3',
      [
        '-c',
        [
          'import json,sys',
          'sys.path.insert(0,"tool")',
          'from trusted_discover_cutover_policy_v1 import empty_counts, public_counts, REPORT_COUNT_KEYS',
          'print(json.dumps({"keys": list(public_counts(empty_counts()).keys()), "report": list(REPORT_COUNT_KEYS)}))',
        ].join(';'),
      ],
      { cwd: ROOT, encoding: 'utf8' },
    );
    assert.strictEqual(result.status, 0, result.stderr);
    const body = JSON.parse(result.stdout);
    assert.deepStrictEqual(body.keys, EXPECTED_COUNTS);
    assert.deepStrictEqual(body.report, EXPECTED_COUNTS);
    for (const key of PII_KEYS) {
      assert.strictEqual(body.keys.includes(key), false, key);
    }
    assert.doesNotMatch(drySrc.toLowerCase(), /email/);
    assert.doesNotMatch(drySrc.toLowerCase(), /phone_number/);
    assert.match(drySrc, /total_users_scanned/);
    assert.match(drySrc, /public_counts\(counts\)/);
  });

  it('does not use client completion flags or Frequency V2 as grant', () => {
    assert.doesNotMatch(drySrc, /test_completed == true/);
    assert.doesNotMatch(drySrc, /assessment_flow_completed == true/);
    const policySrc = fs.readFileSync(POLICY_PY, 'utf8');
    assert.match(policySrc, /has_trusted_v1_battery/);
    assert.match(policySrc, /pre_c2_preserved/);
    assert.match(policySrc, /pre_trust_migration_preserved/);
    assert.doesNotMatch(
      policySrc,
      /data\.get\("test_completed"\) is True/,
    );
    assert.ok(!policySrc.includes('runtime_selectable'));
  });
});

describe('trusted_discover_cutover JS/Python parity', () => {
  it('representative fixtures match JS deriveDiscoverEligible', () => {
    const fixtures = JSON.parse(fs.readFileSync(FIXTURES, 'utf8'));
    const required = [
      'pre_c2_grandfather',
      'full_trusted_v1',
      'iq_only',
      'iq_eq_only',
      'flow_complete_only',
      'test_completed_only',
      'assessment_flow_completed_only',
      'inactive',
      'no_photo',
      'profile_incomplete',
      'deletion_requested',
      'frequency_v2_only',
    ];
    const ids = fixtures.cases.map((row) => row.id);
    for (const id of required) {
      assert.strictEqual(ids.includes(id), true, id);
    }

    const py = spawnPython(POLICY_PY, ['--parity-stdin'], {
      input: JSON.stringify(fixtures),
    });
    assert.strictEqual(py.status, 0, py.stderr + py.stdout);
    const pyBody = JSON.parse(py.stdout);
    assert.strictEqual(pyBody.cases.length, fixtures.cases.length);

    const jsCases = fixtures.cases.map(jsCase);
    assert.deepStrictEqual(
      JSON.parse(JSON.stringify(pyBody.cases)),
      JSON.parse(JSON.stringify(jsCases)),
    );

    const byId = Object.fromEntries(jsCases.map((row) => [row.id, row]));
    assert.strictEqual(byId.pre_c2_grandfather.derived, true);
    assert.strictEqual(byId.pre_c2_grandfather.grandfather, true);
    assert.strictEqual(byId.pre_c2_grandfather.trusted_v1, false);
    assert.strictEqual(byId.full_trusted_v1.derived, true);
    assert.strictEqual(byId.full_trusted_v1.trusted_v1, true);
    assert.strictEqual(byId.iq_only.derived, false);
    assert.strictEqual(byId.iq_eq_only.derived, false);
    assert.strictEqual(byId.flow_complete_only.derived, false);
    assert.strictEqual(byId.test_completed_only.derived, false);
    assert.strictEqual(byId.assessment_flow_completed_only.derived, false);
    assert.strictEqual(byId.inactive.derived, false);
    assert.strictEqual(byId.no_photo.derived, false);
    assert.strictEqual(byId.profile_incomplete.derived, false);
    assert.strictEqual(byId.deletion_requested.derived, false);
    assert.strictEqual(byId.frequency_v2_only.derived, false);
    assert.strictEqual(
      hasTrustedAssessmentDiscoverGrant(fixtures.cases.find((r) => r.id === 'frequency_v2_only').user),
      false,
    );
  });
});
