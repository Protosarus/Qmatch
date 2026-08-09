import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'aggregation_v1_helpers.dart';

class ExplanationV1Helpers {
  static const configPath =
      'assets/data/core_method_v2/structured_explanation_config_v1.json';
  static const configSchemaPath =
      'assets/schemas/core_method_v2/structured_explanation_config_v1.schema.json';
  static const codeRegistryPath =
      'assets/data/core_method_v2/structured_explanation_code_registry_v1.json';
  static const codeRegistrySchemaPath =
      'assets/schemas/core_method_v2/structured_explanation_code_registry_v1.schema.json';

  static StructuredExplanationConfig loadConfig() =>
      StructuredExplanationConfig.loadFile(configPath);

  static StructuredExplanationCodeRegistry loadCodeRegistry() =>
      StructuredExplanationCodeRegistry.loadFile(codeRegistryPath);

  static CanonicalDimensionRegistry loadDims() =>
      CanonicalDimensionRegistry.loadFile(AggregationV1Helpers.registryPath);

  static RelationshipValueRegistry loadValues() =>
      RelationshipValueRegistry.loadFile(
        'assets/data/core_method_v2/relationship_value_registry_v1.json',
      );

  static CoreMethodV2EvaluationResult evaluationFromOverall(
    CoreMethodOverallScoreResult overall, {
    DateTime? ts,
  }) {
    return CoreMethodV2EvaluationResult(
      structuralProfileResultJson: null,
      mutualPreferenceResultJson: null,
      relationshipCompatibilityLayerResultJson: null,
      overallScoreResult: overall,
      missingComponents: overall.diagnostics.missingComponentIds,
      softConflictSummary: overall.diagnostics.softConflictSummary,
      asymmetrySummary: overall.diagnostics.asymmetrySummary,
      aggregationConfigVersion: overall.configVersion,
      registryVersion: overall.registryVersion,
      evaluationTimestamp: ts ?? overall.evaluationTimestamp,
      deterministicFingerprint: overall.deterministicFingerprint,
    );
  }

  static CoreMethodV2EvaluationResult evalAllEqual(
    double score,
    double confidence, {
    HardConstraintOutcome hard = HardConstraintOutcome.passed,
    Set<String> exclude = const {},
  }) {
    final overall = AggregationV1Helpers.aggregate(
      AggregationV1Helpers.allEqual(score, confidence, exclude: exclude),
      hard: hard,
    );
    return evaluationFromOverall(overall);
  }

  static StructuralDimensionComparison dimCompare({
    required String id,
    required AssessmentModuleId module,
    required double absDiff,
    double pairQ = 1.0,
    double baseWeight = 1.0,
    double a = 0.5,
    double b = 0.5,
  }) {
    final eff = baseWeight * pairQ;
    return StructuralDimensionComparison(
      dimensionId: id,
      module: module,
      subjectAScore: a,
      subjectBScore: b,
      absoluteDifference: absDiff,
      subjectAConfidence: pairQ,
      subjectBConfidence: pairQ,
      pairConfidence: pairQ,
      baseWeight: baseWeight,
      effectiveWeight: eff,
      squaredDifference: absDiff * absDiff,
      weightedSquaredContribution: eff * absDiff * absDiff,
      registryVersion: 'canonical_dimension_registry_v1',
      scoringContractVersions: const ['v1'],
    );
  }

  static StructuralModuleSimilarityResult moduleResult({
    required AssessmentModuleId module,
    required List<StructuralDimensionComparison> comparisons,
    List<StructuralSimilarityExclusion> excluded = const [],
    StructuralModuleStatus status = StructuralModuleStatus.complete,
    double coverage = 1.0,
    double? similarity = 0.7,
  }) {
    final sumW = comparisons.fold<double>(0, (a, c) => a + c.effectiveWeight);
    return StructuralModuleSimilarityResult(
      module: module,
      similarityScore: similarity,
      distanceSquared: 0.1,
      distance: 0.316,
      comparableDimensionCount: comparisons.length,
      eligibleDimensionCount: comparisons.length + excluded.length,
      totalActiveModuleDimensionCount: comparisons.length + excluded.length,
      comparableDimensionIds: [
        for (final c in comparisons) c.dimensionId,
      ]..sort(),
      excludedDimensions: excluded,
      dimensionComparisons: comparisons,
      unweightedCoverage: coverage,
      weightedCoverage: coverage,
      meanPairConfidence: 1.0,
      evidenceConfidence: 1.0,
      effectiveWeightSum: sumW,
      scaleParameter: 1.0,
      status: status,
      configVersion: 'structural_similarity_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
      diagnostics: StructuralSimilarityDiagnostics.empty(),
    );
  }

  static StructuralProfileSimilarityResult structuralProfile({
    StructuralModuleSimilarityResult? iq,
    StructuralModuleSimilarityResult? eq,
    StructuralModuleSimilarityResult? frequency,
  }) {
    final evaluated = <String>[
      if (iq != null) 'iq',
      if (eq != null) 'eq',
      if (frequency != null) 'frequency',
    ];
    return StructuralProfileSimilarityResult(
      iq: iq,
      eq: eq,
      frequency: frequency,
      evaluatedModules: evaluated,
      missingModules: [
        for (final m in ['iq', 'eq', 'frequency'])
          if (!evaluated.contains(m)) m,
      ],
      configVersion: 'structural_similarity_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
      evaluationTimestamp: DateTime.utc(2026, 7, 25),
      deterministicFingerprint: 'struct_fp',
      overallStatus: StructuralProfileStatus.complete,
    );
  }

  static PreferenceDimensionFit prefFit({
    required String id,
    required AssessmentModuleId module,
    required double fit,
    double importance = 1.0,
    double confidence = 1.0,
    String directionOwner = 'A',
    String evaluated = 'B',
  }) {
    final eff = importance * confidence;
    return PreferenceDimensionFit(
      dimensionId: id,
      module: module,
      preferenceMode: PreferenceMode.range,
      preferenceOwnerId: directionOwner,
      evaluatedSubjectId: evaluated,
      evaluatedScore: 0.5,
      selfScore: null,
      preferredMin: 0.4,
      preferredMax: 0.6,
      distanceToTarget: 1 - fit,
      importance: importance,
      flexibility: 0.2,
      flexibilityScale: 1.0,
      evidenceConfidence: confidence,
      rawDimensionFit: fit,
      effectiveWeight: eff,
      weightedContribution: eff * fit,
      registryVersion: 'canonical_dimension_registry_v1',
      scoringContractVersions: const ['v1'],
      diagnosticCodes: const [],
    );
  }

  static DirectionalPreferenceFitResult directionalPref({
    required String owner,
    required String evaluated,
    required List<PreferenceDimensionFit> fits,
    List<DirectionalPreferenceFitExclusion> excluded = const [],
  }) {
    final sumW = fits.fold<double>(0, (a, f) => a + f.effectiveWeight);
    final raw = sumW > 0
        ? fits.fold<double>(0, (a, f) => a + f.weightedContribution) / sumW
        : null;
    return DirectionalPreferenceFitResult(
      preferenceOwnerId: owner,
      evaluatedSubjectId: evaluated,
      rawFitScore: raw,
      evidenceConfidence: 1.0,
      declaredScoreablePreferenceCount: fits.length,
      comparablePreferenceCount: fits.length,
      explicitlyOpenPreferenceCount:
          excluded.where((e) => e.reasonCode.contains('open')).length,
      unavailablePreferenceCount:
          excluded.where((e) => !e.reasonCode.contains('open')).length,
      comparablePreferenceIds: [for (final f in fits) f.dimensionId]..sort(),
      openPreferenceIds: [
        for (final e in excluded)
          if (e.reasonCode.contains('open')) e.dimensionId,
      ]..sort(),
      excludedPreferences: excluded,
      dimensionFits: fits,
      declaredImportanceMass: sumW,
      comparableImportanceMass: sumW,
      effectiveWeightSum: sumW,
      evaluationCoverage: 1.0,
      profileDeclarationBreadth: 1.0,
      status: DirectionalPreferenceFitStatus.complete,
      configVersion: 'directional_preference_fit_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
      deterministicFingerprint: 'pref_dir_fp',
      diagnostics: DirectionalPreferenceFitDiagnostics.empty(),
    );
  }

  static MutualPreferenceFitResult mutualPref({
    required DirectionalPreferenceFitResult aToB,
    required DirectionalPreferenceFitResult bToA,
    double? asymmetry,
  }) {
    final raw = ((aToB.rawFitScore ?? 0) + (bToA.rawFitScore ?? 0)) / 2;
    return MutualPreferenceFitResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      mutualRawFitScore: raw,
      mutualEvidenceConfidence: 1.0,
      directionalAsymmetry: asymmetry ??
          ((aToB.rawFitScore ?? 0) - (bToA.rawFitScore ?? 0)).abs(),
      status: MutualPreferenceFitStatus.complete,
      configVersion: 'directional_preference_fit_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
      deterministicFingerprint: 'pref_mutual_fp',
      diagnostics: DirectionalPreferenceFitDiagnostics.empty(),
    );
  }

  static RelationshipValueFieldComparison valueField({
    required String fieldId,
    required double fit,
    double importance = 1.0,
    double confidence = 1.0,
    String owner = 'A',
    String evaluated = 'B',
  }) {
    final eff = importance * confidence;
    return RelationshipValueFieldComparison(
      fieldId: fieldId,
      comparisonMode: 'exact',
      preferenceOwnerId: owner,
      evaluatedSubjectId: evaluated,
      ownerValue: 'x',
      ownerValues: const ['x'],
      evaluatedValue: 'y',
      evaluatedValues: const ['y'],
      baseCompatibility: fit,
      ownerImportance: importance,
      ownerFlexibility: 0.2,
      adjustedDirectionalFit: fit,
      evidenceConfidence: confidence,
      effectiveWeight: eff,
      weightedContribution: eff * fit,
      registryVersion: 'relationship_value_registry_v1',
      configVersion: 'relationship_value_comparison_config_v1',
      diagnosticCodes: const [],
    );
  }

  static DirectionalRelationshipValueResult directionalValue({
    required String owner,
    required String evaluated,
    required List<RelationshipValueFieldComparison> fields,
    List<RelationshipValueComparisonExclusion> excluded = const [],
  }) {
    final sumW = fields.fold<double>(0, (a, f) => a + f.effectiveWeight);
    final raw = sumW > 0
        ? fields.fold<double>(0, (a, f) => a + f.weightedContribution) / sumW
        : null;
    return DirectionalRelationshipValueResult(
      preferenceOwnerId: owner,
      evaluatedSubjectId: evaluated,
      rawValueFitScore: raw,
      evidenceConfidence: 1.0,
      comparableFieldCount: fields.length,
      declaredScoreableFieldCount: fields.length,
      explicitlyOpenOrFlexibleFieldCount: 0,
      comparableFieldIds: [for (final f in fields) f.fieldId]..sort(),
      excludedFields: excluded,
      fieldComparisons: fields,
      declaredImportanceMass: sumW,
      comparableImportanceMass: sumW,
      effectiveWeightSum: sumW,
      evaluationCoverage: 1.0,
      status: DirectionalRelationshipValueStatus.complete,
      deterministicFingerprint: 'val_dir_fp',
      diagnostics: const [],
      configVersion: 'relationship_value_comparison_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
    );
  }

  static MutualRelationshipValueResult mutualValue({
    required DirectionalRelationshipValueResult aToB,
    required DirectionalRelationshipValueResult bToA,
    double? asymmetry,
  }) {
    final raw =
        ((aToB.rawValueFitScore ?? 0) + (bToA.rawValueFitScore ?? 0)) / 2;
    return MutualRelationshipValueResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      mutualRawValueFitScore: raw,
      mutualEvidenceConfidence: 1.0,
      directionalAsymmetry: asymmetry ??
          ((aToB.rawValueFitScore ?? 0) - (bToA.rawValueFitScore ?? 0)).abs(),
      status: MutualRelationshipValueStatus.complete,
      configVersion: 'relationship_value_comparison_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
      deterministicFingerprint: 'val_mutual_fp',
      diagnostics: const [],
    );
  }

  static MutualHardConstraintResult hardResult({
    required HardConstraintOutcome outcome,
    List<HardConstraintFieldEvaluation> aToB = const [],
    List<HardConstraintFieldEvaluation> bToA = const [],
  }) {
    DirectionalHardConstraintResult dir(
      String owner,
      String evaluated,
      List<HardConstraintFieldEvaluation> evals,
    ) =>
        DirectionalHardConstraintResult(
          ownerId: owner,
          evaluatedSubjectId: evaluated,
          evaluations: evals,
          passedConstraintIds: [
            for (final e in evals)
              if (e.outcome == HardConstraintOutcome.passed) e.constraintId,
          ]..sort(),
          failedConstraintIds: [
            for (final e in evals)
              if (e.outcome == HardConstraintOutcome.failed) e.constraintId,
          ]..sort(),
          unknownConstraintIds: [
            for (final e in evals)
              if (e.outcome == HardConstraintOutcome.unknown) e.constraintId,
          ]..sort(),
          notApplicableConstraintIds: [
            for (final e in evals)
              if (e.outcome == HardConstraintOutcome.notApplicable)
                e.constraintId,
          ]..sort(),
          aggregateOutcome: outcome,
          deterministicFingerprint: 'hard_dir_fp',
          diagnostics: const [],
          configVersion: 'relationship_value_comparison_config_v1',
          registryVersion: 'canonical_dimension_registry_v1',
        );

    return MutualHardConstraintResult(
      subjectAToBResult: dir('A', 'B', aToB),
      subjectBToAResult: dir('B', 'A', bToA),
      aggregateOutcome: outcome,
      deterministicFingerprint: 'hard_mutual_fp',
      diagnostics: const [],
      configVersion: 'relationship_value_comparison_config_v1',
      registryVersion: 'canonical_dimension_registry_v1',
    );
  }

  static HardConstraintFieldEvaluation hardEval({
    required String id,
    required String field,
    required HardConstraintOutcome outcome,
    String owner = 'A',
    String evaluated = 'B',
  }) =>
      HardConstraintFieldEvaluation(
        constraintId: id,
        ownerId: owner,
        evaluatedSubjectId: evaluated,
        fieldId: field,
        counterpartValue: null,
        counterpartValues: const [],
        acceptedValues: const ['ok'],
        rejectedValues: const [],
        enabled: true,
        matchMode: 'any_allowed',
        outcome: outcome,
        reasonCode: outcome.wire,
        registryVersion: 'canonical_dimension_registry_v1',
        diagnosticCodes: const [],
      );

  static SoftConflictEvaluationResult softResult({
    List<MutualSoftConflictSignal> mutual = const [],
    List<DirectionalSoftConflictSignal> aToB = const [],
    List<DirectionalSoftConflictSignal> bToA = const [],
  }) =>
      SoftConflictEvaluationResult(
        subjectAToBSignals: aToB,
        subjectBToASignals: bToA,
        mutualSignals: mutual,
        deterministicFingerprint: 'soft_fp',
        diagnostics: const [],
        configVersion: 'relationship_value_comparison_config_v1',
        registryVersion: 'canonical_dimension_registry_v1',
      );

  static RelationshipCompatibilityLayerResult layer({
    required MutualRelationshipValueResult values,
    required MutualHardConstraintResult hard,
    SoftConflictEvaluationResult? soft,
  }) =>
      RelationshipCompatibilityLayerResult.assemble(
        mutualValueResult: values,
        mutualHardConstraintResult: hard,
        softConflictResult: soft ?? softResult(),
      );

  static StructuredCompatibilityExplanationResult explain({
    StructuralProfileSimilarityResult? structural,
    MutualPreferenceFitResult? preference,
    RelationshipCompatibilityLayerResult? layer,
    required CoreMethodV2EvaluationResult evaluation,
    DateTime? ts,
  }) {
    const svc = StructuredCompatibilityExplanationService();
    return svc.explain(
      structural: structural,
      preference: preference,
      relationshipLayer: layer,
      evaluation: evaluation,
      dimensionRegistry: loadDims(),
      valueRegistry: loadValues(),
      config: loadConfig(),
      codeRegistry: loadCodeRegistry(),
      generatedAt: ts ?? DateTime.utc(2026, 7, 25, 12),
    );
  }
}
