import 'display_name_contract.dart';
import 'display_name_validator.dart';

/// Shared public identity resolution — no UID/email/phone fallbacks.
class ResolvedUserIdentity {
  const ResolvedUserIdentity({
    required this.displayName,
    required this.age,
    required this.source,
  });

  /// Public display name suitable for UI, or null when missing/unsafe.
  final String? displayName;

  /// Positive age when present; null when absent/invalid.
  final int? age;

  final UserIdentitySource source;

  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;
}

enum UserIdentitySource {
  canonicalFirestore,
  missing,
}

/// One resolver for Profile, Discover, Messages, and Chat Detail.
class UserIdentityResolver {
  UserIdentityResolver._();

  /// Extract identity from a Firestore `users/{uid}` map (or compatible).
  static ResolvedUserIdentity fromUserMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const ResolvedUserIdentity(
        displayName: null,
        age: null,
        source: UserIdentitySource.missing,
      );
    }

    final raw = data[DisplayNameContract.firestoreField];
    final rawName = raw is String ? raw : (raw?.toString() ?? '');
    final display = coerceForDisplay(rawName);
    final ageRaw = data['age'];
    final age = ageRaw is num ? ageRaw.toInt() : int.tryParse('$ageRaw');
    final safeAge = (age != null && age > 0) ? age : null;

    if (display != null) {
      return ResolvedUserIdentity(
        displayName: display,
        age: safeAge,
        source: UserIdentitySource.canonicalFirestore,
      );
    }

    return ResolvedUserIdentity(
      displayName: null,
      age: safeAge,
      source: UserIdentitySource.missing,
    );
  }

  /// Safe public header: never `", 26"`; never age-only as the identity string.
  static String? formatNameAndAge({
    String? displayName,
    int? age,
  }) {
    final name = coerceForDisplay(displayName);
    final safeAge = (age != null && age > 0) ? age : null;

    if (name != null && safeAge != null) return '$name, $safeAge';
    if (name != null) return name;
    return null;
  }

  static String? formatFromUserMap(Map<String, dynamic>? data) {
    final resolved = fromUserMap(data);
    return formatNameAndAge(
      displayName: resolved.displayName,
      age: resolved.age,
    );
  }

  /// Read-path coercion for peer/own display.
  ///
  /// Write-path remains [DisplayNameValidator.validate] (2–24 graphemes).
  static String? coerceForDisplay(String? raw) {
    if (raw == null) return null;
    final normalized = DisplayNameValidator.normalize(raw);
    if (!DisplayNameValidator.isSafePublicDisplay(normalized)) return null;
    return normalized;
  }
}
