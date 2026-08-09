/// Canonical display-name persistence keys (P2C-1C-4A).
///
/// Domain property: [displayName]. Firestore key remains `name` per repo convention.
class DisplayNameContract {
  DisplayNameContract._();

  /// Canonical Firestore field on `users/{uid}`.
  static const String firestoreField = 'name';

  /// Minimum / maximum user-perceived grapheme counts.
  static const int minGraphemes = 2;
  static const int maxGraphemes = 24;
}
