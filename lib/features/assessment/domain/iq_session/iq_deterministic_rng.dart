import 'iq_session_contract.dart';

/// Deterministic PRNG for IQ session composition.
///
/// Algorithm version: [IqSessionContract.rngAlgorithmVersion]
///
/// - Seed material is mixed with FNV-1a 32-bit (never Dart identity hashing).
/// - Stream advances with xorshift32 (platform-independent).
/// - No timestamps, no global Random(), no unordered-map entropy.
class IqDeterministicRng {
  IqDeterministicRng._(this._state);

  int _state;

  /// Derive a 32-bit seed from explicit parts (order matters).
  factory IqDeterministicRng.fromParts(List<String> parts) {
    var hash = 0x811c9dc5;
    for (final part in parts) {
      hash = fnv1a32Update(hash, part);
      // Separator so ["ab","c"] ≠ ["a","bc"].
      hash = fnv1a32Update(hash, '\u0000');
    }
    if (hash == 0) hash = 0xA5A5A5A5;
    return IqDeterministicRng._(hash & 0xFFFFFFFF);
  }

  /// Convenience: policy + bank + session seed (+ optional stream label).
  factory IqDeterministicRng.forSession({
    required String selectionPolicyVersion,
    required String bankVersion,
    required String sessionSeed,
    String stream = 'compose',
  }) {
    return IqDeterministicRng.fromParts([
      selectionPolicyVersion,
      bankVersion,
      sessionSeed,
      stream,
      IqSessionContract.rngAlgorithmVersion,
    ]);
  }

  /// Stable FNV-1a 32-bit over UTF-16 code units (Dart string codeUnits).
  static int fnv1a32(String input) {
    return fnv1a32Update(0x811c9dc5, input) & 0xFFFFFFFF;
  }

  static int fnv1a32Update(int hash, String input) {
    var h = hash & 0xFFFFFFFF;
    for (final unit in input.codeUnits) {
      h ^= unit & 0xFFFF;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Uniform in `[0, maxExclusive)`.
  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'must be > 0');
    }
    // Rejection sampling to avoid modulo bias for small ranges.
    final bound = 0x100000000 ~/ maxExclusive * maxExclusive;
    while (true) {
      final r = nextUint32();
      if (r < bound) return r % maxExclusive;
    }
  }

  double nextDouble() => nextUint32() / 4294967296.0;

  /// Fisher–Yates using this stream. Mutates a **copy**.
  List<T> shuffledCopy<T>(List<T> input) {
    final list = List<T>.from(input);
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
