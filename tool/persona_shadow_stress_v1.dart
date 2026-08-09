// Offline P2C-3A-3 Persona shadow stress runner.
// Usage: dart run tool/persona_shadow_stress_v1.dart
// Writes aggregate JSON only (no raw profiles).

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

void main() {
  final root = Directory.current.path;
  final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(root);
  final scorer = CanonicalPersonaShadowScorer(
    catalog: loaded.catalog,
    config: loaded.config,
  );
  final sim = PersonaShadowStressSimulator(
    scorer: scorer,
    catalog: loaded.catalog,
    config: loaded.config,
  );

  stdout.writeln('P2C-3A-3 stress start seed=${sim.seed}');
  final sw = Stopwatch()..start();
  final report = sim.runFull();
  sw.stop();
  stdout.writeln(
    'done n=${report.sampleCounts['overall']} '
    'ms=${sw.elapsedMilliseconds} '
    'self_center_failures=${report.selfCenterFailureCount} '
    'H_norm=${report.overall['normalized_entropy']} '
    'max_share=${report.overall['max_persona_share']} '
    'mid=${report.midpointExact['primary']}/'
    '${report.midpointExact['secondary']} '
    'delta=${report.midpointExact['delta_d']}',
  );

  final outDir = Directory('$root/docs/persona/reports');
  outDir.createSync(recursive: true);
  final outFile =
      File('${outDir.path}/persona_shadow_stress_v1_aggregate.json');
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );
  stdout.writeln('wrote ${outFile.path}');
}
