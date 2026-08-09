import 'assessment_module_id.dart';
import 'canonical_dimension_registry.dart';
import 'compatibility_result_contracts.dart';
import 'core_method_v2_aggregation_models.dart';
import 'core_method_v2_validation.dart';
import 'directional_preference_fit_models.dart';
import 'hard_constraint.dart';
import 'hard_constraint_evaluation_models.dart';
import 'relationship_compatibility_layer_result.dart';
import 'relationship_value_comparison_models.dart';
import 'relationship_value_registry.dart';
import 'soft_conflict_evaluation_models.dart';
import 'structural_similarity_models.dart';
import 'structured_explanation_config.dart';
import 'structured_explanation_models.dart';

/// Offline structured explanation layer (P2B-5).
///
/// Reads already-calculated source results only. Never modifies scores.
class StructuredCompatibilityExplanationService {
  const StructuredCompatibilityExplanationService();

  StructuredCompatibilityExplanationResult explain({
    required StructuralProfileSimilarityResult? structural,
    required MutualPreferenceFitResult? preference,
    required RelationshipCompatibilityLayerResult? relationshipLayer,
    required CoreMethodV2EvaluationResult evaluation,
    required CanonicalDimensionRegistry dimensionRegistry,
    required RelationshipValueRegistry valueRegistry,
    required StructuredExplanationConfig config,
    required StructuredExplanationCodeRegistry codeRegistry,
    DateTime? generatedAt,
  }) {
    config.validate();
    final overall = evaluation.overallScoreResult;
    final privacy = <String>[];
    final candidates = <_Cand>[];

    _validateVersions(
      config: config,
      structural: structural,
      preference: preference,
      relationshipLayer: relationshipLayer,
      overall: overall,
    );

    // Overall status
    candidates.addAll(_overallStatus(overall, config, codeRegistry));

    // Confidence adjustment
    candidates.addAll(_confidenceAdjustment(overall, config, codeRegistry));

    // Production limitation (always)
    candidates.add(_code(
      code: 'production_not_approved',
      config: config,
      registry: codeRegistry,
      sourceType: 'aggregation',
      sourceComponentId: 'aggregation',
      salience: 0.15,
      confidence: overall.overallEvidenceConfidence,
      magnitude: null,
      params: [
        _p('status_code', 'status_code', 'not_approved'),
      ],
      refs: [
        _ref(
          type: 'CoreMethodOverallScoreResult',
          fp: overall.deterministicFingerprint,
          path: 'overall.production_approval',
          status: overall.evaluationStatus.wire,
          configVersion: overall.configVersion,
          nums: const {},
        ),
      ],
      diags: const ['no_production_ranking'],
    ));

    // Hard constraints
    candidates.addAll(_hard(
      relationshipLayer?.mutualHardConstraintResult,
      overall,
      config,
      codeRegistry,
      privacy,
    ));

    // Soft conflicts
    candidates.addAll(_soft(
      relationshipLayer?.softConflictResult,
      config,
      codeRegistry,
    ));

    // Structural
    candidates.addAll(
        _structural(structural, dimensionRegistry, config, codeRegistry));

    // Preference
    candidates.addAll(_preference(preference, config, codeRegistry));

    // Values
    candidates.addAll(_values(
      relationshipLayer?.mutualValueResult,
      valueRegistry,
      config,
      codeRegistry,
      privacy,
    ));

    // Aggregation evidence / missing
    candidates.addAll(_aggregationEvidence(overall, config, codeRegistry));

    // Asymmetry
    candidates.addAll(
        _asymmetry(preference, relationshipLayer, config, codeRegistry));

    // Dedup
    final deduped = _dedupe(candidates);

    // Rank + caps
    final ranked = _rankAndCap(deduped, config, dimensionRegistry);

    final omitted = deduped.length - ranked.length;
    final signals = <StructuredCompatibilityExplanationSignal>[];
    for (var i = 0; i < ranked.length; i++) {
      final c = ranked[i];
      final def = codeRegistry.require(c.explanationCode);
      signals.add(StructuredCompatibilityExplanationSignal(
        signalId: c.signalId,
        explanationCode: c.explanationCode,
        category: def.category,
        polarity: def.polarity,
        sourceType: c.sourceType,
        sourceComponentId: c.sourceComponentId,
        dimensionId: c.dimensionId,
        fieldId: c.fieldId,
        module: c.module,
        direction: c.direction,
        salienceScore: c.salience,
        evidenceConfidence: c.confidence,
        confidenceBand: config.confidenceBand(c.confidence),
        magnitude: c.magnitude,
        rank: i + 1,
        localizationKey: def.defaultLocalizationKey,
        localizationParameters: c.params,
        evidenceReferences: c.refs,
        diagnosticCodes: c.diags,
        blocking: def.blockingEligibility || def.polarity == 'blocking',
        displayEligible: true,
        productionEligible: false,
        configVersion: config.configVersion,
        registryVersion: config.registryVersion,
      ));
    }

    // Ensure every emitted code is registered (already via require).
    for (final s in signals) {
      codeRegistry.require(s.explanationCode);
    }

    final missing = [
      ...overall.diagnostics.missingComponentIds,
      if (structural == null) 'structural_profile',
      if (preference == null) 'mutual_partner_preference',
      if (relationshipLayer == null) 'relationship_compatibility_layer',
    ]..sort();

    final coverage = StructuredExplanationCoverage(
      availableAggregationComponentsExplained: overall.availableComponentCount,
      totalAvailableAggregationComponents: overall.availableComponentCount,
      includedHighSalienceSourceSignals:
          signals.where((s) => s.salienceScore >= 0.5).length,
      omittedEligibleSignals: omitted < 0 ? 0 : omitted,
      sourceExclusionsRepresented: signals
          .where((s) =>
              s.category == 'missing_information' ||
              s.explanationCode.contains('excluded'))
          .length,
      missingComponentsRepresented:
          signals.where((s) => s.explanationCode == 'component_missing').length,
    );

    final summary = StructuredExplanationSummary(
      totalSignals: signals.length,
      supportiveCount: signals.where((s) => s.polarity == 'supportive').length,
      cautionaryCount: signals.where((s) => s.polarity == 'cautionary').length,
      blockingCount: signals.where((s) => s.blocking).length,
      evidenceLimitationCount:
          signals.where((s) => s.category == 'evidence_limitation').length,
      topExplanationCodes: [
        for (final s in signals.take(5)) s.explanationCode,
      ],
    );

    final diagCodes = <String>{
      'no_score_modification',
      'no_soft_conflict_penalty',
      'no_AI_scoring',
      'no_persona_input',
      'no_complementarity',
      'localization_keys_only',
      ...privacy,
    }.toList()
      ..sort();

    final provisional = StructuredCompatibilityExplanationResult(
      evaluationStatus: overall.evaluationStatus,
      overallRawScore: overall.rawScore,
      confidenceAdjustedScore: overall.confidenceAdjustedScore,
      overallEvidenceConfidence: overall.overallEvidenceConfidence,
      signals: signals,
      supportiveSignals:
          signals.where((s) => s.polarity == 'supportive').toList(),
      cautionarySignals:
          signals.where((s) => s.polarity == 'cautionary').toList(),
      blockingSignals: signals.where((s) => s.blocking).toList(),
      evidenceLimitationSignals:
          signals.where((s) => s.category == 'evidence_limitation').toList(),
      omittedSignalCount: omitted < 0 ? 0 : omitted,
      missingSourceComponents: missing.toSet().toList()..sort(),
      explanationCoverage: coverage,
      summary: summary,
      deterministicFingerprint: '',
      diagnostics: StructuredExplanationDiagnostics(
        diagnosticCodes: diagCodes,
        privacyDiagnostics: privacy.toSet().toList()..sort(),
      ),
      configVersion: config.configVersion,
      registryVersion: config.registryVersion,
      generatedAt: generatedAt,
    );

    final fp = StructuredCompatibilityExplanationResult.fingerprintOf(
      provisional.toJson(),
    );
    return StructuredCompatibilityExplanationResult(
      evaluationStatus: provisional.evaluationStatus,
      overallRawScore: provisional.overallRawScore,
      confidenceAdjustedScore: provisional.confidenceAdjustedScore,
      overallEvidenceConfidence: provisional.overallEvidenceConfidence,
      signals: provisional.signals,
      supportiveSignals: provisional.supportiveSignals,
      cautionarySignals: provisional.cautionarySignals,
      blockingSignals: provisional.blockingSignals,
      evidenceLimitationSignals: provisional.evidenceLimitationSignals,
      omittedSignalCount: provisional.omittedSignalCount,
      missingSourceComponents: provisional.missingSourceComponents,
      explanationCoverage: provisional.explanationCoverage,
      summary: provisional.summary,
      deterministicFingerprint: fp,
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
      generatedAt: generatedAt,
    );
  }

  void _validateVersions({
    required StructuredExplanationConfig config,
    required StructuralProfileSimilarityResult? structural,
    required MutualPreferenceFitResult? preference,
    required RelationshipCompatibilityLayerResult? relationshipLayer,
    required CoreMethodOverallScoreResult overall,
  }) {
    if (config.versionCompatibilityPolicy !=
        'require_matching_registry_version') {
      return;
    }
    if (overall.registryVersion.isNotEmpty &&
        overall.registryVersion != config.registryVersion) {
      throw CoreMethodValidationException('registry mismatch', [
        CoreMethodValidationError(
          fieldPath: 'overall.registry_version',
          reasonCode: 'component_registry_version_mismatch',
          explanation: overall.registryVersion,
        ),
      ]);
    }
    void check(String? v, String path) {
      if (v != null && v.isNotEmpty && v != config.registryVersion) {
        throw CoreMethodValidationException('registry mismatch', [
          CoreMethodValidationError(
            fieldPath: path,
            reasonCode: 'component_registry_version_mismatch',
            explanation: v,
          ),
        ]);
      }
    }

    check(structural?.registryVersion, 'structural.registry_version');
    check(preference?.registryVersion, 'preference.registry_version');
    check(relationshipLayer?.registryVersion, 'relationship.registry_version');
  }

  List<_Cand> _overallStatus(
    CoreMethodOverallScoreResult overall,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    final code = switch (overall.evaluationStatus) {
      CompatibilityEvaluationStatus.complete => 'overall_status_complete',
      CompatibilityEvaluationStatus.partial => 'overall_status_partial',
      CompatibilityEvaluationStatus.insufficientEvidence =>
        'overall_status_insufficient',
      CompatibilityEvaluationStatus.blockedByHardConstraint =>
        'overall_status_blocked',
      CompatibilityEvaluationStatus.invalidInput => 'overall_status_invalid',
    };
    return [
      _code(
        code: code,
        config: config,
        registry: registry,
        sourceType: 'aggregation',
        sourceComponentId: 'aggregation',
        salience: overall.evaluationStatus ==
                CompatibilityEvaluationStatus.blockedByHardConstraint
            ? 1.0
            : 0.95,
        confidence: overall.overallEvidenceConfidence,
        magnitude: null,
        params: [
          _p('status_code', 'status_code', overall.evaluationStatus.wire),
          if (overall.rawScore != null)
            _p('normalized_score', 'normalized_score', overall.rawScore),
          if (overall.overallEvidenceConfidence != null)
            _p('confidence', 'confidence', overall.overallEvidenceConfidence),
          if (overall.availableComponentCount > 0)
            _p('count', 'count', overall.availableComponentCount),
        ],
        refs: [
          _ref(
            type: 'CoreMethodOverallScoreResult',
            fp: overall.deterministicFingerprint,
            path: 'overall.evaluation_status',
            status: overall.evaluationStatus.wire,
            configVersion: overall.configVersion,
            nums: {
              'raw_score': overall.rawScore,
              'adjusted_score': overall.confidenceAdjustedScore,
            },
          ),
        ],
        diags: const [],
        blocking: overall.evaluationStatus ==
            CompatibilityEvaluationStatus.blockedByHardConstraint,
      ),
    ];
  }

  List<_Cand> _confidenceAdjustment(
    CoreMethodOverallScoreResult overall,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    final raw = overall.rawScore;
    final adj = overall.confidenceAdjustedScore;
    if (raw == null || adj == null) {
      if (overall.evaluationStatus ==
          CompatibilityEvaluationStatus.insufficientEvidence) {
        return [
          _code(
            code: 'overall_status_insufficient',
            config: config,
            registry: registry,
            sourceType: 'evidence_coverage',
            sourceComponentId: 'aggregation',
            salience: 0.9,
            confidence: overall.overallEvidenceConfidence,
            magnitude: null,
            params: [
              _p('status_code', 'status_code', 'insufficient_evidence'),
              _p('count', 'count', overall.availableComponentCount),
            ],
            refs: [
              _ref(
                type: 'CoreMethodOverallScoreResult',
                fp: overall.deterministicFingerprint,
                path: 'overall.insufficient_evidence',
                status: overall.evaluationStatus.wire,
                configVersion: overall.configVersion,
                nums: {
                  'm_available': overall.availableConfiguredWeightMass,
                },
              ),
            ],
            diags: const ['no_fabricated_neutral_explanation'],
            signalIdOverride: 'overall_insufficient_evidence_detail',
          ),
        ];
      }
      return const [];
    }
    if ((raw - adj).abs() <= config.scoreDifferenceTolerance) {
      return const [];
    }
    final q = overall.overallEvidenceConfidence ?? 0;
    final shrink = raw > overall.neutralScore + config.scoreDifferenceTolerance
        ? 'high_raw_shrunk_downward'
        : raw < overall.neutralScore - config.scoreDifferenceTolerance
            ? 'low_raw_shrunk_upward'
            : 'neutral_unchanged';
    return [
      _code(
        code: 'score_shrunk_toward_neutral',
        config: config,
        registry: registry,
        sourceType: 'aggregation',
        sourceComponentId: 'aggregation',
        salience: 0.85,
        confidence: q,
        magnitude: (raw - adj).abs().clamp(0.0, 1.0),
        params: [
          _p('normalized_score', 'normalized_score', raw),
          _p('confidence', 'confidence', q),
          _p('status_code', 'status_code', shrink),
          _p('percentage_like_ratio', 'percentage_like_ratio', adj),
          _p('count', 'count', overall.availableComponentCount),
        ],
        refs: [
          _ref(
            type: 'CoreMethodOverallScoreResult',
            fp: overall.deterministicFingerprint,
            path: 'overall.confidence_adjustment',
            status: overall.evaluationStatus.wire,
            configVersion: overall.configVersion,
            nums: {
              'raw_score': raw,
              'adjusted_score': adj,
              'neutral_score': overall.neutralScore,
              'q_overall': q,
              'm_available': overall.availableConfiguredWeightMass,
              'q_available_mean': overall.availableComponentMeanConfidence,
            },
          ),
        ],
        diags: const [
          'conservative_evidence_adjustment',
          'not_corrected_score',
          'not_true_score',
        ],
      ),
    ];
  }

  List<_Cand> _hard(
    MutualHardConstraintResult? hard,
    CoreMethodOverallScoreResult overall,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
    List<String> privacy,
  ) {
    if (hard == null) return const [];
    final out = <_Cand>[];
    if (hard.aggregateOutcome == HardConstraintOutcome.failed) {
      out.add(_code(
        code: 'hard_constraint_result_blocked',
        config: config,
        registry: registry,
        sourceType: 'hard_constraint',
        sourceComponentId: 'hard_constraint',
        salience: 1.0,
        confidence: 1.0,
        magnitude: null,
        params: [
          _p('status_code', 'status_code', 'blocked_by_hard_constraint')
        ],
        refs: [
          _ref(
            type: 'MutualHardConstraintResult',
            fp: hard.deterministicFingerprint,
            path: 'hard.aggregate_outcome',
            status: hard.aggregateOutcome.wire,
            configVersion: hard.configVersion,
            nums: const {},
          ),
        ],
        diags: const ['hard_constraint_failed_block'],
        blocking: true,
      ));
    }
    if (hard.aggregateOutcome == HardConstraintOutcome.unknown) {
      out.add(_code(
        code: 'hard_constraint_resolution_required',
        config: config,
        registry: registry,
        sourceType: 'hard_constraint',
        sourceComponentId: 'hard_constraint',
        salience: 0.98,
        confidence: 1.0,
        magnitude: null,
        params: [_p('status_code', 'status_code', 'unknown')],
        refs: [
          _ref(
            type: 'MutualHardConstraintResult',
            fp: hard.deterministicFingerprint,
            path: 'hard.aggregate_outcome',
            status: hard.aggregateOutcome.wire,
            configVersion: hard.configVersion,
            nums: const {},
          ),
        ],
        diags: const ['hard_constraint_unknown'],
      ));
    }

    void emitEval(HardConstraintFieldEvaluation e, String direction) {
      final code = switch (e.outcome) {
        HardConstraintOutcome.failed => 'hard_constraint_failed',
        HardConstraintOutcome.unknown => 'hard_constraint_unknown',
        HardConstraintOutcome.passed => 'hard_constraint_passed',
        HardConstraintOutcome.notApplicable => 'hard_constraint_not_applicable',
      };
      privacy.add('hard_constraint_value_redacted');
      out.add(_code(
        code: code,
        config: config,
        registry: registry,
        sourceType: 'hard_constraint',
        sourceComponentId: 'hard_constraint',
        fieldId: e.fieldId,
        direction: direction,
        salience: switch (e.outcome) {
          HardConstraintOutcome.failed => 1.0,
          HardConstraintOutcome.unknown => 0.9,
          HardConstraintOutcome.passed => 0.4,
          HardConstraintOutcome.notApplicable => 0.2,
        },
        confidence: 1.0,
        magnitude: null,
        params: [
          _p('constraint_id', 'constraint_id', e.constraintId),
          _p('field_id', 'field_id', e.fieldId),
          _p('status_code', 'status_code', e.outcome.wire),
          _p('direction', 'direction', direction),
        ],
        refs: [
          _ref(
            type: 'HardConstraintFieldEvaluation',
            fp: hard.deterministicFingerprint,
            path: 'hard.$direction.${e.constraintId}',
            status: e.outcome.wire,
            configVersion: hard.configVersion,
            nums: const {},
          ),
        ],
        diags: const ['hard_constraint_value_redacted'],
        blocking: e.outcome == HardConstraintOutcome.failed,
      ));
    }

    for (final e in hard.subjectAToBResult.evaluations) {
      emitEval(e, 'a_evaluates_b');
    }
    for (final e in hard.subjectBToAResult.evaluations) {
      emitEval(e, 'b_evaluates_a');
    }
    return out;
  }

  List<_Cand> _soft(
    SoftConflictEvaluationResult? soft,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    if (soft == null) return const [];
    final out = <_Cand>[];
    for (final m in soft.mutualSignals) {
      if (!config.softConflictReportingBands.contains(m.severityBand)) {
        continue;
      }
      final sev = m.mutualSeverity;
      if (sev == null || !sev.isFinite) continue;
      final code = switch (m.severityBand) {
        'low' => 'soft_conflict_low',
        'moderate' => 'soft_conflict_moderate',
        'high' => 'soft_conflict_high',
        _ => 'soft_conflict_moderate',
      };
      final q = 1.0; // mutual signal may lack confidence; treat as available
      out.add(_code(
        code: code,
        config: config,
        registry: registry,
        sourceType: 'soft_conflict',
        sourceComponentId: 'soft_conflict',
        fieldId: m.fieldId,
        salience: (sev * q).clamp(0.0, 1.0),
        confidence: q,
        magnitude: sev,
        params: [
          _p('field_id', 'field_id', m.fieldId),
          _p('severity_band', 'severity_band', m.severityBand),
          _p('normalized_score', 'normalized_score', sev),
          _p('confidence', 'confidence', q),
        ],
        refs: [
          _ref(
            type: 'MutualSoftConflictSignal',
            fp: soft.deterministicFingerprint,
            path: 'soft.mutual.${m.fieldId}',
            status: m.severityBand,
            configVersion: soft.configVersion,
            nums: {
              'mutual_severity': sev,
              'a_to_b': m.subjectAToBSeverity,
              'b_to_a': m.subjectBToASeverity,
            },
          ),
        ],
        diags: const ['soft_conflicts_diagnostic_only', 'no_soft_penalty'],
      ));
    }
    for (final d in soft.subjectAToBSignals) {
      out.add(_code(
        code: 'soft_conflict_directional',
        config: config,
        registry: registry,
        sourceType: 'soft_conflict',
        sourceComponentId: 'soft_conflict',
        fieldId: d.fieldId,
        direction: 'a_evaluates_b',
        salience: (d.severity * d.evidenceConfidence).clamp(0.0, 1.0),
        confidence: d.evidenceConfidence,
        magnitude: d.severity,
        params: [
          _p('field_id', 'field_id', d.fieldId),
          _p('direction', 'direction', 'a_evaluates_b'),
          _p('normalized_score', 'normalized_score', d.severity),
          _p('severity_band', 'severity_band', d.severityBand),
        ],
        refs: [
          _ref(
            type: 'DirectionalSoftConflictSignal',
            fp: soft.deterministicFingerprint,
            path: 'soft.a_to_b.${d.fieldId}',
            status: d.severityBand,
            configVersion: soft.configVersion,
            nums: {'severity': d.severity},
          ),
        ],
        diags: d.evidenceConfidence < config.moderateConfidenceThreshold
            ? const ['soft_conflict_evidence_limited']
            : const ['soft_conflicts_diagnostic_only'],
      ));
    }
    return out;
  }

  List<_Cand> _structural(
    StructuralProfileSimilarityResult? structural,
    CanonicalDimensionRegistry dims,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    if (structural == null) return const [];
    final out = <_Cand>[];
    void module(StructuralModuleSimilarityResult? m, String sourceType,
        String componentId) {
      if (m == null) return;
      if (m.status == StructuralModuleStatus.insufficientEvidence) {
        out.add(_code(
          code: 'structural_module_insufficient',
          config: config,
          registry: registry,
          sourceType: sourceType,
          sourceComponentId: componentId,
          module: m.module.wire,
          salience: 0.7,
          confidence: m.evidenceConfidence,
          magnitude: null,
          params: [
            _p('module_id', 'module_id', m.module.wire),
            _p('status_code', 'status_code', m.status.wire),
          ],
          refs: [
            _ref(
              type: 'StructuralModuleSimilarityResult',
              fp: structural.deterministicFingerprint,
              path: 'structural.${m.module.wire}',
              status: m.status.wire,
              configVersion: m.configVersion,
              nums: {'coverage': m.weightedCoverage},
            ),
          ],
          diags: const [],
        ));
        return;
      }
      if (m.status == StructuralModuleStatus.partial) {
        out.add(_code(
          code: 'structural_module_partial_coverage',
          config: config,
          registry: registry,
          sourceType: sourceType,
          sourceComponentId: componentId,
          module: m.module.wire,
          salience: 0.55,
          confidence: m.evidenceConfidence,
          magnitude: m.weightedCoverage,
          params: [
            _p('module_id', 'module_id', m.module.wire),
            _p('normalized_score', 'normalized_score', m.weightedCoverage),
            _p('count', 'count', m.comparableDimensionCount),
          ],
          refs: [
            _ref(
              type: 'StructuralModuleSimilarityResult',
              fp: structural.deterministicFingerprint,
              path: 'structural.${m.module.wire}.coverage',
              status: m.status.wire,
              configVersion: m.configVersion,
              nums: {'weighted_coverage': m.weightedCoverage},
            ),
          ],
          diags: const [],
        ));
      } else if (m.weightedCoverage >= 0.85) {
        out.add(_code(
          code: 'structural_module_high_coverage',
          config: config,
          registry: registry,
          sourceType: sourceType,
          sourceComponentId: componentId,
          module: m.module.wire,
          salience: 0.35,
          confidence: m.evidenceConfidence,
          magnitude: m.weightedCoverage,
          params: [
            _p('module_id', 'module_id', m.module.wire),
            _p('normalized_score', 'normalized_score', m.weightedCoverage),
          ],
          refs: [
            _ref(
              type: 'StructuralModuleSimilarityResult',
              fp: structural.deterministicFingerprint,
              path: 'structural.${m.module.wire}.coverage',
              status: m.status.wire,
              configVersion: m.configVersion,
              nums: {'weighted_coverage': m.weightedCoverage},
            ),
          ],
          diags: const [],
        ));
      }

      for (final e in m.excludedDimensions) {
        out.add(_code(
          code: 'structural_dimension_excluded',
          config: config,
          registry: registry,
          sourceType: sourceType,
          sourceComponentId: componentId,
          dimensionId: e.dimensionId,
          module: m.module.wire,
          salience: 0.3,
          confidence: null,
          magnitude: null,
          params: [
            _p('dimension_id', 'dimension_id', e.dimensionId),
            _p('module_id', 'module_id', m.module.wire),
            _p('status_code', 'status_code', e.reasonCode),
          ],
          refs: [
            _ref(
              type: 'StructuralSimilarityExclusion',
              fp: structural.deterministicFingerprint,
              path: 'structural.${m.module.wire}.excluded.${e.dimensionId}',
              status: e.reasonCode,
              configVersion: m.configVersion,
              nums: const {},
            ),
          ],
          diags: const [],
        ));
      }

      final sumW = m.dimensionComparisons
          .fold<double>(0, (a, c) => a + c.effectiveWeight);
      if (sumW <= 0) return;
      for (final c in m.dimensionComparisons) {
        final wNorm = c.effectiveWeight / sumW;
        final delta = c.absoluteDifference;
        final q = c.pairConfidence;
        if (q < config.minimumSignalConfidence) continue;
        final lowQ = q < config.moderateConfidenceThreshold;
        if (delta <= config.structuralCloseThreshold) {
          final mag = (1 - delta).clamp(0.0, 1.0);
          final sal = (wNorm * mag).clamp(0.0, 1.0);
          out.add(_code(
            code: lowQ
                ? 'structural_dimension_close_low_confidence'
                : 'structural_dimension_close',
            config: config,
            registry: registry,
            sourceType: sourceType,
            sourceComponentId: componentId,
            dimensionId: c.dimensionId,
            module: m.module.wire,
            salience: sal,
            confidence: q,
            magnitude: mag,
            params: [
              _p('dimension_id', 'dimension_id', c.dimensionId),
              _p('module_id', 'module_id', m.module.wire),
              _p('normalized_score', 'normalized_score', mag),
              _p('confidence', 'confidence', q),
              _p('confidence_band', 'confidence_band',
                  config.confidenceBand(q)),
            ],
            refs: [
              _ref(
                type: 'StructuralDimensionComparison',
                fp: structural.deterministicFingerprint,
                path: 'structural.${m.module.wire}.${c.dimensionId}',
                status: m.status.wire,
                configVersion: m.configVersion,
                nums: {
                  'absolute_difference': delta,
                  'pair_confidence': q,
                  'effective_weight': c.effectiveWeight,
                  'normalized_effective_weight': wNorm,
                },
              ),
            ],
            diags: const [
              'salience_normalized_effective_weight_times_magnitude',
            ],
            displayOrder: dims.dimensionsById[c.dimensionId]?.displayOrder,
          ));
        } else if (delta >= config.structuralDifferenceThreshold) {
          final mag = delta.clamp(0.0, 1.0);
          final sal = (wNorm * mag).clamp(0.0, 1.0);
          out.add(_code(
            code: lowQ
                ? 'structural_dimension_different_low_confidence'
                : 'structural_dimension_different',
            config: config,
            registry: registry,
            sourceType: sourceType,
            sourceComponentId: componentId,
            dimensionId: c.dimensionId,
            module: m.module.wire,
            salience: sal,
            confidence: q,
            magnitude: mag,
            params: [
              _p('dimension_id', 'dimension_id', c.dimensionId),
              _p('module_id', 'module_id', m.module.wire),
              _p('normalized_score', 'normalized_score', mag),
              _p('confidence', 'confidence', q),
              _p('confidence_band', 'confidence_band',
                  config.confidenceBand(q)),
            ],
            refs: [
              _ref(
                type: 'StructuralDimensionComparison',
                fp: structural.deterministicFingerprint,
                path: 'structural.${m.module.wire}.${c.dimensionId}',
                status: m.status.wire,
                configVersion: m.configVersion,
                nums: {
                  'absolute_difference': delta,
                  'pair_confidence': q,
                  'effective_weight': c.effectiveWeight,
                  'normalized_effective_weight': wNorm,
                },
              ),
            ],
            diags: const [
              'salience_normalized_effective_weight_times_magnitude',
            ],
            displayOrder: dims.dimensionsById[c.dimensionId]?.displayOrder,
          ));
        }
      }
    }

    module(structural.iq, 'structural_iq', 'iq_structural');
    module(structural.eq, 'structural_eq', 'eq_structural');
    module(
        structural.frequency, 'structural_frequency', 'frequency_structural');
    return out;
  }

  List<_Cand> _preference(
    MutualPreferenceFitResult? preference,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    if (preference == null) return const [];
    final out = <_Cand>[];

    void dir(DirectionalPreferenceFitResult d, String direction) {
      final sumW =
          d.dimensionFits.fold<double>(0, (a, f) => a + f.effectiveWeight);
      for (final f in d.dimensionFits) {
        final wNorm = sumW > 0 ? f.effectiveWeight / sumW : 0.0;
        final fit = f.rawDimensionFit;
        final q = f.evidenceConfidence;
        if (q < config.minimumSignalConfidence) {
          out.add(_code(
            code: 'partner_preference_low_evidence',
            config: config,
            registry: registry,
            sourceType: 'partner_preference',
            sourceComponentId: 'mutual_partner_preference',
            dimensionId: f.dimensionId,
            module: f.module.wire,
            direction: direction,
            salience: 0.35,
            confidence: q,
            magnitude: fit,
            params: [
              _p('dimension_id', 'dimension_id', f.dimensionId),
              _p('direction', 'direction', direction),
              _p('confidence', 'confidence', q),
              _p('confidence_band', 'confidence_band',
                  config.confidenceBand(q)),
            ],
            refs: [
              _ref(
                type: 'PreferenceDimensionFit',
                fp: preference.deterministicFingerprint,
                path: 'preference.$direction.${f.dimensionId}',
                status: 'low_evidence',
                configVersion: preference.configVersion,
                nums: {'raw_dimension_fit': fit, 'evidence_confidence': q},
              ),
            ],
            diags: const [],
          ));
          continue;
        }
        String code;
        double mag;
        if (fit >= config.preferenceStrongFitThreshold) {
          code = 'partner_preference_strongly_satisfied';
          mag = fit;
        } else if (fit <= config.preferenceWeakFitThreshold) {
          code = 'partner_preference_weakly_satisfied';
          mag = (1 - fit).clamp(0.0, 1.0);
        } else {
          code = 'partner_preference_partially_satisfied';
          mag = fit;
        }
        out.add(_code(
          code: code,
          config: config,
          registry: registry,
          sourceType: 'partner_preference',
          sourceComponentId: 'mutual_partner_preference',
          dimensionId: f.dimensionId,
          module: f.module.wire,
          direction: direction,
          salience: (wNorm * mag).clamp(0.0, 1.0),
          confidence: q,
          magnitude: mag,
          params: [
            _p('dimension_id', 'dimension_id', f.dimensionId),
            _p('direction', 'direction', direction),
            _p('normalized_score', 'normalized_score', fit),
            _p('confidence', 'confidence', q),
            _p('module_id', 'module_id', f.module.wire),
          ],
          refs: [
            _ref(
              type: 'PreferenceDimensionFit',
              fp: preference.deterministicFingerprint,
              path: 'preference.$direction.${f.dimensionId}',
              status: preference.status.wire,
              configVersion: preference.configVersion,
              nums: {
                'raw_dimension_fit': fit,
                'effective_weight': f.effectiveWeight,
                'normalized_effective_weight': wNorm,
              },
            ),
          ],
          diags: const ['uses_existing_preference_fit'],
        ));
      }
      for (final e in d.excludedPreferences) {
        final open = e.reasonCode.contains('open');
        final code =
            open ? 'partner_preference_open' : 'partner_preference_unavailable';
        out.add(_code(
          code: code,
          config: config,
          registry: registry,
          sourceType: 'partner_preference',
          sourceComponentId: 'mutual_partner_preference',
          dimensionId: e.dimensionId,
          direction: direction,
          salience: 0.25,
          confidence: null,
          magnitude: null,
          params: [
            _p('dimension_id', 'dimension_id', e.dimensionId),
            _p('direction', 'direction', direction),
            _p('status_code', 'status_code', e.reasonCode),
          ],
          refs: [
            _ref(
              type: 'DirectionalPreferenceFitExclusion',
              fp: preference.deterministicFingerprint,
              path: 'preference.$direction.excluded.${e.dimensionId}',
              status: e.reasonCode,
              configVersion: preference.configVersion,
              nums: const {},
            ),
          ],
          diags: const [],
        ));
      }
    }

    dir(preference.subjectAToBResult, 'a_evaluates_b');
    dir(preference.subjectBToAResult, 'b_evaluates_a');
    return out;
  }

  List<_Cand> _values(
    MutualRelationshipValueResult? values,
    RelationshipValueRegistry registryFields,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
    List<String> privacy,
  ) {
    if (values == null) return const [];
    final out = <_Cand>[];

    void dir(DirectionalRelationshipValueResult d, String direction) {
      final sumW =
          d.fieldComparisons.fold<double>(0, (a, f) => a + f.effectiveWeight);
      for (final f in d.fieldComparisons) {
        final fieldDef = registryFields.fieldsById[f.fieldId];
        if (fieldDef?.pendingContentReview == true) {
          out.add(_code(
            code: 'relationship_value_comparison_pending',
            config: config,
            registry: registry,
            sourceType: 'relationship_value',
            sourceComponentId: 'mutual_relationship_values',
            fieldId: f.fieldId,
            direction: direction,
            salience: 0.2,
            confidence: f.evidenceConfidence,
            magnitude: null,
            params: [
              _p('field_id', 'field_id', f.fieldId),
              _p('status_code', 'status_code', 'pending_review'),
            ],
            refs: [
              _ref(
                type: 'RelationshipValueFieldComparison',
                fp: values.deterministicFingerprint,
                path: 'values.$direction.${f.fieldId}',
                status: 'pending',
                configVersion: values.configVersion,
                nums: const {},
              ),
            ],
            diags: const ['pending_comparison_rule'],
          ));
          continue;
        }
        final wNorm = sumW > 0 ? f.effectiveWeight / sumW : 0.0;
        final fit = f.adjustedDirectionalFit;
        final q = f.evidenceConfidence;
        if (q < config.minimumSignalConfidence) continue;
        String code;
        double mag;
        if (fit >= config.valueStrongFitThreshold) {
          code = 'relationship_value_aligned';
          mag = fit;
        } else if (fit <= config.valueWeakFitThreshold) {
          code = 'relationship_value_difference';
          mag = (1 - fit).clamp(0.0, 1.0);
        } else {
          code = 'relationship_value_partially_aligned';
          mag = fit;
        }
        out.add(_code(
          code: code,
          config: config,
          registry: registry,
          sourceType: 'relationship_value',
          sourceComponentId: 'mutual_relationship_values',
          fieldId: f.fieldId,
          direction: direction,
          salience: (wNorm * mag).clamp(0.0, 1.0),
          confidence: q,
          magnitude: mag,
          params: [
            _p('field_id', 'field_id', f.fieldId),
            _p('direction', 'direction', direction),
            _p('normalized_score', 'normalized_score', fit),
            _p('confidence', 'confidence', q),
          ],
          refs: [
            _ref(
              type: 'RelationshipValueFieldComparison',
              fp: values.deterministicFingerprint,
              path: 'values.$direction.${f.fieldId}',
              status: values.status.wire,
              configVersion: values.configVersion,
              nums: {
                'adjusted_directional_fit': fit,
                'base_compatibility': f.baseCompatibility,
                'effective_weight': f.effectiveWeight,
                'normalized_effective_weight': wNorm,
              },
            ),
          ],
          diags: const ['uses_existing_value_fit', 'no_raw_private_values'],
        ));
      }
      for (final e in d.excludedFields) {
        final reason = e.reasonCode;
        String code;
        if (reason.contains('private') || reason.contains('visibility')) {
          code = 'relationship_value_private';
          privacy.add('private_value_redacted');
        } else if (reason.contains('permission')) {
          code = 'comparison_permission_denied';
          privacy.add('comparison_permission_redacted');
        } else if (reason.contains('pending')) {
          code = 'relationship_value_comparison_pending';
        } else {
          code = 'relationship_value_missing';
        }
        out.add(_code(
          code: code,
          config: config,
          registry: registry,
          sourceType: 'relationship_value',
          sourceComponentId: 'mutual_relationship_values',
          fieldId: e.fieldId,
          direction: direction,
          salience: 0.28,
          confidence: null,
          magnitude: null,
          params: [
            _p('field_id', 'field_id', e.fieldId),
            _p('status_code', 'status_code', reason),
            _p('direction', 'direction', direction),
          ],
          refs: [
            _ref(
              type: 'RelationshipValueComparisonExclusion',
              fp: values.deterministicFingerprint,
              path: 'values.$direction.excluded.${e.fieldId}',
              status: reason,
              configVersion: values.configVersion,
              nums: const {},
            ),
          ],
          diags: [
            if (code == 'relationship_value_private') 'private_value_redacted',
            if (code == 'comparison_permission_denied')
              'comparison_permission_redacted',
            'sensitive_parameter_omitted',
          ],
        ));
      }
    }

    dir(values.subjectAToBResult, 'a_evaluates_b');
    dir(values.subjectBToAResult, 'b_evaluates_a');
    return out;
  }

  List<_Cand> _aggregationEvidence(
    CoreMethodOverallScoreResult overall,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    final out = <_Cand>[];
    for (final c in overall.componentContributions) {
      if (c.inclusionStatus == CoreMethodComponentInclusionStatus.excluded &&
          (c.exclusionReason == 'component_missing' ||
              c.diagnosticCodes.contains('component_missing'))) {
        out.add(_code(
          code: 'component_missing',
          config: config,
          registry: registry,
          sourceType: 'aggregation',
          sourceComponentId: c.componentId,
          salience: 0.6,
          confidence: null,
          magnitude: null,
          params: [
            _p('component_id', 'component_id', c.componentId),
            _p('status_code', 'status_code', 'component_missing'),
          ],
          refs: [
            _ref(
              type: 'CoreMethodComponentContribution',
              fp: overall.deterministicFingerprint,
              path: 'overall.components.${c.componentId}',
              status: c.sourceStatus,
              configVersion: overall.configVersion,
              nums: {'configured_weight': c.configuredWeight},
            ),
          ],
          diags: const [],
        ));
      }
      if (c.inclusionStatus == CoreMethodComponentInclusionStatus.included &&
          (c.componentEvidenceConfidence ?? 1) <
              config.moderateConfidenceThreshold) {
        out.add(_code(
          code: 'component_low_confidence',
          config: config,
          registry: registry,
          sourceType: 'evidence_coverage',
          sourceComponentId: c.componentId,
          salience: 0.5,
          confidence: c.componentEvidenceConfidence,
          magnitude: c.componentEvidenceConfidence,
          params: [
            _p('component_id', 'component_id', c.componentId),
            _p('confidence', 'confidence', c.componentEvidenceConfidence),
            _p(
              'confidence_band',
              'confidence_band',
              config.confidenceBand(c.componentEvidenceConfidence),
            ),
          ],
          refs: [
            _ref(
              type: 'CoreMethodComponentContribution',
              fp: overall.deterministicFingerprint,
              path: 'overall.components.${c.componentId}.confidence',
              status: c.sourceStatus,
              configVersion: overall.configVersion,
              nums: {
                'component_evidence_confidence': c.componentEvidenceConfidence,
              },
            ),
          ],
          diags: const [],
        ));
      }
      if (c.sourceStatus == 'partial' &&
          c.inclusionStatus == CoreMethodComponentInclusionStatus.included) {
        out.add(_code(
          code: 'component_partial',
          config: config,
          registry: registry,
          sourceType: 'evidence_coverage',
          sourceComponentId: c.componentId,
          salience: 0.4,
          confidence: c.componentEvidenceConfidence,
          magnitude: null,
          params: [
            _p('component_id', 'component_id', c.componentId),
            _p('status_code', 'status_code', 'partial'),
          ],
          refs: [
            _ref(
              type: 'CoreMethodComponentContribution',
              fp: overall.deterministicFingerprint,
              path: 'overall.components.${c.componentId}.status',
              status: c.sourceStatus,
              configVersion: overall.configVersion,
              nums: const {},
            ),
          ],
          diags: const [],
        ));
      }
    }
    if (overall.availableConfiguredWeightMass < 0.75 &&
        overall.availableConfiguredWeightMass > 0) {
      out.add(_code(
        code: 'limited_available_weight_mass',
        config: config,
        registry: registry,
        sourceType: 'evidence_coverage',
        sourceComponentId: 'aggregation',
        salience: 0.55,
        confidence: overall.overallEvidenceConfidence,
        magnitude: overall.availableConfiguredWeightMass,
        params: [
          _p('normalized_score', 'normalized_score',
              overall.availableConfiguredWeightMass),
          _p('count', 'count', overall.availableComponentCount),
        ],
        refs: [
          _ref(
            type: 'CoreMethodOverallScoreResult',
            fp: overall.deterministicFingerprint,
            path: 'overall.m_available',
            status: overall.evaluationStatus.wire,
            configVersion: overall.configVersion,
            nums: {'m_available': overall.availableConfiguredWeightMass},
          ),
        ],
        diags: const [],
      ));
    }
    if (overall.evaluationStatus ==
        CompatibilityEvaluationStatus.insufficientEvidence) {
      if (overall.diagnosticCodes
          .contains('available_component_count_below_minimum')) {
        out.add(_code(
          code: 'insufficient_component_count',
          config: config,
          registry: registry,
          sourceType: 'evidence_coverage',
          sourceComponentId: 'aggregation',
          salience: 0.88,
          confidence: overall.overallEvidenceConfidence,
          magnitude: null,
          params: [
            _p('count', 'count', overall.availableComponentCount),
            _p('status_code', 'status_code', 'insufficient_evidence'),
          ],
          refs: [
            _ref(
              type: 'CoreMethodOverallScoreResult',
              fp: overall.deterministicFingerprint,
              path: 'overall.available_component_count',
              status: overall.evaluationStatus.wire,
              configVersion: overall.configVersion,
              nums: {
                'available_component_count':
                    overall.availableComponentCount.toDouble(),
              },
            ),
          ],
          diags: const ['no_fabricated_neutral_explanation'],
        ));
      }
      if (overall.diagnosticCodes
          .contains('available_weight_mass_below_minimum')) {
        out.add(_code(
          code: 'insufficient_component_weight',
          config: config,
          registry: registry,
          sourceType: 'evidence_coverage',
          sourceComponentId: 'aggregation',
          salience: 0.88,
          confidence: overall.overallEvidenceConfidence,
          magnitude: overall.availableConfiguredWeightMass,
          params: [
            _p('normalized_score', 'normalized_score',
                overall.availableConfiguredWeightMass),
            _p('status_code', 'status_code', 'insufficient_evidence'),
          ],
          refs: [
            _ref(
              type: 'CoreMethodOverallScoreResult',
              fp: overall.deterministicFingerprint,
              path: 'overall.m_available',
              status: overall.evaluationStatus.wire,
              configVersion: overall.configVersion,
              nums: {'m_available': overall.availableConfiguredWeightMass},
            ),
          ],
          diags: const ['no_fabricated_neutral_explanation'],
        ));
      }
    }
    if (overall.availableConfiguredWeightMass < 1.0 ||
        (overall.overallEvidenceConfidence ?? 1) < 0.85) {
      out.add(_code(
        code: 'explanation_evidence_limited',
        config: config,
        registry: registry,
        sourceType: 'evidence_coverage',
        sourceComponentId: 'aggregation',
        salience: 0.32,
        confidence: overall.overallEvidenceConfidence,
        magnitude: overall.overallEvidenceConfidence,
        params: [
          _p('status_code', 'status_code', 'evidence_limited'),
          _p('count', 'count', overall.availableComponentCount),
        ],
        refs: [
          _ref(
            type: 'CoreMethodOverallScoreResult',
            fp: overall.deterministicFingerprint,
            path: 'overall.evidence',
            status: overall.evaluationStatus.wire,
            configVersion: overall.configVersion,
            nums: {
              'q_overall': overall.overallEvidenceConfidence,
              'm_available': overall.availableConfiguredWeightMass,
            },
          ),
        ],
        diags: const [],
      ));
    }
    return out;
  }

  List<_Cand> _asymmetry(
    MutualPreferenceFitResult? preference,
    RelationshipCompatibilityLayerResult? layer,
    StructuredExplanationConfig config,
    StructuredExplanationCodeRegistry registry,
  ) {
    final out = <_Cand>[];
    final prefA = preference?.directionalAsymmetry;
    if (prefA != null && prefA >= config.asymmetryReportingThreshold) {
      out.add(_code(
        code: 'partner_preference_directional_asymmetry',
        config: config,
        registry: registry,
        sourceType: 'partner_preference',
        sourceComponentId: 'mutual_partner_preference',
        salience: prefA.clamp(0.0, 1.0),
        confidence: preference?.mutualEvidenceConfidence,
        magnitude: prefA,
        params: [
          _p('normalized_score', 'normalized_score', prefA),
          if (preference?.mutualEvidenceConfidence != null)
            _p('confidence', 'confidence',
                preference!.mutualEvidenceConfidence),
        ],
        refs: [
          _ref(
            type: 'MutualPreferenceFitResult',
            fp: preference?.deterministicFingerprint,
            path: 'preference.directional_asymmetry',
            status: preference?.status.wire ?? '',
            configVersion: preference?.configVersion,
            nums: {'directional_asymmetry': prefA},
          ),
        ],
        diags: const ['asymmetry_diagnostic_only', 'no_asymmetry_penalty'],
      ));
    }
    final valA = layer?.mutualValueResult.directionalAsymmetry;
    if (valA != null && valA >= config.asymmetryReportingThreshold) {
      out.add(_code(
        code: 'relationship_value_directional_asymmetry',
        config: config,
        registry: registry,
        sourceType: 'relationship_value',
        sourceComponentId: 'mutual_relationship_values',
        salience: valA.clamp(0.0, 1.0),
        confidence: layer?.mutualValueResult.mutualEvidenceConfidence,
        magnitude: valA,
        params: [_p('normalized_score', 'normalized_score', valA)],
        refs: [
          _ref(
            type: 'MutualRelationshipValueResult',
            fp: layer?.mutualValueResult.deterministicFingerprint,
            path: 'values.directional_asymmetry',
            status: layer?.mutualValueResult.status.wire ?? '',
            configVersion: layer?.mutualValueResult.configVersion,
            nums: {'directional_asymmetry': valA},
          ),
        ],
        diags: const ['asymmetry_diagnostic_only', 'no_asymmetry_penalty'],
      ));
    }
    return out;
  }

  List<_Cand> _dedupe(List<_Cand> input) {
    final map = <String, _Cand>{};
    for (final c in input) {
      final key = [
        c.explanationCode,
        c.sourceType,
        c.sourceComponentId,
        c.dimensionId ?? '',
        c.fieldId ?? '',
        c.direction ?? '',
      ].join('|');
      final existing = map[key];
      if (existing == null || c.salience > existing.salience) {
        map[key] = c;
      }
    }
    return map.values.toList();
  }

  List<_Cand> _rankAndCap(
    List<_Cand> input,
    StructuredExplanationConfig config,
    CanonicalDimensionRegistry dims,
  ) {
    final sorted = [...input];
    sorted.sort((a, b) {
      if (a.blocking != b.blocking) return a.blocking ? -1 : 1;
      final s = b.salience.compareTo(a.salience);
      if (s != 0) return s;
      final qa = a.confidence ?? -1;
      final qb = b.confidence ?? -1;
      final cq = qb.compareTo(qa);
      if (cq != 0) return cq;
      final ca = _categoryOf(a.explanationCode);
      final cb = _categoryOf(b.explanationCode);
      final pa = config.categoryPriority.indexOf(ca);
      final pb = config.categoryPriority.indexOf(cb);
      final cp = (pa < 0 ? 99 : pa).compareTo(pb < 0 ? 99 : pb);
      if (cp != 0) return cp;
      final oa = config.sourceComponentOrder.indexOf(a.sourceComponentId);
      final ob = config.sourceComponentOrder.indexOf(b.sourceComponentId);
      final co = (oa < 0 ? 99 : oa).compareTo(ob < 0 ? 99 : ob);
      if (co != 0) return co;
      final da = a.displayOrder ??
          dims.dimensionsById[a.dimensionId ?? '']?.displayOrder ??
          9999;
      final db = b.displayOrder ??
          dims.dimensionsById[b.dimensionId ?? '']?.displayOrder ??
          9999;
      final cd = da.compareTo(db);
      if (cd != 0) return cd;
      final fa = a.fieldId ?? a.dimensionId ?? '';
      final fb = b.fieldId ?? b.dimensionId ?? '';
      final cf = fa.compareTo(fb);
      if (cf != 0) return cf;
      return a.signalId.compareTo(b.signalId);
    });

    // Diversity: ensure at least one supportive and one cautionary when present
    // after caps — applied during selection.
    final selected = <_Cand>[];
    final perCat = <String, int>{};
    final perMod = <String, int>{};
    var hasSupportive = false;
    var hasCautionary = false;

    void tryAdd(_Cand c) {
      if (selected.length >= config.maximumTotalSignals) return;
      final cat = _categoryOf(c.explanationCode);
      final catCount = perCat[cat] ?? 0;
      if (!c.blocking && catCount >= config.maximumSignalsPerCategory) return;
      final mod = c.module;
      if (mod != null && !c.blocking) {
        final mc = perMod[mod] ?? 0;
        if (mc >= config.maximumSignalsPerModule) return;
      }
      selected.add(c);
      perCat[cat] = catCount + 1;
      if (mod != null) perMod[mod] = (perMod[mod] ?? 0) + 1;
      final pol = _polarityOf(c.explanationCode);
      if (pol == 'supportive') hasSupportive = true;
      if (pol == 'cautionary') hasCautionary = true;
    }

    // Blocking first always.
    for (final c in sorted.where((c) => c.blocking)) {
      tryAdd(c);
    }
    for (final c in sorted.where((c) => !c.blocking)) {
      tryAdd(c);
    }

    // Diversity backfill if space remains.
    if (config.diversityPolicy.contains('supportive_and_cautionary')) {
      if (!hasSupportive) {
        final s = sorted.where((c) =>
            !c.blocking &&
            _polarityOf(c.explanationCode) == 'supportive' &&
            !selected.contains(c));
        for (final c in s) {
          if (selected.length >= config.maximumTotalSignals) break;
          // Force replace lowest non-blocking if needed — keep simple: add if room.
          tryAdd(c);
          break;
        }
      }
      if (!hasCautionary) {
        final s = sorted.where((c) =>
            !c.blocking &&
            _polarityOf(c.explanationCode) == 'cautionary' &&
            !selected.contains(c));
        for (final c in s) {
          if (selected.length >= config.maximumTotalSignals) break;
          tryAdd(c);
          break;
        }
      }
    }

    // Re-sort selected with same comparator for stable ranks.
    selected.sort((a, b) {
      if (a.blocking != b.blocking) return a.blocking ? -1 : 1;
      final s = b.salience.compareTo(a.salience);
      if (s != 0) return s;
      return a.signalId.compareTo(b.signalId);
    });
    return selected;
  }

  String _categoryOf(String code) {
    if (code.startsWith('overall_')) return 'overall_status';
    if (code.startsWith('structural_dimension_close')) {
      return 'strong_alignment';
    }
    if (code.startsWith('structural_dimension_different')) {
      return 'measured_difference';
    }
    if (code.startsWith('structural_')) return 'evidence_limitation';
    if (code.startsWith('partner_preference_directional')) {
      return 'directional_asymmetry';
    }
    if (code.startsWith('partner_preference_open') ||
        code.startsWith('partner_preference_unavailable')) {
      return 'missing_information';
    }
    if (code.startsWith('partner_preference_')) return 'partner_preference_fit';
    if (code.startsWith('relationship_value_directional')) {
      return 'directional_asymmetry';
    }
    if (code.startsWith('relationship_value_comparison') ||
        code.startsWith('relationship_value_missing') ||
        code.startsWith('relationship_value_private') ||
        code == 'comparison_permission_denied') {
      return 'missing_information';
    }
    if (code.startsWith('relationship_value_')) {
      return 'relationship_value_alignment';
    }
    if (code.startsWith('soft_conflict_')) return 'soft_conflict';
    if (code.startsWith('hard_constraint_')) return 'hard_constraint';
    if (code == 'component_missing' || code == 'relationship_value_missing') {
      return 'missing_information';
    }
    if (code.startsWith('component_') ||
        code.startsWith('insufficient_') ||
        code.startsWith('limited_') ||
        code.startsWith('explanation_evidence')) {
      return 'evidence_limitation';
    }
    if (code.startsWith('score_shrunk')) return 'confidence_adjustment';
    if (code.startsWith('production_')) return 'production_limitation';
    return 'evidence_limitation';
  }

  String _polarityOf(String code) {
    if (code.contains('failed') || code.contains('blocked')) return 'blocking';
    if (code.contains('strong') ||
        (code.contains('aligned') && !code.contains('partial')) ||
        code.contains('close') ||
        (code.contains('passed') && code.contains('hard'))) {
      return 'supportive';
    }
    if (code.contains('weak') ||
        code.contains('different') ||
        code.contains('difference') ||
        code.contains('soft_conflict') ||
        code.contains('unknown') ||
        code.contains('asymmetry') ||
        code.contains('low_confidence') ||
        code.contains('partial_coverage') ||
        code.contains('limited')) {
      return 'cautionary';
    }
    if (code.contains('missing') ||
        code.contains('open') ||
        code.contains('unavailable') ||
        code.contains('private') ||
        code.contains('denied') ||
        code.contains('pending') ||
        code.contains('insufficient') ||
        code.contains('invalid')) {
      return 'unavailable';
    }
    return 'neutral';
  }

  _Cand _code({
    required String code,
    required StructuredExplanationConfig config,
    required StructuredExplanationCodeRegistry registry,
    required String sourceType,
    required String sourceComponentId,
    required double salience,
    required double? confidence,
    required double? magnitude,
    required List<StructuredExplanationParameter> params,
    required List<StructuredExplanationEvidenceReference> refs,
    required List<String> diags,
    String? dimensionId,
    String? fieldId,
    String? module,
    String? direction,
    bool blocking = false,
    int? displayOrder,
    String? signalIdOverride,
  }) {
    registry.require(code);
    final id = signalIdOverride ??
        [
          code,
          sourceComponentId,
          dimensionId ?? '',
          fieldId ?? '',
          direction ?? '',
        ].join('__');
    return _Cand(
      signalId: id,
      explanationCode: code,
      sourceType: sourceType,
      sourceComponentId: sourceComponentId,
      dimensionId: dimensionId,
      fieldId: fieldId,
      module: module,
      direction: direction,
      salience: salience.clamp(0.0, 1.0),
      confidence: confidence,
      magnitude: magnitude,
      params: params,
      refs: refs,
      diags: [...diags]..sort(),
      blocking: blocking || registry.require(code).blockingEligibility,
      displayOrder: displayOrder,
    );
  }

  StructuredExplanationParameter _p(String name, String type, Object? value) =>
      StructuredExplanationParameter(name: name, type: type, value: value);

  StructuredExplanationEvidenceReference _ref({
    required String type,
    required String? fp,
    required String path,
    required String status,
    required String? configVersion,
    required Map<String, double?> nums,
  }) =>
      StructuredExplanationEvidenceReference(
        sourceResultType: type,
        sourceResultFingerprint: fp,
        sourcePath: path,
        relevantNumericFields: nums,
        sourceStatus: status,
        sourceConfigVersion: configVersion,
      );
}

class _Cand {
  final String signalId;
  final String explanationCode;
  final String sourceType;
  final String sourceComponentId;
  final String? dimensionId;
  final String? fieldId;
  final String? module;
  final String? direction;
  final double salience;
  final double? confidence;
  final double? magnitude;
  final List<StructuredExplanationParameter> params;
  final List<StructuredExplanationEvidenceReference> refs;
  final List<String> diags;
  final bool blocking;
  final int? displayOrder;

  const _Cand({
    required this.signalId,
    required this.explanationCode,
    required this.sourceType,
    required this.sourceComponentId,
    required this.dimensionId,
    required this.fieldId,
    required this.module,
    required this.direction,
    required this.salience,
    required this.confidence,
    required this.magnitude,
    required this.params,
    required this.refs,
    required this.diags,
    required this.blocking,
    required this.displayOrder,
  });
}
