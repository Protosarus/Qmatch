'use strict';

const assert = require('assert');
const {
  deriveDiscoverEligible,
  planDiscoverEligibleWrite,
  hasValidPhoto,
  relevantFieldsChanged,
} = require('../src/discover_eligibility');

function validBase(overrides = {}) {
  return {
    active: true,
    test_completed: true,
    assessment_flow_completed: false,
    profile_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    account_deletion_requested: false,
    discover_eligible: false,
    ...overrides,
  };
}

describe('trusted_discover_eligibility_authority_v1', () => {
  it('incomplete -> false', () => {
    assert.strictEqual(deriveDiscoverEligible({}), false);
    assert.strictEqual(deriveDiscoverEligible(null), false);
    assert.strictEqual(
      deriveDiscoverEligible({
        active: true,
        profile_completed: false,
        test_completed: false,
        assessment_flow_completed: false,
      }),
      false,
    );
  });

  it('profile complete only -> false', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          test_completed: false,
          assessment_flow_completed: false,
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
          test_completed: true,
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
    assert.strictEqual(hasValidPhoto(validBase({ profile_photo_url: '' , photos: [] })), false);
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

  it('either assessment completion flag works', () => {
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          test_completed: true,
          assessment_flow_completed: false,
        }),
      ),
      true,
    );
    assert.strictEqual(
      deriveDiscoverEligible(
        validBase({
          test_completed: false,
          assessment_flow_completed: true,
        }),
      ),
      true,
    );
  });

  it('active false -> false', () => {
    assert.strictEqual(deriveDiscoverEligible(validBase({ active: false })), false);
    // Missing active is not eligible (strict == true).
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

    // Simulated CF write of discover_eligible only → second invocation no-ops.
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
    assert.strictEqual(planDiscoverEligibleWrite(ineligible, ineligible).shouldWrite, false);

    // Unrelated field change with correct flag → no write.
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
    // Client must clear primary; CF does not invent deletes.
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
});
