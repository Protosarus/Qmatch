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
