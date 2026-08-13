/**
 * Deletion close-all planner (`deletion_close_all_backend_v1`).
 *
 * Pure helpers — no I/O. Used by the trusted Admin SDK Cloud Function that
 * closes ACTIVE matches when `account_deletion_requested` flips false → true.
 */

'use strict';

const CLOSE_REASON = 'account_deletion_requested';
const POLICY = 'deletion_close_all_backend_v1';

/**
 * @param {string} matchId
 * @param {string|null|undefined} matchThreadId
 * @returns {string}
 */
function resolveThreadId(matchId, matchThreadId) {
  const fromMatch =
    typeof matchThreadId === 'string' ? matchThreadId.trim() : '';
  if (fromMatch) return fromMatch;
  return matchId;
}

/**
 * Whether this user-doc write should run close-all.
 * @param {Record<string, unknown>|null|undefined} beforeData
 * @param {Record<string, unknown>|null|undefined} afterData
 * @returns {boolean}
 */
function shouldRunCloseAllOnUserWrite(beforeData, afterData) {
  if (!afterData || typeof afterData !== 'object') return false;
  const after = afterData.account_deletion_requested === true;
  if (!after) return false;
  const beforeRequested =
    beforeData && typeof beforeData === 'object'
      ? beforeData.account_deletion_requested === true
      : false;
  return !beforeRequested;
}

/**
 * Plan a single match+thread close for deletion.
 *
 * - active → unmatched (+ close_reason)
 * - unmatched / blocked → no match write (preserve)
 * - thread exists && not closed → closed (+ closed_reason)
 * - missing thread → match may still close
 * - never reopens thread/match to active
 * - never plans message deletes
 *
 * @param {{
 *   matchExists: boolean,
 *   matchState: string|null|undefined,
 *   threadExists: boolean,
 *   threadStatus: string|null|undefined,
 * }} input
 * @returns {{
 *   updateMatch: boolean,
 *   newMatchState: string|null,
 *   matchCloseReason: string,
 *   updateThread: boolean,
 *   threadClosedReason: string,
 *   idempotent: boolean,
 *   skipReason: string|null,
 * }}
 */
function planDeletionMatchClose(input) {
  const matchState = input.matchState;
  const threadStatus = input.threadStatus;

  let updateMatch = false;
  let newMatchState = null;
  let skipReason = null;

  if (!input.matchExists) {
    skipReason = 'match_missing';
  } else if (matchState === 'blocked') {
    skipReason = 'preserve_blocked';
  } else if (matchState === 'unmatched') {
    skipReason = 'already_unmatched';
  } else if (matchState === 'active') {
    updateMatch = true;
    newMatchState = 'unmatched';
  } else {
    // Unknown / missing state: do not invent active; leave alone.
    skipReason = 'non_active_state';
  }

  const updateThread =
    input.threadExists === true && threadStatus !== 'closed';

  return {
    updateMatch,
    newMatchState,
    matchCloseReason: CLOSE_REASON,
    updateThread,
    threadClosedReason: CLOSE_REASON,
    idempotent: !updateMatch && !updateThread,
    skipReason: updateMatch || updateThread ? null : skipReason,
  };
}

/**
 * Build match merge payload for deletion close (no timestamps — caller adds).
 * @param {{ actorUid: string }} args
 * @returns {Record<string, string>}
 */
function matchClosePayloadFields(args) {
  return {
    state: 'unmatched',
    close_reason: CLOSE_REASON,
    unmatched_by: args.actorUid,
  };
}

/**
 * Build thread merge payload for deletion close (no timestamps — caller adds).
 * @param {{ actorUid: string }} args
 * @returns {Record<string, string>}
 */
function threadClosePayloadFields(args) {
  return {
    status: 'closed',
    closed_reason: CLOSE_REASON,
    closed_by: args.actorUid,
  };
}

/** Source-level guarantee: close-all must never touch messages. */
function closeAllMayDeleteMessages() {
  return false;
}

/** Source-level guarantee: close-all must never set state/status back to active. */
function closeAllMayReopen() {
  return false;
}

module.exports = {
  CLOSE_REASON,
  POLICY,
  resolveThreadId,
  shouldRunCloseAllOnUserWrite,
  planDeletionMatchClose,
  matchClosePayloadFields,
  threadClosePayloadFields,
  closeAllMayDeleteMessages,
  closeAllMayReopen,
};
