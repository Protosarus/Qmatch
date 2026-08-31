import 'frequency_behavior_v2_contract.dart';

/// Deterministic PRNG for dormant Frequency V2 session composition.
///
/// Algorithm version: [FrequencyBehaviorV2Contract.selectorRngAlgorithmVersion]
///
/// - Seed material is mixed with FNV-1a 32-bit (never Dart identity hashing).
/// - Stream advances with xorshift32 (platform-independent).
/// - No timestamps, no global Random(), no unordered-map entropy.
/// - [createdAt] and wall-clock time are never mixed into the seed.
class FrequencyBehaviorV2Rng {
  FrequencyBehaviorV2Rng._(this._state);

  int _state;

  factory FrequencyBehaviorV2Rng.fromParts(List<String> parts) {
    var hash = 0x811c9dc5;
    for (final part in parts) {
      hash = fnv1a32Update(hash, part);
      hash = fnv1a32Update(hash, '\u0000');
    }
    if (hash == 0) hash = 0xA5A5A5A5;
    return FrequencyBehaviorV2Rng._(hash & 0xFFFFFFFF);
  }

  factory FrequencyBehaviorV2Rng.forStream({
    required String selectorVersion,
    required String bankVersion,
    required String sessionSeed,
    required String stream,
  }) {
    return FrequencyBehaviorV2Rng.fromParts([
      selectorVersion,
      bankVersion,
      sessionSeed,
      stream,
      FrequencyBehaviorV2Contract.selectorRngAlgorithmVersion,
    ]);
  }

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

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive', 'must be > 0');
    }
    final bound = 0x100000000 ~/ maxExclusive * maxExclusive;
    while (true) {
      final r = nextUint32();
      if (r < bound) return r % maxExclusive;
    }
  }

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
