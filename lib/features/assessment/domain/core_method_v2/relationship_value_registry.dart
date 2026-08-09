import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';

class RelationshipValueFieldDefinition {
  final String fieldId;
  final String valueType;
  final List<String> allowedValues;
  final bool supportsHardConstraint;
  final bool supportsSoftPreference;
  final String sensitiveDataLevel;
  final bool directlyAskedOnly;
  final bool inferenceProhibited;
  final String description;
  final bool pendingContentReview;

  const RelationshipValueFieldDefinition({
    required this.fieldId,
    required this.valueType,
    required this.allowedValues,
    required this.supportsHardConstraint,
    required this.supportsSoftPreference,
    required this.sensitiveDataLevel,
    required this.directlyAskedOnly,
    required this.inferenceProhibited,
    required this.description,
    required this.pendingContentReview,
  });

  factory RelationshipValueFieldDefinition.fromJson(Map<String, dynamic> j) {
    final id = j['field_id']?.toString() ?? '';
    cmRequire(id.isNotEmpty, 'field_id', 'missing', 'field_id required');
    return RelationshipValueFieldDefinition(
      fieldId: id,
      valueType: j['value_type']?.toString() ?? '',
      allowedValues: [
        for (final e in (j['allowed_values'] as List?) ?? const [])
          e.toString(),
      ],
      supportsHardConstraint: j['supports_hard_constraint'] == true,
      supportsSoftPreference: j['supports_soft_preference'] == true,
      sensitiveDataLevel: j['sensitive_data_level']?.toString() ?? 'medium',
      directlyAskedOnly: j['directly_asked_only'] == true,
      inferenceProhibited: j['inference_prohibited'] == true,
      description: j['description']?.toString() ?? '',
      pendingContentReview: j['pending_content_review'] == true,
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'value_type': valueType,
        'allowed_values': allowedValues,
        'supports_hard_constraint': supportsHardConstraint,
        'supports_soft_preference': supportsSoftPreference,
        'sensitive_data_level': sensitiveDataLevel,
        'directly_asked_only': directlyAskedOnly,
        'inference_prohibited': inferenceProhibited,
        'description': description,
        'pending_content_review': pendingContentReview,
      });
}

class RelationshipValueRegistry {
  final String registryId;
  final String registryVersion;
  final String status;
  final List<RelationshipValueFieldDefinition> fields;

  RelationshipValueRegistry({
    required this.registryId,
    required this.registryVersion,
    required this.status,
    required this.fields,
  }) {
    final seen = <String>{};
    for (final f in fields) {
      cmRequire(seen.add(f.fieldId), 'fields', 'duplicate_field', f.fieldId);
    }
  }

  Map<String, RelationshipValueFieldDefinition> get fieldsById => {
        for (final f in fields) f.fieldId: f,
      };

  RelationshipValueFieldDefinition require(String fieldId) {
    final f = fieldsById[fieldId];
    if (f == null) {
      throw CoreMethodValidationException('unknown value field', [
        CoreMethodValidationError(
          fieldPath: 'field_id',
          reasonCode: 'unknown_field',
          explanation: fieldId,
        ),
      ]);
    }
    return f;
  }

  factory RelationshipValueRegistry.fromJson(Map<String, dynamic> j) {
    return RelationshipValueRegistry(
      registryId: j['registry_id']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      fields: [
        for (final e in (j['fields'] as List?) ?? const [])
          RelationshipValueFieldDefinition.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
      ],
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'registry_id': registryId,
        'registry_version': registryVersion,
        'schema_version': registryVersion,
        'status': status,
        'fields': [for (final f in fields) f.toJson()],
      });

  static RelationshipValueRegistry parseJsonString(String text) =>
      RelationshipValueRegistry.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static RelationshipValueRegistry loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
