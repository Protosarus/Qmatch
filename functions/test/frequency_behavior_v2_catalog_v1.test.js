'use strict';

const assert = require('assert');
const catalog = require('../src/frequency_behavior_v2_catalog_v1.generated');
const contract = require('../src/frequency_behavior_v2_contract');

describe('frequency_behavior_v2_catalog_v1', () => {
  it('pins catalog version and runtime_selectable=false', () => {
    assert.strictEqual(catalog.catalog_version, contract.CATALOG_VERSION);
    assert.strictEqual(catalog.runtime_selectable, false);
  });

  for (const [bankVersion, spec] of [
    ['TR', contract.POOL_VERSION_TR],
    ['EN', contract.POOL_VERSION_EN],
  ]) {
    describe(`${bankVersion} bank`, () => {
      let bank;
      before(() => {
        bank = catalog.banks[spec];
        assert.ok(bank, `missing bank ${spec}`);
      });

      it('has expected pool counts', () => {
        assert.strictEqual(bank.question_count, 426);
        assert.strictEqual(bank.option_count, 1704);
        assert.strictEqual(bank.selectable_item_count, 405);
        assert.strictEqual(bank.drop_item_count, 21);
        assert.strictEqual(bank.runtime_selectable, false);
        assert.strictEqual(bank.items.length, 426);
      });

      it('has version pins and source sha256', () => {
        assert.ok(catalog.source_sha256[spec].pool);
        assert.ok(catalog.source_sha256[spec].review);
        assert.strictEqual(
          bank.selection_policy_version,
          contract.SELECTION_POLICY_VERSION,
        );
        assert.strictEqual(
          bank.scoring_policy_version,
          contract.SCORING_POLICY_VERSION,
        );
      });

      if (bankVersion === 'EN') {
        it('has EN translation version and reviewed counts', () => {
          assert.strictEqual(bank.translation_version, contract.TRANSLATION_VERSION_EN);
          let reviewed = 0;
          let pending = 0;
          for (const item of bank.items) {
            const review = bank.review_by_item_id[item.item_id];
            if (review.translation_review_status === 'REVIEWED') reviewed++;
            if (review.translation_review_status === 'PENDING_HUMAN_REVIEW') {
              pending++;
            }
          }
          assert.strictEqual(reviewed, 426);
          assert.strictEqual(pending, 0);
        });
      }

      it('DROP item q0409 remains dropped', () => {
        const item = bank.items_by_id['frequency_v2_q0409'];
        assert.ok(item);
        assert.strictEqual(item.drop_from_selectable, true);
      });

      it('every selectable item has 4 weighted options', () => {
        for (const item of bank.items) {
          assert.strictEqual(item.authored_option_ids.length, 4);
          for (const oid of item.authored_option_ids) {
            const opt = item.options[oid];
            assert.ok(opt.behavioral_weights);
            if (!item.drop_from_selectable) {
              assert.ok(Object.keys(opt.behavioral_weights).length > 0);
            }
          }
        }
      });
    });
  }
});
