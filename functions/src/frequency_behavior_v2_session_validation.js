'use strict';

const contract = require('./frequency_behavior_v2_contract');
const catalogModule = require('./frequency_behavior_v2_catalog_v1.generated');
const { composeManifest } = require('./frequency_behavior_v2_selector');

const MAX_SESSION_ID_LENGTH = 128;
const MAX_OWNER_UID_LENGTH = 128;
const MAX_ID_LENGTH = 128;
const MAX_PAYLOAD_CHARS = 256 * 1024;
const MAX_OPTION_LIST_LENGTH = 8;

const ALLOWED_PAYLOAD_KEYS = new Set([
  'schema_version',
  'catalog_version',
  'session_id',
  'owner_uid',
  'assessment_type',
  'bank_version',
  'bank_locale',
  'selection_policy_version',
  'selector_version',
  'session_seed',
  'translation_version',
  'item_plans',
  'answers',
]);

const ALLOWED_PLAN_KEYS = new Set([
  'item_id',
  'presented_option_order',
  'displayed_option_ids',
]);

const ALLOWED_ANSWER_KEYS = new Set(['item_id', 'selected_option_id']);

const FORBIDDEN_AUTHORITY_KEYS = new Set([
  'completed',
  'test_completed',
  'assessment_flow_completed',
  'iq_test_completed',
  'eq_test_completed',
  'frequency_test_completed',
  'iq_completed',
  'eq_completed',
  'frequency_completed',
  'remote_finalized',
  'score',
  'normalized_score',
  'dimension_score',
  'dimension_scores',
  'canonical_v1',
  'canonical_dimensions',
  'canonical_score',
  'status',
  'completed_at',
  'completion',
  'iq_score',
  'eq_score',
  'frequency_score',
  'normalized_behavior',
  'behavioral_mean_12d',
  'provisional_confidence',
  'confidence_flags',
  'dimensions',
  'summary',
  'global_support',
  'cross_context_consistency',
  'cross_context_coverage',
  'pair_fit',
  'pair_relation',
  'signed_pole',
  'mixed_density',
  'telemetry',
]);

const ERROR_CODES = Object.freeze({
  INVALID_PAYLOAD: 'INVALID_PAYLOAD',
  PAYLOAD_TOO_LARGE: 'PAYLOAD_TOO_LARGE',
  UNEXPECTED_FIELD: 'UNEXPECTED_FIELD',
  FORBIDDEN_AUTHORITY_FIELD: 'FORBIDDEN_AUTHORITY_FIELD',
  UNSUPPORTED_SCHEMA_VERSION: 'UNSUPPORTED_SCHEMA_VERSION',
  UNSUPPORTED_CATALOG_VERSION: 'UNSUPPORTED_CATALOG_VERSION',
  INVALID_SESSION_ID: 'INVALID_SESSION_ID',
  INVALID_OWNER_UID: 'INVALID_OWNER_UID',
  UNSUPPORTED_ASSESSMENT_TYPE: 'UNSUPPORTED_ASSESSMENT_TYPE',
  UNSUPPORTED_BANK: 'UNSUPPORTED_BANK',
  UNSUPPORTED_SELECTION_POLICY: 'UNSUPPORTED_SELECTION_POLICY',
  UNSUPPORTED_SELECTOR_VERSION: 'UNSUPPORTED_SELECTOR_VERSION',
  MISSING_SESSION_SEED: 'MISSING_SESSION_SEED',
  MISSING_TRANSLATION_VERSION: 'MISSING_TRANSLATION_VERSION',
  INVALID_ITEM_PLANS: 'INVALID_ITEM_PLANS',
  INVALID_ANSWERS: 'INVALID_ANSWERS',
  INVALID_ITEM_COUNT: 'INVALID_ITEM_COUNT',
  DUPLICATE_PLAN_ITEM_ID: 'DUPLICATE_PLAN_ITEM_ID',
  DUPLICATE_ANSWER_ITEM_ID: 'DUPLICATE_ANSWER_ITEM_ID',
  PLAN_ANSWER_MISMATCH: 'PLAN_ANSWER_MISMATCH',
  UNKNOWN_ITEM_ID: 'UNKNOWN_ITEM_ID',
  INVALID_PRESENTED_OPTIONS: 'INVALID_PRESENTED_OPTIONS',
  INVALID_SELECTED_OPTION: 'INVALID_SELECTED_OPTION',
  INVALID_PLAN_FIELD: 'INVALID_PLAN_FIELD',
  DROP_ITEM_IN_SESSION: 'DROP_ITEM_IN_SESSION',
  SESSION_RECONSTRUCTION_MISMATCH: 'SESSION_RECONSTRUCTION_MISMATCH',
  RUNTIME_SELECTABLE_ACTIVE: 'RUNTIME_SELECTABLE_ACTIVE',
});

class FrequencyBehaviorV2ValidationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'FrequencyBehaviorV2ValidationError';
    this.code = code;
  }
}

function findForbiddenAuthorityKey(value, path) {
  if (value == null || typeof value !== 'object') return null;
  if (Array.isArray(value)) {
    for (let i = 0; i < value.length; i++) {
      const hit = findForbiddenAuthorityKey(value[i], `${path}[${i}]`);
      if (hit) return hit;
    }
    return null;
  }
  for (const [key, child] of Object.entries(value)) {
    if (FORBIDDEN_AUTHORITY_KEYS.has(key)) {
      return { key, path: path ? `${path}.${key}` : key };
    }
    const hit = findForbiddenAuthorityKey(child, path ? `${path}.${key}` : key);
    if (hit) return hit;
  }
  return null;
}

function assertTrimmedId(value, maxLen, label) {
  if (typeof value !== 'string' || value.trim() === '' || value !== value.trim()) {
    return { ok: false, code: label };
  }
  if (value.length > maxLen) {
    return { ok: false, code: label };
  }
  return { ok: true, value };
}

function getBank(bankVersion) {
  return catalogModule.banks[bankVersion] || null;
}

function planOptionOrder(plan) {
  if (Array.isArray(plan.presented_option_order)) {
    return plan.presented_option_order;
  }
  if (Array.isArray(plan.displayed_option_ids)) {
    return plan.displayed_option_ids;
  }
  return null;
}

function validateFrequencyV2Session(payload) {
  if (payload == null || typeof payload !== 'object' || Array.isArray(payload)) {
    return err(ERROR_CODES.INVALID_PAYLOAD, 'payload must be an object');
  }

  const serialized = JSON.stringify(payload);
  if (serialized.length > MAX_PAYLOAD_CHARS) {
    return err(ERROR_CODES.PAYLOAD_TOO_LARGE, 'payload exceeds size limit');
  }

  const forbidden = findForbiddenAuthorityKey(payload, '');
  if (forbidden) {
    return err(
      ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
      `forbidden authority field ${forbidden.key}`,
    );
  }

  for (const key of Object.keys(payload)) {
    if (!ALLOWED_PAYLOAD_KEYS.has(key)) {
      return err(ERROR_CODES.UNEXPECTED_FIELD, `unexpected field ${key}`);
    }
  }

  if (payload.schema_version !== contract.SCHEMA_VERSION) {
    return err(
      ERROR_CODES.UNSUPPORTED_SCHEMA_VERSION,
      `unsupported schema_version ${payload.schema_version}`,
    );
  }
  if (payload.catalog_version !== contract.CATALOG_VERSION) {
    return err(
      ERROR_CODES.UNSUPPORTED_CATALOG_VERSION,
      `unsupported catalog_version ${payload.catalog_version}`,
    );
  }

  const sessionId = assertTrimmedId(
    payload.session_id,
    MAX_SESSION_ID_LENGTH,
    ERROR_CODES.INVALID_SESSION_ID,
  );
  if (!sessionId.ok) {
    return err(sessionId.code, 'invalid session_id');
  }
  const ownerUid = assertTrimmedId(
    payload.owner_uid,
    MAX_OWNER_UID_LENGTH,
    ERROR_CODES.INVALID_OWNER_UID,
  );
  if (!ownerUid.ok) {
    return err(ownerUid.code, 'invalid owner_uid');
  }

  if (payload.assessment_type !== contract.ASSESSMENT_TYPE) {
    return err(
      ERROR_CODES.UNSUPPORTED_ASSESSMENT_TYPE,
      `unsupported assessment_type ${payload.assessment_type}`,
    );
  }

  const bank = getBank(payload.bank_version);
  if (!bank) {
    return err(ERROR_CODES.UNSUPPORTED_BANK, `unsupported bank ${payload.bank_version}`);
  }
  const bankLocale = bank.bank_locale || bank.locale;
  if (bankLocale !== payload.bank_locale) {
    return err(ERROR_CODES.UNSUPPORTED_BANK, 'bank_locale mismatch');
  }
  if (bank.runtime_selectable === true || catalogModule.runtime_selectable === true) {
    return err(ERROR_CODES.RUNTIME_SELECTABLE_ACTIVE, 'runtime_selectable must be false');
  }
  if (payload.selection_policy_version !== contract.SELECTION_POLICY_VERSION) {
    return err(
      ERROR_CODES.UNSUPPORTED_SELECTION_POLICY,
      `unsupported selection_policy_version ${payload.selection_policy_version}`,
    );
  }
  if (
    payload.selector_version != null &&
    payload.selector_version !== contract.SELECTOR_VERSION
  ) {
    return err(
      ERROR_CODES.UNSUPPORTED_SELECTOR_VERSION,
      `unsupported selector_version ${payload.selector_version}`,
    );
  }
  if (typeof payload.session_seed !== 'string' || payload.session_seed.trim() === '') {
    return err(ERROR_CODES.MISSING_SESSION_SEED, 'session_seed required');
  }
  if (bankLocale === contract.LOCALE_EN) {
    if (payload.translation_version !== contract.TRANSLATION_VERSION_EN) {
      return err(
        ERROR_CODES.MISSING_TRANSLATION_VERSION,
        'translation_version required for en-US',
      );
    }
  }

  if (!Array.isArray(payload.item_plans)) {
    return err(ERROR_CODES.INVALID_ITEM_PLANS, 'item_plans must be an array');
  }
  if (!Array.isArray(payload.answers)) {
    return err(ERROR_CODES.INVALID_ANSWERS, 'answers must be an array');
  }
  if (payload.item_plans.length !== contract.SESSION_ITEM_COUNT) {
    return err(
      ERROR_CODES.INVALID_ITEM_COUNT,
      `expected ${contract.SESSION_ITEM_COUNT} item_plans`,
    );
  }
  if (payload.answers.length !== contract.SESSION_ITEM_COUNT) {
    return err(
      ERROR_CODES.INVALID_ITEM_COUNT,
      `expected ${contract.SESSION_ITEM_COUNT} answers`,
    );
  }

  const planIds = new Set();
  for (const plan of payload.item_plans) {
    if (plan == null || typeof plan !== 'object' || Array.isArray(plan)) {
      return err(ERROR_CODES.INVALID_ITEM_PLANS, 'invalid item_plan entry');
    }
    for (const key of Object.keys(plan)) {
      if (!ALLOWED_PLAN_KEYS.has(key)) {
        return err(ERROR_CODES.INVALID_PLAN_FIELD, `invalid plan field ${key}`);
      }
    }
    const itemId = assertTrimmedId(plan.item_id, MAX_ID_LENGTH, 'item_id');
    if (!itemId.ok) {
      return err(ERROR_CODES.INVALID_ITEM_PLANS, 'invalid item_id in plan');
    }
    if (planIds.has(itemId.value)) {
      return err(ERROR_CODES.DUPLICATE_PLAN_ITEM_ID, `duplicate plan ${itemId.value}`);
    }
    planIds.add(itemId.value);
    const item = bank.items_by_id[itemId.value];
    if (!item) {
      return err(ERROR_CODES.UNKNOWN_ITEM_ID, `unknown item ${itemId.value}`);
    }
    if (item.drop_from_selectable) {
      return err(ERROR_CODES.DROP_ITEM_IN_SESSION, `drop item ${itemId.value}`);
    }
    const order = planOptionOrder(plan);
    if (!Array.isArray(order) || order.length !== item.authored_option_ids.length) {
      return err(
        ERROR_CODES.INVALID_PRESENTED_OPTIONS,
        `invalid presented options for ${itemId.value}`,
      );
    }
    if (order.length > MAX_OPTION_LIST_LENGTH) {
      return err(ERROR_CODES.INVALID_PRESENTED_OPTIONS, 'too many options');
    }
    const authored = new Set(item.authored_option_ids);
    const seenOpt = new Set();
    for (const oid of order) {
      if (typeof oid !== 'string' || !authored.has(oid) || seenOpt.has(oid)) {
        return err(
          ERROR_CODES.INVALID_PRESENTED_OPTIONS,
          `invalid option order for ${itemId.value}`,
        );
      }
      seenOpt.add(oid);
    }
  }

  const answerIds = new Set();
  for (const answer of payload.answers) {
    if (answer == null || typeof answer !== 'object' || Array.isArray(answer)) {
      return err(ERROR_CODES.INVALID_ANSWERS, 'invalid answer entry');
    }
    for (const key of Object.keys(answer)) {
      if (!ALLOWED_ANSWER_KEYS.has(key)) {
        return err(ERROR_CODES.UNEXPECTED_FIELD, `unexpected answer field ${key}`);
      }
    }
    const itemId = assertTrimmedId(answer.item_id, MAX_ID_LENGTH, 'item_id');
    if (!itemId.ok) {
      return err(ERROR_CODES.INVALID_ANSWERS, 'invalid item_id in answer');
    }
    if (answerIds.has(itemId.value)) {
      return err(
        ERROR_CODES.DUPLICATE_ANSWER_ITEM_ID,
        `duplicate answer ${itemId.value}`,
      );
    }
    answerIds.add(itemId.value);
    if (!planIds.has(itemId.value)) {
      return err(ERROR_CODES.PLAN_ANSWER_MISMATCH, `answer without plan ${itemId.value}`);
    }
    const item = bank.items_by_id[itemId.value];
    const orderPlan = payload.item_plans.find((p) => p.item_id === itemId.value);
    const order = planOptionOrder(orderPlan);
    const selected = answer.selected_option_id;
    if (typeof selected !== 'string' || !order.includes(selected)) {
      return err(
        ERROR_CODES.INVALID_SELECTED_OPTION,
        `invalid selected option for ${itemId.value}`,
      );
    }
    if (!item.options[selected]) {
      return err(
        ERROR_CODES.INVALID_SELECTED_OPTION,
        `unknown selected option ${selected}`,
      );
    }
  }

  for (const planId of planIds) {
    if (!answerIds.has(planId)) {
      return err(ERROR_CODES.PLAN_ANSWER_MISMATCH, `plan without answer ${planId}`);
    }
  }

  let expected;
  try {
    expected = composeManifest({
      bank,
      sessionSeed: payload.session_seed,
      sessionId: sessionId.value,
    });
  } catch (e) {
    return err(
      ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH,
      `selector reconstruction failed: ${e.message}`,
    );
  }

  if (payload.item_plans.length !== expected.questions.length) {
    return err(
      ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH,
      'item_plans length mismatch after reconstruction',
    );
  }

  for (let i = 0; i < expected.questions.length; i++) {
    const exp = expected.questions[i];
    const sub = payload.item_plans[i];
    if (sub.item_id !== exp.question_id) {
      return err(
        ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH,
        `item order mismatch at index ${i}`,
      );
    }
    const subOrder = planOptionOrder(sub);
    if (subOrder.join(',') !== exp.presented_option_order.join(',')) {
      return err(
        ERROR_CODES.SESSION_RECONSTRUCTION_MISMATCH,
        `option order mismatch for ${sub.item_id}`,
      );
    }
  }

  return {
    ok: true,
    bank,
    manifest: expected,
  };
}

function err(code, message) {
  return { ok: false, code, message };
}

function validateFrequencyV2SessionOrThrow(payload) {
  const result = validateFrequencyV2Session(payload);
  if (!result.ok) {
    throw new FrequencyBehaviorV2ValidationError(result.code, result.message);
  }
  return result;
}

module.exports = {
  SCHEMA_VERSION: contract.SCHEMA_VERSION,
  CATALOG_VERSION: contract.CATALOG_VERSION,
  ERROR_CODES,
  FORBIDDEN_AUTHORITY_KEYS,
  FrequencyBehaviorV2ValidationError,
  validateFrequencyV2Session,
  validateFrequencyV2SessionOrThrow,
  findForbiddenAuthorityKey,
};
