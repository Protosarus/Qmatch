// Offline validator for Core Method v2 domain contracts (P2B-0).
// Usage: dart run tool/validate_core_method_v2_contracts.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outDir = 'tool/core_method_v2_out';
const reportName = 'validate_core_method_v2_contracts_report.json';

void main() {
  final root = Directory.current.path;
  final findings = <Map<String, String>>[];
  void add(String severity, String code, String message) {
    findings.add({'severity': severity, 'code': code, 'message': message});
  }

  final paths = <String, String>{
    'dimension_registry':
        'assets/data/core_method_v2/canonical_dimension_registry_v1.json',
    'value_registry':
        'assets/data/core_method_v2/relationship_value_registry_v1.json',
    'config': 'assets/data/core_method_v2/core_method_v2_config_v1.json',
    'freeze':
        'assets/data/core_method_v2/p2a_assessment_engineering_freeze_manifest_v1.json',
    'schema_dim':
        'assets/schemas/core_method_v2/canonical_dimension_registry_v1.schema.json',
    'schema_val':
        'assets/schemas/core_method_v2/relationship_value_registry_v1.schema.json',
    'schema_cfg':
        'assets/schemas/core_method_v2/core_method_v2_config_v1.schema.json',
    'schema_freeze':
        'assets/schemas/core_method_v2/p2a_assessment_engineering_freeze_manifest_v1.schema.json',
    'docs_contracts': 'docs/core_engine/core_method_v2_domain_contracts.md',
    'docs_freeze':
        'docs/core_engine/p2a_assessment_engineering_freeze_manifest_v1.md',
    'fixture_24':
        'assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
  };

  for (final e in paths.entries) {
    if (!File('$root/${e.value}').existsSync()) {
      add('error', 'missing_${e.key}', e.value);
    }
  }

  CanonicalDimensionRegistry? dimReg;
  RelationshipValueRegistry? valReg;
  CoreMethodV2Config? cfg;
  P2aAssessmentEngineeringFreezeManifest? freeze;

  try {
    dimReg = CanonicalDimensionRegistry.loadFile(
      '$root/${paths['dimension_registry']}',
    );
    if (dimReg.activeCount != 20) {
      add('error', 'active_count', 'expected 20 got ${dimReg.activeCount}');
    }
    final iq = dimReg.dimsForModule(AssessmentModuleId.iq).length;
    final eq = dimReg.dimsForModule(AssessmentModuleId.eq).length;
    final fr = dimReg.dimsForModule(AssessmentModuleId.frequency).length;
    if (iq != 4 || eq != 10 || fr != 6) {
      add('error', 'module_counts', 'iq=$iq eq=$eq frequency=$fr');
    }
  } catch (e) {
    add('error', 'dimension_registry_parse', e.toString());
  }

  try {
    valReg = RelationshipValueRegistry.loadFile(
      '$root/${paths['value_registry']}',
    );
    for (final f in valReg.fields) {
      if (!f.directlyAskedOnly || !f.inferenceProhibited) {
        add('error', 'sensitive_policy', f.fieldId);
      }
    }
  } catch (e) {
    add('error', 'value_registry_parse', e.toString());
  }

  try {
    cfg = CoreMethodV2Config.loadFile('$root/${paths['config']}');
  } catch (e) {
    add('error', 'config_parse', e.toString());
  }

  try {
    freeze = P2aAssessmentEngineeringFreezeManifest.loadFile(
      '$root/${paths['freeze']}',
    );
    for (final err in freeze.verifyArtifactHashes(root)) {
      add('error', err.reasonCode, '${err.fieldPath}: ${err.explanation}');
    }
    if (freeze.scientificallyValidated) {
      add('error', 'freeze_claims_science', 'must be false');
    }
  } catch (e) {
    add('error', 'freeze_parse', e.toString());
  }

  try {
    final fixture = CanonicalDimensionRegistry.loadFile(
      '$root/${paths['fixture_24']}',
    );
    if (fixture.dimensions.length != 24) {
      add('error', 'fixture_24_count', '${fixture.dimensions.length}');
    }
  } catch (e) {
    add('error', 'fixture_24_parse', e.toString());
  }

  // No Firebase imports in core_method_v2 domain.
  final domainDir =
      Directory('$root/lib/features/assessment/domain/core_method_v2');
  for (final f in domainDir.listSync().whereType<File>()) {
    final text = f.readAsStringSync();
    for (final bad in [
      'cloud_firestore',
      'firebase_auth',
      'firebase_core',
      'package:qmatch/features/discover',
      'CompatibilityScoring',
      'PersonaScoringService',
    ]) {
      if (text.contains(bad)) {
        add('error', 'domain_dependency', '${f.path}: $bad');
      }
    }
    if (RegExp(r'dimensionCount\s*=\s*20').hasMatch(text)) {
      add('error', 'hardcoded_dimension_count', f.path);
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
    'validator': 'validate_core_method_v2_contracts',
    'phase': 'P2B-0',
    'status': errors == 0 ? 'PASS' : 'FAIL',
    'error_count': errors,
    'finding_count': findings.length,
    'active_dimension_count': dimReg?.activeCount,
    'value_field_count': valReg?.fields.length,
    'config_version': cfg?.configVersion,
    'freeze_artifact_count': freeze?.artifacts.length,
    'findings': findings,
  });

  final out = Directory('$root/$outDir');
  out.createSync(recursive: true);
  final reportPath = '${out.path}/$reportName';
  File(reportPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );

  stdout.writeln(jsonEncode({
    'status': report['status'],
    'error_count': errors,
    'report': reportPath,
  }));
  exit(errors == 0 ? 0 : 1);
}
