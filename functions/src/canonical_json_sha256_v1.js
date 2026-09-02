/**
 * Deterministic canonical JSON + SHA-256.
 *
 * Object keys are sorted at every nesting level. Array order is preserved.
 * Do not use ordinary object insertion order as a hashing contract.
 */

'use strict';

const crypto = require('crypto');

function canonicalJson(value) {
  if (value === undefined) {
    throw new Error('canonicalJson cannot serialize undefined');
  }
  if (value === null) return 'null';
  const t = typeof value;
  if (t === 'number') {
    if (!Number.isFinite(value)) {
      throw new Error('canonicalJson cannot serialize non-finite numbers');
    }
    return JSON.stringify(value === 0 ? 0 : value);
  }
  if (t === 'boolean') return value ? 'true' : 'false';
  if (t === 'string') return JSON.stringify(value);
  if (Array.isArray(value)) {
    return `[${value.map((item) => canonicalJson(item)).join(',')}]`;
  }
  if (t === 'object') {
    const keys = Object.keys(value).sort();
    const parts = [];
    for (const key of keys) {
      const child = value[key];
      if (child === undefined) continue;
      parts.push(`${JSON.stringify(key)}:${canonicalJson(child)}`);
    }
    return `{${parts.join(',')}}`;
  }
  throw new Error(`canonicalJson cannot serialize ${t}`);
}

function sha256Utf8Hex(text) {
  return crypto.createHash('sha256').update(text, 'utf8').digest('hex');
}

function sha256Canonical(value) {
  return sha256Utf8Hex(canonicalJson(value));
}

module.exports = {
  canonicalJson,
  sha256Utf8Hex,
  sha256Canonical,
};
