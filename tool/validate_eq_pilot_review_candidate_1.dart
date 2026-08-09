// Offline validator for EQ pilot review candidate 1 (P2A-2C-2).
// Usage: dart run tool/validate_eq_pilot_review_candidate_1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

const candidatePath =
    'assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json';
const parentPath = 'assets/data/assessment_v3/eq/eq_pilot_tr_v1.json';
const redTeamPath = 'docs/core_engine/eq_pilot_tr_v1_red_team_review.md';
const changelogPath =
    'docs/core_engine/eq_pilot_tr_v1_review_candidate_1_changelog.md';
const evidencePath =
    'docs/core_engine/eq_pilot_tr_v1_review_candidate_1_evidence_review.md';
const strengthContractPath =
    'docs/core_engine/eq_evidence_strength_contract_v1.md';
const configPath = 'assets/data/trait_scoring_config_v1.json';
const pubspecPath = 'pubspec.yaml';

class Finding {
  final String severity;
  final String code;
  final String message;
  Finding(this.severity, this.code, this.message);
  Map<String, Object?> toJson() =>
      {'severity': severity, 'code': code, 'message': message};
}

void main() {
  final root = Directory.current.path;
  final findings = <Finding>[];
  void err(String c, String m) => findings.add(Finding('error', c, m));
  void warn(String c, String m) => findings.add(Finding('warn', c, m));
  void info(String c, String m) => findings.add(Finding('info', c, m));

  final parentFile = File('$root/$parentPath');
  final candFile = File('$root/$candidatePath');
  if (!parentFile.existsSync()) err('parent_missing', parentPath);
  if (!candFile.existsSync()) {
    stderr.writeln('missing candidate');
    exit(2);
  }

  final parent =
      jsonDecode(parentFile.readAsStringSync()) as Map<String, dynamic>;
  final form = jsonDecode(candFile.readAsStringSync()) as Map<String, dynamic>;
  final redTeam = File('$root/$redTeamPath').readAsStringSync();
  final changelog = File('$root/$changelogPath').readAsStringSync();
  final evidence = File('$root/$evidencePath').readAsStringSync();
  final contract = File('$root/$strengthContractPath').readAsStringSync();
  final pubspec = File('$root/$pubspecPath').readAsStringSync();

  if (parent['content_version'] != 'eq-tr-pilot-v1') {
    err('parent_mutated', 'parent content_version changed');
  }
  if (form['content_version'] != 'eq-tr-pilot-v1-review-candidate-1') {
    err('content_version', 'unexpected');
  }
  if (form['parent_content_version'] != 'eq-tr-pilot-v1') {
    err('lineage', 'parent_content_version mismatch');
  }
  if (form['form_id'] != 'eq_tr_pilot_v1_review_candidate_1') {
    err('form_id', 'unexpected');
  }
  if (form['status'] != 'internal_review') {
    err('status', 'expected internal_review');
  }
  if (form['review_state'] != 'red_team_reviewed') {
    err('review_state', 'expected red_team_reviewed');
  }
  if (form['calibration_status'] != 'uncalibrated') {
    err('calibration', 'must be uncalibrated');
  }

  final notes = Map<String, dynamic>.from(form['notes'] as Map? ?? {});
  if (notes['internal_language_review'] != 'completed') {
    err('internal_language_review', 'must be completed');
  }
  if (notes['expert_language_review'] != 'pending') {
    err('expert_language_review', 'must remain pending');
  }
  if (contract.contains('Single semantic meaning') == false) {
    err('strength_contract', 'contract incomplete');
  }

  if (pubspec.contains('eq_pilot_tr_v1_review_candidate_1')) {
    err('pubspec', 'candidate must not be runtime-loaded');
  }

  final items = (form['items'] as List?) ?? const [];
  if (items.length != 30) err('item_count', 'expected 30');

  final ids = <String>[];
  final idSet = <String>{};
  var flat072 = 0;
  final primaryCounts = <String, int>{};
  final blob = jsonEncode(form).toLowerCase();

  if (blob.contains('correct_option_id') || blob.contains('correctanswer')) {
    err('correct_answer', 'correct-answer fields forbidden');
  }
  if (blob.contains('persona_id') || blob.contains('persona_points')) {
    err('persona', 'persona scoring forbidden');
  }
  for (final a in PersonaDimensionIds.forbiddenAliases) {
    if (blob.contains('"$a"')) err('alias', a);
  }

  for (final raw in items) {
    final j = Map<String, dynamic>.from(raw as Map);
    final qid = j['question_id']?.toString() ?? '';
    if (qid.isEmpty || !idSet.add(qid)) err('id', 'bad/duplicate $qid');
    ids.add(qid);
    if (j['schema_version'] != 'qmatch_question_schema_v3') {
      err('schema', qid);
    }
    if (j['module'] != 'eq') err('module', qid);
    if (j['content_version'] != 'eq-tr-pilot-v1-review-candidate-1') {
      err('item_cv', qid);
    }
    if (j['calibration_status'] != 'uncalibrated') {
      err('item_calibration', qid);
    }
    final primary = j['primary_dimension']?.toString() ?? '';
    if (!PersonaDimensionIds.eq.contains(primary)) {
      err('primary', '$qid $primary');
    }
    primaryCounts[primary] = (primaryCounts[primary] ?? 0) + 1;
    for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
      if (!PersonaDimensionIds.eq.contains(s.toString())) {
        err('secondary', '$qid $s');
      }
    }
    final opts = (j['options'] as List?) ?? const [];
    if (opts.length != 4) err('options', qid);
    for (final oRaw in opts) {
      final o = Map<String, dynamic>.from(oRaw as Map);
      final oid = o['option_id']?.toString() ?? '';
      final strength = (o['evidence_strength'] as num?)?.toDouble();
      if (strength == null) {
        err('strength_missing', '$qid/$oid');
      } else {
        if (strength < 0.40 || strength > 0.85) {
          err('strength_range', '$qid/$oid $strength');
        }
        if ((strength - 0.72).abs() < 1e-9) flat072++;
      }
      final deltas = Map<String, dynamic>.from(o['dimension_deltas'] as Map);
      if (!deltas.containsKey(primary)) {
        err('primary_delta', '$qid/$oid');
      }
      var l1 = 0.0;
      var nonzero = 0;
      for (final e in deltas.entries) {
        final v = (e.value as num).toDouble();
        if (v < -1.0 || v > 1.0) err('delta_range', '$qid/$oid/${e.key}');
        if (v.abs() > 1e-12) nonzero++;
        l1 += v.abs();
      }
      if (nonzero > 3) err('dim_count', '$qid/$oid');
      if (l1 > 1.40 + 1e-9) err('authoring_l1', '$qid/$oid $l1');
      final sdr = o['social_desirability_risk']?.toString() ?? '';
      if (sdr != 'low' && sdr != 'moderate' && sdr != 'high') {
        err('sdr', '$qid/$oid');
      }
    }
  }

  if (flat072 > 0) err('flat_072', 'found $flat072 options with 0.72');

  for (final d in PersonaDimensionIds.eq) {
    if ((primaryCounts[d] ?? 0) != 3) {
      warn('primary_allocation', '$d=${primaryCounts[d]}');
    }
  }

  // Doc coverage
  for (final qid in ids) {
    if (!redTeam.contains('`$qid`')) err('red_team_coverage', qid);
    if (!changelog.contains('`$qid`')) err('changelog_coverage', qid);
    if (!evidence.contains('`$qid`')) err('evidence_coverage', qid);
  }
  if (RegExp(r'\bUNRESOLVED\b').hasMatch(redTeam) &&
      redTeam.contains('| UNRESOLVED | 0 |') == false) {
    // allow count table zero; fail if item disposition UNRESOLVED
    final itemUnresolved =
        RegExp(r'Recommended action:\*\* UNRESOLVED').hasMatch(redTeam) ||
            RegExp(r'\*\*UNRESOLVED\*\*').hasMatch(redTeam);
    if (itemUnresolved) err('unresolved_item', 'UNRESOLVED remains');
  }
  if (!evidence.contains('evidence_strength:')) {
    err('evidence_meta', 'option-level evidence_strength missing from docs');
  }
  if (!evidence.contains('social_desirability_risk:')) {
    err('evidence_sdr_meta', 'option-level SDR missing from docs');
  }
  if (!evidence.contains('response_style_risk:')) {
    err('evidence_rsr_meta', 'option-level RSR missing from docs');
  }

  // empathy_003 consistency
  final emp3 = items.cast<Map>().firstWhere(
        (j) => j['question_id'] == 'eq_tr_v1_empathy_003',
      );
  final notes3 = emp3['authoring_notes']?.toString() ?? '';
  if (!notes3.contains('sdr_item_risk=moderate')) {
    err('empathy_003_item_sdr', 'item-level must be moderate');
  }
  final hasMod = (emp3['options'] as List).any(
    (o) => (o as Map)['social_desirability_risk'] == 'moderate',
  );
  if (!hasMod) err('empathy_003_option_sdr', 'expected moderate option');

  // Reverse behavioral keying smoke: assertiveness_003 A must be positive
  final a3 = items.cast<Map>().firstWhere(
        (j) => j['question_id'] == 'eq_tr_v1_assertiveness_003',
      );
  final a3a = (a3['options'] as List).cast<Map>().firstWhere(
        (o) => o['option_id'] == 'A',
      );
  final a3delta =
      ((a3a['dimension_deltas'] as Map)['assertiveness'] as num).toDouble();
  if (a3delta <= 0) {
    err('reverse_polarity', 'assertiveness_003 A must be +assertiveness');
  }

  // TraitScoringService compatibility
  try {
    final config = TraitScoringParser.parseConfigJson(
      File('$root/$configPath').readAsStringSync(),
    );
    final parsed = TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'eq',
      source: 'review_candidate_1',
      config: config,
    );
    if (parsed.length != 30) err('parser_count', '${parsed.length}');
    final service = TraitScoringService(config: config);
    final responses = [
      for (var i = 0; i < parsed.length; i++)
        AssessmentResponse(
          questionId: parsed[i].questionId,
          selectedOptionId: parsed[i].options[i % 4].optionId,
          responseTimeMilliseconds: 5000 + i * 100,
        ),
    ];
    final result = service.scoreModule(
      TraitScoringSessionInput(
        module: 'eq',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: parsed,
        submittedResponses: responses,
        assessmentStatus: 'complete',
      ),
    );
    for (final s in result.module.dimensionScores.values) {
      if (s.isNaN || s.isInfinite) err('nan', 'dimension score invalid');
    }
    info('trait_scoring', 'offline scoreModule succeeded');
  } catch (e) {
    err('trait_scoring', '$e');
  }

  final errors = findings.where((f) => f.severity == 'error').length;
  final warns = findings.where((f) => f.severity == 'warn').length;
  final report = <String, Object?>{
    'form_id': form['form_id'],
    'content_version': form['content_version'],
    'parent_content_version': form['parent_content_version'],
    'automated_validation': errors == 0 ? 'PASS' : 'FAIL',
    'overall_readiness': errors == 0 ? 'CONDITIONAL' : 'FAIL',
    'error_count': errors,
    'warn_count': warns,
    'primary_counts': primaryCounts,
    'flat_072_count': flat072,
    'findings': [for (final f in findings) f.toJson()],
    'notes': {
      'expert_review': 'pending',
      'participant_testing': 'pending',
      'calibration': 'pending',
      'reverse_rvi': 'conditional_service_gap',
    },
  };

  final outDir = Directory('$root/tool/eq_pilot_out');
  outDir.createSync(recursive: true);
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final outFile =
      File('${outDir.path}/validate_eq_pilot_review_candidate_1_report.json');
  outFile.writeAsStringSync('$encoded\n');

  stdout.writeln('=== EQ Pilot Review Candidate 1 Validator (P2A-2C-2) ===');
  stdout.writeln('automated=${report['automated_validation']}');
  stdout.writeln('overall=${report['overall_readiness']}');
  stdout.writeln('errors=$errors warns=$warns');
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('fingerprint=${encoded.hashCode}');
  exit(errors == 0 ? 0 : 1);
}
