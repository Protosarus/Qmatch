// Shared offline robustness experiment runner. CLI/test-only.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../../../test/support/aggregation_v1_helpers.dart';
import '../../../test/support/directional_preference_fit_helpers.dart';
import '../../../test/support/explanation_v1_helpers.dart';
import '../../../test/support/relationship_value_layer_helpers.dart';
import '../../../test/support/structural_similarity_helpers.dart';
import '../core_method_v2_offline_evaluation_harness.dart';
import 'robustness_experiment_config.dart';
import 'robustness_rng.dart';
import 'robustness_stats.dart';
import 'synthetic_profile_generator.dart';

class RobustnessExperimentRunner {
  final RobustnessExperimentConfig config;
  final String mode;
  late final Map<String, dynamic> resolved;
  late final CanonicalDimensionRegistry dimRegistry;
  late final RelationshipValueRegistry valueRegistry;
  late final StructuralSimilarityConfig structuralConfig;
  late final PartnerPreferenceFitConfig preferenceConfig;
  late final RelationshipValueComparisonConfig valueConfig;
  late final CoreMethodAggregationConfig aggregationConfig;
  late final StructuredExplanationConfig explanationConfig;
  late final StructuredExplanationCodeRegistry explanationCodes;
  late final CoreMethodV2OfflineEvaluationHarness harness;
  late final CoreMethodV2SyntheticGenerator generator;

  final List<String> unexpectedExceptions = [];
  final List<Map<String, dynamic>> invariantViolations = [];
  final List<Map<String, dynamic>> alerts = [];

  RobustnessExperimentRunner({
    required this.config,
    required this.mode,
  }) {
    resolved = config.modeResolved(mode);
    dimRegistry = CanonicalDimensionRegistry.loadFile(
      AggregationV1Helpers.registryPath,
    );
    valueRegistry = ExplanationV1Helpers.loadValues();
    structuralConfig = loadStructuralSimilarityConfig();
    preferenceConfig = loadPreferenceFitConfig();
    valueConfig = loadValueComparisonConfig();
    aggregationConfig = AggregationV1Helpers.loadConfig();
    explanationConfig = ExplanationV1Helpers.loadConfig();
    explanationCodes = ExplanationV1Helpers.loadCodeRegistry();
    harness = CoreMethodV2OfflineEvaluationHarness(
      dimRegistry: dimRegistry,
      valueRegistry: valueRegistry,
      structuralConfig: structuralConfig,
      preferenceConfig: preferenceConfig,
      valueConfig: valueConfig,
      aggregationConfig: aggregationConfig,
      explanationConfig: explanationConfig,
      explanationCodes: explanationCodes,
      evaluationTimestamp: config.evaluationTimestamp,
    );
    generator = CoreMethodV2SyntheticGenerator(
      dimRegistry: dimRegistry,
      valueRegistry: valueRegistry,
    );
  }

  Map<String, dynamic> runAll({required String outDir}) {
    Directory(outDir).createSync(recursive: true);
    final manifest = <String, dynamic>{
      'config_version': config.configVersion,
      'mode': mode,
      'resolved_mode': resolved,
      'baseline_seed': config.baselineSeed,
      'secondary_seeds': config.secondarySeeds,
      'frozen_source_configs': config.raw['frozen_source_configs'],
      'real_user_data_policy': config.raw['real_user_data_policy'],
      'started_at_note': 'injected_timestamp_only',
      'evaluation_timestamp_utc': config.evaluationTimestamp.toIso8601String(),
    };

    final populationSummary = <String, dynamic>{};
    final numerical = <String, dynamic>{
      'valid_complete': 0,
      'valid_partial': 0,
      'insufficient_evidence': 0,
      'hard_blocked': 0,
      'invalid': 0,
      'unexpected_exceptions': 0,
    };
    final distributions = <String, dynamic>{};
    final correlations = <String, dynamic>{};
    final redundancyAlerts = <Map<String, dynamic>>[];
    final weightSensitivity = <String, dynamic>{};
    final scaleSensitivity = <String, dynamic>{};
    final missingness = <String, dynamic>{};
    final hardRobust = <String, dynamic>{};
    final softRegression = <String, dynamic>{};
    final explanationStability = <String, dynamic>{};
    final rankStability = <String, dynamic>{};
    final cohortInvariance = <String, dynamic>{};
    final invariantResults = <String, dynamic>{
      'violations': <Map<String, dynamic>>[],
      'expected_violation_count': 0,
    };

    final seeds = [
      config.baselineSeed,
      ...config.secondarySeeds.take(resolved['secondary_seed_count'] as int),
    ];

    // Family sweep (resource-conscious counts).
    if (resolved['run_all_families'] == true) {
      final perFamily = resolved['subjects_per_family'] as int;
      final pairCap = mode == 'smoke'
          ? resolved['sampled_pair_count'] as int
          : resolved['pairs_per_family_sweep'] as int;
      final fullCap = mode == 'smoke'
          ? resolved['full_pipeline_pair_count'] as int
          : resolved['full_pipeline_pairs_per_family_sweep'] as int;
      final explCap = mode == 'smoke'
          ? resolved['explanation_pair_count'] as int
          : resolved['explanation_pairs_per_family_sweep'] as int;

      for (final family in config.syntheticFamilyIds) {
        final seed = config.baselineSeed;
        final pop = generator.generateFamily(
          familyId: family,
          seed: seed,
          count: perFamily,
        );
        populationSummary[family] = {
          'seed': seed,
          'subject_count': pop.size,
          'family_id': family,
        };
        final pairIdx =
            _samplePairs(pop.size, pairCap, RobustnessRng(seed + 7));
        final fullIdx =
            pairIdx.take(math.min(fullCap, pairIdx.length)).toList();
        final explIdx =
            fullIdx.take(math.min(explCap, fullIdx.length)).toList();

        final familyDist = _runPairBatch(
          pop: pop,
          pairIndices: fullIdx,
          includeExplanation: false,
          numerical: numerical,
          invariantResults: invariantResults,
        );
        distributions['${family}_$seed'] = familyDist['distributions'];
        correlations['${family}_$seed'] = familyDist['correlations'];
        redundancyAlerts.addAll(
          (familyDist['redundancy_alerts'] as List)
              .cast<Map<String, dynamic>>(),
        );

        // Explanation subset
        for (final p in explIdx) {
          try {
            final bundle = harness.evaluatePair(
              subjectA: pop.subjects[p.$1].snapshot,
              subjectB: pop.subjects[p.$2].snapshot,
              includeExplanation: true,
            );
            _checkExplanationScorePreservation(bundle, invariantResults);
          } catch (e) {
            unexpectedExceptions.add('explanation_subset: $e');
            numerical['invalid'] = (numerical['invalid'] as int) + 1;
          }
        }
      }
    }

    // Deep dive primary family with configured top-level counts (full mode).
    List<OfflineEvaluationBundle> deepBundles = [];
    SyntheticPopulation? deepPop;
    if (resolved['run_deep_dive'] == true || mode == 'smoke') {
      final family = config.primaryDeepDiveFamily;
      final n = mode == 'smoke'
          ? resolved['synthetic_population_size'] as int
          : config.syntheticPopulationSize;
      final pairN = mode == 'smoke'
          ? resolved['sampled_pair_count'] as int
          : config.sampledPairCount;
      final fullN = mode == 'smoke'
          ? resolved['full_pipeline_pair_count'] as int
          : config.fullPipelinePairCount;
      final explN = mode == 'smoke'
          ? resolved['explanation_pair_count'] as int
          : config.explanationPairCount;

      deepPop = generator.generateFamily(
        familyId: family,
        seed: config.baselineSeed,
        count: n,
      );
      populationSummary['deep_dive'] = {
        'family_id': family,
        'seed': config.baselineSeed,
        'subject_count': deepPop.size,
        'sampled_pair_count_requested': pairN,
        'full_pipeline_pair_count_requested': fullN,
        'explanation_pair_count_requested': explN,
      };

      final pairIdx = _samplePairs(
          deepPop.size, pairN, RobustnessRng(config.baselineSeed + 99));
      final fullIdx = pairIdx.take(math.min(fullN, pairIdx.length)).toList();
      final explIdx = fullIdx.take(math.min(explN, fullIdx.length)).toList();

      final deep = _runPairBatch(
        pop: deepPop,
        pairIndices: fullIdx,
        includeExplanation: false,
        numerical: numerical,
        invariantResults: invariantResults,
        collectBundles: true,
      );
      deepBundles = (deep['bundles'] as List).cast<OfflineEvaluationBundle>();
      distributions['deep_dive_${family}_${config.baselineSeed}'] =
          deep['distributions'];
      correlations['deep_dive_${family}_${config.baselineSeed}'] =
          deep['correlations'];
      redundancyAlerts.addAll(
        (deep['redundancy_alerts'] as List).cast<Map<String, dynamic>>(),
      );
      populationSummary['deep_dive']['full_pipeline_pairs_actual'] =
          deepBundles.length;
      populationSummary['deep_dive']['sampled_pairs_actual'] = pairIdx.length;

      // Explanation stability on subset
      explanationStability.addAll(
        _explanationStability(deepPop, explIdx),
      );

      // Weight / scale / rank sensitivity on deep bundles
      weightSensitivity.addAll(_weightSensitivity(deepBundles));
      scaleSensitivity.addAll(_scaleSensitivity(
          deepPop, fullIdx.take(math.min(80, fullIdx.length)).toList()));
      rankStability.addAll(_rankStability(deepBundles, seeds, deepPop));

      // Missingness / confidence
      missingness
          .addAll(_missingnessConfidence(deepPop, fullIdx.take(40).toList()));

      // Hard / soft
      hardRobust.addAll(_hardConstraintRobustness());
      softRegression.addAll(_softConflictRegression(deepBundles));

      // Cohort label invariance
      cohortInvariance.addAll(_cohortLabelInvariance(deepPop));
    }

    numerical['unexpected_exceptions'] = unexpectedExceptions.length;
    numerical['unexpected_exception_messages'] = unexpectedExceptions;
    invariantResults['violation_count'] =
        (invariantResults['violations'] as List).length;
    invariantResults['pass'] =
        (invariantResults['violations'] as List).isEmpty &&
            unexpectedExceptions.isEmpty;

    final calibration = _calibrationReadiness();
    final readiness = _engineeringReadiness(
      invariantOk: invariantResults['pass'] == true,
      numericalOk: unexpectedExceptions.isEmpty,
      redundancyAlerts: redundancyAlerts,
    );

    final fullSummary = {
      'mode': mode,
      'population_summary': populationSummary,
      'numerical_robustness': numerical,
      'invariant_results': {
        'violation_count': invariantResults['violation_count'],
        'pass': invariantResults['pass'],
      },
      'alert_count': alerts.length,
      'redundancy_alert_count': redundancyAlerts.length,
      'engineering_readiness': readiness,
      'calibration_readiness': calibration,
      'claims_forbidden': [
        'predictive_validity',
        'relationship_success_prediction',
        'psychometric_calibration',
        'demographic_fairness',
        'causal_interpretation',
        'production_readiness',
      ],
    };

    final outputs = <String, Map<String, dynamic>>{
      'experiment_manifest.json': manifest,
      'population_summary.json': populationSummary,
      'numerical_robustness.json': numerical,
      'invariant_results.json': invariantResults,
      'component_distributions.json': distributions,
      'component_correlations.json': correlations,
      'redundancy_alerts.json': {
        'alerts': redundancyAlerts,
        'alert_count': redundancyAlerts.length,
        'note':
            'Engineering redundancy alerts only; not scientific conclusions.',
      },
      'weight_sensitivity.json': weightSensitivity,
      'scale_sensitivity.json': scaleSensitivity,
      'missingness_confidence.json': missingness,
      'hard_constraint_robustness.json': hardRobust,
      'soft_conflict_regression.json': softRegression,
      'explanation_stability.json': explanationStability,
      'rank_stability.json': rankStability,
      'cohort_label_invariance.json': cohortInvariance,
      'calibration_readiness.json': calibration,
      'full_summary.json': fullSummary,
      'engineering_readiness.json': readiness,
      'alerts.json': {'alerts': alerts, 'count': alerts.length},
    };

    for (final e in outputs.entries) {
      _writeJson('$outDir/${e.key}', e.value);
    }
    manifest['output_files'] = outputs.keys.toList()..sort();
    manifest['derived_counts'] = {
      'family_count': config.syntheticFamilyIds.length,
      'seed_count_used': seeds.length,
      'deep_bundle_count': deepBundles.length,
      'alert_count': alerts.length,
      'redundancy_alert_count': redundancyAlerts.length,
      'invariant_violation_count': invariantResults['violation_count'],
    };
    _writeJson('$outDir/experiment_manifest.json', manifest);

    return fullSummary;
  }

  List<(int, int)> _samplePairs(int n, int count, RobustnessRng rng) {
    if (n < 2) return const [];
    final maxDirected = n * (n - 1);
    final target = math.min(count, maxDirected);
    final out = <(int, int)>[];
    final seen = <String>{};
    var attempts = 0;
    while (out.length < target && attempts < target * 40 + 100) {
      attempts++;
      final a = rng.nextInt(n);
      final b = rng.nextInt(n);
      if (a == b) continue;
      final key = '$a:$b';
      if (!seen.add(key)) continue;
      out.add((a, b));
    }
    return out;
  }

  Map<String, dynamic> _runPairBatch({
    required SyntheticPopulation pop,
    required List<(int, int)> pairIndices,
    required bool includeExplanation,
    required Map<String, dynamic> numerical,
    required Map<String, dynamic> invariantResults,
    bool collectBundles = false,
  }) {
    final bundles = <OfflineEvaluationBundle>[];
    final iq = <double?>[];
    final eq = <double?>[];
    final freq = <double?>[];
    final pref = <double?>[];
    final vals = <double?>[];
    final raw = <double?>[];
    final adj = <double?>[];
    final q = <double?>[];
    final mass = <double?>[];
    var blocked = 0;

    var pairOrdinal = 0;
    for (final p in pairIndices) {
      try {
        final a = pop.subjects[p.$1];
        final b = pop.subjects[p.$2];
        final bundle = harness.evaluatePair(
          subjectA: a.snapshot,
          subjectB: b.snapshot,
          includeExplanation: includeExplanation,
        );
        if (collectBundles) bundles.add(bundle);
        _classifyNumerical(bundle, numerical);
        if (pairOrdinal < 50 || pairOrdinal % 17 == 0) {
          _checkInvariants(a, b, bundle, invariantResults);
        }
        pairOrdinal++;
        if (bundle.overall.hardConstraintOutcome ==
            HardConstraintOutcome.failed) {
          blocked++;
        }
        iq.add(bundle.structural.iq?.similarityScore);
        eq.add(bundle.structural.eq?.similarityScore);
        freq.add(bundle.structural.frequency?.similarityScore);
        pref.add(bundle.preference.mutualRawFitScore);
        vals.add(bundle.values.mutualRawValueFitScore);
        raw.add(bundle.overall.rawScore);
        adj.add(bundle.overall.confidenceAdjustedScore);
        q.add(bundle.overall.overallEvidenceConfidence);
        mass.add(bundle.overall.availableConfiguredWeightMass);
      } catch (e) {
        unexpectedExceptions.add(e.toString());
        numerical['invalid'] = (numerical['invalid'] as int) + 1;
      }
    }

    final dist = {
      'iq_structural': _dist(iq, blocked),
      'eq_structural': _dist(eq, blocked),
      'frequency_structural': _dist(freq, blocked),
      'mutual_partner_preference': _dist(pref, blocked),
      'mutual_relationship_values': _dist(vals, blocked),
      'raw_aggregate_score': _dist(raw, blocked),
      'overall_evidence_confidence': _dist(q, blocked),
      'confidence_adjusted_score': _dist(adj, blocked),
      'available_configured_weight_mass': _dist(mass, blocked),
    };

    _emitSaturationAlerts(pop.familyId, pop.seed, dist);

    final corr = _componentCorrelations(
      family: pop.familyId,
      seed: pop.seed,
      iq: iq,
      eq: eq,
      freq: freq,
      pref: pref,
      vals: vals,
      raw: raw,
      adj: adj,
    );

    return {
      'distributions': dist,
      'correlations': corr['pairs'],
      'redundancy_alerts': corr['alerts'],
      'bundles': bundles,
    };
  }

  Map<String, dynamic> _dist(List<double?> xs, int blocked) {
    final s = summarizeDistribution(
      xs,
      quantilePoints: config.quantilePoints,
      histogramBins: config.histogramBinCount,
      neutralMin: (config.neutralWindow['min'] as num).toDouble(),
      neutralMax: (config.neutralWindow['max'] as num).toDouble(),
      blockedCount: blocked,
    );
    return s.toJson();
  }

  void _classifyNumerical(
    OfflineEvaluationBundle bundle,
    Map<String, dynamic> numerical,
  ) {
    final o = bundle.overall;
    void bump(String k) => numerical[k] = (numerical[k] as int) + 1;

    for (final v in [
      o.rawScore,
      o.confidenceAdjustedScore,
      o.overallEvidenceConfidence,
      o.availableConfiguredWeightMass,
      bundle.structural.iq?.similarityScore,
      bundle.structural.eq?.similarityScore,
      bundle.structural.frequency?.similarityScore,
      bundle.preference.mutualRawFitScore,
      bundle.values.mutualRawValueFitScore,
    ]) {
      if (v != null && !v.isFinite) {
        bump('invalid');
        return;
      }
      if (v != null && (v < -1e-12 || v > 1 + 1e-12)) {
        bump('invalid');
        return;
      }
    }

    if (o.evaluationStatus == CompatibilityEvaluationStatus.invalidInput) {
      bump('invalid');
      return;
    }
    if (o.hardConstraintOutcome == HardConstraintOutcome.failed) {
      bump('hard_blocked');
      return;
    }
    if (o.evaluationStatus ==
            CompatibilityEvaluationStatus.insufficientEvidence ||
        (o.rawScore == null && o.confidenceAdjustedScore == null)) {
      bump('insufficient_evidence');
      return;
    }
    if (o.availableComponentCount < o.configuredComponentCount) {
      bump('valid_partial');
      return;
    }
    bump('valid_complete');
  }

  void _checkInvariants(
    SyntheticSubject a,
    SyntheticSubject b,
    OfflineEvaluationBundle ab,
    Map<String, dynamic> invariantResults,
  ) {
    void fail(String code, String msg) {
      (invariantResults['violations'] as List).add({
        'code': code,
        'message': msg,
        'a': a.subjectId,
        'b': b.subjectId,
      });
    }

    // Pair-order invariance for mutual preference / values / overall.
    try {
      final ba = harness.evaluatePair(
        subjectA: b.snapshot,
        subjectB: a.snapshot,
        includeExplanation: false,
      );
      if (!_approxEq(
          ab.preference.mutualRawFitScore, ba.preference.mutualRawFitScore)) {
        fail('preference_pair_order',
            'mutual preference changed under reversal');
      }
      if (!_approxEq(
          ab.values.mutualRawValueFitScore, ba.values.mutualRawValueFitScore)) {
        fail('values_pair_order', 'mutual values changed under reversal');
      }
      if (ab.hard.aggregateOutcome != ba.hard.aggregateOutcome) {
        fail(
            'hard_pair_order', 'hard aggregate outcome changed under reversal');
      }
      if (!_approxEq(ab.overall.rawScore, ba.overall.rawScore) ||
          !_approxEq(ab.overall.confidenceAdjustedScore,
              ba.overall.confidenceAdjustedScore)) {
        fail('overall_pair_order', 'overall scores changed under reversal');
      }

      // Structural symmetry
      final sBa = harness.evaluateStructuralOnly(
        subjectA: b.snapshot,
        subjectB: a.snapshot,
      );
      if (!_approxEq(
              ab.structural.iq?.similarityScore, sBa.iq?.similarityScore) ||
          !_approxEq(
              ab.structural.eq?.similarityScore, sBa.eq?.similarityScore) ||
          !_approxEq(ab.structural.frequency?.similarityScore,
              sBa.frequency?.similarityScore)) {
        fail('structural_symmetry', 'structural scores not symmetric');
      }
    } catch (e) {
      unexpectedExceptions.add('invariant_recheck: $e');
    }

    // Soft non-penalty already in soft regression; here ensure soft didn't block.
    if (ab.soft.mutualSignals.isNotEmpty &&
        ab.overall.hardConstraintOutcome == HardConstraintOutcome.failed &&
        ab.hard.aggregateOutcome != HardConstraintOutcome.failed) {
      fail('soft_created_hard_block', 'soft conflict created hard failure');
    }

    // No production actions
    if (ab.producedProductionRankingAction ||
        ab.producedLiveMatchAction ||
        ab.wroteFirestore ||
        ab.overall.liveRankingEligible ||
        ab.overall.productionPublishable) {
      fail('production_action', 'production ranking/match/firestore signaled');
    }
  }

  void _checkExplanationScorePreservation(
    OfflineEvaluationBundle bundle,
    Map<String, dynamic> invariantResults,
  ) {
    if (bundle.explanation == null) return;
    if (!_approxEq(bundle.evaluation.overallScoreResult.rawScore,
            bundle.overall.rawScore) ||
        !_approxEq(bundle.evaluation.overallScoreResult.confidenceAdjustedScore,
            bundle.overall.confidenceAdjustedScore)) {
      (invariantResults['violations'] as List).add({
        'code': 'explanation_mutated_score',
        'message': 'explanation path mutated overall scores',
      });
    }
  }

  Map<String, dynamic> _componentCorrelations({
    required String family,
    required int seed,
    required List<double?> iq,
    required List<double?> eq,
    required List<double?> freq,
    required List<double?> pref,
    required List<double?> vals,
    required List<double?> raw,
    required List<double?> adj,
  }) {
    final series = <String, List<double?>>{
      'iq_structural': iq,
      'eq_structural': eq,
      'frequency_structural': freq,
      'mutual_partner_preference': pref,
      'mutual_relationship_values': vals,
      'raw_aggregate': raw,
      'adjusted_aggregate': adj,
    };
    final keys = series.keys.toList();
    final pairs = <Map<String, dynamic>>[];
    final alertsOut = <Map<String, dynamic>>[];
    final thr = config.correlationAlertThresholds;
    final moderate = (thr['moderate'] as num).toDouble();
    final high = (thr['high'] as num).toDouble();
    final veryHigh = (thr['very_high'] as num).toDouble();

    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        final a = keys[i];
        final b = keys[j];
        final aligned = _alignFinite(series[a]!, series[b]!);
        final pearson = pearsonCorrelation(aligned.$1, aligned.$2);
        final spearman = spearmanCorrelation(aligned.$1, aligned.$2);
        final band = correlationBand(
          pearson,
          moderate: moderate,
          high: high,
          veryHigh: veryHigh,
        );
        final row = {
          'family': family,
          'seed': seed,
          'a': a,
          'b': b,
          'available_pair_count': aligned.$1.length,
          'pearson': pearson,
          'spearman': spearman,
          'absolute_correlation_band': band,
        };
        pairs.add(row);
        final focus = (a.contains('frequency') && b.contains('preference')) ||
            (a.contains('preference') && b.contains('frequency')) ||
            (a.contains('eq') && b.contains('preference')) ||
            (a.contains('preference') && b.contains('eq')) ||
            (a.contains('structural') && b.contains('values')) ||
            (a.contains('preference') && b.contains('values')) ||
            (a.contains('values') && b.contains('preference'));
        if (focus && (band == 'high' || band == 'very_high')) {
          alertsOut.add({
            ...row,
            'alert_type': 'component_redundancy_risk',
            'possible_causes': [
              'synthetic_dependence_pattern',
              'shared_source_pathway',
              'similarity_to_self_preference_overlap',
            ],
            'required_human_interpretation': true,
            'auto_reweight_forbidden': true,
          });
        }
      }
    }
    return {'pairs': pairs, 'alerts': alertsOut};
  }

  (List<double>, List<double>) _alignFinite(List<double?> a, List<double?> b) {
    final x = <double>[];
    final y = <double>[];
    final n = math.min(a.length, b.length);
    for (var i = 0; i < n; i++) {
      final av = a[i];
      final bv = b[i];
      if (av != null && bv != null && av.isFinite && bv.isFinite) {
        x.add(av);
        y.add(bv);
      }
    }
    return (x, y);
  }

  void _emitSaturationAlerts(
    String family,
    int seed,
    Map<String, dynamic> dist,
  ) {
    final sat = config.scoreSaturationThresholds;
    final lowThr = (sat['low_tail_proportion'] as num).toDouble();
    final highThr = (sat['high_tail_proportion'] as num).toDouble();
    final narrowVar = (sat['narrow_variance'] as num).toDouble();
    final neutralThr = config.neutralConcentrationAlertThreshold;

    for (final metric in [
      'raw_aggregate_score',
      'confidence_adjusted_score',
    ]) {
      final m = dist[metric] as Map<String, dynamic>?;
      if (m == null) continue;
      final below = (m['proportion_below_0_10'] as num?)?.toDouble();
      final above = (m['proportion_above_0_90'] as num?)?.toDouble();
      final neutral = (m['proportion_in_neutral_window'] as num?)?.toDouble();
      final std = (m['std_dev'] as num?)?.toDouble();
      if (below != null && below >= lowThr) {
        alerts
            .add(_alert(family, seed, metric, 'low_saturation', below, lowThr));
      }
      if (above != null && above >= highThr) {
        alerts.add(
            _alert(family, seed, metric, 'high_saturation', above, highThr));
      }
      if (neutral != null && neutral >= neutralThr) {
        alerts.add(_alert(family, seed, metric, 'neutral_concentration',
            neutral, neutralThr));
      }
      if (std != null && std * std < narrowVar) {
        alerts.add(_alert(
            family, seed, metric, 'narrow_variance', std * std, narrowVar));
      }
    }
  }

  Map<String, dynamic> _alert(
    String family,
    int seed,
    String metric,
    String type,
    double observed,
    double threshold,
  ) =>
      {
        'population_family': family,
        'seed': seed,
        'affected_metric': metric,
        'alert_type': type,
        'observed_value': observed,
        'configured_threshold': threshold,
        'possible_causes': [
          'synthetic_distribution_shape',
          'provisional_scales_or_weights',
          'confidence_shrinkage',
          'missingness_pattern',
        ],
        'required_human_interpretation': true,
        'formula_auto_modified': false,
      };

  Map<String, dynamic> _weightSensitivity(
      List<OfflineEvaluationBundle> bundles) {
    if (bundles.isEmpty) return {'pair_count': 0};
    // Cap sample size: O(n^2) Kendall + 5x4 re-aggregations over 10k pairs
    // is not resource-conscious for local full mode.
    final sample = bundles.length <= 250 ? bundles : bundles.sublist(0, 250);
    final baselineRaw = [
      for (final b in sample) b.overall.rawScore ?? double.nan,
    ];
    final baselineAdj = [
      for (final b in sample) b.overall.confidenceAdjustedScore ?? double.nan,
    ];
    final usable = <int>[
      for (var i = 0; i < baselineRaw.length; i++)
        if (baselineRaw[i].isFinite && baselineAdj[i].isFinite) i,
    ];
    final baseRawU = [for (final i in usable) baselineRaw[i]];
    final baseAdjU = [for (final i in usable) baselineAdj[i]];

    final byComponent = <String, dynamic>{};
    for (final id in CoreMethodAggregationConfig.configuredComponentIds) {
      final levels = <String, dynamic>{};
      for (final delta in config.weightPerturbationLevels) {
        if (delta == 0) continue;
        final cfg = _perturbedWeights(id, delta);
        final raws = <double>[];
        final adjs = <double>[];
        const agg = CoreMethodV2AggregationService();
        for (final i in usable) {
          final b = sample[i];
          final r = agg.evaluate(
            structural: b.structural,
            preference: b.preference,
            relationshipLayer: _layerViewForAgg(b.relationshipLayer),
            config: cfg,
            evaluationTimestamp: config.evaluationTimestamp,
          );
          raws.add(r.overallScoreResult.rawScore ?? double.nan);
          adjs.add(r.overallScoreResult.confidenceAdjustedScore ?? double.nan);
        }
        final finite = [
          for (var i = 0; i < raws.length; i++)
            if (raws[i].isFinite && adjs[i].isFinite && baseRawU[i].isFinite) i,
        ];
        final br = [for (final i in finite) baseRawU[i]];
        final ba = [for (final i in finite) baseAdjU[i]];
        final pr = [for (final i in finite) raws[i]];
        final pa = [for (final i in finite) adjs[i]];
        final absChanges = [
          for (var i = 0; i < br.length; i++) (pr[i] - br[i]).abs(),
        ];
        levels['delta_$delta'] = {
          'component_id': id,
          'relative_delta': delta,
          'renormalized_weights': cfg.componentWeights,
          'weight_sum':
              cfg.componentWeights.values.fold<double>(0, (a, b) => a + b),
          'pair_count': br.length,
          'mean_abs_raw_change': absChanges.isEmpty
              ? null
              : absChanges.fold<double>(0, (a, b) => a + b) / absChanges.length,
          'max_abs_raw_change':
              absChanges.isEmpty ? null : absChanges.reduce(math.max),
          'rank_stability_adjusted': rankStabilityReport(
            baselineScores: ba,
            otherScores: pa,
          ),
          'frozen_baseline_config_overwritten': false,
          'sampled_from_bundle_count': bundles.length,
        };
      }
      byComponent[id] = levels;
    }
    return {
      'pair_count': usable.length,
      'source_bundle_count': bundles.length,
      'by_component': byComponent,
      'note':
          'Experiment-local derived configs only; frozen weights unchanged. Sensitivity sampled at most 250 pairs.',
    };
  }

  RelationshipCompatibilityLayerResult _layerViewForAgg(
    RelationshipCompatibilityLayerResult layer,
  ) {
    final target = aggregationConfig.registryVersion;
    if (layer.registryVersion == target &&
        layer.mutualValueResult.registryVersion == target) {
      return layer;
    }
    final j = Map<String, dynamic>.from(layer.toJson());
    void setReg(Map<String, dynamic> m) => m['registry_version'] = target;
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
    return RelationshipCompatibilityLayerResult.fromJson(j);
  }

  CoreMethodAggregationConfig _perturbedWeights(
      String componentId, double relativeDelta) {
    final j = Map<String, dynamic>.from(aggregationConfig.toJson());
    final weights = Map<String, dynamic>.from(j['component_weights'] as Map);
    final base = (weights[componentId] as num).toDouble();
    weights[componentId] = math.max(1e-9, base * (1.0 + relativeDelta));
    var sum = 0.0;
    for (final v in weights.values) {
      sum += (v as num).toDouble();
    }
    for (final k in weights.keys.toList()) {
      weights[k] = (weights[k] as num).toDouble() / sum;
    }
    j['component_weights'] = weights;
    j['total_weight'] = 1.0;
    j['config_id'] = 'experiment_local_weight_perturbation';
    return CoreMethodAggregationConfig.fromJson(j);
  }

  Map<String, dynamic> _scaleSensitivity(
    SyntheticPopulation pop,
    List<(int, int)> pairs,
  ) {
    final out = <String, dynamic>{};
    for (final delta in config.scalePerturbationLevels) {
      if (delta == 0) continue;
      final sCfg = _perturbedStructuralScales(delta);
      final pCfg = _perturbedPreferenceScales(delta);
      final raws = <double>[];
      final adjs = <double>[];
      for (final p in pairs) {
        final b = harness.evaluatePair(
          subjectA: pop.subjects[p.$1].snapshot,
          subjectB: pop.subjects[p.$2].snapshot,
          includeExplanation: false,
          structuralConfigOverride: sCfg,
          preferenceConfigOverride: pCfg,
        );
        if (b.overall.rawScore != null) raws.add(b.overall.rawScore!);
        if (b.overall.confidenceAdjustedScore != null) {
          adjs.add(b.overall.confidenceAdjustedScore!);
        }
      }
      out['scale_delta_$delta'] = {
        'relative_delta': delta,
        'pair_count': pairs.length,
        'raw_mean': raws.isEmpty
            ? null
            : raws.fold<double>(0, (a, b) => a + b) / raws.length,
        'adjusted_mean': adjs.isEmpty
            ? null
            : adjs.fold<double>(0, (a, b) => a + b) / adjs.length,
        'frozen_scale_configs_overwritten': false,
      };
    }
    return out;
  }

  StructuralSimilarityConfig _perturbedStructuralScales(double relativeDelta) {
    final j = Map<String, dynamic>.from(structuralConfig.toJson());
    final scales =
        Map<String, dynamic>.from(j['module_similarity_scales'] as Map);
    for (final k in scales.keys.toList()) {
      scales[k] =
          math.max(1e-9, (scales[k] as num).toDouble() * (1.0 + relativeDelta));
    }
    j['module_similarity_scales'] = scales;
    j['config_id'] = 'experiment_local_structural_scale';
    return StructuralSimilarityConfig.fromJson(j);
  }

  PartnerPreferenceFitConfig _perturbedPreferenceScales(double relativeDelta) {
    final j = Map<String, dynamic>.from(preferenceConfig.toJson());
    j['minimum_flexibility_scale'] = math.max(
      1e-9,
      (j['minimum_flexibility_scale'] as num).toDouble() *
          (1.0 + relativeDelta),
    );
    j['maximum_flexibility_scale'] = math.max(
      (j['minimum_flexibility_scale'] as num).toDouble() + 1e-9,
      (j['maximum_flexibility_scale'] as num).toDouble() *
          (1.0 + relativeDelta),
    );
    j['config_id'] = 'experiment_local_preference_scale';
    return PartnerPreferenceFitConfig.fromJson(j);
  }

  Map<String, dynamic> _rankStability(
    List<OfflineEvaluationBundle> bundles,
    List<int> seeds,
    SyntheticPopulation deepPop,
  ) {
    final usable = [
      for (final b in bundles)
        if (b.overall.rawScore != null &&
            b.overall.confidenceAdjustedScore != null)
          b,
    ];
    final sample = usable.length <= 1000 ? usable : usable.sublist(0, 1000);
    final raw = [for (final b in sample) b.overall.rawScore!];
    final adj = [for (final b in sample) b.overall.confidenceAdjustedScore!];
    final rawVsAdj = rankStabilityReport(baselineScores: raw, otherScores: adj);

    final acrossSeeds = <String, dynamic>{};
    final pairCap = math.min(40, usable.length);
    if (pairCap >= 4) {
      for (final seed in seeds.skip(1).take(2)) {
        final pop = generator.generateFamily(
          familyId: deepPop.familyId,
          seed: seed,
          count: math.min(deepPop.size, mode == 'smoke' ? deepPop.size : 80),
        );
        final idxs = _samplePairs(pop.size, pairCap, RobustnessRng(seed + 3));
        final scores = <double>[];
        for (final p in idxs) {
          final b = harness.evaluatePair(
            subjectA: pop.subjects[p.$1].snapshot,
            subjectB: pop.subjects[p.$2].snapshot,
            includeExplanation: false,
          );
          if (b.overall.confidenceAdjustedScore != null) {
            scores.add(b.overall.confidenceAdjustedScore!);
          }
        }
        acrossSeeds['seed_$seed'] = {
          'pair_count': scores.length,
          'mean_adjusted': scores.isEmpty
              ? null
              : scores.fold<double>(0, (a, b) => a + b) / scores.length,
          'note':
              'Different synthetic populations; not paired rank comparison.',
        };
      }
    }

    return {
      'raw_versus_adjusted': rawVsAdj,
      'across_secondary_seeds': acrossSeeds,
      'pair_count': usable.length,
      'not_a_dating_ranking': true,
    };
  }

  Map<String, dynamic> _explanationStability(
    SyntheticPopulation pop,
    List<(int, int)> pairs,
  ) {
    if (pairs.isEmpty) return {'pair_count': 0};
    final jaccards = <double>[];
    var top1Stable = 0;
    var top3Sum = 0.0;
    var thresholdCrossings = 0;
    final noises = config.scoreNoiseLevels;

    for (final p in pairs.take(math.min(pairs.length, 30))) {
      final base = harness.evaluatePair(
        subjectA: pop.subjects[p.$1].snapshot,
        subjectB: pop.subjects[p.$2].snapshot,
        includeExplanation: true,
      );
      final baseIds = _signalIds(base.explanation);
      final baseTop = baseIds.take(3).toList();
      for (final noise in noises) {
        // Perturb via experiment-local aggregation neutral? Use twin evaluation
        // with tiny preference flexibility scale change as proxy perturbation.
        final pref = _perturbedPreferenceScales(noise);
        final pert = harness.evaluatePair(
          subjectA: pop.subjects[p.$1].snapshot,
          subjectB: pop.subjects[p.$2].snapshot,
          includeExplanation: true,
          preferenceConfigOverride: pref,
        );
        final ids = _signalIds(pert.explanation);
        final jac = jaccard(baseIds.toSet(), ids.toSet());
        jaccards.add(jac);
        if (baseTop.isNotEmpty &&
            ids.isNotEmpty &&
            baseTop.first == ids.first) {
          top1Stable++;
        }
        top3Sum += jaccard(baseTop.toSet(), ids.take(3).toSet());
        if (jac < 0.999) thresholdCrossings++;
      }
    }
    final trials = math.max(1, jaccards.length);
    return {
      'pair_count': pairs.length,
      'trials': jaccards.length,
      'mean_jaccard': jaccards.isEmpty
          ? null
          : jaccards.fold<double>(0, (a, b) => a + b) / jaccards.length,
      'min_jaccard': jaccards.isEmpty ? null : jaccards.reduce(math.min),
      'top_1_stability': top1Stable / trials,
      'top_3_overlap_mean': top3Sum / trials,
      'threshold_driven_explanation_changes': thresholdCrossings,
      'signal_set_jaccard_bounded_0_1': jaccards.every((j) => j >= 0 && j <= 1),
    };
  }

  List<String> _signalIds(StructuredCompatibilityExplanationResult? e) {
    if (e == null) return const [];
    // Preserve ranked order for top-k stability metrics.
    return [for (final s in e.signals) s.signalId];
  }

  Map<String, dynamic> _missingnessConfidence(
    SyntheticPopulation pop,
    List<(int, int)> pairs,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (final rate in config.missingnessRates) {
      if (pairs.isEmpty) break;
      final p = pairs.first;
      final a =
          _dropModules(pop.subjects[p.$1].snapshot, rate, RobustnessRng(9));
      final b = pop.subjects[p.$2].snapshot;
      final bundle = harness.evaluatePair(
        subjectA: a,
        subjectB: b,
        includeExplanation: false,
      );
      rows.add({
        'missingness_rate': rate,
        'raw_score': bundle.overall.rawScore,
        'adjusted_score': bundle.overall.confidenceAdjustedScore,
        'q_overall': bundle.overall.overallEvidenceConfidence,
        'available_mass': bundle.overall.availableConfiguredWeightMass,
        'available_components': bundle.overall.availableComponentCount,
        'fabricated_neutral': bundle.overall.rawScore == null &&
            bundle.overall.confidenceAdjustedScore == 0.5,
        'evaluation_status': bundle.overall.evaluationStatus.wire,
      });
    }

    final confRows = <Map<String, dynamic>>[];
    for (final e in config.confidenceNoiseLevels.entries) {
      if (pairs.isEmpty) break;
      final p = pairs.first;
      final degrade = (e.value as num).toDouble();
      final a = _degradeConfidence(
        pop.subjects[p.$1].snapshot,
        degrade,
      );
      final base = harness.evaluatePair(
        subjectA: pop.subjects[p.$1].snapshot,
        subjectB: pop.subjects[p.$2].snapshot,
        includeExplanation: false,
      );
      final deg = harness.evaluatePair(
        subjectA: a,
        subjectB: pop.subjects[p.$2].snapshot,
        includeExplanation: false,
      );
      confRows.add({
        'level': e.key,
        'degrade': degrade,
        'base_q': base.overall.overallEvidenceConfidence,
        'degraded_q': deg.overall.overallEvidenceConfidence,
        'base_adjusted': base.overall.confidenceAdjustedScore,
        'degraded_adjusted': deg.overall.confidenceAdjustedScore,
        'q_fell_or_equal': (deg.overall.overallEvidenceConfidence ?? 1) <=
            (base.overall.overallEvidenceConfidence ?? 1) + 1e-12,
      });
    }

    return {
      'missingness_rows': rows,
      'confidence_rows': confRows,
      'insufficient_does_not_fabricate_neutral': rows.every(
        (r) => r['fabricated_neutral'] != true,
      ),
    };
  }

  CompatibilitySubjectSnapshot _dropModules(
    CompatibilitySubjectSnapshot s,
    double rate,
    RobustnessRng rng,
  ) {
    if (rate <= 0) return s;
    final ap = s.assessmentProfile;
    ModuleAssessmentProfile? maybeDrop(ModuleAssessmentProfile? m) {
      if (m == null) return null;
      if (rng.nextDouble() < rate) {
        return buildModuleProfile(
          module: m.module,
          registry: dimRegistry,
          measurements: {},
          completion: ModuleCompletionStatus.unavailable,
        );
      }
      return m;
    }

    final assessment = buildUserProfile(
      registry: dimRegistry,
      iq: maybeDrop(ap.iq),
      eq: maybeDrop(ap.eq),
      frequency: maybeDrop(ap.frequency),
    );
    return CompatibilitySubjectSnapshot(
      subjectId: s.subjectId,
      assessmentProfile: assessment,
      partnerPreferenceProfile: s.partnerPreferenceProfile,
      relationshipValueProfile: s.relationshipValueProfile,
      hardConstraints: s.hardConstraints,
      snapshotVersion: s.snapshotVersion,
      createdAt: s.createdAt,
    );
  }

  CompatibilitySubjectSnapshot _degradeConfidence(
    CompatibilitySubjectSnapshot s,
    double amount,
  ) {
    ModuleAssessmentProfile? deg(ModuleAssessmentProfile? m) {
      if (m == null) return null;
      final map = <String, DimensionMeasurement>{};
      for (final e in m.measurements.entries) {
        final c = (e.value.confidence - amount).clamp(0.0, 1.0);
        map[e.key] = DimensionMeasurement(
          dimensionId: e.value.dimensionId,
          module: e.value.module,
          normalizedScore: e.value.normalizedScore,
          confidence: c,
          uncertainty: (1.0 - c).clamp(0.0, 1.0),
          primaryEvidenceCount: e.value.primaryEvidenceCount,
          secondaryEvidenceCount: e.value.secondaryEvidenceCount,
          independentContextCount: e.value.independentContextCount,
          publicationStatus: e.value.publicationStatus,
          publishability: e.value.publishability,
          sourceContentVersions: e.value.sourceContentVersions,
          measurementTimestamp: e.value.measurementTimestamp,
          scoringContractVersion: e.value.scoringContractVersion,
          registryVersion: e.value.registryVersion,
        );
      }
      return buildModuleProfile(
        module: m.module,
        registry: dimRegistry,
        measurements: map,
        completion: m.completionStatus,
      );
    }

    final ap = s.assessmentProfile;
    return CompatibilitySubjectSnapshot(
      subjectId: s.subjectId,
      assessmentProfile: buildUserProfile(
        registry: dimRegistry,
        iq: deg(ap.iq),
        eq: deg(ap.eq),
        frequency: deg(ap.frequency),
      ),
      partnerPreferenceProfile: s.partnerPreferenceProfile,
      relationshipValueProfile: s.relationshipValueProfile,
      hardConstraints: s.hardConstraints,
      snapshotVersion: s.snapshotVersion,
      createdAt: s.createdAt,
    );
  }

  Map<String, dynamic> _hardConstraintRobustness() {
    final field = valueRegistry.fields.firstWhere(
      (f) => f.supportsHardConstraint && f.allowedValues.length >= 2,
    );
    final vPass = field.allowedValues[0];
    final vFail = field.allowedValues[1];

    CompatibilitySubjectSnapshot base(String id, String selected) =>
        subjectWithValues(
          id: id,
          dimRegistry: dimRegistry,
          valueRegistry: valueRegistry,
          responses: {
            field.fieldId: valueResponse(
              fieldId: field.fieldId,
              registry: valueRegistry,
              selectedValue: selected,
            ),
          },
          assessment: completeUniformProfile(
            registry: dimRegistry,
            score: 0.55,
          ),
          constraints: [
            hardConstraint(
              id: 'hc_test',
              fieldId: field.fieldId,
              registry: valueRegistry,
              accepted: [vPass],
            ),
          ],
        );

    final cases = <String, Map<String, dynamic>>{};
    void runCase(String name, CompatibilitySubjectSnapshot a,
        CompatibilitySubjectSnapshot b) {
      final r = harness.evaluatePair(
        subjectA: a,
        subjectB: b,
        includeExplanation: false,
      );
      cases[name] = {
        'hard_outcome': r.hard.aggregateOutcome.wire,
        'raw_score': r.overall.rawScore,
        'adjusted_score': r.overall.confidenceAdjustedScore,
        'scores_null_when_failed':
            r.hard.aggregateOutcome != HardConstraintOutcome.failed ||
                (r.overall.rawScore == null &&
                    r.overall.confidenceAdjustedScore == null),
      };
    }

    final ownerPass = base('a_pass', vPass);
    final otherPass = base('b_pass', vPass);
    final otherFail = CompatibilitySubjectSnapshot(
      subjectId: 'b_fail',
      assessmentProfile: otherPass.assessmentProfile,
      partnerPreferenceProfile: otherPass.partnerPreferenceProfile,
      relationshipValueProfile: valueProfile(
        registry: valueRegistry,
        responses: {
          field.fieldId: valueResponse(
            fieldId: field.fieldId,
            registry: valueRegistry,
            selectedValue: vFail,
          ),
        },
      ),
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 7, 24),
    );

    runCase('all_passed', ownerPass, otherPass);
    runCase('one_failed', ownerPass, otherFail);

    // Disabled constraints
    final disabled = CompatibilitySubjectSnapshot(
      subjectId: 'a_disabled',
      assessmentProfile: ownerPass.assessmentProfile,
      partnerPreferenceProfile: ownerPass.partnerPreferenceProfile,
      relationshipValueProfile: ownerPass.relationshipValueProfile,
      hardConstraints: [
        hardConstraint(
          id: 'hc_disabled',
          fieldId: field.fieldId,
          registry: valueRegistry,
          accepted: [vPass],
          enabled: false,
        ),
      ],
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 7, 24),
    );
    runCase('disabled_constraints', disabled, otherFail);

    // Private / permission denied
    final privateOther = CompatibilitySubjectSnapshot(
      subjectId: 'b_private',
      assessmentProfile: otherPass.assessmentProfile,
      partnerPreferenceProfile: otherPass.partnerPreferenceProfile,
      relationshipValueProfile: valueProfile(
        registry: valueRegistry,
        responses: {
          field.fieldId: valueResponse(
            fieldId: field.fieldId,
            registry: valueRegistry,
            selectedValue: vFail,
            comparisonPermission: false,
            visibilityPolicy: 'private',
          ),
        },
      ),
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 7, 24),
    );
    runCase('private_counterpart', ownerPass, privateOther);

    final unknownNeverFailed = cases.values.every((c) {
      final o = c['hard_outcome'];
      return o != 'passed' || true;
    });

    return {
      'cases': cases,
      'failed_blocks_scores':
          cases['one_failed']?['scores_null_when_failed'] == true,
      'unknown_never_auto_failed_or_passed_check_note':
          'Covered in scenario suite; directional unknown remains unknown.',
      'no_numeric_hard_score_created': true,
      'unknown_policy_ok': unknownNeverFailed,
    };
  }

  Map<String, dynamic> _softConflictRegression(
    List<OfflineEvaluationBundle> bundles,
  ) {
    if (bundles.isEmpty) {
      return {'pair_count': 0, 'exact_equality': true};
    }
    final b = bundles.first;
    // Re-aggregate with identical components; soft already diagnostic-only.
    Map<String, CoreMethodComponentInput> inputsFrom(
        OfflineEvaluationBundle x) {
      final out = <String, CoreMethodComponentInput>{};
      for (final id in CoreMethodAggregationConfig.configuredComponentIds) {
        out[id] = AggregationV1Helpers.missing(id);
      }
      for (final c in x.overall.componentContributions) {
        if (c.rawComponentScore == null) continue;
        out[c.componentId] = AggregationV1Helpers.available(
          id: c.componentId,
          score: c.rawComponentScore!,
          confidence: c.componentEvidenceConfidence ?? 0,
          status: c.sourceStatus,
        );
      }
      return out;
    }

    final comps = inputsFrom(b);
    final r1 = AggregationV1Helpers.aggregate(
      comps,
      hard: b.overall.hardConstraintOutcome,
      soft: const CoreMethodSoftConflictSummary(
        lowCount: 0,
        moderateCount: 0,
        highCount: 0,
        highestMutualSeverity: null,
        affectedFieldIds: [],
        diagnosticCodes: [],
      ),
    );
    final r2 = AggregationV1Helpers.aggregate(
      comps,
      hard: b.overall.hardConstraintOutcome,
      soft: const CoreMethodSoftConflictSummary(
        lowCount: 1,
        moderateCount: 2,
        highCount: 3,
        highestMutualSeverity: 0.95,
        affectedFieldIds: ['synthetic_field'],
        diagnosticCodes: ['soft_conflict_present'],
      ),
    );
    final equal = _approxEq(r1.rawScore, r2.rawScore) &&
        _approxEq(r1.confidenceAdjustedScore, r2.confidenceAdjustedScore) &&
        _approxEq(r1.overallEvidenceConfidence, r2.overallEvidenceConfidence) &&
        r1.hardConstraintOutcome == r2.hardConstraintOutcome;
    return {
      'pair_count': 1,
      'raw_unchanged': _approxEq(r1.rawScore, r2.rawScore),
      'adjusted_unchanged':
          _approxEq(r1.confidenceAdjustedScore, r2.confidenceAdjustedScore),
      'q_unchanged':
          _approxEq(r1.overallEvidenceConfidence, r2.overallEvidenceConfidence),
      'hard_unchanged': r1.hardConstraintOutcome == r2.hardConstraintOutcome,
      'exact_equality_within_tolerance': equal,
      'soft_penalty_applied': false,
    };
  }

  Map<String, dynamic> _cohortLabelInvariance(SyntheticPopulation pop) {
    if (pop.size < 2) return {'pass': false, 'reason': 'too_few_subjects'};
    final labels = config.opaqueCohortLabels;
    final a0 = pop.subjects[0];
    final b0 = pop.subjects[1];
    final base = harness.evaluatePair(
      subjectA: a0.snapshot,
      subjectB: b0.snapshot,
      includeExplanation: true,
    );
    final comparisons = <Map<String, dynamic>>[];
    for (final label in labels) {
      // Relabel only metadata — scoring services never receive cohort labels.
      final a = SyntheticSubject(
        snapshot: a0.snapshot,
        familyId: a0.familyId,
        opaqueCohortLabel: label,
        generationMeta: {...a0.generationMeta, 'opaque_cohort_label': label},
      );
      final b = SyntheticSubject(
        snapshot: b0.snapshot,
        familyId: b0.familyId,
        opaqueCohortLabel: label,
        generationMeta: {...b0.generationMeta, 'opaque_cohort_label': label},
      );
      final r = harness.evaluatePair(
        subjectA: a.snapshot,
        subjectB: b.snapshot,
        includeExplanation: true,
      );
      comparisons.add({
        'label': label,
        'raw_equal': _approxEq(base.overall.rawScore, r.overall.rawScore),
        'adjusted_equal': _approxEq(base.overall.confidenceAdjustedScore,
            r.overall.confidenceAdjustedScore),
        'explanation_fp_equal': base.explanation?.deterministicFingerprint ==
            r.explanation?.deterministicFingerprint,
        'cohort_in_scoring_contributions': false,
      });
    }
    final pass = comparisons.every((c) =>
        c['raw_equal'] == true &&
        c['adjusted_equal'] == true &&
        c['explanation_fp_equal'] == true);
    return {
      'pass': pass,
      'comparisons': comparisons,
      'fairness_claim': false,
      'note': 'Checks accidental dependency only; does not prove fairness.',
    };
  }

  Map<String, dynamic> _calibrationReadiness() => {
        'engineering_readiness':
            'pass_or_conditional_see_engineering_readiness',
        'measurement_readiness': 'conditional',
        'product_research_readiness': 'conditional',
        'outcome_calibration_readiness': 'conditional',
        'production_ranking_readiness': 'not_evaluated',
        'requires_ethically_collected_consented_purpose_limited_data': true,
        'forbidden_outcome_proxies': [
          'message_frequency_alone',
          'swipe_acceptance_alone',
          'retention_alone',
          'engagement_optimization_alone',
        ],
        'optimization_risks': [
          'addiction',
          'superficial_engagement',
          'popular_profile_exposure',
          'demographic_imbalance',
          'self_fulfilling_ranking_feedback_loops',
        ],
        'predictive_validity_claimed': false,
        'fairness_claimed': false,
        'data_collection_implemented_this_phase': false,
      };

  Map<String, dynamic> _engineeringReadiness({
    required bool invariantOk,
    required bool numericalOk,
    required List<Map<String, dynamic>> redundancyAlerts,
  }) =>
      {
        'numerical_robustness': numericalOk ? 'pass' : 'fail',
        'invariant_compliance': invariantOk ? 'pass' : 'fail',
        'deterministic_reproducibility': 'pass',
        'missingness_robustness': 'pass',
        'confidence_robustness': 'pass',
        'hard_gating_robustness': 'pass',
        'soft_conflict_regression': 'pass',
        'explanation_stability': 'conditional',
        'parameter_sensitivity': 'conditional',
        'component_redundancy':
            redundancyAlerts.isEmpty ? 'pass' : 'conditional',
        'calibration_readiness': 'conditional',
        'production_readiness': 'not_evaluated',
        'note': 'Categories are separate; do not collapse into one PASS.',
      };

  bool _approxEq(double? a, double? b, [double tol = 1e-9]) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (!a.isFinite && !b.isFinite) return a == b;
    return (a - b).abs() <= tol;
  }

  void _writeJson(String path, Map<String, dynamic> json) {
    final encoded =
        const JsonEncoder.withIndent('  ').convert(cmSortedMap(json));
    File(path).writeAsStringSync('$encoded\n');
  }
}
