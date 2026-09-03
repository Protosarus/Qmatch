'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  deriveLegacyDiscoverEligiblePreTrust,
  legacyHasValidPhoto,
} = require('../src/legacy_discover_eligibility_pre_trust_v1');
const discoverEligibility = require('../src/discover_eligibility');

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
    assert.strictEqual(discoverEligibility.deriveDiscoverEligible(flagsEligible), false);
    assert.notStrictEqual(
      deriveLegacyDiscoverEligiblePreTrust(flagsEligible),
      discoverEligibility.deriveDiscoverEligible(flagsEligible),
    );
  });

  it('has no live Discover eligibility dependency', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../src/legacy_discover_eligibility_pre_trust_v1.js'),
      'utf8',
    );
    assert.doesNotMatch(src, /require\(['"]\.\/discover_eligibility['"]\)/);
    assert.doesNotMatch(src, /from ['"]\.\/discover_eligibility['"]/);
    assert.doesNotMatch(src, /\{\s*hasValidPhoto\s*\}/);
    assert.ok(src.includes('legacyHasValidPhoto'));
    assert.ok(src.includes('deriveLegacyDiscoverEligiblePreTrust'));
  });

  it('live hasValidPhoto changes cannot affect the frozen helper', () => {
    const original = discoverEligibility.hasValidPhoto;
    discoverEligibility.hasValidPhoto = () => false;
    try {
      assert.strictEqual(original(flagsEligible), true);
      assert.strictEqual(discoverEligibility.hasValidPhoto(flagsEligible), false);
      assert.strictEqual(legacyHasValidPhoto(flagsEligible), true);
      assert.strictEqual(deriveLegacyDiscoverEligiblePreTrust(flagsEligible), true);
      assert.strictEqual(
        deriveLegacyDiscoverEligiblePreTrust({
          ...flagsEligible,
          profile_photo_url: '',
          photos: ['https://example.com/alt.jpg'],
        }),
        true,
      );
      assert.strictEqual(
        deriveLegacyDiscoverEligiblePreTrust({
          ...flagsEligible,
          profile_photo_url: '',
          photos: [],
        }),
        false,
      );
    } finally {
      discoverEligibility.hasValidPhoto = original;
    }
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
