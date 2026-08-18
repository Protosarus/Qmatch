'use strict';

const assert = require('assert');
const {
  DEFAULT_CONCURRENCY,
  mapWithConcurrency,
} = require('../src/bounded_map');

describe('mapWithConcurrency', () => {
  it('defaults to 8', () => {
    assert.strictEqual(DEFAULT_CONCURRENCY, 8);
  });

  it('preserves input order with slower earlier items', async () => {
    const started = [];
    const inFlight = { n: 0, max: 0 };
    const out = await mapWithConcurrency([10, 20, 30, 40, 50], 2, async (item) => {
      started.push(item);
      inFlight.n += 1;
      inFlight.max = Math.max(inFlight.max, inFlight.n);
      await new Promise((resolve) => {
        setTimeout(resolve, item === 10 ? 40 : 5);
      });
      inFlight.n -= 1;
      return item * 2;
    });
    assert.deepStrictEqual(out, [20, 40, 60, 80, 100]);
    assert.ok(inFlight.max <= 2);
    assert.strictEqual(started[0], 10);
  });

  it('returns empty for empty input', async () => {
    const out = await mapWithConcurrency([], 8, async (item) => item);
    assert.deepStrictEqual(out, []);
  });
});
