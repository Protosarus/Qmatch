import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

/// Offline helpers for IQ pilot scoring fixtures (not production).
class IqPilotV1Loader {
  IqPilotV1Loader._();

  static String get repoRoot => Directory.current.path;

  static Map<String, dynamic> loadForm() {
    final text = File(
      '$repoRoot/assets/data/assessment_v3/iq/iq_pilot_tr_v1.json',
    ).readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static TraitScoringConfig loadConfig() {
    return TraitScoringParser.parseConfigJson(
      File('$repoRoot/assets/data/trait_scoring_config_v1.json')
          .readAsStringSync(),
    );
  }

  static List<AssessmentItemDefinition> loadItems(TraitScoringConfig config) {
    final form = loadForm();
    return TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'iq',
      source: 'iq_pilot_tr_v1.json',
      config: config,
    );
  }

  /// Rejects duplicate question IDs and unknown IDs explicitly.
  static List<AssessmentResponse> validateResponses({
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
  }) {
    final known = {for (final q in items) q.questionId};
    final seen = <String>{};
    final errors = <TraitValidationError>[];
    for (final r in responses) {
      if (!known.contains(r.questionId)) {
        errors.add(TraitValidationError(
          questionId: r.questionId,
          fieldPath: 'question_id',
          reasonCode: 'unknown_question_id',
          explanation: 'Response references unknown question',
        ));
      }
      if (!seen.add(r.questionId)) {
        errors.add(TraitValidationError(
          questionId: r.questionId,
          fieldPath: 'question_id',
          reasonCode: 'duplicate_response',
          explanation: 'Duplicate response for question',
        ));
      }
    }
    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Invalid responses', errors);
    }
    return responses;
  }

  static TraitScoringSessionInput session({
    required TraitScoringConfig config,
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
    String assessmentStatus = 'complete',
  }) {
    final form = loadForm();
    final validated = validateResponses(items: items, responses: responses);
    return TraitScoringSessionInput(
      module: 'iq',
      schemaVersion: config.questionSchemaVersion,
      contentVersion: form['content_version'] as String,
      traitScoringVersion: config.traitScoringVersion,
      locale: 'tr',
      setId: form['set_id'] as String,
      questionDefinitions: items,
      submittedResponses: validated,
      assessmentStatus: assessmentStatus,
    );
  }

  static List<AssessmentResponse> allCorrect(
    List<AssessmentItemDefinition> items,
  ) =>
      [
        for (final q in items)
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: q.correctOptionId,
            responseTimeMilliseconds: 7000 + q.questionId.hashCode % 2000,
          ),
      ];

  static List<AssessmentResponse> allIncorrect(
    List<AssessmentItemDefinition> items,
  ) =>
      [
        for (final q in items)
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: q.options
                .firstWhere((o) => o.optionId != q.correctOptionId)
                .optionId,
            responseTimeMilliseconds: 6000,
          ),
      ];

  static List<AssessmentResponse> oneCorrectPerDomain(
    List<AssessmentItemDefinition> items,
  ) {
    final byDom = <String, AssessmentItemDefinition>{};
    for (final q in items) {
      byDom.putIfAbsent(q.primaryDimension, () => q);
    }
    return [
      for (final q in items)
        AssessmentResponse(
          questionId: q.questionId,
          selectedOptionId: identical(byDom[q.primaryDimension], q)
              ? q.correctOptionId
              : q.options
                  .firstWhere((o) => o.optionId != q.correctOptionId)
                  .optionId,
          responseTimeMilliseconds: 6500,
        ),
    ];
  }

  static List<AssessmentResponse> omitDomain(
    List<AssessmentItemDefinition> items,
    String domain,
  ) =>
      [
        for (final q in items)
          if (q.primaryDimension != domain)
            AssessmentResponse(
              questionId: q.questionId,
              selectedOptionId: q.correctOptionId,
              responseTimeMilliseconds: 7000,
            ),
      ];

  static List<AssessmentResponse> alternating(
    List<AssessmentItemDefinition> items,
  ) =>
      [
        for (var i = 0; i < items.length; i++)
          AssessmentResponse(
            questionId: items[i].questionId,
            selectedOptionId: i.isEven
                ? items[i].correctOptionId
                : items[i]
                    .options
                    .firstWhere((o) => o.optionId != items[i].correctOptionId)
                    .optionId,
            responseTimeMilliseconds: 5500 + i * 100,
          ),
      ];

  static List<AssessmentResponse> randomSeeded(
    List<AssessmentItemDefinition> items, {
    int seed = 42,
  }) {
    final rng = Random(seed);
    return [
      for (final q in items)
        AssessmentResponse(
          questionId: q.questionId,
          selectedOptionId: q.options[rng.nextInt(q.options.length)].optionId,
          responseTimeMilliseconds: 4000 + rng.nextInt(8000),
        ),
    ];
  }

  static List<AssessmentResponse> alwaysOptionA(
    List<AssessmentItemDefinition> items,
  ) =>
      [
        for (final q in items)
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: 'A',
            responseTimeMilliseconds: 5000,
          ),
      ];
}
