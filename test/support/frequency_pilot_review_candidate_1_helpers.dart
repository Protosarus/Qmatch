import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

/// Offline helpers for Frequency review candidate 1 (not production).
class FrequencyPilotReviewCandidate1Loader {
  FrequencyPilotReviewCandidate1Loader._();

  static const parentSha256 =
      '8b9e3b13f761707d32cee62dc4a3eef02e8983b1c76b71ae4976543457b041ab';
  static const candidatePath =
      'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json';
  static const parentPath =
      'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json';
  static const configPath = 'assets/data/trait_scoring_config_v1.json';

  static String get repoRoot => Directory.current.path;

  static Map<String, dynamic> loadForm() => Map<String, dynamic>.from(
        jsonDecode(File('$repoRoot/$candidatePath').readAsStringSync()) as Map,
      );

  static Map<String, dynamic> loadParent() => Map<String, dynamic>.from(
        jsonDecode(File('$repoRoot/$parentPath').readAsStringSync()) as Map,
      );

  static TraitScoringConfig loadConfig() => TraitScoringParser.parseConfigJson(
        File('$repoRoot/$configPath').readAsStringSync(),
      );

  static List<AssessmentItemDefinition> loadItems(TraitScoringConfig config) {
    final form = loadForm();
    return TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'frequency',
      source: 'frequency_pilot_tr_v1_review_candidate_1.json',
      config: config,
    );
  }

  static String parentSha256FromDisk() {
    final r = Process.runSync('shasum', ['-a', '256', '$repoRoot/$parentPath']);
    return r.stdout.toString().split(' ').first.trim();
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
    final validated = validateResponses(items: items, responses: responses);
    final pairRegistry = form['pair_registry'] as Map? ?? const {};
    return TraitScoringSessionInput(
      module: 'frequency',
      schemaVersion: config.questionSchemaVersion,
      contentVersion: form['content_version'] as String,
      traitScoringVersion: config.traitScoringVersion,
      locale: 'tr',
      setId: form['set_id'] as String,
      questionDefinitions: items,
      submittedResponses: validated,
      assessmentStatus: assessmentStatus,
      reversePairDescriptors: ReversePairDescriptor.parseRegistry(
        pairRegistry['reverse_pairs'],
      ),
    );
  }

  static AssessmentOptionDefinition pickMax(
    AssessmentItemDefinition item,
    String dimension,
  ) {
    var best = item.options.first;
    var bestVal = double.negativeInfinity;
    for (final o in item.options) {
      final v = o.dimensionDeltas[dimension] ?? 0.0;
      if (v > bestVal) {
        bestVal = v;
        best = o;
      }
    }
    return best;
  }

  static AssessmentOptionDefinition pickMin(
    AssessmentItemDefinition item,
    String dimension,
  ) {
    var best = item.options.first;
    var bestVal = double.infinity;
    for (final o in item.options) {
      final v = o.dimensionDeltas[dimension] ?? 0.0;
      if (v < bestVal) {
        bestVal = v;
        best = o;
      }
    }
    return best;
  }

  static AssessmentOptionDefinition pickModerate(
      AssessmentItemDefinition item) {
    final dim = item.primaryDimension;
    var best = item.options.first;
    var bestAbs = double.infinity;
    for (final o in item.options) {
      final v = (o.dimensionDeltas[dim] ?? 0.0).abs();
      if (v < bestAbs) {
        bestAbs = v;
        best = o;
      }
    }
    return best;
  }

  static AssessmentOptionDefinition pickPrimarySign(
    AssessmentItemDefinition item,
    int desiredSign,
  ) {
    AssessmentOptionDefinition? best;
    var bestMag = -1.0;
    for (final o in item.options) {
      final v = o.dimensionDeltas[item.primaryDimension] ?? 0.0;
      if (v == 0) continue;
      if (v.sign == desiredSign && v.abs() >= bestMag) {
        bestMag = v.abs();
        best = o;
      }
    }
    return best ?? pickModerate(item);
  }

  /// Behavioral reverse consistency: same primary-delta sign on both pair members.
  static List<AssessmentResponse> reverseBehavioralConsistent(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.reversePairId == null) return pickModerate(q);
        return pickPrimarySign(q, 1);
      });

  /// Behavioral reverse inconsistency: opposite primary sign on second member.
  static List<AssessmentResponse> reverseBehavioralInconsistent(
    List<AssessmentItemDefinition> items,
  ) {
    final seen = <String>{};
    return fromPicker(items, (q) {
      if (q.reversePairId == null) return pickModerate(q);
      if (seen.add(q.reversePairId!)) return pickPrimarySign(q, 1);
      return pickPrimarySign(q, -1);
    });
  }

  static List<AssessmentResponse> fromPicker(
    List<AssessmentItemDefinition> items,
    AssessmentOptionDefinition Function(AssessmentItemDefinition) pick, {
    int baseMs = 6000,
  }) =>
      [
        for (var i = 0; i < items.length; i++)
          AssessmentResponse(
            questionId: items[i].questionId,
            selectedOptionId: pick(items[i]).optionId,
            responseTimeMilliseconds: baseMs + (i * 137) % 4000,
          ),
      ];

  static List<AssessmentResponse> balancedMixed(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, pickModerate);

  static List<AssessmentResponse> highDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      fromPicker(
        items,
        (q) => q.primaryDimension == dimension
            ? pickMax(q, dimension)
            : pickModerate(q),
      );

  static List<AssessmentResponse> lowDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      fromPicker(
        items,
        (q) => q.primaryDimension == dimension
            ? pickMin(q, dimension)
            : pickModerate(q),
      );

  static List<AssessmentResponse> semanticConsistent(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.semanticPairId == null) return pickModerate(q);
        return pickPrimarySign(q, 1);
      });

  static List<AssessmentResponse> semanticInconsistent(
    List<AssessmentItemDefinition> items,
  ) {
    final seen = <String>{};
    return fromPicker(items, (q) {
      if (q.semanticPairId == null) return pickModerate(q);
      if (seen.add(q.semanticPairId!)) return pickPrimarySign(q, 1);
      return pickPrimarySign(q, -1);
    });
  }

  static List<AssessmentResponse> alwaysOption(
    List<AssessmentItemDefinition> items,
    String optionId,
  ) =>
      fromPicker(
        items,
        (q) => q.options.firstWhere((o) => o.optionId == optionId),
      );

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
          responseTimeMilliseconds: 5000 + rng.nextInt(7000),
        ),
    ];
  }

  static List<AssessmentResponse> omitPrimaryDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      [
        for (final q in items)
          if (q.primaryDimension != dimension)
            AssessmentResponse(
              questionId: q.questionId,
              selectedOptionId: pickModerate(q).optionId,
              responseTimeMilliseconds: 6500,
            ),
      ];

  static List<AssessmentResponse> sortResponses(
    List<AssessmentResponse> responses,
  ) =>
      [...responses]..sort((a, b) => a.questionId.compareTo(b.questionId));
}
