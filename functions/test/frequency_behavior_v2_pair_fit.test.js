'use strict';

const assert = require('assert');
const contract = require('../src/frequency_behavior_v2_contract');
const {
  policyForDimension,
  rawFitForPolicy,
  pairSupport,
  fitFromParsedUsers,
  FREQUENCY_V2_PUBLIC_KEYS,
  publicFrequencyV2FromFit,
} = require('../src/frequency_behavior_v2_pair_fit');

function parsedUser({ nb = 0, pc = 1, cc = 1, nbBy, pcBy, ccBy } = {}) {
  const byDimension = Object.create(null);
  for (const id of contract.CANONICAL_DIMENSIONS) {
    byDimension[id] = {
      dimension_id: id,
      normalized_behavior: nbBy && nbBy[id] !== undefined ? nbBy[id] : nb,
      provisional_confidence: pcBy && pcBy[id] !== undefined ? pcBy[id] : pc,
      confidence_completeness: ccBy && ccBy[id] !== undefined ? ccBy[id] : cc,
    };
  }
  return { byDimension };
}

describe('frequency_behavior_v2_pair_fit', () => {
  it('pins match Dart contract versions and policy membership', () => {
    assert.strictEqual(contract.PAIR_FIT_VERSION, 'frequency_behavior_v2_pair_fit_v1');
    assert.strictEqual(contract.PAIR_FIT_POLICY_VERSION, 'frequency_pair_fit_policy_v1');
    assert.strictEqual(
      contract.PAIR_RELATION_VERSION,
      'frequency_behavior_v2_pair_relation_v1',
    );
    assert.deepStrictEqual(contract.PAIR_FIT_LINEAR_POLICY_DIMENSIONS, [
      'contact_need',
      'closeness_pace',
      'autonomy',
      'reassurance_need',
      'uncertainty_tolerance',
      'disclosure_pace',
      'boundary_firmness',
      'repair_style',
    ]);
    assert.deepStrictEqual(contract.PAIR_FIT_TOLERANT_POLICY_DIMENSIONS, [
      'initiative',
      'social_energy',
      'structure_preference',
      'adaptability',
    ]);
    assert.strictEqual(policyForDimension('contact_need'), 'SIMILARITY_LINEAR');
    assert.strictEqual(policyForDimension('initiative'), 'SIMILARITY_TOLERANT');
  });

  it('linear raw fit is 1 - halfDelta; tolerant is 1 - halfDelta^2', () => {
    assert.strictEqual(rawFitForPolicy(0, 'SIMILARITY_LINEAR'), 1);
    assert.strictEqual(rawFitForPolicy(2, 'SIMILARITY_LINEAR'), 0);
    assert.strictEqual(rawFitForPolicy(1, 'SIMILARITY_LINEAR'), 0.5);
    assert.strictEqual(rawFitForPolicy(0, 'SIMILARITY_TOLERANT'), 1);
    assert.strictEqual(rawFitForPolicy(2, 'SIMILARITY_TOLERANT'), 0);
    assert.strictEqual(rawFitForPolicy(1, 'SIMILARITY_TOLERANT'), 0.75);
  });

  it('identical full support => raw=1 supported=1 index=100', () => {
    const fit = fitFromParsedUsers(
      parsedUser({ nb: 0.6, pc: 1, cc: 1 }),
      parsedUser({ nb: 0.6, pc: 1, cc: 1 }),
    );
    assert.strictEqual(fit.ok, true);
    assert.strictEqual(fit.overall_raw_fit, 1);
    assert.strictEqual(fit.overall_supported_fit, 1);
    assert.strictEqual(fit.overall_pair_support, 1);
    assert.strictEqual(fit.frequency_fit_index, 100);
  });

  it('zero support keeps raw fit and collapses supported fit to 0.5', () => {
    const fit = fitFromParsedUsers(
      parsedUser({ nb: -0.3, pc: 0, cc: 1 }),
      parsedUser({ nb: -0.3, pc: 0, cc: 1 }),
    );
    assert.strictEqual(fit.overall_raw_fit, 1);
    assert.strictEqual(fit.overall_supported_fit, 0.5);
    assert.strictEqual(fit.overall_pair_support, 0);
    assert.strictEqual(fit.frequency_fit_index, 50);
  });

  it('public diagnostic omits per-dimension and 12D fields', () => {
    const fit = fitFromParsedUsers(
      parsedUser({ nb: 0.2 }),
      parsedUser({ nb: -0.4 }),
    );
    const pub = publicFrequencyV2FromFit(fit);
    assert.deepStrictEqual(Object.keys(pub).sort(), [
      'available',
      'frequency_fit_index',
      'overall_pair_support',
      'overall_supported_fit',
      'pair_fit_version',
    ].sort());
    for (const key of Object.keys(pub)) {
      assert.ok(FREQUENCY_V2_PUBLIC_KEYS.includes(key), key);
    }
    const blob = JSON.stringify(pub);
    assert.strictEqual(blob.includes('normalized_behavior'), false);
    assert.strictEqual(blob.includes('x_a'), false);
    assert.strictEqual(blob.includes('raw_fit'), false);
    assert.strictEqual(blob.includes('contact_need'), false);
    assert.strictEqual(blob.includes('session'), false);
  });

  it('pair support is sqrt of clamped product', () => {
    assert.strictEqual(pairSupport(1, 1), 1);
    assert.strictEqual(pairSupport(0, 1), 0);
    assert.strictEqual(pairSupport(0.25, 0.25), 0.25);
  });
});
