import '../models/user_profile_model.dart';

/// Result of reading the authenticated user's `users/{uid}` profile document.
///
/// Uses the same Firestore path as [ProfileService.getProfile].
enum ProfileReadStatus {
  loaded,
  missing,
  failed,
  unauthenticated,
}

class ProfileReadResult {
  const ProfileReadResult._(this.status, this.profile);

  const ProfileReadResult.loaded(UserProfileModel profile)
      : this._(ProfileReadStatus.loaded, profile);

  const ProfileReadResult.missing() : this._(ProfileReadStatus.missing, null);

  const ProfileReadResult.failed() : this._(ProfileReadStatus.failed, null);

  const ProfileReadResult.unauthenticated()
      : this._(ProfileReadStatus.unauthenticated, null);

  final ProfileReadStatus status;
  final UserProfileModel? profile;
}
