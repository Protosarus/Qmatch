'use strict';

const assert = require('assert');
const catalog = require('../src/frequency_behavior_v2_catalog_v1.generated');
const contract = require('../src/frequency_behavior_v2_contract');
const { composeManifest } = require('../src/frequency_behavior_v2_selector');
const {
  SCHEMA_VERSION,
  CATALOG_VERSION,
  ERROR_CODES,
  FrequencyBehaviorV2ValidationError,
  validateFrequencyV2Session,
  validateFrequencyV2SessionOrThrow,
} = require('../src/frequency_behavior_v2_session_validation');

function bankTr() {
  return catalog.banks[contract.POOL_VERSION_TR];
}

function bankEn() {
  return catalog.banks[contract.POOL_VERSION_EN];
}

function buildValidPayload(bank, sessionSeed, overrides = {}) {
  const manifest = composeManifest({
    bank,
    sessionSeed,
    sessionId: overrides.session_id || 'phase7c_test_session',
  });
  const payload = {
    schema_version: SCHEMA_VERSION,
    catalog_version: CATALOG_VERSION,
    session_id: overrides.session_id || manifest.session_id,
    owner_uid: 'owner_uid_phase7c_test',
    assessment_type: contract.ASSESSMENT_TYPE,
    bank_version: bank.bank_version,
    bank_locale: bank.locale,
    selection_policy_version: contract.SELECTION_POLICY_VERSION,
    selector_version: contract.SELECTOR_VERSION,
    session_seed: sessionSeed,
    item_plans: manifest.questions.map((q) => ({
      item_id: q.question_id,
      presented_option_order: q.presented_option_order.slice(),
    })),
    answers: manifest.questions.map((q) => ({
      item_id: q.question_id,
      selected_option_id: q.presented_option_order[0],
    })),
  };
  if (bank.locale === contract.LOCALE_EN) {
    payload.translation_version = contract.TRANSLATION_VERSION_EN;
  }
  return Object.assign(payload, overrides);
}

function assertInvalid(payload, code) {
  const result = validateFrequencyV2Session(payload);
  assert.strictEqual(result.ok, false, `expected ${code}, got success`);
  assert.strictEqual(result.code, code, result.message);
  assert.throws(
    () => validateFrequencyV2SessionOrThrow(payload),
    (err) =>
      err instanceof FrequencyBehaviorV2ValidationError && err.code === code,
  );
}

describe('frequency_behavior_v2_session_validation', () => {
  it('accepts valid TR session with reconstructed plans', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-ok-001');
    const result = validateFrequencyV2Session(payload);
    assert.strictEqual(result.ok, true);
    assert.ok(result.manifest);
    validateFrequencyV2SessionOrThrow(payload);
  });

  it('accepts valid EN session with translation_version', () => {
    const payload = buildValidPayload(bankEn(), 'phase7c-validation-en-001');
    const result = validateFrequencyV2Session(payload);
    assert.strictEqual(result.ok, true);
  });

  it('rejects unsupported schema_version', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-bad-schema');
    payload.schema_version = 'wrong';
    assertInvalid(payload, ERROR_CODES.UNSUPPORTED_SCHEMA_VERSION);
  });

  it('rejects unsupported catalog_version', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-bad-catalog');
    payload.catalog_version = 'wrong';
    assertInvalid(payload, ERROR_CODES.UNSUPPORTED_CATALOG_VERSION);
  });

  it('rejects unsupported assessment_type', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-bad-type');
    payload.assessment_type = 'frequency';
    assertInvalid(payload, ERROR_CODES.UNSUPPORTED_ASSESSMENT_TYPE);
  });

  it('rejects unsupported bank_version', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-bad-bank');
    payload.bank_version = 'missing_bank';
    assertInvalid(payload, ERROR_CODES.UNSUPPORTED_BANK);
  });

  it('rejects missing session_seed', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-no-seed');
    delete payload.session_seed;
    assertInvalid(payload, ERROR_CODES.MISSING_SESSION_SEED);
  });

  it('rejects EN without translation_version', () => {
    const payload = buildValidPayload(bankEn(), 'phase7c-validation-en-missing-tv');
    delete payload.translation_version;
    assertInvalid(payload, ERROR_CODES.MISSING_TRANSLATION_VERSION);
  });

  it('rejects wrong item count', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-count');
    payload.item_plans.pop();
    payload.answers.pop();
    assertInvalid(payload, ERROR_CODES.INVALID_ITEM_COUNT);
  });

  it('rejects duplicate plan item_id', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-dup-plan');
    payload.item_plans[1].item_id = payload.item_plans[0].item_id;
    assertInvalid(payload, ERROR_CODES.DUPLICATE_PLAN_ITEM_ID);
  });

  it('rejects plan/answer mismatch', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-mismatch');
    const planIds = new Set(payload.item_plans.map((p) => p.item_id));
    const swapItem = bankTr().items.find(
      (item) => !planIds.has(item.item_id) && !item.drop_from_selectable,
    );
    assert.ok(swapItem, 'expected off-session selectable item');
    payload.answers[0].item_id = swapItem.item_id;
    assertInvalid(payload, ERROR_CODES.PLAN_ANSWER_MISMATCH);
  });

  it('rejects invalid selected option', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-bad-opt');
    payload.answers[0].selected_option_id = 'not_an_option';
    assertInvalid(payload, ERROR_CODES.INVALID_SELECTED_OPTION);
  });

  it('rejects session reconstruction mismatch (wrong seed)', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-recon-ok');
    payload.session_seed = 'different-seed-will-not-match';
    assertInvalid(payload, ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH);
  });

  it('rejects forbidden authority field normalized_behavior', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-forbidden');
    payload.normalized_behavior = 0.5;
    assertInvalid(payload, ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD);
  });

  it('rejects unexpected top-level field', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-extra');
    payload.debug_notes = 'not allowed';
    assertInvalid(payload, ERROR_CODES.UNEXPECTED_FIELD);
  });

  it('accepts displayed_option_ids alias for presented_option_order', () => {
    const payload = buildValidPayload(bankTr(), 'phase7c-validation-alias');
    payload.item_plans = payload.item_plans.map((p) => ({
      item_id: p.item_id,
      displayed_option_ids: p.presented_option_order,
    }));
    const result = validateFrequencyV2Session(payload);
    assert.strictEqual(result.ok, true);
  });
});
