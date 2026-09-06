import 'auth_provider_resolver.dart';

/// Create-if-missing / safe-merge plan for `users/{uid}`.
///
/// Existing completion, profile, and identity fields are never reset.
/// Provider linking reuses this helper idempotently and must not rewrite
/// `auth_provider`, IQ/EQ/Frequency/Persona, profile, Discover, or
/// subscription fields on an existing document.
///
/// Google/Apple provider profile names are prefill candidates only. They must
/// not become canonical `users.name` on create. Email/phone keep their
/// existing create-time name seeding.
class UserDocumentEnsureInput {
  const UserDocumentEnsureInput({
    required this.uid,
    required this.authProvider,
    this.phoneNumber,
    this.email,
    this.displayName,
  });

  final String uid;
  final String authProvider;
  final String? phoneNumber;
  final String? email;
  final String? displayName;
}

class UserDocumentEnsureWrite {
  const UserDocumentEnsureWrite._({
    required this.isCreate,
    required this.fields,
  });

  factory UserDocumentEnsureWrite.create(Map<String, dynamic> fields) {
    return UserDocumentEnsureWrite._(isCreate: true, fields: fields);
  }

  factory UserDocumentEnsureWrite.merge(Map<String, dynamic> fields) {
    return UserDocumentEnsureWrite._(isCreate: false, fields: fields);
  }

  final bool isCreate;
  final Map<String, dynamic> fields;
}

class UserDocumentEnsure {
  UserDocumentEnsure._();

  static const Set<String> protectedExistingFields = {
    'test_completed',
    'frequency_completed',
    'profile_completed',
    'discover_eligible',
    'active',
    'name',
  };

  static bool isBlank(Object? value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  /// OAuth profile names stay off `users.name` until the user confirms them.
  static bool persistProviderDisplayNameAsCanonical(String authProvider) {
    return authProvider != AuthProviderResolver.google &&
        authProvider != AuthProviderResolver.apple;
  }

  static UserDocumentEnsureWrite decide({
    required Map<String, dynamic>? existing,
    required UserDocumentEnsureInput input,
    required Object Function() timestamp,
  }) {
    if (existing == null) {
      final trimmedName = input.displayName?.trim() ?? '';
      final seedName =
          persistProviderDisplayNameAsCanonical(input.authProvider) &&
              trimmedName.isNotEmpty;
      return UserDocumentEnsureWrite.create({
        'uid': input.uid,
        if (!isBlank(input.phoneNumber)) 'phone_number': input.phoneNumber,
        if (seedName) 'name': trimmedName,
        'email': input.email,
        'auth_provider': input.authProvider,
        'test_completed': false,
        'frequency_completed': false,
        'profile_completed': false,
        'discover_eligible': false,
        'active': true,
        'created_at': timestamp(),
        'updated_at': timestamp(),
        'last_active_at': timestamp(),
      });
    }

    final merge = <String, dynamic>{
      'updated_at': timestamp(),
      'last_active_at': timestamp(),
    };
    if (isBlank(existing['auth_provider'])) {
      merge['auth_provider'] = input.authProvider;
    }
    if (isBlank(existing['phone_number']) && !isBlank(input.phoneNumber)) {
      merge['phone_number'] = input.phoneNumber;
    }
    if (isBlank(existing['email']) && !isBlank(input.email)) {
      merge['email'] = input.email;
    }
    return UserDocumentEnsureWrite.merge(merge);
  }

  /// In-memory apply used by tests. Same create-vs-merge rules as production.
  static Map<String, dynamic> applyInMemory({
    required Map<String, Map<String, dynamic>> docs,
    required UserDocumentEnsureInput input,
    Object Function()? timestamp,
  }) {
    final existing = docs[input.uid];
    final write = decide(
      existing: existing == null ? null : Map<String, dynamic>.from(existing),
      input: input,
      timestamp: timestamp ?? () => 'ts',
    );
    if (write.isCreate) {
      docs[input.uid] = Map<String, dynamic>.from(write.fields);
    } else {
      docs[input.uid] = <String, dynamic>{
        ...existing!,
        ...write.fields,
      };
    }
    return docs[input.uid]!;
  }
}
