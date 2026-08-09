// Offline validator for relationship-value comparison config (P2B-3).
// Usage: dart run tool/validate_relationship_value_comparison_v1.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/validate_relationship_value_comparison_v1_report.json';

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
    config.validateAgainstRegistry(registry);

    if (!File(
            '$root/assets/schemas/core_method_v2/relationship_value_comparison_config_v1.schema.json')
        .existsSync()) {
      add('error', 'schema_missing', 'schema file missing');
    }

    // Exact / flexibility / mutual smoke
    const service = RelationshipValueComparisonService();
    RelationshipValueResponse resp(
      String field,
      String value, {
      double importance = 0.8,
      double flexibility = 0.0,
    }) =>
        RelationshipValueResponse(
          fieldId: field,
          selectedValue: value,
          selectedValues: const [],
          importance: importance,
          flexibility: flexibility,
          explicitlyProvided: true,
          responseTimestamp: DateTime.utc(2026, 1, 1),
          registryVersion: registry.registryVersion,
          visibilityPolicy: 'internal_comparison_allowed',
          comparisonPermission: true,
        );

    CompatibilitySubjectSnapshot snap(
      String id,
      Map<String, RelationshipValueResponse> responses,
    ) =>
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
          hardConstraints: const [],
          snapshotVersion: 'v1',
          createdAt: null,
        );

    final a = snap('A', {
      'monogamy_expectation':
          resp('monogamy_expectation', 'monogamous', flexibility: 0),
    });
    final bSame = snap('B', {
      'monogamy_expectation': resp('monogamy_expectation', 'monogamous'),
    });
    final bDiff = snap('B', {
      'monogamy_expectation':
          resp('monogamy_expectation', 'open_to_non_monogamy'),
    });
    final eq = service.evaluateDirectional(
      preferenceOwner: a,
      evaluatedSubject: bSame,
      registry: registry,
      config: config,
    );
    final ne = service.evaluateDirectional(
      preferenceOwner: a,
      evaluatedSubject: bDiff,
      registry: registry,
      config: config,
    );
    if (eq.rawValueFitScore != 1.0) {
      add('error', 'exact_match_equal', '${eq.rawValueFitScore}');
    }
    if (ne.rawValueFitScore != 0.0) {
      add('error', 'exact_match_diff', '${ne.rawValueFitScore}');
    }

    final flex1 = service.evaluateDirectional(
      preferenceOwner: snap('A', {
        'monogamy_expectation':
            resp('monogamy_expectation', 'monogamous', flexibility: 1),
      }),
      evaluatedSubject: bDiff,
      registry: registry,
      config: config,
    );
    if (flex1.rawValueFitScore != 1.0) {
      add('error', 'flexibility_one', '${flex1.rawValueFitScore}');
    }

    final ma = snap('A', {
      'marriage_intent':
          resp('marriage_intent', 'yes', flexibility: 0, importance: 0.9),
    });
    final mb = snap('B', {
      'marriage_intent':
          resp('marriage_intent', 'maybe', flexibility: 0, importance: 0.9),
    });
    final mutual = service.evaluateMutual(
      subjectA: ma,
      subjectB: mb,
      registry: registry,
      config: config,
    );
    final expected = math.sqrt(mutual.subjectAToBResult.rawValueFitScore! *
        mutual.subjectBToAResult.rawValueFitScore!);
    if ((mutual.mutualRawValueFitScore! - expected).abs() > 1e-12) {
      add('error', 'mutual_geom', '${mutual.mutualRawValueFitScore}');
    }
    final rev = service.evaluateMutual(
      subjectA: mb,
      subjectB: ma,
      registry: registry,
      config: config,
    );
    if (rev.mutualRawValueFitScore != mutual.mutualRawValueFitScore) {
      add('error', 'reversal_mutual', 'changed');
    }

    // No production imports
    for (final path in [
      'lib/core/utils/compatibility_scoring.dart',
      'lib/features/discover/services/discover_service.dart',
    ]) {
      final t = File('$root/$path').readAsStringSync();
      if (t.contains('RelationshipValueComparisonService')) {
        add('error', 'production_import', path);
      }
    }
  } catch (e) {
    add('error', 'exception', e.toString());
  }

  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_relationship_value_comparison_v1',
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
