import 'dart:math' as math;

import 'relationship_bank_models.dart';
import 'relationship_dimensions.dart';

class RelationshipScoreSnapshot {
  const RelationshipScoreSnapshot({
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.dimensionRawSignedEvidence,
    required this.answeredQuestionIds,
    required this.analysisDepth,
  });

  final Map<String, double> dimensionScores;
  final Map<String, int> dimensionEvidenceCounts;
  final Map<String, double> dimensionRawSignedEvidence;
  final List<String> answeredQuestionIds;
  final double analysisDepth;
}

class RelationshipAnalysisScorer {
  const RelationshipAnalysisScorer();

  RelationshipScoreSnapshot score({
    required RelationshipAnalysisBank bank,
    required Map<String, String> answersByQuestionId,
  }) {
    final raw = {for (final d in RelationshipDimensionIds.all) d: 0.0};
    final evidence = {for (final d in RelationshipDimensionIds.all) d: 0};

    final answered = <String>[];
    final byId = bank.byId;
    final ids = answersByQuestionId.keys.toList()..sort();

    for (final qid in ids) {
      final optionId = answersByQuestionId[qid];
      if (optionId == null || optionId.isEmpty) continue;
      final question = byId[qid];
      if (question == null) continue;
      RelationshipAnswerOption? option;
      for (final o in question.options) {
        if (o.id == optionId) {
          option = o;
          break;
        }
      }
      if (option == null) continue;

      answered.add(qid);
      for (final e in option.dimensionDeltas.entries) {
        if (!RelationshipDimensionIds.allSet.contains(e.key)) continue;
        if (e.value == 0) continue;
        raw[e.key] = raw[e.key]! + e.value;
        evidence[e.key] = evidence[e.key]! + 1;
      }
    }

    final scores = <String, double>{};
    for (final d in RelationshipDimensionIds.all) {
      final scaled = RelationshipAnalysisContract.scoreBaseline +
          (raw[d]! / RelationshipAnalysisContract.scoreScale);
      scores[d] = _clip01(scaled);
    }

    final depth = computeAnalysisDepth(
      bank: bank,
      answersByQuestionId: answersByQuestionId,
    );

    return RelationshipScoreSnapshot(
      dimensionScores: Map.unmodifiable(scores),
      dimensionEvidenceCounts: Map.unmodifiable(evidence),
      dimensionRawSignedEvidence: Map.unmodifiable(raw),
      answeredQuestionIds: List.unmodifiable(answered),
      analysisDepth: depth,
    );
  }

  /// Monotonic user-facing depth from answered question *capability*, not
  /// selected-option deltas. Changing an answer cannot change depth.
  static double computeAnalysisDepth({
    required RelationshipAnalysisBank bank,
    required Map<String, String> answersByQuestionId,
  }) {
    final totalQuestions = bank.items.length;
    if (totalQuestions <= 0) return 0.0;

    final byId = bank.byId;
    final exposure = {for (final d in RelationshipDimensionIds.all) d: 0};
    final contexts = {
      for (final d in RelationshipDimensionIds.all) d: <String>{},
    };

    var answeredCount = 0;
    final ids = answersByQuestionId.keys.toList()..sort();
    for (final qid in ids) {
      final optionId = answersByQuestionId[qid];
      if (optionId == null || optionId.isEmpty) continue;
      final question = byId[qid];
      if (question == null) continue;
      if (!question.options.any((o) => o.id == optionId)) continue;

      answeredCount += 1;
      final capable = questionCapabilityDimensions(question);
      for (final d in capable) {
        exposure[d] = exposure[d]! + 1;
        if (question.context.isNotEmpty) {
          contexts[d]!.add(question.context);
        }
      }
    }

    final answerShare =
        (answeredCount / totalQuestions).clamp(0.0, 1.0).toDouble();

    var covered = 0;
    for (final d in RelationshipDimensionIds.all) {
      final e = exposure[d] ?? 0;
      final c = contexts[d]!.length;
      if (e >= 2 || (e >= 1 && c >= 2)) covered += 1;
    }
    final dimShare =
        (covered / RelationshipDimensionIds.all.length).clamp(0.0, 1.0);

    return _clip01(0.55 * answerShare + 0.45 * dimShare);
  }

  /// Dimensions a question can measure = union of non-zero option delta keys.
  static Set<String> questionCapabilityDimensions(
      RelationshipQuestion question) {
    final dims = <String>{};
    for (final o in question.options) {
      for (final e in o.dimensionDeltas.entries) {
        if (!RelationshipDimensionIds.allSet.contains(e.key)) continue;
        if (e.value == 0) continue;
        dims.add(e.key);
      }
    }
    return dims;
  }

  static double _clip01(double x) {
    if (!x.isFinite) return RelationshipAnalysisContract.scoreBaseline;
    return math.max(0.0, math.min(1.0, x));
  }
}
