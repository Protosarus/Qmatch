import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow.dart';

void main() {
  const matcher = WaveStateModalShadowMatcher();
  final ids = WaveStateModalShadowContract.frequencyDimensionIds;

  Map<String, double> fill(double v) => {for (final id in ids) id: v};

  Map<String, double> values(List<double> xs) {
    expect(xs.length, ids.length);
    return {for (var i = 0; i < ids.length; i++) ids[i]: xs[i]};
  }

  WaveStateModalSubject subject({
    Map<String, double>? amplitudes,
    Map<String, double>? phases,
    Map<String, double>? omegas,
  }) {
    return WaveStateModalSubject.fromMaps(
      amplitudes: amplitudes,
      phasesRadians: phases,
      omegas: omegas,
    );
  }

  group('WaveStateModalShadowMatcher', () {
    test('identical states → r_wave = 1', () {
      final a = subject(
        amplitudes: fill(0.4),
        phases: fill(0.3),
        omegas: fill(1.2),
      );
      final b = subject(
        amplitudes: fill(0.4),
        phases: fill(0.3),
        omegas: fill(1.2),
      );
      final r = matcher.compare(a: a, b: b, t: 2.5);
      expect(r.resonanceAvailable, isTrue);
      expect(r.rWave, closeTo(1.0, 1e-12));
      expect(r.overlapImag, closeTo(0.0, 1e-12));
      expect(r.scoringVersion, 'wave_state_modal_shadow_v1');
      expect(r.policyStatus, 'shadow_only_not_live');
      expect(r.structuralDistanceCoupled, isFalse);
      expect(r.shadowOnly, isTrue);
    });

    test('same amplitudes / same phase → r_wave = 1 at any t when omega equal',
        () {
      final amps = values([0.1, 0.2, 0.3, 0.4, 0.5, 0.6]);
      final phases = fill(0.7);
      final omegas = fill(0.9);
      final a = subject(amplitudes: amps, phases: phases, omegas: omegas);
      final b = subject(amplitudes: amps, phases: phases, omegas: omegas);
      for (final t in [0.0, 1.0, 10.0]) {
        final r = matcher.compare(a: a, b: b, t: t);
        expect(r.rWave, closeTo(1.0, 1e-12), reason: 't=$t');
      }
    });

    test('phase opposition → r_wave = -1', () {
      final amps = fill(0.5);
      final a = subject(
        amplitudes: amps,
        phases: fill(0.0),
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: amps,
        phases: fill(math.pi),
        omegas: fill(1.0),
      );
      final r = matcher.compare(a: a, b: b, t: 0.0);
      expect(r.resonanceAvailable, isTrue);
      expect(r.rWave, closeTo(-1.0, 1e-12));
    });

    test('orthogonal modal states → r_wave = 0', () {
      // Shared complete modes with orthogonal amplitude vectors.
      final a = subject(
        amplitudes: {ids[0]: 1.0, ids[1]: 0.0},
        phases: {ids[0]: 0.0, ids[1]: 0.0},
        omegas: {ids[0]: 1.0, ids[1]: 1.0},
      );
      final b = subject(
        amplitudes: {ids[0]: 0.0, ids[1]: 1.0},
        phases: {ids[0]: 0.0, ids[1]: 0.0},
        omegas: {ids[0]: 1.0, ids[1]: 1.0},
      );
      final r = matcher.compare(a: a, b: b, t: 0.0);
      expect(r.resonanceAvailable, isTrue);
      expect(r.sharedModeCount, 2);
      expect(r.rWave, closeTo(0.0, 1e-12));
    });

    test('different omega over time → resonance drifts from 1', () {
      final amps = fill(0.4);
      final phases = fill(0.0);
      final a = subject(
        amplitudes: amps,
        phases: phases,
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: amps,
        phases: phases,
        omegas: fill(1.5),
      );
      final at0 = matcher.compare(a: a, b: b, t: 0.0);
      final later = matcher.compare(a: a, b: b, t: math.pi / 0.5);
      expect(at0.rWave, closeTo(1.0, 1e-12));
      expect(later.rWave!, lessThan(0.999));
      expect(later.rWave, isNot(closeTo(at0.rWave!, 1e-6)));
    });

    test('missing phi → unavailable (never fabricated)', () {
      final a = subject(
        amplitudes: fill(0.5),
        phases: fill(0.1),
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: fill(0.5),
        // phases omitted
        omegas: fill(1.0),
      );
      final r = matcher.compare(a: a, b: b);
      expect(r.resonanceAvailable, isFalse);
      expect(r.rWave, isNull);
      expect(
        r.unavailableReason,
        WaveStateModalShadowMatcher.reasonMissingPhase,
      );
      expect(
        r.toWireMap()['fabricates_missing_phase'],
        isFalse,
      );
    });

    test('missing omega → unavailable (never fabricated)', () {
      final a = subject(
        amplitudes: fill(0.5),
        phases: fill(0.1),
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: fill(0.5),
        phases: fill(0.1),
        // omegas omitted
      );
      final r = matcher.compare(a: a, b: b, t: 0.0);
      expect(r.resonanceAvailable, isFalse);
      expect(r.rWave, isNull);
      expect(
        r.unavailableReason,
        WaveStateModalShadowMatcher.reasonMissingOmega,
      );
      expect(
        r.toWireMap()['fabricates_missing_omega'],
        isFalse,
      );
    });

    test('normalization: scaled amplitudes keep r_wave', () {
      final base = values([0.1, 0.2, 0.15, 0.25, 0.12, 0.18]);
      final scaled = {
        for (final e in base.entries) e.key: math.min(1.0, e.value * 2.0),
      };
      final phases = fill(0.2);
      final omegas = fill(0.8);
      final a = subject(amplitudes: base, phases: phases, omegas: omegas);
      final b = subject(amplitudes: scaled, phases: phases, omegas: omegas);
      final r = matcher.compare(a: a, b: b, t: 1.0);
      expect(r.resonanceAvailable, isTrue);
      expect(r.rWave, closeTo(1.0, 1e-12));
      expect(r.normA! * 2.0, closeTo(r.normB!, 1e-12));
    });

    test('symmetry: R(a,b) = R(b,a)', () {
      final a = subject(
        amplitudes: values([0.2, 0.4, 0.1, 0.7, 0.3, 0.5]),
        phases: values([0.1, -0.2, 0.4, 1.0, -1.2, 0.0]),
        omegas: values([0.5, 0.6, 0.7, 0.8, 0.9, 1.0]),
      );
      final b = subject(
        amplitudes: values([0.5, 0.1, 0.6, 0.2, 0.8, 0.3]),
        phases: values([0.3, 0.1, -0.5, 0.2, 0.7, -0.1]),
        omegas: values([0.4, 0.9, 0.2, 1.1, 0.3, 0.7]),
      );
      final ab = matcher.compare(a: a, b: b, t: 1.7);
      final ba = matcher.compare(a: b, b: a, t: 1.7);
      expect(ab.resonanceAvailable, isTrue);
      expect(ba.resonanceAvailable, isTrue);
      expect(ab.rWave, closeTo(ba.rWave!, 1e-12));
    });

    test('mode shapes are orthonormal under discrete L2 on [0,L]', () {
      const L = 1.0;
      const n = 4000;
      final ds = L / n;
      double inner(int m, int nHarm) {
        var acc = 0.0;
        for (var k = 1; k < n; k++) {
          final s = k * ds;
          acc += matcher.modeShape(m, s) * matcher.modeShape(nHarm, s) * ds;
        }
        return acc;
      }

      expect(inner(1, 1), closeTo(1.0, 2e-3));
      expect(inner(2, 2), closeTo(1.0, 2e-3));
      expect(inner(1, 2), closeTo(0.0, 2e-3));
      expect(inner(3, 5), closeTo(0.0, 2e-3));
    });

    test('Psi unavailable when subject lacks complete modes', () {
      final u = subject(amplitudes: fill(0.5)); // no phi/omega
      final psi = matcher.evaluatePsi(subject: u, s: 0.25, t: 0.0);
      expect(psi.available, isFalse);
      expect(psi.unavailableReason, 'no_complete_modes');
    });

    test('no Discover / Persona / RVI / density-matrix coupling in sources', () {
      final paths = [
        'lib/features/matching/domain/wave_state_modal_shadow.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_contract.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_models.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_matcher.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('CompatibilityScoring')), reason: path);
        expect(src, isNot(contains('DensityMatrix')), reason: path);
        expect(src, isNot(contains('quantumFidelity')), reason: path);
      }
      final discover =
          File('lib/features/discover/services/discover_service.dart')
              .readAsStringSync();
      expect(discover, isNot(contains('wave_state_modal_shadow')));
    });
  });
}
