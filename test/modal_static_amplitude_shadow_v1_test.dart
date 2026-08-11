import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/modal_static_amplitude_shadow.dart';

void main() {
  const matcher = ModalStaticAmplitudeShadowMatcher();
  final freq = ModalStaticAmplitudeShadowContract.frequencyDimensionIds;

  Canonical20dShadowSubject subject(Map<String, double> scores) {
    return Canonical20dShadowSubject(
      measuredScores: scores,
      evidenceCounts: const {},
    );
  }

  Map<String, double> fill(double v) => {for (final id in freq) id: v};

  Map<String, double> values(List<double> xs) {
    assert(xs.length == freq.length);
    return {for (var i = 0; i < freq.length; i++) freq[i]: xs[i]};
  }

  group('ModalStaticAmplitudeShadowMatcher', () {
    test('identical profiles → shape 1, level 0, full coverage', () {
      final a = subject(fill(0.42));
      final b = subject(fill(0.42));
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.shapeAvailable, isTrue);
      expect(r.levelAvailable, isTrue);
      expect(r.rModalShape, closeTo(1.0, 1e-12));
      expect(r.dModalLevel, 0.0);
      expect(r.sharedModeCount, 6);
      expect(r.modalCoverage, 1.0);
      expect(r.shapeUnavailableReason, isNull);
      expect(r.staticAmplitudeOnly, isTrue);
      expect(r.phaseEnabled, isFalse);
      expect(r.omegaEnabled, isFalse);
      expect(r.shadowOnly, isTrue);
      expect(
        r.scoringVersion,
        ModalStaticAmplitudeShadowContract.scoringVersion,
      );
      expect(
        r.policyStatus,
        'shadow_only_static_amplitude_not_live',
      );
    });

    test('0.1 vs 0.9 flat → shape 1 (level-blind) but large level distance', () {
      final a = subject(fill(0.1));
      final b = subject(fill(0.9));
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.shapeAvailable, isTrue);
      expect(r.rModalShape, closeTo(1.0, 1e-12));
      expect(r.dModalLevel, closeTo(0.8, 1e-12));
      expect(r.levelAvailable, isTrue);
    });

    test('same-shape different magnitude → shape ≈1, positive level distance',
        () {
      final base = [0.10, 0.20, 0.15, 0.25, 0.12, 0.18];
      final scaled = [for (final x in base) math.min(1.0, x * 4.0)];
      final r = matcher.compareMeasuredPresence(
        a: subject(values(base)),
        b: subject(values(scaled)),
      );

      expect(r.shapeAvailable, isTrue);
      expect(r.rModalShape, closeTo(1.0, 1e-9));
      expect(r.dModalLevel!, greaterThan(0.4));
    });

    test('opposite-shaped profiles → low shape, high level distance', () {
      final r = matcher.compareMeasuredPresence(
        a: subject(values([0.1, 0.9, 0.1, 0.9, 0.1, 0.9])),
        b: subject(values([0.9, 0.1, 0.9, 0.1, 0.9, 0.1])),
      );

      expect(r.shapeAvailable, isTrue);
      expect(r.rModalShape!, lessThan(0.25));
      expect(r.dModalLevel, closeTo(0.8, 1e-12));
    });

    test('partial modes: 1 shared → shape unavailable, level still reported',
        () {
      final a = subject({freq[0]: 0.1, freq[1]: 0.5});
      final b = subject({freq[0]: 0.9, freq[2]: 0.5});
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.sharedModeCount, 1);
      expect(r.modalCoverage, closeTo(1 / 6, 1e-12));
      expect(r.shapeAvailable, isFalse);
      expect(r.rModalShape, isNull);
      expect(
        r.shapeUnavailableReason,
        ModalStaticAmplitudeShadowMatcher.reasonInsufficientSharedModes,
      );
      expect(r.levelAvailable, isTrue);
      expect(r.dModalLevel, closeTo(0.8, 1e-12));
    });

    test('partial modes: 3 shared opposite → shape + level both available', () {
      final a = subject({
        freq[0]: 0.1,
        freq[1]: 0.9,
        freq[2]: 0.1,
      });
      final b = subject({
        freq[0]: 0.9,
        freq[1]: 0.1,
        freq[2]: 0.9,
      });
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.sharedModeCount, 3);
      expect(r.shapeAvailable, isTrue);
      expect(r.levelAvailable, isTrue);
      expect(r.rModalShape!, lessThan(0.25));
      expect(r.dModalLevel, closeTo(0.8, 1e-12));
    });

    test('zero-norm amplitude vector → shape unavailable; level may remain', () {
      final a = subject(fill(0.0));
      final b = subject(fill(0.5));
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.sharedModeCount, 6);
      expect(r.shapeAvailable, isFalse);
      expect(r.rModalShape, isNull);
      expect(
        r.shapeUnavailableReason,
        ModalStaticAmplitudeShadowMatcher.reasonZeroNorm,
      );
      expect(r.levelAvailable, isTrue);
      expect(r.dModalLevel, closeTo(0.5, 1e-12));
    });

    test('symmetry A↔B', () {
      final a = subject(values([0.12, 0.44, 0.71, 0.33, 0.08, 0.91]));
      final b = subject(values([0.55, 0.21, 0.67, 0.40, 0.88, 0.15]));
      final ab = matcher.compareMeasuredPresence(a: a, b: b);
      final ba = matcher.compareMeasuredPresence(a: b, b: a);

      expect(ab.rModalShape, ba.rModalShape);
      expect(ab.dModalLevel, ba.dModalLevel);
      expect(ab.sharedModeCount, ba.sharedModeCount);
      expect(ab.modalCoverage, ba.modalCoverage);
      expect(ab.shapeAvailable, ba.shapeAvailable);
      expect(ab.levelAvailable, ba.levelAvailable);
    });

    test('no shared modes → both unavailable', () {
      final a = subject({freq[0]: 0.2, freq[1]: 0.3});
      final b = subject({freq[2]: 0.4, freq[3]: 0.5});
      final r = matcher.compareMeasuredPresence(a: a, b: b);

      expect(r.shapeAvailable, isFalse);
      expect(r.levelAvailable, isFalse);
      expect(r.rModalShape, isNull);
      expect(r.dModalLevel, isNull);
      expect(
        r.shapeUnavailableReason,
        ModalStaticAmplitudeShadowMatcher.reasonNoSharedModes,
      );
      expect(r.sharedModeCount, 0);
      expect(r.modalCoverage, 0.0);
    });
  });

  group('isolation', () {
    test('no Discover / Persona coupling; static amplitude flags frozen', () {
      final src = File(
        'lib/features/matching/domain/'
        'modal_static_amplitude_shadow_matcher.dart',
      ).readAsStringSync();
      expect(src.contains('DiscoverService'), isFalse);
      expect(src.contains('persona_scoring'), isFalse);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('exp('), isFalse);

      expect(ModalStaticAmplitudeShadowContract.phaseEnabled, isFalse);
      expect(ModalStaticAmplitudeShadowContract.omegaEnabled, isFalse);
      expect(ModalStaticAmplitudeShadowContract.staticAmplitudeOnly, isTrue);
      expect(
        ModalStaticAmplitudeShadowContract.liveDiscoverRanking,
        isFalse,
      );

      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(discover.contains('modal_static_amplitude'), isFalse);
      expect(discover.contains('ModalStaticAmplitude'), isFalse);
    });
  });
}
