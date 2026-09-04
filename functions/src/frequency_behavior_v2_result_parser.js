/**
 * Strict parser for trusted users/{uid}/assessments/frequency_v2.
 *
 * Accepts only the authoritative server result shape.
 * Does not infer, impute, or neutral-fill missing/malformed values.
 */

'use strict';

const contract = require('./frequency_behavior_v2_contract');

function isFiniteNumber(value) {
  return typeof value === 'number' && Number.isFinite(value);
}

function inClosedRange(value, min, max) {
  return isFiniteNumber(value) && value >= min && value <= max;
}

function parseFrequencyV2Result(data) {
  if (data == null || typeof data !== 'object' || Array.isArray(data)) {
    return { ok: false, code: 'malformed_result' };
  }
  if (data.schema_version !== contract.RESULT_SCHEMA_VERSION) {
    return { ok: false, code: 'wrong_schema' };
  }
  if (data.assessment_type !== contract.ASSESSMENT_TYPE) {
    return { ok: false, code: 'wrong_assessment_type' };
  }
  if (data.status !== contract.RESULT_STATUS) {
    return { ok: false, code: 'not_completed' };
  }
  if (data.source !== contract.RESULT_SOURCE) {
    return { ok: false, code: 'untrusted_source' };
  }
  if (!Array.isArray(data.dimensions)) {
    return { ok: false, code: 'malformed_result' };
  }

  const byDimension = Object.create(null);
  const seen = new Set();
  for (const row of data.dimensions) {
    if (row == null || typeof row !== 'object' || Array.isArray(row)) {
      return { ok: false, code: 'malformed_result' };
    }
    const id = row.dimension_id;
    if (typeof id !== 'string' || id.length === 0) {
      return { ok: false, code: 'malformed_result' };
    }
    if (!contract.isCanonicalDimension(id)) {
      return { ok: false, code: 'unknown_dimension' };
    }
    if (seen.has(id)) {
      return { ok: false, code: 'duplicate_dimension' };
    }
    seen.add(id);
    if (!inClosedRange(row.normalized_behavior, -1, 1)) {
      return { ok: false, code: 'invalid_normalized_behavior' };
    }
    if (!inClosedRange(row.provisional_confidence, 0, 1)) {
      return { ok: false, code: 'invalid_provisional_confidence' };
    }
    if (!inClosedRange(row.confidence_completeness, 0, 1)) {
      return { ok: false, code: 'invalid_confidence_completeness' };
    }
    byDimension[id] = {
      dimension_id: id,
      normalized_behavior: row.normalized_behavior,
      provisional_confidence: row.provisional_confidence,
      confidence_completeness: row.confidence_completeness,
    };
  }

  for (const id of contract.CANONICAL_DIMENSIONS) {
    if (!byDimension[id]) {
      return { ok: false, code: 'missing_dimension' };
    }
  }

  return { ok: true, byDimension };
}

function parseFrequencyV2Snapshot(snap) {
  if (!snap || !snap.exists) {
    return { ok: false, code: 'missing_document' };
  }
  try {
    return parseFrequencyV2Result(snap.data());
  } catch (_) {
    return { ok: false, code: 'malformed_result' };
  }
}

function publicUnavailableReason(parsed, role) {
  if (!parsed || parsed.ok) return null;
  if (parsed.code === 'missing_document') {
    return `${role}_frequency_v2_missing`;
  }
  return `${role}_frequency_v2_malformed`;
}

module.exports = {
  parseFrequencyV2Result,
  parseFrequencyV2Snapshot,
  publicUnavailableReason,
};
