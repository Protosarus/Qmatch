// Offline validator for structured compatibility explanation (P2B-5).
// Usage: dart run tool/validate_structured_compatibility_explanation_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../test/support/aggregation_v1_helpers.dart';
import '../test/support/explanation_v1_helpers.dart';

const outPath =
    'tool/core_method_v2_out/validate_structured_compatibility_explanation_v1_report.json';

void main() {
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  try {
    final config = ExplanationV1Helpers.loadConfig();
    final codes = ExplanationV1Helpers.loadCodeRegistry();
    final schema = jsonDecode(
      File(ExplanationV1Helpers.configSchemaPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final raw = jsonDecode(
      File(ExplanationV1Helpers.configPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final k in schema['required'] as List) {
      if (!raw.containsKey(k)) add('error', 'schema_missing_key', '$k');
    }
    for (final c in codes.codesById.values) {
      if (c.defaultLocalizationKey.isEmpty) {
        add('error', 'missing_loc_key', c.explanationCode);
      }
    }
    if (config.highConfidenceThreshold < config.moderateConfidenceThreshold) {
      add('error', 'threshold_order', 'high < moderate');
    }

    final eval = ExplanationV1Helpers.evalAllEqual(0.9, 1.0);
    final structural = ExplanationV1Helpers.structuralProfile(
      iq: ExplanationV1Helpers.moduleResult(
        module: AssessmentModuleId.iq,
        comparisons: [
          ExplanationV1Helpers.dimCompare(
            id: 'logical_reasoning',
            module: AssessmentModuleId.iq,
            absDiff: 0.1,
          ),
        ],
      ),
    );
    final r = ExplanationV1Helpers.explain(
      structural: structural,
      evaluation: eval,
    );
    for (final s in r.signals) {
      if (!codes.codesById.containsKey(s.explanationCode)) {
        add('error', 'undocumented_code', s.explanationCode);
      }
    }
    if (r.overallRawScore != eval.overallScoreResult.rawScore ||
        r.confidenceAdjustedScore !=
            eval.overallScoreResult.confidenceAdjustedScore) {
      add('error', 'score_modified', 'explanation changed scores');
    }
    if (r.diagnostics.aiGenerated ||
        r.diagnostics.personaInputUsed ||
        r.diagnostics.frequencyTypeUsed ||
        r.diagnostics.scoreModified) {
      add('error', 'prohibited_diag', 'flag set');
    }

    final hard = ExplanationV1Helpers.hardResult(
      outcome: HardConstraintOutcome.failed,
      aToB: [
        ExplanationV1Helpers.hardEval(
          id: 'hc1',
          field: 'children_preference',
          outcome: HardConstraintOutcome.failed,
        ),
      ],
    );
    final values = ExplanationV1Helpers.mutualValue(
      aToB: ExplanationV1Helpers.directionalValue(
        owner: 'A',
        evaluated: 'B',
        fields: [
          ExplanationV1Helpers.valueField(fieldId: 'syn_a', fit: 0.9),
        ],
      ),
      bToA: ExplanationV1Helpers.directionalValue(
        owner: 'B',
        evaluated: 'A',
        fields: [
          ExplanationV1Helpers.valueField(
            fieldId: 'syn_a',
            fit: 0.9,
            owner: 'B',
            evaluated: 'A',
          ),
        ],
      ),
    );
    final blocked = ExplanationV1Helpers.explain(
      layer: ExplanationV1Helpers.layer(values: values, hard: hard),
      evaluation: ExplanationV1Helpers.evalAllEqual(
        0.8,
        1.0,
        hard: HardConstraintOutcome.failed,
      ),
    );
    if (blocked.signals.isEmpty || !blocked.signals.first.blocking) {
      add('error', 'hard_precedence', 'blocking not first');
    }

    final encoded = jsonEncode(blocked.toJson());
    if (encoded.contains('"text"') || encoded.contains('"prose"')) {
      add('error', 'free_form_text', 'unexpected prose field');
    }

    for (final path in [
      'lib/core/utils/compatibility_scoring.dart',
      'lib/features/discover/services/discover_service.dart',
    ]) {
      final text = File(path).readAsStringSync();
      if (text.contains('StructuredCompatibilityExplanationService') ||
          text.contains('structured_explanation')) {
        add('error', 'production_import', path);
      }
    }

    final svc = File(
      'lib/features/assessment/domain/core_method_v2/structured_compatibility_explanation_service.dart',
    ).readAsStringSync();
    for (final name in [
      'StructuralSimilarityService(',
      'DirectionalPreferenceFitService(',
      'RelationshipValueComparisonService(',
      'HardConstraintEvaluationService(',
      'SoftConflictEvaluationService(',
      'CoreMethodV2AggregationService(',
      'firebase',
      'Firestore',
    ]) {
      if (svc.contains(name)) add('error', 'forbidden_dep', name);
    }
  } catch (e, st) {
    add('error', 'exception', '$e\n$st');
  }

  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_structured_compatibility_explanation_v1',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'finding_count': findings.length,
    'findings': findings,
  });
  AggregationV1Helpers.writeJson(outPath, report);
  stdout.writeln(jsonEncode({'status': report['status'], 'errors': errors}));
  if (errors > 0) exit(1);
}
