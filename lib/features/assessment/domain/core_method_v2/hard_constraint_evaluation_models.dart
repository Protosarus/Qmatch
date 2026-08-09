import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';

class HardConstraintFieldEvaluation {
  final String constraintId;
  final String ownerId;
  final String evaluatedSubjectId;
  final String fieldId;
  final String? counterpartValue;
  final List<String> counterpartValues;
  final List<String> acceptedValues;
  final List<String> rejectedValues;
  final bool enabled;
  final String matchMode;
  final HardConstraintOutcome outcome;
  final String reasonCode;
  final String registryVersion;
  final List<String> diagnosticCodes;

  const HardConstraintFieldEvaluation({
    required this.constraintId,
    required this.ownerId,
    required this.evaluatedSubjectId,
    required this.fieldId,
    required this.counterpartValue,
    required this.counterpartValues,
    required this.acceptedValues,
    required this.rejectedValues,
    required this.enabled,
    required this.matchMode,
    required this.outcome,
    required this.reasonCode,
    required this.registryVersion,
    required this.diagnosticCodes,
  });

  factory HardConstraintFieldEvaluation.fromJson(Map<String, dynamic> j) =>
      HardConstraintFieldEvaluation(
        constraintId: j['constraint_id']?.toString() ?? '',
        ownerId: j['owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        fieldId: j['field_id']?.toString() ?? '',
        counterpartValue: j['counterpart_value']?.toString(),
        counterpartValues: [
          for (final e in (j['counterpart_values'] as List?) ?? const [])
            e.toString(),
        ],
        acceptedValues: [
          for (final e in (j['accepted_values'] as List?) ?? const [])
            e.toString(),
        ],
        rejectedValues: [
          for (final e in (j['rejected_values'] as List?) ?? const [])
            e.toString(),
        ],
        enabled: j['enabled'] == true,
        matchMode: j['match_mode']?.toString() ?? '',
        outcome: parseHardConstraintOutcome(j['outcome']?.toString() ?? ''),
        reasonCode: j['reason_code']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'constraint_id': constraintId,
        'owner_id': ownerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'field_id': fieldId,
        'counterpart_value': counterpartValue,
        'counterpart_values': counterpartValues,
        'accepted_values': acceptedValues,
        'rejected_values': rejectedValues,
        'enabled': enabled,
        'match_mode': matchMode,
        'outcome': outcome.wire,
        'reason_code': reasonCode,
        'registry_version': registryVersion,
        'diagnostic_codes': diagnosticCodes,
      });
}

class DirectionalHardConstraintResult {
  final String ownerId;
  final String evaluatedSubjectId;
  final List<HardConstraintFieldEvaluation> evaluations;
  final List<String> passedConstraintIds;
  final List<String> failedConstraintIds;
  final List<String> unknownConstraintIds;
  final List<String> notApplicableConstraintIds;
  final HardConstraintOutcome aggregateOutcome;
  final String deterministicFingerprint;
  final List<String> diagnostics;
  final String configVersion;
  final String registryVersion;

  const DirectionalHardConstraintResult({
    required this.ownerId,
    required this.evaluatedSubjectId,
    required this.evaluations,
    required this.passedConstraintIds,
    required this.failedConstraintIds,
    required this.unknownConstraintIds,
    required this.notApplicableConstraintIds,
    required this.aggregateOutcome,
    required this.deterministicFingerprint,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
  });

  factory DirectionalHardConstraintResult.fromJson(Map<String, dynamic> j) =>
      DirectionalHardConstraintResult(
        ownerId: j['owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        evaluations: [
          for (final e in (j['evaluations'] as List?) ?? const [])
            HardConstraintFieldEvaluation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        passedConstraintIds: [
          for (final e in (j['passed_constraint_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        failedConstraintIds: [
          for (final e in (j['failed_constraint_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        unknownConstraintIds: [
          for (final e in (j['unknown_constraint_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        notApplicableConstraintIds: [
          for (final e
              in (j['not_applicable_constraint_ids'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        aggregateOutcome: parseHardConstraintOutcome(
            j['aggregate_outcome']?.toString() ?? ''),
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'owner_id': ownerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'evaluations': [for (final e in evaluations) e.toJson()],
        'passed_constraint_ids': passedConstraintIds,
        'failed_constraint_ids': failedConstraintIds,
        'unknown_constraint_ids': unknownConstraintIds,
        'not_applicable_constraint_ids': notApplicableConstraintIds,
        'aggregate_outcome': aggregateOutcome.wire,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics,
        'config_version': configVersion,
        'registry_version': registryVersion,
      });
}

class MutualHardConstraintResult {
  final DirectionalHardConstraintResult subjectAToBResult;
  final DirectionalHardConstraintResult subjectBToAResult;
  final HardConstraintOutcome aggregateOutcome;
  final String deterministicFingerprint;
  final List<String> diagnostics;
  final String configVersion;
  final String registryVersion;

  const MutualHardConstraintResult({
    required this.subjectAToBResult,
    required this.subjectBToAResult,
    required this.aggregateOutcome,
    required this.deterministicFingerprint,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
  });

  factory MutualHardConstraintResult.fromJson(Map<String, dynamic> j) =>
      MutualHardConstraintResult(
        subjectAToBResult: DirectionalHardConstraintResult.fromJson(
          Map<String, dynamic>.from(j['subject_a_to_b_result'] as Map),
        ),
        subjectBToAResult: DirectionalHardConstraintResult.fromJson(
          Map<String, dynamic>.from(j['subject_b_to_a_result'] as Map),
        ),
        aggregateOutcome: parseHardConstraintOutcome(
            j['aggregate_outcome']?.toString() ?? ''),
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_a_to_b_result': subjectAToBResult.toJson(),
        'subject_b_to_a_result': subjectBToAResult.toJson(),
        'aggregate_outcome': aggregateOutcome.wire,
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics,
        'config_version': configVersion,
        'registry_version': registryVersion,
      });
}
