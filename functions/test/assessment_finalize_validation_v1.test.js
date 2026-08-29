'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const catalog = require('../src/assessment_finalize_catalog_v1.generated');
const {
  SCHEMA_VERSION,
  CATALOG_VERSION,
  ERROR_CODES,
  AssessmentFinalizeValidationError,
  validateAssessmentFinalizeSession,
  validateAssessmentFinalizeSessionOrThrow,
} = require('../src/assessment_finalize_validation_v1');

function bankFor(assessmentType, locale) {
  const bank = catalog.banks.find(
    (candidate) =>
      candidate.assessment_type === assessmentType && candidate.bank_locale === locale,
  );
  assert.ok(bank, `missing catalog bank ${assessmentType} ${locale}`);
  return bank;
}

function pickIqItems(bank) {
  const remaining = { ...bank.dimension_quotas };
  const usedFamilies = new Set();
  const picked = [];
  for (const item of bank.items) {
    if ((remaining[item.dimension] || 0) <= 0) continue;
    if (usedFamilies.has(item.template_family_id)) continue;
    picked.push(item);
    usedFamilies.add(item.template_family_id);
    remaining[item.dimension] -= 1;
  }
  assert.strictEqual(picked.length, 25);
  return picked;
}

function pickItems(bank) {
  if (bank.assessment_type === 'iq') return pickIqItems(bank);
  return [...bank.items];
}

function buildPayload(bank, items, overrides) {
  const payload = {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: `${bank.assessment_type}_sess_test`,
    owner_uid: 'owner_uid_test',
    assessment_type: bank.assessment_type,
    bank_version: bank.bank_version,
    bank_locale: bank.bank_locale,
    selection_policy_version: bank.selection_policy_version,
    item_plans: items.map((item) => ({
      item_id: item.id,
      displayed_option_ids: [...item.option_ids],
    })),
    answers: items.map((item) => ({
      item_id: item.id,
      selected_option_id: item.option_ids[0],
    })),
  };
  return Object.assign(payload, overrides);
}

function assertInvalid(payload, code) {
  const result = validateAssessmentFinalizeSession(payload);
  assert.strictEqual(result.ok, false, `expected ${code}, got success`);
  assert.strictEqual(result.code, code, result.message);
  assert.ok(result.message);
  assert.doesNotMatch(result.message, /"text"|dimension_deltas|correct_option/);
  assert.throws(
    () => validateAssessmentFinalizeSessionOrThrow(payload),
    (err) =>
      err instanceof AssessmentFinalizeValidationError && err.code === code,
  );
}

const CASES = [
  { type: 'iq', locale: 'en-US' },
  { type: 'eq', locale: 'en-US' },
  { type: 'frequency', locale: 'en-US' },
];

describe('assessment_finalize_validation_v1', () => {
  for (const { type, locale } of CASES) {
    describe(type, () => {
      const bank = bankFor(type, locale);
      const items = pickItems(bank);

      it('accepts a valid complete session', () => {
        const result = validateAssessmentFinalizeSession(buildPayload(bank, items));
        assert.strictEqual(result.ok, true, result.message);
        assert.strictEqual(result.session.assessmentType, type);
        assert.strictEqual(result.session.schemaVersion, SCHEMA_VERSION);
        assert.strictEqual(result.session.catalogVersion, CATALOG_VERSION);
        assert.strictEqual(result.session.bankVersion, bank.bank_version);
        assert.strictEqual(result.session.bankLocale, bank.bank_locale);
        assert.strictEqual(result.session.selectionPolicyVersion, bank.selection_policy_version);
        assert.strictEqual(result.session.itemCount, bank.expected_item_count);
        assert.strictEqual(result.session.normalizedPlans.length, bank.expected_item_count);
        assert.strictEqual(result.session.normalizedAnswers.length, bank.expected_item_count);
        assert.strictEqual(result.session.ownerUid, 'owner_uid_test');
      });

      it('rejects one missing item', () => {
        assertInvalid(buildPayload(bank, items.slice(1)), ERROR_CODES.INVALID_ITEM_COUNT);
      });

      it('rejects one extra item', () => {
        const extra = {
          id: 'not_in_catalog_extra',
          option_ids: [...items[0].option_ids],
        };
        assertInvalid(buildPayload(bank, items.concat(extra)), ERROR_CODES.INVALID_ITEM_COUNT);
      });

      it('rejects a duplicate plan item id', () => {
        const dup = items.map((item, index) => (index === 1 ? items[0] : item));
        assertInvalid(buildPayload(bank, dup), ERROR_CODES.DUPLICATE_PLAN_ITEM_ID);
      });

      it('rejects a duplicate answer item id', () => {
        const payload = buildPayload(bank, items);
        payload.answers[1] = { ...payload.answers[0] };
        assertInvalid(payload, ERROR_CODES.DUPLICATE_ANSWER_ITEM_ID);
      });

      it('rejects an unknown item id', () => {
        const mutated = items.map((item, index) =>
          index === 0
            ? { ...item, id: 'unknown_item_not_in_catalog' }
            : item,
        );
        assertInvalid(buildPayload(bank, mutated), ERROR_CODES.UNKNOWN_ITEM_ID);
      });

      it('rejects an answer for an item not in the plan', () => {
        const payload = buildPayload(bank, items);
        const outsider = bank.items.find((item) => !items.some((picked) => picked.id === item.id));
        if (type === 'iq') {
          assert.ok(outsider);
          payload.answers[0] = {
            item_id: outsider.id,
            selected_option_id: outsider.option_ids[0],
          };
          assertInvalid(payload, ERROR_CODES.PLAN_ANSWER_MISMATCH);
        } else {
          payload.answers[0] = {
            item_id: 'unknown_item_not_in_catalog',
            selected_option_id: items[0].option_ids[0],
          };
          assertInvalid(payload, ERROR_CODES.PLAN_ANSWER_MISMATCH);
        }
      });

      it('rejects a missing answer', () => {
        const payload = buildPayload(bank, items);
        payload.answers = payload.answers.slice(1);
        assertInvalid(payload, ERROR_CODES.PLAN_ANSWER_MISMATCH);
      });

      it('rejects an unknown selected option', () => {
        const payload = buildPayload(bank, items);
        payload.answers[0] = {
          item_id: items[0].id,
          selected_option_id: 'not_an_option',
        };
        assertInvalid(payload, ERROR_CODES.INVALID_SELECTED_OPTION);
      });

      it('rejects a selected option that is not displayed', () => {
        const payload = buildPayload(bank, items);
        payload.item_plans[0] = {
          item_id: items[0].id,
          displayed_option_ids: items[0].option_ids.slice(1),
        };
        payload.answers[0] = {
          item_id: items[0].id,
          selected_option_id: items[0].option_ids[0],
        };
        assertInvalid(payload, ERROR_CODES.INVALID_SELECTED_OPTION);
      });

      it('rejects an invalid bank version', () => {
        assertInvalid(
          buildPayload(bank, items, { bank_version: 'not_a_bank' }),
          ERROR_CODES.UNSUPPORTED_BANK,
        );
      });

      it('rejects an invalid catalog version', () => {
        assertInvalid(
          buildPayload(bank, items, { catalog_version: 'assessment_finalize_catalog_v0' }),
          ERROR_CODES.UNSUPPORTED_CATALOG_VERSION,
        );
      });

      it('rejects an invalid selection policy', () => {
        assertInvalid(
          buildPayload(bank, items, { selection_policy_version: 'not_a_policy' }),
          ERROR_CODES.UNSUPPORTED_SELECTION_POLICY,
        );
      });

      it('rejects malformed arrays and nested objects', () => {
        assertInvalid(
          buildPayload(bank, items, { item_plans: { not: 'array' } }),
          ERROR_CODES.INVALID_ITEM_PLANS,
        );
        assertInvalid(
          buildPayload(bank, items, { answers: null }),
          ERROR_CODES.INVALID_ANSWERS,
        );
        const nested = buildPayload(bank, items);
        nested.item_plans[0] = ['not-an-object'];
        assertInvalid(nested, ERROR_CODES.INVALID_ITEM_PLANS);
      });

      it('rejects the wrong expected count', () => {
        assertInvalid(buildPayload(bank, items.slice(0, 2)), ERROR_CODES.INVALID_ITEM_COUNT);
      });

      it('rejects an invalid owner_uid', () => {
        assertInvalid(buildPayload(bank, items, { owner_uid: '' }), ERROR_CODES.INVALID_OWNER_UID);
        assertInvalid(buildPayload(bank, items, { owner_uid: ' padded ' }), ERROR_CODES.INVALID_OWNER_UID);
        const numeric = buildPayload(bank, items);
        numeric.owner_uid = 123;
        assertInvalid(numeric, ERROR_CODES.INVALID_OWNER_UID);
      });

      it('rejects an invalid or oversized session_id', () => {
        assertInvalid(buildPayload(bank, items, { session_id: '' }), ERROR_CODES.INVALID_SESSION_ID);
        assertInvalid(
          buildPayload(bank, items, { session_id: 'x'.repeat(129) }),
          ERROR_CODES.INVALID_SESSION_ID,
        );
      });

      it('rejects authority-like fields instead of trusting them', () => {
        for (const field of [
          'completed',
          'test_completed',
          'assessment_flow_completed',
        ]) {
          const forged = buildPayload(bank, items, { [field]: true });
          assertInvalid(forged, ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD);
        }
        const incomplete = buildPayload(bank, items.slice(1), { completed: true });
        assertInvalid(incomplete, ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD);
      });
    });
  }

  it('rejects a non-object payload', () => {
    assertInvalid(null, ERROR_CODES.INVALID_PAYLOAD);
    assertInvalid([], ERROR_CODES.INVALID_PAYLOAD);
    assertInvalid('session', ERROR_CODES.INVALID_PAYLOAD);
  });

  it('rejects an unsupported schema_version', () => {
    const bank = bankFor('eq', 'en-US');
    assertInvalid(
      buildPayload(bank, pickItems(bank), { schema_version: 'qmatch_eq_persisted_session_v1' }),
      ERROR_CODES.UNSUPPORTED_SCHEMA_VERSION,
    );
  });

  describe('iq structural contract', () => {
    const bank = bankFor('iq', 'en-US');

    it('rejects the wrong dimension quota', () => {
      const usedFamilies = new Set();
      const logical = [];
      for (const item of bank.items) {
        if (item.dimension !== 'logical_reasoning') continue;
        if (usedFamilies.has(item.template_family_id)) continue;
        logical.push(item);
        usedFamilies.add(item.template_family_id);
        if (logical.length === 25) break;
      }
      assert.strictEqual(logical.length, 25);
      assertInvalid(buildPayload(bank, logical), ERROR_CODES.INVALID_DIMENSION_QUOTA);
    });

    it('rejects a repeated template family', () => {
      const items = pickIqItems(bank);
      const firstLogical = items.find((item) => item.dimension === 'logical_reasoning');
      const sibling = bank.items.find(
        (item) =>
          item.template_family_id === firstLogical.template_family_id &&
          item.id !== firstLogical.id &&
          item.dimension === firstLogical.dimension,
      );
      assert.ok(sibling);
      const replaceIndex = items.findIndex(
        (item) => item.dimension === firstLogical.dimension && item.id !== firstLogical.id,
      );
      const mutated = items.map((item, index) => (index === replaceIndex ? sibling : item));
      assertInvalid(buildPayload(bank, mutated), ERROR_CODES.DUPLICATE_TEMPLATE_FAMILY);
    });

    it('accepts the matching TR bank', () => {
      const tr = bankFor('iq', 'tr-TR');
      const result = validateAssessmentFinalizeSession(buildPayload(tr, pickIqItems(tr)));
      assert.strictEqual(result.ok, true, result.message);
      assert.strictEqual(result.session.bankVersion, 'tr_v2_340');
    });
  });

  describe('eq structural contract', () => {
    const bank = bankFor('eq', 'en-US');
    const items = pickItems(bank);

    it('rejects wrong dimension coverage / mismatched primary_dimension', () => {
      const payload = buildPayload(bank, items);
      const other = items.find((item) => item.dimension !== items[0].dimension);
      payload.item_plans[0] = {
        ...payload.item_plans[0],
        primary_dimension: other.dimension,
      };
      assertInvalid(payload, ERROR_CODES.INVALID_DIMENSION_COVERAGE);
    });

    it('accepts the matching TR bank', () => {
      const tr = bankFor('eq', 'tr-TR');
      const result = validateAssessmentFinalizeSession(buildPayload(tr, pickItems(tr)));
      assert.strictEqual(result.ok, true, result.message);
      assert.strictEqual(result.session.itemCount, 30);
    });
  });

  describe('frequency structural contract', () => {
    const bank = bankFor('frequency', 'en-US');
    const items = pickItems(bank);

    it('rejects a role / dimension contract violation', () => {
      const quality = items.find((item) => item.item_role === 'response_quality');
      assert.ok(quality);
      const payload = buildPayload(bank, items);
      const index = items.findIndex((item) => item.id === quality.id);
      payload.item_plans[index] = {
        ...payload.item_plans[index],
        item_role: 'core',
        primary_dimension: 'depth_preference',
      };
      assertInvalid(payload, ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT);
    });

    it('accepts the matching TR bank', () => {
      const tr = bankFor('frequency', 'tr-TR');
      const result = validateAssessmentFinalizeSession(buildPayload(tr, pickItems(tr)));
      assert.strictEqual(result.ok, true, result.message);
      assert.strictEqual(result.session.itemCount, 50);
    });
  });
});

describe('assessment_finalize load safety', () => {
  it('does not initialize Firebase or register functions', () => {
    const catalogSrc = fs.readFileSync(
      path.join(__dirname, '../src/assessment_finalize_catalog_v1.generated.js'),
      'utf8',
    );
    const validatorSrc = fs.readFileSync(
      path.join(__dirname, '../src/assessment_finalize_validation_v1.js'),
      'utf8',
    );
    for (const source of [catalogSrc, validatorSrc]) {
      assert.doesNotMatch(source, /initializeApp/);
      assert.doesNotMatch(source, /firebase-admin/);
      assert.doesNotMatch(source, /firebase-functions/);
      assert.doesNotMatch(source, /onCall|onRequest|onDocumentWritten/);
      assert.doesNotMatch(source, /https?:\/\//);
      assert.doesNotMatch(source, /writeFileSync|createWriteStream/);
    }
    const { getApps } = require('firebase-admin/app');
    const before = getApps().length;
    delete require.cache[require.resolve('../src/assessment_finalize_catalog_v1.generated')];
    delete require.cache[require.resolve('../src/assessment_finalize_validation_v1')];
    require('../src/assessment_finalize_catalog_v1.generated');
    require('../src/assessment_finalize_validation_v1');
    assert.strictEqual(getApps().length, before);
  });
});
