// Offline deterministic validator for EQ pilot form (P2A-2C-1).
// Usage: dart run tool/validate_eq_pilot_v1.dart
// Not runtime-wired. Does not prove semantic correctness of trade-offs.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

const pilotPath = 'assets/data/assessment_v3/eq/eq_pilot_tr_v1.json';
const configPath = 'assets/data/trait_scoring_config_v1.json';

const eqDims = PersonaDimensionIds.eq;

const requiredRviRoles = {
  'semantic_consistency',
  'reverse_consistency',
  'response_variation',
  'social_impression_risk',
  'repeated_context_stability',
  'timing_quality',
};

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
  report['review_state'] = form['review_state'];
  report['calibration_status'] = form['calibration_status'];

  if (form['form_id'] != 'eq_tr_pilot_v1') {
    err('form_id', 'expected eq_tr_pilot_v1');
  }
  if (form['module'] != 'eq') err('module', 'module must be eq');
  if (form['locale'] != 'tr-TR') err('locale', 'locale must be tr-TR');
  if (form['schema_version'] != 3) {
    err('schema_version', 'form schema_version must be 3');
  }
  if (form['question_schema_version'] != 'qmatch_question_schema_v3') {
    err('question_schema_version', 'must be qmatch_question_schema_v3');
  }
  if (form['content_version'] != 'eq-tr-pilot-v1') {
    err('content_version', 'expected eq-tr-pilot-v1');
  }
  if (form['status'] != 'pilot') err('status', 'status must be pilot');
  if (form['review_state'] != 'internal_review') {
    err('review_state', 'review_state must be internal_review');
  }
  if (form['calibration_status'] != 'uncalibrated') {
    err('calibration_status', 'must be uncalibrated');
  }
  if (form['set_id'] != 'eq_tr_pilot_v1_set_001') {
    err('set_id', 'expected eq_tr_pilot_v1_set_001');
  }
  if (form['question_count'] != 30) {
    err('question_count', 'question_count must be 30');
  }

  final items = (form['items'] as List?) ?? const [];
  if (items.length != 30) {
    err('item_count', 'expected 30 items, got ${items.length}');
  }

  late TraitScoringConfig config;
  try {
    config = TraitScoringParser.parseConfigJson(
      File('$root/$configPath').readAsStringSync(),
    );
  } catch (e) {
    err('config_parse', '$e');
    config = TraitScoringParser.parseConfigJson('{}');
  }

  final ids = <String>{};
  final domainCounts = <String, int>{};
  final secondaryAppearances = <String, int>{};
  final rviRoleCounts = <String, int>{};
  final prompts = <String>[];
  final scenarioFamilies =
      Map<String, dynamic>.from(form['item_scenario_families'] as Map? ?? {});
  final familyCounts = <String, int>{};
  final contextsByDim = {for (final d in eqDims) d: <String>{}};
  final idPattern = RegExp(r'^eq_tr_v1_[a-z_]+_\d{3}$');

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
    if (!idPattern.hasMatch(qid)) {
      err('question_id_pattern', 'expected eq_tr_v1_<dim>_00N', qid: qid);
    }
    if (j['module'] != 'eq') err('module', 'item module must be eq', qid: qid);
    if (j['schema_version'] != 'qmatch_question_schema_v3') {
      err('schema_version', 'item schema_version invalid', qid: qid);
    }
    if (j['content_version'] != form['content_version']) {
      err('content_version_mismatch', 'item content_version mismatch',
          qid: qid);
    }
    if (j['item_type'] != 'scenario_mcq') {
      err('item_type', 'expected scenario_mcq', qid: qid);
    }
    if (j['calibration_status'] != 'uncalibrated') {
      err('calibration_status', 'must be uncalibrated', qid: qid);
    }
    if (j['review_state'] != 'internal_review') {
      err('review_state', 'item review_state must be internal_review',
          qid: qid);
    }

    final domain = j['primary_dimension']?.toString() ?? '';
    if (!eqDims.contains(domain)) {
      err('unknown_dimension', domain, qid: qid);
    }
    if (PersonaDimensionIds.forbiddenAliases.contains(domain)) {
      err('retired_alias', domain, qid: qid);
    }
    domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;

    for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
      final sd = s.toString();
      if (!eqDims.contains(sd)) {
        err('secondary_not_canonical', sd, qid: qid);
      }
      secondaryAppearances[sd] = (secondaryAppearances[sd] ?? 0) + 1;
    }

    final fam = scenarioFamilies[qid]?.toString();
    if (fam == null || fam.isEmpty) {
      err('scenario_family_missing', 'missing item_scenario_families entry',
          qid: qid);
    } else {
      familyCounts[fam] = (familyCounts[fam] ?? 0) + 1;
      contextsByDim[domain]?.add(fam);
      for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
        contextsByDim[s.toString()]?.add(fam);
      }
    }

    for (final role in (j['response_validity_roles'] as List?) ?? const []) {
      final r = role.toString();
      rviRoleCounts[r] = (rviRoleCounts[r] ?? 0) + 1;
    }

    if (j.containsKey('correct_option_id') ||
        j.containsKey('correctAnswer') ||
        j.containsKey('correct') ||
        j.containsKey('solution_method') ||
        j.containsKey('cognitive_domain') ||
        j.containsKey('difficulty') ||
        j.containsKey('distractor_logic')) {
      err('iq_fields_forbidden', 'IQ-only fields present', qid: qid);
    }

    final secs = (j['estimated_completion_seconds'] as num?)?.toDouble() ?? 0;
    if (secs < 20 || secs > 90) {
      err('time_bounds', 'estimated_completion_seconds=$secs', qid: qid);
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
    final optLens = <int>[];
    final tradeoffNote = j['authoring_notes']?.toString() ?? '';
    for (final oRaw in options) {
      final o = Map<String, dynamic>.from(oRaw as Map);
      final oid = o['option_id']?.toString() ?? '';
      if (oid.isEmpty || !optIds.add(oid)) {
        err('option_id', 'duplicate/missing option_id', qid: qid);
      }
      if (!{'A', 'B', 'C', 'D'}.contains(oid)) {
        err('option_id_letter', 'expected A-D', qid: qid);
      }
      if (o.containsKey('persona_id') ||
          o.containsKey('persona_points') ||
          o.containsKey('correct') ||
          o.containsKey('correctAnswer')) {
        err('forbidden_option_field', 'persona/correct forbidden', qid: qid);
      }
      for (final req in [
        'social_desirability_risk',
        'response_style_risk',
        'extremity',
        'evidence_strength',
      ]) {
        if (!o.containsKey(req) || o[req] == null) {
          err('option_metadata', 'missing $req on $oid', qid: qid);
        }
      }
      final lt = Map<String, dynamic>.from(o['localized_text'] as Map? ?? {});
      optLens.add((lt['tr']?.toString() ?? '').length);

      final sdr = o['social_desirability_risk']?.toString() ?? '';
      if (sdr == 'high' &&
          !tradeoffNote.contains('tradeoff') &&
          !tradeoffNote.contains('how_avoids_ideal_answer')) {
        warn('high_sdr_no_tradeoff', 'high SDR without tradeoff note',
            qid: qid);
      }
      if (sdr == 'high' &&
          tradeoffNote.contains('sdr_item_risk=high') &&
          tradeoffNote.contains('unresolved')) {
        err('unresolved_high_sdr', 'item-level unresolved high SDR', qid: qid);
      }

      final deltas = Map<String, dynamic>.from(
        o['dimension_deltas'] as Map? ?? {},
      );
      if (!deltas.containsKey(domain)) {
        err('primary_delta_missing', 'primary $domain missing in option $oid',
            qid: qid);
      }
      var l1 = 0.0;
      var nonzero = 0;
      for (final de in deltas.entries) {
        if (!PersonaDimensionIds.allSet.contains(de.key)) {
          err('delta_unknown_dim', de.key, qid: qid);
        }
        if (!eqDims.contains(de.key) && de.key.isNotEmpty) {
          err('delta_non_eq', de.key, qid: qid);
        }
        final v = (de.value as num?)?.toDouble() ?? 0.0;
        if (v < -1 || v > 1) {
          err('delta_range', 'delta out of [-1,1]', qid: qid);
        }
        if (v.abs() > 1e-12) nonzero++;
        l1 += v.abs();
      }
      if (nonzero > 3) {
        err('too_many_dims', 'more than 3 nonzero deltas', qid: qid);
      }
      if (l1 > 1.40 + 1e-9) {
        err('authoring_l1', 'L1 $l1 > 1.40', qid: qid);
      }
      if (l1 > config.maxL1DeltaMagnitude + 1e-9) {
        err('config_l1', 'L1 exceeds config max', qid: qid);
      }
    }

    if (optLens.isNotEmpty) {
      optLens.sort();
      if (optLens.last > (1.5 * optLens.first).ceil()) {
        warn('option_length_leakage', 'max/min option length ratio > 1.5',
            qid: qid);
      }
    }

    _dominantOptionWarn(j, warn);

    final blob = jsonEncode(j).toLowerCase();
    for (final bad in [
      'persona_id',
      'persona_points',
      'correct_option_id',
      'correctanswer',
      '"hh"',
      '"hm"',
      'deep connector',
      'balanced frequency',
      'uygulayici',
    ]) {
      if (blob.contains(bad)) {
        err('forbidden_content', 'contains $bad', qid: qid);
      }
    }
    for (final g in PersonaDimensionIds.forbiddenLegacyGridIds) {
      if (RegExp('\\b$g\\b').hasMatch(blob)) {
        err('grid_id', 'legacy grid id $g', qid: qid);
      }
    }
    for (final f in PersonaDimensionIds.forbiddenFrequencyTypes) {
      if (blob.contains(f.toLowerCase())) {
        err('frequency_type', f, qid: qid);
      }
    }
  }

  for (final d in eqDims) {
    if (domainCounts[d] != 3) {
      err('primary_allocation',
          'expected 3 primary for $d got ${domainCounts[d]}');
    }
    if ((secondaryAppearances[d] ?? 0) < 2) {
      err('secondary_evidence', '$d secondary appearances < 2');
    }
    if ((contextsByDim[d]?.length ?? 0) < 3) {
      err('independent_contexts', '$d has < 3 scenario families');
    }
  }

  for (final e in (form['scenario_family_allocation'] as Map? ?? {}).entries) {
    final expected = (e.value as num?)?.toInt();
    final got = familyCounts[e.key.toString()] ?? 0;
    if (expected != got) {
      err('family_allocation', '${e.key} expected $expected got $got');
    }
  }

  final pairRegistry =
      Map<String, dynamic>.from(form['pair_registry'] as Map? ?? {});
  final semRegistry = (pairRegistry['semantic_pairs'] as List?) ?? const [];
  final revRegistry = (pairRegistry['reverse_pairs'] as List?) ?? const [];
  final isoRegistry =
      (pairRegistry['behavioral_isomorph_groups'] as List?) ?? const [];

  if (semRegistry.length < 6) {
    err('semantic_pairs', 'expected >=6 semantic pairs');
  }
  if (revRegistry.length < 5) {
    err('reverse_pairs', 'expected >=5 reverse pairs');
  }
  if (isoRegistry.length < 5) {
    err('isomorph_groups', 'expected >=5 isomorph groups');
  }

  _validatePairRegistry(
    semRegistry,
    'semantic_pair_id',
    ids,
    items,
    err,
    idKey: 'pair_id',
  );
  _validatePairRegistry(
    revRegistry,
    'reverse_pair_id',
    ids,
    items,
    err,
    idKey: 'pair_id',
  );
  _validatePairRegistry(
    isoRegistry,
    'behavioral_isomorph_group',
    ids,
    items,
    err,
    idKey: 'group_id',
  );

  for (final role in requiredRviRoles) {
    if ((rviRoleCounts[role] ?? 0) == 0) {
      err('rvi_role_missing', 'form missing RVI role $role');
    }
  }

  final promptCounts = <String, int>{};
  for (final p in prompts) {
    promptCounts[p] = (promptCounts[p] ?? 0) + 1;
  }
  for (final e in promptCounts.entries) {
    if (e.value > 1) {
      err('duplicate_prompt', 'normalized prompt repeated ${e.value}x');
    }
  }

  final pubspec = File('$root/pubspec.yaml').readAsStringSync();
  if (pubspec.contains('eq_pilot_tr_v1') ||
      pubspec.contains('eq_pilot_tr_v1_review_candidate')) {
    err('pubspec_integration', 'pilot must not be listed in pubspec.yaml');
  }

  try {
    final parsed = TraitScoringParser.parseItemBank(
      items,
      expectedModule: 'eq',
      source: pilotPath,
      config: config,
    );
    final svc = TraitScoringService(config: config);

    AssessmentOptionDefinition pickMax(AssessmentItemDefinition q, String d) {
      AssessmentOptionDefinition? best;
      var bestVal = double.negativeInfinity;
      for (final o in q.options) {
        final v = o.dimensionDeltas[d] ?? 0.0;
        if (v > bestVal) {
          bestVal = v;
          best = o;
        }
      }
      return best ?? q.options.first;
    }

    AssessmentOptionDefinition pickMin(AssessmentItemDefinition q, String d) {
      AssessmentOptionDefinition? best;
      var bestVal = double.infinity;
      for (final o in q.options) {
        final v = o.dimensionDeltas[d] ?? 0.0;
        if (v < bestVal) {
          bestVal = v;
          best = o;
        }
      }
      return best ?? q.options.first;
    }

    AssessmentOptionDefinition pickModerate(AssessmentItemDefinition q) {
      AssessmentOptionDefinition? best;
      var bestAbs = double.infinity;
      for (final o in q.options) {
        final v = (o.dimensionDeltas[q.primaryDimension] ?? 0.0).abs();
        if (v < bestAbs) {
          bestAbs = v;
          best = o;
        }
      }
      return best ?? q.options.first;
    }

    List<AssessmentResponse> keyed(
      AssessmentOptionDefinition Function(AssessmentItemDefinition q) pick, {
      int baseMs = 6500,
    }) =>
        [
          for (var i = 0; i < parsed.length; i++)
            AssessmentResponse(
              questionId: parsed[i].questionId,
              selectedOptionId: pick(parsed[i]).optionId,
              responseTimeMilliseconds: baseMs + i * 113,
            ),
        ];

    TraitScoringSessionInput sess(
      List<AssessmentResponse> rs, {
      String status = 'complete',
      List<AssessmentItemDefinition>? defs,
    }) {
      final defsFinal = defs ?? parsed;
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
        if (!defsFinal.any((q) => q.questionId == r.questionId)) {
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
        module: 'eq',
        schemaVersion: config.questionSchemaVersion,
        contentVersion: form['content_version'] as String,
        traitScoringVersion: config.traitScoringVersion,
        locale: 'tr',
        setId: form['set_id'] as String,
        questionDefinitions: defsFinal,
        submittedResponses: rs,
        assessmentStatus: status,
      );
    }

    final balanced = svc.scoreModule(
      sess(keyed(pickModerate)),
    );
    final fullRun = svc.scoreModule(
      sess(
        keyed((q) => pickMax(q, q.primaryDimension)),
      ),
    );
    for (final d in eqDims) {
      if (!fullRun.module.dimensionScores.containsKey(d)) {
        err('trait_all_dims', 'missing score for $d on full run');
      }
    }

    final highEmp = svc.scoreModule(
      sess(keyed(
        (q) => q.primaryDimension == 'empathy'
            ? pickMax(q, 'empathy')
            : pickModerate(q),
      )),
    );
    final lowEmp = svc.scoreModule(
      sess(keyed(
        (q) => q.primaryDimension == 'empathy'
            ? pickMin(q, 'empathy')
            : pickModerate(q),
      )),
    );
    if (!highEmp.module.dimensionScores.containsKey('empathy') ||
        !lowEmp.module.dimensionScores.containsKey('empathy')) {
      err('empathy_scores', 'empathy not scored');
    } else if (highEmp.module.dimensionScores['empathy']! <=
        lowEmp.module.dimensionScores['empathy']!) {
      err('negative_evidence', 'high empathy should exceed low empathy');
    }

    final omitEmpathy = [
      for (final q in parsed)
        if (q.primaryDimension != 'empathy')
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: pickModerate(q).optionId,
            responseTimeMilliseconds: 7000,
          ),
    ];
    final miss = svc.scoreModule(sess(omitEmpathy));
    if (miss.module.dimensionScores.containsKey('empathy')) {
      err('missing_published',
          'empathy should be missing when primaries omitted');
    }
    if (!miss.module.missingDimensions.contains('empathy') &&
        !miss.module.insufficientDimensions.contains('empathy')) {
      err('missing_flag', 'empathy not flagged missing/insufficient');
    }

    final incomplete = svc.scoreModule(
      sess(keyed(pickModerate).take(5).toList(), status: 'incomplete'),
    );
    if (incomplete.module.status != ModuleTraitStatus.incomplete) {
      err('incomplete_status', 'expected incomplete module status');
    }

    try {
      sess([
        ...keyed(pickModerate),
        AssessmentResponse(
          questionId: parsed.first.questionId,
          selectedOptionId: 'A',
        ),
      ]);
      err('duplicate_not_rejected', 'expected duplicate throw');
    } on TraitScoringValidationException {
      info('duplicate', 'rejected');
    }
    try {
      sess([
        const AssessmentResponse(
          questionId: 'does_not_exist',
          selectedOptionId: 'A',
        ),
      ]);
      err('unknown_not_rejected', 'expected unknown throw');
    } on TraitScoringValidationException {
      info('unknown', 'rejected');
    }

    final canonicalResponses = keyed(pickModerate)
      ..sort((a, b) => a.questionId.compareTo(b.questionId));
    final s1 = svc.scoreModule(sess(canonicalResponses));
    final revParsed = parsed.reversed.toList();
    final s2 = svc.scoreModule(
      sess(canonicalResponses, defs: revParsed),
    );
    if (s1.module.dimensionScores.length != s2.module.dimensionScores.length) {
      err('order_independence',
          'shuffled defs changed published dimension count');
    } else {
      for (final e in s1.module.dimensionScores.entries) {
        if ((e.value - (s2.module.dimensionScores[e.key] ?? -1)).abs() > 1e-9) {
          err('order_independence', 'shuffled defs/responses changed ${e.key}');
          break;
        }
      }
    }

    final idealized = svc.scoreModule(
      sess(keyed((q) {
        if (!q.responseValidityRoles.contains('social_impression_risk')) {
          return pickModerate(q);
        }
        return pickMax(q, q.primaryDimension);
      })),
    );
    if (!idealized.module.responseValidity.componentScores
        .containsKey('social_impression_risk')) {
      err('impression_component', 'social_impression_risk missing from RVI');
    } else {
      final imp = idealized
          .module.responseValidity.componentScores['social_impression_risk']!;
      if (!imp.isFinite || imp < 0 || imp > 1) {
        err('impression_bounded', 'impression component out of bounds');
      }
    }

    final traitsBefore = balanced.module.dimensionScores;
    final traitsAfter = svc
        .scoreModule(
          sess(canonicalResponses),
          rviInput: const ResponseValidityInput(impressionRiskOverride: 0.99),
        )
        .module
        .dimensionScores;
    if (traitsBefore.length != traitsAfter.length) {
      err('rvi_trait_separation',
          'RVI override changed published dimension set');
    } else {
      for (final e in traitsBefore.entries) {
        if ((e.value - (traitsAfter[e.key] ?? -1)).abs() > 1e-9) {
          err('rvi_trait_separation', 'RVI override changed trait scores');
          break;
        }
      }
    }

    info('trait_scoring',
        'EQ pilot scoring smoke passed (${parsed.length} items)');
  } catch (e) {
    if (e is! TraitScoringValidationException ||
        findings.any((f) => f.code == 'duplicate_not_rejected')) {
      err('trait_scoring_parse', '$e');
    }
  }

  final errors = findings.where((f) => f.severity == 'error').length;
  final warns = findings.where((f) => f.severity == 'warn').length;

  report['automated_validation'] =
      errors == 0 ? (warns > 0 ? 'CONDITIONAL' : 'PASS') : 'FAIL';
  report['overall_readiness'] = errors == 0 ? 'CONDITIONAL' : 'FAIL';
  report['manual_tradeoff_review'] = 'PENDING';
  report['domain_counts'] = domainCounts;
  report['scenario_family_counts'] = familyCounts;
  report['secondary_appearances'] = secondaryAppearances;
  report['rvi_role_counts'] = rviRoleCounts;
  report['independent_context_counts'] = {
    for (final e in contextsByDim.entries) e.key: e.value.length,
  };
  report['pair_registry_counts'] = {
    'semantic_pairs': semRegistry.length,
    'reverse_pairs': revRegistry.length,
    'behavioral_isomorph_groups': isoRegistry.length,
  };
  report['error_count'] = errors;
  report['warn_count'] = warns;
  report['findings'] = [for (final f in findings) f.toJson()];
  report['notes'] = {
    'does_not_prove_tradeoff_semantics': true,
    'offline_only': true,
    'not_production_wired': true,
    'json_map_order_not_applicable': true,
  };

  final outDir = Directory('$root/tool/eq_pilot_out');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/validate_eq_pilot_v1_report.json');
  final encoded = const JsonEncoder.withIndent('  ').convert(_sortJson(report));
  outFile.writeAsStringSync('$encoded\n');

  stdout.writeln('=== EQ Pilot Validator (P2A-2C-1) ===');
  stdout.writeln('automated=${report['automated_validation']}');
  stdout.writeln('errors=$errors warns=$warns');
  stdout.writeln('domains=$domainCounts');
  stdout.writeln('families=$familyCounts');
  stdout.writeln('rvi=$rviRoleCounts');
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('fingerprint=${encoded.hashCode}');

  exit(errors == 0 ? 0 : 1);
}

void _validatePairRegistry(
  List<dynamic> registry,
  String itemField,
  Set<String> ids,
  List<dynamic> items,
  void Function(String, String) err, {
  required String idKey,
}) {
  for (final raw in registry) {
    final p = Map<String, dynamic>.from(raw as Map);
    final pid = p[idKey]?.toString() ?? '';
    final qids = List<String>.from(
      (p['question_ids'] as List?)?.map((e) => e.toString()) ?? const [],
    );
    if (qids.length < 2) {
      err('pair_registry', '$pid needs >=2 question_ids');
    }
    for (final qid in qids) {
      if (!ids.contains(qid)) {
        err('pair_registry', '$pid references unknown $qid');
      }
      final item = items.cast<Map>().firstWhere(
            (x) => x['question_id'] == qid,
            orElse: () => {},
          );
      if (item.isEmpty) continue;
      if (item[itemField]?.toString() != pid) {
        err('pair_registry_mismatch', '$qid $itemField != $pid');
      }
    }
  }
}

void _dominantOptionWarn(
  Map<String, dynamic> j,
  void Function(String code, String msg, {String? qid}) warn,
) {
  final qid = j['question_id']?.toString();
  final primary = j['primary_dimension']?.toString() ?? '';
  for (final oRaw in (j['options'] as List?) ?? const []) {
    final o = Map<String, dynamic>.from(oRaw as Map);
    final deltas = Map<String, dynamic>.from(
      o['dimension_deltas'] as Map? ?? {},
    );
    if (deltas.isEmpty) continue;
    var allPositive = true;
    var primaryMag = 0.0;
    var maxOther = 0.0;
    for (final e in deltas.entries) {
      final v = (e.value as num?)?.toDouble() ?? 0.0;
      if (v <= 0) allPositive = false;
      if (e.key == primary) {
        primaryMag = v.abs();
      } else {
        maxOther = math.max(maxOther, v.abs());
      }
    }
    if (allPositive && primaryMag > maxOther && primaryMag > 0.5) {
      warn('dominant_option', 'option ${o['option_id']} positive on all dims',
          qid: qid);
    }
  }
}

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[^\wçğıöşü\s]', caseSensitive: false), '')
    .trim();

dynamic _sortJson(dynamic v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _sortJson(v[k])};
  }
  if (v is List) return [for (final e in v) _sortJson(e)];
  return v;
}
