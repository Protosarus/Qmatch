/**
 * Minimal in-memory Firestore for entitlement repository unit tests.
 * Supports doc get/set/update and runTransaction with basic isolation.
 */

'use strict';

function clone(v) {
  if (v === undefined) return undefined;
  return JSON.parse(JSON.stringify(v));
}

class MemoryDocSnapshot {
  constructor(path, data) {
    this._path = path;
    this._data = data;
  }
  get exists() {
    return this._data !== undefined && this._data !== null;
  }
  data() {
    return this.exists ? clone(this._data) : undefined;
  }
  get id() {
    const parts = this._path.split('/');
    return parts[parts.length - 1];
  }
  get ref() {
    return { path: this._path };
  }
}

class MemoryDocRef {
  constructor(db, path) {
    this._db = db;
    this.path = path;
  }
  async get() {
    return new MemoryDocSnapshot(this.path, this._db._store.get(this.path));
  }
  async set(data, opts = {}) {
    const prev = this._db._store.get(this.path);
    if (opts.merge && prev) {
      this._db._store.set(this.path, { ...clone(prev), ...clone(data) });
    } else {
      this._db._store.set(this.path, clone(data));
    }
  }
  async update(data) {
    const prev = this._db._store.get(this.path);
    if (!prev) throw new Error('not-found');
    this._db._store.set(this.path, { ...clone(prev), ...clone(data) });
  }
}

class MemoryTransaction {
  constructor(db) {
    this._db = db;
    this._writes = [];
  }
  async get(ref) {
    return new MemoryDocSnapshot(ref.path, this._db._store.get(ref.path));
  }
  set(ref, data, opts = {}) {
    this._writes.push({ type: 'set', path: ref.path, data: clone(data), opts });
  }
  update(ref, data) {
    this._writes.push({ type: 'update', path: ref.path, data: clone(data) });
  }
  _commit() {
    for (const w of this._writes) {
      if (w.type === 'set') {
        const prev = this._db._store.get(w.path);
        if (w.opts && w.opts.merge && prev) {
          this._db._store.set(w.path, { ...clone(prev), ...w.data });
        } else {
          this._db._store.set(w.path, w.data);
        }
      } else if (w.type === 'update') {
        const prev = this._db._store.get(w.path);
        if (!prev) throw new Error('not-found');
        this._db._store.set(w.path, { ...clone(prev), ...w.data });
      }
    }
  }
}

class MemoryFirestore {
  constructor() {
    this._store = new Map();
  }
  doc(path) {
    return new MemoryDocRef(this, path);
  }
  async runTransaction(fn) {
    // Simple single-attempt transaction for unit tests.
    const tx = new MemoryTransaction(this);
    const result = await fn(tx);
    tx._commit();
    return result;
  }
}

module.exports = { MemoryFirestore };
