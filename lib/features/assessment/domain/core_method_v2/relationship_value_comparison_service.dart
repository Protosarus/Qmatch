import 'dart:convert';
import 'dart:math' as math;

import 'compatibility_pair_input.dart';
import 'core_method_v2_validation.dart';
import 'relationship_value_comparison_config.dart';
import 'relationship_value_comparison_models.dart';
import 'relationship_value_models.dart';
import 'relationship_value_registry.dart';

/// Offline directional relationship-value comparison (P2B-3).
///
/// Does not call structural similarity, partner-preference fit,
/// persona, AI, or final compatibility aggregation.
class RelationshipValueComparisonService {
  const RelationshipValueComparisonService();

  DirectionalRelationshipValueResult evaluateDirectional({
    required CompatibilitySubjectSnapshot preferenceOwner,
    required CompatibilitySubjectSnapshot evaluatedSubject,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
    DateTime? evaluationTimestamp,
  }) {
    _validateConfig(config, registry);

    final ownerResponses = preferenceOwner.relationshipValueProfile.responses;
    final evaluatedResponses =
        evaluatedSubject.relationshipValueProfile.responses;
    final fieldIds = <String>{
      ...ownerResponses.keys,
      ...config.fieldRules.keys,
    }.toList()
      ..sort();

    final exclusions = <RelationshipValueComparisonExclusion>[];
    final comparisons = <RelationshipValueFieldComparison>[];
    var declaredScoreableCount = 0;
    var declaredImportanceMass = 0.0;
    var comparableImportanceMass = 0.0;
    var weightSum = 0.0;
    var weightedFitSum = 0.0;
    var meanQNumerator = 0.0;
    var flexibleCount = 0;

    for (final fieldId in fieldIds) {
      final rule = config.ruleFor(fieldId);
      final owner = ownerResponses[fieldId];
      final evaluated = evaluatedResponses[fieldId];

      if (rule != null &&
          rule.comparisonMode != 'comparison_pending_review' &&
          owner != null &&
          owner.explicitlyProvided &&
          owner.importance != null &&
          owner.importance!.isFinite &&
          owner.importance! > 0) {
        declaredScoreableCount++;
        declaredImportanceMass += owner.importance!;
      }

      final exclusion = _eligibilityExclusion(
        fieldId: fieldId,
        rule: rule,
        owner: owner,
        evaluated: evaluated,
        registry: registry,
        config: config,
      );
      if (exclusion != null) {
        exclusions.add(exclusion);
        continue;
      }

      final c = _baseCompatibility(
        rule: rule!,
        owner: owner!,
        evaluated: evaluated!,
        registry: registry,
      );
      if (c == null) {
        exclusions.add(RelationshipValueComparisonExclusion(
          fieldId: fieldId,
          reasonCode: 'unsupported_comparison_mode',
          explanation: rule.comparisonMode,
        ));
        continue;
      }

      final importance = owner.importance!;
      final flexibility = owner.flexibility!;
      if (flexibility >= 0.7) flexibleCount++;
      final p = c + flexibility * (1 - c);
      const q = 1.0;
      final a = importance * q;
      if (a <= 0) {
        exclusions.add(RelationshipValueComparisonExclusion(
          fieldId: fieldId,
          reasonCode: 'zero_effective_weight',
          explanation: 'effective weight <= 0',
        ));
        continue;
      }

      comparableImportanceMass += importance;
      weightSum += a;
      weightedFitSum += a * p;
      meanQNumerator += importance * q;

      final ownerVals = _valuesOf(owner, rule);
      final evalVals = _valuesOf(evaluated, rule);
      comparisons.add(RelationshipValueFieldComparison(
        fieldId: fieldId,
        comparisonMode: rule.comparisonMode,
        preferenceOwnerId: preferenceOwner.subjectId,
        evaluatedSubjectId: evaluatedSubject.subjectId,
        ownerValue: ownerVals.scalar,
        ownerValues: ownerVals.setValues,
        evaluatedValue: evalVals.scalar,
        evaluatedValues: evalVals.setValues,
        baseCompatibility: c,
        ownerImportance: importance,
        ownerFlexibility: flexibility,
        adjustedDirectionalFit: p,
        evidenceConfidence: q,
        effectiveWeight: a,
        weightedContribution: a * p,
        registryVersion: registry.registryVersion,
        configVersion: config.configVersion,
        diagnosticCodes: const ['value_comparison_available'],
      ));
    }

    comparisons.sort((a, b) => a.fieldId.compareTo(b.fieldId));
    exclusions.sort((a, b) => a.fieldId.compareTo(b.fieldId));

    double? raw;
    double? coverage;
    double? evidenceQ;
    DirectionalRelationshipValueStatus status;
    final diagnostics = <String>[];

    if (comparisons.isEmpty) {
      raw = null;
      coverage = declaredImportanceMass > 0 ? 0.0 : null;
      evidenceQ = null;
      status = DirectionalRelationshipValueStatus.insufficientEvidence;
      diagnostics.add('mutual_value_result_unavailable');
    } else if (comparisons.length < config.minimumComparableValueFields) {
      raw = null;
      coverage = declaredImportanceMass > 0
          ? comparableImportanceMass / declaredImportanceMass
          : null;
      evidenceQ = null;
      status = DirectionalRelationshipValueStatus.insufficientEvidence;
    } else {
      raw = weightedFitSum / weightSum;
      coverage = declaredImportanceMass > 0
          ? comparableImportanceMass / declaredImportanceMass
          : 1.0;
      final meanQ = meanQNumerator / comparableImportanceMass;
      evidenceQ = coverage * meanQ;
      status = exclusions.isEmpty
          ? DirectionalRelationshipValueStatus.complete
          : DirectionalRelationshipValueStatus.partial;
      diagnostics.add('mutual_value_result_available');
    }

    final provisional = DirectionalRelationshipValueResult(
      preferenceOwnerId: preferenceOwner.subjectId,
      evaluatedSubjectId: evaluatedSubject.subjectId,
      rawValueFitScore: raw,
      evidenceConfidence: evidenceQ,
      comparableFieldCount: comparisons.length,
      declaredScoreableFieldCount: declaredScoreableCount,
      explicitlyOpenOrFlexibleFieldCount: flexibleCount,
      comparableFieldIds: [for (final c in comparisons) c.fieldId],
      excludedFields: exclusions,
      fieldComparisons: comparisons,
      declaredImportanceMass: declaredImportanceMass,
      comparableImportanceMass: comparableImportanceMass,
      effectiveWeightSum: weightSum,
      evaluationCoverage: coverage,
      status: status,
      deterministicFingerprint: '',
      diagnostics: diagnostics..sort(),
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
    );

    return DirectionalRelationshipValueResult(
      preferenceOwnerId: provisional.preferenceOwnerId,
      evaluatedSubjectId: provisional.evaluatedSubjectId,
      rawValueFitScore: provisional.rawValueFitScore,
      evidenceConfidence: provisional.evidenceConfidence,
      comparableFieldCount: provisional.comparableFieldCount,
      declaredScoreableFieldCount: provisional.declaredScoreableFieldCount,
      explicitlyOpenOrFlexibleFieldCount:
          provisional.explicitlyOpenOrFlexibleFieldCount,
      comparableFieldIds: provisional.comparableFieldIds,
      excludedFields: provisional.excludedFields,
      fieldComparisons: provisional.fieldComparisons,
      declaredImportanceMass: provisional.declaredImportanceMass,
      comparableImportanceMass: provisional.comparableImportanceMass,
      effectiveWeightSum: provisional.effectiveWeightSum,
      evaluationCoverage: provisional.evaluationCoverage,
      status: provisional.status,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
    );
  }

  MutualRelationshipValueResult evaluateMutual({
    required CompatibilitySubjectSnapshot subjectA,
    required CompatibilitySubjectSnapshot subjectB,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
    DateTime? evaluationTimestamp,
  }) {
    final aToB = evaluateDirectional(
      preferenceOwner: subjectA,
      evaluatedSubject: subjectB,
      registry: registry,
      config: config,
      evaluationTimestamp: evaluationTimestamp,
    );
    final bToA = evaluateDirectional(
      preferenceOwner: subjectB,
      evaluatedSubject: subjectA,
      registry: registry,
      config: config,
      evaluationTimestamp: evaluationTimestamp,
    );

    double? mutual;
    double? mutualQ;
    double? asymmetry;
    final diagnostics = <String>[];
    MutualRelationshipValueStatus status;

    if (aToB.rawValueFitScore != null && bToA.rawValueFitScore != null) {
      mutual = math.sqrt(aToB.rawValueFitScore! * bToA.rawValueFitScore!);
      mutualQ = math.sqrt(aToB.evidenceConfidence! * bToA.evidenceConfidence!);
      asymmetry = (aToB.rawValueFitScore! - bToA.rawValueFitScore!).abs();
      diagnostics.add('mutual_value_result_available');
      if (asymmetry > 1e-12) diagnostics.add('directional_value_asymmetry');
      status = (aToB.status == DirectionalRelationshipValueStatus.complete &&
              bToA.status == DirectionalRelationshipValueStatus.complete)
          ? MutualRelationshipValueStatus.complete
          : MutualRelationshipValueStatus.partial;
    } else {
      mutual = null;
      mutualQ = null;
      asymmetry = null;
      diagnostics.add('mutual_value_result_unavailable');
      status = MutualRelationshipValueStatus.insufficientEvidence;
    }

    final provisional = MutualRelationshipValueResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      mutualRawValueFitScore: mutual,
      mutualEvidenceConfidence: mutualQ,
      directionalAsymmetry: asymmetry,
      status: status,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      deterministicFingerprint: '',
      diagnostics: diagnostics..sort(),
    );
    return MutualRelationshipValueResult(
      subjectAToBResult: provisional.subjectAToBResult,
      subjectBToAResult: provisional.subjectBToAResult,
      mutualRawValueFitScore: provisional.mutualRawValueFitScore,
      mutualEvidenceConfidence: provisional.mutualEvidenceConfidence,
      directionalAsymmetry: provisional.directionalAsymmetry,
      status: provisional.status,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      diagnostics: provisional.diagnostics,
    );
  }

  void _validateConfig(
    RelationshipValueComparisonConfig config,
    RelationshipValueRegistry registry,
  ) {
    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_version') {
      cmRequire(
        config.registryVersion == registry.registryVersion,
        'registry_version',
        'registry_version_mismatch',
        '${config.registryVersion} vs ${registry.registryVersion}',
      );
    }
    config.validateAgainstRegistry(registry);
  }

  RelationshipValueComparisonExclusion? _eligibilityExclusion({
    required String fieldId,
    required RelationshipValueFieldRule? rule,
    required RelationshipValueResponse? owner,
    required RelationshipValueResponse? evaluated,
    required RelationshipValueRegistry registry,
    required RelationshipValueComparisonConfig config,
  }) {
    if (!registry.fieldsById.containsKey(fieldId)) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'unsupported_value_type',
        explanation: 'field not in registry',
      );
    }
    if (rule == null) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'comparison_rule_missing',
        explanation: 'no configured rule',
      );
    }
    if (rule.comparisonMode == 'comparison_pending_review') {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'comparison_pending_review',
        explanation: rule.exclusionReason ?? 'pending review',
      );
    }
    if (!config.supportedComparisonModes.contains(rule.comparisonMode)) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'unsupported_comparison_mode',
        explanation: rule.comparisonMode,
      );
    }
    if (owner == null) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'value_missing_subject_a',
        explanation: 'owner missing response',
      );
    }
    if (!owner.explicitlyProvided) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'value_not_explicit_subject_a',
        explanation: 'owner not explicit',
      );
    }
    if (evaluated == null) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'value_missing_subject_b',
        explanation: 'evaluated missing response',
      );
    }
    if (!evaluated.explicitlyProvided) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'value_not_explicit_subject_b',
        explanation: 'evaluated not explicit',
      );
    }

    final def = registry.require(fieldId);
    final ownerVals = _valuesOf(owner, rule);
    final evalVals = _valuesOf(evaluated, rule);
    final ownerInvalid = _invalidValues(ownerVals, def, rule);
    if (ownerInvalid != null) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: ownerInvalid,
        explanation: 'owner value invalid',
      );
    }
    final evalInvalid = _invalidValues(evalVals, def, rule);
    if (evalInvalid != null) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: evalInvalid == 'value_invalid_subject_a'
            ? 'value_invalid_subject_b'
            : evalInvalid,
        explanation: 'evaluated value invalid',
      );
    }

    if (owner.importance == null ||
        !owner.importance!.isFinite ||
        owner.importance! < config.importanceMin ||
        owner.importance! > config.importanceMax) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'invalid_importance',
        explanation: '${owner.importance}',
      );
    }
    if (owner.importance! <= 0) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'zero_importance',
        explanation: 'importance must be > 0',
      );
    }
    if (owner.flexibility == null ||
        !owner.flexibility!.isFinite ||
        owner.flexibility! < config.flexibilityMin ||
        owner.flexibility! > config.flexibilityMax) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'invalid_flexibility',
        explanation: '${owner.flexibility}',
      );
    }

    if (!owner.comparisonPermission || !evaluated.comparisonPermission) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'comparison_permission_denied',
        explanation: 'comparison_permission false',
      );
    }
    final allow = config.visibilityPoliciesAllowingComparison;
    if (!allow.contains(owner.visibilityPolicy) ||
        !allow.contains(evaluated.visibilityPolicy)) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'visibility_policy_blocked',
        explanation: '${owner.visibilityPolicy}|${evaluated.visibilityPolicy}',
      );
    }

    if (owner.registryVersion != registry.registryVersion ||
        evaluated.registryVersion != registry.registryVersion) {
      return RelationshipValueComparisonExclusion(
        fieldId: fieldId,
        reasonCode: 'registry_version_mismatch',
        explanation: 'response registry mismatch',
      );
    }

    return null;
  }

  String? _invalidValues(
    _ResolvedValues vals,
    RelationshipValueFieldDefinition def,
    RelationshipValueFieldRule rule,
  ) {
    if (rule.comparisonMode == 'set_overlap') {
      if (vals.setValues.isEmpty) {
        return 'value_invalid_subject_a';
      }
      for (final v in vals.setValues) {
        if (!def.allowedValues.contains(v)) return 'value_not_allowed';
      }
      return null;
    }
    final v = vals.scalar;
    if (v == null || v.isEmpty) return 'value_invalid_subject_a';
    if (!def.allowedValues.contains(v)) return 'value_not_allowed';
    return null;
  }

  double? _baseCompatibility({
    required RelationshipValueFieldRule rule,
    required RelationshipValueResponse owner,
    required RelationshipValueResponse evaluated,
    required RelationshipValueRegistry registry,
  }) {
    final ownerVals = _valuesOf(owner, rule);
    final evalVals = _valuesOf(evaluated, rule);
    switch (rule.comparisonMode) {
      case 'exact_match':
        return ownerVals.scalar == evalVals.scalar ? 1.0 : 0.0;
      case 'categorical_compatibility_matrix':
        final cells = rule.matrixCells!;
        return cells[ownerVals.scalar!]![evalVals.scalar!]!;
      case 'ordered_distance':
        final ordered = rule.orderedValues!;
        final i = ordered.indexOf(ownerVals.scalar!);
        final j = ordered.indexOf(evalVals.scalar!);
        final d = (i - j).abs() / math.max(1, ordered.length - 1);
        return 1.0 - d;
      case 'set_overlap':
        final a = ownerVals.setValues.toSet();
        final b = evalVals.setValues.toSet();
        final inter = a.intersection(b).length;
        final union = a.union(b).length;
        if (union == 0) return null;
        return inter / union;
      default:
        return null;
    }
  }

  _ResolvedValues _valuesOf(
    RelationshipValueResponse r,
    RelationshipValueFieldRule rule,
  ) {
    if (rule.comparisonMode == 'set_overlap') {
      final set = [...r.selectedValues]..sort();
      return _ResolvedValues(scalar: null, setValues: set);
    }
    final scalar = r.selectedValue ??
        (r.selectedValues.length == 1 ? r.selectedValues.first : null);
    return _ResolvedValues(
      scalar: scalar,
      setValues: scalar == null ? const [] : [scalar],
    );
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

class _ResolvedValues {
  final String? scalar;
  final List<String> setValues;
  const _ResolvedValues({required this.scalar, required this.setValues});
}
