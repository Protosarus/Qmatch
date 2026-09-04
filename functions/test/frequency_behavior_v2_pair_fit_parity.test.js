'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { fitFromParsedUsers } = require('../src/frequency_behavior_v2_pair_fit');

const FIXTURE_PATH = path.join(
  __dirname,
  '../../test/fixtures/frequency_v2/pair_fit_js_dart_parity_v1.json',
);
const TOL = 1e-9;

function nearEqual(a, b) {
  return Math.abs(a - b) <= TOL;
}

function parsedFromFixtureUser(user) {
  const byDimension = Object.create(null);
  for (const [id, value] of Object.entries(user.normalized_behavior)) {
    byDimension[id] = {
      dimension_id: id,
      normalized_behavior: value,
      provisional_confidence: user.provisional_confidence[id],
      confidence_completeness: user.confidence_completeness[id],
    };
  }
  return { byDimension };
}

describe('Frequency V2 JS/Dart pair-fit parity fixtures', () => {
  it('JS pair-fit matches committed fixtures within 1e-9', () => {
    const doc = JSON.parse(fs.readFileSync(FIXTURE_PATH, 'utf8'));
    assert.ok(doc.fixture_count >= 12);
    assert.strictEqual(doc.tolerance, 1e-9);
    for (const fixture of doc.fixtures) {
      const fit = fitFromParsedUsers(
        parsedFromFixtureUser(fixture.user_a),
        parsedFromFixtureUser(fixture.user_b),
      );
      const expected = fixture.expected;
      assert.ok(
        nearEqual(fit.overall_raw_fit, expected.overall_raw_fit),
        `${fixture.id} overall_raw_fit js=${fit.overall_raw_fit} exp=${expected.overall_raw_fit}`,
      );
      assert.ok(
        nearEqual(fit.overall_supported_fit, expected.overall_supported_fit),
        fixture.id,
      );
      assert.ok(
        nearEqual(fit.overall_pair_support, expected.overall_pair_support),
        fixture.id,
      );
      assert.ok(
        nearEqual(fit.frequency_fit_index, expected.frequency_fit_index),
        fixture.id,
      );
      assert.strictEqual(fit.dimensions.length, 12);
      for (let i = 0; i < 12; i++) {
        const actual = fit.dimensions[i];
        const exp = expected.dimensions[i];
        assert.strictEqual(actual.dimension_id, exp.dimension_id, fixture.id);
        assert.strictEqual(actual.policy_type, exp.policy_type, fixture.id);
        assert.ok(nearEqual(actual.raw_fit, exp.raw_fit), `${fixture.id} ${actual.dimension_id} raw`);
        assert.ok(
          nearEqual(actual.supported_fit, exp.supported_fit),
          `${fixture.id} ${actual.dimension_id} supported`,
        );
        assert.ok(
          nearEqual(actual.pair_support, exp.pair_support),
          `${fixture.id} ${actual.dimension_id} support`,
        );
      }
    }
  });
});
