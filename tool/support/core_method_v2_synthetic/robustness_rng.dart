// Deterministic PRNG for offline Core Method v2 robustness experiments.
// CLI/test-only. Not a production library.

class RobustnessRng {
  int _state;

  RobustnessRng(int seed) : _state = seed & 0xFFFFFFFF;

  /// xorshift32 — deterministic, no platform entropy.
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  double nextDouble() => nextUint32() / 4294967296.0;

  double nextBounded(double min, double max) =>
      min + (max - min) * nextDouble();

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError('maxExclusive must be > 0');
    }
    return nextUint32() % maxExclusive;
  }

  bool nextBool([double p = 0.5]) => nextDouble() < p;

  T choose<T>(List<T> items) => items[nextInt(items.length)];

  List<int> sampleDistinctIndices(int population, int sampleSize) {
    if (sampleSize > population) {
      throw ArgumentError('sampleSize > population');
    }
    final indices = List<int>.generate(population, (i) => i);
    for (var i = 0; i < sampleSize; i++) {
      final j = i + nextInt(population - i);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    return indices.sublist(0, sampleSize)..sort();
  }
}
