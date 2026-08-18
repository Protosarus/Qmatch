/**
 * Trusted Super Resonance daily allowance (`super_resonance_daily_allowance_v1`).
 *
 * Resonance members with resonance_access get 2 uses per UTC day.
 * Unused uses expire at the next UTC day and never accumulate.
 * Purchased `super_resonance_balance` is separate and never expires.
 *
 * Spend evaluation uses trusted `now` only — never a client clock.
 */

'use strict';

const { BALANCE_FIELDS } = require('./entitlement_schema');

const DAILY_LIMIT = 2;
const DAILY_UTC_DATE = 'super_resonance_daily_utc_date';
const DAILY_USED = 'super_resonance_daily_used';

function nonNegInt(v) {
  const n = typeof v === 'number' ? Math.floor(v) : 0;
  return Number.isFinite(n) && n > 0 ? n : 0;
}

function isUtcDate(value) {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

/**
 * UTC calendar day from trusted server time.
 * @param {Date|string|number} now
 * @returns {string} YYYY-MM-DD
 */
function utcDateString(now) {
  const d = now instanceof Date ? now : new Date(now);
  if (!(d instanceof Date) || Number.isNaN(d.getTime())) {
    throw new Error('invalid_trusted_now');
  }
  return d.toISOString().slice(0, 10);
}

/**
 * Resolve current-day remaining from stored bucket + trusted now.
 * Does not mutate purchased balance. Does not accumulate unused uses.
 *
 * @param {Record<string, unknown>} snapshot normalized entitlement
 * @param {Date|string|number} now trusted server time
 */
function resolveDailyAllowance(snapshot, now) {
  const access = !!(snapshot && snapshot.resonance_access === true);
  const utcDate = utcDateString(now);
  const storedDate = snapshot && isUtcDate(snapshot[DAILY_UTC_DATE])
    ? snapshot[DAILY_UTC_DATE]
    : null;
  const storedUsed = snapshot ? nonNegInt(snapshot[DAILY_USED]) : 0;
  const limit = access ? DAILY_LIMIT : 0;
  const used = storedDate === utcDate ? storedUsed : 0;
  const remaining = access ? Math.max(0, limit - used) : 0;
  const purchased = snapshot
    ? nonNegInt(snapshot[BALANCE_FIELDS.SUPER_RESONANCE])
    : 0;
  return {
    utcDate,
    used,
    remaining,
    limit,
    purchased,
    totalAvailable: remaining + purchased,
    access,
  };
}

function withDailyBucket(snapshot, daily) {
  return {
    ...snapshot,
    [DAILY_UTC_DATE]: daily.utcDate,
    [DAILY_USED]: daily.used,
  };
}

function spendDailyAllowance(snapshot, daily) {
  if (!daily || daily.remaining < 1) {
    throw new Error('insufficient_daily_allowance');
  }
  return withDailyBucket(snapshot, {
    utcDate: daily.utcDate,
    used: daily.used + 1,
  });
}

function publicAvailability(daily) {
  const purchased =
    daily && typeof daily.purchased === 'number' && Number.isFinite(daily.purchased)
      ? Math.max(0, daily.purchased)
      : 0;
  const remaining =
    daily && typeof daily.remaining === 'number' && Number.isFinite(daily.remaining)
      ? Math.max(0, daily.remaining)
      : 0;
  const limit =
    daily && typeof daily.limit === 'number' && Number.isFinite(daily.limit)
      ? Math.max(0, daily.limit)
      : 0;
  return {
    daily_remaining: remaining,
    daily_limit: limit,
    purchased_balance: purchased,
    total_available: remaining + purchased,
    super_resonance_balance: purchased,
  };
}

module.exports = {
  DAILY_LIMIT,
  DAILY_UTC_DATE,
  DAILY_USED,
  utcDateString,
  resolveDailyAllowance,
  withDailyBucket,
  spendDailyAllowance,
  publicAvailability,
};
