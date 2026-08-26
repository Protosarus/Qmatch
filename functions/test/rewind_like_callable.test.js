'use strict';

const assert = require('node:assert/strict');
const { describe, it } = require('node:test');

const {
  handleRewindLike,
} = require('../src/rewind_like_callable');

const {
  deterministicMatchId,
} = require('../src/like_match_atomicity');

class MemorySnapshot {
  constructor(value) {
    this._value = value;
    this.exists = value !== undefined;
  }

  data() {
    return this._value;
  }
}

class MemoryRef {
  constructor(path) {
    this.path = path;
  }
}

class MemoryFirestore {
  constructor(seed = {}) {
    this.docs = new Map(Object.entries(seed));
    this.deletedPaths = [];
  }

  doc(path) {
    return new MemoryRef(path);
  }

  async runTransaction(callback) {
    const tx = {
      get: async (ref) =>
        new MemorySnapshot(this.docs.get(ref.path)),
      delete: (ref) => {
        this.docs.delete(ref.path);
        this.deletedPaths.push(ref.path);
      },
    };

    return callback(tx);
  }
}

function request({
  uid = 'viewer',
  targetUid = 'target',
} = {}) {
  return {
    auth: uid ? { uid } : null,
    data: {
      target_uid: targetUid,
    },
  };
}

function swipe({
  fromUid = 'viewer',
  targetUid = 'target',
  direction = 'like',
  source = 'discover',
} = {}) {
  return {
    from_uid: fromUid,
    target_uid: targetUid,
    direction,
    source,
  };
}

const swipePath = 'users/viewer/swipes/target';
const matchId = deterministicMatchId('viewer', 'target');
const matchPath = `matches/${matchId}`;
const threadPath = `threads/${matchId}`;
const messagePath =
  `threads/${matchId}/messages/system_match_v1`;

describe('rewindLike', () => {
  it('deletes an owned one-sided Discover Like', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe(),
    });

    const result = await handleRewindLike(
      request(),
      { db },
    );

    assert.deepStrictEqual(result, {
      rewound: true,
    });

    assert.strictEqual(
      db.docs.has(swipePath),
      false,
    );

    assert.deepStrictEqual(
      db.deletedPaths,
      [swipePath],
    );
  });

  it('never rewinds a Like when a Match exists', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe(),
      [matchPath]: {
        state: 'active',
      },
    });

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('never rewinds a Like when a Thread exists', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe(),
      [threadPath]: {
        status: 'active',
      },
    });

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('never rewinds a Like when an orphaned match message exists', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe(),
      [messagePath]: {
        type: 'system',
      },
    });

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('never rewinds a Pass', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe({
        direction: 'pass',
      }),
    });

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
  });

  it('never rewinds another user ownership shape', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe({
        fromUid: 'someone-else',
      }),
    });

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
  });

  it('fails when the Like does not exist', async () => {
    const db = new MemoryFirestore();

    await assert.rejects(
      () => handleRewindLike(request(), { db }),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );
  });

  it('requires authentication', async () => {
    const db = new MemoryFirestore({
      [swipePath]: swipe(),
    });

    await assert.rejects(
      () =>
        handleRewindLike(
          request({
            uid: null,
          }),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'unauthenticated',
    );

    assert.strictEqual(db.docs.has(swipePath), true);
  });
});
