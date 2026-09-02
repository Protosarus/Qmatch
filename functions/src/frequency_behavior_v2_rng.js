'use strict';

const { SELECTOR_RNG_ALGORITHM_VERSION } = require('./frequency_behavior_v2_contract');

class FrequencyBehaviorV2Rng {
  constructor(state) {
    this._state = state;
  }

  static fromParts(parts) {
    let hash = 0x811c9dc5;
    for (const part of parts) {
      hash = FrequencyBehaviorV2Rng.fnv1a32Update(hash, part);
      hash = FrequencyBehaviorV2Rng.fnv1a32Update(hash, '\u0000');
    }
    if (hash === 0) hash = 0xa5a5a5a5;
    return new FrequencyBehaviorV2Rng(hash >>> 0);
  }

  static forStream({
    selectorVersion,
    bankVersion,
    sessionSeed,
    stream,
  }) {
    return FrequencyBehaviorV2Rng.fromParts([
      selectorVersion,
      bankVersion,
      sessionSeed,
      stream,
      SELECTOR_RNG_ALGORITHM_VERSION,
    ]);
  }

  static fnv1a32(input) {
    return FrequencyBehaviorV2Rng.fnv1a32Update(0x811c9dc5, input) >>> 0;
  }

  static fnv1a32Update(hash, input) {
    let h = hash >>> 0;
    for (let i = 0; i < input.length; i++) {
      const unit = input.charCodeAt(i);
      h ^= unit & 0xffff;
      h = Math.imul(h, 0x01000193) >>> 0;
    }
    return h >>> 0;
  }

  nextUint32() {
    let x = this._state >>> 0;
    x ^= (x << 13) >>> 0;
    x ^= x >>> 17;
    x ^= (x << 5) >>> 0;
    this._state = x >>> 0;
    return this._state;
  }

  nextInt(maxExclusive) {
    if (maxExclusive <= 0) {
      throw new RangeError('maxExclusive must be > 0');
    }
    const bound = Math.floor(0x100000000 / maxExclusive) * maxExclusive;
    while (true) {
      const r = this.nextUint32();
      if (r < bound) return r % maxExclusive;
    }
  }

  shuffledCopy(input) {
    const list = input.slice();
    for (let i = list.length - 1; i > 0; i--) {
      const j = this.nextInt(i + 1);
      const tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}

module.exports = {
  FrequencyBehaviorV2Rng,
};
