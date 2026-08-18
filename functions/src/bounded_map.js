'use strict';

const DEFAULT_CONCURRENCY = 8;

/**
 * Map [items] with at most [limit] in-flight promises. Preserves input order.
 * Single-threaded increment of `next` is race-free in Node.
 *
 * @template T, R
 * @param {T[]} items
 * @param {number} limit
 * @param {(item: T, index: number) => Promise<R>} mapper
 * @returns {Promise<R[]>}
 */
async function mapWithConcurrency(items, limit, mapper) {
  const list = Array.isArray(items) ? items : [];
  const n = list.length;
  if (n === 0) return [];
  const parsed = Number(limit);
  const concurrency = Math.max(
    1,
    Math.min(Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_CONCURRENCY, n),
  );
  const out = new Array(n);
  let next = 0;

  async function worker() {
    while (next < n) {
      const index = next;
      next += 1;
      out[index] = await mapper(list[index], index);
    }
  }

  const workers = [];
  for (let i = 0; i < concurrency; i += 1) {
    workers.push(worker());
  }
  await Promise.all(workers);
  return out;
}

module.exports = {
  DEFAULT_CONCURRENCY,
  mapWithConcurrency,
};
