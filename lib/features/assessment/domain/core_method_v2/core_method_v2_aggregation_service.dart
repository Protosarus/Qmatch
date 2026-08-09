import 'dart:convert';

import 'compatibility_result_contracts.dart';
import 'core_method_v2_aggregation_config.dart';
import 'core_method_v2_aggregation_models.dart';
import 'core_method_v2_validation.dart';
import 'directional_preference_fit_models.dart';
import 'hard_constraint.dart';
import 'hard_constraint_evaluation_models.dart';
import 'relationship_compatibility_layer_result.dart';
import 'relationship_value_comparison_models.dart';
import 'soft_conflict_evaluation_models.dart';
import 'structural_similarity_models.dart';

/// Offline Core Method v2 aggregation + confidence adjustment (P2B-4).
///
/// Accepts already-calculated source results only. Does not invoke structural,
/// preference, value, hard, or soft services.
class CoreMethodV2AggregationService {
  const CoreMethodV2AggregationService();

  static const _tol = 1e-12;

  CoreMethodV2EvaluationResult evaluate({
    required StructuralProfileSimilarityResult? structural,
    required MutualPreferenceFitResult? preference,
    required RelationshipCompatibilityLayerResult? relationshipLayer,
    required CoreMethodAggregationConfig config,
    DateTime? evaluationTimestamp,
  }) {
    final inputs = <String, CoreMethodComponentInput>{
      for (final id in CoreMethodAggregationConfig.configuredComponentIds)
        id: _resolveFromSources(
          componentId: id,
          structural: structural,
          preference: preference,
          relationshipLayer: relationshipLayer,
        ),
    };

    final hard =
        relationshipLayer?.mutualHardConstraintResult.aggregateOutcome ??
            HardConstraintOutcome.notApplicable;
    final failedIds = _failedHardConstraintIds(
      relationshipLayer?.mutualHardConstraintResult,
    );
    final softSummary = _softSummary(relationshipLayer?.softConflictResult);
    final asymmetry = CoreMethodAsymmetrySummary(
      preferenceDirectionalAsymmetry: preference?.directionalAsymmetry,
      valueDirectionalAsymmetry:
          relationshipLayer?.mutualValueResult.directionalAsymmetry,
      diagnosticCodes: [
        if ((preference?.directionalAsymmetry ?? 0) > 0.05)
          'preference_asymmetry_present',
        if ((relationshipLayer?.mutualValueResult.directionalAsymmetry ?? 0) >
            0.05)
          'value_asymmetry_present',
      ]..sort(),
      asymmetryPenaltyApplied: false,
    );

    final overall = aggregateComponents(
      componentInputs: inputs,
      config: config,
      hardConstraintOutcome: hard,
      failedHardConstraintIds: failedIds,
      softConflictSummary: softSummary,
      asymmetrySummary: asymmetry,
      evaluationTimestamp: evaluationTimestamp,
    );

    final eval = CoreMethodV2EvaluationResult(
      structuralProfileResultJson: structural?.toJson(),
      mutualPreferenceResultJson: preference?.toJson(),
      relationshipCompatibilityLayerResultJson: relationshipLayer?.toJson(),
      overallScoreResult: overall,
      missingComponents: overall.diagnostics.missingComponentIds,
      softConflictSummary: softSummary,
      asymmetrySummary: asymmetry,
      aggregationConfigVersion: config.configVersion,
      registryVersion: config.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: '',
    );
    final fp = CoreMethodV2EvaluationResult.fingerprintOf(eval.toJson());
    return CoreMethodV2EvaluationResult(
      structuralProfileResultJson: eval.structuralProfileResultJson,
      mutualPreferenceResultJson: eval.mutualPreferenceResultJson,
      relationshipCompatibilityLayerResultJson:
          eval.relationshipCompatibilityLayerResultJson,
      overallScoreResult: overall,
      missingComponents: eval.missingComponents,
      softConflictSummary: softSummary,
      asymmetrySummary: asymmetry,
      aggregationConfigVersion: config.configVersion,
      registryVersion: config.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: fp,
    );
  }

  /// Direct component aggregation path (synthetic/offline tests & sims).
  CoreMethodOverallScoreResult aggregateComponents({
    required Map<String, CoreMethodComponentInput> componentInputs,
    required CoreMethodAggregationConfig config,
    required HardConstraintOutcome hardConstraintOutcome,
    List<String> failedHardConstraintIds = const [],
    CoreMethodSoftConflictSummary? softConflictSummary,
    CoreMethodAsymmetrySummary? asymmetrySummary,
    DateTime? evaluationTimestamp,
  }) {
    config.validate();

    final soft = softConflictSummary ??
        const CoreMethodSoftConflictSummary(
          lowCount: 0,
          moderateCount: 0,
          highCount: 0,
          highestMutualSeverity: null,
          affectedFieldIds: [],
          diagnosticCodes: [],
          softConflictPenaltyApplied: false,
        );
    final asym = asymmetrySummary ??
        const CoreMethodAsymmetrySummary(
          preferenceDirectionalAsymmetry: null,
          valueDirectionalAsymmetry: null,
          diagnosticCodes: [],
          asymmetryPenaltyApplied: false,
        );

    final codes = <String>{
      'no_persona_input',
      'no_complementarity',
      'no_AI_scoring',
      'soft_conflicts_diagnostic_only',
      ...soft.diagnosticCodes,
      ...asym.diagnosticCodes,
    };

    if (soft.lowCount + soft.moderateCount + soft.highCount > 0) {
      codes.add('soft_conflicts_present_diagnostic_only');
    }

    final resolved = <_ResolvedComponent>[];
    var anyInvalid = false;

    for (final id in CoreMethodAggregationConfig.configuredComponentIds) {
      final weight = config.componentWeights[id];
      if (weight == null) {
        anyInvalid = true;
        codes.add('component_weight_missing');
        resolved.add(_ResolvedComponent.excluded(
          id: id,
          weight: double.nan,
          input: componentInputs[id],
          reason: 'component_weight_missing',
          diag: const ['component_weight_missing'],
        ));
        continue;
      }
      if (!weight.isFinite || weight <= 0) {
        anyInvalid = true;
        codes.add('component_weight_invalid');
        resolved.add(_ResolvedComponent.excluded(
          id: id,
          weight: weight,
          input: componentInputs[id],
          reason: 'component_weight_invalid',
          diag: const ['component_weight_invalid'],
          inclusion: CoreMethodComponentInclusionStatus.invalid,
        ));
        continue;
      }

      final input = componentInputs[id];
      final decision = _eligibility(
        componentId: id,
        input: input,
        weight: weight,
        config: config,
      );
      if (decision.inclusion == CoreMethodComponentInclusionStatus.invalid) {
        anyInvalid = true;
      }
      codes.addAll(decision.diagnosticCodes);
      resolved.add(decision);
    }

    // Unexpected extra component IDs.
    for (final key in componentInputs.keys) {
      if (!CoreMethodAggregationConfig.configuredComponentIds.contains(key)) {
        anyInvalid = true;
        codes.add('component_not_configured');
      }
    }

    final included = resolved
        .where(
            (r) => r.inclusion == CoreMethodComponentInclusionStatus.included)
        .toList();
    final availableCount = included.length;
    final availableMass =
        included.fold<double>(0, (a, b) => a + b.configuredWeight);

    final missingIds = [
      for (final r in resolved)
        if (r.diagnosticCodes.contains('component_missing')) r.componentId,
    ]..sort();
    final excludedIds = [
      for (final r in resolved)
        if (r.inclusion != CoreMethodComponentInclusionStatus.included)
          r.componentId,
    ]..sort();

    if (anyInvalid) {
      codes.add('overall_score_invalid');
      return _finalize(
        config: config,
        hard: hardConstraintOutcome,
        failedIds: failedHardConstraintIds,
        soft: soft,
        asym: asym,
        resolved: resolved,
        included: const [],
        availableMass: availableMass,
        availableCount: availableCount,
        raw: null,
        qOverall: null,
        qMean: null,
        adjusted: null,
        status: CompatibilityEvaluationStatus.invalidInput,
        codes: codes,
        missingIds: missingIds,
        excludedIds: excludedIds,
        evaluationTimestamp: evaluationTimestamp,
        mathematicallyAvailable: false,
      );
    }

    if (hardConstraintOutcome == HardConstraintOutcome.failed) {
      codes.addAll([
        'hard_constraint_failed',
        'hard_constraint_failed_block',
        'overall_score_blocked',
      ]);
      // Contributions for audit without overall scores.
      final auditContrib = _contributions(
        included: included,
        resolved: resolved,
        availableMass: availableMass,
        computeScores: false,
      );
      return _finalize(
        config: config,
        hard: hardConstraintOutcome,
        failedIds: failedHardConstraintIds,
        soft: soft,
        asym: asym,
        resolved: resolved,
        included: included,
        availableMass: availableMass,
        availableCount: availableCount,
        raw: null,
        qOverall: availableCount > 0
            ? included.fold<double>(
                0, (a, b) => a + b.configuredWeight * b.confidence!)
            : null,
        qMean: availableMass > 0
            ? included.fold<double>(
                    0, (a, b) => a + b.configuredWeight * b.confidence!) /
                availableMass
            : null,
        adjusted: null,
        status: CompatibilityEvaluationStatus.blockedByHardConstraint,
        codes: codes,
        missingIds: missingIds,
        excludedIds: excludedIds,
        evaluationTimestamp: evaluationTimestamp,
        mathematicallyAvailable: false,
        forcedContributions: auditContrib,
      );
    }

    final belowCount = availableCount < config.minimumAvailableComponentCount;
    final belowMass = availableMass < config.minimumAvailableWeightMass - _tol;
    final zeroMass = availableMass <= _tol;

    if (belowCount || belowMass || zeroMass) {
      if (belowCount) codes.add('available_component_count_below_minimum');
      if (belowMass || zeroMass) {
        codes.add('available_weight_mass_below_minimum');
      }
      codes.add('overall_score_insufficient_evidence');
      return _finalize(
        config: config,
        hard: hardConstraintOutcome,
        failedIds: failedHardConstraintIds,
        soft: soft,
        asym: asym,
        resolved: resolved,
        included: included,
        availableMass: availableMass,
        availableCount: availableCount,
        raw: null,
        qOverall: availableCount > 0 && availableMass > 0
            ? included.fold<double>(
                0, (a, b) => a + b.configuredWeight * b.confidence!)
            : (availableCount == 0 ? 0.0 : null),
        qMean: availableMass > _tol
            ? included.fold<double>(
                    0, (a, b) => a + b.configuredWeight * b.confidence!) /
                availableMass
            : null,
        adjusted: null,
        status: CompatibilityEvaluationStatus.insufficientEvidence,
        codes: codes,
        missingIds: missingIds,
        excludedIds: excludedIds,
        evaluationTimestamp: evaluationTimestamp,
        mathematicallyAvailable: false,
      );
    }

    // Raw score with available-weight renormalization.
    final rawNumerator =
        included.fold<double>(0, (a, b) => a + b.configuredWeight * b.score!);
    final raw = rawNumerator / availableMass;

    final confNumerator = included.fold<double>(
        0, (a, b) => a + b.configuredWeight * b.confidence!);
    final qOverall = confNumerator; // weights sum to 1 over full C
    final qMean = confNumerator / availableMass;

    cmRequire(
      (qOverall - availableMass * qMean).abs() <= 1e-9,
      'q_overall',
      'identity_failed',
      'Q_overall != M_available * Q_available_mean',
    );

    final neutral = config.neutralScore;
    final adjusted = qOverall * raw + (1 - qOverall) * neutral;
    // Equivalent: neutral + qOverall * (raw - neutral)

    // Never move farther from neutral.
    final distRaw = (raw - neutral).abs();
    final distAdj = (adjusted - neutral).abs();
    cmRequire(
      distAdj <= distRaw + 1e-12,
      'confidenceAdjustedScore',
      'moved_farther_from_neutral',
      'adj=$adjusted raw=$raw',
    );

    if ((qOverall - 1.0).abs() <= 1e-12) {
      // preserve raw
    } else if (qOverall <= _tol) {
      codes.add('score_unchanged_at_neutral');
    } else if ((raw - neutral).abs() > 1e-12) {
      codes.add('score_shrunk_toward_neutral');
    } else {
      codes.add('score_unchanged_at_neutral');
    }

    if (availableMass >= 0.85) {
      codes.add('high_available_weight_mass');
    } else if (availableMass < 0.75) {
      codes.add('limited_available_weight_mass');
    }

    if (qOverall >= 0.85) {
      codes.add('high_evidence_confidence');
    } else if (qOverall >= 0.5) {
      codes.add('moderate_evidence_confidence');
    } else {
      codes.add('low_evidence_confidence');
    }

    var status = CompatibilityEvaluationStatus.complete;
    if (availableCount < config.componentWeights.length ||
        hardConstraintOutcome == HardConstraintOutcome.unknown) {
      status = CompatibilityEvaluationStatus.partial;
      codes.add('overall_score_partial');
    } else {
      codes.add('overall_score_available');
    }

    if (hardConstraintOutcome == HardConstraintOutcome.unknown) {
      codes.add('hard_constraint_unknown');
      codes.add('hard_constraint_resolution_required');
    }

    return _finalize(
      config: config,
      hard: hardConstraintOutcome,
      failedIds: failedHardConstraintIds,
      soft: soft,
      asym: asym,
      resolved: resolved,
      included: included,
      availableMass: availableMass,
      availableCount: availableCount,
      raw: raw,
      qOverall: qOverall,
      qMean: qMean,
      adjusted: adjusted,
      status: status,
      codes: codes,
      missingIds: missingIds,
      excludedIds: excludedIds,
      evaluationTimestamp: evaluationTimestamp,
      mathematicallyAvailable: true,
    );
  }

  CoreMethodComponentInput _resolveFromSources({
    required String componentId,
    required StructuralProfileSimilarityResult? structural,
    required MutualPreferenceFitResult? preference,
    required RelationshipCompatibilityLayerResult? relationshipLayer,
  }) {
    switch (componentId) {
      case 'iq_structural':
        return _fromStructuralModule(
          componentId: componentId,
          module: structural?.iq,
          profilePresent: structural != null,
        );
      case 'eq_structural':
        return _fromStructuralModule(
          componentId: componentId,
          module: structural?.eq,
          profilePresent: structural != null,
        );
      case 'frequency_structural':
        return _fromStructuralModule(
          componentId: componentId,
          module: structural?.frequency,
          profilePresent: structural != null,
        );
      case 'mutual_partner_preference':
        if (preference == null) {
          return const CoreMethodComponentInput(
            componentId: 'mutual_partner_preference',
            score: null,
            confidence: null,
            sourceStatus: 'missing',
            sourceConfigVersion: null,
            sourceRegistryVersion: null,
            sourcePresent: false,
          );
        }
        return CoreMethodComponentInput(
          componentId: componentId,
          score: preference.mutualRawFitScore,
          confidence: preference.mutualEvidenceConfidence,
          sourceStatus: preference.status.wire,
          sourceConfigVersion: preference.configVersion,
          sourceRegistryVersion: preference.registryVersion,
          sourcePresent: true,
          sourceDiagnosticCodes:
              preference.status == MutualPreferenceFitStatus.partial
                  ? const ['component_partial_but_scoreable']
                  : const [],
        );
      case 'mutual_relationship_values':
        final mutual = relationshipLayer?.mutualValueResult;
        if (mutual == null) {
          return const CoreMethodComponentInput(
            componentId: 'mutual_relationship_values',
            score: null,
            confidence: null,
            sourceStatus: 'missing',
            sourceConfigVersion: null,
            sourceRegistryVersion: null,
            sourcePresent: false,
          );
        }
        return CoreMethodComponentInput(
          componentId: componentId,
          score: mutual.mutualRawValueFitScore,
          confidence: mutual.mutualEvidenceConfidence,
          sourceStatus: mutual.status.wire,
          sourceConfigVersion: mutual.configVersion,
          sourceRegistryVersion: mutual.registryVersion,
          sourcePresent: true,
          sourceDiagnosticCodes:
              mutual.status == MutualRelationshipValueStatus.partial
                  ? const ['component_partial_but_scoreable']
                  : const [],
        );
      default:
        return CoreMethodComponentInput(
          componentId: componentId,
          score: null,
          confidence: null,
          sourceStatus: 'missing',
          sourceConfigVersion: null,
          sourceRegistryVersion: null,
          sourcePresent: false,
          markedInvalid: true,
          sourceDiagnosticCodes: const ['component_not_configured'],
        );
    }
  }

  CoreMethodComponentInput _fromStructuralModule({
    required String componentId,
    required StructuralModuleSimilarityResult? module,
    required bool profilePresent,
  }) {
    if (module == null) {
      return CoreMethodComponentInput(
        componentId: componentId,
        score: null,
        confidence: null,
        sourceStatus: profilePresent ? 'missing' : 'missing',
        sourceConfigVersion: null,
        sourceRegistryVersion: null,
        sourcePresent: false,
      );
    }
    return CoreMethodComponentInput(
      componentId: componentId,
      score: module.similarityScore,
      confidence: module.evidenceConfidence,
      sourceStatus: module.status.wire,
      sourceConfigVersion: module.configVersion,
      sourceRegistryVersion: module.registryVersion,
      sourcePresent: true,
      sourceDiagnosticCodes: module.status == StructuralModuleStatus.partial
          ? const ['component_partial_but_scoreable']
          : const [],
    );
  }

  _ResolvedComponent _eligibility({
    required String componentId,
    required CoreMethodComponentInput? input,
    required double weight,
    required CoreMethodAggregationConfig config,
  }) {
    if (input == null || !input.sourcePresent) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_missing',
        diag: const ['component_missing', 'component_excluded_missing'],
      );
    }

    if (input.markedInvalid) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_invalid_input',
        diag: const [
          'component_invalid_input',
          'component_excluded_invalid',
        ],
        inclusion: CoreMethodComponentInclusionStatus.invalid,
      );
    }

    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_version') {
      if (input.sourceRegistryVersion != null &&
          input.sourceRegistryVersion != config.registryVersion) {
        return _ResolvedComponent.excluded(
          id: componentId,
          weight: weight,
          input: input,
          reason: 'component_registry_version_mismatch',
          diag: const [
            'component_registry_version_mismatch',
            'component_excluded_invalid',
          ],
          inclusion: CoreMethodComponentInclusionStatus.invalid,
        );
      }
      if (input.sourceConfigVersion != null &&
          input.sourceConfigVersion!.isNotEmpty) {
        // Source config versions differ by engine; mismatch is diagnostic only
        // unless the value is explicitly marked incompatible.
        if (input.sourceDiagnosticCodes
            .contains('component_config_version_mismatch')) {
          return _ResolvedComponent.excluded(
            id: componentId,
            weight: weight,
            input: input,
            reason: 'component_config_version_mismatch',
            diag: const [
              'component_config_version_mismatch',
              'component_excluded_invalid',
            ],
            inclusion: CoreMethodComponentInclusionStatus.invalid,
          );
        }
      }
    }

    final status = input.sourceStatus;
    if (status == 'insufficient_evidence') {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_insufficient_evidence',
        diag: const ['component_insufficient_evidence', 'component_excluded'],
      );
    }
    if (status == 'invalid_input') {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_invalid_input',
        diag: const [
          'component_invalid_input',
          'component_excluded_invalid',
        ],
        inclusion: CoreMethodComponentInclusionStatus.invalid,
      );
    }
    if (status != 'complete' && status != 'partial') {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_excluded',
        diag: const ['component_excluded'],
      );
    }

    final score = input.score;
    final conf = input.confidence;
    if (score == null) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_score_unavailable',
        diag: const ['component_score_unavailable', 'component_excluded'],
      );
    }
    if (conf == null) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_confidence_unavailable',
        diag: const [
          'component_confidence_unavailable',
          'component_excluded',
        ],
      );
    }
    if (!score.isFinite) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_invalid_score',
        diag: const [
          'component_invalid_score',
          'component_excluded_invalid',
        ],
        inclusion: CoreMethodComponentInclusionStatus.invalid,
      );
    }
    if (score < 0 || score > 1) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_invalid_score',
        diag: const [
          'component_invalid_score',
          'component_excluded_invalid',
        ],
        inclusion: CoreMethodComponentInclusionStatus.invalid,
      );
    }
    if (!conf.isFinite || conf < 0 || conf > 1) {
      return _ResolvedComponent.excluded(
        id: componentId,
        weight: weight,
        input: input,
        reason: 'component_invalid_confidence',
        diag: const [
          'component_invalid_confidence',
          'component_excluded_invalid',
        ],
        inclusion: CoreMethodComponentInclusionStatus.invalid,
      );
    }

    final diags = <String>[
      ...input.sourceDiagnosticCodes,
      if (status == 'partial') 'component_partial_but_scoreable',
    ];

    return _ResolvedComponent(
      componentId: componentId,
      configuredWeight: weight,
      score: score,
      confidence: conf,
      sourceStatus: status,
      sourceConfigVersion: input.sourceConfigVersion,
      sourceRegistryVersion: input.sourceRegistryVersion,
      inclusion: CoreMethodComponentInclusionStatus.included,
      exclusionReason: null,
      diagnosticCodes: diags.toSet().toList()..sort(),
    );
  }

  List<CoreMethodComponentContribution> _contributions({
    required List<_ResolvedComponent> included,
    required List<_ResolvedComponent> resolved,
    required double availableMass,
    required bool computeScores,
  }) {
    final normFactor =
        (computeScores && availableMass > _tol) ? (1.0 / availableMass) : null;
    double? finiteOrNull(double? v) => v != null && v.isFinite ? v : null;
    return [
      for (final r in resolved)
        CoreMethodComponentContribution(
          componentId: r.componentId,
          configuredWeight:
              r.configuredWeight.isFinite ? r.configuredWeight : 0,
          availableWeightNormalizationFactor:
              r.inclusion == CoreMethodComponentInclusionStatus.included
                  ? normFactor
                  : null,
          normalizedAvailableWeight:
              r.inclusion == CoreMethodComponentInclusionStatus.included &&
                      normFactor != null
                  ? r.configuredWeight * normFactor
                  : null,
          rawComponentScore: finiteOrNull(r.score),
          componentEvidenceConfidence: finiteOrNull(r.confidence),
          weightedRawContribution:
              r.inclusion == CoreMethodComponentInclusionStatus.included &&
                      normFactor != null &&
                      r.score != null &&
                      r.score!.isFinite
                  ? (r.configuredWeight * normFactor) * r.score!
                  : null,
          weightedConfidenceContribution:
              r.inclusion == CoreMethodComponentInclusionStatus.included &&
                      r.confidence != null &&
                      r.confidence!.isFinite
                  ? r.configuredWeight * r.confidence!
                  : null,
          sourceStatus: r.sourceStatus,
          sourceConfigVersion: r.sourceConfigVersion,
          sourceRegistryVersion: r.sourceRegistryVersion,
          inclusionStatus: r.inclusion,
          exclusionReason: r.exclusionReason,
          diagnosticCodes: r.diagnosticCodes,
        ),
    ];
  }

  CoreMethodOverallScoreResult _finalize({
    required CoreMethodAggregationConfig config,
    required HardConstraintOutcome hard,
    required List<String> failedIds,
    required CoreMethodSoftConflictSummary soft,
    required CoreMethodAsymmetrySummary asym,
    required List<_ResolvedComponent> resolved,
    required List<_ResolvedComponent> included,
    required double availableMass,
    required int availableCount,
    required double? raw,
    required double? qOverall,
    required double? qMean,
    required double? adjusted,
    required CompatibilityEvaluationStatus status,
    required Set<String> codes,
    required List<String> missingIds,
    required List<String> excludedIds,
    required DateTime? evaluationTimestamp,
    required bool mathematicallyAvailable,
    List<CoreMethodComponentContribution>? forcedContributions,
  }) {
    final contrib = forcedContributions ??
        _contributions(
          included: included,
          resolved: resolved,
          availableMass: availableMass,
          computeScores: mathematicallyAvailable && raw != null,
        );

    if (mathematicallyAvailable && raw != null) {
      final sumRaw = contrib
          .where((c) => c.weightedRawContribution != null)
          .fold<double>(0, (a, b) => a + b.weightedRawContribution!);
      cmRequire(
        (sumRaw - raw).abs() <= 1e-9,
        'weighted_raw_contribution',
        'sum_mismatch',
        'sum=$sumRaw raw=$raw',
      );
      if (qOverall != null) {
        final sumQ = contrib
            .where((c) => c.weightedConfidenceContribution != null)
            .fold<double>(0, (a, b) => a + b.weightedConfidenceContribution!);
        cmRequire(
          (sumQ - qOverall).abs() <= 1e-9,
          'weighted_confidence_contribution',
          'sum_mismatch',
          'sum=$sumQ q=$qOverall',
        );
      }
    }

    final internalPublish = mathematicallyAvailable &&
        raw != null &&
        adjusted != null &&
        (hard == HardConstraintOutcome.passed ||
            hard == HardConstraintOutcome.notApplicable) &&
        (status == CompatibilityEvaluationStatus.complete ||
            status == CompatibilityEvaluationStatus.partial);

    // Unknown hard: scores may exist, but not publishable / ranking eligible.
    final publishable = internalPublish;

    final sortedCodes = codes.toList()..sort();
    final diagnostics = CoreMethodAggregationDiagnostics(
      diagnosticCodes: sortedCodes,
      softConflictSummary: soft,
      asymmetrySummary: asym,
      missingComponentIds: missingIds,
      excludedComponentIds: excludedIds,
      failedHardConstraintIds: [...failedIds]..sort(),
      complementarityApplied: false,
      temporalLayerApplied: false,
      personaInputUsed: false,
      frequencyTypeUsed: false,
      aiScoringUsed: false,
      softConflictPenaltyApplied: false,
      asymmetryPenaltyApplied: false,
    );

    final provisional = CoreMethodOverallScoreResult(
      rawScore: raw,
      confidenceAdjustedScore: adjusted,
      neutralScore: config.neutralScore,
      overallEvidenceConfidence: qOverall,
      availableComponentMeanConfidence: qMean,
      availableConfiguredWeightMass: availableMass,
      configuredComponentCount: config.componentWeights.length,
      availableComponentCount: availableCount,
      includedComponentIds: [
        for (final r in included) r.componentId,
      ]..sort(),
      componentContributions: contrib,
      hardConstraintOutcome: hard,
      mathematicallyAvailable: mathematicallyAvailable,
      internallyPublishableForReview: publishable,
      productionPublishable: false,
      publishable: publishable,
      rankingEligible: false,
      liveRankingEligible: false,
      productionApproved: false,
      evaluationStatus: status,
      configVersion: config.configVersion,
      registryVersion: config.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: '',
      diagnosticCodes: sortedCodes,
      diagnostics: diagnostics,
    );

    final fp = _fingerprint(provisional.toJson());
    return CoreMethodOverallScoreResult(
      rawScore: provisional.rawScore,
      confidenceAdjustedScore: provisional.confidenceAdjustedScore,
      neutralScore: provisional.neutralScore,
      overallEvidenceConfidence: provisional.overallEvidenceConfidence,
      availableComponentMeanConfidence:
          provisional.availableComponentMeanConfidence,
      availableConfiguredWeightMass: provisional.availableConfiguredWeightMass,
      configuredComponentCount: provisional.configuredComponentCount,
      availableComponentCount: provisional.availableComponentCount,
      includedComponentIds: provisional.includedComponentIds,
      componentContributions: provisional.componentContributions,
      hardConstraintOutcome: provisional.hardConstraintOutcome,
      mathematicallyAvailable: provisional.mathematicallyAvailable,
      internallyPublishableForReview:
          provisional.internallyPublishableForReview,
      productionPublishable: false,
      publishable: provisional.publishable,
      rankingEligible: false,
      liveRankingEligible: false,
      productionApproved: false,
      evaluationStatus: provisional.evaluationStatus,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: fp,
      diagnosticCodes: provisional.diagnosticCodes,
      diagnostics: provisional.diagnostics,
    );
  }

  CoreMethodSoftConflictSummary _softSummary(
      SoftConflictEvaluationResult? soft) {
    if (soft == null) {
      return const CoreMethodSoftConflictSummary(
        lowCount: 0,
        moderateCount: 0,
        highCount: 0,
        highestMutualSeverity: null,
        affectedFieldIds: [],
        diagnosticCodes: [],
        softConflictPenaltyApplied: false,
      );
    }
    var low = 0, mod = 0, high = 0;
    double? highest;
    final fields = <String>[];
    for (final s in soft.mutualSignals) {
      fields.add(s.fieldId);
      final sev = s.mutualSeverity;
      if (sev != null) {
        highest = highest == null ? sev : (sev > highest ? sev : highest);
      }
      switch (s.severityBand) {
        case 'low':
          low++;
          break;
        case 'moderate':
          mod++;
          break;
        case 'high':
          high++;
          break;
      }
    }
    fields.sort();
    return CoreMethodSoftConflictSummary(
      lowCount: low,
      moderateCount: mod,
      highCount: high,
      highestMutualSeverity: highest,
      affectedFieldIds: fields,
      diagnosticCodes: [
        if (low + mod + high > 0) 'soft_conflicts_present_diagnostic_only',
      ],
      softConflictPenaltyApplied: false,
    );
  }

  List<String> _failedHardConstraintIds(MutualHardConstraintResult? hard) {
    if (hard == null) return const [];
    final ids = <String>{};
    for (final r in [
      ...hard.subjectAToBResult.evaluations,
      ...hard.subjectBToAResult.evaluations,
    ]) {
      if (r.outcome == HardConstraintOutcome.failed) {
        ids.add(r.constraintId);
      }
    }
    return ids.toList()..sort();
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

class _ResolvedComponent {
  final String componentId;
  final double configuredWeight;
  final double? score;
  final double? confidence;
  final String sourceStatus;
  final String? sourceConfigVersion;
  final String? sourceRegistryVersion;
  final CoreMethodComponentInclusionStatus inclusion;
  final String? exclusionReason;
  final List<String> diagnosticCodes;

  _ResolvedComponent({
    required this.componentId,
    required this.configuredWeight,
    required this.score,
    required this.confidence,
    required this.sourceStatus,
    required this.sourceConfigVersion,
    required this.sourceRegistryVersion,
    required this.inclusion,
    required this.exclusionReason,
    required this.diagnosticCodes,
  });

  factory _ResolvedComponent.excluded({
    required String id,
    required double weight,
    required CoreMethodComponentInput? input,
    required String reason,
    required List<String> diag,
    CoreMethodComponentInclusionStatus inclusion =
        CoreMethodComponentInclusionStatus.excluded,
  }) =>
      _ResolvedComponent(
        componentId: id,
        configuredWeight: weight,
        score: input?.score,
        confidence: input?.confidence,
        sourceStatus: input?.sourceStatus ?? 'missing',
        sourceConfigVersion: input?.sourceConfigVersion,
        sourceRegistryVersion: input?.sourceRegistryVersion,
        inclusion: inclusion,
        exclusionReason: reason,
        diagnosticCodes: diag,
      );
}
