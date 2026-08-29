#!/usr/bin/env node
/**
 * Generate functions/src/assessment_finalize_catalog_v1.generated.js
 * from canonical Flutter assessment bank assets.
 *
 * Structural IDs/options/dimensions only — no prompts, no IQ answer keys.
 *
 *   node tool/generate_assessment_finalize_catalog_v1.js
 *   node tool/generate_assessment_finalize_catalog_v1.js --check
 */

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT_REL = 'functions/src/assessment_finalize_catalog_v1.generated.js';
const OUTPUT_PATH = path.join(ROOT, OUTPUT_REL);
const CATALOG_VERSION = 'assessment_finalize_catalog_v1';

const IQ_DIMENSION_QUOTAS = Object.freeze({
  logical_reasoning: 7,
  pattern_reasoning: 6,
  verbal_reasoning: 6,
  spatial_reasoning: 6,
});
const IQ_CANONICAL_DIMENSIONS = Object.freeze(Object.keys(IQ_DIMENSION_QUOTAS));
const EQ_CANONICAL_DIMENSIONS = Object.freeze([
  'empathy',
  'perspective_taking',
  'self_awareness',
  'emotion_regulation',
  'emotional_openness',
  'boundary_setting',
  'assertiveness',
  'conflict_approach',
  'repair_orientation',
  'social_awareness',
]);
const FREQUENCY_CANONICAL_DIMENSIONS = Object.freeze([
  'depth_preference',
  'social_energy',
  'spontaneity',
  'stability',
  'disclosure_pace',
  'communication_pace',
]);
const FREQUENCY_BLUEPRINT = Object.freeze({
  core: 30,
  behavioral_equivalence: 12,
  separator: 6,
  response_quality: 2,
});

const SOURCES = Object.freeze([
  Object.freeze({
    assessment_type: 'iq',
    asset_path: 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json',
    selection_policy_version: 'iq_session_selection_v1',
    expected_item_count: 25,
  }),
  Object.freeze({
    assessment_type: 'iq',
    asset_path: 'assets/data/assessment_v3/iq/iq_bank_en_v1.json',
    selection_policy_version: 'iq_session_selection_v1',
    expected_item_count: 25,
  }),
  Object.freeze({
    assessment_type: 'eq',
    asset_path: 'assets/data/assessment_v3/eq/eq_bank_tr_v1.json',
    selection_policy_version: 'eq_30_full_bank_deterministic_v1',
    expected_item_count: 30,
  }),
  Object.freeze({
    assessment_type: 'eq',
    asset_path: 'assets/data/assessment_v3/eq/eq_bank_en_v1.json',
    selection_policy_version: 'eq_30_full_bank_deterministic_v1',
    expected_item_count: 30,
  }),
  Object.freeze({
    assessment_type: 'frequency',
    asset_path: 'assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json',
    selection_policy_version: 'frequency_50_full_bank_deterministic_v1',
    expected_item_count: 50,
  }),
  Object.freeze({
    assessment_type: 'frequency',
    asset_path: 'assets/data/assessment_v3/frequency/frequency_bank_en_v1.json',
    selection_policy_version: 'frequency_50_full_bank_deterministic_v1',
    expected_item_count: 50,
  }),
]);

function fail(message) {
  throw new Error(`assessment_finalize_catalog_v1 generator: ${message}`);
}

function readJsonAsset(relPath) {
  const abs = path.join(ROOT, relPath);
  if (!fs.existsSync(abs)) fail(`missing asset ${relPath}`);
  const raw = fs.readFileSync(abs, 'utf8');
  try {
    return JSON.parse(raw);
  } catch (err) {
    fail(`invalid JSON ${relPath}: ${err.message}`);
  }
}

function assertNonEmptyString(value, label) {
  if (typeof value !== 'string' || value.trim() === '' || value !== value.trim()) {
    fail(`${label} must be a non-empty trimmed string`);
  }
  return value;
}

function uniqueSorted(values) {
  return [...new Set(values)].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
}

function extractOptionIds(item, idField, itemId) {
  if (!Array.isArray(item.options) || item.options.length === 0) {
    fail(`item ${itemId} has no options`);
  }
  const ids = [];
  const seen = new Set();
  for (const option of item.options) {
    if (option === null || typeof option !== 'object' || Array.isArray(option)) {
      fail(`item ${itemId} has a malformed option`);
    }
    const id = option[idField];
    assertNonEmptyString(id, `${itemId} option ${idField}`);
    if (seen.has(id)) fail(`item ${itemId} duplicate option id`);
    seen.add(id);
    ids.push(id);
  }
  return ids;
}

function sortItems(items) {
  return [...items].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
}

function countBy(items, keyFn) {
  const counts = Object.create(null);
  for (const item of items) {
    const key = keyFn(item);
    if (key == null) continue;
    counts[key] = (counts[key] || 0) + 1;
  }
  return counts;
}

function extractIqBank(json, source) {
  if (json.schema_version !== 'qmatch_iq_bank_v1') {
    fail(`unexpected IQ schema_version in ${source.asset_path}`);
  }
  const bankVersion = assertNonEmptyString(json.bank_version, 'IQ bank_version');
  const locale = assertNonEmptyString(json.locale, 'IQ locale');
  if (!Array.isArray(json.items)) fail(`IQ ${source.asset_path} missing items`);

  const items = [];
  const seenIds = new Set();
  for (const raw of json.items) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
      fail(`IQ ${source.asset_path} has a malformed item`);
    }
    const id = assertNonEmptyString(raw.id, 'IQ item id');
    if (seenIds.has(id)) fail(`IQ duplicate item id ${id}`);
    seenIds.add(id);
    const dimension = assertNonEmptyString(raw.dimension, `IQ ${id} dimension`);
    if (!IQ_CANONICAL_DIMENSIONS.includes(dimension)) {
      fail(`IQ ${id} has non-canonical dimension ${dimension}`);
    }
    const templateFamilyId = assertNonEmptyString(
      raw.template_family_id,
      `IQ ${id} template_family_id`,
    );
    items.push({
      id,
      dimension,
      option_ids: extractOptionIds(raw, 'id', id),
      template_family_id: templateFamilyId,
    });
  }

  if (items.length !== 340) {
    fail(`IQ ${source.asset_path} expected 340 items, got ${items.length}`);
  }

  return {
    assessment_type: 'iq',
    source_asset: source.asset_path,
    bank_schema_version: 'qmatch_iq_bank_v1',
    bank_version: bankVersion,
    bank_locale: locale,
    selection_policy_version: source.selection_policy_version,
    expected_item_count: source.expected_item_count,
    require_full_bank: false,
    require_unique_template_families: true,
    canonical_dimensions: [...IQ_CANONICAL_DIMENSIONS],
    dimension_quotas: { ...IQ_DIMENSION_QUOTAS },
    items: sortItems(items),
  };
}

function extractEqBank(json, source) {
  if (json.schema_version !== 'qmatch_eq_bank_v1') {
    fail(`unexpected EQ schema_version in ${source.asset_path}`);
  }
  const bankVersion = assertNonEmptyString(json.bank_version, 'EQ bank_version');
  const locale = assertNonEmptyString(json.locale, 'EQ locale');
  if (!Array.isArray(json.items)) fail(`EQ ${source.asset_path} missing items`);
  if (json.question_count !== 30) {
    fail(`EQ ${source.asset_path} question_count must be 30`);
  }

  const items = [];
  const seenIds = new Set();
  for (const raw of json.items) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
      fail(`EQ ${source.asset_path} has a malformed item`);
    }
    const id = assertNonEmptyString(raw.item_id, 'EQ item_id');
    if (seenIds.has(id)) fail(`EQ duplicate item_id ${id}`);
    seenIds.add(id);
    const dimension = assertNonEmptyString(
      raw.primary_dimension,
      `EQ ${id} primary_dimension`,
    );
    if (!EQ_CANONICAL_DIMENSIONS.includes(dimension)) {
      fail(`EQ ${id} has non-canonical dimension ${dimension}`);
    }
    items.push({
      id,
      dimension,
      option_ids: extractOptionIds(raw, 'option_id', id),
    });
  }

  if (items.length !== 30) {
    fail(`EQ ${source.asset_path} expected 30 items, got ${items.length}`);
  }
  const dimCounts = countBy(items, (item) => item.dimension);
  for (const dim of EQ_CANONICAL_DIMENSIONS) {
    if (dimCounts[dim] !== 3) {
      fail(`EQ ${source.asset_path} ${dim} expected 3 items, got ${dimCounts[dim] || 0}`);
    }
  }

  return {
    assessment_type: 'eq',
    source_asset: source.asset_path,
    bank_schema_version: 'qmatch_eq_bank_v1',
    bank_version: bankVersion,
    bank_locale: locale,
    selection_policy_version: source.selection_policy_version,
    expected_item_count: source.expected_item_count,
    require_full_bank: true,
    require_unique_template_families: false,
    canonical_dimensions: [...EQ_CANONICAL_DIMENSIONS],
    primary_items_per_dimension: 3,
    items: sortItems(items),
  };
}

function extractFrequencyBank(json, source) {
  if (json.schema_version !== 'qmatch_frequency_bank_v1') {
    fail(`unexpected Frequency schema_version in ${source.asset_path}`);
  }
  const bankVersion = assertNonEmptyString(
    json.bank_version,
    'Frequency bank_version',
  );
  const locale = assertNonEmptyString(json.locale, 'Frequency locale');
  if (!Array.isArray(json.items)) {
    fail(`Frequency ${source.asset_path} missing items`);
  }
  if (json.question_count !== 50) {
    fail(`Frequency ${source.asset_path} question_count must be 50`);
  }

  const items = [];
  const seenIds = new Set();
  const roleCounts = {
    core: 0,
    behavioral_equivalence: 0,
    separator: 0,
    response_quality: 0,
  };
  const coreByDim = Object.create(null);
  const relatedByDim = Object.create(null);
  for (const dim of FREQUENCY_CANONICAL_DIMENSIONS) {
    coreByDim[dim] = 0;
    relatedByDim[dim] = 0;
  }

  for (const raw of json.items) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
      fail(`Frequency ${source.asset_path} has a malformed item`);
    }
    const id = assertNonEmptyString(raw.item_id, 'Frequency item_id');
    if (seenIds.has(id)) fail(`Frequency duplicate item_id ${id}`);
    seenIds.add(id);
    const itemRole = assertNonEmptyString(raw.item_role, `Frequency ${id} item_role`);
    if (!Object.prototype.hasOwnProperty.call(roleCounts, itemRole)) {
      fail(`Frequency ${id} unknown item_role ${itemRole}`);
    }
    roleCounts[itemRole] += 1;

    let dimension = null;
    if (itemRole === 'core' || itemRole === 'behavioral_equivalence') {
      dimension = assertNonEmptyString(
        raw.primary_dimension,
        `Frequency ${id} primary_dimension`,
      );
      if (!FREQUENCY_CANONICAL_DIMENSIONS.includes(dimension)) {
        fail(`Frequency ${id} has non-canonical dimension ${dimension}`);
      }
      if (itemRole === 'core') coreByDim[dimension] += 1;
      if (itemRole === 'behavioral_equivalence') relatedByDim[dimension] += 1;
    } else if (raw.primary_dimension != null) {
      fail(`Frequency ${id} ${itemRole} must omit primary_dimension`);
    }

    items.push({
      id,
      dimension,
      item_role: itemRole,
      option_ids: extractOptionIds(raw, 'option_id', id),
    });
  }

  if (items.length !== 50) {
    fail(`Frequency ${source.asset_path} expected 50 items, got ${items.length}`);
  }
  for (const [role, expected] of Object.entries(FREQUENCY_BLUEPRINT)) {
    if (roleCounts[role] !== expected) {
      fail(
        `Frequency ${source.asset_path} ${role} expected ${expected}, got ${roleCounts[role]}`,
      );
    }
  }
  for (const dim of FREQUENCY_CANONICAL_DIMENSIONS) {
    if (coreByDim[dim] !== 5) {
      fail(`Frequency ${source.asset_path} ${dim} core expected 5, got ${coreByDim[dim]}`);
    }
    if (relatedByDim[dim] !== 2) {
      fail(
        `Frequency ${source.asset_path} ${dim} related expected 2, got ${relatedByDim[dim]}`,
      );
    }
  }

  return {
    assessment_type: 'frequency',
    source_asset: source.asset_path,
    bank_schema_version: 'qmatch_frequency_bank_v1',
    bank_version: bankVersion,
    bank_locale: locale,
    selection_policy_version: source.selection_policy_version,
    expected_item_count: source.expected_item_count,
    require_full_bank: true,
    require_unique_template_families: false,
    canonical_dimensions: [...FREQUENCY_CANONICAL_DIMENSIONS],
    blueprint: { ...FREQUENCY_BLUEPRINT },
    primary_core_items_per_dimension: 5,
    related_items_per_dimension: 2,
    items: sortItems(items),
  };
}

function extractBank(source) {
  const json = readJsonAsset(source.asset_path);
  if (source.assessment_type === 'iq') return extractIqBank(json, source);
  if (source.assessment_type === 'eq') return extractEqBank(json, source);
  if (source.assessment_type === 'frequency') {
    return extractFrequencyBank(json, source);
  }
  fail(`unsupported assessment_type ${source.assessment_type}`);
}

function compareBanks(a, b) {
  const keys = ['assessment_type', 'bank_version', 'bank_locale'];
  for (const key of keys) {
    if (a[key] < b[key]) return -1;
    if (a[key] > b[key]) return 1;
  }
  return 0;
}

function buildCatalog() {
  const banks = SOURCES.map((source) => extractBank(source)).sort(compareBanks);
  const keys = banks.map(
    (bank) => `${bank.assessment_type}:${bank.bank_version}:${bank.bank_locale}`,
  );
  if (uniqueSorted(keys).length !== keys.length) {
    fail('duplicate bank identity in generated catalog');
  }
  return {
    catalog_version: CATALOG_VERSION,
    banks,
  };
}

function renderCatalogSource(catalog) {
  const header = [
    `'use strict';`,
    '',
    '/**',
    ' * GENERATED FILE. Do not edit.',
    ' * Regenerated by: node tool/generate_assessment_finalize_catalog_v1.js',
    ' * Contains structural assessment IDs/options/dimensions only.',
    ' */',
    '',
    'module.exports =',
  ].join('\n');
  return `${header} ${JSON.stringify(catalog, null, 2)};\n`;
}

function existingGeneratedSource() {
  if (!fs.existsSync(OUTPUT_PATH)) return null;
  return fs.readFileSync(OUTPUT_PATH, 'utf8');
}

function run(argv) {
  const check = argv.includes('--check');
  const catalog = buildCatalog();
  const source = renderCatalogSource(catalog);
  if (check) {
    const current = existingGeneratedSource();
    if (current !== source) {
      process.stderr.write(
        `${OUTPUT_REL} is stale. Run: node tool/generate_assessment_finalize_catalog_v1.js\n`,
      );
      process.exitCode = 1;
      return;
    }
    process.stdout.write('assessment_finalize_catalog_v1.generated.js is current\n');
    return;
  }
  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, source, 'utf8');
  process.stdout.write(`wrote ${OUTPUT_REL}\n`);
}

module.exports = {
  CATALOG_VERSION,
  OUTPUT_PATH,
  OUTPUT_REL,
  ROOT,
  SOURCES,
  buildCatalog,
  renderCatalogSource,
};

if (require.main === module) {
  run(process.argv.slice(2));
}
