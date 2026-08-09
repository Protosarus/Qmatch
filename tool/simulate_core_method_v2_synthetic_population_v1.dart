// Deterministic synthetic population robustness simulator (P2B-6).
// Usage:
//   dart run tool/simulate_core_method_v2_synthetic_population_v1.dart --mode=smoke
//   dart run tool/simulate_core_method_v2_synthetic_population_v1.dart --mode=full

import 'dart:io';

import 'support/core_method_v2_synthetic/robustness_experiment_config.dart';
import 'support/core_method_v2_synthetic/robustness_experiment_runner.dart';

void main(List<String> args) {
  var mode = 'smoke';
  for (final a in args) {
    if (a.startsWith('--mode=')) {
      mode = a.substring('--mode='.length);
    }
  }
  if (mode != 'smoke' && mode != 'full') {
    stderr.writeln('Invalid mode: $mode (expected smoke|full)');
    exitCode = 2;
    return;
  }

  final config = RobustnessExperimentConfig.loadFile();
  final outDir = mode == 'smoke'
      ? 'tool/core_method_v2_out/robustness_v1_smoke'
      : 'tool/core_method_v2_out/robustness_v1';

  stdout.writeln('P2B-6 synthetic population mode=$mode out=$outDir');
  final runner = RobustnessExperimentRunner(config: config, mode: mode);
  final summary = runner.runAll(outDir: outDir);
  stdout.writeln(
    'done families=${config.syntheticFamilyIds.length} '
    'invariant_pass=${summary['invariant_results']?['pass']} '
    'alerts=${summary['alert_count']}',
  );
}
