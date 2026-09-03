'use strict';

const assert = require('assert');
const {
  deriveProgressionFlow,
  resolveTrustedFlow,
  preserveGrantReason,
  moduleIsTrusted,
  hasTrustedV1Battery,
  hasPreTrustMigrationGrant,
} = require('../src/assessment_verification_flow_v1');

describe('assessment_verification_flow_v1', () => {
  it('hasTrustedV1Battery requires IQ + EQ + Frequency V1', () => {
    assert.strictEqual(hasTrustedV1Battery(null), false);
    assert.strictEqual(hasTrustedV1Battery({ flow: 'complete' }), false);
    assert.strictEqual(
      hasTrustedV1Battery({ iq: { status: 'verified' } }),
      false,
    );
    assert.strictEqual(
      hasTrustedV1Battery({
        iq: { status: 'verified' },
        eq: { status: 'verified' },
      }),
      false,
    );
    assert.strictEqual(
      hasTrustedV1Battery({
        iq: { status: 'verified' },
        eq: { status: 'verified' },
        frequency: { status: 'verified' },
      }),
      true,
    );
    assert.strictEqual(
      hasPreTrustMigrationGrant({
        flow: 'pre_c2_preserved',
        grant_reason: 'pre_trust_migration_preserved',
      }),
      true,
    );
    assert.strictEqual(
      hasPreTrustMigrationGrant({ flow: 'complete' }),
      false,
    );
  });

  it('treats verified and grandfathered modules as trusted', () => {
    assert.strictEqual(moduleIsTrusted({ status: 'verified' }), true);
    assert.strictEqual(moduleIsTrusted({ status: 'grandfathered' }), true);
    assert.strictEqual(moduleIsTrusted({ status: 'none' }), false);
    assert.strictEqual(moduleIsTrusted(null), false);
  });

  it('derives none → iq → iq_eq → complete', () => {
    assert.strictEqual(deriveProgressionFlow({}), 'none');
    assert.strictEqual(
      deriveProgressionFlow({ iq: { status: 'verified' } }),
      'iq',
    );
    assert.strictEqual(
      deriveProgressionFlow({
        iq: { status: 'verified' },
        eq: { status: 'grandfathered' },
      }),
      'iq_eq',
    );
    assert.strictEqual(
      deriveProgressionFlow({
        iq: { status: 'verified' },
        eq: { status: 'verified' },
        frequency: { status: 'grandfathered' },
      }),
      'complete',
    );
  });

  it('never downgrades preserved grant flows', () => {
    assert.strictEqual(resolveTrustedFlow('complete', 'iq'), 'complete');
    assert.strictEqual(resolveTrustedFlow('legacy_iq_eq', 'iq'), 'legacy_iq_eq');
    assert.strictEqual(
      resolveTrustedFlow('pre_c2_preserved', 'iq_eq'),
      'pre_c2_preserved',
    );
  });

  it('may upgrade a weaker preserved grant to complete', () => {
    assert.strictEqual(resolveTrustedFlow('legacy_iq_eq', 'complete'), 'complete');
    assert.strictEqual(
      resolveTrustedFlow('pre_c2_preserved', 'complete'),
      'pre_c2_preserved',
    );
  });

  it('preserves grant_reason only for preserved grant flows', () => {
    assert.strictEqual(
      preserveGrantReason({ grant_reason: 'legacy' }, 'legacy_iq_eq'),
      'legacy',
    );
    assert.strictEqual(
      preserveGrantReason({ grant_reason: 'legacy' }, 'iq'),
      'admin_finalize_iq_v1',
    );
    assert.strictEqual(
      preserveGrantReason(
        { grant_reason: 'legacy' },
        'iq_eq',
        'admin_finalize_eq_v1',
      ),
      'admin_finalize_eq_v1',
    );
  });
});
