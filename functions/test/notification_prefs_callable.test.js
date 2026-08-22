'use strict';

const assert = require('assert');
const { HttpsError } = require('firebase-functions/v2/https');
const { MemoryFirestore } = require('./memory_firestore');
const {
  SCHEMA_VERSION,
  BOOL_KEYS,
  CATEGORY,
  prefsPath,
  normalizePrefs,
  isCategoryEnabled,
  isPushCategoryEnabled,
  parseStrictBoolPayload,
} = require('../src/notification_prefs');
const {
  GET_CALLABLE_NAME,
  SET_CALLABLE_NAME,
  handleGetNotificationPrefs,
  handleSetNotificationPrefs,
} = require('../src/notification_prefs_callable');

function request(uid, data = {}) {
  return {
    auth: uid ? { uid } : null,
    data,
  };
}

describe('notification_prefs_v1', () => {
  it('callable names and bool keys are frozen', () => {
    assert.strictEqual(GET_CALLABLE_NAME, 'getNotificationPrefs');
    assert.strictEqual(SET_CALLABLE_NAME, 'setNotificationPrefs');
    assert.strictEqual(SCHEMA_VERSION, 'notification_prefs_v1');
    assert.deepStrictEqual([...BOOL_KEYS], [
      'push_master',
      'messages',
      'matches',
      'super_resonance',
    ]);
  });

  it('missing and malformed prefs normalize to all enabled', () => {
    assert.deepStrictEqual(normalizePrefs(null), {
      push_master: true,
      messages: true,
      matches: true,
      super_resonance: true,
    });
    assert.deepStrictEqual(normalizePrefs({ push_master: 'no', messages: 0 }), {
      push_master: true,
      messages: true,
      matches: true,
      super_resonance: true,
    });
    assert.strictEqual(
      isCategoryEnabled({ messages: false }, CATEGORY.MESSAGES),
      false,
    );
    assert.strictEqual(
      isCategoryEnabled(
        { push_master: false, messages: true },
        CATEGORY.MESSAGES,
      ),
      false,
    );
    assert.strictEqual(
      isCategoryEnabled(
        { push_master: true, messages: true },
        CATEGORY.MESSAGES,
      ),
      true,
    );
  });

  it('parseStrictBoolPayload rejects non-booleans', () => {
    assert.strictEqual(parseStrictBoolPayload(null), null);
    assert.strictEqual(
      parseStrictBoolPayload({
        push_master: true,
        messages: true,
        matches: true,
      }),
      null,
    );
    assert.deepStrictEqual(
      parseStrictBoolPayload({
        push_master: false,
        messages: true,
        matches: false,
        super_resonance: true,
      }),
      {
        push_master: false,
        messages: true,
        matches: false,
        super_resonance: true,
      },
    );
  });

  it('unauthenticated get/set throw', async () => {
    await assert.rejects(
      () => handleGetNotificationPrefs(request(null), { db: new MemoryFirestore() }),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
    await assert.rejects(
      () =>
        handleSetNotificationPrefs(
          request(null, {
            push_master: true,
            messages: true,
            matches: true,
            super_resonance: true,
          }),
          { db: new MemoryFirestore() },
        ),
      (err) => err instanceof HttpsError && err.code === 'unauthenticated',
    );
  });

  it('get returns defaults when doc is missing', async () => {
    const db = new MemoryFirestore();
    const res = await handleGetNotificationPrefs(request('u1'), { db });
    assert.deepStrictEqual(res, {
      push_master: true,
      messages: true,
      matches: true,
      super_resonance: true,
    });
  });

  it('set writes only four booleans plus schema and updated_at', async () => {
    const db = new MemoryFirestore();
    const stamps = [];
    const res = await handleSetNotificationPrefs(
      request('u1', {
        push_master: true,
        messages: false,
        matches: true,
        super_resonance: false,
        forged: true,
      }),
      {
        db,
        serverTimestamp: () => {
          stamps.push('TS');
          return 'TS';
        },
      },
    );
    assert.deepStrictEqual(res, {
      push_master: true,
      messages: false,
      matches: true,
      super_resonance: false,
    });
    const snap = await db.doc(prefsPath('u1')).get();
    assert.strictEqual(snap.exists, true);
    assert.deepStrictEqual(snap.data(), {
      schema_version: SCHEMA_VERSION,
      push_master: true,
      messages: false,
      matches: true,
      super_resonance: false,
      updated_at: 'TS',
    });
    assert.strictEqual(stamps.length, 1);
  });

  it('set rejects non-boolean fields', async () => {
    await assert.rejects(
      () =>
        handleSetNotificationPrefs(
          request('u1', {
            push_master: true,
            messages: 'no',
            matches: true,
            super_resonance: true,
          }),
          { db: new MemoryFirestore() },
        ),
      (err) => err instanceof HttpsError && err.code === 'invalid-argument',
    );
  });

  it('isPushCategoryEnabled reads recipient doc once', async () => {
    const db = new MemoryFirestore();
    await db.doc(prefsPath('u1')).set({
      push_master: true,
      messages: false,
      matches: true,
      super_resonance: true,
    });
    assert.strictEqual(
      await isPushCategoryEnabled(db, 'u1', CATEGORY.MESSAGES),
      false,
    );
    assert.strictEqual(
      await isPushCategoryEnabled(db, 'u1', CATEGORY.MATCHES),
      true,
    );
    assert.strictEqual(
      await isPushCategoryEnabled(db, 'missing', CATEGORY.MESSAGES),
      true,
    );
  });

  it('EU callables are exported in europe-west1 without secrets', () => {
    const fs = require('fs');
    const path = require('path');
    const index = fs.readFileSync(
      path.resolve(__dirname, '../index.js'),
      'utf8',
    );
    const getStart = index.indexOf('exports.getNotificationPrefs = onCall(');
    const setStart = index.indexOf('exports.setNotificationPrefs = onCall(');
    assert.ok(getStart >= 0);
    assert.ok(setStart > getStart);
    const getBlock = index.slice(getStart, setStart);
    const setBlock = index.slice(
      setStart,
      index.indexOf('exports.handleGetNotificationPrefs'),
    );
    assert.ok(getBlock.includes("region: 'europe-west1'"));
    assert.ok(setBlock.includes("region: 'europe-west1'"));
    assert.strictEqual(getBlock.includes('secrets'), false);
    assert.strictEqual(setBlock.includes('secrets'), false);
  });
});
