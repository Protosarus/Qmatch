'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '../..');
const generator = require('../../tool/generate_assessment_finalize_catalog_v1');
const generated = require('../src/assessment_finalize_catalog_v1.generated');

function loadAsset(rel) {
  return JSON.parse(fs.readFileSync(path.join(ROOT, rel), 'utf8'));
}

function optionIds(item, field) {
  return item.options.map((option) => option[field]);
}

describe('assessment_finalize_catalog_v1 generated', () => {
  it('uses the frozen catalog_version', () => {
    assert.strictEqual(generated.catalog_version, 'assessment_finalize_catalog_v1');
    assert.strictEqual(generator.CATALOG_VERSION, generated.catalog_version);
  });

  it('contains exactly the six live TR/EN banks', () => {
    const keys = generated.banks.map(
      (bank) => `${bank.assessment_type}:${bank.bank_version}:${bank.bank_locale}`,
    );
    assert.deepStrictEqual(keys, [
      'eq:eq_bank_en_v1:en-US',
      'eq:eq_bank_tr_v1:tr-TR',
      'frequency:frequency_bank_en_v1:en-US',
      'frequency:frequency_bank_tr_v1:tr-TR',
      'iq:en_v2_340:en-US',
      'iq:tr_v2_340:tr-TR',
    ]);
  });

  it('is deterministic and matches the checked-in file', () => {
    const first = generator.buildCatalog();
    const second = generator.buildCatalog();
    assert.deepStrictEqual(first, second);
    const rendered = generator.renderCatalogSource(first);
    const onDisk = fs.readFileSync(generator.OUTPUT_PATH, 'utf8');
    assert.strictEqual(rendered, onDisk);
    const again = generator.renderCatalogSource(second);
    assert.strictEqual(again, rendered);
  });

  it('passes generator --check against current assets', () => {
    const result = spawnSync(
      process.execPath,
      [path.join(ROOT, 'tool/generate_assessment_finalize_catalog_v1.js'), '--check'],
      { encoding: 'utf8' },
    );
    assert.strictEqual(result.status, 0, result.stderr);
    assert.match(result.stdout, /is current/);
  });

  it('does not embed prompts, IQ answer keys, or Firebase wiring', () => {
    const source = fs.readFileSync(generator.OUTPUT_PATH, 'utf8');
    assert.doesNotMatch(source, /correct_option_id/);
    assert.doesNotMatch(source, /"prompt"/);
    assert.doesNotMatch(source, /dimension_deltas/);
    assert.doesNotMatch(source, /initializeApp/);
    assert.doesNotMatch(source, /firebase-admin/);
    assert.doesNotMatch(source, /firebase-functions/);
  });

  for (const bank of generated.banks) {
    it(`${bank.assessment_type} ${bank.bank_locale} matches canonical asset IDs/options`, () => {
      const asset = loadAsset(bank.source_asset);
      const rawItems = asset.items;
      const catalogIds = bank.items.map((item) => item.id);
      assert.deepStrictEqual(catalogIds, [...catalogIds].sort());
      assert.strictEqual(new Set(catalogIds).size, catalogIds.length);

      if (bank.assessment_type === 'iq') {
        assert.strictEqual(bank.items.length, 340);
        assert.strictEqual(bank.expected_item_count, 25);
        const assetIds = rawItems.map((item) => item.id).sort();
        assert.deepStrictEqual(catalogIds, assetIds);
        for (const item of bank.items) {
          const raw = rawItems.find((candidate) => candidate.id === item.id);
          assert.ok(raw);
          assert.deepStrictEqual(item.option_ids, optionIds(raw, 'id'));
          assert.strictEqual(item.dimension, raw.dimension);
          assert.strictEqual(item.template_family_id, raw.template_family_id);
          assert.strictEqual(new Set(item.option_ids).size, item.option_ids.length);
          assert.ok(!Object.prototype.hasOwnProperty.call(item, 'correct_option_id'));
        }
        assert.deepStrictEqual(bank.dimension_quotas, {
          logical_reasoning: 7,
          pattern_reasoning: 6,
          verbal_reasoning: 6,
          spatial_reasoning: 6,
        });
      }

      if (bank.assessment_type === 'eq') {
        assert.strictEqual(bank.items.length, 30);
        assert.strictEqual(bank.expected_item_count, 30);
        const assetIds = rawItems.map((item) => item.item_id).sort();
        assert.deepStrictEqual(catalogIds, assetIds);
        const dimCounts = Object.create(null);
        for (const item of bank.items) {
          const raw = rawItems.find((candidate) => candidate.item_id === item.id);
          assert.ok(raw);
          assert.deepStrictEqual(item.option_ids, optionIds(raw, 'option_id'));
          assert.strictEqual(item.dimension, raw.primary_dimension);
          assert.strictEqual(new Set(item.option_ids).size, item.option_ids.length);
          dimCounts[item.dimension] = (dimCounts[item.dimension] || 0) + 1;
        }
        for (const dim of bank.canonical_dimensions) {
          assert.strictEqual(dimCounts[dim], 3);
        }
      }

      if (bank.assessment_type === 'frequency') {
        assert.strictEqual(bank.items.length, 50);
        assert.strictEqual(bank.expected_item_count, 50);
        const assetIds = rawItems.map((item) => item.item_id).sort();
        assert.deepStrictEqual(catalogIds, assetIds);
        const roles = {
          core: 0,
          behavioral_equivalence: 0,
          separator: 0,
          response_quality: 0,
        };
        const coreByDim = Object.create(null);
        const relatedByDim = Object.create(null);
        for (const item of bank.items) {
          const raw = rawItems.find((candidate) => candidate.item_id === item.id);
          assert.ok(raw);
          assert.deepStrictEqual(item.option_ids, optionIds(raw, 'option_id'));
          assert.strictEqual(item.item_role, raw.item_role);
          assert.strictEqual(item.dimension, raw.primary_dimension ?? null);
          assert.strictEqual(new Set(item.option_ids).size, item.option_ids.length);
          roles[item.item_role] += 1;
          if (item.item_role === 'core') {
            coreByDim[item.dimension] = (coreByDim[item.dimension] || 0) + 1;
          }
          if (item.item_role === 'behavioral_equivalence') {
            relatedByDim[item.dimension] = (relatedByDim[item.dimension] || 0) + 1;
          }
        }
        assert.deepStrictEqual(roles, {
          core: 30,
          behavioral_equivalence: 12,
          separator: 6,
          response_quality: 2,
        });
        for (const dim of bank.canonical_dimensions) {
          assert.strictEqual(coreByDim[dim], 5);
          assert.strictEqual(relatedByDim[dim], 2);
        }
      }
    });
  }
});
