import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_insight_copy.dart';
import 'package:qmatch/features/relationship_analysis/domain/relationship_insight_engine.dart';

void main() {
  const resolver = RelationshipInsightCopyResolver();

  RelationshipInsight buildInsight({
    required RelationshipInsightFamily family,
    required RelationshipInsightBand firstBand,
    required RelationshipInsightBand secondBand,
  }) {
    return RelationshipInsight(
      family: family,
      firstDimension: 'first',
      secondDimension: 'second',
      firstBand: firstBand,
      secondBand: secondBand,
      firstScore: 0.5,
      secondScore: 0.5,
      firstEvidence: 2,
      secondEvidence: 2,
      confidence: RelationshipInsightConfidence.emerging,
      rankScore: 0.5,
    );
  }

  test('all 36 family and band combinations resolve to copy', () {
    var resolvedCount = 0;

    for (final family in RelationshipInsightFamily.values) {
      for (final firstBand in RelationshipInsightBand.values) {
        for (final secondBand in RelationshipInsightBand.values) {
          final copy = resolver.resolve(
            buildInsight(
              family: family,
              firstBand: firstBand,
              secondBand: secondBand,
            ),
          );

          expect(copy.titleTr.trim(), isNotEmpty);
          expect(copy.bodyTr.trim(), isNotEmpty);
          expect(copy.titleEn.trim(), isNotEmpty);
          expect(copy.bodyEn.trim(), isNotEmpty);

          resolvedCount += 1;
        }
      }
    }

    expect(resolvedCount, 36);
  });

  test('every resolved title is concise and body is substantive', () {
    for (final family in RelationshipInsightFamily.values) {
      for (final firstBand in RelationshipInsightBand.values) {
        for (final secondBand in RelationshipInsightBand.values) {
          final copy = resolver.resolve(
            buildInsight(
              family: family,
              firstBand: firstBand,
              secondBand: secondBand,
            ),
          );

          expect(copy.titleTr.length, lessThan(90));
          expect(copy.titleEn.length, lessThan(90));

          expect(copy.bodyTr.length, greaterThan(35));
          expect(copy.bodyEn.length, greaterThan(35));
        }
      }
    }
  });

  test('copy does not expose internal dimension identifiers', () {
    const forbidden = [
      'closeness_need',
      'autonomy_need',
      'reassurance_need',
      'trust_orientation',
      'commitment_orientation',
      'relationship_pace',
      'affection_expression',
    ];

    for (final family in RelationshipInsightFamily.values) {
      for (final firstBand in RelationshipInsightBand.values) {
        for (final secondBand in RelationshipInsightBand.values) {
          final copy = resolver.resolve(
            buildInsight(
              family: family,
              firstBand: firstBand,
              secondBand: secondBand,
            ),
          );

          final text = [
            copy.titleTr,
            copy.bodyTr,
            copy.titleEn,
            copy.bodyEn,
          ].join(' ').toLowerCase();

          for (final term in forbidden) {
            expect(
              text,
              isNot(contains(term)),
              reason: 'Internal term "$term" leaked into user-facing copy.',
            );
          }
        }
      }
    }
  });

  test('copy avoids clinical attachment labels', () {
    const forbidden = [
      'anxious attachment',
      'avoidant attachment',
      'secure attachment',
      'kaygılı bağlanma',
      'kaçıngan bağlanma',
      'güvenli bağlanma',
    ];

    for (final family in RelationshipInsightFamily.values) {
      for (final firstBand in RelationshipInsightBand.values) {
        for (final secondBand in RelationshipInsightBand.values) {
          final copy = resolver.resolve(
            buildInsight(
              family: family,
              firstBand: firstBand,
              secondBand: secondBand,
            ),
          );

          final text = [
            copy.titleTr,
            copy.bodyTr,
            copy.titleEn,
            copy.bodyEn,
          ].join(' ').toLowerCase();

          for (final term in forbidden) {
            expect(text, isNot(contains(term)));
          }
        }
      }
    }
  });
}
