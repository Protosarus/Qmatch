import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_analysis_state.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_dimensions.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_insight_engine.dart';

RelationshipAnalysisState buildState({
  required int answeredCount,
  Map<String, double> scores = const {},
  Map<String, int> evidence = const {},
}) {
  return RelationshipAnalysisState.empty().copyWith(
    answersByQuestionId: {
      for (var i = 0; i < answeredCount; i++) 'q_$i': 'a',
    },
    dimensionScores: {
      for (final d in RelationshipDimensionIds.all) d: scores[d] ?? 0.5,
    },
    dimensionEvidenceCounts: {
      for (final d in RelationshipDimensionIds.all) d: evidence[d] ?? 0,
    },
  );
}

void main() {
  const engine = RelationshipInsightEngine();

  test('fewer than 4 answered questions produce no insights', () {
    final state = buildState(
      answeredCount: 3,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.75,
        RelationshipDimensionIds.autonomyNeed: 0.70,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 2,
        RelationshipDimensionIds.autonomyNeed: 2,
      },
    );

    expect(engine.derive(state), isEmpty);
  });

  test('pair requires evidence on both dimensions and at least 3 total', () {
    final insufficient = buildState(
      answeredCount: 4,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.75,
        RelationshipDimensionIds.autonomyNeed: 0.70,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 1,
        RelationshipDimensionIds.autonomyNeed: 1,
      },
    );

    expect(engine.derive(insufficient), isEmpty);

    final sufficient = buildState(
      answeredCount: 4,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.75,
        RelationshipDimensionIds.autonomyNeed: 0.70,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 2,
        RelationshipDimensionIds.autonomyNeed: 1,
      },
    );

    expect(engine.derive(sufficient), hasLength(1));
  });

  test('score bands use low 0.42 and high 0.58 thresholds', () {
    final state = buildState(
      answeredCount: 4,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.42,
        RelationshipDimensionIds.autonomyNeed: 0.58,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 2,
        RelationshipDimensionIds.autonomyNeed: 2,
      },
    );

    final insight = engine.derive(state).single;

    expect(insight.firstBand, RelationshipInsightBand.low);
    expect(insight.secondBand, RelationshipInsightBand.high);
  });

  test('scores inside middle band are balanced', () {
    final state = buildState(
      answeredCount: 4,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.50,
        RelationshipDimensionIds.autonomyNeed: 0.55,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 2,
        RelationshipDimensionIds.autonomyNeed: 2,
      },
    );

    final insight = engine.derive(state).single;

    expect(insight.firstBand, RelationshipInsightBand.balanced);
    expect(insight.secondBand, RelationshipInsightBand.balanced);
  });

  test('4 answered questions expose at most 1 insight', () {
    final state = buildState(
      answeredCount: 4,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.80,
        RelationshipDimensionIds.autonomyNeed: 0.75,
        RelationshipDimensionIds.reassuranceNeed: 0.20,
        RelationshipDimensionIds.trustOrientation: 0.25,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 2,
        RelationshipDimensionIds.autonomyNeed: 2,
        RelationshipDimensionIds.reassuranceNeed: 2,
        RelationshipDimensionIds.trustOrientation: 2,
      },
    );

    expect(engine.derive(state), hasLength(1));
  });

  test('progressive insight caps are 1, 2, 3, 4', () {
    final scores = {
      RelationshipDimensionIds.closenessNeed: 0.80,
      RelationshipDimensionIds.autonomyNeed: 0.75,
      RelationshipDimensionIds.reassuranceNeed: 0.20,
      RelationshipDimensionIds.trustOrientation: 0.25,
      RelationshipDimensionIds.commitmentOrientation: 0.78,
      RelationshipDimensionIds.relationshipPace: 0.30,
      RelationshipDimensionIds.affectionExpression: 0.74,
      RelationshipDimensionIds.playfulness: 0.28,
    };

    final evidence = {
      for (final d in RelationshipDimensionIds.all) d: 3,
    };

    expect(
      engine.derive(
        buildState(
          answeredCount: 4,
          scores: scores,
          evidence: evidence,
        ),
      ),
      hasLength(1),
    );

    expect(
      engine.derive(
        buildState(
          answeredCount: 8,
          scores: scores,
          evidence: evidence,
        ),
      ),
      hasLength(2),
    );

    expect(
      engine.derive(
        buildState(
          answeredCount: 12,
          scores: scores,
          evidence: evidence,
        ),
      ),
      hasLength(3),
    );

    expect(
      engine.derive(
        buildState(
          answeredCount: 16,
          scores: scores,
          evidence: evidence,
        ),
      ),
      hasLength(4),
    );
  });

  test('stronger supported pattern ranks before weaker pattern', () {
    final state = buildState(
      answeredCount: 8,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.90,
        RelationshipDimensionIds.autonomyNeed: 0.85,
        RelationshipDimensionIds.reassuranceNeed: 0.56,
        RelationshipDimensionIds.trustOrientation: 0.54,
      },
      evidence: {
        RelationshipDimensionIds.closenessNeed: 3,
        RelationshipDimensionIds.autonomyNeed: 3,
        RelationshipDimensionIds.reassuranceNeed: 2,
        RelationshipDimensionIds.trustOrientation: 2,
      },
    );

    final insights = engine.derive(state);

    expect(insights, hasLength(2));
    expect(
      insights.first.family,
      RelationshipInsightFamily.closenessAutonomy,
    );
    expect(
      insights.first.rankScore,
      greaterThan(insights.last.rankScore),
    );
  });

  test('confidence progresses from emerging to developing to established', () {
    RelationshipInsight one({
      required int first,
      required int second,
    }) {
      final state = buildState(
        answeredCount: 4,
        scores: {
          RelationshipDimensionIds.closenessNeed: 0.75,
          RelationshipDimensionIds.autonomyNeed: 0.70,
        },
        evidence: {
          RelationshipDimensionIds.closenessNeed: first,
          RelationshipDimensionIds.autonomyNeed: second,
        },
      );

      return engine.derive(state).single;
    }

    expect(
      one(first: 2, second: 1).confidence,
      RelationshipInsightConfidence.emerging,
    );

    expect(
      one(first: 3, second: 2).confidence,
      RelationshipInsightConfidence.developing,
    );

    expect(
      one(first: 4, second: 3).confidence,
      RelationshipInsightConfidence.established,
    );
  });

  test('same state always produces identical deterministic ordering', () {
    final state = buildState(
      answeredCount: 16,
      scores: {
        RelationshipDimensionIds.closenessNeed: 0.70,
        RelationshipDimensionIds.autonomyNeed: 0.70,
        RelationshipDimensionIds.reassuranceNeed: 0.70,
        RelationshipDimensionIds.trustOrientation: 0.70,
        RelationshipDimensionIds.commitmentOrientation: 0.70,
        RelationshipDimensionIds.relationshipPace: 0.70,
        RelationshipDimensionIds.affectionExpression: 0.70,
        RelationshipDimensionIds.playfulness: 0.70,
      },
      evidence: {
        for (final d in RelationshipDimensionIds.all) d: 3,
      },
    );

    final first = engine.derive(state);
    final second = engine.derive(state);

    expect(
      first.map((e) => e.family).toList(),
      second.map((e) => e.family).toList(),
    );
  });
}
