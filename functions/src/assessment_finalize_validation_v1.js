'use strict';

/**
 * Pure structural validation for future IQ / EQ / Frequency finalize callables.
 *
 * No Firebase init, no Firestore, no Auth, no Cloud Function registration.
 * Does not score answers or grant completion.
 */

const catalogModule = require('./assessment_finalize_catalog_v1.generated');

const SCHEMA_VERSION = 'assessment_finalize_session_v1';
const CATALOG_VERSION = 'assessment_finalize_catalog_v1';

const MAX_SESSION_ID_LENGTH = 128;
const MAX_OWNER_UID_LENGTH = 128;
const MAX_ID_LENGTH = 128;
const MAX_PAYLOAD_CHARS = 256 * 1024;
const MAX_ARRAY_LENGTH = 64;
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
  'item_plans',
  'answers',
]);

const ALLOWED_PLAN_KEYS = new Set([
  'item_id',
  'displayed_option_ids',
  'dimension',
  'primary_dimension',
  'template_family_id',
  'item_role',
]);

const ALLOWED_ANSWER_KEYS = new Set([
  'item_id',
  'selected_option_id',
]);

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
  INVALID_ITEM_PLANS: 'INVALID_ITEM_PLANS',
  INVALID_ANSWERS: 'INVALID_ANSWERS',
  INVALID_ITEM_COUNT: 'INVALID_ITEM_COUNT',
  DUPLICATE_PLAN_ITEM_ID: 'DUPLICATE_PLAN_ITEM_ID',
  DUPLICATE_ANSWER_ITEM_ID: 'DUPLICATE_ANSWER_ITEM_ID',
  PLAN_ANSWER_MISMATCH: 'PLAN_ANSWER_MISMATCH',
  UNKNOWN_ITEM_ID: 'UNKNOWN_ITEM_ID',
  INVALID_DISPLAYED_OPTIONS: 'INVALID_DISPLAYED_OPTIONS',
  INVALID_SELECTED_OPTION: 'INVALID_SELECTED_OPTION',
  INVALID_PLAN_FIELD: 'INVALID_PLAN_FIELD',
  INVALID_DIMENSION_QUOTA: 'INVALID_DIMENSION_QUOTA',
  INVALID_DIMENSION_COVERAGE: 'INVALID_DIMENSION_COVERAGE',
  INVALID_FREQUENCY_BLUEPRINT: 'INVALID_FREQUENCY_BLUEPRINT',
  DUPLICATE_TEMPLATE_FAMILY: 'DUPLICATE_TEMPLATE_FAMILY',
});

class AssessmentFinalizeValidationError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'AssessmentFinalizeValidationError';
    this.code = code;
  }
}

function isPlainObject(value) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    return false;
  }
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}

function fail(code, message) {
  throw new AssessmentFinalizeValidationError(code, message);
}

function payloadSize(payload) {
  try {
    return JSON.stringify(payload).length;
  } catch (err) {
    fail(ERROR_CODES.INVALID_PAYLOAD, 'payload is not serializable');
  }
}

function rejectForbiddenAndUnexpectedKeys(obj, allowed, context) {
  for (const key of Object.keys(obj)) {
    if (FORBIDDEN_AUTHORITY_KEYS.has(key)) {
      fail(
        ERROR_CODES.FORBIDDEN_AUTHORITY_FIELD,
        `${context} contains a forbidden authority field`,
      );
    }
    if (!allowed.has(key)) {
      fail(ERROR_CODES.UNEXPECTED_FIELD, `${context} contains an unexpected field`);
    }
  }
}

function requireBoundedString(value, code, label, maxLen) {
  if (typeof value !== 'string' || value.length === 0 || value.trim() !== value) {
    fail(code, `${label} must be a non-empty trimmed string`);
  }
  if (value.length > maxLen) {
    fail(code, `${label} exceeds the allowed length`);
  }
  if (/[\u0000-\u001f\u007f]/.test(value)) {
    fail(code, `${label} contains invalid characters`);
  }
  return value;
}

function requireId(value, code, label) {
  return requireBoundedString(value, code, label, MAX_ID_LENGTH);
}

const banksByKey = new Map();
for (const bank of catalogModule.banks) {
  banksByKey.set(
    `${bank.assessment_type}\0${bank.bank_version}\0${bank.bank_locale}`,
    bank,
  );
}

function lookupBank(assessmentType, bankVersion, bankLocale) {
  return banksByKey.get(`${assessmentType}\0${bankVersion}\0${bankLocale}`) || null;
}

function asItemMap(bank) {
  const map = new Map();
  for (const item of bank.items) {
    map.set(item.id, item);
  }
  return map;
}

function sameStringSet(left, right) {
  if (left.length !== right.length) return false;
  const set = new Set(left);
  if (set.size !== left.length) return false;
  for (const value of right) {
    if (!set.has(value)) return false;
  }
  return true;
}

function validatePlan(plan, index, bank, catalogItem) {
  if (!isPlainObject(plan)) {
    fail(ERROR_CODES.INVALID_ITEM_PLANS, 'each item plan must be a plain object');
  }
  rejectForbiddenAndUnexpectedKeys(plan, ALLOWED_PLAN_KEYS, 'item_plans');

  const itemId = requireId(plan.item_id, ERROR_CODES.INVALID_ITEM_PLANS, 'item_id');
  if (!catalogItem) {
    fail(ERROR_CODES.UNKNOWN_ITEM_ID, 'plan contains an item that is not in the catalog');
  }

  if (!Array.isArray(plan.displayed_option_ids)) {
    fail(ERROR_CODES.INVALID_DISPLAYED_OPTIONS, 'displayed_option_ids must be an array');
  }
  if (
    plan.displayed_option_ids.length === 0 ||
    plan.displayed_option_ids.length > MAX_OPTION_LIST_LENGTH
  ) {
    fail(ERROR_CODES.INVALID_DISPLAYED_OPTIONS, 'displayed_option_ids exceeds the allowed length');
  }
  const displayed = [];
  const seenDisplayed = new Set();
  for (const optionId of plan.displayed_option_ids) {
    if (typeof optionId !== 'string' || optionId.length === 0 || optionId.length > MAX_ID_LENGTH) {
      fail(ERROR_CODES.INVALID_DISPLAYED_OPTIONS, 'displayed option ids are malformed');
    }
    if (seenDisplayed.has(optionId)) {
      fail(ERROR_CODES.INVALID_DISPLAYED_OPTIONS, 'displayed option ids must be unique');
    }
    if (!catalogItem.option_ids.includes(optionId)) {
      fail(ERROR_CODES.INVALID_DISPLAYED_OPTIONS, 'displayed option ids must belong to the item');
    }
    seenDisplayed.add(optionId);
    displayed.push(optionId);
  }

  if (Object.prototype.hasOwnProperty.call(plan, 'dimension')) {
    if (bank.assessment_type !== 'iq' || plan.dimension !== catalogItem.dimension) {
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'plan dimension does not match the catalog');
    }
  }
  if (Object.prototype.hasOwnProperty.call(plan, 'primary_dimension')) {
    if (bank.assessment_type === 'iq') {
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'plan primary_dimension does not match the catalog');
    }
    if (plan.primary_dimension !== catalogItem.dimension) {
      if (bank.assessment_type === 'eq') {
        fail(ERROR_CODES.INVALID_DIMENSION_COVERAGE, 'EQ dimension coverage is not satisfied');
      }
      if (bank.assessment_type === 'frequency') {
        fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency role blueprint is not satisfied');
      }
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'plan primary_dimension does not match the catalog');
    }
  }
  if (Object.prototype.hasOwnProperty.call(plan, 'template_family_id')) {
    if (
      bank.assessment_type !== 'iq' ||
      plan.template_family_id !== catalogItem.template_family_id
    ) {
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'plan template_family_id does not match the catalog');
    }
  }
  if (Object.prototype.hasOwnProperty.call(plan, 'item_role')) {
    if (bank.assessment_type !== 'frequency' || plan.item_role !== catalogItem.item_role) {
      if (bank.assessment_type === 'frequency') {
        fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency role blueprint is not satisfied');
      }
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'plan item_role does not match the catalog');
    }
  }

  return {
    item_id: itemId,
    displayed_option_ids: displayed,
    dimension: catalogItem.dimension,
    template_family_id: catalogItem.template_family_id || null,
    item_role: catalogItem.item_role || null,
    plan_index: index,
  };
}

function validateAnswer(answer, planById, catalogById) {
  if (!isPlainObject(answer)) {
    fail(ERROR_CODES.INVALID_ANSWERS, 'each answer must be a plain object');
  }
  rejectForbiddenAndUnexpectedKeys(answer, ALLOWED_ANSWER_KEYS, 'answers');
  const itemId = requireId(answer.item_id, ERROR_CODES.INVALID_ANSWERS, 'item_id');
  const selected = requireId(
    answer.selected_option_id,
    ERROR_CODES.INVALID_SELECTED_OPTION,
    'selected_option_id',
  );
  const plan = planById.get(itemId);
  if (!plan) {
    fail(ERROR_CODES.PLAN_ANSWER_MISMATCH, 'an answer does not belong to the item plan');
  }
  const catalogItem = catalogById.get(itemId);
  if (!catalogItem.option_ids.includes(selected)) {
    fail(ERROR_CODES.INVALID_SELECTED_OPTION, 'selected option is not in the catalog item');
  }
  if (!plan.displayed_option_ids.includes(selected)) {
    fail(
      ERROR_CODES.INVALID_SELECTED_OPTION,
      'selected option is not in the displayed options',
    );
  }
  return {
    item_id: itemId,
    selected_option_id: selected,
  };
}

function validateIqStructure(bank, normalizedPlans) {
  const counts = Object.create(null);
  for (const dim of bank.canonical_dimensions) counts[dim] = 0;
  const families = new Set();
  for (const plan of normalizedPlans) {
    if (!Object.prototype.hasOwnProperty.call(counts, plan.dimension)) {
      fail(ERROR_CODES.INVALID_DIMENSION_QUOTA, 'session uses a non-canonical IQ dimension');
    }
    counts[plan.dimension] += 1;
    if (!plan.template_family_id) {
      fail(ERROR_CODES.INVALID_PLAN_FIELD, 'IQ item is missing a template family');
    }
    if (families.has(plan.template_family_id)) {
      fail(ERROR_CODES.DUPLICATE_TEMPLATE_FAMILY, 'IQ session repeats a template family');
    }
    families.add(plan.template_family_id);
  }
  for (const [dim, expected] of Object.entries(bank.dimension_quotas)) {
    if (counts[dim] !== expected) {
      fail(ERROR_CODES.INVALID_DIMENSION_QUOTA, 'IQ dimension quota is not satisfied');
    }
  }
}

function validateEqStructure(bank, normalizedPlans) {
  if (normalizedPlans.length !== bank.items.length) {
    fail(ERROR_CODES.INVALID_DIMENSION_COVERAGE, 'EQ session is not the full bank');
  }
  const catalogIds = new Set(bank.items.map((item) => item.id));
  for (const plan of normalizedPlans) {
    catalogIds.delete(plan.item_id);
  }
  if (catalogIds.size !== 0) {
    fail(ERROR_CODES.INVALID_DIMENSION_COVERAGE, 'EQ session is not the full bank');
  }
  const counts = Object.create(null);
  for (const dim of bank.canonical_dimensions) counts[dim] = 0;
  for (const plan of normalizedPlans) {
    if (!Object.prototype.hasOwnProperty.call(counts, plan.dimension)) {
      fail(ERROR_CODES.INVALID_DIMENSION_COVERAGE, 'EQ session uses a non-canonical dimension');
    }
    counts[plan.dimension] += 1;
  }
  for (const dim of bank.canonical_dimensions) {
    if (counts[dim] !== bank.primary_items_per_dimension) {
      fail(ERROR_CODES.INVALID_DIMENSION_COVERAGE, 'EQ dimension coverage is not satisfied');
    }
  }
}

function validateFrequencyStructure(bank, normalizedPlans) {
  if (normalizedPlans.length !== bank.items.length) {
    fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency session is not the full bank');
  }
  const catalogIds = new Set(bank.items.map((item) => item.id));
  for (const plan of normalizedPlans) {
    catalogIds.delete(plan.item_id);
  }
  if (catalogIds.size !== 0) {
    fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency session is not the full bank');
  }

  const roleCounts = {
    core: 0,
    behavioral_equivalence: 0,
    separator: 0,
    response_quality: 0,
  };
  const coreByDim = Object.create(null);
  const relatedByDim = Object.create(null);
  for (const dim of bank.canonical_dimensions) {
    coreByDim[dim] = 0;
    relatedByDim[dim] = 0;
  }
  for (const plan of normalizedPlans) {
    const role = plan.item_role;
    if (!Object.prototype.hasOwnProperty.call(roleCounts, role)) {
      fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency item has an unknown role');
    }
    roleCounts[role] += 1;
    if (role === 'core' || role === 'behavioral_equivalence') {
      if (typeof plan.dimension !== 'string') {
        fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency trait item is missing a dimension');
      }
      if (role === 'core') coreByDim[plan.dimension] += 1;
      else relatedByDim[plan.dimension] += 1;
    } else if (plan.dimension != null) {
      fail(
        ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT,
        'Frequency non-trait items must not have a primary dimension',
      );
    }
  }
  for (const [role, expected] of Object.entries(bank.blueprint)) {
    if (roleCounts[role] !== expected) {
      fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency role blueprint is not satisfied');
    }
  }
  for (const dim of bank.canonical_dimensions) {
    if (coreByDim[dim] !== bank.primary_core_items_per_dimension) {
      fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency core coverage is not satisfied');
    }
    if (relatedByDim[dim] !== bank.related_items_per_dimension) {
      fail(ERROR_CODES.INVALID_FREQUENCY_BLUEPRINT, 'Frequency related coverage is not satisfied');
    }
  }
}

function validateAssessmentFinalizeSessionOrThrow(payload) {
  if (!isPlainObject(payload)) {
    fail(ERROR_CODES.INVALID_PAYLOAD, 'payload must be a plain object');
  }
  if (payloadSize(payload) > MAX_PAYLOAD_CHARS) {
    fail(ERROR_CODES.PAYLOAD_TOO_LARGE, 'payload exceeds the allowed size');
  }
  rejectForbiddenAndUnexpectedKeys(payload, ALLOWED_PAYLOAD_KEYS, 'payload');

  if (payload.schema_version !== SCHEMA_VERSION) {
    fail(ERROR_CODES.UNSUPPORTED_SCHEMA_VERSION, 'schema_version is not supported');
  }
  if (payload.catalog_version !== CATALOG_VERSION) {
    fail(ERROR_CODES.UNSUPPORTED_CATALOG_VERSION, 'catalog_version is not supported');
  }
  if (catalogModule.catalog_version !== CATALOG_VERSION) {
    fail(ERROR_CODES.UNSUPPORTED_CATALOG_VERSION, 'loaded catalog_version is not supported');
  }

  const sessionId = requireBoundedString(
    payload.session_id,
    ERROR_CODES.INVALID_SESSION_ID,
    'session_id',
    MAX_SESSION_ID_LENGTH,
  );
  const ownerUid = requireBoundedString(
    payload.owner_uid,
    ERROR_CODES.INVALID_OWNER_UID,
    'owner_uid',
    MAX_OWNER_UID_LENGTH,
  );

  const assessmentType = payload.assessment_type;
  if (assessmentType !== 'iq' && assessmentType !== 'eq' && assessmentType !== 'frequency') {
    fail(ERROR_CODES.UNSUPPORTED_ASSESSMENT_TYPE, 'assessment_type is not supported');
  }
  const bankVersion = requireId(
    payload.bank_version,
    ERROR_CODES.UNSUPPORTED_BANK,
    'bank_version',
  );
  const bankLocale = requireId(
    payload.bank_locale,
    ERROR_CODES.UNSUPPORTED_BANK,
    'bank_locale',
  );
  const selectionPolicyVersion = requireId(
    payload.selection_policy_version,
    ERROR_CODES.UNSUPPORTED_SELECTION_POLICY,
    'selection_policy_version',
  );

  const bank = lookupBank(assessmentType, bankVersion, bankLocale);
  if (!bank) {
    fail(ERROR_CODES.UNSUPPORTED_BANK, 'bank_version/locale is not supported');
  }
  if (selectionPolicyVersion !== bank.selection_policy_version) {
    fail(ERROR_CODES.UNSUPPORTED_SELECTION_POLICY, 'selection_policy_version is not supported');
  }

  if (!Array.isArray(payload.item_plans)) {
    fail(ERROR_CODES.INVALID_ITEM_PLANS, 'item_plans must be an array');
  }
  if (!Array.isArray(payload.answers)) {
    fail(ERROR_CODES.INVALID_ANSWERS, 'answers must be an array');
  }
  if (payload.item_plans.length > MAX_ARRAY_LENGTH || payload.answers.length > MAX_ARRAY_LENGTH) {
    fail(ERROR_CODES.INVALID_ITEM_COUNT, 'item_plans or answers exceed the allowed length');
  }
  if (payload.item_plans.length !== bank.expected_item_count) {
    fail(ERROR_CODES.INVALID_ITEM_COUNT, 'session does not contain the expected item count');
  }

  const catalogById = asItemMap(bank);
  const seenPlanIds = new Set();
  const normalizedPlans = [];
  for (let i = 0; i < payload.item_plans.length; i += 1) {
    const rawPlan = payload.item_plans[i];
    if (!isPlainObject(rawPlan) || typeof rawPlan.item_id !== 'string') {
      if (isPlainObject(rawPlan)) {
        rejectForbiddenAndUnexpectedKeys(rawPlan, ALLOWED_PLAN_KEYS, 'item_plans');
      }
      fail(ERROR_CODES.INVALID_ITEM_PLANS, 'each item plan must be a plain object');
    }
    if (seenPlanIds.has(rawPlan.item_id)) {
      fail(ERROR_CODES.DUPLICATE_PLAN_ITEM_ID, 'item_plans contain a duplicate item id');
    }
    seenPlanIds.add(rawPlan.item_id);
    normalizedPlans.push(validatePlan(rawPlan, i, bank, catalogById.get(rawPlan.item_id)));
  }

  const seenAnswerIds = new Set();
  const planById = new Map(normalizedPlans.map((plan) => [plan.item_id, plan]));
  const normalizedAnswers = [];
  for (const rawAnswer of payload.answers) {
    if (!isPlainObject(rawAnswer) || typeof rawAnswer.item_id !== 'string') {
      if (isPlainObject(rawAnswer)) {
        rejectForbiddenAndUnexpectedKeys(rawAnswer, ALLOWED_ANSWER_KEYS, 'answers');
      }
      fail(ERROR_CODES.INVALID_ANSWERS, 'each answer must be a plain object');
    }
    if (seenAnswerIds.has(rawAnswer.item_id)) {
      fail(ERROR_CODES.DUPLICATE_ANSWER_ITEM_ID, 'answers contain a duplicate item id');
    }
    seenAnswerIds.add(rawAnswer.item_id);
    normalizedAnswers.push(validateAnswer(rawAnswer, planById, catalogById));
  }

  if (payload.answers.length !== payload.item_plans.length || seenAnswerIds.size !== seenPlanIds.size) {
    fail(ERROR_CODES.PLAN_ANSWER_MISMATCH, 'answers do not exactly cover the item plan');
  }
  for (const id of seenPlanIds) {
    if (!seenAnswerIds.has(id)) {
      fail(ERROR_CODES.PLAN_ANSWER_MISMATCH, 'answers do not exactly cover the item plan');
    }
  }

  for (const plan of normalizedPlans) {
    const catalogItem = catalogById.get(plan.item_id);
    if (!sameStringSet(plan.displayed_option_ids, catalogItem.option_ids)) {
      fail(
        ERROR_CODES.INVALID_DISPLAYED_OPTIONS,
        'displayed option ids must be a permutation of the catalog options',
      );
    }
  }

  if (bank.assessment_type === 'iq') {
    validateIqStructure(bank, normalizedPlans);
  } else if (bank.assessment_type === 'eq') {
    validateEqStructure(bank, normalizedPlans);
  } else {
    validateFrequencyStructure(bank, normalizedPlans);
  }

  return {
    assessmentType: bank.assessment_type,
    schemaVersion: SCHEMA_VERSION,
    catalogVersion: CATALOG_VERSION,
    bankVersion: bank.bank_version,
    bankLocale: bank.bank_locale,
    selectionPolicyVersion: bank.selection_policy_version,
    sessionId,
    ownerUid,
    itemCount: normalizedPlans.length,
    normalizedPlans: normalizedPlans.map((plan) => ({
      item_id: plan.item_id,
      displayed_option_ids: [...plan.displayed_option_ids],
      dimension: plan.dimension,
      template_family_id: plan.template_family_id,
      item_role: plan.item_role,
    })),
    normalizedAnswers: normalizedAnswers.map((answer) => ({
      item_id: answer.item_id,
      selected_option_id: answer.selected_option_id,
    })),
  };
}

function validateAssessmentFinalizeSession(payload) {
  try {
    return {
      ok: true,
      session: validateAssessmentFinalizeSessionOrThrow(payload),
    };
  } catch (err) {
    if (err instanceof AssessmentFinalizeValidationError) {
      return {
        ok: false,
        code: err.code,
        message: err.message,
      };
    }
    throw err;
  }
}

module.exports = {
  SCHEMA_VERSION,
  CATALOG_VERSION,
  ERROR_CODES,
  AssessmentFinalizeValidationError,
  validateAssessmentFinalizeSession,
  validateAssessmentFinalizeSessionOrThrow,
};
