import 'dart:convert';

import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';
import 'hard_constraint_evaluation_models.dart';
import 'relationship_value_comparison_models.dart';
import 'soft_conflict_evaluation_models.dart';

/// Non-final P2B-3 aggregate container. No overall compatibility score.
class RelationshipCompatibilityLayerResult {
  final MutualRelationshipValueResult mutualValueResult;
  final MutualHardConstraintResult mutualHardConstraintResult;
  final SoftConflictEvaluationResult softConflictResult;
  final double? evaluationCoverageAToB;
  final double? evaluationCoverageBToA;
  final List<String> missingFields;
  final List<String> diagnostics;
  final String configVersion;
  final String registryVersion;
  final String deterministicFingerprint;
  final bool futureFinalResultShouldBeBlocked;

  RelationshipCompatibilityLayerResult({
    required this.mutualValueResult,
    required this.mutualHardConstraintResult,
    required this.softConflictResult,
    required this.evaluationCoverageAToB,
    required this.evaluationCoverageBToA,
    required this.missingFields,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
    required this.deterministicFingerprint,
    required this.futureFinalResultShouldBeBlocked,
  });

  factory RelationshipCompatibilityLayerResult.assemble({
    required MutualRelationshipValueResult mutualValueResult,
    required MutualHardConstraintResult mutualHardConstraintResult,
    required SoftConflictEvaluationResult softConflictResult,
  }) {
    final missing = <String>{
      for (final e in mutualValueResult.subjectAToBResult.excludedFields)
        if (e.reasonCode.contains('missing')) e.fieldId,
      for (final e in mutualValueResult.subjectBToAResult.excludedFields)
        if (e.reasonCode.contains('missing')) e.fieldId,
    }.toList()
      ..sort();
    final blocked = mutualHardConstraintResult.aggregateOutcome ==
        HardConstraintOutcome.failed;
    final provisional = RelationshipCompatibilityLayerResult(
      mutualValueResult: mutualValueResult,
      mutualHardConstraintResult: mutualHardConstraintResult,
      softConflictResult: softConflictResult,
      evaluationCoverageAToB:
          mutualValueResult.subjectAToBResult.evaluationCoverage,
      evaluationCoverageBToA:
          mutualValueResult.subjectBToAResult.evaluationCoverage,
      missingFields: missing,
      diagnostics: [
        ...mutualValueResult.diagnostics,
        ...mutualHardConstraintResult.diagnostics,
        ...softConflictResult.diagnostics,
        if (blocked) 'future_final_result_should_be_blocked',
      ]..sort(),
      configVersion: mutualValueResult.configVersion,
      registryVersion: mutualValueResult.registryVersion,
      deterministicFingerprint: '',
      futureFinalResultShouldBeBlocked: blocked,
    );
    return RelationshipCompatibilityLayerResult(
      mutualValueResult: provisional.mutualValueResult,
      mutualHardConstraintResult: provisional.mutualHardConstraintResult,
      softConflictResult: provisional.softConflictResult,
      evaluationCoverageAToB: provisional.evaluationCoverageAToB,
      evaluationCoverageBToA: provisional.evaluationCoverageBToA,
      missingFields: provisional.missingFields,
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      futureFinalResultShouldBeBlocked:
          provisional.futureFinalResultShouldBeBlocked,
    );
  }

  factory RelationshipCompatibilityLayerResult.fromJson(
          Map<String, dynamic> j) =>
      RelationshipCompatibilityLayerResult(
        mutualValueResult: MutualRelationshipValueResult.fromJson(
          Map<String, dynamic>.from(j['mutual_value_result'] as Map),
        ),
        mutualHardConstraintResult: MutualHardConstraintResult.fromJson(
          Map<String, dynamic>.from(j['mutual_hard_constraint_result'] as Map),
        ),
        softConflictResult: SoftConflictEvaluationResult.fromJson(
          Map<String, dynamic>.from(j['soft_conflict_result'] as Map),
        ),
        evaluationCoverageAToB:
            (j['evaluation_coverage_a_to_b'] as num?)?.toDouble(),
        evaluationCoverageBToA:
            (j['evaluation_coverage_b_to_a'] as num?)?.toDouble(),
        missingFields: [
          for (final e in (j['missing_fields'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        futureFinalResultShouldBeBlocked:
            j['future_final_result_should_be_blocked'] == true,
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'mutual_value_result': mutualValueResult.toJson(),
        'mutual_hard_constraint_result': mutualHardConstraintResult.toJson(),
        'soft_conflict_result': softConflictResult.toJson(),
        'evaluation_coverage_a_to_b': evaluationCoverageAToB,
        'evaluation_coverage_b_to_a': evaluationCoverageBToA,
        'missing_fields': missingFields,
        'diagnostics': diagnostics,
        'config_version': configVersion,
        'registry_version': registryVersion,
        'deterministic_fingerprint': deterministicFingerprint,
        'future_final_result_should_be_blocked':
            futureFinalResultShouldBeBlocked,
      });

  static String _fingerprint(Map<String, dynamic> json) {
    final encoded = jsonEncode(cmSortedMap({
      ...json,
      'deterministic_fingerprint': null,
    }));
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
