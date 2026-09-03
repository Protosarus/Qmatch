'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const {
  APPLY_CONFIRM,
  CLASSIFICATIONS,
  FROZEN_USER_KEYS,
  planGrandfatherWrite,
} = require('../src/assessment_trust_grandfather_v1');

const ROOT = path.resolve(__dirname, '../..');
const DRY_RUN = path.join(ROOT, 'tool/assessment_trust_grandfather_dry_run_v1.py');
const EXECUTE = path.join(ROOT, 'tool/assessment_trust_grandfather_execute_v1.py');
const POLICY_PY = path.join(ROOT, 'tool/assessment_trust_grandfather_policy_v1.py');
const FIXTURES = path.join(
  __dirname,
  'fixtures/assessment_trust_grandfather_v1.json',
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

describe('assessment_trust_grandfather Python tool safety', () => {
  const drySrc = fs.readFileSync(DRY_RUN, 'utf8');
  const execSrc = fs.readFileSync(EXECUTE, 'utf8');

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

  it('execute without flags refuses', () => {
    const result = spawnPython(EXECUTE, []);
    assert.strictEqual(result.status, 2, result.stderr);
    assert.match(result.stdout, /Refusing without --execute --confirm/);
  });

  it('--execute only refuses', () => {
    const result = spawnPython(EXECUTE, ['--execute']);
    assert.strictEqual(result.status, 2, result.stderr);
    assert.match(result.stdout, /Refusing/);
    const check = spawnPython(EXECUTE, ['--self-check-only', '--execute']);
    assert.strictEqual(jsonLines(check.stdout).write_mode, false);
  });

  it('confirmation only refuses', () => {
    const result = spawnPython(EXECUTE, ['--confirm', APPLY_CONFIRM]);
    assert.strictEqual(result.status, 2, result.stderr);
    assert.match(result.stdout, /Refusing/);
    const check = spawnPython(EXECUTE, [
      '--self-check-only',
      '--confirm',
      APPLY_CONFIRM,
    ]);
    assert.strictEqual(jsonLines(check.stdout).write_mode, false);
  });

  it('wrong confirmation refuses', () => {
    const yes = spawnPython(EXECUTE, ['--execute', '--confirm', 'YES']);
    assert.strictEqual(yes.status, 2, yes.stderr);
    const wrong = spawnPython(EXECUTE, [
      '--execute',
      '--confirm',
      'PRE_TRUST_MIGRATION',
    ]);
    assert.strictEqual(wrong.status, 2, wrong.stderr);
    const check = spawnPython(EXECUTE, [
      '--self-check-only',
      '--execute',
      '--confirm',
      'YES',
    ]);
    assert.strictEqual(jsonLines(check.stdout).write_mode, false);
  });

  it('exact --execute + --confirm PRE_TRUST_MIGRATION_V1 enables write mode', () => {
    const check = spawnPython(EXECUTE, [
      '--self-check-only',
      '--execute',
      '--confirm',
      APPLY_CONFIRM,
    ]);
    assert.strictEqual(check.status, 0, check.stderr);
    const body = jsonLines(check.stdout);
    assert.strictEqual(body.write_mode, true);
    assert.match(execSrc, /--execute/);
    assert.match(execSrc, /PRE_TRUST_MIGRATION_V1/);
    assert.match(execSrc, /Do NOT run against production/);
  });

  it('execute planner writes only assessment_verification_v1', () => {
    const fixtures = JSON.parse(fs.readFileSync(FIXTURES, 'utf8'));
    const candidate = fixtures.cases.find(
      (row) => row.id === 'eligible_legacy_candidate',
    );
    const planned = planGrandfatherWrite(candidate.user);
    assert.deepStrictEqual(Object.keys(planned.write), [
      'assessment_verification_v1',
    ]);
    for (const frozen of FROZEN_USER_KEYS) {
      assert.strictEqual(
        Object.prototype.hasOwnProperty.call(planned.write, frozen),
        false,
        frozen,
      );
    }
    assert.match(execSrc, /assert_verification_only_write\(write\)/);
    assert.match(execSrc, /batch\.update\(doc\.reference, write\)/);
    assert.doesNotMatch(execSrc, /["']discover_eligible["']\s*:/);
    assert.doesNotMatch(execSrc, /["']test_completed["']\s*:/);
    assert.doesNotMatch(execSrc, /["']assessment_flow_completed["']\s*:/);
    assert.doesNotMatch(execSrc, /["']updated_at["']\s*:/);
  });

  it('repeated candidate processing is idempotent', () => {
    const fixtures = JSON.parse(fs.readFileSync(FIXTURES, 'utf8'));
    const candidate = fixtures.cases.find((row) => row.id === 'legacy_iq_eq');
    const first = planGrandfatherWrite(candidate.user);
    assert.ok(first.write);
    const applied = {
      ...candidate.user,
      ...first.write,
    };
    const second = planGrandfatherWrite(applied);
    assert.strictEqual(
      second.classification,
      CLASSIFICATIONS.alreadyPreC2Preserved,
    );
    assert.strictEqual(second.write, null);
    const third = planGrandfatherWrite(applied);
    assert.deepStrictEqual(second, third);
  });

  it('no PII in aggregate report schema', () => {
    const result = spawnSync(
      'python3',
      [
        '-c',
        [
          'import json,sys',
          'sys.path.insert(0,"tool")',
          'from assessment_trust_grandfather_policy_v1 import empty_counts, public_counts, REPORT_COUNT_KEYS',
          'print(json.dumps({"keys": list(public_counts(empty_counts()).keys()), "report": list(REPORT_COUNT_KEYS)}))',
        ].join(';'),
      ],
      { cwd: ROOT, encoding: 'utf8' },
    );
    assert.strictEqual(result.status, 0, result.stderr);
    const body = JSON.parse(result.stdout);
    const expected = [
      'total_users_scanned',
      'grandfather_candidates',
      'already_trusted_complete',
      'already_pre_c2_preserved',
      'stored_eligible_but_formula_false',
      'formula_true_but_stored_false',
      'not_eligible',
      'malformed_verification',
      'planned_writes',
    ];
    assert.deepStrictEqual(body.keys, expected);
    assert.deepStrictEqual(body.report, expected);
    for (const key of PII_KEYS) {
      assert.strictEqual(body.keys.includes(key), false, key);
    }
    assert.doesNotMatch(drySrc.toLowerCase(), /email/);
    assert.doesNotMatch(drySrc.toLowerCase(), /phone/);
    assert.doesNotMatch(execSrc, /\.email/);
    assert.doesNotMatch(execSrc, /phone_number/);
    assert.match(drySrc, /total_users_scanned/);
    assert.match(drySrc, /public_counts\(counts\)/);
  });
});

describe('assessment_trust_grandfather JS/Python parity', () => {
  it('representative fixtures match the JS planner', () => {
    const fixtures = JSON.parse(fs.readFileSync(FIXTURES, 'utf8'));
    const required = [
      'eligible_legacy_candidate',
      'inactive',
      'deletion_requested',
      'missing_photo',
      'stored_false_formula_true',
      'trusted_complete',
      'pre_c2_preserved',
      'legacy_iq_eq',
      'malformed_verification',
      'existing_iq_only_proof',
      'existing_iq_eq_proof',
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

    const jsCases = fixtures.cases.map((row) => {
      const planned = planGrandfatherWrite(row.user);
      return {
        id: row.id,
        classification: planned.classification,
        write: planned.write,
      };
    });

    assert.deepStrictEqual(
      JSON.parse(JSON.stringify(pyBody.cases)),
      JSON.parse(JSON.stringify(jsCases)),
    );

    const byId = Object.fromEntries(jsCases.map((row) => [row.id, row]));
    assert.strictEqual(
      byId.eligible_legacy_candidate.classification,
      CLASSIFICATIONS.grandfatherCandidate,
    );
    assert.ok(byId.eligible_legacy_candidate.write);
    assert.strictEqual(
      byId.inactive.classification,
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(byId.inactive.write, null);
    assert.strictEqual(
      byId.deletion_requested.classification,
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(
      byId.missing_photo.classification,
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(
      byId.stored_false_formula_true.classification,
      CLASSIFICATIONS.formulaTrueButStoredFalse,
    );
    assert.strictEqual(
      byId.trusted_complete.classification,
      CLASSIFICATIONS.alreadyTrustedComplete,
    );
    assert.strictEqual(
      byId.pre_c2_preserved.classification,
      CLASSIFICATIONS.alreadyPreC2Preserved,
    );
    assert.strictEqual(
      byId.legacy_iq_eq.classification,
      CLASSIFICATIONS.grandfatherCandidate,
    );
    assert.strictEqual(
      byId.legacy_iq_eq.write.assessment_verification_v1.flow,
      'pre_c2_preserved',
    );
    assert.deepStrictEqual(
      byId.legacy_iq_eq.write.assessment_verification_v1.iq,
      fixtures.cases.find((row) => row.id === 'legacy_iq_eq').user
        .assessment_verification_v1.iq,
    );
    assert.strictEqual(
      byId.malformed_verification.classification,
      CLASSIFICATIONS.malformedVerification,
    );
    assert.strictEqual(
      byId.existing_iq_only_proof.write.assessment_verification_v1.iq.status,
      'verified',
    );
    assert.strictEqual(
      byId.existing_iq_only_proof.write.assessment_verification_v1
        .server_owned_marker,
      'keep-me',
    );
    assert.strictEqual(
      byId.existing_iq_eq_proof.write.assessment_verification_v1.eq.session_id,
      'eq_pair',
    );
    assert.strictEqual(
      Object.prototype.hasOwnProperty.call(
        byId.existing_iq_only_proof.write.assessment_verification_v1,
        'frequency_v2',
      ),
      false,
    );
  });
});
