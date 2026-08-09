import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

/// Shared helpers for P2B-4 aggregation tests and offline tools.
class AggregationV1Helpers {
  static const configPath =
      'assets/data/core_method_v2/core_method_v2_aggregation_config_v1.json';
  static const schemaPath =
      'assets/schemas/core_method_v2/core_method_v2_aggregation_config_v1.schema.json';
  static const registryPath =
      'assets/data/core_method_v2/canonical_dimension_registry_v1.json';
  static const fixture24Path =
      'assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json';

  static const componentIds =
      CoreMethodAggregationConfig.configuredComponentIds;

  static CoreMethodAggregationConfig loadConfig([String? path]) =>
      CoreMethodAggregationConfig.loadFile(path ?? configPath);

  static CoreMethodComponentInput available({
    required String id,
    required double score,
    required double confidence,
    String status = 'complete',
    String configVersion = 'source_config_v1',
    String registryVersion = 'canonical_dimension_registry_v1',
    List<String> diags = const [],
  }) =>
      CoreMethodComponentInput(
        componentId: id,
        score: score,
        confidence: confidence,
        sourceStatus: status,
        sourceConfigVersion: configVersion,
        sourceRegistryVersion: registryVersion,
        sourcePresent: true,
        sourceDiagnosticCodes: diags,
      );

  static CoreMethodComponentInput missing(String id) =>
      CoreMethodComponentInput(
        componentId: id,
        score: null,
        confidence: null,
        sourceStatus: 'missing',
        sourceConfigVersion: null,
        sourceRegistryVersion: null,
        sourcePresent: false,
      );

  static Map<String, CoreMethodComponentInput> allEqual(
    double score,
    double confidence, {
    Set<String> exclude = const {},
  }) {
    final out = <String, CoreMethodComponentInput>{};
    for (final id in componentIds) {
      out[id] = exclude.contains(id)
          ? missing(id)
          : available(id: id, score: score, confidence: confidence);
    }
    return out;
  }

  static Map<String, CoreMethodComponentInput> withScores(
    Map<String, double> scores, {
    double confidence = 1.0,
    Map<String, double>? confidences,
  }) {
    final out = <String, CoreMethodComponentInput>{};
    for (final id in componentIds) {
      if (!scores.containsKey(id)) {
        out[id] = missing(id);
        continue;
      }
      out[id] = available(
        id: id,
        score: scores[id]!,
        confidence: confidences?[id] ?? confidence,
      );
    }
    return out;
  }

  static CoreMethodOverallScoreResult aggregate(
    Map<String, CoreMethodComponentInput> inputs, {
    CoreMethodAggregationConfig? config,
    HardConstraintOutcome hard = HardConstraintOutcome.passed,
    CoreMethodSoftConflictSummary? soft,
    CoreMethodAsymmetrySummary? asymmetry,
    DateTime? ts,
    List<String> failedIds = const [],
  }) {
    const svc = CoreMethodV2AggregationService();
    return svc.aggregateComponents(
      componentInputs: inputs,
      config: config ?? loadConfig(),
      hardConstraintOutcome: hard,
      failedHardConstraintIds: failedIds,
      softConflictSummary: soft,
      asymmetrySummary: asymmetry,
      evaluationTimestamp: ts ?? DateTime.utc(2026, 7, 24, 12),
    );
  }

  static SoftConflictEvaluationResult softResult({
    List<MutualSoftConflictSignal> mutual = const [],
  }) =>
      SoftConflictEvaluationResult(
        subjectAToBSignals: const [],
        subjectBToASignals: const [],
        mutualSignals: mutual,
        deterministicFingerprint: 'soft_fp',
        diagnostics: const [],
        configVersion: 'relationship_value_comparison_config_v1',
        registryVersion: 'canonical_dimension_registry_v1',
      );

  static MutualSoftConflictSignal mutualSoft({
    required String fieldId,
    required double severity,
    required String band,
  }) =>
      MutualSoftConflictSignal(
        fieldId: fieldId,
        subjectAToBSeverity: severity,
        subjectBToASeverity: severity,
        mutualSeverity: severity,
        severityBand: band,
        directionalAsymmetry: 0,
        diagnosticCodes: const ['soft_conflict_signal'],
      );

  static bool nearly(double? a, double? b, [double tol = 1e-9]) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() <= tol;
  }

  static String canonicalJson(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);

  static void writeJson(String path, Map<String, dynamic> data) {
    Directory(File(path).parent.path).createSync(recursive: true);
    File(path).writeAsStringSync('${canonicalJson(cmSortedMap(data))}\n');
  }

  static String fileShaLike(String path) {
    final bytes = File(path).readAsBytesSync();
    var hash = 0xcbf29ce484222325;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
