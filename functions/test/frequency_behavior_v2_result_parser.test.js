'use strict';

const assert = require('assert');
const contract = require('../src/frequency_behavior_v2_contract');
const { parseFrequencyV2Result } = require('../src/frequency_behavior_v2_result_parser');

function validRow(id, extra = {}) {
  return {
    dimension_id: id,
    normalized_behavior: 0.25,
    provisional_confidence: 0.8,
    confidence_completeness: 1,
    ...extra,
  };
}

function validDoc(overrides = {}) {
  return {
    schema_version: contract.RESULT_SCHEMA_VERSION,
    assessment_type: contract.ASSESSMENT_TYPE,
    status: contract.RESULT_STATUS,
    source: contract.RESULT_SOURCE,
    dimensions: contract.CANONICAL_DIMENSIONS.map((id) => validRow(id)),
    ...overrides,
  };
}

describe('frequency_behavior_v2_result_parser', () => {
  it('accepts a complete authoritative result', () => {
    const parsed = parseFrequencyV2Result(validDoc());
    assert.strictEqual(parsed.ok, true);
    assert.strictEqual(Object.keys(parsed.byDimension).length, 12);
    assert.strictEqual(parsed.byDimension.contact_need.normalized_behavior, 0.25);
  });

  it('refuses client-like fabricated source', () => {
    const parsed = parseFrequencyV2Result(
      validDoc({ source: 'client_frequency_v2_write' }),
    );
    assert.deepStrictEqual(parsed, { ok: false, code: 'untrusted_source' });
  });

  it('refuses wrong schema', () => {
    assert.strictEqual(
      parseFrequencyV2Result(validDoc({ schema_version: 'qmatch_frequency_v1' }))
        .code,
      'wrong_schema',
    );
  });

  it('refuses wrong assessment type', () => {
    assert.strictEqual(
      parseFrequencyV2Result(validDoc({ assessment_type: 'frequency' })).code,
      'wrong_assessment_type',
    );
  });

  it('refuses non-completed result', () => {
    assert.strictEqual(
      parseFrequencyV2Result(validDoc({ status: 'pending' })).code,
      'not_completed',
    );
  });

  it('refuses missing dimension', () => {
    const doc = validDoc();
    doc.dimensions = doc.dimensions.slice(1);
    assert.strictEqual(parseFrequencyV2Result(doc).code, 'missing_dimension');
  });

  it('refuses duplicate dimension', () => {
    const doc = validDoc();
    doc.dimensions[1] = validRow('contact_need');
    assert.strictEqual(parseFrequencyV2Result(doc).code, 'duplicate_dimension');
  });

  it('refuses unknown dimension', () => {
    const doc = validDoc();
    doc.dimensions.push(validRow('processing_style'));
    assert.strictEqual(parseFrequencyV2Result(doc).code, 'unknown_dimension');
  });

  it('refuses normalized_behavior outside [-1, 1]', () => {
    const doc = validDoc();
    doc.dimensions[0] = validRow('contact_need', { normalized_behavior: 1.01 });
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_normalized_behavior',
    );
    doc.dimensions[0] = validRow('contact_need', { normalized_behavior: -1.01 });
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_normalized_behavior',
    );
  });

  it('refuses confidence outside [0, 1]', () => {
    const doc = validDoc();
    doc.dimensions[0] = validRow('contact_need', { provisional_confidence: 1.2 });
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_provisional_confidence',
    );
    doc.dimensions[0] = validRow('contact_need', { provisional_confidence: -0.01 });
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_provisional_confidence',
    );
  });

  it('refuses completeness outside [0, 1]', () => {
    const doc = validDoc();
    doc.dimensions[0] = validRow('contact_need', {
      confidence_completeness: 1.1,
    });
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_confidence_completeness',
    );
  });

  it('refuses NaN and infinity without fallback-to-neutral', () => {
    const nanDoc = validDoc();
    nanDoc.dimensions[0] = validRow('contact_need', {
      normalized_behavior: Number.NaN,
    });
    assert.strictEqual(
      parseFrequencyV2Result(nanDoc).code,
      'invalid_normalized_behavior',
    );
    const infDoc = validDoc();
    infDoc.dimensions[0] = validRow('contact_need', {
      provisional_confidence: Number.POSITIVE_INFINITY,
    });
    assert.strictEqual(
      parseFrequencyV2Result(infDoc).code,
      'invalid_provisional_confidence',
    );
  });

  it('refuses omitted normalized_behavior instead of filling 0', () => {
    const doc = validDoc();
    delete doc.dimensions[0].normalized_behavior;
    assert.strictEqual(
      parseFrequencyV2Result(doc).code,
      'invalid_normalized_behavior',
    );
  });

  it('accepts boundary values -1, +1, 0, 1', () => {
    const doc = validDoc();
    doc.dimensions[0] = validRow('contact_need', {
      normalized_behavior: -1,
      provisional_confidence: 0,
      confidence_completeness: 0,
    });
    doc.dimensions[1] = validRow('closeness_pace', {
      normalized_behavior: 1,
      provisional_confidence: 1,
      confidence_completeness: 1,
    });
    const parsed = parseFrequencyV2Result(doc);
    assert.strictEqual(parsed.ok, true);
    assert.strictEqual(parsed.byDimension.contact_need.normalized_behavior, -1);
    assert.strictEqual(parsed.byDimension.closeness_pace.normalized_behavior, 1);
  });
});
