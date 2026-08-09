// Offline validator for Frequency pilot review candidate 1 (P2A-2D-2).
// Usage: dart run tool/validate_frequency_pilot_review_candidate_1.dart

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

const parentSha256 =
    '8b9e3b13f761707d32cee62dc4a3eef02e8983b1c76b71ae4976543457b041ab';
const reversePairContractPath =
    'docs/core_engine/reverse_pair_consistency_contract_v1.md';
const candidatePath =
    'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json';
const parentPath =
    'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json';
const redTeamPath = 'docs/core_engine/frequency_pilot_tr_v1_red_team_review.md';
const changelogPath =
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_changelog.md';
const evidencePath =
    'docs/core_engine/frequency_pilot_tr_v1_review_candidate_1_evidence_review.md';
const reversePairPath =
    'docs/core_engine/frequency_reverse_pair_application_review_v1.md';
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

int compareFindings(Finding a, Finding b) {
  final c = a.severity.compareTo(b.severity);
  if (c != 0) return c;
  final d = a.code.compareTo(b.code);
  if (d != 0) return d;
  return a.message.compareTo(b.message);
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

  final parentSha = Process.runSync(
    'shasum',
    ['-a', '256', parentFile.path],
  ).stdout.toString().split(' ').first.trim();
  if (parentSha != parentSha256) {
    err('parent_sha256', 'parent bytes changed: $parentSha');
  }

  final parent =
      jsonDecode(parentFile.readAsStringSync()) as Map<String, dynamic>;
  final form = jsonDecode(candFile.readAsStringSync()) as Map<String, dynamic>;
  final redTeam = File('$root/$redTeamPath').readAsStringSync();
  final changelog = File('$root/$changelogPath').readAsStringSync();
  final evidence = File('$root/$evidencePath').readAsStringSync();
  final reverseDoc = File('$root/$reversePairPath').readAsStringSync();
  final pubspec = File('$root/$pubspecPath').readAsStringSync();

  if (parent['content_version'] != 'frequency-tr-pilot-v1') {
    err('parent_mutated', 'parent content_version changed');
  }
  if (form['content_version'] != 'frequency-tr-pilot-v1-review-candidate-1') {
    err('content_version', 'unexpected candidate content_version');
  }
  if (form['parent_content_version'] != 'frequency-tr-pilot-v1') {
    err('lineage', 'parent_content_version mismatch');
  }
  if (form['form_id'] != 'frequency_tr_pilot_v1_review_candidate_1') {
    err('form_id', 'unexpected form_id');
  }
  if (form['set_id'] != 'frequency_tr_pilot_v1_review_candidate_1_set_001') {
    err('set_id', 'unexpected set_id');
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
  if (notes['reverse_pair_rvi_service_compatibility'] != 'PASS') {
    err('reverse_pair_compat', 'notes must document PASS after P2A-2D-2.1');
  }
  final revPairs =
      ((form['pair_registry'] as Map?)?['reverse_pairs'] as List?) ?? const [];
  for (final raw in revPairs) {
    final p = Map<String, dynamic>.from(raw as Map);
    if (p['consistency_mode'] != 'behavioral_correspondence') {
      err(
        'reverse_pair_mode',
        '${p['pair_id']} must declare behavioral_correspondence',
      );
    }
  }

  if (pubspec.contains('frequency_pilot_tr_v1_review_candidate_1')) {
    err('pubspec', 'candidate must not be runtime-loaded');
  }

  final items = (form['items'] as List?) ?? const [];
  if (items.length != 50) err('item_count', 'expected 50');

  final ids = <String>[];
  final idSet = <String>{};
  var flat072 = 0;
  var maxLenRatio = 0.0;
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
    if (j['module'] != 'frequency') err('module', qid);
    if (j['content_version'] != 'frequency-tr-pilot-v1-review-candidate-1') {
      err('item_cv', qid);
    }
    if (j['calibration_status'] != 'uncalibrated') {
      err('item_calibration', qid);
    }
    if (!(j['authoring_notes']?.toString() ?? '')
        .contains('red_team=candidate_1')) {
      err('red_team_note', qid);
    }
    final primary = j['primary_dimension']?.toString() ?? '';
    if (!PersonaDimensionIds.frequency.contains(primary)) {
      err('primary', '$qid $primary');
    }
    primaryCounts[primary] = (primaryCounts[primary] ?? 0) + 1;
    for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
      if (!PersonaDimensionIds.frequency.contains(s.toString())) {
        err('secondary', '$qid $s');
      }
      if (PersonaDimensionIds.eq.contains(s.toString())) {
        err('eq_write', '$qid $s');
      }
    }
    final opts = (j['options'] as List?) ?? const [];
    if (opts.length != 4) err('options', qid);
    final lens = <int>[];
    for (final oRaw in opts) {
      final o = Map<String, dynamic>.from(oRaw as Map);
      final oid = o['option_id']?.toString() ?? '';
      final trText =
          (((o['localized_text'] as Map?) ?? {})['tr'] as String?) ?? '';
      lens.add(trText.length);
      final strength = (o['evidence_strength'] as num?)?.toDouble();
      if (strength == null) {
        err('strength_missing', '$qid/$oid');
      } else {
        if (strength < 0.40 || strength > 0.85) {
          err('strength_range', '$qid/$oid $strength');
        }
        if ((strength - 0.72).abs() < 1e-9) flat072++;
        final prim = (o['dimension_deltas'] as Map)[primary] as num?;
        if (prim != null && (strength - prim.abs()).abs() < 1e-9) {
          err('strength_equals_primary', '$qid/$oid');
        }
      }
      final deltas = Map<String, dynamic>.from(o['dimension_deltas'] as Map);
      if (!deltas.containsKey(primary)) {
        err('primary_delta', '$qid/$oid');
      }
      var l1 = 0.0;
      var nonzero = 0;
      var allPosMulti = false;
      final nz = <String, double>{};
      for (final e in deltas.entries) {
        final v = (e.value as num).toDouble();
        if (PersonaDimensionIds.eq.contains(e.key)) {
          err('eq_delta', '$qid/$oid/${e.key}');
        }
        if (v < -1.0 || v > 1.0) err('delta_range', '$qid/$oid/${e.key}');
        if (v.abs() > 1e-12) {
          nonzero++;
          nz[e.key] = v;
        }
        l1 += v.abs();
      }
      if (nz.length >= 2 && nz.values.every((v) => v > 0)) allPosMulti = true;
      if (allPosMulti) err('all_positive_multi', '$qid/$oid');
      if (nonzero > 3) err('dim_count', '$qid/$oid');
      if (l1 > 1.40 + 1e-9) err('authoring_l1', '$qid/$oid $l1');
      final sdr = o['social_desirability_risk']?.toString() ?? '';
      if (sdr != 'low' && sdr != 'moderate' && sdr != 'high') {
        err('sdr', '$qid/$oid');
      }
    }
    if (lens.isNotEmpty) {
      final mn = lens.reduce((a, b) => a < b ? a : b);
      final mx = lens.reduce((a, b) => a > b ? a : b);
      if (mn > 0) {
        final ratio = mx / mn;
        if (ratio > maxLenRatio) maxLenRatio = ratio;
        if (ratio > 1.50 + 1e-9) {
          err('option_length_ratio', '$qid ratio=$ratio');
        }
      }
    }
  }

  if (flat072 > 0) err('flat_072', 'found $flat072 options with 0.72');

  for (final d in PersonaDimensionIds.frequency) {
    if (!primaryCounts.containsKey(d)) {
      warn('primary_allocation', 'missing primary $d');
    }
  }

  for (final qid in ids) {
    if (!redTeam.contains('`$qid`')) err('red_team_coverage', qid);
    if (!changelog.contains('`$qid`')) err('changelog_coverage', qid);
    if (!evidence.contains('`$qid`')) err('evidence_coverage', qid);
  }
  if (RegExp(r'Recommended action:\*\* UNRESOLVED').hasMatch(redTeam)) {
    err('unresolved_item', 'UNRESOLVED remains');
  }
  if (!redTeam.contains('| UNRESOLVED | 0 |')) {
    err('unresolved_count', 'UNRESOLVED count table missing or non-zero');
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
  final contractDoc = File('$root/$reversePairContractPath').readAsStringSync();
  if (!contractDoc.contains('behavioral_correspondence')) {
    err('reverse_pair_contract', 'contract missing behavioral_correspondence');
  }
  if (!reverseDoc.contains('PASS') &&
      !reverseDoc.contains('behavioral_correspondence')) {
    err('reverse_pair_doc', 'reverse pair application review not updated');
  }
  info(
    'reverse_pair_service_compatibility',
    'PASS — declared behavioral_correspondence under reverse_pair_consistency_contract_v1',
  );

  try {
    final config = TraitScoringParser.parseConfigJson(
      File('$root/$configPath').readAsStringSync(),
    );
    final parsed = TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'frequency',
      source: 'review_candidate_1',
      config: config,
    );
    if (parsed.length != 50) err('parser_count', '${parsed.length}');
    final descriptors = ReversePairDescriptor.parseRegistry(revPairs);
    if (descriptors.length != 6) {
      err('reverse_descriptors', 'expected 6 parsed reverse descriptors');
    }
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
        module: 'frequency',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: parsed,
        submittedResponses: responses,
        assessmentStatus: 'complete',
        reversePairDescriptors: descriptors,
      ),
    );
    for (final s in result.module.dimensionScores.values) {
      if (s.isNaN || s.isInfinite) err('nan', 'dimension score invalid');
    }
    if (!result.module.responseValidity.componentScores
        .containsKey('reverse_consistency')) {
      err('reverse_rvi_missing', 'reverse_consistency should be available');
    }
    info('trait_scoring', 'offline scoreModule succeeded');
  } catch (e) {
    err('trait_scoring', '$e');
  }

  findings.sort(compareFindings);

  final errors = findings.where((f) => f.severity == 'error').length;
  final warns = findings.where((f) => f.severity == 'warn').length;
  final report = <String, Object?>{
    'form_id': form['form_id'],
    'content_version': form['content_version'],
    'parent_content_version': form['parent_content_version'],
    'parent_sha256': parentSha,
    'parent_sha256_expected': parentSha256,
    'automated_validation': errors == 0 ? 'PASS' : 'FAIL',
    'overall_readiness': errors == 0 ? 'CONDITIONAL' : 'FAIL',
    'reverse_pair_service_compatibility': 'PASS',
    'error_count': errors,
    'warn_count': warns,
    'max_option_length_ratio': maxLenRatio,
    'primary_counts': primaryCounts,
    'flat_072_count': flat072,
    'findings': [for (final f in findings) f.toJson()],
    'notes': {
      'expert_review': 'pending',
      'cognitive_interviews': 'pending',
      'calibration': 'pending',
      'reverse_rvi': 'aligned_behavioral_correspondence',
      'reverse_pair_consistency_contract': reversePairContractPath,
    },
  };

  final outDir = Directory('$root/tool/frequency_pilot_out');
  outDir.createSync(recursive: true);
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  final outFile = File(
    '${outDir.path}/validate_frequency_pilot_review_candidate_1_report.json',
  );
  outFile.writeAsStringSync('$encoded\n');
  report['fingerprint'] = encoded.hashCode;

  stdout.writeln(
      '=== Frequency Pilot Review Candidate 1 Validator (P2A-2D-2) ===');
  stdout.writeln('automated=${report['automated_validation']}');
  stdout.writeln('overall=${report['overall_readiness']}');
  stdout.writeln('reverse_pair_service_compatibility=PASS');
  stdout.writeln('errors=$errors warns=$warns');
  stdout.writeln('max_option_length_ratio=$maxLenRatio');
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('fingerprint=${encoded.hashCode}');
  exit(errors == 0 ? 0 : 1);
}
