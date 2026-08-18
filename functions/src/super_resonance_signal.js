/**
 * Super Resonance directed peer-signal constants (`super_resonance_signal_v1`).
 *
 * Documents are Admin-only. Clients must not read or write this collection.
 */

'use strict';

const SCHEMA_VERSION = 'super_resonance_signal_v1';
const COLLECTION = 'super_resonance_signals';
const STATUS_ACTIVE = 'active';
const SPEND_PLATFORM = 'unknown';

function signalId(fromUid, toUid) {
  return `${fromUid}_${toUid}`;
}

function signalPath(fromUid, toUid) {
  return `${COLLECTION}/${signalId(fromUid, toUid)}`;
}

function isSafeRequestId(requestId) {
  if (typeof requestId !== 'string') return false;
  const trimmed = requestId.trim();
  if (!trimmed) return false;
  if (trimmed.includes('/') || trimmed.includes(':')) return false;
  return true;
}

function publicSendResult({ alreadySent, balance, id }) {
  return {
    ok: true,
    already_sent: !!alreadySent,
    super_resonance_balance:
      typeof balance === 'number' && Number.isFinite(balance) ? balance : 0,
    signal_id: id,
  };
}

function buildSignalDocument({
  fromUid,
  toUid,
  requestId,
  ledgerId,
  createdAt,
}) {
  return {
    from_uid: fromUid,
    to_uid: toUid,
    created_at: createdAt,
    status: STATUS_ACTIVE,
    spend_request_id: requestId,
    spend_ledger_id: ledgerId,
    schema_version: SCHEMA_VERSION,
  };
}

module.exports = {
  SCHEMA_VERSION,
  COLLECTION,
  STATUS_ACTIVE,
  SPEND_PLATFORM,
  signalId,
  signalPath,
  isSafeRequestId,
  publicSendResult,
  buildSignalDocument,
};
