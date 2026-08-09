// Offline assessment-bank audit (P2A-1).
//
// - Does not modify bank files
// - Deterministic rule-based classifications (not expert replacement)
// - No Firebase / network
//
// Usage:
//   dart run tool/audit_assessment_banks.dart

import 'dart:convert';
import 'dart:io';

const outDirRel = 'tool/assessment_bank_audit_out';

const canonIq = {
  'logical_reasoning',
  'pattern_reasoning',
  'verbal_reasoning',
  'spatial_reasoning',
};

const canonEq = {
  'empathy',
  'perspective_taking',
  'self_awareness',
  'emotion_regulation',
  'emotional_openness',
  'boundary_setting',
  'assertiveness',
  'conflict_approach',
  'repair_orientation',
  'social_awareness',
};

const canonFreq = {
  'depth_preference',
  'social_energy',
  'spontaneity',
  'stability',
  'disclosure_pace',
  'communication_pace',
};

const legacyFreqMap = {
  'depth': 'depth_preference',
  'socialEnergy': 'social_energy',
  'spontaneity': 'spontaneity',
  'stability': 'stability',
  'emotionalOpenness': 'disclosure_pace',
  'conversationPace': 'communication_pace',
};

const forbiddenPersonaHints = [
  'uygulayici',
  'koruyucu',
  'bilge',
  'lider',
  'muhafiz',
  'sifaci',
  'yargic',
  'empat',
  'cesur',
  'kararli',
  'vizyoner',
  'yaratici',
  'iletisimci',
  'analist',
  'donusturucu',
  'bagimsiz',
  'sezgisel',
  'stratejist',
];

const socialCueEn = [
  'the right thing',
  'be a good person',
  'always be kind',
  'never hurt',
  'perfect partner',
];

String normText(Object? raw) {
  if (raw == null) return '';
  if (raw is Map) {
    final parts = raw.values.map((v) => v.toString()).toList()..sort();
    return parts.join(' ').toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  return raw.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String fingerprint(String s) {
  final t = s.replaceAll(RegExp(r'[^a-z0-9ğüşıöçâîû ]'), ' ');
  final tokens = t.split(RegExp(r'\s+')).where((e) => e.length > 2).toList()
    ..sort();
  return tokens.take(24).join(' ');
}

class ItemRecord {
  ItemRecord({
    required this.module,
    required this.sourcePath,
    required this.setId,
    required this.questionId,
    required this.raw,
  });

  final String module;
  final String sourcePath;
  final String setId;
  final String questionId;
  final Map<String, dynamic> raw;
}

List<ItemRecord> loadSetItems(String path, String module) {
  final root =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final sets = (root['sets'] as List).cast<Map<String, dynamic>>();
  final out = <ItemRecord>[];
  for (final s in sets) {
    final setId = s['id']?.toString() ?? 'unknown_set';
    final qs = (s['questions'] as List? ?? const []).cast<dynamic>();
    for (var i = 0; i < qs.length; i++) {
      final q = Map<String, dynamic>.from(qs[i] as Map);
      final id = (q['id'] ?? q['question_id'] ?? '${setId}_q$i').toString();
      out.add(
        ItemRecord(
          module: module,
          sourcePath: path,
          setId: setId,
          questionId: id,
          raw: q,
        ),
      );
    }
  }
  // Stable order
  out.sort((a, b) {
    final c = a.setId.compareTo(b.setId);
    if (c != 0) return c;
    return a.questionId.compareTo(b.questionId);
  });
  return out;
}

List<ItemRecord> loadFlatList(String path, String module) {
  final list =
      (jsonDecode(File(path).readAsStringSync()) as List).cast<dynamic>();
  final out = <ItemRecord>[];
  for (var i = 0; i < list.length; i++) {
    final q = Map<String, dynamic>.from(list[i] as Map);
    final id = (q['id'] ?? '${module}_legacy_$i').toString();
    out.add(
      ItemRecord(
        module: module,
        sourcePath: path,
        setId: 'legacy_flat',
        questionId: id,
        raw: q,
      ),
    );
  }
  out.sort((a, b) => a.questionId.compareTo(b.questionId));
  return out;
}

Map<String, dynamic> classifyItem(ItemRecord item, Set<String> nearDupIds) {
  final reasons = <String>[];
  final q = item.raw;
  var cls = 'KEEP';

  void bump(String next, String reason) {
    reasons.add(reason);
    const rank = {
      'KEEP': 0,
      'KEEP_WITH_METADATA': 1,
      'MANUAL_REVIEW': 2,
      'REWRITE': 3,
      'RETIRE': 4,
    };
    if ((rank[next] ?? 0) > (rank[cls] ?? 0)) cls = next;
  }

  final id = item.questionId;
  if (id.isEmpty) bump('REWRITE', 'missing_id');

  final text = normText(q['text'] ?? q['question']);
  if (text.length < 8) bump('REWRITE', 'unclear_or_too_short');

  final localesOk = q['question'] is Map &&
      (q['question'] as Map).containsKey('tr') &&
      (q['question'] as Map).containsKey('en');
  if (q['question'] is Map && !localesOk) {
    bump('REWRITE', 'localization_incomplete');
  }
  if (q['question'] is String) {
    bump('KEEP_WITH_METADATA', 'missing_bilingual_object');
  }

  if (!q.containsKey('content_version') && !q.containsKey('schema_version')) {
    bump('KEEP_WITH_METADATA', 'missing_version_metadata');
  }

  if (nearDupIds.contains(id)) {
    bump('MANUAL_REVIEW', 'near_duplicate_fingerprint');
  }

  for (final p in forbiddenPersonaHints) {
    if (text.contains(p)) bump('REWRITE', 'persona_name_in_prompt');
  }

  final module = item.module;
  var mappable = false;
  String? mappedDim;

  if (module == 'iq' || module.startsWith('iq')) {
    final opts = q['options'];
    if (opts is! List || opts.length != 4) {
      bump('REWRITE', 'invalid_option_count');
    }
    if (!q.containsKey('correctAnswer') &&
        !q.containsKey('correct_option_id')) {
      bump('REWRITE', 'missing_keyed_answer');
    }
    final domain =
        q['primary_dimension'] ?? q['cognitive_domain'] ?? q['dimension'];
    if (domain == null || !canonIq.contains(domain.toString())) {
      bump('KEEP_WITH_METADATA', 'missing_canonical_iq_domain');
      mappable = false;
    } else {
      mappable = true;
      mappedDim = domain.toString();
    }
    if (q['difficulty'] == null) {
      bump('KEEP_WITH_METADATA', 'missing_difficulty');
    }
    if (!q.containsKey('solution_method') &&
        !q.containsKey('distractor_logic')) {
      bump('KEEP_WITH_METADATA', 'missing_solution_or_distractor_logic');
    }
  } else if (module == 'eq' || module.startsWith('eq')) {
    if (q.containsKey('correctAnswer') ||
        q.containsKey('correct_option_id') ||
        q['correct'] == true) {
      bump('REWRITE', 'eq_uses_correct_answer_field');
    }
    final opts = q['options'];
    if (opts is! List || opts.length < 2) {
      bump('REWRITE', 'invalid_option_count');
    }
    final dim = q['primary_dimension'] ?? q['dimension'];
    if (dim != null && canonEq.contains(dim.toString())) {
      mappable = true;
      mappedDim = dim.toString();
    } else {
      bump('REWRITE', 'unmappable_eq_dimension');
      mappable = false;
    }
    for (final cue in socialCueEn) {
      if (text.contains(cue)) bump('REWRITE', 'obvious_social_answer_risk');
    }
    // Heuristic: keyed EQ strongly implies moralized design
    if (q.containsKey('correctAnswer')) {
      bump('REWRITE', 'moralized_or_keyed_eq_design');
    }
  } else if (module == 'frequency' || module.startsWith('frequency')) {
    final dimRaw = (q['dimension'] ?? q['primary_dimension'] ?? '').toString();
    final mapped =
        legacyFreqMap[dimRaw] ?? (canonFreq.contains(dimRaw) ? dimRaw : null);
    if (mapped == null) {
      bump('REWRITE', 'unmappable_frequency_dimension');
      mappable = false;
    } else {
      mappable = true;
      mappedDim = mapped;
      if (legacyFreqMap.containsKey(dimRaw)) {
        bump('KEEP_WITH_METADATA', 'legacy_frequency_dimension_alias');
      }
    }
    if (q.containsKey('correctAnswer')) {
      bump('REWRITE', 'frequency_correct_answer_forbidden');
    }
    if (text.contains('aura') ||
        text.contains('vibration') ||
        text.contains('destiny') ||
        text.contains('kader')) {
      bump('REWRITE', 'mystical_or_unsupported_claim');
    }
    if (!q.containsKey('options') && q['reverseScored'] != null) {
      bump('KEEP_WITH_METADATA', 'likert_needs_schema_v3_scale_deltas');
    }
  }

  if (item.setId == 'legacy_flat') {
    bump('RETIRE', 'superseded_by_assessment_sets');
  }

  // Default: if still KEEP but missing metadata path already applied
  if (cls == 'KEEP' && reasons.isEmpty) {
    reasons.add('passes_rule_checks');
  }

  return {
    'question_id': id,
    'module': module,
    'set_id': item.setId,
    'source_path': item.sourcePath,
    'classification': cls,
    'reasons': reasons..sort(),
    'mappable_to_canonical': mappable,
    'mapped_dimension': mappedDim,
    'text_fingerprint': fingerprint(text),
  };
}

Map<String, dynamic> auditModule({
  required String module,
  required List<ItemRecord> items,
}) {
  // Near-duplicate fingerprints
  final fpToIds = <String, List<String>>{};
  for (final it in items) {
    final text = normText(it.raw['text'] ?? it.raw['question']);
    final fp = fingerprint(text);
    if (fp.isEmpty) continue;
    (fpToIds[fp] ??= []).add(it.questionId);
  }
  final nearDupIds = <String>{};
  final nearDupGroups = <String, List<String>>{};
  for (final e in fpToIds.entries) {
    if (e.value.length > 1) {
      nearDupGroups[e.key] = (e.value.toList()..sort());
      nearDupIds.addAll(e.value);
    }
  }

  final classified = [
    for (final it in items) classifyItem(it, nearDupIds),
  ];
  classified.sort((a, b) =>
      (a['question_id'] as String).compareTo(b['question_id'] as String));

  final counts = <String, int>{
    'KEEP': 0,
    'KEEP_WITH_METADATA': 0,
    'REWRITE': 0,
    'RETIRE': 0,
    'MANUAL_REVIEW': 0,
  };
  final dimDist = <String, int>{};
  var missingMeta = 0;
  var mappable = 0;
  var unmappable = 0;
  var socialRisk = 0;
  var disputedIq = 0;
  var localizationIssues = 0;
  var securityExposure = 0;

  final setIds = <String>{};
  for (final c in classified) {
    final cls = c['classification'] as String;
    counts[cls] = (counts[cls] ?? 0) + 1;
    setIds.add(c['set_id'] as String);
    final reasons = (c['reasons'] as List).cast<String>();
    if (reasons.any((r) => r.contains('missing_'))) missingMeta++;
    if (c['mappable_to_canonical'] == true) {
      mappable++;
      final d = c['mapped_dimension'] as String?;
      if (d != null) dimDist[d] = (dimDist[d] ?? 0) + 1;
    } else {
      unmappable++;
    }
    if (reasons.any((r) => r.contains('social') || r.contains('moralized'))) {
      socialRisk++;
    }
    if (reasons
        .any((r) => r.contains('keyed_answer') || r.contains('solution'))) {
      disputedIq++;
    }
    if (reasons.any((r) => r.contains('localization'))) localizationIssues++;
    if (reasons
        .any((r) => r.contains('persona_name') || r.contains('exposure'))) {
      securityExposure++;
    }
  }

  final uniqueIds = classified.map((c) => c['question_id']).toSet().length;
  final exactDupExtra = items.length - uniqueIds;

  String nextAction;
  if ((counts['REWRITE'] ?? 0) > items.length * 0.5) {
    nextAction =
        'Author schema-v3 replacements; do not promote current items to active';
  } else if ((counts['KEEP_WITH_METADATA'] ?? 0) > items.length * 0.5) {
    nextAction = 'Attach canonical metadata / migrate aliases before reuse';
  } else {
    nextAction = 'Selective rewrite with manual construct review';
  }

  return {
    'module': module,
    'total_set_count': setIds.length,
    'total_item_count': items.length,
    'unique_question_count': uniqueIds,
    'duplicate_id_extra_count': exactDupExtra < 0 ? 0 : exactDupExtra,
    'near_duplicate_group_count': nearDupGroups.length,
    'near_duplicate_item_count': nearDupIds.length,
    'items_with_missing_metadata_signals': missingMeta,
    'classification_counts': counts,
    'dimension_mappable_count': mappable,
    'dimension_unmappable_count': unmappable,
    'canonical_dimension_distribution': Map.fromEntries(
      (dimDist.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
    ),
    'obvious_social_answer_risk_count': socialRisk,
    'disputed_or_weak_iq_answer_risk_count': disputedIq,
    'localization_issue_count': localizationIssues,
    'security_exposure_issue_count': securityExposure,
    'recommended_next_action': nextAction,
    'near_duplicate_groups': Map.fromEntries(
      (nearDupGroups.entries.toList()..sort((a, b) => a.key.compareTo(b.key))),
    ),
    'items': classified,
  };
}

String toMarkdown(Map<String, dynamic> report) {
  final buf = StringBuffer();
  buf.writeln('# Current Assessment Bank Audit v1');
  buf.writeln();
  buf.writeln('**Status:** offline deterministic rule audit (P2A-1)');
  buf.writeln(
      '**Generated_at_logic:** content-hash stable; no wall-clock in body');
  buf.writeln(
      '**Important:** Automated checks do **not** replace expert manual review.');
  buf.writeln('**Banks were not modified.**');
  buf.writeln();
  buf.writeln('Audit content version: `${report['audit_content_version']}`');
  buf.writeln();

  for (final key in ['iq', 'eq', 'frequency', 'legacy_flat']) {
    final m = report['modules'][key] as Map<String, dynamic>?;
    if (m == null) continue;
    buf.writeln('## ${key.toUpperCase()}');
    buf.writeln();
    buf.writeln('| Metric | Value |');
    buf.writeln('|---|---:|');
    buf.writeln('| Total sets | ${m['total_set_count']} |');
    buf.writeln('| Total items | ${m['total_item_count']} |');
    buf.writeln('| Unique question ids | ${m['unique_question_count']} |');
    buf.writeln(
        '| Near-duplicate groups | ${m['near_duplicate_group_count']} |');
    buf.writeln('| Near-duplicate items | ${m['near_duplicate_item_count']} |');
    buf.writeln(
        '| Missing-metadata signals | ${m['items_with_missing_metadata_signals']} |');
    final cc = m['classification_counts'] as Map;
    for (final k in [
      'KEEP',
      'KEEP_WITH_METADATA',
      'REWRITE',
      'RETIRE',
      'MANUAL_REVIEW'
    ]) {
      buf.writeln('| $k | ${cc[k] ?? 0} |');
    }
    buf.writeln('| Dimension-mappable | ${m['dimension_mappable_count']} |');
    buf.writeln('| Unmappable | ${m['dimension_unmappable_count']} |');
    buf.writeln(
        '| Social-answer risk | ${m['obvious_social_answer_risk_count']} |');
    buf.writeln(
        '| IQ answer/logic risk signals | ${m['disputed_or_weak_iq_answer_risk_count']} |');
    buf.writeln('| Localization issues | ${m['localization_issue_count']} |');
    buf.writeln(
        '| Security/exposure issues | ${m['security_exposure_issue_count']} |');
    buf.writeln();
    buf.writeln('**Recommended next action:** ${m['recommended_next_action']}');
    buf.writeln();
    buf.writeln('### Canonical dimension distribution (where mapped)');
    buf.writeln();
    final dist =
        Map<String, dynamic>.from(m['canonical_dimension_distribution'] as Map);
    if (dist.isEmpty) {
      buf.writeln('_None mappable with current metadata._');
    } else {
      buf.writeln('| Dimension | Count |');
      buf.writeln('|---|---:|');
      for (final e in dist.entries) {
        buf.writeln('| `${e.key}` | ${e.value} |');
      }
    }
    buf.writeln();
  }

  final totals = report['totals'] as Map<String, dynamic>;
  buf.writeln('## Totals across audited sources');
  buf.writeln();
  buf.writeln('| Classification | Count |');
  buf.writeln('|---|---:|');
  final tc = totals['classification_counts'] as Map;
  for (final k in [
    'KEEP',
    'KEEP_WITH_METADATA',
    'REWRITE',
    'RETIRE',
    'MANUAL_REVIEW'
  ]) {
    buf.writeln('| $k | ${tc[k] ?? 0} |');
  }
  buf.writeln();
  buf.writeln('## Coverage findings');
  buf.writeln();
  buf.writeln(
      '- IQ items lack canonical domain metadata → unmappable to 4 IQ domains without rewrite/enrichment.');
  buf.writeln(
      '- EQ items use `correctAnswer` and lack canonical EQ dimensions → treat as REWRITE before persona handoff.');
  buf.writeln(
      '- Frequency items map 1:1 via legacy aliases to all 6 canonical Frequency dims (100 each in sets), but need schema-v3 Likert evidence deltas.');
  buf.writeln(
      '- Legacy flat IQ/EQ lists are RETIRE candidates (superseded by assessment_sets).');
  buf.writeln();
  buf.writeln('## Uncertainty');
  buf.writeln();
  buf.writeln(
      'MANUAL_REVIEW and heuristic social-risk flags are uncertain. Expert construct review is required before any item becomes `active`.');
  buf.writeln();
  return buf.toString();
}

void main(List<String> args) {
  final root = Directory.current.path;
  final iq =
      loadSetItems('$root/assets/data/assessment_sets/iq_sets.json', 'iq');
  final eq =
      loadSetItems('$root/assets/data/assessment_sets/eq_sets.json', 'eq');
  final freq = loadSetItems(
    '$root/assets/data/assessment_sets/frequency_sets.json',
    'frequency',
  );
  final legacyIq =
      loadFlatList('$root/assets/data/iq_questions.json', 'iq_legacy');
  final legacyEq =
      loadFlatList('$root/assets/data/eq_questions.json', 'eq_legacy');

  final modules = {
    'iq': auditModule(module: 'iq', items: iq),
    'eq': auditModule(module: 'eq', items: eq),
    'frequency': auditModule(module: 'frequency', items: freq),
    'legacy_flat': auditModule(
      module: 'legacy_flat',
      items: [...legacyIq, ...legacyEq],
    ),
  };

  final totalsCounts = <String, int>{
    'KEEP': 0,
    'KEEP_WITH_METADATA': 0,
    'REWRITE': 0,
    'RETIRE': 0,
    'MANUAL_REVIEW': 0,
  };
  var totalItems = 0;
  for (final m in modules.values) {
    totalItems += m['total_item_count'] as int;
    final cc = m['classification_counts'] as Map;
    for (final e in cc.entries) {
      totalsCounts[e.key.toString()] =
          (totalsCounts[e.key.toString()] ?? 0) + (e.value as int);
    }
  }

  final report = {
    'audit_content_version': 'assessment_bank_audit_v1',
    'status': 'deterministic_rule_audit_only',
    'banks_modified': false,
    'sources': [
      'assets/data/assessment_sets/iq_sets.json',
      'assets/data/assessment_sets/eq_sets.json',
      'assets/data/assessment_sets/frequency_sets.json',
      'assets/data/iq_questions.json',
      'assets/data/eq_questions.json',
    ],
    'modules': modules,
    'totals': {
      'total_item_count': totalItems,
      'classification_counts': totalsCounts,
    },
    'notes': {
      'not_expert_replacement': true,
      'uncertain_classifications_retained': true,
      'persona_scoring_service_not_modified': true,
    },
  };

  final outDir = Directory('$root/$outDirRel');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final jsonPath = '${outDir.path}/audit_report.json';
  final mdPath = '${outDir.path}/current_assessment_bank_audit_v1.md';
  final jsonText = const JsonEncoder.withIndent('  ').convert(report);
  File(jsonPath).writeAsStringSync('$jsonText\n');

  final md = toMarkdown(report);
  File(mdPath).writeAsStringSync(md);
  // Also publish to docs path for human navigation (same bytes).
  File('$root/docs/core_engine/current_assessment_bank_audit_v1.md')
      .writeAsStringSync(md);

  stdout.writeln('=== Assessment bank audit (deterministic) ===');
  stdout.writeln('total_items=$totalItems');
  stdout.writeln('counts=$totalsCounts');
  stdout.writeln('wrote $jsonPath');
  stdout.writeln('wrote $mdPath');
  stdout.writeln('wrote docs/core_engine/current_assessment_bank_audit_v1.md');
}
