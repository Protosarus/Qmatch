import 'dart:convert';

import 'compatibility_pair_input.dart';
import 'core_method_v2_validation.dart';
import 'hard_constraint.dart';
import 'hard_constraint_evaluation_models.dart';
import 'relationship_value_comparison_config.dart';
import 'relationship_value_models.dart';
import 'relationship_value_registry.dart';

/// Offline hard-constraint evaluation (P2B-3). Categorical only — no numeric score.
class HardConstraintEvaluationService {
  const HardConstraintEvaluationService();

  DirectionalHardConstraintResult evaluateDirectional({
    required CompatibilitySubjectSnapshot preferenceOwner,
    required CompatibilitySubjectSnapshot evaluatedSubject,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
  }) {
    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_version') {
      cmRequire(
        config.registryVersion == registry.registryVersion,
        'registry_version',
        'registry_version_mismatch',
        '${config.registryVersion} vs ${registry.registryVersion}',
      );
    }

    final constraints = [...preferenceOwner.hardConstraints]
      ..sort((a, b) => a.constraintId.compareTo(b.constraintId));
    final evaluations = <HardConstraintFieldEvaluation>[];

    for (final c in constraints) {
      evaluations.add(_evaluateOne(
        constraint: c,
        owner: preferenceOwner,
        evaluated: evaluatedSubject,
        registry: registry,
        config: config,
      ));
    }

    final passed = [
      for (final e in evaluations)
        if (e.outcome == HardConstraintOutcome.passed) e.constraintId
    ]..sort();
    final failed = [
      for (final e in evaluations)
        if (e.outcome == HardConstraintOutcome.failed) e.constraintId
    ]..sort();
    final unknown = [
      for (final e in evaluations)
        if (e.outcome == HardConstraintOutcome.unknown) e.constraintId
    ]..sort();
    final na = [
      for (final e in evaluations)
        if (e.outcome == HardConstraintOutcome.notApplicable) e.constraintId
    ]..sort();

    final aggregate = _aggregate(failed, unknown, passed);
    final diagnostics = <String>[
      for (final e in evaluations) e.reasonCode,
      'hard_constraint_${aggregate.wire}',
    ]..sort();

    final provisional = DirectionalHardConstraintResult(
      ownerId: preferenceOwner.subjectId,
      evaluatedSubjectId: evaluatedSubject.subjectId,
      evaluations: evaluations,
      passedConstraintIds: passed,
      failedConstraintIds: failed,
      unknownConstraintIds: unknown,
      notApplicableConstraintIds: na,
      aggregateOutcome: aggregate,
      deterministicFingerprint: '',
      diagnostics: diagnostics,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
    );
    return DirectionalHardConstraintResult(
      ownerId: provisional.ownerId,
      evaluatedSubjectId: provisional.evaluatedSubjectId,
      evaluations: provisional.evaluations,
      passedConstraintIds: provisional.passedConstraintIds,
      failedConstraintIds: provisional.failedConstraintIds,
      unknownConstraintIds: provisional.unknownConstraintIds,
      notApplicableConstraintIds: provisional.notApplicableConstraintIds,
      aggregateOutcome: provisional.aggregateOutcome,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
    );
  }

  MutualHardConstraintResult evaluateMutual({
    required CompatibilitySubjectSnapshot subjectA,
    required CompatibilitySubjectSnapshot subjectB,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
  }) {
    final aToB = evaluateDirectional(
      preferenceOwner: subjectA,
      evaluatedSubject: subjectB,
      registry: registry,
      config: config,
    );
    final bToA = evaluateDirectional(
      preferenceOwner: subjectB,
      evaluatedSubject: subjectA,
      registry: registry,
      config: config,
    );
    final aggregate = _mutualAggregate(
      aToB.aggregateOutcome,
      bToA.aggregateOutcome,
    );
    final provisional = MutualHardConstraintResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      aggregateOutcome: aggregate,
      deterministicFingerprint: '',
      diagnostics: [
        'hard_constraint_${aggregate.wire}',
        ...aToB.diagnostics,
        ...bToA.diagnostics,
      ]..sort(),
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
    );
    return MutualHardConstraintResult(
      subjectAToBResult: provisional.subjectAToBResult,
      subjectBToAResult: provisional.subjectBToAResult,
      aggregateOutcome: provisional.aggregateOutcome,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
    );
  }

  HardConstraintFieldEvaluation _evaluateOne({
    required HardConstraint constraint,
    required CompatibilitySubjectSnapshot owner,
    required CompatibilitySubjectSnapshot evaluated,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
  }) {
    if (!constraint.explicitlyEnabled) {
      return HardConstraintFieldEvaluation(
        constraintId: constraint.constraintId,
        ownerId: owner.subjectId,
        evaluatedSubjectId: evaluated.subjectId,
        fieldId: constraint.fieldId,
        counterpartValue: null,
        counterpartValues: const [],
        acceptedValues: constraint.acceptedValues,
        rejectedValues: constraint.rejectedValues,
        enabled: false,
        matchMode: constraint.matchMode,
        outcome: HardConstraintOutcome.notApplicable,
        reasonCode: 'hard_constraint_not_applicable',
        registryVersion: registry.registryVersion,
        diagnosticCodes: const ['hard_constraint_not_applicable'],
      );
    }

    final def = registry.fieldsById[constraint.fieldId];
    if (def == null || !def.supportsHardConstraint) {
      return HardConstraintFieldEvaluation(
        constraintId: constraint.constraintId,
        ownerId: owner.subjectId,
        evaluatedSubjectId: evaluated.subjectId,
        fieldId: constraint.fieldId,
        counterpartValue: null,
        counterpartValues: const [],
        acceptedValues: constraint.acceptedValues,
        rejectedValues: constraint.rejectedValues,
        enabled: true,
        matchMode: constraint.matchMode,
        outcome: HardConstraintOutcome.notApplicable,
        reasonCode: 'unsupported_hard_constraint_field',
        registryVersion: registry.registryVersion,
        diagnosticCodes: const ['hard_constraint_not_applicable'],
      );
    }

    final response =
        evaluated.relationshipValueProfile.responses[constraint.fieldId];
    if (response == null || !response.explicitlyProvided) {
      return _unknown(
        constraint,
        owner,
        evaluated,
        registry,
        'counterpart_value_missing',
      );
    }
    if (!response.comparisonPermission) {
      return _unknown(
        constraint,
        owner,
        evaluated,
        registry,
        'comparison_permission_denied',
      );
    }
    if (!config.visibilityPoliciesAllowingComparison
        .contains(response.visibilityPolicy)) {
      return _unknown(
        constraint,
        owner,
        evaluated,
        registry,
        'visibility_policy_blocked',
      );
    }

    final values = _counterpartValues(response);
    if (values.isEmpty) {
      return _unknown(
        constraint,
        owner,
        evaluated,
        registry,
        'counterpart_value_invalid',
      );
    }
    for (final v in values) {
      if (!def.allowedValues.contains(v)) {
        return _unknown(
          constraint,
          owner,
          evaluated,
          registry,
          'counterpart_value_invalid',
        );
      }
    }

    final mode = constraint.matchMode.isEmpty
        ? config.defaultHardConstraintMatchMode
        : constraint.matchMode;
    final accepted = constraint.acceptedValues.toSet();
    final rejected = constraint.rejectedValues.toSet();
    final set = values.toSet();

    if (set.intersection(rejected).isNotEmpty) {
      return HardConstraintFieldEvaluation(
        constraintId: constraint.constraintId,
        ownerId: owner.subjectId,
        evaluatedSubjectId: evaluated.subjectId,
        fieldId: constraint.fieldId,
        counterpartValue: values.length == 1 ? values.first : null,
        counterpartValues: values,
        acceptedValues: constraint.acceptedValues,
        rejectedValues: constraint.rejectedValues,
        enabled: true,
        matchMode: mode,
        outcome: HardConstraintOutcome.failed,
        reasonCode: 'hard_constraint_failed',
        registryVersion: registry.registryVersion,
        diagnosticCodes: const ['hard_constraint_failed'],
      );
    }

    var pass = true;
    switch (mode) {
      case 'any_allowed':
        if (accepted.isNotEmpty) {
          pass = set.intersection(accepted).isNotEmpty;
        }
        break;
      case 'all_required':
        if (accepted.isNotEmpty) {
          pass = accepted.every(set.contains);
        }
        break;
      case 'no_rejected_overlap':
        pass = true; // rejected overlap already handled
        break;
      default:
        return _unknown(
          constraint,
          owner,
          evaluated,
          registry,
          'unsupported_match_mode',
        );
    }

    return HardConstraintFieldEvaluation(
      constraintId: constraint.constraintId,
      ownerId: owner.subjectId,
      evaluatedSubjectId: evaluated.subjectId,
      fieldId: constraint.fieldId,
      counterpartValue: values.length == 1 ? values.first : null,
      counterpartValues: values,
      acceptedValues: constraint.acceptedValues,
      rejectedValues: constraint.rejectedValues,
      enabled: true,
      matchMode: mode,
      outcome:
          pass ? HardConstraintOutcome.passed : HardConstraintOutcome.failed,
      reasonCode: pass ? 'hard_constraint_passed' : 'hard_constraint_failed',
      registryVersion: registry.registryVersion,
      diagnosticCodes: [
        pass ? 'hard_constraint_passed' : 'hard_constraint_failed',
      ],
    );
  }

  HardConstraintFieldEvaluation _unknown(
    HardConstraint constraint,
    CompatibilitySubjectSnapshot owner,
    CompatibilitySubjectSnapshot evaluated,
    RelationshipValueRegistry registry,
    String reason,
  ) =>
      HardConstraintFieldEvaluation(
        constraintId: constraint.constraintId,
        ownerId: owner.subjectId,
        evaluatedSubjectId: evaluated.subjectId,
        fieldId: constraint.fieldId,
        counterpartValue: null,
        counterpartValues: const [],
        acceptedValues: constraint.acceptedValues,
        rejectedValues: constraint.rejectedValues,
        enabled: true,
        matchMode: constraint.matchMode,
        outcome: HardConstraintOutcome.unknown,
        reasonCode: reason,
        registryVersion: registry.registryVersion,
        diagnosticCodes: const ['hard_constraint_unknown'],
      );

  List<String> _counterpartValues(RelationshipValueResponse r) {
    if (r.selectedValues.isNotEmpty) {
      return [...r.selectedValues]..sort();
    }
    if (r.selectedValue != null && r.selectedValue!.isNotEmpty) {
      return [r.selectedValue!];
    }
    return const [];
  }

  HardConstraintOutcome _aggregate(
    List<String> failed,
    List<String> unknown,
    List<String> passed,
  ) {
    if (failed.isNotEmpty) return HardConstraintOutcome.failed;
    if (unknown.isNotEmpty) return HardConstraintOutcome.unknown;
    if (passed.isNotEmpty) return HardConstraintOutcome.passed;
    return HardConstraintOutcome.notApplicable;
  }

  HardConstraintOutcome _mutualAggregate(
    HardConstraintOutcome a,
    HardConstraintOutcome b,
  ) {
    if (a == HardConstraintOutcome.failed ||
        b == HardConstraintOutcome.failed) {
      return HardConstraintOutcome.failed;
    }
    if (a == HardConstraintOutcome.unknown ||
        b == HardConstraintOutcome.unknown) {
      return HardConstraintOutcome.unknown;
    }
    if (a == HardConstraintOutcome.passed ||
        b == HardConstraintOutcome.passed) {
      return HardConstraintOutcome.passed;
    }
    return HardConstraintOutcome.notApplicable;
  }

  String _fingerprint(Map<String, dynamic> json) {
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
