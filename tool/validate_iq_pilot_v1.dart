// Offline deterministic validator for IQ pilot form (P2A-2B-1).
// Usage: dart run tool/validate_iq_pilot_v1.dart
// Not runtime-wired. Does not prove semantic correctness of answers.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

const pilotPath = 'assets/data/assessment_v3/iq/iq_pilot_tr_v1.json';
const schemaPath = 'assets/schemas/qmatch_question_schema_v3.json';
const configPath = 'assets/data/trait_scoring_config_v1.json';

class Finding {
  final String severity; // error | warn | info
  final String code;
  final String message;
  final String? questionId;

  Finding(this.severity, this.code, this.message, {this.questionId});

  Map<String, Object?> toJson() => {
        'severity': severity,
        'code': code,
        'message': message,
        if (questionId != null) 'question_id': questionId,
      };
}

void main(List<String> args) {
  final root = Directory.current.path;
  final findings = <Finding>[];
  final report = <String, Object?>{};

  void err(String code, String msg, {String? qid}) =>
      findings.add(Finding('error', code, msg, questionId: qid));
  void warn(String code, String msg, {String? qid}) =>
      findings.add(Finding('warn', code, msg, questionId: qid));
  void info(String code, String msg, {String? qid}) =>
      findings.add(Finding('info', code, msg, questionId: qid));

  final pilotFile = File('$root/$pilotPath');
  if (!pilotFile.existsSync()) {
    stderr.writeln('MISSING $pilotPath');
    exit(2);
  }

  late Map<String, dynamic> form;
  try {
    form = Map<String, dynamic>.from(jsonDecode(pilotFile.readAsStringSync()));
  } catch (e) {
    stderr.writeln('JSON parse failed: $e');
    exit(2);
  }

  report['form_id'] = form['form_id'];
  report['set_id'] = form['set_id'];
  report['content_version'] = form['content_version'];
  report['locale'] = form['locale'];
  report['status'] = form['status'];
  report['calibration_status'] = form['calibration_status'];

  if (form['module'] != 'iq') err('module', 'module must be iq');
  if (form['locale'] != 'tr-TR') err('locale', 'locale must be tr-TR');
  if (form['schema_version'] != 3) {
    err('schema_version', 'form schema_version must be 3');
  }
  if (form['question_schema_version'] != 'qmatch_question_schema_v3') {
    err('question_schema_version', 'must be qmatch_question_schema_v3');
  }
  if (form['content_version'] != 'iq-tr-pilot-v1') {
    err('content_version', 'expected iq-tr-pilot-v1');
  }
  if (form['status'] != 'pilot') err('status', 'status must be pilot');
  if (form['calibration_status'] != 'uncalibrated') {
    err('calibration_status', 'must be uncalibrated');
  }
  if (form['set_id'] != 'iq_tr_pilot_v1_set_001') {
    err('set_id', 'expected iq_tr_pilot_v1_set_001');
  }
  if (form['question_count'] != 25) {
    err('question_count', 'question_count must be 25');
  }

  final items = (form['items'] as List?) ?? const [];
  if (items.length != 25) {
    err('item_count', 'expected 25 items, got ${items.length}');
  }

  final schemaText = File('$root/$schemaPath').readAsStringSync();
  final schema = jsonDecode(schemaText);
  if (schema is! Map) {
    err('schema_file', 'schema root invalid');
  }

  final ids = <String>{};
  final domainCounts = <String, int>{};
  final diffCounts = <int, int>{};
  final correctPos = <String, int>{};
  final correctSeq = <String>[];
  final anchors = <String, String>{};
  final prompts = <String>[];
  final optionSets = <String>[];

  const iqDomains = {
    'logical_reasoning',
    'pattern_reasoning',
    'verbal_reasoning',
    'spatial_reasoning',
  };

  for (final raw in items) {
    final j = Map<String, dynamic>.from(raw as Map);
    final qid = j['question_id']?.toString() ?? '';

    void need(String k, {bool allowNull = false}) {
      if (!j.containsKey(k)) {
        err('missing_field', 'missing $k', qid: qid);
        return;
      }
      if (!allowNull && j[k] == null) {
        err('missing_field', 'missing $k', qid: qid);
      }
    }

    for (final k in [
      'question_id',
      'module',
      'schema_version',
      'content_version',
      'locale',
      'status',
      'review_state',
      'item_type',
      'primary_dimension',
      'secondary_dimensions',
      'prompt',
      'options',
      'correct_option_id',
      'solution_method',
      'cognitive_domain',
      'difficulty',
      'estimated_discrimination',
      'distractor_logic',
      'calibration_status',
      'separator_targets',
      'response_validity_roles',
      'exposure_class',
      'security_level',
      'estimated_completion_seconds',
      'authoring_notes',
      'created_at',
      'updated_at',
    ]) {
      need(k);
    }
    // Explicit nulls allowed / required as keys:
    for (final k in [
      'anchor_group',
      'semantic_pair_id',
      'reverse_pair_id',
      'behavioral_isomorph_group',
    ]) {
      need(k, allowNull: true);
    }

    if (qid.isEmpty || !ids.add(qid)) {
      err('duplicate_or_missing_id', 'bad question_id', qid: qid);
    }
    if (j['module'] != 'iq') err('module', 'item module must be iq', qid: qid);
    if (j['schema_version'] != 'qmatch_question_schema_v3') {
      err('schema_version', 'item schema_version invalid', qid: qid);
    }
    if (j['content_version'] != form['content_version']) {
      err('content_version_mismatch', 'item content_version mismatch',
          qid: qid);
    }
    if (j['item_type'] != 'mcq_keyed') {
      err('item_type', 'expected mcq_keyed', qid: qid);
    }
    if (j['calibration_status'] != 'uncalibrated') {
      err('calibration_status', 'must be uncalibrated', qid: qid);
    }

    final domain = j['primary_dimension']?.toString() ?? '';
    final cog = j['cognitive_domain']?.toString() ?? '';
    if (!iqDomains.contains(domain)) {
      err('unknown_dimension', domain, qid: qid);
    }
    if (domain != cog) {
      err('domain_mismatch', 'primary_dimension != cognitive_domain', qid: qid);
    }
    if (PersonaDimensionIds.forbiddenAliases.contains(domain)) {
      err('retired_alias', domain, qid: qid);
    }
    domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;

    final secs = (j['estimated_completion_seconds'] as num?)?.toDouble() ?? 0;
    if (secs < 15 || secs > 120) {
      warn('time_bounds', 'estimated_completion_seconds=$secs', qid: qid);
    }

    final prompt = Map<String, dynamic>.from(j['prompt'] as Map? ?? {});
    final tr = prompt['tr']?.toString() ?? '';
    final en = prompt['en']?.toString() ?? '';
    if (tr.isEmpty || en.isEmpty) {
      err('prompt', 'tr/en required', qid: qid);
    }
    prompts.add(_norm(tr));

    final options = (j['options'] as List?) ?? const [];
    if (options.length != 4) {
      err('options_count', 'expected 4 options', qid: qid);
    }
    final optIds = <String>{};
    final optTexts = <String>[];
    for (final oRaw in options) {
      final o = Map<String, dynamic>.from(oRaw as Map);
      final oid = o['option_id']?.toString() ?? '';
      if (oid.isEmpty || !optIds.add(oid)) {
        err('option_id', 'duplicate/missing option_id', qid: qid);
      }
      final lt = Map<String, dynamic>.from(o['localized_text'] as Map? ?? {});
      optTexts.add(_norm(lt['tr']?.toString() ?? ''));
      if (o.containsKey('persona_id') || o.containsKey('persona_points')) {
        err('persona_in_option', 'persona fields forbidden', qid: qid);
      }
      // IQ: dimension_deltas should be empty object
      final deltas = o['dimension_deltas'];
      if (deltas is Map && deltas.isNotEmpty) {
        warn('iq_deltas_nonempty', 'IQ option deltas unexpected', qid: qid);
      }
    }
    optionSets.add(optTexts.join('|'));

    final correct = j['correct_option_id']?.toString() ?? '';
    if (!optIds.contains(correct)) {
      err('correct_option', 'correct_option_id not in options', qid: qid);
    }
    correctPos[correct] = (correctPos[correct] ?? 0) + 1;
    correctSeq.add(correct);

    final diff = (j['difficulty'] as num?)?.toInt();
    if (diff == null || diff < 1 || diff > 5) {
      err('difficulty', 'invalid difficulty', qid: qid);
    } else {
      diffCounts[diff] = (diffCounts[diff] ?? 0) + 1;
    }

    final dl = j['distractor_logic'];
    if (dl is! Map || dl.isEmpty) {
      err('distractor_logic', 'required non-empty', qid: qid);
    } else {
      for (final oid in optIds) {
        if (oid == correct) continue;
        if (!dl.containsKey(oid)) {
          warn('distractor_incomplete', 'missing logic for $oid', qid: qid);
        }
      }
    }

    final sol = j['solution_method']?.toString() ?? '';
    if (sol.trim().length < 20) {
      err('solution_method', 'solution too short', qid: qid);
    }

    final ag = j['anchor_group'];
    if (ag != null) {
      anchors[qid] = ag.toString();
      if (j['exposure_class'] != 'anchor') {
        err('anchor_exposure', 'anchor items need exposure_class=anchor',
            qid: qid);
      }
      if (diff != 3) {
        warn('anchor_difficulty', 'anchors should be medium(3)', qid: qid);
      }
    }

    // Forbidden content
    final blob = jsonEncode(j).toLowerCase();
    for (final bad in [
      'uygulayici',
      'empat',
      '"hh"',
      '"hm"',
      'deep connector',
      'balanced frequency',
    ]) {
      if (blob.contains(bad)) {
        err('forbidden_id', 'contains $bad', qid: qid);
      }
    }

    // Semantic heuristics (warn only)
    _semanticHeuristics(j, warn);
  }

  // Domain allocation 7/6/6/6
  if (domainCounts['logical_reasoning'] != 7 ||
      domainCounts['pattern_reasoning'] != 6 ||
      domainCounts['verbal_reasoning'] != 6 ||
      domainCounts['spatial_reasoning'] != 6) {
    err('domain_allocation', 'expected 7/6/6/6 got $domainCounts');
  }

  // Difficulty 8/12/5 via encoding easy=2 medium=3 hard=4
  final easy = diffCounts[2] ?? 0;
  final mid = diffCounts[3] ?? 0;
  final hard = diffCounts[4] ?? 0;
  if (easy != 8 || mid != 12 || hard != 5) {
    err('difficulty_allocation',
        'expected easy8/mid12/hard5 via 2/3/4; got e$easy m$mid h$hard');
  }

  // Answer position balance
  final a = correctPos['A'] ?? 0;
  final b = correctPos['B'] ?? 0;
  final c = correctPos['C'] ?? 0;
  final d = correctPos['D'] ?? 0;
  if (!((a == 6 || a == 7) &&
      (b == 6 || b == 7) &&
      (c == 6 || c == 7) &&
      (d == 6 || d == 7) &&
      a + b + c + d == 25)) {
    err('answer_position_balance', 'got A$a B$b C$c D$d');
  }

  var run = 1;
  var maxRun = 1;
  for (var i = 1; i < correctSeq.length; i++) {
    if (correctSeq[i] == correctSeq[i - 1]) {
      run++;
      maxRun = math.max(maxRun, run);
    } else {
      run = 1;
    }
  }
  if (maxRun > 2) {
    err('answer_position_run', 'max consecutive correct position $maxRun > 2');
  }

  // Anchors: exactly 4, one per domain
  if (anchors.length != 4) {
    err('anchor_count', 'expected 4 anchors, got ${anchors.length}');
  }
  final anchorDomains = <String>{};
  for (final e in anchors.entries) {
    final it = items.cast<Map>().firstWhere(
          (x) => x['question_id'] == e.key,
        );
    anchorDomains.add(it['primary_dimension'].toString());
  }
  if (!iqDomains.every(anchorDomains.contains)) {
    err('anchor_domains', 'need one anchor per domain; got $anchorDomains');
  }

  // Duplicate prompts
  final promptCounts = <String, int>{};
  for (final p in prompts) {
    promptCounts[p] = (promptCounts[p] ?? 0) + 1;
  }
  for (final e in promptCounts.entries) {
    if (e.value > 1) {
      err('duplicate_prompt', 'normalized prompt repeated ${e.value}x');
    }
  }

  // Identical option sets
  final osCounts = <String, int>{};
  for (final s in optionSets) {
    osCounts[s] = (osCounts[s] ?? 0) + 1;
  }
  for (final e in osCounts.entries) {
    if (e.value > 1 && e.key.isNotEmpty) {
      warn('identical_option_set', 'option set repeated ${e.value}x');
    }
  }

  // Near-duplicate report (deterministic token Jaccard on contentful tokens)
  final near = <Map<String, Object?>>[];
  for (var i = 0; i < prompts.length; i++) {
    for (var j = i + 1; j < prompts.length; j++) {
      final ti = _tokens(prompts[i]);
      final tj = _tokens(prompts[j]);
      if (ti.length < 5 || tj.length < 5) continue;
      final sim = _jaccard(ti, tj);
      final exact = prompts[i] == prompts[j];
      if (exact || sim >= 0.85) {
        near.add({
          'a': (items[i] as Map)['question_id'],
          'b': (items[j] as Map)['question_id'],
          'jaccard': double.parse(sim.toStringAsFixed(4)),
          'exact_normalized': exact,
        });
      }
    }
  }
  near.sort((x, y) {
    final c = (x['a'] as String).compareTo(y['a'] as String);
    if (c != 0) return c;
    return (x['b'] as String).compareTo(y['b'] as String);
  });
  if (near.any((n) =>
      n['exact_normalized'] == true || (n['jaccard'] as double) >= 0.95)) {
    err('high_risk_near_duplicate', 'exact or jaccard>=0.95 pair present');
  } else if (near.isNotEmpty) {
    warn('near_duplicate', '${near.length} pairs jaccard>=0.85');
  }

  // Pubspec / production guards
  final pubspec = File('$root/pubspec.yaml').readAsStringSync();
  // Canonical bank may be runtime-registered; pilot assets must not be.
  if (pubspec.contains('iq_pilot_tr_v1') ||
      pubspec.contains('iq_pilot_tr_v1.json') ||
      pubspec.contains('review_candidate')) {
    err('pubspec_integration', 'pilot must not be listed in pubspec.yaml');
  }

  // Trait scoring parse + all-correct smoke
  try {
    final config = TraitScoringParser.parseConfigJson(
      File('$root/$configPath').readAsStringSync(),
    );
    final parsed = TraitScoringParser.parseItemBank(
      items,
      expectedModule: 'iq',
      source: pilotPath,
      config: config,
    );
    final svc = TraitScoringService(config: config);
    final allCorrect = [
      for (final q in parsed)
        AssessmentResponse(
          questionId: q.questionId,
          selectedOptionId: q.correctOptionId,
          responseTimeMilliseconds: 8000,
        ),
    ];
    final scored = svc.scoreModule(
      TraitScoringSessionInput(
        module: 'iq',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: parsed,
        submittedResponses: allCorrect,
        assessmentStatus: 'complete',
      ),
    );
    for (final d in iqDomains) {
      final s = scored.module.dimensionScores[d];
      if (s == null || (s - 1.0).abs() > 1e-9) {
        err('trait_all_correct', 'domain $d score=$s expected 1.0');
      }
    }
    if (scored.module.legacyRawScore != 25) {
      err('legacy_total',
          'legacyRawScore=${scored.module.legacyRawScore} expected 25');
    }
    info('trait_scoring', 'all-correct smoke passed');
  } catch (e) {
    err('trait_scoring_parse', '$e');
  }

  final errors = findings.where((f) => f.severity == 'error').length;
  final warns = findings.where((f) => f.severity == 'warn').length;

  report['automated_validation'] = errors == 0 ? 'PASS' : 'FAIL';
  report['manual_reasoning_review'] = 'PENDING';
  report['unresolved_semantic_risk'] = 'PENDING_EXPERT_REVIEW';
  report['domain_counts'] = domainCounts;
  report['difficulty_counts'] = {
    'easy_2': easy,
    'medium_3': mid,
    'hard_4': hard,
  };
  report['correct_option_counts'] = correctPos;
  report['correct_option_sequence'] = correctSeq.join();
  report['max_correct_run'] = maxRun;
  report['anchors'] = anchors;
  report['near_duplicates'] = near;
  report['error_count'] = errors;
  report['warn_count'] = warns;
  report['findings'] = [for (final f in findings) f.toJson()];
  report['notes'] = {
    'does_not_prove_answer_semantics': true,
    'offline_only': true,
    'not_production_wired': true,
  };

  final outDir = Directory('$root/tool/iq_pilot_out');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/validate_iq_pilot_v1_report.json');
  final encoded = const JsonEncoder.withIndent('  ').convert(_sortJson(report));
  outFile.writeAsStringSync('$encoded\n');

  stdout.writeln('=== IQ Pilot Validator (P2A-2B-1) ===');
  stdout.writeln('automated=${report['automated_validation']}');
  stdout.writeln('errors=$errors warns=$warns');
  stdout.writeln('domains=$domainCounts');
  stdout.writeln('difficulty=e$easy/m$mid/h$hard');
  stdout.writeln('correctPos=$correctPos maxRun=$maxRun');
  stdout.writeln('anchors=${anchors.length}');
  stdout.writeln('near_duplicates=${near.length}');
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('fingerprint=${encoded.hashCode}');

  exit(errors == 0 ? 0 : 1);
}

void _semanticHeuristics(
  Map<String, dynamic> j,
  void Function(String code, String msg, {String? qid}) warn,
) {
  final qid = j['question_id']?.toString();
  final tr = (j['prompt'] as Map)['tr'].toString().toLowerCase();
  if (tr.contains('hangisi değildir') || tr.contains('hangisi degildir')) {
    warn('negative_wording', 'negative stem present', qid: qid);
  }
  if (RegExp(r'\b(genellikle|çoğunlukla|cogunlukla)\b').hasMatch(tr)) {
    warn('ambiguous_quantifier', 'genellikle/çoğunlukla', qid: qid);
  }
  if (tr.length > 450) {
    warn('prompt_length', 'prompt unusually long', qid: qid);
  }
  final opts = (j['options'] as List)
      .map((o) => ((o as Map)['localized_text'] as Map)['tr'].toString())
      .toList();
  if (opts.any((t) =>
      t.toLowerCase().contains('hepsi') &&
      t.toLowerCase().contains('yukarı'))) {
    warn('all_of_above', 'possible all-of-the-above', qid: qid);
  }
  if (opts.any((t) =>
      t.toLowerCase().contains('hiçbiri') ||
      t.toLowerCase().contains('hicbiri'))) {
    warn('none_of_above', 'possible none-of-the-above', qid: qid);
  }
  final lens = opts.map((t) => t.length).toList()..sort();
  if (lens.last - lens.first > 80) {
    warn('option_length_gap', 'large option length difference', qid: qid);
  }
  final correct = j['correct_option_id'];
  final correctText = opts[(j['options'] as List)
      .indexWhere((o) => (o as Map)['option_id'] == correct)];
  if (correctText.length == lens.last && lens.last - lens[2] > 40) {
    warn('answer_length_leakage', 'correct option much longer', qid: qid);
  }
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[^\wçğıöşü\s]', caseSensitive: false), '')
    .trim();

Set<String> _tokens(String s) {
  const stop = {
    'bir',
    'bu',
    've',
    'ile',
    'icin',
    'için',
    'veya',
    'gibi',
    'olan',
    'nedir',
    'hangi',
    'hangisi',
    'sonra',
    'sonraki',
    'yerine',
    'gelmelidir',
    'dizi',
    'sayi',
    'sayı',
  };
  return s.split(' ').where((t) => t.length > 2 && !stop.contains(t)).toSet();
}

double _jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final inter = a.intersection(b).length;
  final union = a.union(b).length;
  return inter / union;
}

dynamic _sortJson(dynamic v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sortJson(v[k])};
  }
  if (v is List) return [for (final e in v) _sortJson(e)];
  return v;
}
