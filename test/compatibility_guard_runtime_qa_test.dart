import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';

/// Phase 3R-A3 runtime QA — pure compatibility + vector contract checks.
/// Does not touch Firestore or assessment JSON.
void main() {
  const dims = CompatibilityScoring.frequencyDimensionKeys;

  Map<String, double> vec({
    double depth = 0.5,
    double socialEnergy = 0.5,
    double spontaneity = 0.5,
    double stability = 0.5,
    double emotionalOpenness = 0.5,
    double conversationPace = 0.5,
  }) =>
      {
        'depth': depth,
        'socialEnergy': socialEnergy,
        'spontaneity': spontaneity,
        'stability': stability,
        'emotionalOpenness': emotionalOpenness,
        'conversationPace': conversationPace,
      };

  Map<String, dynamic> profile({
    String category = 'MM',
    int? iq = 50,
    int? eq = 50,
    Map<String, double>? frequencyVector,
    List<String> frequencyTags = const [],
    String? frequencyType,
    List<String> interests = const [],
    DateTime? lastActiveAt,
  }) {
    return {
      'category': category,
      'iq_normalized': iq,
      'eq_normalized': eq,
      if (frequencyVector != null) 'frequency_vector': frequencyVector,
      'frequency_tags': frequencyTags,
      if (frequencyType != null) 'frequency_type': frequencyType,
      'interests': interests,
      'last_active_at': lastActiveAt ?? DateTime.now(),
    };
  }

  /// Legacy A1 formula (for differentiation comparison only).
  double legacyScore({
    required double archetype,
    required double frequencyTypeTag,
    required double iqRawClose,
    required double eqRawClose,
    required double interests,
    required double recency,
  }) {
    return (archetype * 0.35) +
        (frequencyTypeTag * 0.20) +
        (iqRawClose * 0.15) +
        (eqRawClose * 0.15) +
        (interests * 0.10) +
        (recency * 0.05);
  }

  group('Frequency vector contract', () {
    test('expected 6 dimension keys and 0..1 range', () {
      expect(dims, [
        'depth',
        'socialEnergy',
        'spontaneity',
        'stability',
        'emotionalOpenness',
        'conversationPace',
      ]);
      final sample = vec(
        depth: 0.8,
        socialEnergy: 0.2,
        spontaneity: 0.3,
        stability: 0.9,
        emotionalOpenness: 0.7,
        conversationPace: 0.4,
      );
      expect(sample.keys.toSet(), dims.toSet());
      for (final v in sample.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('parseFrequencyVector reads frequency_vector and vector keys', () {
      final fromMirror = CompatibilityScoring.parseFrequencyVector({
        'frequency_vector': vec(depth: 0.75),
      });
      final fromAssessment = CompatibilityScoring.parseFrequencyVector({
        'vector': vec(depth: 0.75),
      });
      expect(fromMirror?['depth'], 0.75);
      expect(fromAssessment?['depth'], 0.75);
      expect(CompatibilityScoring.parseFrequencyVector({}), isNull);
    });
  });

  group('Missing-data fallbacks (no crash)', () {
    test('both vectors present', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(frequencyVector: vec(depth: 0.8, stability: 0.8)),
        candidate: profile(frequencyVector: vec(depth: 0.75, stability: 0.7)),
      );
      expect(r.scoreTotal, inInclusiveRange(0.0, 1.0));
      expect(r.breakdown['frequency_vector']!, greaterThan(0.8));
    });

    test('my vector present, candidate missing', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(frequencyVector: vec(depth: 0.8)),
        candidate: profile(), // no vector
      );
      expect(r.breakdown['frequency_vector'],
          CompatibilityScoring.missingSignalNeutral);
      expect(r.scoreTotal, isNonNegative);
    });

    test('legacy candidate: type/tags only, no vector', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(
          frequencyVector: vec(depth: 0.8, emotionalOpenness: 0.8),
          frequencyType: 'Deep Connector',
          frequencyTags: const ['deep_talker'],
        ),
        candidate: profile(
          frequencyType: 'Balanced Frequency',
          frequencyTags: const [],
        ),
      );
      expect(r.breakdown['frequency_vector'],
          CompatibilityScoring.missingSignalNeutral);
      expect(r.scoreTotal, inInclusiveRange(0.0, 1.0));
    });

    test('missing IQ/EQ', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(iq: null, eq: null, frequencyVector: vec()),
        candidate: profile(iq: null, eq: null, frequencyVector: vec()),
      );
      expect(r.breakdown['iq'], CompatibilityScoring.missingSignalNeutral);
      expect(r.breakdown['eq'], CompatibilityScoring.missingSignalNeutral);
    });

    test('empty tags and empty interests', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(frequencyTags: const [], interests: const []),
        candidate: profile(frequencyTags: const [], interests: const []),
      );
      expect(r.breakdown['frequency_type_tag'],
          CompatibilityScoring.missingSignalNeutral);
      expect(r.breakdown['interests'],
          CompatibilityScoring.missingSignalNeutral);
    });
  });

  group('Score differentiation vs archetype-heavy legacy', () {
    final deep = vec(
      depth: 0.9,
      socialEnergy: 0.2,
      spontaneity: 0.2,
      stability: 0.85,
      emotionalOpenness: 0.8,
      conversationPace: 0.3,
    );
    final social = vec(
      depth: 0.2,
      socialEnergy: 0.9,
      spontaneity: 0.85,
      stability: 0.3,
      emotionalOpenness: 0.4,
      conversationPace: 0.8,
    );

    test('same archetype + similar vs different Frequency vectors diverge', () {
      final similar = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'MM', frequencyVector: deep),
        candidate: profile(category: 'MM', frequencyVector: deep),
      );
      final different = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'MM', frequencyVector: deep),
        candidate: profile(category: 'MM', frequencyVector: social),
      );
      expect(similar.scoreTotal, greaterThan(different.scoreTotal + 0.08));

      // Legacy: same MM + empty tags + identical IQ/EQ → nearly identical
      // regardless of Frequency vector (vector unused).
      final legacySimilar = legacyScore(
        archetype: 0.85,
        frequencyTypeTag: 0.5,
        iqRawClose: 1.0,
        eqRawClose: 1.0,
        interests: 0.5,
        recency: 1.0,
      );
      final legacyDifferent = legacySimilar; // vector unused → same
      expect((legacySimilar - legacyDifferent).abs(), lessThan(0.001));
      expect(
        (similar.scoreTotal - different.scoreTotal).abs(),
        greaterThan((legacySimilar - legacyDifferent).abs() + 0.08),
      );
    });

    test('different archetype + similar Frequency still competitive', () {
      final sameArchDiffVec = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'MM', frequencyVector: deep),
        candidate: profile(category: 'MM', frequencyVector: social),
      );
      final diffArchSimilarVec = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'HH', frequencyVector: deep),
        candidate: profile(category: 'LL', frequencyVector: deep),
      );
      // Vector-first: similar Frequency can outrank same-archetype + dissimilar vector.
      expect(diffArchSimilarVec.scoreTotal,
          greaterThan(sameArchDiffVec.scoreTotal));
    });

    test('missing vector fallback is not a free high match', () {
      final missing = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'MM'),
        candidate: profile(category: 'MM'),
      );
      final withVec = CompatibilityScoring.calculateCompatibility(
        me: profile(category: 'MM', frequencyVector: deep),
        candidate: profile(category: 'MM', frequencyVector: deep),
      );
      expect(missing.breakdown['frequency_vector'],
          CompatibilityScoring.missingSignalNeutral);
      expect(withVec.scoreTotal, greaterThan(missing.scoreTotal));
    });
  });

  group('No fake percentile', () {
    test('compatibility output has no percentile fields', () {
      final r = CompatibilityScoring.calculateCompatibility(
        me: profile(frequencyVector: vec()),
        candidate: profile(frequencyVector: vec()),
      );
      expect(r.breakdown.containsKey('percentile'), isFalse);
      expect(r.label, isNot(contains('percentile')));
    });
  });
}
