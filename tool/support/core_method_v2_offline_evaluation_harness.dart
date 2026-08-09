// Offline end-to-end Core Method v2 evaluation harness.
// CLI/test-only. Calls existing pure services sequentially — no formula duplication.
// Does not produce Firestore objects, production rankings, or live matches.

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

class OfflineEvaluationBundle {
  final String subjectAId;
  final String subjectBId;
  final StructuralProfileSimilarityResult structural;
  final MutualPreferenceFitResult preference;
  final MutualRelationshipValueResult values;
  final MutualHardConstraintResult hard;
  final SoftConflictEvaluationResult soft;
  final RelationshipCompatibilityLayerResult relationshipLayer;
  final CoreMethodV2EvaluationResult evaluation;
  final StructuredCompatibilityExplanationResult? explanation;
  final List<String> diagnosticCodes;
  final bool producedProductionRankingAction;
  final bool producedLiveMatchAction;
  final bool wroteFirestore;
  final Object? unexpectedException;

  OfflineEvaluationBundle({
    required this.subjectAId,
    required this.subjectBId,
    required this.structural,
    required this.preference,
    required this.values,
    required this.hard,
    required this.soft,
    required this.relationshipLayer,
    required this.evaluation,
    required this.explanation,
    required this.diagnosticCodes,
    this.producedProductionRankingAction = false,
    this.producedLiveMatchAction = false,
    this.wroteFirestore = false,
    this.unexpectedException,
  });

  CoreMethodOverallScoreResult get overall => evaluation.overallScoreResult;

  Map<String, dynamic> metricsJson() {
    final o = overall;
    return {
      'subject_a_id': subjectAId,
      'subject_b_id': subjectBId,
      'iq_structural': structural.iq?.similarityScore,
      'eq_structural': structural.eq?.similarityScore,
      'frequency_structural': structural.frequency?.similarityScore,
      'iq_structural_fp':
          structural.iq != null ? structural.deterministicFingerprint : null,
      'structural_fingerprint': structural.deterministicFingerprint,
      'preference_fingerprint': preference.deterministicFingerprint,
      'values_fingerprint': values.deterministicFingerprint,
      'hard_fingerprint': hard.deterministicFingerprint,
      'soft_fingerprint': soft.deterministicFingerprint,
      'layer_fingerprint': relationshipLayer.deterministicFingerprint,
      'evaluation_fingerprint': evaluation.deterministicFingerprint,
      'overall_fingerprint': o.deterministicFingerprint,
      'explanation_fingerprint': explanation?.deterministicFingerprint,
      'mutual_partner_preference': preference.mutualRawFitScore,
      'mutual_relationship_values': values.mutualRawValueFitScore,
      'raw_score': o.rawScore,
      'confidence_adjusted_score': o.confidenceAdjustedScore,
      'overall_evidence_confidence': o.overallEvidenceConfidence,
      'available_configured_weight_mass': o.availableConfiguredWeightMass,
      'hard_outcome': o.hardConstraintOutcome.wire,
      'evaluation_status': o.evaluationStatus.wire,
      'soft_signal_count': soft.mutualSignals.length,
      'ranking_eligible': o.rankingEligible,
      'live_ranking_eligible': o.liveRankingEligible,
      'production_publishable': o.productionPublishable,
      'produced_production_ranking_action': producedProductionRankingAction,
      'produced_live_match_action': producedLiveMatchAction,
      'wrote_firestore': wroteFirestore,
      'diagnostic_codes': diagnosticCodes,
      'unexpected_exception': unexpectedException?.toString(),
    };
  }
}

class CoreMethodV2OfflineEvaluationHarness {
  final CanonicalDimensionRegistry dimRegistry;
  final RelationshipValueRegistry valueRegistry;
  final StructuralSimilarityConfig structuralConfig;
  final PartnerPreferenceFitConfig preferenceConfig;
  final RelationshipValueComparisonConfig valueConfig;
  final CoreMethodAggregationConfig aggregationConfig;
  final StructuredExplanationConfig explanationConfig;
  final StructuredExplanationCodeRegistry explanationCodes;
  final DateTime evaluationTimestamp;

  final StructuralSimilarityService _structural;
  final DirectionalPreferenceFitService _preference;
  final RelationshipValueComparisonService _values;
  final HardConstraintEvaluationService _hard;
  final SoftConflictEvaluationService _soft;
  final CoreMethodV2AggregationService _aggregation;
  final StructuredCompatibilityExplanationService _explanation;

  CoreMethodV2OfflineEvaluationHarness({
    required this.dimRegistry,
    required this.valueRegistry,
    required this.structuralConfig,
    required this.preferenceConfig,
    required this.valueConfig,
    required this.aggregationConfig,
    required this.explanationConfig,
    required this.explanationCodes,
    required this.evaluationTimestamp,
    StructuralSimilarityService structural =
        const StructuralSimilarityService(),
    DirectionalPreferenceFitService preference =
        const DirectionalPreferenceFitService(),
    RelationshipValueComparisonService values =
        const RelationshipValueComparisonService(),
    HardConstraintEvaluationService hard =
        const HardConstraintEvaluationService(),
    SoftConflictEvaluationService soft = const SoftConflictEvaluationService(),
    CoreMethodV2AggregationService aggregation =
        const CoreMethodV2AggregationService(),
    StructuredCompatibilityExplanationService explanation =
        const StructuredCompatibilityExplanationService(),
  })  : _structural = structural,
        _preference = preference,
        _values = values,
        _hard = hard,
        _soft = soft,
        _aggregation = aggregation,
        _explanation = explanation;

  /// Full pipeline. Optionally skip explanation for cheaper sweeps.
  OfflineEvaluationBundle evaluatePair({
    required CompatibilitySubjectSnapshot subjectA,
    required CompatibilitySubjectSnapshot subjectB,
    bool includeExplanation = true,
    StructuralSimilarityConfig? structuralConfigOverride,
    PartnerPreferenceFitConfig? preferenceConfigOverride,
    RelationshipValueComparisonConfig? valueConfigOverride,
    CoreMethodAggregationConfig? aggregationConfigOverride,
  }) {
    try {
      final structural = _structural.compare(
        subjectA: subjectA.assessmentProfile,
        subjectB: subjectB.assessmentProfile,
        registry: dimRegistry,
        config: structuralConfigOverride ?? structuralConfig,
        evaluationTimestamp: evaluationTimestamp,
      );
      final preference = _preference.evaluateMutual(
        subjectA: subjectA,
        subjectB: subjectB,
        registry: dimRegistry,
        config: preferenceConfigOverride ?? preferenceConfig,
        evaluationTimestamp: evaluationTimestamp,
      );
      final values = _values.evaluateMutual(
        subjectA: subjectA,
        subjectB: subjectB,
        registry: valueRegistry,
        config: valueConfigOverride ?? valueConfig,
      );
      final hard = _hard.evaluateMutual(
        subjectA: subjectA,
        subjectB: subjectB,
        registry: valueRegistry,
        config: valueConfigOverride ?? valueConfig,
      );
      final soft = _soft.evaluate(
        mutualValues: values,
        config: valueConfigOverride ?? valueConfig,
      );
      final layer = RelationshipCompatibilityLayerResult.assemble(
        mutualValueResult: values,
        mutualHardConstraintResult: hard,
        softConflictResult: soft,
      );
      // Offline interop only: relationship-value results carry
      // relationship_value_registry_v1 while aggregation/explanation configs are
      // keyed to canonical_dimension_registry_v1. Source `layer` in the bundle
      // remains the authentic service output; aggregation/explanation receive a
      // non-mutating namespace view so pipeline math can be evaluated offline.
      final layerForAgg = _dimensionRegistryNamespaceView(layer);
      final evaluation = _aggregation.evaluate(
        structural: structural,
        preference: preference,
        relationshipLayer: layerForAgg,
        config: aggregationConfigOverride ?? aggregationConfig,
        evaluationTimestamp: evaluationTimestamp,
      );
      StructuredCompatibilityExplanationResult? explanation;
      final diags = <String>[
        ...evaluation.overallScoreResult.diagnosticCodes,
      ];
      if (layer.registryVersion != aggregationConfig.registryVersion) {
        diags.add('aggregation_registry_namespace_view_applied');
      }
      if (includeExplanation) {
        final layerForExplain = _dimensionRegistryNamespaceView(layer);
        explanation = _explanation.explain(
          structural: structural,
          preference: preference,
          relationshipLayer: layerForExplain,
          evaluation: evaluation,
          dimensionRegistry: dimRegistry,
          valueRegistry: valueRegistry,
          config: explanationConfig,
          codeRegistry: explanationCodes,
          generatedAt: evaluationTimestamp,
        );
        diags.add('explanation_generated');
        if (layer.registryVersion != explanationConfig.registryVersion) {
          diags.add('explanation_registry_namespace_view_applied');
        }
      }
      diags.sort();
      return OfflineEvaluationBundle(
        subjectAId: subjectA.subjectId,
        subjectBId: subjectB.subjectId,
        structural: structural,
        preference: preference,
        values: values,
        hard: hard,
        soft: soft,
        relationshipLayer: layer,
        evaluation: evaluation,
        explanation: explanation,
        diagnosticCodes: diags,
      );
    } catch (e) {
      // Unexpected exceptions are surfaced to the robustness validator.
      rethrow;
    }
  }

  StructuralProfileSimilarityResult evaluateStructuralOnly({
    required CompatibilitySubjectSnapshot subjectA,
    required CompatibilitySubjectSnapshot subjectB,
    StructuralSimilarityConfig? configOverride,
  }) =>
      _structural.compare(
        subjectA: subjectA.assessmentProfile,
        subjectB: subjectB.assessmentProfile,
        registry: dimRegistry,
        config: configOverride ?? structuralConfig,
        evaluationTimestamp: evaluationTimestamp,
      );

  /// Non-mutating view aligning relationship-layer registry namespace to the
  /// dimension-registry namespace expected by aggregation/explanation configs.
  RelationshipCompatibilityLayerResult _dimensionRegistryNamespaceView(
    RelationshipCompatibilityLayerResult layer,
  ) {
    final target = aggregationConfig.registryVersion;
    if (layer.registryVersion == target &&
        layer.mutualValueResult.registryVersion == target) {
      return layer;
    }
    final j = Map<String, dynamic>.from(layer.toJson());
    void setReg(Map<String, dynamic> m) {
      m['registry_version'] = target;
    }

    setReg(j);
    final mv = Map<String, dynamic>.from(j['mutual_value_result'] as Map);
    setReg(mv);
    for (final key in ['subject_a_to_b_result', 'subject_b_to_a_result']) {
      final raw = mv[key];
      if (raw is Map) {
        final d = Map<String, dynamic>.from(raw);
        setReg(d);
        mv[key] = d;
      }
    }
    j['mutual_value_result'] = mv;
    for (final key in [
      'mutual_hard_constraint_result',
      'soft_conflict_result',
    ]) {
      final raw = j[key];
      if (raw is Map) {
        final d = Map<String, dynamic>.from(raw);
        setReg(d);
        j[key] = d;
      }
    }
    return RelationshipCompatibilityLayerResult.fromJson(j);
  }
}
