// Offline validator for Core Method v2 aggregation (P2B-4).
// Usage: dart run tool/validate_core_method_v2_aggregation_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../test/support/aggregation_v1_helpers.dart';

const outPath =
    'tool/core_method_v2_out/validate_core_method_v2_aggregation_v1_report.json';

void main() {
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  try {
    final config = AggregationV1Helpers.loadConfig();
    final schema =
        jsonDecode(File(AggregationV1Helpers.schemaPath).readAsStringSync())
            as Map<String, dynamic>;

    // Schema required keys.
    final required =
        (schema['required'] as List).map((e) => e.toString()).toSet();
    final cfgJson = config.toJson();
    for (final k in required) {
      if (!cfgJson.containsKey(k) &&
          k != 'scientifically_validated' &&
          !File(AggregationV1Helpers.configPath)
              .readAsStringSync()
              .contains('"$k"')) {
        // raw file check for keys not in toJson
      }
    }
    final rawCfg =
        jsonDecode(File(AggregationV1Helpers.configPath).readAsStringSync())
            as Map<String, dynamic>;
    for (final k in required) {
      if (!rawCfg.containsKey(k)) {
        add('error', 'schema_missing_key', k);
      }
    }

    if (config.componentWeights.length != 5) {
      add('error', 'component_count', '${config.componentWeights.length}');
    }
    for (final id in CoreMethodAggregationConfig.configuredComponentIds) {
      if (!config.componentWeights.containsKey(id)) {
        add('error', 'missing_component', id);
      }
      final w = config.componentWeights[id]!;
      if (!w.isFinite || w <= 0) {
        add('error', 'invalid_weight', '$id=$w');
      }
    }
    final sum = config.componentWeights.values.fold<double>(0, (a, b) => a + b);
    if ((sum - 1.0).abs() > config.weightSumTolerance) {
      add('error', 'weight_sum', '$sum');
    }

    // Weight derivation check.
    final expected = {
      'iq_structural': 0.08,
      'eq_structural': 0.24,
      'frequency_structural': 0.28,
      'mutual_partner_preference': 0.20,
      'mutual_relationship_values': 0.20,
    };
    for (final e in expected.entries) {
      if ((config.componentWeights[e.key]! - e.value).abs() > 1e-12) {
        add('error', 'weight_derivation', e.key);
      }
    }

    if (config.neutralScore != 0.5) {
      add('error', 'neutral_score', '${config.neutralScore}');
    }
    if (config.minimumAvailableComponentCount != 2) {
      add('error', 'min_count', '${config.minimumAvailableComponentCount}');
    }
    if ((config.minimumAvailableWeightMass - 0.5).abs() > 1e-12) {
      add('error', 'min_mass', '${config.minimumAvailableWeightMass}');
    }

    const svc = CoreMethodV2AggregationService();

    // Raw formula + renormalization.
    final mixed = AggregationV1Helpers.withScores({
      'iq_structural': 1.0,
      'eq_structural': 0.5,
      'frequency_structural': 0.0,
      'mutual_partner_preference': 0.8,
      'mutual_relationship_values': 0.2,
    });
    final r1 = svc.aggregateComponents(
      componentInputs: mixed,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
      evaluationTimestamp: DateTime.utc(2026, 7, 24),
    );
    final expectedRaw =
        (0.08 * 1.0 + 0.24 * 0.5 + 0.28 * 0.0 + 0.20 * 0.8 + 0.20 * 0.2) / 1.0;
    if (!AggregationV1Helpers.nearly(r1.rawScore, expectedRaw)) {
      add('error', 'raw_formula', '${r1.rawScore} != $expectedRaw');
    }
    final contribSum = r1.componentContributions
        .where((c) => c.weightedRawContribution != null)
        .fold<double>(0, (a, b) => a + b.weightedRawContribution!);
    if (!AggregationV1Helpers.nearly(contribSum, r1.rawScore)) {
      add('error', 'contrib_sum', '$contribSum');
    }
    final qSum = r1.componentContributions
        .where((c) => c.weightedConfidenceContribution != null)
        .fold<double>(0, (a, b) => a + b.weightedConfidenceContribution!);
    if (!AggregationV1Helpers.nearly(qSum, r1.overallEvidenceConfidence)) {
      add('error', 'q_contrib_sum', '$qSum');
    }
    if (!AggregationV1Helpers.nearly(
      r1.overallEvidenceConfidence,
      r1.availableConfiguredWeightMass * r1.availableComponentMeanConfidence!,
    )) {
      add('error', 'q_identity', 'Q != M*Qmean');
    }

    // Neutral shrinkage identity.
    final adj = r1.overallEvidenceConfidence! * r1.rawScore! +
        (1 - r1.overallEvidenceConfidence!) * config.neutralScore;
    if (!AggregationV1Helpers.nearly(r1.confidenceAdjustedScore, adj)) {
      add('error', 'shrinkage', '${r1.confidenceAdjustedScore}');
    }

    // Missing component: exclude without imputation.
    final missIq =
        AggregationV1Helpers.allEqual(0.9, 1.0, exclude: {'iq_structural'});
    final rMiss = svc.aggregateComponents(
      componentInputs: missIq,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
    );
    final expectedMissRaw =
        (0.24 * 0.9 + 0.28 * 0.9 + 0.20 * 0.9 + 0.20 * 0.9) / 0.92;
    if (!AggregationV1Helpers.nearly(rMiss.rawScore, expectedMissRaw)) {
      add('error', 'missing_renorm', '${rMiss.rawScore}');
    }
    if (!AggregationV1Helpers.nearly(rMiss.rawScore, 0.9)) {
      add('error', 'missing_should_not_lower_raw', '${rMiss.rawScore}');
    }
    if (!AggregationV1Helpers.nearly(rMiss.overallEvidenceConfidence, 0.92)) {
      add('error', 'missing_lowers_q', '${rMiss.overallEvidenceConfidence}');
    }

    // Hard failed.
    final rFail = svc.aggregateComponents(
      componentInputs: AggregationV1Helpers.allEqual(1, 1),
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.failed,
      failedHardConstraintIds: const ['hc_1'],
    );
    if (rFail.rawScore != null || rFail.confidenceAdjustedScore != null) {
      add('error', 'hard_failed_scores', 'must be null');
    }
    if (rFail.evaluationStatus !=
        CompatibilityEvaluationStatus.blockedByHardConstraint) {
      add('error', 'hard_failed_status', rFail.evaluationStatus.wire);
    }
    if (rFail.publishable || rFail.rankingEligible) {
      add('error', 'hard_failed_publish', 'must be false');
    }

    // Hard unknown.
    final rUnk = svc.aggregateComponents(
      componentInputs: AggregationV1Helpers.allEqual(0.8, 1),
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.unknown,
    );
    if (rUnk.rawScore == null) {
      add('error', 'hard_unknown_scores', 'should retain offline scores');
    }
    if (rUnk.publishable || rUnk.rankingEligible) {
      add('error', 'hard_unknown_publish', 'must be false');
    }
    if (rUnk.evaluationStatus != CompatibilityEvaluationStatus.partial) {
      add('error', 'hard_unknown_status', rUnk.evaluationStatus.wire);
    }
    if (!rUnk.diagnosticCodes.contains('hard_constraint_resolution_required')) {
      add('error', 'hard_unknown_code', 'missing resolution code');
    }

    // Hard passed / not_applicable.
    for (final h in [
      HardConstraintOutcome.passed,
      HardConstraintOutcome.notApplicable,
    ]) {
      final r = svc.aggregateComponents(
        componentInputs: AggregationV1Helpers.allEqual(0.7, 1),
        config: config,
        hardConstraintOutcome: h,
      );
      if (r.rawScore == null) {
        add('error', 'hard_${h.wire}_scores', 'missing');
      }
      if (h == HardConstraintOutcome.notApplicable &&
          r.hardConstraintOutcome != HardConstraintOutcome.notApplicable) {
        add('error', 'not_applicable_relabel', r.hardConstraintOutcome.wire);
      }
    }

    // Insufficient evidence.
    final oneOnly = AggregationV1Helpers.withScores({'iq_structural': 1.0});
    final rInsuf = svc.aggregateComponents(
      componentInputs: oneOnly,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
    );
    if (rInsuf.rawScore != null ||
        rInsuf.confidenceAdjustedScore != null ||
        rInsuf.evaluationStatus !=
            CompatibilityEvaluationStatus.insufficientEvidence) {
      add('error', 'insufficient', rInsuf.evaluationStatus.wire);
    }

    // Soft conflict no penalty.
    final base = AggregationV1Helpers.allEqual(0.75, 1);
    final rBase = svc.aggregateComponents(
      componentInputs: base,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
    );
    final rSoft = svc.aggregateComponents(
      componentInputs: base,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
      softConflictSummary: CoreMethodSoftConflictSummary(
        lowCount: 0,
        moderateCount: 0,
        highCount: 1,
        highestMutualSeverity: 0.9,
        affectedFieldIds: const ['children_intent'],
        diagnosticCodes: const ['soft_conflicts_present_diagnostic_only'],
        softConflictPenaltyApplied: false,
      ),
    );
    if (!AggregationV1Helpers.nearly(rBase.rawScore, rSoft.rawScore) ||
        !AggregationV1Helpers.nearly(
            rBase.confidenceAdjustedScore, rSoft.confidenceAdjustedScore) ||
        !AggregationV1Helpers.nearly(
            rBase.overallEvidenceConfidence, rSoft.overallEvidenceConfidence)) {
      add('error', 'soft_penalty', 'scores changed');
    }
    if (rSoft.diagnostics.softConflictPenaltyApplied) {
      add('error', 'soft_penalty_flag', 'true');
    }

    // Asymmetry no penalty.
    final rAsym = svc.aggregateComponents(
      componentInputs: base,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
      asymmetrySummary: const CoreMethodAsymmetrySummary(
        preferenceDirectionalAsymmetry: 0.4,
        valueDirectionalAsymmetry: 0.35,
        diagnosticCodes: [
          'preference_asymmetry_present',
          'value_asymmetry_present',
        ],
        asymmetryPenaltyApplied: false,
      ),
    );
    if (!AggregationV1Helpers.nearly(rBase.rawScore, rAsym.rawScore)) {
      add('error', 'asymmetry_penalty', 'raw changed');
    }

    // Prohibited statuses.
    if (config.personaInputStatus != 'prohibited' ||
        config.frequencyTypeStatus != 'prohibited' ||
        config.aiScoringStatus != 'prohibited' ||
        config.complementarityStatus != 'disabled_pending_calibration' ||
        config.productionApprovalStatus != 'not_approved') {
      add('error', 'prohibited_status', 'policy drift');
    }

    // No production imports (static search via file read).
    for (final path in [
      'lib/core/utils/compatibility_scoring.dart',
      'lib/features/discover/services/discover_service.dart',
    ]) {
      final text = File(path).readAsStringSync();
      if (text.contains('CoreMethodV2AggregationService') ||
          text.contains('core_method_v2_aggregation')) {
        add('error', 'production_import', path);
      }
    }

    // Map order independence.
    final ordered = Map<String, CoreMethodComponentInput>.from(mixed);
    final shuffled = Map<String, CoreMethodComponentInput>.fromEntries(
      ordered.entries.toList().reversed,
    );
    final rOrd = svc.aggregateComponents(
      componentInputs: ordered,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
    );
    final rShuf = svc.aggregateComponents(
      componentInputs: shuffled,
      config: config,
      hardConstraintOutcome: HardConstraintOutcome.passed,
    );
    if (rOrd.deterministicFingerprint != rShuf.deterministicFingerprint) {
      add('error', 'map_order', 'fingerprint drift');
    }
  } catch (e, st) {
    add('error', 'exception', '$e\n$st');
  }

  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_core_method_v2_aggregation_v1',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'finding_count': findings.length,
    'findings': findings,
  });
  AggregationV1Helpers.writeJson(outPath, report);
  stdout.writeln(jsonEncode({'status': report['status'], 'errors': errors}));
  if (errors > 0) exit(1);
}
