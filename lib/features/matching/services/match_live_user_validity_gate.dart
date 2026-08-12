import '../../discover/services/discover_l1_eligibility_gate.dart';

/// Live user-doc validity for Like → match (`stale_user_match_eligibility_v1`).
///
/// Aligns with Discover L1 account gates **and** requires `discover_eligible == true`.
class MatchLiveUserValidityGate {
  MatchLiveUserValidityGate._();

  static const String policyVersion = 'stale_user_match_eligibility_v1';

  /// Photo rule consistent with Discover / ProfileService eligibility.
  static bool hasValidPhoto(Map<String, dynamic> data) {
    final url = (data['profile_photo_url'] as String?)?.trim();
    if (url != null && url.isNotEmpty) return true;
    final photos = data['photos'];
    if (photos is List) {
      for (final p in photos) {
        if (p is String && p.trim().isNotEmpty) return true;
      }
    }
    return false;
  }

  /// True when the user doc exists and is eligible for a **new** Like/match.
  static bool isValidLiveUser({
    required bool exists,
    required Map<String, dynamic>? data,
  }) {
    if (!exists || data == null) return false;
    if (data['discover_eligible'] != true) return false;

    final active = data['active'] as bool? ?? true;
    final profileCompleted = data['profile_completed'] as bool? ?? false;
    final testCompleted = data['test_completed'] as bool? ?? false;
    final assessmentFlowCompleted =
        data['assessment_flow_completed'] as bool? ?? false;

    return DiscoverL1EligibilityGate.passesLocalAccountGates(
      active: active,
      profileCompleted: profileCompleted,
      testCompleted: testCompleted,
      assessmentFlowCompleted: assessmentFlowCompleted,
      hasPhoto: hasValidPhoto(data),
    );
  }
}
