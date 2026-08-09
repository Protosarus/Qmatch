// Offline validator for Core Method v2 robustness evaluation (P2B-6).
// Usage: dart run tool/validate_core_method_v2_robustness_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import 'support/core_method_v2_synthetic/robustness_experiment_config.dart';
import 'support/core_method_v2_synthetic/synthetic_profile_generator.dart';

const outPath =
    'tool/core_method_v2_out/validate_core_method_v2_robustness_v1_report.json';

void main() {
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  try {
    final config = RobustnessExperimentConfig.loadFile();
    final schemaRaw = jsonDecode(
            File(RobustnessExperimentConfig.schemaPath).readAsStringSync())
        as Map<String, dynamic>;
    final required =
        (schemaRaw['required'] as List).map((e) => e.toString()).toSet();
    for (final k in required) {
      if (!config.raw.containsKey(k)) {
        add('error', 'schema_missing_key', k);
      }
    }

    if (config.raw['status'] != 'provisional') {
      add('error', 'status', '${config.raw['status']}');
    }
    if (config.raw['runtime_status'] != 'offline_only') {
      add('error', 'runtime_status', '${config.raw['runtime_status']}');
    }
    if (config.raw['production_approval_status'] != 'not_approved') {
      add('error', 'production_approval',
          '${config.raw['production_approval_status']}');
    }
    if (config.secondarySeeds.length < 4) {
      add('error', 'secondary_seeds', '${config.secondarySeeds.length}');
    }
    if (config.syntheticFamilyIds.length != 26) {
      add('error', 'family_count', '${config.syntheticFamilyIds.length}');
    }
    for (final f in kSyntheticFamilyIds) {
      if (!config.syntheticFamilyIds.contains(f)) {
        add('error', 'missing_family', f);
      }
    }
    if (config.raw['real_user_data_policy'] != 'forbidden_in_this_phase') {
      add('error', 'real_user_data_policy',
          '${config.raw['real_user_data_policy']}');
    }
    if (config.histogramBinCount != 20) {
      add('error', 'histogram_bins', '${config.histogramBinCount}');
    }
    if (config.syntheticPopulationSize < 1 ||
        config.sampledPairCount < 1 ||
        config.fullPipelinePairCount < 1) {
      add('error', 'counts_invalid', 'non-positive population/pair counts');
    }

    // Smoke outputs (preferred) or full outputs.
    final smokeDir = 'tool/core_method_v2_out/robustness_v1_smoke';
    final fullDir = 'tool/core_method_v2_out/robustness_v1';
    final dir = Directory(fullDir).existsSync() &&
            File('$fullDir/full_summary.json').existsSync()
        ? fullDir
        : smokeDir;

    final requiredFiles = [
      'experiment_manifest.json',
      'population_summary.json',
      'numerical_robustness.json',
      'invariant_results.json',
      'component_distributions.json',
      'component_correlations.json',
      'redundancy_alerts.json',
      'weight_sensitivity.json',
      'scale_sensitivity.json',
      'missingness_confidence.json',
      'hard_constraint_robustness.json',
      'soft_conflict_regression.json',
      'explanation_stability.json',
      'rank_stability.json',
      'cohort_label_invariance.json',
      'calibration_readiness.json',
      'full_summary.json',
    ];

    if (!Directory(dir).existsSync()) {
      add('error', 'missing_out_dir', dir);
    } else {
      for (final f in requiredFiles) {
        if (!File('$dir/$f').existsSync()) {
          add('error', 'missing_report', '$dir/$f');
        }
      }
      if (File('$dir/invariant_results.json').existsSync()) {
        final inv =
            jsonDecode(File('$dir/invariant_results.json').readAsStringSync())
                as Map<String, dynamic>;
        final vCount = (inv['violation_count'] as num?)?.toInt() ??
            ((inv['violations'] as List?)?.length ?? -1);
        if (vCount != 0) {
          add('error', 'invariant_violations', '$vCount');
        }
      }
      if (File('$dir/numerical_robustness.json').existsSync()) {
        final numj = jsonDecode(
                File('$dir/numerical_robustness.json').readAsStringSync())
            as Map<String, dynamic>;
        final ex = (numj['unexpected_exceptions'] as num?)?.toInt() ?? 0;
        if (ex != 0) {
          add('error', 'unexpected_exceptions', '$ex');
        }
      }
      if (File('$dir/cohort_label_invariance.json').existsSync()) {
        final c = jsonDecode(
                File('$dir/cohort_label_invariance.json').readAsStringSync())
            as Map<String, dynamic>;
        if (c['pass'] != true) {
          add('error', 'cohort_label_invariance', '${c['pass']}');
        }
      }
      if (File('$dir/soft_conflict_regression.json').existsSync()) {
        final s = jsonDecode(
                File('$dir/soft_conflict_regression.json').readAsStringSync())
            as Map<String, dynamic>;
        if (s['exact_equality_within_tolerance'] == false) {
          add('error', 'soft_conflict_penalty', 'scores changed');
        }
      }
      if (File('$dir/engineering_readiness.json').existsSync()) {
        final e = jsonDecode(
                File('$dir/engineering_readiness.json').readAsStringSync())
            as Map<String, dynamic>;
        if (e['production_readiness'] == 'pass') {
          add('error', 'production_readiness_overclaim', 'must not be pass');
        }
      }
      if (File('$dir/calibration_readiness.json').existsSync()) {
        final c = jsonDecode(
                File('$dir/calibration_readiness.json').readAsStringSync())
            as Map<String, dynamic>;
        if (c['predictive_validity_claimed'] == true ||
            c['fairness_claimed'] == true) {
          add('error', 'calibration_overclaim', 'forbidden claims present');
        }
      }
    }

    // Scenario report
    final scenPath =
        'tool/core_method_v2_out/core_method_v2_robustness_scenarios_v1_report.json';
    if (!File(scenPath).existsSync()) {
      add('warning', 'scenarios_missing', scenPath);
    } else {
      final scen =
          jsonDecode(File(scenPath).readAsStringSync()) as Map<String, dynamic>;
      final count = (scen['scenario_count'] as num?)?.toInt() ?? 0;
      if (count < 100) {
        add('error', 'scenario_count', '$count');
      }
      if (scen['contiguous'] != true) {
        add('error', 'scenario_contiguous', '${scen['contiguous']}');
      }
      if (scen['engineering_pass'] != true) {
        add('error', 'scenario_failures', '${scen['fail_count']}');
      }
    }

    // Production non-integration: no imports of forbidden modules in new tools.
    final toolFiles = [
      'tool/simulate_core_method_v2_synthetic_population_v1.dart',
      'tool/simulate_core_method_v2_robustness_scenarios_v1.dart',
      'tool/validate_core_method_v2_robustness_v1.dart',
      'tool/support/core_method_v2_offline_evaluation_harness.dart',
    ];
    final forbiddenImportPatterns = [
      RegExp(r"import\s+[^;]*discover_service"),
      RegExp(r"import\s+[^;]*compatibility_scoring", caseSensitive: false),
      RegExp(r"import\s+[^;]*question_service", caseSensitive: false),
      RegExp(r"import\s+[^;]*persona_scoring", caseSensitive: false),
      RegExp(r"import\s+[^;]*cloud_firestore"),
      RegExp(r"import\s+[^;]*firebase_auth"),
    ];
    for (final path in toolFiles) {
      if (!File(path).existsSync()) continue;
      final src = File(path).readAsStringSync();
      for (final pat in forbiddenImportPatterns) {
        if (pat.hasMatch(src)) {
          add('error', 'production_integration', '$path matches ${pat.pattern}');
        }
      }
    }

    // Frozen aggregation weights untouched
    final agg = CoreMethodAggregationConfig.loadFile(
      'assets/data/core_method_v2/core_method_v2_aggregation_config_v1.json',
    );
    if ((agg.weightOf('iq_structural') - 0.08).abs() > 1e-12 ||
        (agg.weightOf('eq_structural') - 0.24).abs() > 1e-12 ||
        (agg.weightOf('frequency_structural') - 0.28).abs() > 1e-12 ||
        (agg.weightOf('mutual_partner_preference') - 0.20).abs() > 1e-12 ||
        (agg.weightOf('mutual_relationship_values') - 0.20).abs() > 1e-12) {
      add('error', 'frozen_weights_changed', agg.componentWeights.toString());
    }
  } catch (e, st) {
    add('error', 'validator_exception', '$e');
    add('error', 'stack', '$st');
  }

  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_core_method_v2_robustness_v1',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'warning_count': findings.where((f) => f['severity'] == 'warning').length,
    'findings': findings,
    'production_readiness': 'not_evaluated',
    'predictive_validity_claimed': false,
    'fairness_claimed': false,
  });

  Directory(File(outPath).parent.path).createSync(recursive: true);
  File(outPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln('robustness validator: ${report['status']} errors=$errors');
  if (errors > 0) {
    for (final f in findings.where((f) => f['severity'] == 'error')) {
      stdout.writeln('  ERROR ${f['code']}: ${f['message']}');
    }
    exitCode = 1;
  }
}
