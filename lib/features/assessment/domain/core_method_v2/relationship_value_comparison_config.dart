import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';
import 'relationship_value_registry.dart';

class RelationshipValueFieldRule {
  final String fieldId;
  final String comparisonMode;
  final String directionality;
  final bool provisional;
  final bool pendingExpertContentReview;
  final bool productionApproved;
  final Map<String, Map<String, double>>? matrixCells;
  final List<String>? orderedValues;
  final String? setOverlapMetric;
  final String? emptySetPolicy;
  final String? hardConstraintMatchMode;
  final String? exclusionReason;

  const RelationshipValueFieldRule({
    required this.fieldId,
    required this.comparisonMode,
    required this.directionality,
    required this.provisional,
    required this.pendingExpertContentReview,
    required this.productionApproved,
    this.matrixCells,
    this.orderedValues,
    this.setOverlapMetric,
    this.emptySetPolicy,
    this.hardConstraintMatchMode,
    this.exclusionReason,
  });

  factory RelationshipValueFieldRule.fromJson(
    String fieldId,
    Map<String, dynamic> j,
  ) {
    Map<String, Map<String, double>>? cells;
    final matrix = j['matrix'];
    if (matrix is Map) {
      final rawCells = Map<String, dynamic>.from(
        (matrix['cells'] as Map?) ?? const {},
      );
      cells = {
        for (final row in rawCells.entries)
          row.key: {
            for (final col
                in Map<String, dynamic>.from(row.value as Map).entries)
              col.key: (col.value as num).toDouble(),
          },
      };
    }
    return RelationshipValueFieldRule(
      fieldId: fieldId,
      comparisonMode: j['comparison_mode']?.toString() ?? '',
      directionality: j['directionality']?.toString() ?? '',
      provisional: j['provisional'] == true,
      pendingExpertContentReview: j['pending_expert_content_review'] == true,
      productionApproved: j['production_approved'] == true,
      matrixCells: cells,
      orderedValues: j['ordered_values'] == null
          ? null
          : [
              for (final e in j['ordered_values'] as List) e.toString(),
            ],
      setOverlapMetric: j['set_overlap_metric']?.toString(),
      emptySetPolicy: j['empty_set_policy']?.toString(),
      hardConstraintMatchMode: j['hard_constraint_match_mode']?.toString(),
      exclusionReason: j['exclusion_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'comparison_mode': comparisonMode,
        'directionality': directionality,
        'provisional': provisional,
        'pending_expert_content_review': pendingExpertContentReview,
        'production_approved': productionApproved,
        if (matrixCells != null)
          'matrix': {
            'directionality': directionality,
            'cells': {
              for (final r in matrixCells!.entries)
                r.key: {for (final c in r.value.entries) c.key: c.value},
            },
          },
        if (orderedValues != null) 'ordered_values': orderedValues,
        if (setOverlapMetric != null) 'set_overlap_metric': setOverlapMetric,
        if (emptySetPolicy != null) 'empty_set_policy': emptySetPolicy,
        if (hardConstraintMatchMode != null)
          'hard_constraint_match_mode': hardConstraintMatchMode,
        if (exclusionReason != null) 'exclusion_reason': exclusionReason,
      });
}

class SoftConflictSeverityBands {
  final double noneMax;
  final double lowMax;
  final double moderateMax;
  final double highMax;

  const SoftConflictSeverityBands({
    required this.noneMax,
    required this.lowMax,
    required this.moderateMax,
    required this.highMax,
  });

  factory SoftConflictSeverityBands.fromJson(Map<String, dynamic> j) {
    double maxOf(String key) =>
        ((j[key] as Map?)?['max'] as num?)?.toDouble() ?? double.nan;
    return SoftConflictSeverityBands(
      noneMax: maxOf('none'),
      lowMax: maxOf('low'),
      moderateMax: maxOf('moderate'),
      highMax: maxOf('high'),
    );
  }

  String bandFor(double severity) {
    if (severity == 0) return 'none';
    if (severity <= lowMax) return 'low';
    if (severity <= moderateMax) return 'moderate';
    return 'high';
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'none': {'min': 0.0, 'max': noneMax},
        'low': {'min_exclusive': 0.0, 'max': lowMax},
        'moderate': {'min_exclusive': lowMax, 'max': moderateMax},
        'high': {'min_exclusive': moderateMax, 'max': highMax},
      });
}

class RelationshipValueComparisonConfig {
  final String configId;
  final String configVersion;
  final String registryVersion;
  final String status;
  final String calibrationStatus;
  final String runtimeStatus;
  final bool productionApproved;
  final bool scientificallyValidated;
  final List<String> supportedComparisonModes;
  final double importanceMin;
  final double importanceMax;
  final double flexibilityMin;
  final double flexibilityMax;
  final double scoreMin;
  final double scoreMax;
  final int minimumComparableValueFields;
  final String mutualAggregationMode;
  final String evidenceConfidencePolicy;
  final String missingDataPolicy;
  final String privateDataPolicy;
  final String unsupportedFieldPolicy;
  final String hardConstraintUnknownPolicy;
  final String versionCompatibilityPolicy;
  final String defaultHardConstraintMatchMode;
  final List<String> supportedHardConstraintMatchModes;
  final SoftConflictSeverityBands softConflictSeverityBands;
  final List<String> visibilityPoliciesAllowingComparison;
  final String complementarityStatus;
  final String personaInputStatus;
  final String aiScoringStatus;
  final Map<String, RelationshipValueFieldRule> fieldRules;

  RelationshipValueComparisonConfig({
    required this.configId,
    required this.configVersion,
    required this.registryVersion,
    required this.status,
    required this.calibrationStatus,
    required this.runtimeStatus,
    required this.productionApproved,
    required this.scientificallyValidated,
    required this.supportedComparisonModes,
    required this.importanceMin,
    required this.importanceMax,
    required this.flexibilityMin,
    required this.flexibilityMax,
    required this.scoreMin,
    required this.scoreMax,
    required this.minimumComparableValueFields,
    required this.mutualAggregationMode,
    required this.evidenceConfidencePolicy,
    required this.missingDataPolicy,
    required this.privateDataPolicy,
    required this.unsupportedFieldPolicy,
    required this.hardConstraintUnknownPolicy,
    required this.versionCompatibilityPolicy,
    required this.defaultHardConstraintMatchMode,
    required this.supportedHardConstraintMatchModes,
    required this.softConflictSeverityBands,
    required this.visibilityPoliciesAllowingComparison,
    required this.complementarityStatus,
    required this.personaInputStatus,
    required this.aiScoringStatus,
    required this.fieldRules,
  }) {
    validate();
  }

  RelationshipValueFieldRule? ruleFor(String fieldId) => fieldRules[fieldId];

  void validate() {
    cmRequire(status == 'provisional', 'status', 'must_be_provisional', status);
    cmRequire(calibrationStatus == 'uncalibrated', 'calibration_status',
        'must_be_uncalibrated', calibrationStatus);
    cmRequire(runtimeStatus == 'offline_only', 'runtime_status',
        'must_be_offline_only', runtimeStatus);
    cmRequire(!productionApproved, 'production_approved', 'must_be_false',
        'not production approved');
    cmRequire(!scientificallyValidated, 'scientifically_validated',
        'must_be_false', 'not scientifically validated');
    cmRequire(mutualAggregationMode == 'geometric_mean',
        'mutual_aggregation_mode', 'unexpected', mutualAggregationMode);
    cmRequire(
        minimumComparableValueFields >= 1,
        'minimum_comparable_value_fields',
        'invalid',
        '$minimumComparableValueFields');
    cmRequire(
      complementarityStatus == 'disabled_pending_calibration',
      'complementarity_status',
      'must_be_disabled',
      complementarityStatus,
    );
    cmRequire(personaInputStatus == 'prohibited', 'persona_input_status',
        'must_be_prohibited', personaInputStatus);
    cmRequire(aiScoringStatus == 'prohibited', 'ai_scoring_status',
        'must_be_prohibited', aiScoringStatus);
    for (final m in const [
      'exact_match',
      'categorical_compatibility_matrix',
      'ordered_distance',
      'set_overlap',
      'comparison_pending_review',
    ]) {
      cmRequire(supportedComparisonModes.contains(m),
          'supported_comparison_modes', 'missing_mode', m);
    }
  }

  void validateAgainstRegistry(RelationshipValueRegistry registry) {
    cmRequire(
      registryVersion == registry.registryVersion,
      'registry_version',
      'registry_version_mismatch',
      '$registryVersion vs ${registry.registryVersion}',
    );
    for (final e in fieldRules.entries) {
      final def = registry.require(e.key);
      final rule = e.value;
      cmRequire(rule.provisional, 'field_rules.${e.key}', 'must_be_provisional',
          e.key);
      cmRequire(!rule.productionApproved, 'field_rules.${e.key}',
          'must_not_be_production_approved', e.key);
      switch (rule.comparisonMode) {
        case 'categorical_compatibility_matrix':
          final cells = rule.matrixCells;
          cmRequire(cells != null, 'matrix', 'missing', e.key);
          for (final a in def.allowedValues) {
            cmRequire(cells!.containsKey(a), 'matrix', 'missing_row', a);
            for (final b in def.allowedValues) {
              cmRequire(
                  cells[a]!.containsKey(b), 'matrix', 'missing_cell', '$a|$b');
              final v = cells[a]![b]!;
              cmRequire(v.isFinite && v >= 0 && v <= 1, 'matrix',
                  'out_of_range', '$a|$b=$v');
              if (rule.directionality == 'symmetric') {
                cmRequire(
                  (cells[a]![b]! - cells[b]![a]!).abs() < 1e-12,
                  'matrix',
                  'not_symmetric',
                  '$a|$b',
                );
              }
            }
          }
          break;
        case 'ordered_distance':
          final ordered = rule.orderedValues ?? const [];
          cmRequire(ordered.toSet().length == ordered.length, 'ordered_values',
              'duplicates', e.key);
          cmRequire(
            ordered.toSet().containsAll(def.allowedValues) &&
                def.allowedValues.toSet().containsAll(ordered),
            'ordered_values',
            'set_mismatch',
            e.key,
          );
          break;
        case 'set_overlap':
          cmRequire(rule.setOverlapMetric == 'jaccard', 'set_overlap_metric',
              'unexpected', '${rule.setOverlapMetric}');
          cmRequire(rule.emptySetPolicy != null, 'empty_set_policy', 'missing',
              e.key);
          break;
        case 'exact_match':
        case 'comparison_pending_review':
          break;
        default:
          cmRequire(
              false, 'comparison_mode', 'unsupported', rule.comparisonMode);
      }
    }
  }

  factory RelationshipValueComparisonConfig.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> bounds(String key) =>
        Map<String, dynamic>.from(j[key] as Map? ?? {});
    final ib = bounds('importance_bounds');
    final fb = bounds('flexibility_bounds');
    final sb = bounds('score_bounds');
    final rawRules = Map<String, dynamic>.from(j['field_rules'] as Map? ?? {});
    final ruleKeys = rawRules.keys.toList()..sort();
    return RelationshipValueComparisonConfig(
      configId: j['config_id']?.toString() ?? '',
      configVersion: j['config_version']?.toString() ?? '',
      registryVersion: j['registry_version']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      calibrationStatus: j['calibration_status']?.toString() ?? '',
      runtimeStatus: j['runtime_status']?.toString() ?? '',
      productionApproved: j['production_approved'] == true,
      scientificallyValidated: j['scientifically_validated'] == true,
      supportedComparisonModes: [
        for (final e in (j['supported_comparison_modes'] as List?) ?? const [])
          e.toString(),
      ]..sort(),
      importanceMin: (ib['min'] as num?)?.toDouble() ?? 0,
      importanceMax: (ib['max'] as num?)?.toDouble() ?? 1,
      flexibilityMin: (fb['min'] as num?)?.toDouble() ?? 0,
      flexibilityMax: (fb['max'] as num?)?.toDouble() ?? 1,
      scoreMin: (sb['min'] as num?)?.toDouble() ?? 0,
      scoreMax: (sb['max'] as num?)?.toDouble() ?? 1,
      minimumComparableValueFields:
          (j['minimum_comparable_value_fields'] as num?)?.toInt() ?? 0,
      mutualAggregationMode: j['mutual_aggregation_mode']?.toString() ?? '',
      evidenceConfidencePolicy:
          j['evidence_confidence_policy']?.toString() ?? '',
      missingDataPolicy: j['missing_data_policy']?.toString() ?? '',
      privateDataPolicy: j['private_data_policy']?.toString() ?? '',
      unsupportedFieldPolicy: j['unsupported_field_policy']?.toString() ?? '',
      hardConstraintUnknownPolicy:
          j['hard_constraint_unknown_policy']?.toString() ?? '',
      versionCompatibilityPolicy:
          j['version_compatibility_policy']?.toString() ?? '',
      defaultHardConstraintMatchMode:
          j['default_hard_constraint_match_mode']?.toString() ?? 'any_allowed',
      supportedHardConstraintMatchModes: [
        for (final e in (j['supported_hard_constraint_match_modes'] as List?) ??
            const [])
          e.toString(),
      ]..sort(),
      softConflictSeverityBands: SoftConflictSeverityBands.fromJson(
        Map<String, dynamic>.from(
          j['soft_conflict_severity_bands'] as Map? ?? {},
        ),
      ),
      visibilityPoliciesAllowingComparison: [
        for (final e
            in (j['visibility_policies_allowing_comparison'] as List?) ??
                const [])
          e.toString(),
      ]..sort(),
      complementarityStatus: j['complementarity_status']?.toString() ?? '',
      personaInputStatus: j['persona_input_status']?.toString() ?? '',
      aiScoringStatus: j['ai_scoring_status']?.toString() ?? '',
      fieldRules: {
        for (final k in ruleKeys)
          k: RelationshipValueFieldRule.fromJson(
            k,
            Map<String, dynamic>.from(rawRules[k] as Map),
          ),
      },
    );
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'config_id': configId,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'status': status,
        'calibration_status': calibrationStatus,
        'runtime_status': runtimeStatus,
        'production_approved': productionApproved,
        'scientifically_validated': scientificallyValidated,
        'supported_comparison_modes': supportedComparisonModes,
        'importance_bounds': {'min': importanceMin, 'max': importanceMax},
        'flexibility_bounds': {'min': flexibilityMin, 'max': flexibilityMax},
        'score_bounds': {'min': scoreMin, 'max': scoreMax},
        'minimum_comparable_value_fields': minimumComparableValueFields,
        'mutual_aggregation_mode': mutualAggregationMode,
        'evidence_confidence_policy': evidenceConfidencePolicy,
        'missing_data_policy': missingDataPolicy,
        'private_data_policy': privateDataPolicy,
        'unsupported_field_policy': unsupportedFieldPolicy,
        'hard_constraint_unknown_policy': hardConstraintUnknownPolicy,
        'version_compatibility_policy': versionCompatibilityPolicy,
        'default_hard_constraint_match_mode': defaultHardConstraintMatchMode,
        'supported_hard_constraint_match_modes':
            supportedHardConstraintMatchModes,
        'soft_conflict_severity_bands': softConflictSeverityBands.toJson(),
        'visibility_policies_allowing_comparison':
            visibilityPoliciesAllowingComparison,
        'complementarity_status': complementarityStatus,
        'persona_input_status': personaInputStatus,
        'ai_scoring_status': aiScoringStatus,
        'field_rules': {
          for (final k in (fieldRules.keys.toList()..sort()))
            k: fieldRules[k]!.toJson(),
        },
      });

  static RelationshipValueComparisonConfig parseJsonString(String text) =>
      RelationshipValueComparisonConfig.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static RelationshipValueComparisonConfig loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());
}
