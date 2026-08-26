import 'dart:math' as math;

import 'relationship_analysis_state.dart';
import 'relationship_dimensions.dart';

enum RelationshipInsightFamily {
  closenessAutonomy,
  reassuranceTrust,
  commitmentPace,
  affectionPlayfulness,
}

enum RelationshipInsightBand {
  low,
  balanced,
  high,
}

enum RelationshipInsightConfidence {
  emerging,
  developing,
  established,
}

class RelationshipInsight {
  const RelationshipInsight({
    required this.family,
    required this.firstDimension,
    required this.secondDimension,
    required this.firstBand,
    required this.secondBand,
    required this.firstScore,
    required this.secondScore,
    required this.firstEvidence,
    required this.secondEvidence,
    required this.confidence,
    required this.rankScore,
  });

  final RelationshipInsightFamily family;

  final String firstDimension;
  final String secondDimension;

  final RelationshipInsightBand firstBand;
  final RelationshipInsightBand secondBand;

  final double firstScore;
  final double secondScore;

  final int firstEvidence;
  final int secondEvidence;

  final RelationshipInsightConfidence confidence;

  /// Internal deterministic ranking only.
  /// Never expose this as psychological confidence/accuracy.
  final double rankScore;
}

class RelationshipInsightEngine {
  const RelationshipInsightEngine();

  static const double lowThreshold = 0.42;
  static const double highThreshold = 0.58;

  static const List<_RelationshipInsightPair> _pairs = [
    _RelationshipInsightPair(
      family: RelationshipInsightFamily.closenessAutonomy,
      firstDimension: RelationshipDimensionIds.closenessNeed,
      secondDimension: RelationshipDimensionIds.autonomyNeed,
    ),
    _RelationshipInsightPair(
      family: RelationshipInsightFamily.reassuranceTrust,
      firstDimension: RelationshipDimensionIds.reassuranceNeed,
      secondDimension: RelationshipDimensionIds.trustOrientation,
    ),
    _RelationshipInsightPair(
      family: RelationshipInsightFamily.commitmentPace,
      firstDimension: RelationshipDimensionIds.commitmentOrientation,
      secondDimension: RelationshipDimensionIds.relationshipPace,
    ),
    _RelationshipInsightPair(
      family: RelationshipInsightFamily.affectionPlayfulness,
      firstDimension: RelationshipDimensionIds.affectionExpression,
      secondDimension: RelationshipDimensionIds.playfulness,
    ),
  ];

  List<RelationshipInsight> derive(RelationshipAnalysisState state) {
    final maxInsights = _maxInsightsFor(state.answeredCount);
    if (maxInsights == 0) return const [];

    final candidates = <RelationshipInsight>[];

    for (final pair in _pairs) {
      final firstEvidence =
          state.dimensionEvidenceCounts[pair.firstDimension] ?? 0;
      final secondEvidence =
          state.dimensionEvidenceCounts[pair.secondDimension] ?? 0;

      // Do not narrate a pair when one side has never produced actual
      // selected-answer evidence.
      if (firstEvidence < 1 || secondEvidence < 1) continue;
      if (firstEvidence + secondEvidence < 3) continue;

      final firstScore = state.dimensionScores[pair.firstDimension] ?? 0.5;
      final secondScore = state.dimensionScores[pair.secondDimension] ?? 0.5;

      final signalStrength =
          ((firstScore - 0.5).abs() + (secondScore - 0.5).abs())
              .clamp(0.0, 1.0);

      final evidenceStrength =
          ((firstEvidence + secondEvidence) / 6.0).clamp(0.0, 1.0);

      final rankScore = (0.75 * signalStrength) + (0.25 * evidenceStrength);

      candidates.add(
        RelationshipInsight(
          family: pair.family,
          firstDimension: pair.firstDimension,
          secondDimension: pair.secondDimension,
          firstBand: _bandFor(firstScore),
          secondBand: _bandFor(secondScore),
          firstScore: firstScore,
          secondScore: secondScore,
          firstEvidence: firstEvidence,
          secondEvidence: secondEvidence,
          confidence: _confidenceFor(
            firstEvidence,
            secondEvidence,
          ),
          rankScore: rankScore,
        ),
      );
    }

    candidates.sort((a, b) {
      final byRank = b.rankScore.compareTo(a.rankScore);
      if (byRank != 0) return byRank;

      // Deterministic tie-break.
      return a.family.index.compareTo(b.family.index);
    });

    return List.unmodifiable(
      candidates.take(math.min(maxInsights, candidates.length)),
    );
  }

  static RelationshipInsightBand _bandFor(double score) {
    if (score <= lowThreshold) return RelationshipInsightBand.low;
    if (score >= highThreshold) return RelationshipInsightBand.high;
    return RelationshipInsightBand.balanced;
  }

  static RelationshipInsightConfidence _confidenceFor(
    int firstEvidence,
    int secondEvidence,
  ) {
    final minimum = math.min(firstEvidence, secondEvidence);
    final total = firstEvidence + secondEvidence;

    if (minimum >= 3 && total >= 7) {
      return RelationshipInsightConfidence.established;
    }

    if (minimum >= 2 && total >= 5) {
      return RelationshipInsightConfidence.developing;
    }

    return RelationshipInsightConfidence.emerging;
  }

  static int _maxInsightsFor(int answeredCount) {
    if (answeredCount < 4) return 0;
    if (answeredCount < 8) return 1;
    if (answeredCount < 12) return 2;
    if (answeredCount < 16) return 3;
    return 4;
  }
}

class _RelationshipInsightPair {
  const _RelationshipInsightPair({
    required this.family,
    required this.firstDimension,
    required this.secondDimension,
  });

  final RelationshipInsightFamily family;
  final String firstDimension;
  final String secondDimension;
}
