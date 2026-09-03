'use strict';

const assert = require('assert');
const { MemoryFirestore } = require('./memory_firestore');
const { deriveDiscoverEligible } = require('../src/discover_eligibility');
const {
  POLICY,
  VERIFICATION_SCHEMA,
  DEFAULT_CATALOG_VERSION,
  PRESERVED_FLOW,
  MIGRATION_GRANT_REASON,
  APPLY_CONFIRM,
  CLASSIFICATIONS,
  FROZEN_USER_KEYS,
  classifyGrandfatherCandidate,
  planGrandfatherWrite,
  parseGrandfatherCliArgs,
  runGrandfatherMigration,
  commitGrandfatherPage,
} = require('../src/assessment_trust_grandfather_v1');

function eligibleUser(overrides = {}) {
  return {
    active: true,
    discover_eligible: true,
    profile_completed: true,
    test_completed: true,
    assessment_flow_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    photos: ['https://example.com/p.jpg'],
    account_deletion_requested: false,
    iq_completed: true,
    eq_completed: true,
    frequency_completed: true,
    assessment_flow_version: 'v2',
    ...overrides,
  };
}

function frozenSnapshot(data) {
  const out = {};
  for (const key of FROZEN_USER_KEYS) out[key] = data[key];
  return out;
}

function verifiedModule(id, extra = {}) {
  return {
    status: 'verified',
    source: 'admin_finalize_iq_v1',
    session_id: id,
    bank_version: 'bank_x',
    catalog_version: DEFAULT_CATALOG_VERSION,
    ...extra,
  };
}

function trustedCompleteVerification(extra = {}) {
  return {
    schema_version: VERIFICATION_SCHEMA,
    flow: 'complete',
    grant_reason: 'admin_finalize_frequency_v1',
    catalog_version: DEFAULT_CATALOG_VERSION,
    iq: verifiedModule('iq_keep'),
    eq: { ...verifiedModule('eq_keep'), source: 'admin_finalize_eq_v1' },
    frequency: {
      ...verifiedModule('freq_keep'),
      source: 'admin_finalize_frequency_v1',
    },
    ...extra,
  };
}

describe('assessment_trust_grandfather_v1 planner', () => {
  it('discover_eligible=true + old formula true => candidate', () => {
    const user = eligibleUser();
    assert.strictEqual(deriveDiscoverEligible(user), true);
    assert.strictEqual(
      classifyGrandfatherCandidate(user),
      CLASSIFICATIONS.grandfatherCandidate,
    );
    const planned = planGrandfatherWrite(user);
    assert.strictEqual(planned.classification, CLASSIFICATIONS.grandfatherCandidate);
    assert.ok(planned.write);
    assert.strictEqual(planned.write.assessment_verification_v1.flow, PRESERVED_FLOW);
    assert.strictEqual(
      planned.write.assessment_verification_v1.grant_reason,
      MIGRATION_GRANT_REASON,
    );
  });

  it('discover_eligible=true + deletion requested => stored_eligible_but_formula_false', () => {
    const user = eligibleUser({ account_deletion_requested: true });
    assert.strictEqual(deriveDiscoverEligible(user), false);
    assert.strictEqual(
      classifyGrandfatherCandidate(user),
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(planGrandfatherWrite(user).write, null);
  });

  it('discover_eligible=true + inactive => no grandfather write', () => {
    const user = eligibleUser({ active: false });
    assert.strictEqual(deriveDiscoverEligible(user), false);
    assert.strictEqual(
      classifyGrandfatherCandidate(user),
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(planGrandfatherWrite(user).write, null);
  });

  it('discover_eligible=true + profile incomplete => no grandfather write', () => {
    const user = eligibleUser({ profile_completed: false });
    assert.strictEqual(deriveDiscoverEligible(user), false);
    assert.strictEqual(
      classifyGrandfatherCandidate(user),
      CLASSIFICATIONS.storedEligibleButFormulaFalse,
    );
    assert.strictEqual(planGrandfatherWrite(user).write, null);
  });

  it('discover_eligible=true + no photo => no grandfather write', () => {
    const user = eligibleUser({
      profile_photo_url: '',
      photos: [],
    });
    assert.strictEqual(deriveDiscoverEligible(user), false);
    assert.strictEqual(planGrandfatherWrite(user).write, null);
  });

  it('formula true but discover_eligible=false => report only, no grandfather', () => {
    const user = eligibleUser({ discover_eligible: false });
    assert.strictEqual(deriveDiscoverEligible(user), true);
    assert.strictEqual(
      classifyGrandfatherCandidate(user),
      CLASSIFICATIONS.formulaTrueButStoredFalse,
    );
    assert.strictEqual(planGrandfatherWrite(user).write, null);
  });

  it('flow=complete without trusted modules is NOT trusted-complete', () => {
    const user = eligibleUser({
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'complete',
        grant_reason: 'client_claimed',
      },
    });
    const planned = planGrandfatherWrite(user);
    assert.strictEqual(
      planned.classification,
      CLASSIFICATIONS.grandfatherCandidate,
    );
    assert.ok(planned.write);
    assert.strictEqual(planned.write.assessment_verification_v1.flow, PRESERVED_FLOW);
    assert.strictEqual(
      planned.write.assessment_verification_v1.grant_reason,
      MIGRATION_GRANT_REASON,
    );
    assert.strictEqual(planned.write.assessment_verification_v1.iq, undefined);
  });

  it('trusted complete => unchanged', () => {
    const user = eligibleUser({
      assessment_verification_v1: trustedCompleteVerification(),
    });
    const before = JSON.parse(JSON.stringify(user.assessment_verification_v1));
    const planned = planGrandfatherWrite(user);
    assert.strictEqual(
      planned.classification,
      CLASSIFICATIONS.alreadyTrustedComplete,
    );
    assert.strictEqual(planned.write, null);
    assert.deepStrictEqual(user.assessment_verification_v1, before);
  });

  it('existing pre_c2_preserved => idempotent / unchanged', () => {
    const user = eligibleUser({
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: PRESERVED_FLOW,
        grant_reason: 'legacy_pre_c2_audit',
        catalog_version: DEFAULT_CATALOG_VERSION,
        iq: verifiedModule('iq_keep'),
      },
    });
    const before = JSON.parse(JSON.stringify(user.assessment_verification_v1));
    const planned = planGrandfatherWrite(user);
    assert.strictEqual(
      planned.classification,
      CLASSIFICATIONS.alreadyPreC2Preserved,
    );
    assert.strictEqual(planned.write, null);
    assert.deepStrictEqual(user.assessment_verification_v1, before);
    assert.strictEqual(before.grant_reason, 'legacy_pre_c2_audit');
  });

  it('legacy_iq_eq eligible => plan pre_c2_preserved', () => {
    const iq = verifiedModule('iq_legacy');
    const eq = { ...verifiedModule('eq_legacy'), source: 'admin_finalize_eq_v1' };
    const user = eligibleUser({
      assessment_verification_v1: {
        schema_version: VERIFICATION_SCHEMA,
        flow: 'legacy_iq_eq',
        grant_reason: 'legacy_iq_eq_grant',
        catalog_version: DEFAULT_CATALOG_VERSION,
        iq,
        eq,
      },
    });
    const planned = planGrandfatherWrite(user);
    assert.strictEqual(
      planned.classification,
      CLASSIFICATIONS.grandfatherCandidate,
    );
    const next = planned.write.assessment_verification_v1;
    assert.strictEqual(next.flow, PRESERVED_FLOW);
    assert.strictEqual(next.grant_reason, MIGRATION_GRANT_REASON);
    assert.deepStrictEqual(next.iq, iq);
    assert.deepStrictEqual(next.eq, eq);
    assert.strictEqual(next.frequency, undefined);
  });

  it('existing IQ verified proof preserved', () => {
    const iq = verifiedModule('iq_proof');
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          schema_version: VERIFICATION_SCHEMA,
          flow: 'iq',
          iq,
        },
      }),
    );
    assert.deepStrictEqual(planned.write.assessment_verification_v1.iq, iq);
    assert.strictEqual(planned.write.assessment_verification_v1.iq.status, 'verified');
  });

  it('existing EQ verified proof preserved', () => {
    const eq = {
      status: 'verified',
      source: 'admin_finalize_eq_v1',
      session_id: 'eq_proof',
    };
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          flow: 'iq_eq',
          iq: verifiedModule('iq_proof'),
          eq,
        },
      }),
    );
    assert.deepStrictEqual(planned.write.assessment_verification_v1.eq, eq);
  });

  it('existing Frequency V1 verified proof preserved', () => {
    const frequency = {
      status: 'verified',
      source: 'admin_finalize_frequency_v1',
      session_id: 'freq_v1_proof',
    };
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          flow: 'iq_eq',
          frequency,
        },
      }),
    );
    assert.deepStrictEqual(
      planned.write.assessment_verification_v1.frequency,
      frequency,
    );
  });

  it('existing module timestamps and session IDs preserved', () => {
    const iq = verifiedModule('iq_ts', { verified_at: '2024-01-02T03:04:05Z' });
    const eq = {
      status: 'verified',
      source: 'admin_finalize_eq_v1',
      session_id: 'eq_ts',
      verified_at: '2024-02-03T04:05:06Z',
    };
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          flow: 'iq_eq',
          server_owned_marker: 'keep-me',
          iq,
          eq,
        },
      }),
    );
    const next = planned.write.assessment_verification_v1;
    assert.strictEqual(next.iq.session_id, 'iq_ts');
    assert.strictEqual(next.iq.verified_at, '2024-01-02T03:04:05Z');
    assert.strictEqual(next.eq.session_id, 'eq_ts');
    assert.strictEqual(next.eq.verified_at, '2024-02-03T04:05:06Z');
    assert.strictEqual(next.server_owned_marker, 'keep-me');
  });

  it('no Frequency V2 sibling introduced', () => {
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          flow: 'none',
          frequency_v2: { status: 'verified', should_not_copy: true },
        },
      }),
    );
    const next = planned.write.assessment_verification_v1;
    assert.strictEqual(Object.prototype.hasOwnProperty.call(next, 'frequency_v2'), false);
    assert.strictEqual(next.frequency, undefined);
  });

  it('no fake module grandfather statuses', () => {
    const planned = planGrandfatherWrite(eligibleUser());
    const next = planned.write.assessment_verification_v1;
    assert.strictEqual(next.iq, undefined);
    assert.strictEqual(next.eq, undefined);
    assert.strictEqual(next.frequency, undefined);
    assert.strictEqual(JSON.stringify(next).includes('"grandfathered"'), false);
    assert.strictEqual(next.flow, PRESERVED_FLOW);
  });

  it('catalog_version preserved when valid', () => {
    const planned = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: {
          flow: 'iq',
          catalog_version: 'assessment_finalize_catalog_historic',
        },
      }),
    );
    assert.strictEqual(
      planned.write.assessment_verification_v1.catalog_version,
      'assessment_finalize_catalog_historic',
    );
  });

  it('default catalog version used when needed', () => {
    const missing = planGrandfatherWrite(eligibleUser());
    assert.strictEqual(
      missing.write.assessment_verification_v1.catalog_version,
      DEFAULT_CATALOG_VERSION,
    );
    const empty = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: { flow: 'none', catalog_version: '' },
      }),
    );
    assert.strictEqual(
      empty.write.assessment_verification_v1.catalog_version,
      DEFAULT_CATALOG_VERSION,
    );
  });

  it('planned write does not change test_completed / flow / discover / profile', () => {
    const user = eligibleUser({
      test_completed: true,
      assessment_flow_completed: true,
      discover_eligible: true,
      profile_photo_url: 'https://example.com/p.jpg',
    });
    const before = frozenSnapshot(user);
    const planned = planGrandfatherWrite(user);
    const keys = Object.keys(planned.write);
    assert.deepStrictEqual(keys, ['assessment_verification_v1']);
    for (const frozen of FROZEN_USER_KEYS) {
      assert.strictEqual(
        Object.prototype.hasOwnProperty.call(planned.write, frozen),
        false,
        frozen,
      );
    }
    assert.strictEqual(user.discover_eligible, before.discover_eligible);
    assert.strictEqual(user.test_completed, before.test_completed);
    assert.strictEqual(
      user.assessment_flow_completed,
      before.assessment_flow_completed,
    );
    assert.deepStrictEqual(frozenSnapshot(user), before);
  });

  it('malformed assessment_verification handled safely', () => {
    for (const bad of [[], 'oops', 3, true]) {
      const planned = planGrandfatherWrite(
        eligibleUser({ assessment_verification_v1: bad }),
      );
      assert.strictEqual(
        planned.classification,
        CLASSIFICATIONS.malformedVerification,
      );
      assert.strictEqual(planned.write, null);
    }
    const badFlow = planGrandfatherWrite(
      eligibleUser({
        assessment_verification_v1: { flow: ['complete'] },
      }),
    );
    assert.strictEqual(
      badFlow.classification,
      CLASSIFICATIONS.malformedVerification,
    );
    assert.strictEqual(badFlow.write, null);
  });

  it('repeated planner call is idempotent', () => {
    const user = eligibleUser({
      assessment_verification_v1: {
        flow: 'legacy_iq_eq',
        iq: verifiedModule('iq_1'),
      },
    });
    const first = planGrandfatherWrite(user);
    const second = planGrandfatherWrite(user);
    assert.deepStrictEqual(first, second);
    const applied = {
      ...user,
      ...first.write,
    };
    const after = planGrandfatherWrite(applied);
    assert.strictEqual(
      after.classification,
      CLASSIFICATIONS.alreadyPreC2Preserved,
    );
    assert.strictEqual(after.write, null);
  });

  it('not eligible when stored and formula are both false', () => {
    const planned = planGrandfatherWrite({
      active: false,
      discover_eligible: false,
    });
    assert.strictEqual(planned.classification, CLASSIFICATIONS.notEligible);
    assert.strictEqual(planned.write, null);
  });
});

describe('assessment_trust_grandfather_v1 scan / apply path', () => {
  function listFromUsers(users) {
    const rows = Object.keys(users)
      .sort()
      .map((uid) => ({ uid, data: users[uid] }));
    return async ({ startAfterId, pageSize }) => {
      let start = 0;
      if (startAfterId) {
        const idx = rows.findIndex((row) => row.uid === startAfterId);
        start = idx >= 0 ? idx + 1 : rows.length;
      }
      return rows.slice(start, start + pageSize);
    };
  }

  it('dry run writer count zero', async () => {
    const users = {
      a: eligibleUser(),
      b: eligibleUser({ discover_eligible: false, active: false }),
    };
    let commits = 0;
    const counts = await runGrandfatherMigration({
      listPage: listFromUsers(users),
      pageSize: 10,
      writeEnabled: false,
      commitPage: async () => {
        commits += 1;
        throw new Error('dry-run must not commit');
      },
    });
    assert.strictEqual(commits, 0);
    assert.strictEqual(counts.writes_performed, 0);
    assert.strictEqual(counts.planned_writes, 1);
    assert.strictEqual(counts.grandfather_candidates, 1);
    assert.strictEqual(counts.not_eligible, 1);
    assert.strictEqual(counts.total_scanned, 2);
  });

  it('paginates deterministically and is restart-safe', async () => {
    const users = {
      u1: eligibleUser(),
      u2: eligibleUser({
        assessment_verification_v1: trustedCompleteVerification(),
      }),
      u3: eligibleUser(),
      u4: eligibleUser({ account_deletion_requested: true }),
      u5: eligibleUser({ discover_eligible: false }),
    };
    const seen = [];
    const counts = await runGrandfatherMigration({
      listPage: async (args) => {
        const page = await listFromUsers(users)(args);
        for (const row of page) seen.push(row.uid);
        return page;
      },
      pageSize: 2,
      writeEnabled: false,
    });
    assert.deepStrictEqual(seen, ['u1', 'u2', 'u3', 'u4', 'u5']);
    assert.strictEqual(counts.total_scanned, 5);
    assert.strictEqual(counts.grandfather_candidates, 2);
    assert.strictEqual(counts.already_trusted_complete, 1);
    assert.strictEqual(counts.stored_eligible_but_formula_false, 1);
    assert.strictEqual(counts.formula_true_but_stored_false, 1);
    assert.strictEqual(counts.planned_writes, 2);
  });

  it('apply path writes only assessment_verification_v1 and can resume', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u1').set(eligibleUser({ display_name: 'keep-me' }));
    await db.doc('users/u2').set(
      eligibleUser({
        assessment_verification_v1: trustedCompleteVerification(),
      }),
    );
    await db.doc('users/u3').set(eligibleUser({ test_completed: true }));

    const before1 = frozenSnapshot(db._store.get('users/u1'));
    const before3 = frozenSnapshot(db._store.get('users/u3'));

    let pagesCommitted = 0;
    await assert.rejects(
      () =>
        runGrandfatherMigration({
          listPage: listFromUsers({
            u1: db._store.get('users/u1'),
            u2: db._store.get('users/u2'),
            u3: db._store.get('users/u3'),
          }),
          pageSize: 2,
          writeEnabled: true,
          commitPage: async (writes) => {
            pagesCommitted += 1;
            const n = await commitGrandfatherPage(db, writes, {
              writeEnabled: true,
            });
            if (pagesCommitted === 1) {
              throw new Error('simulated crash after first page');
            }
            return n;
          },
        }),
      /simulated crash after first page/,
    );
    assert.strictEqual(pagesCommitted, 1);
    assert.strictEqual(
      db._store.get('users/u1').assessment_verification_v1.flow,
      PRESERVED_FLOW,
    );
    assert.strictEqual(
      db._store.get('users/u2').assessment_verification_v1.flow,
      'complete',
    );
    assert.strictEqual(
      db._store.get('users/u3').assessment_verification_v1,
      undefined,
    );
    assert.deepStrictEqual(frozenSnapshot(db._store.get('users/u1')), before1);
    assert.strictEqual(db._store.get('users/u1').display_name, 'keep-me');

    const resume = await runGrandfatherMigration({
      listPage: listFromUsers({
        u1: db._store.get('users/u1'),
        u2: db._store.get('users/u2'),
        u3: db._store.get('users/u3'),
      }),
      pageSize: 10,
      writeEnabled: true,
      commitPage: (writes) =>
        commitGrandfatherPage(db, writes, { writeEnabled: true }),
    });
    assert.strictEqual(resume.grandfather_candidates, 1);
    assert.strictEqual(resume.already_pre_c2_preserved, 1);
    assert.strictEqual(resume.already_trusted_complete, 1);
    assert.strictEqual(resume.writes_performed, 1);
    assert.strictEqual(
      db._store.get('users/u3').assessment_verification_v1.grant_reason,
      MIGRATION_GRANT_REASON,
    );
    assert.deepStrictEqual(frozenSnapshot(db._store.get('users/u3')), before3);
  });

  it('commitGrandfatherPage without writeEnabled writes zero', async () => {
    const db = new MemoryFirestore();
    await db.doc('users/u1').set(eligibleUser());
    const planned = planGrandfatherWrite(db._store.get('users/u1'));
    const written = await commitGrandfatherPage(
      db,
      [{ uid: 'u1', write: planned.write }],
    );
    assert.strictEqual(written, 0);
    assert.strictEqual(db._store.get('users/u1').assessment_verification_v1, undefined);
  });
});

describe('assessment_trust_grandfather_v1 CLI gates', () => {
  it('default invocation cannot write', () => {
    const parsed = parseGrandfatherCliArgs(['node', 'tool.js']);
    assert.strictEqual(parsed.ok, true);
    assert.strictEqual(parsed.mode, 'dry-run');
    assert.strictEqual(parsed.writeEnabled, false);
  });

  it('apply without confirmation cannot write', () => {
    const parsed = parseGrandfatherCliArgs(['--apply']);
    assert.strictEqual(parsed.writeEnabled, false);
    assert.strictEqual(parsed.ok, false);
    assert.strictEqual(parsed.error, 'apply_refused');
  });

  it('confirmation without apply cannot write', () => {
    const parsed = parseGrandfatherCliArgs([`--confirm=${APPLY_CONFIRM}`]);
    assert.strictEqual(parsed.ok, true);
    assert.strictEqual(parsed.mode, 'dry-run');
    assert.strictEqual(parsed.writeEnabled, false);
  });

  it('exact apply gate required', () => {
    const wrong = parseGrandfatherCliArgs([
      '--apply',
      '--confirm=PRE_TRUST_MIGRATION',
    ]);
    assert.strictEqual(wrong.writeEnabled, false);
    const yes = parseGrandfatherCliArgs(['--apply', '--confirm', 'YES']);
    assert.strictEqual(yes.writeEnabled, false);
    assert.strictEqual(yes.error, 'never_yes');
    const ok = parseGrandfatherCliArgs(['--apply', `--confirm=${APPLY_CONFIRM}`]);
    assert.strictEqual(ok.ok, true);
    assert.strictEqual(ok.mode, 'apply');
    assert.strictEqual(ok.writeEnabled, true);
    const spaced = parseGrandfatherCliArgs(['--apply', '--confirm', APPLY_CONFIRM]);
    assert.strictEqual(spaced.writeEnabled, true);
  });

  it('planner module has no Firestore side effects', () => {
    const src = require('fs').readFileSync(
      require('path').join(
        __dirname,
        '../src/assessment_trust_grandfather_v1.js',
      ),
      'utf8',
    );
    assert.strictEqual(src.includes('firebase-admin'), false);
    assert.strictEqual(src.includes('getFirestore'), false);
    assert.strictEqual(src.includes("require('./discover_eligibility')"), true);
    assert.strictEqual(
      src.includes("require('./assessment_verification_flow_v1')"),
      true,
    );
    assert.strictEqual(src.includes('moduleIsTrusted'), true);
    assert.strictEqual(src.includes('finalizeFrequencyV2'), false);
    assert.strictEqual(src.includes('runtime_selectable'), false);
    assert.strictEqual(POLICY, 'assessment_trust_grandfather_v1');
  });
});
