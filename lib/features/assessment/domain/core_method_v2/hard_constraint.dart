import 'core_method_v2_validation.dart';
import 'relationship_value_registry.dart';

enum HardConstraintOutcome { passed, failed, unknown, notApplicable }

HardConstraintOutcome parseHardConstraintOutcome(String raw) {
  switch (raw) {
    case 'passed':
      return HardConstraintOutcome.passed;
    case 'failed':
      return HardConstraintOutcome.failed;
    case 'unknown':
      return HardConstraintOutcome.unknown;
    case 'not_applicable':
      return HardConstraintOutcome.notApplicable;
    default:
      throw CoreMethodValidationException('unknown outcome', [
        CoreMethodValidationError(
          fieldPath: 'outcome',
          reasonCode: 'unknown_outcome',
          explanation: raw,
        ),
      ]);
  }
}

extension HardConstraintOutcomeX on HardConstraintOutcome {
  String get wire {
    switch (this) {
      case HardConstraintOutcome.passed:
        return 'passed';
      case HardConstraintOutcome.failed:
        return 'failed';
      case HardConstraintOutcome.unknown:
        return 'unknown';
      case HardConstraintOutcome.notApplicable:
        return 'not_applicable';
    }
  }
}

/// Explicit hard-constraint declaration.
///
/// P2B-3 contract note: disabled constraints (`explicitlyEnabled == false`)
/// are valid objects so evaluation can return `not_applicable`. They must
/// never be treated as silently enabled.
class HardConstraint {
  final String constraintId;
  final String fieldId;
  final List<String> acceptedValues;
  final List<String> rejectedValues;
  final bool explicitlyEnabled;
  final String matchMode;
  final String source;
  final DateTime? updatedAt;
  final String registryVersion;

  HardConstraint({
    required this.constraintId,
    required this.fieldId,
    required this.acceptedValues,
    required this.rejectedValues,
    required this.explicitlyEnabled,
    this.matchMode = 'any_allowed',
    required this.source,
    required this.updatedAt,
    required this.registryVersion,
  });

  void validate(RelationshipValueRegistry registry) {
    cmRequire(
      const {
        'any_allowed',
        'all_required',
        'no_rejected_overlap',
      }.contains(matchMode),
      'matchMode',
      'unsupported_match_mode',
      matchMode,
    );
    final accepted = acceptedValues.toSet();
    final rejected = rejectedValues.toSet();
    cmRequire(
      accepted.intersection(rejected).isEmpty,
      'values',
      'accepted_rejected_overlap',
      'accepted and rejected must be disjoint',
    );
    final def = registry.require(fieldId);
    if (explicitlyEnabled) {
      cmRequire(
        def.supportsHardConstraint,
        'fieldId',
        'unsupported_hard_constraint',
        '$fieldId does not support hard constraints',
      );
    }
    for (final v in [...acceptedValues, ...rejectedValues]) {
      cmRequire(def.allowedValues.contains(v), 'values', 'invalid_value', v);
    }
  }

  factory HardConstraint.fromJson(
    Map<String, dynamic> j, {
    required RelationshipValueRegistry registry,
  }) {
    final c = HardConstraint(
      constraintId: j['constraint_id']?.toString() ?? '',
      fieldId: j['field_id']?.toString() ?? '',
      acceptedValues: [
        for (final e in (j['accepted_values'] as List?) ?? const [])
          e.toString(),
      ],
      rejectedValues: [
        for (final e in (j['rejected_values'] as List?) ?? const [])
          e.toString(),
      ],
      explicitlyEnabled: j['explicitly_enabled'] == true,
      matchMode: j['match_mode']?.toString() ?? 'any_allowed',
      source: j['source']?.toString() ?? '',
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.parse(j['updated_at'].toString()),
      registryVersion: j['registry_version']?.toString() ?? '',
    );
    c.validate(registry);
    return c;
  }

  Map<String, dynamic> toJson() => cmSortedMap({
        'constraint_id': constraintId,
        'field_id': fieldId,
        'accepted_values': acceptedValues,
        'rejected_values': rejectedValues,
        'explicitly_enabled': explicitlyEnabled,
        'match_mode': matchMode,
        'source': source,
        'updated_at': updatedAt?.toIso8601String(),
        'registry_version': registryVersion,
      });
}

class HardConstraintEvaluationResult {
  final String constraintId;
  final HardConstraintOutcome outcome;
  final String? explanationCode;

  const HardConstraintEvaluationResult({
    required this.constraintId,
    required this.outcome,
    this.explanationCode,
  });

  factory HardConstraintEvaluationResult.fromJson(Map<String, dynamic> j) =>
      HardConstraintEvaluationResult(
        constraintId: j['constraint_id']?.toString() ?? '',
        outcome: parseHardConstraintOutcome(j['outcome']?.toString() ?? ''),
        explanationCode: j['explanation_code']?.toString(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'constraint_id': constraintId,
        'outcome': outcome.wire,
        'explanation_code': explanationCode,
      });
}
