import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

class TraitScoringFixtureLoader {
  TraitScoringFixtureLoader._();

  static String get repoRoot => Directory.current.path;

  static TraitScoringConfig loadConfig() {
    final text = File('$repoRoot/assets/data/trait_scoring_config_v1.json')
        .readAsStringSync();
    return TraitScoringParser.parseConfigJson(text);
  }

  static Map<String, dynamic> loadBankJson(String name) {
    final text =
        File('$repoRoot/test/fixtures/trait_scoring/$name').readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static List<AssessmentItemDefinition> loadBank(
    String name, {
    required String module,
    required TraitScoringConfig config,
  }) {
    final j = loadBankJson(name);
    return TraitScoringParser.parseItemBank(
      j['items'] as List<dynamic>,
      expectedModule: module,
      source: name,
      config: config,
    );
  }

  static List<ReversePairDescriptor> loadReversePairDescriptors(String name) {
    final j = loadBankJson(name);
    final registry = j['pair_registry'] as Map? ?? const {};
    return ReversePairDescriptor.parseRegistry(registry['reverse_pairs']);
  }

  static List<AssessmentResponse> loadResponses(String name) {
    final text =
        File('$repoRoot/test/fixtures/trait_scoring/$name').readAsStringSync();
    final j = jsonDecode(text) as Map<String, dynamic>;
    return [
      for (final r in j['responses'] as List)
        AssessmentResponse(
          questionId: (r as Map)['question_id'] as String,
          selectedOptionId: r['selected_option_id'] as String?,
          responseTimeMilliseconds:
              (r['response_time_milliseconds'] as num?)?.toInt(),
        ),
    ];
  }

  static TraitScoringSessionInput session({
    required String module,
    required TraitScoringConfig config,
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
    String contentVersion = 'fixture_v1',
    String setId = 'fixture_set',
    List<ReversePairDescriptor> reversePairDescriptors = const [],
  }) {
    return TraitScoringSessionInput(
      module: module,
      schemaVersion: config.questionSchemaVersion,
      contentVersion: contentVersion,
      traitScoringVersion: config.traitScoringVersion,
      locale: 'tr',
      setId: setId,
      questionDefinitions: items,
      submittedResponses: responses,
      assessmentStatus: 'complete',
      startedAt: DateTime.utc(2026, 1, 1, 12),
      completedAt: DateTime.utc(2026, 1, 1, 13),
      reversePairDescriptors: reversePairDescriptors,
    );
  }
}
