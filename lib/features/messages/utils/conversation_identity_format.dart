import '../../../core/identity/identity.dart';

/// Presentation-only identity formatting for Messages conversation rows.
///
/// Delegates to [UserIdentityResolver] — never emits malformed commas.
String? formatConversationIdentity({
  required String name,
  int? age,
}) {
  return UserIdentityResolver.formatNameAndAge(
    displayName: name,
    age: age,
  );
}
