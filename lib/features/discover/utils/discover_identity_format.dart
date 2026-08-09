import '../../../core/identity/identity.dart';

/// Presentation-only identity formatting for Discover cards.
///
/// Delegates to [UserIdentityResolver] — never emits `", 26"` or age-only
/// identity headers.
String? formatDiscoverIdentity({
  required String name,
  int? age,
}) {
  return UserIdentityResolver.formatNameAndAge(
    displayName: name,
    age: age,
  );
}
