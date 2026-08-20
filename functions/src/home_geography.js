/**
 * Coarse geography helpers — port of Dart HomeGeographyNormalizer.
 * Country: ISO-3166-1 alpha-2 uppercase.
 * City: normalized slug for equality queries. Never stores display text.
 */

'use strict';

const ISO2 = /^[A-Z]{2}$/;
const CITY_SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MULTI_HYPHEN = /-{2,}/g;
const EDGE_HYPHEN = /^-+|-+$/g;
const MAX_RAW_CITY = 120;
const MAX_CITY_SLUG = 80;

const LATIN_FOLD = Object.freeze({
  0xc0: 'a', 0xc1: 'a', 0xc2: 'a', 0xc3: 'a', 0xc4: 'a', 0xc5: 'a',
  0xe0: 'a', 0xe1: 'a', 0xe2: 'a', 0xe3: 'a', 0xe4: 'a', 0xe5: 'a',
  0xc8: 'e', 0xc9: 'e', 0xca: 'e', 0xcb: 'e',
  0xe8: 'e', 0xe9: 'e', 0xea: 'e', 0xeb: 'e',
  0xcc: 'i', 0xcd: 'i', 0xce: 'i', 0xcf: 'i',
  0xec: 'i', 0xed: 'i', 0xee: 'i', 0xef: 'i',
  0x0130: 'i',
  0x0131: 'i',
  0xd2: 'o', 0xd3: 'o', 0xd4: 'o', 0xd5: 'o', 0xd6: 'o', 0xd8: 'o',
  0xf2: 'o', 0xf3: 'o', 0xf4: 'o', 0xf5: 'o', 0xf6: 'o', 0xf8: 'o',
  0xd9: 'u', 0xda: 'u', 0xdb: 'u', 0xdc: 'u',
  0xf9: 'u', 0xfa: 'u', 0xfb: 'u', 0xfc: 'u',
  0xc7: 'c', 0xe7: 'c',
  0x011e: 'g', 0x011f: 'g',
  0x015e: 's', 0x015f: 's',
  0xd1: 'n', 0xf1: 'n',
  0xdd: 'y', 0xfd: 'y', 0xff: 'y',
  0xdf: 'ss',
  0xc6: 'ae', 0xe6: 'ae',
  0x0152: 'oe', 0x0153: 'oe',
});

function normalizeCountryCode(raw) {
  if (typeof raw !== 'string') return null;
  const upper = raw.trim().toUpperCase();
  if (!ISO2.test(upper)) return null;
  return upper;
}

function foldChar(code) {
  if (LATIN_FOLD[code]) return LATIN_FOLD[code];
  if (code >= 65 && code <= 90) return String.fromCharCode(code + 32);
  if (code >= 97 && code <= 122) return String.fromCharCode(code);
  if (code >= 48 && code <= 57) return String.fromCharCode(code);
  return null;
}

function normalizeCitySlug(raw) {
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (!trimmed || trimmed.length > MAX_RAW_CITY) return null;
  let folded = '';
  for (const ch of trimmed) {
    const code = ch.codePointAt(0);
    if (code >= 0x0300 && code <= 0x036f) continue;
    const mapped = foldChar(code);
    folded += mapped == null ? '-' : mapped;
  }
  const slug = folded.replace(MULTI_HYPHEN, '-').replace(EDGE_HYPHEN, '');
  if (!slug || slug.length > MAX_CITY_SLUG) return null;
  if (!CITY_SLUG.test(slug)) return null;
  return slug;
}

module.exports = {
  ISO2,
  CITY_SLUG,
  MAX_RAW_CITY,
  MAX_CITY_SLUG,
  normalizeCountryCode,
  normalizeCitySlug,
};
