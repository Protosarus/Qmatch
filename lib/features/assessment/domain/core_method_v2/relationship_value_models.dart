import 'core_method_v2_validation.dart';
import 'relationship_value_registry.dart';

class RelationshipValueResponse {
  final String fieldId;
  final String? selectedValue;
  final List<String> selectedValues;
  final double? importance;
  final double? flexibility;
  final bool explicitlyProvided;
  final DateTime? responseTimestamp;
  final String registryVersion;
  final String visibilityPolicy;
  final bool comparisonPermission;

  RelationshipValueResponse({
    required this.fieldId,
    required this.selectedValue,
    required this.selectedValues,
    required this.importance,
    required this.flexibility,
    required this.explicitlyProvided,
    required this.responseTimestamp,
    required this.registryVersion,
    required this.visibilityPolicy,
    required this.comparisonPermission,
  });

  void validate(RelationshipValueRegistry registry) {
    final def = registry.require(fieldId);
    cmRequire(def.directlyAskedOnly, 'fieldId', 'must_be_direct', fieldId);
    cmRequire(
        def.inferenceProhibited, 'fieldId', 'inference_forbidden', fieldId);
    if (importance != null) {
      cmRequireFinite01(importance, 'importance', allowNull: false);
    }
    if (flexibility != null) {
      cmRequireFinite01(flexibility, 'flexibility', allowNull: false);
    }
    if (selectedValue != null) {
      cmRequire(def.allowedValues.contains(selectedValue), 'selectedValue',
          'invalid_value', '$selectedValue not allowed for $fieldId');
    }
    for (final v in selectedValues) {
      cmRequire(def.allowedValues.contains(v), 'selectedValues',
          'invalid_value', '$v not allowed for $fieldId');
    }
  }

  factory RelationshipValueResponse.fromJson(
    Map<String, dynamic> j, {
    required RelationshipValueRegistry registry,
  }) {
    final r = RelationshipValueResponse(
      fieldId: j['field_id']?.toString() ?? '',
      selectedValue: j['selected_value']?.toString(),
      selectedValues: [
        for (final e in (j['selected_values'] as List?) ?? const [])
          e.toString(),
      ],
      importance: (j['importance'] as num?)?.toDouble(),
      flexibility: (j['flexibility'] as num?)?.toDouble(),
      explicitlyProvided: j['explicitly_provided'] == true,
      responseTimestamp: j['response_timestamp'] == null
          ? null
          : DateTime.parse(j['response_timestamp'].toString()),
      registryVersion: j['registry_version']?.toString() ?? '',
      visibilityPolicy: j['visibility_policy']?.toString() ?? 'private',
      comparisonPermission: j['comparison_permission'] == true,
    );
    r.validate(registry);
    return r;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'selected_value': selectedValue,
        'selected_values': selectedValues,
        'importance': importance,
        'flexibility': flexibility,
        'explicitly_provided': explicitlyProvided,
        'response_timestamp': responseTimestamp?.toIso8601String(),
        'registry_version': registryVersion,
        'visibility_policy': visibilityPolicy,
        'comparison_permission': comparisonPermission,
      });
}

class RelationshipValueProfile {
  final Map<String, RelationshipValueResponse> responses;
  final String profileVersion;
  final String registryVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RelationshipValueProfile({
    required this.responses,
    required this.profileVersion,
    required this.registryVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate(RelationshipValueRegistry registry) {
    for (final e in responses.entries) {
      cmRequire(e.key == e.value.fieldId, 'responses', 'key_mismatch', e.key);
      e.value.validate(registry);
    }
  }

  factory RelationshipValueProfile.fromJson(
    Map<String, dynamic> j, {
    required RelationshipValueRegistry registry,
  }) {
    final raw = Map<String, dynamic>.from(j['responses'] as Map? ?? {});
    final keys = raw.keys.toList()..sort();
    final responses = <String, RelationshipValueResponse>{
      for (final k in keys)
        k: RelationshipValueResponse.fromJson(
          Map<String, dynamic>.from(raw[k] as Map),
          registry: registry,
        ),
    };
    final profile = RelationshipValueProfile(
      responses: responses,
      profileVersion: j['profile_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      createdAt: j['created_at'] == null
          ? null
          : DateTime.parse(j['created_at'].toString()),
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.parse(j['updated_at'].toString()),
    );
    profile.validate(registry);
    return profile;
  }

  Map<String, dynamic> toJson() {
    final keys = responses.keys.toList()..sort();
    return cmSortedMap({
      'responses': {for (final k in keys) k: responses[k]!.toJson()},
      'profile_version': profileVersion,
      'registry_version': registryVersion,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    });
  }
}
