'use strict';

const assert = require('assert');
const {
  ASSESSMENT_GRANT_POLICY_VERSION,
  deriveDiscoverEligible,
  deriveDiscoverEligibleWithAssessmentProof,
  planDiscoverEligibleWriteWithProof,
} = require('../src/discover_eligibility');
const {
  parseFrequencyV2Result,
} = require('../src/frequency_behavior_v2_result_parser');
const contract = require('../src/frequency_behavior_v2_contract');

function trustedBattery(extra = {}) {
  return {
    schema_version: 'assessment_verification_v1',
    flow: 'complete',
    grant_reason: 'admin_finalize_frequency_v1',
    iq: { status: 'verified' },
    eq: { status: 'verified' },
    frequency: { status: 'verified' },
    ...extra,
  };
}

function grandfatherGrant() {
  return {
    schema_version: 'assessment_verification_v1',
    flow: 'pre_c2_preserved',
    grant_reason: 'pre_trust_migration_preserved',
    catalog_version: 'assessment_finalize_catalog_v1',
  };
}

function validBase(overrides = {}) {
  return {
    active: true,
    profile_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    account_deletion_requested: false,
    discover_eligible: false,
    assessment_verification_v1: trustedBattery(),
    ...overrides,
  };
}

function validV2Doc(overrides = {}) {
  return {
    schema_version: contract.RESULT_SCHEMA_VERSION,
    assessment_type: contract.ASSESSMENT_TYPE,
    status: contract.RESULT_STATUS,
    source: contract.RESULT_SOURCE,
    dimensions: contract.CANONICAL_DIMENSIONS.map((id) => ({
      dimension_id: id,
      normalized_behavior: 0.1,
      provisional_confidence: 1,
      confidence_completeness: 1,
    })),
    ...overrides,
  };
}

function proofFrom(doc) {
  return { frequencyV2Result: parseFrequencyV2Result(doc) };
}

describe('trusted_discover_assessment_grant_v2', () => {
  it('pins the grant policy version', () => {
    assert.strictEqual(
      ASSESSMENT_GRANT_POLICY_VERSION,
      'trusted_discover_assessment_grant_v2',
    );
  });

  it('pre_c2 grandfather + no V2 remains eligible', () => {
    const user = validBase({ assessment_verification_v1: grandfatherGrant() });
    assert.strictEqual(deriveDiscoverEligible(user), true);
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, {
        frequencyV2Result: { ok: false, code: 'missing_document' },
      }),
      true,
    );
  });

  it('pre_c2 grandfather + valid V2 remains eligible', () => {
    const user = validBase({ assessment_verification_v1: grandfatherGrant() });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, proofFrom(validV2Doc())),
      true,
    );
  });

  it('pre_c2 grandfather + malformed V2 remains eligible', () => {
    const user = validBase({ assessment_verification_v1: grandfatherGrant() });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(
        user,
        proofFrom(validV2Doc({ source: 'client_write' })),
      ),
      true,
    );
  });

  it('trusted IQ only + valid V2 is not eligible', () => {
    const user = validBase({
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'none' },
        frequency: { status: 'none' },
      },
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, proofFrom(validV2Doc())),
      false,
    );
  });

  it('trusted IQ+EQ + no V2 is not eligible unless V1 Frequency trusted', () => {
    const user = validBase({
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'verified' },
        frequency: { status: 'none' },
      },
    });
    assert.strictEqual(deriveDiscoverEligible(user), false);
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, {
        frequencyV2Result: { ok: false, code: 'missing_document' },
      }),
      false,
    );
  });

  it('trusted IQ+EQ + valid V2 is eligible', () => {
    const user = validBase({
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'verified' },
        frequency: { status: 'none' },
      },
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, proofFrom(validV2Doc())),
      true,
    );
  });

  it('trusted IQ+EQ + malformed V2 is not eligible', () => {
    const user = validBase({
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'verified' },
      },
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(
        user,
        proofFrom(validV2Doc({ schema_version: 'wrong' })),
      ),
      false,
    );
  });

  it('trusted IQ+EQ + client-looking fabricated V2 is not eligible', () => {
    const user = validBase({
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'verified' },
      },
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(
        user,
        proofFrom(validV2Doc({ source: 'client_frequency_v2_write' })),
      ),
      false,
    );
  });

  it('full trusted V1 battery + no V2 is eligible', () => {
    assert.strictEqual(deriveDiscoverEligible(validBase()), true);
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(validBase(), {
        frequencyV2Result: { ok: false, code: 'missing_document' },
      }),
      true,
    );
  });

  it('full V1 + malformed V2 stays eligible through V1', () => {
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(
        validBase(),
        proofFrom(validV2Doc({ source: 'client_write' })),
      ),
      true,
    );
  });

  it('flow=complete alone + valid V2 is not eligible', () => {
    const user = validBase({
      assessment_verification_v1: {
        flow: 'complete',
        grant_reason: 'client_claimed',
      },
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, proofFrom(validV2Doc())),
      false,
    );
  });

  it('old client completion flags + V2 are not trusted', () => {
    const user = validBase({
      assessment_verification_v1: undefined,
      test_completed: true,
      assessment_flow_completed: true,
      frequency_completed: true,
    });
    assert.strictEqual(
      deriveDiscoverEligibleWithAssessmentProof(user, proofFrom(validV2Doc())),
      false,
    );
  });

  it('user-only derivation still cannot grant from a V2 field on users/{uid}', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          assessment_verification_v1: {
            iq: { status: 'verified' },
            eq: { status: 'verified' },
          },
          frequency_v2: validV2Doc(),
        }),
      ),
      false,
    );
  });

  it('does not write when derived V2 grant already matches stored flag', () => {
    const user = validBase({
      discover_eligible: true,
      assessment_verification_v1: {
        iq: { status: 'verified' },
        eq: { status: 'verified' },
      },
    });
    const plan = planDiscoverEligibleWriteWithProof(user, user, proofFrom(validV2Doc()));
    assert.strictEqual(plan.derived, true);
    assert.strictEqual(plan.shouldWrite, false);
  });
});
