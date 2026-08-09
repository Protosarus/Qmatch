// Offline validator for hard-constraint + soft-conflict layer (P2B-3).
// Usage: dart run tool/validate_hard_soft_conflict_v1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/validate_hard_soft_conflict_v1_report.json';

void main() {
  final root = Directory.current.path;
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  try {
    final registry = RelationshipValueRegistry.loadFile(
      '$root/assets/data/core_method_v2/relationship_value_registry_v1.json',
    );
    final config = RelationshipValueComparisonConfig.loadFile(
      '$root/assets/data/core_method_v2/relationship_value_comparison_config_v1.json',
    );
    const hard = HardConstraintEvaluationService();
    const values = RelationshipValueComparisonService();
    const soft = SoftConflictEvaluationService();

    RelationshipValueResponse resp(String field, String? value,
            {bool permission = true,
            String visibility = 'internal_comparison_allowed'}) =>
        RelationshipValueResponse(
          fieldId: field,
          selectedValue: value,
          selectedValues: const [],
          importance: 0.8,
          flexibility: 0.1,
          explicitlyProvided: value != null,
          responseTimestamp: DateTime.utc(2026, 1, 1),
          registryVersion: registry.registryVersion,
          visibilityPolicy: visibility,
          comparisonPermission: permission,
        );

    CompatibilitySubjectSnapshot snap(
      String id, {
      Map<String, RelationshipValueResponse> responses = const {},
      List<HardConstraint> constraints = const [],
    }) =>
        CompatibilitySubjectSnapshot(
          subjectId: id,
          assessmentProfile: CanonicalUserAssessmentProfile(
            snapshotId: id,
            profileSchemaVersion: 'v1',
            registryVersion: 'canonical_dimension_registry_v1',
            iq: null,
            eq: null,
            frequency: null,
            publishedMeasurements: const {},
            unavailableDimensions: const [],
            createdAt: null,
            updatedAt: null,
            sourceAssessmentVersions: const [],
            overallAssessmentCoverage: 0,
            profileReadinessStatus: ProfileReadinessStatus.provisional,
          ),
          partnerPreferenceProfile: PartnerPreferenceProfile(
            preferences: const {},
            profileVersion: 'v1',
            registryVersion: 'canonical_dimension_registry_v1',
            createdAt: null,
            updatedAt: null,
            completionStatus: PreferenceProfileCompletionStatus.incomplete,
            explicitlyAnsweredDimensions: const [],
            openDimensions: const [],
            unavailableDimensions: const [],
          ),
          relationshipValueProfile: RelationshipValueProfile(
            responses: responses,
            profileVersion: 'v1',
            registryVersion: registry.registryVersion,
            createdAt: null,
            updatedAt: null,
          ),
          hardConstraints: constraints,
          snapshotVersion: 'v1',
          createdAt: null,
        );

    HardConstraint hc({
      required String id,
      required String field,
      List<String> accepted = const [],
      List<String> rejected = const [],
      bool enabled = true,
    }) =>
        HardConstraint(
          constraintId: id,
          fieldId: field,
          acceptedValues: accepted,
          rejectedValues: rejected,
          explicitlyEnabled: enabled,
          source: 'user',
          updatedAt: null,
          registryVersion: registry.registryVersion,
        );

    final disabled = hard.evaluateDirectional(
      preferenceOwner: snap('A', constraints: [
        hc(
            id: 'd',
            field: 'smoking_preference',
            accepted: ['non_smoker_only'],
            enabled: false),
      ]),
      evaluatedSubject: snap('B', responses: {
        'smoking_preference': resp('smoking_preference', 'smokes'),
      }),
      registry: registry,
      config: config,
    );
    if (disabled.aggregateOutcome != HardConstraintOutcome.notApplicable) {
      add('error', 'disabled', disabled.aggregateOutcome.wire);
    }

    final passed = hard.evaluateDirectional(
      preferenceOwner: snap('A', constraints: [
        hc(id: 'p', field: 'smoking_preference', accepted: ['non_smoker_only']),
      ]),
      evaluatedSubject: snap('B', responses: {
        'smoking_preference': resp('smoking_preference', 'non_smoker_only'),
      }),
      registry: registry,
      config: config,
    );
    if (passed.aggregateOutcome != HardConstraintOutcome.passed) {
      add('error', 'passed', passed.aggregateOutcome.wire);
    }

    final failed = hard.evaluateDirectional(
      preferenceOwner: snap('A', constraints: [
        hc(id: 'f', field: 'smoking_preference', rejected: ['smokes']),
      ]),
      evaluatedSubject: snap('B', responses: {
        'smoking_preference': resp('smoking_preference', 'smokes'),
      }),
      registry: registry,
      config: config,
    );
    if (failed.aggregateOutcome != HardConstraintOutcome.failed) {
      add('error', 'failed', failed.aggregateOutcome.wire);
    }

    final unknown = hard.evaluateDirectional(
      preferenceOwner: snap('A', constraints: [
        hc(id: 'u', field: 'smoking_preference', accepted: ['non_smoker_only']),
      ]),
      evaluatedSubject: snap('B'),
      registry: registry,
      config: config,
    );
    if (unknown.aggregateOutcome != HardConstraintOutcome.unknown) {
      add('error', 'unknown', unknown.aggregateOutcome.wire);
    }
    if (jsonEncode(failed.toJson()).contains('hard_score')) {
      add('error', 'numeric_hard_score', 'present');
    }

    // Soft severity
    final a = snap('A', responses: {
      'monogamy_expectation': RelationshipValueResponse(
        fieldId: 'monogamy_expectation',
        selectedValue: 'monogamous',
        selectedValues: const [],
        importance: 0.9,
        flexibility: 0.0,
        explicitlyProvided: true,
        responseTimestamp: null,
        registryVersion: registry.registryVersion,
        visibilityPolicy: 'internal_comparison_allowed',
        comparisonPermission: true,
      ),
    });
    final b = snap('B', responses: {
      'monogamy_expectation':
          resp('monogamy_expectation', 'open_to_non_monogamy'),
    });
    final mutual = values.evaluateMutual(
      subjectA: a,
      subjectB: b,
      registry: registry,
      config: config,
    );
    final softResult = soft.evaluate(mutualValues: mutual, config: config);
    final sev = softResult.subjectAToBSignals.single.severity;
    if ((sev - 0.9).abs() > 1e-12) {
      add('error', 'soft_severity', '$sev');
    }
    if (softResult.mutualSignals.single.mutualSeverity != sev) {
      add('error', 'soft_mutual_max', 'mismatch');
    }

    // Soft does not create hard failure
    final layer = RelationshipCompatibilityLayerResult.assemble(
      mutualValueResult: mutual,
      mutualHardConstraintResult: hard.evaluateMutual(
        subjectA: a,
        subjectB: b,
        registry: registry,
        config: config,
      ),
      softConflictResult: softResult,
    );
    if (layer.futureFinalResultShouldBeBlocked) {
      add('error', 'soft_should_not_block', 'blocked');
    }
    if (layer.toJson().containsKey('overall_compatibility_score')) {
      add('error', 'final_score', 'present');
    }

    // Accepted/rejected overlap validation
    try {
      HardConstraint(
        constraintId: 'bad',
        fieldId: 'smoking_preference',
        acceptedValues: const ['smokes'],
        rejectedValues: const ['smokes'],
        explicitlyEnabled: true,
        source: 'user',
        updatedAt: null,
        registryVersion: registry.registryVersion,
      ).validate(registry);
      add('error', 'overlap_should_fail', 'did not throw');
    } catch (_) {}
  } catch (e) {
    add('error', 'exception', e.toString());
  }

  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_hard_soft_conflict_v1',
    'phase': 'P2B-3',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'finding_count': findings.length,
    'findings': findings,
  });
  Directory('$root/tool/core_method_v2_out').createSync(recursive: true);
  File('$root/$outPath').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(jsonEncode({
    'status': report['status'],
    'error_count': errors,
    'report': '$root/$outPath',
  }));
  if (errors > 0) exit(1);
}
