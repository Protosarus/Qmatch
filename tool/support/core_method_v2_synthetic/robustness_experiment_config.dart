// Offline robustness experiment config loader. CLI/test-only.

import 'dart:convert';
import 'dart:io';

class RobustnessExperimentConfig {
  final Map<String, dynamic> raw;
  final String configVersion;
  final String registryVersion;
  final int baselineSeed;
  final List<int> secondarySeeds;
  final int syntheticPopulationSize;
  final int sampledPairCount;
  final int fullPipelinePairCount;
  final int explanationPairCount;
  final List<String> syntheticFamilyIds;
  final List<double> quantilePoints;
  final int histogramBinCount;
  final Map<String, dynamic> correlationAlertThresholds;
  final Map<String, dynamic> scoreSaturationThresholds;
  final Map<String, dynamic> neutralWindow;
  final double neutralConcentrationAlertThreshold;
  final List<double> weightPerturbationLevels;
  final List<double> scalePerturbationLevels;
  final List<double> scoreNoiseLevels;
  final List<double> missingnessRates;
  final Map<String, dynamic> confidenceNoiseLevels;
  final List<String> opaqueCohortLabels;
  final String primaryDeepDiveFamily;
  final DateTime evaluationTimestamp;
  final Map<String, dynamic> modes;

  RobustnessExperimentConfig._({
    required this.raw,
    required this.configVersion,
    required this.registryVersion,
    required this.baselineSeed,
    required this.secondarySeeds,
    required this.syntheticPopulationSize,
    required this.sampledPairCount,
    required this.fullPipelinePairCount,
    required this.explanationPairCount,
    required this.syntheticFamilyIds,
    required this.quantilePoints,
    required this.histogramBinCount,
    required this.correlationAlertThresholds,
    required this.scoreSaturationThresholds,
    required this.neutralWindow,
    required this.neutralConcentrationAlertThreshold,
    required this.weightPerturbationLevels,
    required this.scalePerturbationLevels,
    required this.scoreNoiseLevels,
    required this.missingnessRates,
    required this.confidenceNoiseLevels,
    required this.opaqueCohortLabels,
    required this.primaryDeepDiveFamily,
    required this.evaluationTimestamp,
    required this.modes,
  });

  static const defaultPath =
      'assets/data/core_method_v2/core_method_v2_robustness_experiment_config_v1.json';
  static const schemaPath =
      'assets/schemas/core_method_v2/core_method_v2_robustness_experiment_config_v1.schema.json';

  factory RobustnessExperimentConfig.loadFile([String? path]) {
    final file = File(path ?? defaultPath);
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return RobustnessExperimentConfig.fromJson(raw);
  }

  factory RobustnessExperimentConfig.fromJson(Map<String, dynamic> raw) {
    final ts = DateTime.parse(
      raw['injected_evaluation_timestamp_utc']?.toString() ??
          '2026-07-24T12:00:00.000Z',
    ).toUtc();
    return RobustnessExperimentConfig._(
      raw: Map<String, dynamic>.from(raw),
      configVersion: raw['config_version']?.toString() ?? '',
      registryVersion: raw['registry_version']?.toString() ?? '',
      baselineSeed: (raw['baseline_seed'] as num).toInt(),
      secondarySeeds: [
        for (final e in (raw['secondary_seeds'] as List)) (e as num).toInt(),
      ],
      syntheticPopulationSize:
          (raw['synthetic_population_size'] as num).toInt(),
      sampledPairCount: (raw['sampled_pair_count'] as num).toInt(),
      fullPipelinePairCount: (raw['full_pipeline_pair_count'] as num).toInt(),
      explanationPairCount: (raw['explanation_pair_count'] as num).toInt(),
      syntheticFamilyIds: [
        for (final e in (raw['synthetic_family_ids'] as List)) e.toString(),
      ],
      quantilePoints: [
        for (final e in (raw['quantile_points'] as List)) (e as num).toDouble(),
      ],
      histogramBinCount: (raw['histogram_bin_count'] as num).toInt(),
      correlationAlertThresholds:
          Map<String, dynamic>.from(raw['correlation_alert_thresholds'] as Map),
      scoreSaturationThresholds:
          Map<String, dynamic>.from(raw['score_saturation_thresholds'] as Map),
      neutralWindow:
          Map<String, dynamic>.from(raw['neutral_concentration_window'] as Map),
      neutralConcentrationAlertThreshold:
          (raw['neutral_concentration_alert_threshold'] as num).toDouble(),
      weightPerturbationLevels: [
        for (final e in (raw['weight_perturbation_levels'] as List))
          (e as num).toDouble(),
      ],
      scalePerturbationLevels: [
        for (final e in (raw['scale_perturbation_levels'] as List))
          (e as num).toDouble(),
      ],
      scoreNoiseLevels: [
        for (final e in (raw['score_noise_levels'] as List))
          (e as num).toDouble(),
      ],
      missingnessRates: [
        for (final e in (raw['missingness_rates'] as List))
          (e as num).toDouble(),
      ],
      confidenceNoiseLevels:
          Map<String, dynamic>.from(raw['confidence_noise_levels'] as Map),
      opaqueCohortLabels: [
        for (final e in (raw['opaque_cohort_labels'] as List?) ?? const [])
          e.toString(),
      ],
      primaryDeepDiveFamily:
          raw['primary_deep_dive_family']?.toString() ?? 'independent_uniform',
      evaluationTimestamp: ts,
      modes: Map<String, dynamic>.from(raw['modes'] as Map),
    );
  }

  Map<String, dynamic> modeResolved(String mode) {
    final m = Map<String, dynamic>.from(modes[mode] as Map? ?? const {});
    return {
      'mode': mode,
      'synthetic_population_size':
          m['synthetic_population_size'] ?? syntheticPopulationSize,
      'subjects_per_family': m['subjects_per_family'] ??
          raw['subjects_per_family_full_sweep'] ??
          80,
      'sampled_pair_count': m['sampled_pair_count'] ?? sampledPairCount,
      'full_pipeline_pair_count':
          m['full_pipeline_pair_count'] ?? fullPipelinePairCount,
      'explanation_pair_count':
          m['explanation_pair_count'] ?? explanationPairCount,
      'secondary_seed_count':
          m['secondary_seed_count'] ?? secondarySeeds.length,
      'run_deep_dive': m['run_deep_dive'] == true,
      'run_all_families': m['run_all_families'] != false,
      'deep_dive_uses_top_level_counts':
          m['deep_dive_uses_top_level_counts'] == true,
      'pairs_per_family_sweep': raw['pairs_per_family_full_sweep'] ?? 400,
      'full_pipeline_pairs_per_family_sweep':
          raw['full_pipeline_pairs_per_family_full_sweep'] ?? 120,
      'explanation_pairs_per_family_sweep':
          raw['explanation_pairs_per_family_full_sweep'] ?? 40,
    };
  }
}
