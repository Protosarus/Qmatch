import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

class IqPilotReviewCandidate1Helpers {
  IqPilotReviewCandidate1Helpers._();

  static String get root => Directory.current.path;

  static Map<String, dynamic> loadForm() => Map<String, dynamic>.from(
        jsonDecode(
          File(
            '$root/assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json',
          ).readAsStringSync(),
        ) as Map,
      );

  static TraitScoringConfig loadConfig() => TraitScoringParser.parseConfigJson(
        File('$root/assets/data/trait_scoring_config_v1.json')
            .readAsStringSync(),
      );

  static List<AssessmentItemDefinition> loadItems(TraitScoringConfig config) {
    final form = loadForm();
    return TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'iq',
      source: 'review_candidate_1',
      config: config,
    );
  }

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
          explanation: 'unknown',
        ));
      }
      if (!seen.add(r.questionId)) {
        errors.add(TraitValidationError(
          questionId: r.questionId,
          fieldPath: 'question_id',
          reasonCode: 'duplicate_response',
          explanation: 'duplicate',
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
    return TraitScoringSessionInput(
      module: 'iq',
      schemaVersion: config.questionSchemaVersion,
      contentVersion: form['content_version'] as String,
      traitScoringVersion: config.traitScoringVersion,
      locale: 'tr',
      setId: form['set_id'] as String,
      questionDefinitions: items,
      submittedResponses: validateResponses(items: items, responses: responses),
      assessmentStatus: assessmentStatus,
    );
  }

  static List<AssessmentResponse> allCorrect(
          List<AssessmentItemDefinition> items) =>
      [
        for (final q in items)
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: q.correctOptionId,
            responseTimeMilliseconds: 7000,
          ),
      ];

  static List<AssessmentResponse> allIncorrect(
          List<AssessmentItemDefinition> items) =>
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

  static List<AssessmentResponse> alwaysLetter(
    List<AssessmentItemDefinition> items,
    String letter,
  ) =>
      [
        for (final q in items)
          AssessmentResponse(
            questionId: q.questionId,
            selectedOptionId: letter,
            responseTimeMilliseconds: 5000,
          ),
      ];

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
              responseTimeMilliseconds: 5500,
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
          selectedOptionId: q.options[rng.nextInt(4)].optionId,
          responseTimeMilliseconds: 4000 + rng.nextInt(5000),
        ),
    ];
  }

  static List<AssessmentResponse> alternating(
    List<AssessmentItemDefinition> items,
  ) {
    const letters = ['A', 'B', 'C', 'D'];
    return [
      for (var i = 0; i < items.length; i++)
        AssessmentResponse(
          questionId: items[i].questionId,
          selectedOptionId: letters[i % 4],
          responseTimeMilliseconds: 4500,
        ),
    ];
  }

  static List<AssessmentResponse> oneCorrectPerDomain(
    List<AssessmentItemDefinition> items,
  ) {
    final seen = <String>{};
    return [
      for (final q in items)
        AssessmentResponse(
          questionId: q.questionId,
          selectedOptionId: seen.add(q.primaryDimension)
              ? q.correctOptionId
              : q.options
                  .firstWhere((o) => o.optionId != q.correctOptionId)
                  .optionId,
          responseTimeMilliseconds: 5200,
        ),
    ];
  }
}
