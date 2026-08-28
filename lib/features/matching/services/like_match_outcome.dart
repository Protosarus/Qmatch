/// Minimal public outcome of Discover Like → mutual-match evaluation.
///
/// Wire names: `created_new_match`, `existing_active_match`, `no_match`.
enum LikeMatchOutcome {
  /// Mutual likes created a new active match + thread in this call.
  createdNewMatch,

  /// An active match already existed; no new artifacts written.
  existingActiveMatch,

  /// No active match after this Like (one-sided, refused, etc.).
  noMatch,
}

/// Public Like callable result (`outcome` + `like_rewindable` only).
///
/// Never includes block existence, block reason, or internal refusal names.
class LikeMatchResult {
  const LikeMatchResult({
    required this.outcome,
    required this.likeRewindable,
  });

  final LikeMatchOutcome outcome;

  /// True only for a persisted one-sided Discover Like.
  /// Missing or non-`true` wire values are false (fail closed).
  final bool likeRewindable;

  /// Discover Rewind is armed only for `no_match` + [likeRewindable].
  bool get shouldArmLikeRewind =>
      outcome == LikeMatchOutcome.noMatch && likeRewindable;

  /// Parses the public callable payload. Unknown / missing values fail closed.
  factory LikeMatchResult.fromWire(Object? raw) {
    final map = <String, dynamic>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (key is String) {
          map[key] = value;
        }
      });
    }
    return LikeMatchResult(
      outcome: _outcomeFromWire(map['outcome']),
      likeRewindable: map['like_rewindable'] == true,
    );
  }

  static LikeMatchOutcome _outcomeFromWire(Object? raw) {
    switch (raw) {
      case 'created_new_match':
        return LikeMatchOutcome.createdNewMatch;
      case 'existing_active_match':
        return LikeMatchOutcome.existingActiveMatch;
      default:
        return LikeMatchOutcome.noMatch;
    }
  }
}
