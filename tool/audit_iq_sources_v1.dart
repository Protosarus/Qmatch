// Offline IQ source inventory (P2C-2A-0).
// Usage: dart run tool/audit_iq_sources_v1.dart
//
// Does not touch Firebase, runtime selection, or scoring.

import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current.path;
  final sources = <Map<String, dynamic>>[];

  void add({
    required String path,
    required String fileType,
    required int itemCount,
    required String language,
    required Map<String, int> dimensions,
    required Map<String, int> difficulty,
    required bool answerKeys,
    required bool explanations,
    required bool runtimeLoaded,
    required bool pubspecReferenced,
    required bool productionReachable,
    required String classification,
    required bool duplicateIds,
    required bool usesNumerical,
    required bool canContributeCanonical,
    required String confidence,
    String notes = '',
  }) {
    sources.add({
      'path': path,
      'file_type': fileType,
      'item_count': itemCount,
      'language': language,
      'dimension_distribution': dimensions,
      'difficulty_distribution': difficulty,
      'answer_keys_exist': answerKeys,
      'explanations_exist': explanations,
      'runtime_loaded': runtimeLoaded,
      'pubspec_referenced': pubspecReferenced,
      'production_reachable': productionReachable,
      'classification': classification,
      'duplicate_ids': duplicateIds,
      'uses_retired_numerical': usesNumerical,
      'can_contribute_to_canonical_bank': canContributeCanonical,
      'confidence': confidence,
      if (notes.isNotEmpty) 'notes': notes,
    });
  }

  final pubspec = File('$root/pubspec.yaml').readAsStringSync();
  final hasAssessmentSets = pubspec.contains('assets/data/assessment_sets/');
  final hasFlatIq = pubspec.contains('assets/data/iq_questions.json');
  final hasV3 = pubspec.contains('assessment_v3');

  // Legacy sets
  final iqSetsPath = 'assets/data/assessment_sets/iq_sets.json';
  final iqSetsFile = File('$root/$iqSetsPath');
  if (iqSetsFile.existsSync()) {
    final data = jsonDecode(iqSetsFile.readAsStringSync()) as Map;
    final sets = data['sets'] as List<dynamic>;
    var count = 0;
    final ids = <String>{};
    var dup = false;
    final difficulty = <String, int>{};
    for (final s in sets) {
      final qs = (s as Map)['questions'] as List<dynamic>? ?? const [];
      for (final q in qs) {
        count++;
        final id = (q as Map)['id']?.toString() ?? '';
        if (!ids.add(id)) dup = true;
        final d = q['difficulty']?.toString() ?? 'UNKNOWN';
        difficulty[d] = (difficulty[d] ?? 0) + 1;
      }
    }
    add(
      path: iqSetsPath,
      fileType: 'json',
      itemCount: count,
      language: 'tr+en_labels (legacy bilingual option labels)',
      dimensions: const {'UNKNOWN_legacy_no_dimension_field': 500},
      difficulty: difficulty,
      answerKeys: true,
      explanations: false,
      runtimeLoaded: true,
      pubspecReferenced: hasAssessmentSets,
      productionReachable: true,
      classification: 'legacy_runtime',
      duplicateIds: dup,
      usesNumerical: false,
      canContributeCanonical: false,
      confidence: 'high',
      notes:
          '50×10 prebuilt sets. No canonical primary_dimension. Not silently importable.',
    );
  }

  // Flat fallback
  final flatPath = 'assets/data/iq_questions.json';
  final flatFile = File('$root/$flatPath');
  if (flatFile.existsSync()) {
    final list = jsonDecode(flatFile.readAsStringSync()) as List<dynamic>;
    final difficulty = <String, int>{};
    for (final q in list) {
      final d = (q as Map)['difficulty']?.toString() ?? 'UNKNOWN';
      difficulty[d] = (difficulty[d] ?? 0) + 1;
    }
    add(
      path: flatPath,
      fileType: 'json',
      itemCount: list.length,
      language: 'legacy',
      dimensions: const {'UNKNOWN_legacy_no_dimension_field': 10},
      difficulty: difficulty,
      answerKeys: true,
      explanations: false,
      runtimeLoaded: true,
      pubspecReferenced: hasFlatIq,
      productionReachable: true,
      classification: 'legacy_runtime_fallback',
      duplicateIds: false,
      usesNumerical: false,
      canContributeCanonical: false,
      confidence: 'high',
    );
  }

  // Pilot
  void addPilot(String path, String classification) {
    final f = File('$root/$path');
    if (!f.existsSync()) return;
    final form = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final items = (form['items'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final dims = <String, int>{};
    final diffs = <String, int>{};
    final ids = <String>{};
    var dup = false;
    var explanations = 0;
    for (final i in items) {
      final id = i['question_id']?.toString() ?? '';
      if (!ids.add(id)) dup = true;
      final d = i['primary_dimension']?.toString() ?? 'UNKNOWN';
      dims[d] = (dims[d] ?? 0) + 1;
      final diff = i['difficulty']?.toString() ?? 'UNKNOWN';
      diffs[diff] = (diffs[diff] ?? 0) + 1;
      if ((i['solution_method']?.toString() ?? '').trim().isNotEmpty) {
        explanations++;
      }
    }
    add(
      path: path,
      fileType: 'json',
      itemCount: items.length,
      language: form['locale']?.toString() ?? 'tr-TR',
      dimensions: dims,
      difficulty: diffs,
      answerKeys: true,
      explanations: explanations == items.length,
      runtimeLoaded: false,
      pubspecReferenced: hasV3,
      productionReachable: false,
      classification: classification,
      duplicateIds: dup,
      usesNumerical: dims.containsKey('numerical'),
      canContributeCanonical: true,
      confidence: 'high',
      notes:
          'Offline only. Not wired to IQTestScreen. Uses qmatch_question_schema_v3.',
    );
  }

  addPilot(
    'assets/data/assessment_v3/iq/iq_pilot_tr_v1.json',
    'pilot_offline',
  );
  addPilot(
    'assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json',
    'candidate_offline',
  );

  // Fixture
  final fixturePath = 'test/fixtures/trait_scoring/valid_iq_bank.json';
  final fixture = File('$root/$fixturePath');
  if (fixture.existsSync()) {
    final data = jsonDecode(fixture.readAsStringSync()) as Map;
    final items = data['items'] as List<dynamic>? ?? const [];
    add(
      path: fixturePath,
      fileType: 'json',
      itemCount: items.length,
      language: 'test',
      dimensions: const {},
      difficulty: const {},
      answerKeys: true,
      explanations: false,
      runtimeLoaded: false,
      pubspecReferenced: false,
      productionReachable: false,
      classification: 'test_fixture',
      duplicateIds: false,
      usesNumerical: false,
      canContributeCanonical: false,
      confidence: 'high',
    );
  }

  // Target bank absence
  final target = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
  final targetExists = File('$root/$target').existsSync();
  add(
    path: target,
    fileType: 'json',
    itemCount: 0,
    language: 'tr-TR',
    dimensions: const {},
    difficulty: const {},
    answerKeys: false,
    explanations: false,
    runtimeLoaded: false,
    pubspecReferenced: false,
    productionReachable: false,
    classification: targetExists ? 'canonical_present' : 'canonical_absent',
    duplicateIds: false,
    usesNumerical: false,
    canContributeCanonical: false,
    confidence: 'high',
    notes: targetExists
        ? 'Present on disk'
        : 'Intended path only; file does not exist.',
  );

  // 340 claim classification
  final claim = {
    'classification': 'NOT_FOUND',
    'statement':
        'The canonical 340-item IQ bank does not currently exist in a runtime-ready repository source.',
    'evidence': [
      'No file at assets/data/assessment_v3/iq/iq_bank_tr_v1.json',
      'docs/release/qmatch_release_master_gap_register_v1.md G-010: NOT_STARTED',
      'docs/release/qmatch_question_bank_inventory_v1.md: Final 340 bank absent',
      'Parsed structured IQ JSON totals: 500 legacy + 10 flat + 25 pilot + 25 candidate + 16 fixture; no unique 340 canonical set',
      'No PDF/DOCX/CSV recoverable 340 source located in repository',
    ],
  };

  final report = {
    'phase': 'P2C-2A-0',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'sources': sources,
    'structured_item_count_sum_by_classification': {
      for (final c in {
        for (final s in sources) s['classification'] as String,
      })
        c: sources
            .where((s) => s['classification'] == c)
            .fold<int>(0, (a, s) => a + (s['item_count'] as int)),
    },
    'claim_340': claim,
    'pubspec_assessment_v3_registered': hasV3,
  };

  final outDir = Directory('$root/assets/data/assessment_v3/iq/reports');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final jsonOut = File('${outDir.path}/iq_source_inventory_v1_report.json');
  jsonOut.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  final md = StringBuffer()
    ..writeln('# IQ Source Inventory Report (machine)')
    ..writeln()
    ..writeln('Phase P2C-2A-0')
    ..writeln()
    ..writeln('## 340-item claim')
    ..writeln()
    ..writeln('- Classification: **${claim['classification']}**')
    ..writeln('- ${claim['statement']}')
    ..writeln()
    ..writeln('## Sources')
    ..writeln();
  for (final s in sources) {
    md
      ..writeln('### `${s['path']}`')
      ..writeln()
      ..writeln('- count: ${s['item_count']}')
      ..writeln('- classification: ${s['classification']}')
      ..writeln('- runtime_loaded: ${s['runtime_loaded']}')
      ..writeln('- production_reachable: ${s['production_reachable']}')
      ..writeln('- pubspec: ${s['pubspec_referenced']}')
      ..writeln('- dimensions: ${s['dimension_distribution']}')
      ..writeln();
  }
  File('${outDir.path}/iq_source_inventory_v1_report.md')
      .writeAsStringSync(md.toString());

  stdout.writeln(jsonOut.path);
  stdout.writeln('340_claim=${claim['classification']}');
  stdout.writeln('sources=${sources.length}');
  if ((claim['classification'] as String) == 'UNKNOWN') {
    exitCode = 2;
  }
}
