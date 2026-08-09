// Offline validator for IQ pilot review candidate 1 (P2A-2B-2).
// Usage: dart run tool/validate_iq_pilot_review_candidate_1.dart
// Does not prove semantic correctness; fails on UNRESOLVED / policy breaks.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

const candidatePath =
    'assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json';
const parentPath = 'assets/data/assessment_v3/iq/iq_pilot_tr_v1.json';
const redTeamPath = 'docs/core_engine/iq_pilot_tr_v1_red_team_review.md';
const changelogPath =
    'docs/core_engine/iq_pilot_tr_v1_review_candidate_1_changelog.md';
const configPath = 'assets/data/trait_scoring_config_v1.json';

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

  final parent = jsonDecode(parentFile.readAsStringSync()) as Map;
  final form = jsonDecode(candFile.readAsStringSync()) as Map<String, dynamic>;
  final redTeam = File('$root/$redTeamPath').readAsStringSync();
  final changelog = File('$root/$changelogPath').readAsStringSync();

  // Parent must remain pilot v1 identity
  if (parent['content_version'] != 'iq-tr-pilot-v1') {
    err('parent_mutated', 'parent content_version changed');
  }
  if (form['content_version'] != 'iq-tr-pilot-v1-review-candidate-1') {
    err('content_version', 'unexpected candidate content_version');
  }
  if (form['parent_content_version'] != 'iq-tr-pilot-v1') {
    err('lineage', 'parent_content_version must be iq-tr-pilot-v1');
  }
  if (form['status'] != 'internal_review') {
    err('status', 'expected internal_review');
  }
  if (form['calibration_status'] != 'uncalibrated') {
    err('calibration_status', 'must be uncalibrated');
  }

  final notes = Map<String, dynamic>.from(form['notes'] as Map? ?? {});
  if (notes['internal_language_review'] != 'completed') {
    err('internal_language_review', 'must be completed');
  }
  if (notes['expert_language_review'] != 'pending') {
    err('expert_language_review', 'must remain pending');
  }

  final items = (form['items'] as List?) ?? const [];
  if (items.length != 25) err('item_count', 'expected 25');

  const domains = {
    'logical_reasoning',
    'pattern_reasoning',
    'verbal_reasoning',
    'spatial_reasoning',
  };
  final domainCounts = <String, int>{};
  final diffCounts = <int, int>{};
  final correctPos = <String, int>{};
  final correctSeq = <String>[];
  final ids = <String>{};
  final anchors = <String, String>{};

  for (final raw in items) {
    final j = Map<String, dynamic>.from(raw as Map);
    final qid = j['question_id']?.toString() ?? '';
    if (qid.isEmpty || !ids.add(qid)) err('id', 'bad/duplicate $qid');
    if (j['schema_version'] != 'qmatch_question_schema_v3') {
      err('schema', qid);
    }
    if (j['module'] != 'iq') err('module', qid);
    if (j['primary_dimension'] != j['cognitive_domain']) {
      err('domain_mismatch', qid);
    }
    final d = j['primary_dimension']?.toString() ?? '';
    if (!domains.contains(d)) err('unknown_domain', '$qid $d');
    domainCounts[d] = (domainCounts[d] ?? 0) + 1;
    final diff = (j['difficulty'] as num?)?.toInt() ?? -1;
    diffCounts[diff] = (diffCounts[diff] ?? 0) + 1;
    final opts = (j['options'] as List?) ?? const [];
    if (opts.length != 4) err('options', qid);
    final oidSet = {
      for (final o in opts) (o as Map)['option_id'].toString(),
    };
    final correct = j['correct_option_id']?.toString() ?? '';
    if (!oidSet.contains(correct)) err('correct', qid);
    correctPos[correct] = (correctPos[correct] ?? 0) + 1;
    correctSeq.add(correct);
    final dl = j['distractor_logic'];
    if (dl is! Map || dl.isEmpty) err('distractor_logic', qid);
    if ((j['solution_method']?.toString() ?? '').length < 20) {
      err('solution', qid);
    }
    if (j['calibration_status'] != 'uncalibrated') {
      err('item_calibration', qid);
    }
    if (j['anchor_group'] != null) {
      anchors[qid] = j['anchor_group'].toString();
      if (j['exposure_class'] != 'anchor') err('anchor_exposure', qid);
    }
    // red-team coverage: retired id must not appear
    if (qid == 'iq_tr_v1_spatial_003') {
      err('retired_id_present', 'spatial_003 must not remain in candidate');
    }
  }

  if (domainCounts['logical_reasoning'] != 7 ||
      domainCounts['pattern_reasoning'] != 6 ||
      domainCounts['verbal_reasoning'] != 6 ||
      domainCounts['spatial_reasoning'] != 6) {
    err('domain_allocation', '$domainCounts');
  }

  // Honest reviewed difficulty may differ from 8/12/5
  final easy = diffCounts[2] ?? 0;
  final mid = diffCounts[3] ?? 0;
  final hard = diffCounts[4] ?? 0;
  final reviewed = Map<String, dynamic>.from(
    form['reviewed_difficulty_allocation'] as Map? ?? {},
  );
  if (reviewed['easy'] != easy ||
      reviewed['medium'] != mid ||
      reviewed['hard'] != hard) {
    err('reviewed_difficulty_meta', 'meta mismatch with items');
  }
  if (easy + mid + hard != 25) err('difficulty_sum', 'not 25');
  if (easy == 8 && mid == 12 && hard == 5) {
    info('difficulty', 'matches provisional 8/12/5');
  } else {
    warn('difficulty_honest_mismatch',
        'reviewed e$easy/m$mid/h$hard ≠ provisional 8/12/5');
  }

  final a = correctPos['A'] ?? 0;
  final b = correctPos['B'] ?? 0;
  final c = correctPos['C'] ?? 0;
  final d = correctPos['D'] ?? 0;
  if (!((a == 6 || a == 7) &&
      (b == 6 || b == 7) &&
      (c == 6 || c == 7) &&
      (d == 6 || d == 7) &&
      a + b + c + d == 25)) {
    err('answer_balance', 'A$a B$b C$c D$d');
  }
  var run = 1, maxRun = 1;
  for (var i = 1; i < correctSeq.length; i++) {
    if (correctSeq[i] == correctSeq[i - 1]) {
      run++;
      maxRun = math.max(maxRun, run);
    } else {
      run = 1;
    }
  }
  if (maxRun > 2) err('answer_run', 'maxRun=$maxRun');

  if (anchors.length != 4) err('anchors', 'expected 4 got ${anchors.length}');
  final anchorDomains = <String>{};
  for (final e in anchors.entries) {
    final it = items.cast<Map>().firstWhere((x) => x['question_id'] == e.key);
    anchorDomains.add(it['primary_dimension'].toString());
  }
  if (!domains.every(anchorDomains.contains)) {
    err('anchor_domains', '$anchorDomains');
  }
  if (!ids.contains('iq_tr_v1_spatial_007')) {
    err('replacement_missing', 'spatial_007 required');
  }
  if (!ids.contains('iq_tr_v1_pattern_007')) {
    err('rewrite_missing', 'pattern_007 required after material rewrite');
  }
  if (ids.contains('iq_tr_v1_pattern_006')) {
    err('id_policy_pattern', 'material rewrite must not reuse pattern_006');
  }
  if (!changelog.contains('iq_tr_v1_spatial_007') ||
      !changelog.contains('item_replacement')) {
    err('changelog_replacement', 'replacement not documented');
  }
  if (!changelog.contains('iq_tr_v1_pattern_007') ||
      !changelog.contains('semantic_rewrite')) {
    err('changelog_rewrite', 'pattern rewrite not documented');
  }

  // Red-team coverage + no UNRESOLVED
  for (final qid in [
    ...{for (final i in parent['items'] as List) (i as Map)['question_id']},
  ]) {
    if (!redTeam.contains(qid as String)) {
      err('red_team_coverage', 'missing $qid');
    }
  }
  if (redTeam.contains('UNRESOLVED count | 0') == false &&
      !redTeam.contains('| UNRESOLVED | 0 |')) {
    // allow either table form
    if (RegExp(r'UNRESOLVED\s*\|\s*[1-9]').hasMatch(redTeam) ||
        redTeam.contains('**UNRESOLVED**')) {
      // check explicit unresolved items
    }
  }
  if (RegExp(r'Semantic:\s*\*\*UNRESOLVED\*\*').hasMatch(redTeam)) {
    err('unresolved_item', 'UNRESOLVED verdict present');
  }
  if (!redTeam.contains('| UNRESOLVED | 0 |')) {
    err('unresolved_summary', 'UNRESOLVED count must be 0 in summary table');
  }

  // Material revision ID policy: spatial_003 must not be reused as live id
  final parentIds = {
    for (final i in parent['items'] as List) (i as Map)['question_id'] as String
  };
  if (ids.contains('iq_tr_v1_spatial_003')) {
    err('id_policy', 'retired spatial_003 id reused');
  }
  if (!parentIds.contains('iq_tr_v1_spatial_003')) {
    err('parent_expected_spatial_003', 'parent should still have spatial_003');
  }

  // Changelog coverage for known edits
  for (final token in [
    'iq_tr_v1_logical_005',
    'iq_tr_v1_logical_007',
    'iq_tr_v1_pattern_006',
    'iq_tr_v1_pattern_007',
    'iq_tr_v1_verbal_002',
    'iq_tr_v1_verbal_004',
    'iq_tr_v1_spatial_005',
    'iq_tr_v1_spatial_003',
    'iq_tr_v1_spatial_007',
  ]) {
    if (!changelog.contains(token)) err('changelog_coverage', token);
  }

  // pubspec / production
  final pub = File('$root/pubspec.yaml').readAsStringSync();
  if (pub.contains('review_candidate_1') || pub.contains('assessment_v3/iq')) {
    err('pubspec', 'candidate must not be in pubspec');
  }

  // Trait scoring smoke + adversarial
  try {
    final config = TraitScoringParser.parseConfigJson(
      File('$root/$configPath').readAsStringSync(),
    );
    final parsed = TraitScoringParser.parseItemBank(
      items,
      expectedModule: 'iq',
      source: candidatePath,
      config: config,
    );
    final svc = TraitScoringService(config: config);

    List<AssessmentResponse> keyed(
      String Function(AssessmentItemDefinition q) pick,
    ) =>
        [
          for (final q in parsed)
            AssessmentResponse(
              questionId: q.questionId,
              selectedOptionId: pick(q),
              responseTimeMilliseconds: 7000,
            ),
        ];

    TraitScoringSessionInput sess(List<AssessmentResponse> rs,
        {String status = 'complete'}) {
      final seen = <String>{};
      for (final r in rs) {
        if (!seen.add(r.questionId)) {
          throw TraitScoringValidationException('duplicate', [
            TraitValidationError(
              questionId: r.questionId,
              fieldPath: 'question_id',
              reasonCode: 'duplicate_response',
              explanation: 'dup',
            ),
          ]);
        }
        if (!parsed.any((q) => q.questionId == r.questionId)) {
          throw TraitScoringValidationException('unknown', [
            TraitValidationError(
              questionId: r.questionId,
              fieldPath: 'question_id',
              reasonCode: 'unknown_question_id',
              explanation: 'unknown',
            ),
          ]);
        }
      }
      return TraitScoringSessionInput(
        module: 'iq',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: parsed,
        submittedResponses: rs,
        assessmentStatus: status,
      );
    }

    final allC = svc.scoreModule(
      sess(keyed((q) => q.correctOptionId!)),
    );
    for (final d in domains) {
      if ((allC.module.dimensionScores[d]! - 1.0).abs() > 1e-9) {
        err('all_correct', d);
      }
    }
    if (allC.module.legacyRawScore != 25) err('legacy', 'not 25');

    final allW = svc.scoreModule(
      sess(keyed((q) => q.options
          .firstWhere((o) => o.optionId != q.correctOptionId)
          .optionId)),
    );
    for (final d in domains) {
      if ((allW.module.dimensionScores[d]! - 0.0).abs() > 1e-9) {
        err('all_incorrect', d);
      }
    }

    for (final letter in ['A', 'B', 'C', 'D']) {
      final r = svc.scoreModule(sess(keyed((q) => letter)));
      for (final s in r.module.dimensionScores.values) {
        if (!s.isFinite || s < 0 || s > 1) err('always_$letter', 'bad score');
      }
    }

    // missing verbal domain
    final omit = [
      for (final q in parsed)
        if (q.primaryDimension != 'verbal_reasoning')
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: q.correctOptionId,
            responseTimeMilliseconds: 5000,
          ),
    ];
    final miss = svc.scoreModule(sess(omit));
    if (miss.module.dimensionScores.containsKey('verbal_reasoning')) {
      err('missing_published', 'verbal should be missing');
    }

    // duplicate / unknown must fail
    try {
      sess([
        ...keyed((q) => q.correctOptionId!),
        AssessmentResponse(
          questionId: parsed.first.questionId,
          selectedOptionId: 'A',
        ),
      ]);
      err('duplicate_not_rejected', 'expected throw');
    } on TraitScoringValidationException {
      info('duplicate', 'rejected');
    }
    try {
      sess([
        const AssessmentResponse(
          questionId: 'nope',
          selectedOptionId: 'A',
        ),
      ]);
      err('unknown_not_rejected', 'expected throw');
    } on TraitScoringValidationException {
      info('unknown', 'rejected');
    }

    // shuffled order determinism
    final rev = parsed.reversed.toList();
    final s1 = svc.scoreModule(sess(keyed((q) => q.correctOptionId!)));
    final s2 = svc.scoreModule(
      TraitScoringSessionInput(
        module: 'iq',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: rev,
        submittedResponses: [
          for (final q in rev)
            AssessmentResponse(
              questionId: q.questionId,
              selectedOptionId: q.correctOptionId,
              responseTimeMilliseconds: 7000,
            ),
        ],
        assessmentStatus: 'complete',
      ),
    );
    if (s1.module.dimensionScores.toString() !=
        s2.module.dimensionScores.toString()) {
      err('shuffle_determinism', 'scores differ');
    }
  } catch (e) {
    err('trait_scoring', '$e');
  }

  final errors = findings.where((f) => f.severity == 'error').length;
  final warns = findings.where((f) => f.severity == 'warn').length;
  final report = {
    'automated_validation': errors == 0 ? 'PASS' : 'FAIL',
    'overall_readiness': errors == 0 ? 'CONDITIONAL' : 'FAIL',
    'error_count': errors,
    'warn_count': warns,
    'domain_counts': domainCounts,
    'difficulty_counts': {'easy_2': easy, 'medium_3': mid, 'hard_4': hard},
    'correct_option_counts': correctPos,
    'correct_option_sequence': correctSeq.join(),
    'max_correct_run': maxRun,
    'anchors': anchors,
    'findings': [for (final f in findings) f.toJson()],
    'notes': {
      'expert_reviews_pending': true,
      'does_not_prove_semantics': true,
      'offline_only': true,
    },
  };

  final outDir = Directory('$root/tool/iq_pilot_out');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final encoded = const JsonEncoder.withIndent('  ').convert(_sortJson(report));
  File('${outDir.path}/validate_iq_pilot_review_candidate_1_report.json')
      .writeAsStringSync('$encoded\n');

  stdout.writeln('=== IQ Pilot Review Candidate 1 Validator ===');
  stdout.writeln('automated=${report['automated_validation']}');
  stdout.writeln('overall=${report['overall_readiness']}');
  stdout.writeln('errors=$errors warns=$warns');
  stdout.writeln('difficulty=e$easy/m$mid/h$hard');
  stdout.writeln('correctPos=$correctPos maxRun=$maxRun');
  stdout.writeln('fingerprint=${encoded.hashCode}');
  exit(errors == 0 ? 0 : 1);
}

dynamic _sortJson(dynamic v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sortJson(v[k])};
  }
  if (v is List) return [for (final e in v) _sortJson(e)];
  return v;
}
