// Offline validator for directional preference fit v1 (P2B-2).
// Usage: dart run tool/validate_directional_preference_fit_v1.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/validate_directional_preference_fit_v1_report.json';

void main() {
  final root = Directory.current.path;
  final findings = <Map<String, String>>[];
  void add(String sev, String code, String msg) =>
      findings.add({'severity': sev, 'code': code, 'message': msg});

  final paths = {
    'config':
        'assets/data/core_method_v2/directional_preference_fit_config_v1.json',
    'schema':
        'assets/schemas/core_method_v2/directional_preference_fit_config_v1.schema.json',
    'registry':
        'assets/data/core_method_v2/canonical_dimension_registry_v1.json',
    'fixture24':
        'assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
    'contract':
        'docs/core_engine/directional_partner_preference_fit_contract_v1.md',
  };
  for (final e in paths.entries) {
    if (!File('$root/${e.value}').existsSync()) {
      add('error', 'missing_${e.key}', e.value);
    }
  }

  PartnerPreferenceFitConfig? cfg;
  CanonicalDimensionRegistry? reg;
  try {
    cfg = PartnerPreferenceFitConfig.loadFile('$root/${paths['config']}');
  } catch (e) {
    add('error', 'config_parse', e.toString());
  }
  try {
    reg = CanonicalDimensionRegistry.loadFile('$root/${paths['registry']}');
  } catch (e) {
    add('error', 'registry_parse', e.toString());
  }

  if (cfg != null && reg != null) {
    if (cfg.registryVersion != reg.registryVersion) {
      add('error', 'registry_version', 'mismatch');
    }
    if (!(cfg.minimumFlexibilityScale > 0 &&
        cfg.maximumFlexibilityScale >= cfg.minimumFlexibilityScale)) {
      add('error', 'flexibility_scales', 'invalid');
    }
    const service = DirectionalPreferenceFitService();
    final dim = reg.dimsForModule(AssessmentModuleId.eq).first.dimensionId;

    CompatibilitySubjectSnapshot snap({
      required String id,
      required double score,
      PartnerDimensionPreference? pref,
      double confidence = 0.8,
    }) {
      final meas = DimensionMeasurement(
        dimensionId: dim,
        module: AssessmentModuleId.eq,
        normalizedScore: score,
        confidence: confidence,
        uncertainty: 0.2,
        primaryEvidenceCount: 1,
        secondaryEvidenceCount: 0,
        independentContextCount: 1,
        publicationStatus: DimensionPublicationStatus.published,
        publishability: true,
        sourceContentVersions: const ['v'],
        measurementTimestamp: DateTime.utc(2026, 1, 1),
        scoringContractVersion: 'trait_scoring_config_v1',
        registryVersion: reg!.registryVersion,
      );
      final mod = ModuleAssessmentProfile(
        module: AssessmentModuleId.eq,
        measurements: {dim: meas},
        assessmentFormId: 'eq',
        contentVersion: 'v',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: DateTime.utc(2026, 1, 1),
        moduleConfidence: 0.8,
        evidenceCoverage: 0.1,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: reg.registryVersion,
      );
      final assessment = CanonicalUserAssessmentProfile(
        snapshotId: id,
        profileSchemaVersion: 'v1',
        registryVersion: reg.registryVersion,
        iq: null,
        eq: mod,
        frequency: null,
        publishedMeasurements:
            CanonicalUserAssessmentProfile.flattenPublished(eq: mod),
        unavailableDimensions: const [],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        sourceAssessmentVersions: const ['v'],
        overallAssessmentCoverage: 0.1,
        profileReadinessStatus: ProfileReadinessStatus.provisional,
      );
      final prefs = <String, PartnerDimensionPreference>{
        if (pref != null) dim: pref,
      };
      return CompatibilitySubjectSnapshot(
        subjectId: id,
        assessmentProfile: assessment,
        partnerPreferenceProfile: PartnerPreferenceProfile(
          preferences: prefs,
          profileVersion: 'v1',
          registryVersion: reg.registryVersion,
          createdAt: null,
          updatedAt: null,
          completionStatus: PreferenceProfileCompletionStatus.partial,
          explicitlyAnsweredDimensions: prefs.keys.toList()..sort(),
          openDimensions: const [],
          unavailableDimensions: const [],
        ),
        relationshipValueProfile: RelationshipValueProfile(
          responses: const {},
          profileVersion: 'v1',
          registryVersion: 'relationship_value_registry_v1',
          createdAt: null,
          updatedAt: null,
        ),
        hardConstraints: const [],
        snapshotVersion: 'v1',
        createdAt: DateTime.utc(2026, 1, 1),
      );
    }

    PartnerDimensionPreference range(double L, double U, {double f = 0.5}) =>
        PartnerDimensionPreference(
          dimensionId: dim,
          preferredMin: L,
          preferredMax: U,
          importance: 0.8,
          flexibility: f,
          preferenceMode: PreferenceMode.range,
          source: 'explicit_user',
          explicitlyProvided: true,
          updatedAt: null,
        );

    final owner = snap(id: 'A', score: 0.5, pref: range(0.4, 0.6));
    final inside = service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: snap(id: 'B', score: 0.5),
      registry: reg,
      config: cfg,
    );
    if (inside.rawFitScore != 1.0) {
      add('error', 'inside_range', '${inside.rawFitScore}');
    }
    final near = service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: snap(id: 'B', score: 0.35),
      registry: reg,
      config: cfg,
    );
    final far = service.evaluateDirectional(
      preferenceOwner: owner,
      evaluatedSubject: snap(id: 'B', score: 0.0),
      registry: reg,
      config: cfg,
    );
    if (!(near.rawFitScore! > far.rawFitScore!)) {
      add('error', 'monotonic_range', 'near not > far');
    }
    final strict = service.evaluateDirectional(
      preferenceOwner: snap(id: 'A', score: 0.5, pref: range(0.4, 0.6, f: 0.0)),
      evaluatedSubject: snap(id: 'B', score: 0.2),
      registry: reg,
      config: cfg,
    );
    final flex = service.evaluateDirectional(
      preferenceOwner: snap(id: 'A', score: 0.5, pref: range(0.4, 0.6, f: 1.0)),
      evaluatedSubject: snap(id: 'B', score: 0.2),
      registry: reg,
      config: cfg,
    );
    if (!(flex.rawFitScore! > strict.rawFitScore!)) {
      add('error', 'flexibility_sensitivity', 'flex not > strict');
    }

    final simOwner = snap(
      id: 'A',
      score: 0.55,
      pref: PartnerDimensionPreference(
        dimensionId: dim,
        preferredMin: null,
        preferredMax: null,
        importance: 0.8,
        flexibility: 0.5,
        preferenceMode: PreferenceMode.similarityToSelf,
        source: 'explicit_user',
        explicitlyProvided: true,
        updatedAt: null,
      ),
    );
    final simId = service.evaluateDirectional(
      preferenceOwner: simOwner,
      evaluatedSubject: snap(id: 'B', score: 0.55),
      registry: reg,
      config: cfg,
    );
    if (simId.rawFitScore != 1.0) {
      add('error', 'similarity_identity', '${simId.rawFitScore}');
    }

    final a = snap(id: 'A', score: 0.5, pref: range(0.4, 0.6));
    final b = snap(id: 'B', score: 0.5, pref: range(0.8, 1.0));
    final mutual = service.evaluateMutual(
      subjectA: a,
      subjectB: b,
      registry: reg,
      config: cfg,
    );
    final expected = math.sqrt(
      mutual.subjectAToBResult.rawFitScore! *
          mutual.subjectBToAResult.rawFitScore!,
    );
    if ((mutual.mutualRawFitScore! - expected).abs() > 1e-12) {
      add('error', 'mutual_geometric_mean', '${mutual.mutualRawFitScore}');
    }
    final rev = service.evaluateMutual(
      subjectA: b,
      subjectB: a,
      registry: reg,
      config: cfg,
    );
    if (rev.mutualRawFitScore != mutual.mutualRawFitScore ||
        rev.directionalAsymmetry != mutual.directionalAsymmetry) {
      add('error', 'pair_reversal', 'mutual/asymmetry changed');
    }

    // Open not imputed
    final openOwner = snap(
      id: 'A',
      score: 0.5,
      pref: PartnerDimensionPreference(
        dimensionId: dim,
        preferredMin: null,
        preferredMax: null,
        importance: null,
        flexibility: null,
        preferenceMode: PreferenceMode.open,
        source: 'explicit_user',
        explicitlyProvided: true,
        updatedAt: null,
      ),
    );
    final openR = service.evaluateDirectional(
      preferenceOwner: openOwner,
      evaluatedSubject: snap(id: 'B', score: 0.9),
      registry: reg,
      config: cfg,
    );
    if (openR.rawFitScore != null) {
      add('error', 'open_scored', '${openR.rawFitScore}');
    }

    // 24-dim
    try {
      final f24 = CanonicalDimensionRegistry.loadFile(
        '$root/${paths['fixture24']}',
      );
      if (f24.dimensions.length != 24) {
        add('error', 'fixture24_count', '${f24.dimensions.length}');
      }
    } catch (e) {
      add('error', 'fixture24', e.toString());
    }

    final blob = jsonEncode(mutual.toJson());
    for (final bad in [
      'overall_compatibility',
      'persona_id',
      'frequency_type',
      'StructuralSimilarity',
    ]) {
      if (blob.contains(bad)) add('error', 'forbidden_field', bad);
    }
  }

  for (final rel in [
    'lib/core/utils/compatibility_scoring.dart',
    'lib/features/discover/services/discover_service.dart',
    'lib/features/assessment/services/question_service.dart',
  ]) {
    if (File('$root/$rel')
        .readAsStringSync()
        .contains('DirectionalPreferenceFitService')) {
      add('error', 'production_import', rel);
    }
  }
  for (final f in Directory(
    '$root/lib/features/assessment/domain/core_method_v2',
  ).listSync().whereType<File>()) {
    if (!f.path.contains('directional_preference')) continue;
    final t = f.readAsStringSync();
    if (t.contains('cloud_firestore') || t.contains('firebase_')) {
      add('error', 'firebase_dep', f.path);
    }
    if (t.contains('StructuralSimilarityService') &&
        !t.contains('Does not call structural similarity')) {
      add('error', 'structural_coupling', f.path);
    }
  }

  findings.sort((a, b) {
    final c = a['severity']!.compareTo(b['severity']!);
    if (c != 0) return c;
    final d = a['code']!.compareTo(b['code']!);
    if (d != 0) return d;
    return a['message']!.compareTo(b['message']!);
  });
  final errors = findings.where((f) => f['severity'] == 'error').length;
  final report = cmSortedMap({
    'validator': 'validate_directional_preference_fit_v1',
    'phase': 'P2B-2',
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
  exit(errors == 0 ? 0 : 1);
}
