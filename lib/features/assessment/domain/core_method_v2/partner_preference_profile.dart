import 'canonical_dimension_registry.dart';
import 'core_method_v2_validation.dart';
import 'partner_dimension_preference.dart';

enum PreferenceProfileCompletionStatus {
  complete,
  partial,
  incomplete,
  unavailable,
}

PreferenceProfileCompletionStatus parsePreferenceProfileCompletionStatus(
  String raw,
) {
  switch (raw) {
    case 'complete':
      return PreferenceProfileCompletionStatus.complete;
    case 'partial':
      return PreferenceProfileCompletionStatus.partial;
    case 'incomplete':
      return PreferenceProfileCompletionStatus.incomplete;
    case 'unavailable':
      return PreferenceProfileCompletionStatus.unavailable;
    default:
      throw CoreMethodValidationException('unknown completion', [
        CoreMethodValidationError(
          fieldPath: 'completion_status',
          reasonCode: 'unknown_status',
          explanation: raw,
        ),
      ]);
  }
}

extension PreferenceProfileCompletionStatusX
    on PreferenceProfileCompletionStatus {
  String get wire {
    switch (this) {
      case PreferenceProfileCompletionStatus.complete:
        return 'complete';
      case PreferenceProfileCompletionStatus.partial:
        return 'partial';
      case PreferenceProfileCompletionStatus.incomplete:
        return 'incomplete';
      case PreferenceProfileCompletionStatus.unavailable:
        return 'unavailable';
    }
  }
}

class PartnerPreferenceProfile {
  final Map<String, PartnerDimensionPreference> preferences;
  final String profileVersion;
  final String registryVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PreferenceProfileCompletionStatus completionStatus;
  final List<String> explicitlyAnsweredDimensions;
  final List<String> openDimensions;
  final List<String> unavailableDimensions;

  PartnerPreferenceProfile({
    required this.preferences,
    required this.profileVersion,
    required this.registryVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.completionStatus,
    required this.explicitlyAnsweredDimensions,
    required this.openDimensions,
    required this.unavailableDimensions,
  });

  void validate(CanonicalDimensionRegistry registry) {
    for (final e in preferences.entries) {
      cmRequire(
          e.key == e.value.dimensionId, 'preferences', 'key_mismatch', e.key);
      e.value.validate(registry);
    }
  }

  factory PartnerPreferenceProfile.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry registry,
  }) {
    final raw = Map<String, dynamic>.from(j['preferences'] as Map? ?? {});
    final keys = raw.keys.toList()..sort();
    final prefs = <String, PartnerDimensionPreference>{
      for (final k in keys)
        k: PartnerDimensionPreference.fromJson(
          Map<String, dynamic>.from(raw[k] as Map),
          registry: registry,
        ),
    };
    final profile = PartnerPreferenceProfile(
      preferences: prefs,
      profileVersion: j['profile_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      createdAt: j['created_at'] == null
          ? null
          : DateTime.parse(j['created_at'].toString()),
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.parse(j['updated_at'].toString()),
      completionStatus: parsePreferenceProfileCompletionStatus(
        j['completion_status']?.toString() ?? '',
      ),
      explicitlyAnsweredDimensions: [
        for (final e
            in (j['explicitly_answered_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      openDimensions: [
        for (final e in (j['open_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      unavailableDimensions: [
        for (final e in (j['unavailable_dimensions'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
    );
    profile.validate(registry);
    return profile;
  }

  Map<String, dynamic> toJson() {
    final keys = preferences.keys.toList()..sort();
    return cmSortedMap({
      'preferences': {for (final k in keys) k: preferences[k]!.toJson()},
      'profile_version': profileVersion,
      'registry_version': registryVersion,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completion_status': completionStatus.wire,
      'explicitly_answered_dimensions': explicitlyAnsweredDimensions,
      'open_dimensions': openDimensions,
      'unavailable_dimensions': unavailableDimensions,
    });
  }
}
