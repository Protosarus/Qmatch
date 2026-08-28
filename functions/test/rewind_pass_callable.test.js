'use strict';

const assert = require('node:assert/strict');
const { describe, it } = require('node:test');

const {
  handleRewindPass,
} = require('../src/rewind_pass_callable');

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
  direction = 'pass',
  source = 'discover',
} = {}) {
  return {
    from_uid: fromUid,
    target_uid: targetUid,
    direction,
    source,
  };
}

function resonanceEntitlement(overrides = {}) {
  return {
    uid: 'viewer',
    tier: 'resonance',
    subscription_state: 'active',
    resonance_access: true,
    ...overrides,
  };
}

function memoryDb(docs = {}, entitlement = resonanceEntitlement()) {
  const seed = { ...docs };
  if (entitlement) {
    seed[entitlementPath] = entitlement;
  }
  return new MemoryFirestore(seed);
}

function isResonanceDenied(error) {
  return (
    error &&
    error.code === 'permission-denied' &&
    error.message === 'Rewind requires Resonance.' &&
    !String(error.message).includes('swipe') &&
    !String(error.message).includes('match') &&
    !String(error.message).includes('Like') &&
    !String(error.message).includes('Pass')
  );
}

const swipePath = 'users/viewer/swipes/target';
const entitlementPath = 'entitlements/viewer';

describe('rewindPass', () => {
  it('deletes an owned Discover Pass', async () => {
    const db = memoryDb({
      [swipePath]: swipe(),
    });

    const result = await handleRewindPass(
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

  it('never rewinds a Like', async () => {
    const db = memoryDb({
      [swipePath]: swipe({
        direction: 'like',
      }),
    });

    await assert.rejects(
      () =>
        handleRewindPass(
          request(),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(
      db.docs.has(swipePath),
      true,
    );

    assert.deepStrictEqual(
      db.deletedPaths,
      [],
    );
  });

  it('never rewinds a non-Discover swipe', async () => {
    const db = memoryDb({
      [swipePath]: swipe({
        source: 'other',
      }),
    });

    await assert.rejects(
      () =>
        handleRewindPass(
          request(),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(
      db.docs.has(swipePath),
      true,
    );
  });

  it('never rewinds another user ownership shape', async () => {
    const db = memoryDb({
      [swipePath]: swipe({
        fromUid: 'someone-else',
      }),
    });

    await assert.rejects(
      () =>
        handleRewindPass(
          request(),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );

    assert.strictEqual(
      db.docs.has(swipePath),
      true,
    );
  });

  it('fails when the Pass does not exist', async () => {
    const db = memoryDb();

    await assert.rejects(
      () =>
        handleRewindPass(
          request(),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'failed-precondition',
    );
  });

  it('requires authentication', async () => {
    const db = memoryDb({
      [swipePath]: swipe(),
    });

    await assert.rejects(
      () =>
        handleRewindPass(
          request({
            uid: null,
          }),
          { db },
        ),
      (error) =>
        error &&
        error.code === 'unauthenticated',
    );

    assert.strictEqual(
      db.docs.has(swipePath),
      true,
    );
  });

  it('missing entitlement doc is permission-denied and leaves the Pass', async () => {
    const db = memoryDb(
      { [swipePath]: swipe() },
      null,
    );

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('free entitlement is permission-denied and leaves the Pass', async () => {
    const db = memoryDb(
      { [swipePath]: swipe() },
      resonanceEntitlement({
        tier: 'free',
        subscription_state: 'none',
        resonance_access: false,
      }),
    );

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('expired entitlement is permission-denied and leaves the Pass', async () => {
    const db = memoryDb(
      { [swipePath]: swipe() },
      resonanceEntitlement({
        subscription_state: 'expired',
        resonance_access: true,
      }),
    );

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), true);
  });

  it('revoked entitlement is permission-denied and leaves the Pass', async () => {
    const db = memoryDb(
      { [swipePath]: swipe() },
      resonanceEntitlement({
        subscription_state: 'revoked',
        resonance_access: true,
      }),
    );

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), true);
  });

  it('forged resonance_access without granting tier/state is denied', async () => {
    const db = memoryDb(
      { [swipePath]: swipe() },
      {
        resonance_access: true,
      },
    );

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), true);
    assert.deepStrictEqual(db.deletedPaths, []);
  });

  it('Free user is denied even when the Pass does not exist', async () => {
    const db = memoryDb({}, null);

    await assert.rejects(
      () => handleRewindPass(request(), { db }),
      isResonanceDenied,
    );

    assert.strictEqual(db.docs.has(swipePath), false);
    assert.deepStrictEqual(db.deletedPaths, []);
  });
});
