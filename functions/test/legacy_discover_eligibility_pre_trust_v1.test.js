'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  deriveLegacyDiscoverEligiblePreTrust,
} = require('../src/legacy_discover_eligibility_pre_trust_v1');
const { deriveDiscoverEligible } = require('../src/discover_eligibility');

describe('legacy_discover_eligibility_pre_trust_v1', () => {
  const flagsEligible = {
    active: true,
    test_completed: true,
    assessment_flow_completed: true,
    profile_completed: true,
    profile_photo_url: 'https://example.com/p.jpg',
    account_deletion_requested: false,
    discover_eligible: true,
  };

  it('preserves the historical client-flag formula', () => {
    assert.strictEqual(deriveLegacyDiscoverEligiblePreTrust(flagsEligible), true);
    assert.strictEqual(
      deriveLegacyDiscoverEligiblePreTrust({
        ...flagsEligible,
        test_completed: false,
        assessment_flow_completed: true,
      }),
      true,
    );
    assert.strictEqual(
      deriveLegacyDiscoverEligiblePreTrust({
        ...flagsEligible,
        active: false,
      }),
      false,
    );
  });

  it('does not follow live Discover after the trusted cutover', () => {
    assert.strictEqual(deriveDiscoverEligible(flagsEligible), false);
    assert.notStrictEqual(
      deriveLegacyDiscoverEligiblePreTrust(flagsEligible),
      deriveDiscoverEligible(flagsEligible),
    );
  });

  it('grandfather planner depends on the frozen helper, not live Discover', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../src/assessment_trust_grandfather_v1.js'),
      'utf8',
    );
    assert.ok(src.includes('deriveLegacyDiscoverEligiblePreTrust'));
    assert.ok(!src.includes("require('./discover_eligibility')"));
  });
});
