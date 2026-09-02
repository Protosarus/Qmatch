#!/usr/bin/env node
/**
 * Generate functions/src/frequency_behavior_v2_catalog_v1.generated.js
 * from tracked Frequency V2 pool + review metadata artifacts.
 *
 * Structural scoring/selector fields only — prompts included where required
 * for deterministic selector reconstruction (thematic softening).
 *
 *   node tool/generate_frequency_v2_server_catalog_v1.js
 *   node tool/generate_frequency_v2_server_catalog_v1.js --check
 */

'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const OUTPUT_REL = 'functions/src/frequency_behavior_v2_catalog_v1.generated.js';
const OUTPUT_PATH = path.join(ROOT, OUTPUT_REL);
const CATALOG_VERSION = 'frequency_behavior_v2_catalog_v1';

const BANKS = Object.freeze([
  Object.freeze({
    bank_version: 'frequency_behavior_pool_tr_v2_draft1',
    pool_path: 'tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1.json',
    review_path:
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1_review_metadata.json',
    locale: 'tr-TR',
    translation_version: null,
    expected_items: 426,
    expected_options: 1704,
    expected_selectable: 405,
    expected_drop: 21,
  }),
  Object.freeze({
    bank_version: 'frequency_behavior_pool_en_v2_draft1',
    pool_path: 'tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1.json',
    review_path:
      'tool/frequency_behavior_v2/out/frequency_behavior_pool_en_v2_draft1_review_metadata.json',
    locale: 'en-US',
    translation_version: 'frequency_v2_en_semantic_v1',
    expected_items: 426,
    expected_options: 1704,
    expected_selectable: 405,
    expected_drop: 21,
  }),
]);

function fail(message) {
  throw new Error(`frequency_behavior_v2_catalog_v1 generator: ${message}`);
}

function readJson(relPath) {
  const abs = path.join(ROOT, relPath);
  if (!fs.existsSync(abs)) fail(`missing ${relPath}`);
  try {
    return JSON.parse(fs.readFileSync(abs, 'utf8'));
  } catch (err) {
    fail(`invalid JSON ${relPath}: ${err.message}`);
  }
}

function sha256File(relPath) {
  const abs = path.join(ROOT, relPath);
  return crypto.createHash('sha256').update(fs.readFileSync(abs)).digest('hex');
}

function reviewByItemId(reviewDoc) {
  const out = {};
  for (const raw of reviewDoc.items || []) {
    out[raw.item_id] = raw;
  }
  return out;
}

function loadNearDuplicateClusters(reviewDoc) {
  const raw = reviewDoc.semantic_near_duplicate_clusters || [];
  return raw.map((cluster) =>
  (cluster.item_ids || []).map((id) => String(id)),
  );
}

function normalizeEvidenceMeta(raw) {
  const meta = raw || {};
  return {
    version: meta.version || 'frequency_evidence_prior_v1',
    calibration_status: meta.calibration_status || 'uncalibrated',
    review_status: meta.review_status || 'pending',
    social_desirability: meta.social_desirability ?? null,
    obviousness: meta.obviousness ?? null,
    behavioral_plausibility: meta.behavioral_plausibility ?? null,
    self_presentation_risk: meta.self_presentation_risk ?? null,
    diagnostic_value: meta.diagnostic_value ?? null,
    ambiguity: meta.ambiguity ?? null,
  };
}

function buildBankEntry(spec) {
  const pool = readJson(spec.pool_path);
  const reviewDoc = readJson(spec.review_path);
  const reviewMap = reviewByItemId(reviewDoc);

  if (pool.runtime_selectable !== false) {
    fail(`${spec.bank_version}: runtime_selectable must be false`);
  }
  if (pool.pool_version !== spec.bank_version) {
    fail(`${spec.bank_version}: pool_version mismatch`);
  }

  const items = [];
  const itemsById = {};
  let optionCount = 0;
  let selectableCount = 0;
  let dropCount = 0;
  let enReviewed = 0;
  let enPending = 0;

  for (const raw of pool.items) {
    const itemId = raw.item_id;
    const review = reviewMap[itemId] || {};
    const primaryDims = raw.primary_dimensions || [];
    const drop = review.drop_from_selectable === true;
    let primary = primaryDims.length === 1 ? primaryDims[0] : null;
    if (!primary && !drop) {
      fail(`${itemId}: expected single primary dimension or DROP`);
    }
    const selectorEligible = review.selector_eligible === true;
    if (drop) dropCount++;
    if (selectorEligible && !drop) selectableCount++;

    if (spec.locale === 'en-US') {
      const tr = review.translation_review_status;
      if (tr === 'REVIEWED') enReviewed++;
      if (tr === 'PENDING_HUMAN_REVIEW') enPending++;
    }

    const authoredOptionIds = [];
    const options = {};
    for (const opt of raw.options || []) {
      optionCount++;
      authoredOptionIds.push(opt.option_id);
      const weights = {};
      for (const [k, v] of Object.entries(opt.behavioral_weights || {})) {
        weights[k] = Number(v);
      }
      options[opt.option_id] = {
        behavioral_weights: weights,
        evidence_meta: normalizeEvidenceMeta(opt.evidence_meta),
      };
    }
    if (authoredOptionIds.length !== 4) {
      fail(`${itemId}: expected 4 options`);
    }

    const item = {
      item_id: itemId,
      primary_dimension: primary,
      semantic_cluster: raw.semantic_cluster,
      context: (raw.context || []).map(String),
      prompt: String(raw.prompt || ''),
      authored_option_ids: authoredOptionIds,
      selector_eligible: selectorEligible,
      drop_from_selectable: drop,
      options,
      review_status: review.review_status || null,
      rewrite_pending: review.rewrite_pending === true,
      processing_style_present: review.processing_style_present === true,
      primary_review_pending: review.primary_review_pending === true,
      unresolved_dimension_labels: review.unresolved_dimension_labels || [],
    };
    items.push(item);
    itemsById[itemId] = item;
  }

  if (items.length !== spec.expected_items) {
    fail(`${spec.bank_version}: expected ${spec.expected_items} items, got ${items.length}`);
  }
  if (optionCount !== spec.expected_options) {
    fail(
      `${spec.bank_version}: expected ${spec.expected_options} options, got ${optionCount}`,
    );
  }
  if (selectableCount !== spec.expected_selectable) {
    fail(
      `${spec.bank_version}: expected ${spec.expected_selectable} selectable, got ${selectableCount}`,
    );
  }
  if (dropCount !== spec.expected_drop) {
    fail(`${spec.bank_version}: expected ${spec.expected_drop} DROP, got ${dropCount}`);
  }
  if (spec.locale === 'en-US') {
    if (enReviewed !== 426) {
      fail(`${spec.bank_version}: expected 426 EN REVIEWED, got ${enReviewed}`);
    }
    if (enPending !== 0) {
      fail(`${spec.bank_version}: expected 0 EN PENDING, got ${enPending}`);
    }
  }

  const nearDuplicateClusters = loadNearDuplicateClusters(reviewDoc);
  const reviewByItemIdOut = {};
  for (const [id, review] of Object.entries(reviewMap)) {
    reviewByItemIdOut[id] = {
      selector_eligible: review.selector_eligible === true,
      drop_from_selectable: review.drop_from_selectable === true,
      rewrite_pending: review.rewrite_pending === true,
      processing_style_present: review.processing_style_present === true,
      primary_review_pending: review.primary_review_pending === true,
      unresolved_dimension_labels: review.unresolved_dimension_labels || [],
      review_status: review.review_status || null,
      translation_review_status: review.translation_review_status || null,
    };
  }

  return {
    bank_version: spec.bank_version,
    locale: spec.locale,
    translation_version: spec.translation_version,
    scoring_policy_version: pool.scoring_policy_version,
    selection_policy_version: 'frequency_behavior_50_of_426_seeded_quota_v2_draft1',
    runtime_selectable: false,
    question_count: items.length,
    option_count: optionCount,
    selectable_item_count: selectableCount,
    drop_item_count: dropCount,
    items,
    items_by_id: itemsById,
    review_by_item_id: reviewByItemIdOut,
    near_duplicate_clusters: nearDuplicateClusters,
    source_sha256: {
      pool: sha256File(spec.pool_path),
      review: sha256File(spec.review_path),
    },
  };
}

function buildCatalog() {
  const banks = {};
  const sourceSha256 = {};
  for (const spec of BANKS) {
    const bank = buildBankEntry(spec);
    banks[spec.bank_version] = bank;
    sourceSha256[spec.bank_version] = bank.source_sha256;
    delete bank.source_sha256;
  }
  return {
    catalog_version: CATALOG_VERSION,
    runtime_selectable: false,
    scoring_policy_version: 'frequency_behavior_12d_signed_evidence_v2',
    selection_policy_version: 'frequency_behavior_50_of_426_seeded_quota_v2_draft1',
    selector_version: 'frequency_behavior_v2_selector_v1',
    scorer_version: 'frequency_behavior_v2_scorer_v1',
    confidence_model_version: 'frequency_behavior_v2_confidence_v1',
    source_sha256: sourceSha256,
    banks,
  };
}

function renderCatalogSource(catalog) {
  const header = [
    `'use strict';`,
    '',
    '/**',
    ' * GENERATED FILE. Do not edit.',
    ' * Regenerated by: node tool/generate_frequency_v2_server_catalog_v1.js',
    ' * Frequency V2 server catalog — structural fields for selector/scorer/validation.',
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
        `${OUTPUT_REL} is stale. Run: node tool/generate_frequency_v2_server_catalog_v1.js\n`,
      );
      process.exitCode = 1;
      return;
    }
    process.stdout.write('frequency_behavior_v2_catalog_v1.generated.js is current\n');
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
  BANKS,
  buildCatalog,
  renderCatalogSource,
};

if (require.main === module) {
  run(process.argv.slice(2));
}
