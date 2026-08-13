'use strict';

const assert = require('assert');
const {
  CLOSE_REASON,
  POLICY,
  resolveThreadId,
  shouldRunCloseAllOnUserWrite,
  planDeletionMatchClose,
  matchClosePayloadFields,
  threadClosePayloadFields,
  closeAllMayDeleteMessages,
  closeAllMayReopen,
} = require('../src/deletion_close_all');

describe('deletion_close_all_backend_v1', () => {
  it('trigger only on account_deletion_requested false -> true', () => {
    assert.strictEqual(
      shouldRunCloseAllOnUserWrite(
        { account_deletion_requested: false },
        { account_deletion_requested: true },
      ),
      true,
    );
    assert.strictEqual(
      shouldRunCloseAllOnUserWrite(
        {},
        { account_deletion_requested: true },
      ),
      true,
    );
    assert.strictEqual(
      shouldRunCloseAllOnUserWrite(
        { account_deletion_requested: true },
        { account_deletion_requested: true },
      ),
      false,
    );
    assert.strictEqual(
      shouldRunCloseAllOnUserWrite(
        { account_deletion_requested: false },
        { account_deletion_requested: false },
      ),
      false,
    );
    assert.strictEqual(
      shouldRunCloseAllOnUserWrite(null, { account_deletion_requested: true }),
      true,
    );
  });

  it('one active match → unmatched + close thread', () => {
    const plan = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: true,
      threadStatus: 'active',
    });
    assert.strictEqual(plan.updateMatch, true);
    assert.strictEqual(plan.newMatchState, 'unmatched');
    assert.strictEqual(plan.matchCloseReason, CLOSE_REASON);
    assert.strictEqual(plan.updateThread, true);
    assert.strictEqual(plan.threadClosedReason, CLOSE_REASON);
    assert.strictEqual(plan.idempotent, false);
  });

  it('multiple active matches each plan independently', () => {
    const a = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: true,
      threadStatus: 'active',
    });
    const b = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: true,
      threadStatus: 'active',
    });
    assert.strictEqual(a.updateMatch && b.updateMatch, true);
    assert.strictEqual(a.updateThread && b.updateThread, true);
  });

  it('already unmatched → preserve (idempotent)', () => {
    const plan = planDeletionMatchClose({
      matchExists: true,
      matchState: 'unmatched',
      threadExists: true,
      threadStatus: 'closed',
    });
    assert.strictEqual(plan.updateMatch, false);
    assert.strictEqual(plan.updateThread, false);
    assert.strictEqual(plan.idempotent, true);
    assert.strictEqual(plan.skipReason, 'already_unmatched');
  });

  it('blocked match → preserve', () => {
    const plan = planDeletionMatchClose({
      matchExists: true,
      matchState: 'blocked',
      threadExists: true,
      threadStatus: 'closed',
    });
    assert.strictEqual(plan.updateMatch, false);
    assert.strictEqual(plan.newMatchState, null);
    assert.strictEqual(plan.skipReason, 'preserve_blocked');
  });

  it('missing thread still closes active match', () => {
    const plan = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: false,
      threadStatus: null,
    });
    assert.strictEqual(plan.updateMatch, true);
    assert.strictEqual(plan.newMatchState, 'unmatched');
    assert.strictEqual(plan.updateThread, false);
  });

  it('retry/idempotency after close', () => {
    const first = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: true,
      threadStatus: 'active',
    });
    assert.strictEqual(first.idempotent, false);

    const retry = planDeletionMatchClose({
      matchExists: true,
      matchState: 'unmatched',
      threadExists: true,
      threadStatus: 'closed',
    });
    assert.strictEqual(retry.updateMatch, false);
    assert.strictEqual(retry.updateThread, false);
    assert.strictEqual(retry.idempotent, true);
  });

  it('no message deletion / no reopen', () => {
    assert.strictEqual(closeAllMayDeleteMessages(), false);
    assert.strictEqual(closeAllMayReopen(), false);

    const fields = matchClosePayloadFields({ actorUid: 'u1' });
    assert.strictEqual(fields.state, 'unmatched');
    assert.notStrictEqual(fields.state, 'active');
    assert.strictEqual(fields.close_reason, CLOSE_REASON);

    const thread = threadClosePayloadFields({ actorUid: 'u1' });
    assert.strictEqual(thread.status, 'closed');
    assert.notStrictEqual(thread.status, 'active');
    assert.strictEqual(thread.closed_reason, CLOSE_REASON);
  });

  it('deterministic thread id falls back to matchId', () => {
    assert.strictEqual(resolveThreadId('a_b', null), 'a_b');
    assert.strictEqual(resolveThreadId('a_b', 'a_b'), 'a_b');
    assert.strictEqual(resolveThreadId('a_b', '  '), 'a_b');
  });

  it('active match with already-closed thread still closes match', () => {
    const plan = planDeletionMatchClose({
      matchExists: true,
      matchState: 'active',
      threadExists: true,
      threadStatus: 'closed',
    });
    assert.strictEqual(plan.updateMatch, true);
    assert.strictEqual(plan.updateThread, false);
  });

  it('policy constants', () => {
    assert.strictEqual(POLICY, 'deletion_close_all_backend_v1');
    assert.strictEqual(CLOSE_REASON, 'account_deletion_requested');
  });
});

describe('deletion_close_all runner wiring', () => {
  it('runner never references message deletes or reopen to active', () => {
    const fs = require('fs');
    const path = require('path');
    const src = fs.readFileSync(
      path.join(__dirname, '../src/deletion_close_all_runner.js'),
      'utf8',
    );
    assert.strictEqual(src.includes("collection('messages')"), false);
    assert.strictEqual(src.includes('.delete('), false);
    assert.strictEqual(src.includes("state: 'active'"), false);
    assert.strictEqual(src.includes("status: 'active'"), false);
    assert.ok(src.includes('runTransaction'));
    assert.ok(src.includes("state', '==', 'active'"));
  });

  it('index exports deletion close-all function', () => {
    const fs = require('fs');
    const path = require('path');
    const src = fs.readFileSync(path.join(__dirname, '../index.js'), 'utf8');
    assert.ok(src.includes('closeMatchesOnAccountDeletionRequested'));
    assert.ok(src.includes('shouldRunCloseAllOnUserWrite'));
    assert.ok(src.includes('closeAllActiveMatchesForDeletion'));
  });
});
