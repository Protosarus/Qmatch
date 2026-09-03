'use strict';

const assert = require('assert');
const {
  RELEVANT_KEYS,
  deriveDiscoverEligible,
  planDiscoverEligibleWrite,
  hasValidPhoto,
  hasTrustedAssessmentDiscoverGrant,
  relevantFieldsChanged,
} = require('../src/discover_eligibility');
const {
  deriveLegacyDiscoverEligiblePreTrust,
} = require('../src/legacy_discover_eligibility_pre_trust_v1');

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

describe('trusted_discover_eligibility_authority_v1', () => {
  it('RELEVANT_KEYS use verification, not client completion flags', () => {
    assert.deepStrictEqual(
      [...RELEVANT_KEYS],
      [
        'active',
        'profile_completed',
        'profile_photo_url',
        'photos',
        'account_deletion_requested',
        'discover_eligible',
        'assessment_verification_v1',
      ],
    );
    assert.ok(!RELEVANT_KEYS.includes('test_completed'));
    assert.ok(!RELEVANT_KEYS.includes('assessment_flow_completed'));
  });

  it('incomplete -> false', () => {
    assert.strictEqual(deriveDiscoverEligible({}), false);
    assert.strictEqual(deriveDiscoverEligible(null), false);
    assert.strictEqual(
      deriveDiscoverEligible({
        active: true,
        profile_completed: false,
      }),
      false,
    );
  });

  it('profile complete only -> false', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          assessment_verification_v1: undefined,
          profile_completed: true,
        }),
      ),
      false,
    );
  });

  it('assessment complete only -> false', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          profile_completed: false,
        }),
      ),
      false,
    );
  });

  it('photo missing -> false', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          profile_photo_url: '',
          photos: [],
        }),
      ),
      false,
    );
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          profile_photo_url: null,
          photos: ['  '],
        }),
      ),
      false,
    );
    assert.strictEqual(
      hasValidPhoto(validBase({ profile_photo_url: '', photos: [] })),
      false,
    );
  });

  it('all canonical requirements -> true', () => {
    assert.strictEqual(deriveDiscoverEligible(validBase()), true);
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          profile_photo_url: '',
          photos: ['https://example.com/alt.jpg'],
        }),
      ),
      true,
    );
  });

  it('old client completion flags no longer grant eligibility', () => {
    const flagsOnly = validBase({
      assessment_verification_v1: undefined,
      test_completed: true,
      assessment_flow_completed: true,
    });
    assert.strictEqual(deriveDiscoverEligible(flagsOnly), false);
    assert.strictEqual(deriveLegacyDiscoverEligiblePreTrust(flagsOnly), true);
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          assessment_verification_v1: undefined,
          test_completed: true,
          assessment_flow_completed: false,
        }),
      ),
      false,
    );
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          assessment_verification_v1: undefined,
          test_completed: false,
          assessment_flow_completed: true,
        }),
      ),
      false,
    );
  });

  it('grandfather pre_c2_preserved grant remains eligible without client flags', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          test_completed: false,
          assessment_flow_completed: false,
          assessment_verification_v1: grandfatherGrant(),
        }),
      ),
      true,
    );
    assert.strictEqual(
      hasTrustedAssessmentDiscoverGrant({
        assessment_verification_v1: grandfatherGrant(),
      }),
      true,
    );
  });

  it('trusted V1 battery path requires IQ + EQ + Frequency V1', () => {
    const profileReady = {
      active: true,
      profile_completed: true,
      profile_photo_url: 'https://example.com/p.jpg',
    };
    assert.strictEqual(
      deriveDiscoverEligible({
        ...profileReady,
        assessment_verification_v1: { iq: { status: 'verified' } },
      }),
      false,
    );
    assert.strictEqual(
      deriveDiscoverEligible({
        ...profileReady,
        assessment_verification_v1: {
          iq: { status: 'verified' },
          eq: { status: 'verified' },
        },
      }),
      false,
    );
    assert.strictEqual(
      deriveDiscoverEligible({
        ...profileReady,
        assessment_verification_v1: {
          frequency: { status: 'verified' },
        },
      }),
      false,
    );
    assert.strictEqual(
      deriveDiscoverEligible({
        ...profileReady,
        assessment_verification_v1: trustedBattery(),
      }),
      true,
    );
  });

  it('flow=complete alone and Frequency V2 alone do not grant', () => {
    const profileReady = validBase({
      assessment_verification_v1: {
        flow: 'complete',
        grant_reason: 'client_claimed',
      },
    });
    assert.strictEqual(deriveDiscoverEligible(profileReady), false);
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          assessment_verification_v1: undefined,
          assessments_frequency_v2: { status: 'completed' },
          frequency_v2: { status: 'completed' },
        }),
      ),
      false,
    );
  });

  it('active false -> false', () => {
    assert.strictEqual(deriveDiscoverEligible(validBase({ active: false })), false);
    assert.strictEqual(
      deriveDiscoverEligible(validBase({ active: undefined })),
      false,
    );
  });

  it('deletion/ineligible transition -> false', () => {
    assert.strictEqual(
      deriveDiscoverEligible(validBase({ account_deletion_requested: true })),
      false,
    );

    const before = validBase({
      discover_eligible: true,
      account_deletion_requested: false,
    });
    const after = validBase({
      discover_eligible: true,
      account_deletion_requested: true,
    });
    const plan = planDiscoverEligibleWrite(before, after);
    assert.strictEqual(plan.derived, false);
    assert.strictEqual(plan.shouldWrite, true);
  });

  it('no redundant write / trigger loop', () => {
    const eligible = validBase({ discover_eligible: true });
    const plan1 = planDiscoverEligibleWrite(eligible, eligible);
    assert.strictEqual(plan1.shouldWrite, false);
    assert.strictEqual(plan1.derived, true);

    const afterCfWrite = validBase({ discover_eligible: true });
    const beforeCfWrite = validBase({ discover_eligible: false });
    const planGrant = planDiscoverEligibleWrite(beforeCfWrite, {
      ...afterCfWrite,
      discover_eligible: true,
    });
    assert.strictEqual(planGrant.shouldWrite, false);

    const ineligible = validBase({
      profile_completed: false,
      discover_eligible: false,
    });
    assert.strictEqual(
      planDiscoverEligibleWrite(ineligible, ineligible).shouldWrite,
      false,
    );

    const beforeBio = validBase({ discover_eligible: true, bio: 'a' });
    const afterBio = validBase({ discover_eligible: true, bio: 'b' });
    assert.strictEqual(planDiscoverEligibleWrite(beforeBio, afterBio).shouldWrite, false);
    assert.strictEqual(relevantFieldsChanged(beforeBio, afterBio), false);
  });

  it('plans a write when stored flag drifts from derivation', () => {
    const after = validBase({ discover_eligible: false });
    const plan = planDiscoverEligibleWrite(null, after);
    assert.strictEqual(plan.derived, true);
    assert.strictEqual(plan.shouldWrite, true);
  });

  it('legacy valid photo-only profile (no photos list) stays eligible', () => {
    assert.strictEqual(
      hasValidPhoto({
        profile_photo_url: 'https://example.com/legacy.jpg',
        photos: [],
      }),
      true,
    );
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          profile_photo_url: 'https://example.com/legacy.jpg',
          photos: [],
          discover_eligible: true,
        }),
      ),
      true,
    );
  });

  it('empty photos + cleared primary URL revokes eligibility', () => {
    const before = validBase({
      discover_eligible: true,
      photos: ['https://example.com/a.jpg'],
      profile_photo_url: 'https://example.com/a.jpg',
    });
    const after = validBase({
      discover_eligible: true,
      photos: [],
      profile_photo_url: '',
    });
    assert.strictEqual(hasValidPhoto(after), false);
    const plan = planDiscoverEligibleWrite(before, after);
    assert.strictEqual(plan.derived, false);
    assert.strictEqual(plan.shouldWrite, true);
  });

  it('empty photos + stale primary URL still counts as hasPhoto (until cleared)', () => {
    assert.strictEqual(
      hasValidPhoto({
        photos: [],
        profile_photo_url: 'https://example.com/stale.jpg',
      }),
      true,
    );
  });

  it('removing one of multiple photos keeps hasPhoto', () => {
    assert.strictEqual(
      hasValidPhoto({
        photos: ['https://example.com/b.jpg'],
        profile_photo_url: 'https://example.com/b.jpg',
      }),
      true,
    );
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          photos: ['https://example.com/b.jpg'],
          profile_photo_url: 'https://example.com/b.jpg',
          discover_eligible: true,
        }),
      ),
      true,
    );
  });

  it('changing client flags is not a relevant eligibility field change', () => {
    const before = validBase({ test_completed: false });
    const after = validBase({ test_completed: true });
    assert.strictEqual(relevantFieldsChanged(before, after), false);
  });

  it('changing assessment_verification_v1 is relevant', () => {
    const before = validBase({ assessment_verification_v1: undefined });
    const after = validBase();
    assert.strictEqual(relevantFieldsChanged(before, after), true);
  });
});
