import 'canonical_dimension_registry.dart';
import 'core_method_v2_validation.dart';

enum PreferenceMode { range, similarityToSelf, open, unavailable }

PreferenceMode parsePreferenceMode(String raw) {
  switch (raw) {
    case 'range':
      return PreferenceMode.range;
    case 'similarity_to_self':
      return PreferenceMode.similarityToSelf;
    case 'open':
      return PreferenceMode.open;
    case 'unavailable':
      return PreferenceMode.unavailable;
    default:
      throw CoreMethodValidationException('unknown preference mode', [
        CoreMethodValidationError(
          fieldPath: 'preference_mode',
          reasonCode: 'unknown_mode',
          explanation: raw,
        ),
      ]);
  }
}

extension PreferenceModeX on PreferenceMode {
  String get wire {
    switch (this) {
      case PreferenceMode.range:
        return 'range';
      case PreferenceMode.similarityToSelf:
        return 'similarity_to_self';
      case PreferenceMode.open:
        return 'open';
      case PreferenceMode.unavailable:
        return 'unavailable';
    }
  }
}

class PartnerDimensionPreference {
  final String dimensionId;
  final double? preferredMin;
  final double? preferredMax;
  final double? importance;
  final double? flexibility;
  final PreferenceMode preferenceMode;
  final String source;
  final bool explicitlyProvided;
  final DateTime? updatedAt;

  PartnerDimensionPreference({
    required this.dimensionId,
    required this.preferredMin,
    required this.preferredMax,
    required this.importance,
    required this.flexibility,
    required this.preferenceMode,
    required this.source,
    required this.explicitlyProvided,
    required this.updatedAt,
  });

  void validate(CanonicalDimensionRegistry registry) {
    final def = registry.require(dimensionId);
    cmRequire(def.supportsPartnerPreference, 'dimensionId', 'unsupported',
        '$dimensionId does not support partner preference');
    if (importance != null) {
      cmRequireFinite01(importance, 'importance', allowNull: false);
    }
    if (flexibility != null) {
      cmRequireFinite01(flexibility, 'flexibility', allowNull: false);
    }
    switch (preferenceMode) {
      case PreferenceMode.range:
        cmRequireFinite01(preferredMin, 'preferredMin', allowNull: false);
        cmRequireFinite01(preferredMax, 'preferredMax', allowNull: false);
        cmRequire(preferredMin! <= preferredMax!, 'preferred', 'range',
            'min must be <= max');
        break;
      case PreferenceMode.open:
      case PreferenceMode.unavailable:
        cmRequire(preferredMin == null && preferredMax == null, 'preferred',
            'unexpected_range', 'open/unavailable must not carry ranges');
        break;
      case PreferenceMode.similarityToSelf:
        // Range optional; if present must be valid.
        if (preferredMin != null || preferredMax != null) {
          cmRequireFinite01(preferredMin, 'preferredMin', allowNull: false);
          cmRequireFinite01(preferredMax, 'preferredMax', allowNull: false);
          cmRequire(preferredMin! <= preferredMax!, 'preferred', 'range',
              'min must be <= max');
        }
        break;
    }
  }

  factory PartnerDimensionPreference.fromJson(
    Map<String, dynamic> j, {
    required CanonicalDimensionRegistry registry,
  }) {
    final p = PartnerDimensionPreference(
      dimensionId: j['dimension_id']?.toString() ?? '',
      preferredMin: (j['preferred_min'] as num?)?.toDouble(),
      preferredMax: (j['preferred_max'] as num?)?.toDouble(),
      importance: (j['importance'] as num?)?.toDouble(),
      flexibility: (j['flexibility'] as num?)?.toDouble(),
      preferenceMode:
          parsePreferenceMode(j['preference_mode']?.toString() ?? ''),
      source: j['source']?.toString() ?? '',
      explicitlyProvided: j['explicitly_provided'] == true,
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.parse(j['updated_at'].toString()),
    );
    p.validate(registry);
    return p;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'dimension_id': dimensionId,
        'preferred_min': preferredMin,
        'preferred_max': preferredMax,
        'importance': importance,
        'flexibility': flexibility,
        'preference_mode': preferenceMode.wire,
        'source': source,
        'explicitly_provided': explicitlyProvided,
        'updated_at': updatedAt?.toIso8601String(),
      });
}
