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
    this._db._bump(this.path);
  }
  async update(data) {
    const prev = this._db._store.get(this.path);
    if (!prev) throw new Error('not-found');
    this._db._store.set(this.path, { ...clone(prev), ...clone(data) });
    this._db._bump(this.path);
  }
}

class MemoryTransaction {
  constructor(db) {
    this._db = db;
    this._writes = [];
    this._reads = new Map();
  }
  async get(ref) {
    this._reads.set(ref.path, this._db._version(ref.path));
    return new MemoryDocSnapshot(ref.path, this._db._store.get(ref.path));
  }
  set(ref, data, opts = {}) {
    this._writes.push({ type: 'set', path: ref.path, data: clone(data), opts });
  }
  update(ref, data) {
    this._writes.push({ type: 'update', path: ref.path, data: clone(data) });
  }
  _commit() {
    for (const [path, ver] of this._reads) {
      if (this._db._version(path) !== ver) {
        const err = new Error('aborted');
        err.code = 'aborted';
        throw err;
      }
    }
    for (const w of this._writes) {
      if (w.type === 'set') {
        const prev = this._db._store.get(w.path);
        if (w.opts && w.opts.merge && prev) {
          this._db._store.set(w.path, { ...clone(prev), ...w.data });
        } else {
          this._db._store.set(w.path, w.data);
        }
        this._db._bump(w.path);
      } else if (w.type === 'update') {
        const prev = this._db._store.get(w.path);
        if (!prev) throw new Error('not-found');
        this._db._store.set(w.path, { ...clone(prev), ...w.data });
        this._db._bump(w.path);
      }
    }
  }
}

function collectionIdFromPath(path) {
  const parts = String(path || '').split('/').filter(Boolean);
  if (parts.length < 2 || parts.length % 2 !== 0) return null;
  return parts[parts.length - 2];
}

function toSortable(value) {
  if (value == null) return 0;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  if (typeof value === 'object') {
    if (typeof value.toMillis === 'function') return value.toMillis();
    if (typeof value.seconds === 'number') return value.seconds * 1000;
    if (typeof value._seconds === 'number') return value._seconds * 1000;
  }
  return 0;
}

class MemoryQuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.empty = docs.length === 0;
    this.size = docs.length;
  }
}

class MemoryQuery {
  constructor(db, collectionId, opts = {}) {
    this._db = db;
    this._collectionId = collectionId;
    this._rootOnly = !!opts.rootOnly;
    this._filters = [];
    this._order = null;
    this._limit = null;
  }
  where(field, op, value) {
    this._filters.push({ field, op, value });
    return this;
  }
  orderBy(field, direction) {
    this._order = { field, direction: direction || 'asc' };
    return this;
  }
  limit(n) {
    this._limit = n;
    return this;
  }
  async get() {
    const docs = [];
    for (const [path, data] of this._db._store.entries()) {
      if (collectionIdFromPath(path) !== this._collectionId) continue;
      if (this._rootOnly) {
        const parts = String(path).split('/').filter(Boolean);
        if (parts.length !== 2) continue;
      }
      const snap = new MemoryDocSnapshot(path, data);
      const row = snap.data() || {};
      let ok = true;
      for (const filter of this._filters) {
        if (filter.op === '==' && row[filter.field] !== filter.value) {
          ok = false;
          break;
        }
      }
      if (
        ok &&
        this._order &&
        (row[this._order.field] === undefined || row[this._order.field] === null)
      ) {
        ok = false;
      }
      if (ok) docs.push(snap);
    }
    if (this._order) {
      const field = this._order.field;
      const mul = this._order.direction === 'desc' ? -1 : 1;
      docs.sort((a, b) => {
        const av = toSortable((a.data() || {})[field]);
        const bv = toSortable((b.data() || {})[field]);
        if (av < bv) return -1 * mul;
        if (av > bv) return 1 * mul;
        return 0;
      });
    }
    const limited =
      this._limit != null ? docs.slice(0, this._limit) : docs;
    return new MemoryQuerySnapshot(limited);
  }
}

class MemoryCollection {
  constructor(db, collectionId) {
    this._db = db;
    this._collectionId = collectionId;
  }
  doc(id) {
    return this._db.doc(`${this._collectionId}/${id}`);
  }
  where(field, op, value) {
    return this._query().where(field, op, value);
  }
  orderBy(field, direction) {
    return this._query().orderBy(field, direction);
  }
  limit(n) {
    return this._query().limit(n);
  }
  async get() {
    return this._query().get();
  }
  _query() {
    return new MemoryQuery(this._db, this._collectionId, { rootOnly: true });
  }
}

class MemoryFirestore {
  constructor() {
    this._store = new Map();
    this._versions = new Map();
  }
  _version(path) {
    return this._versions.get(path) || 0;
  }
  _bump(path) {
    this._versions.set(path, this._version(path) + 1);
  }
  doc(path) {
    return new MemoryDocRef(this, path);
  }
  /**
   * Admin SDK getAll: snapshots in request order.
   * @param {...MemoryDocRef} documentRefs
   */
  async getAll(...documentRefs) {
    return Promise.all(
      documentRefs.map((ref) => {
        if (!ref || typeof ref.get !== 'function') {
          throw new Error('getAll requires document refs');
        }
        return ref.get();
      }),
    );
  }
  collection(collectionId) {
    return new MemoryCollection(this, collectionId);
  }
  collectionGroup(collectionId) {
    return new MemoryQuery(this, collectionId);
  }
  async runTransaction(fn) {
    const maxAttempts = 8;
    let lastErr;
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      const tx = new MemoryTransaction(this);
      try {
        const result = await fn(tx);
        tx._commit();
        return result;
      } catch (err) {
        lastErr = err;
        if (!err || err.code !== 'aborted') throw err;
      }
    }
    throw lastErr || new Error('aborted');
  }
}

module.exports = { MemoryFirestore };
