import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow.dart';

/// Offline synthetic stress harness for wave_state_modal_shadow_v1.
///
/// Does **not** change the production formula or Discover wiring.
/// Writes a local diagnostic report only.
void main() {
  test('wave_state_modal_shadow_v1 synthetic stress report', () {
    const matcher = WaveStateModalShadowMatcher();
    final ids = WaveStateModalShadowContract.frequencyDimensionIds;
    final rng = math.Random(42);

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

    Map<String, double> metrics(WaveStateModalShadowResult r) {
      if (!r.resonanceAvailable ||
          r.overlapReal == null ||
          r.overlapImag == null ||
          r.normA == null ||
          r.normB == null ||
          r.normA! <= 0 ||
          r.normB! <= 0) {
        return {
          'available': 0.0,
        };
      }
      final denom = r.normA! * r.normB!;
      final reN = r.overlapReal! / denom;
      final imN = r.overlapImag! / denom;
      final absN = math.sqrt(reN * reN + imN * imN);
      return {
        'available': 1.0,
        'r_wave': reN, // production signed Re(normalized)
        'abs_normalized': absN,
        'abs_normalized_sq': absN * absN,
        'im_normalized': imN,
        'overlap_real': r.overlapReal!,
        'overlap_imag': r.overlapImag!,
      };
    }

    Map<String, dynamic> sample({
      required String id,
      required String family,
      required WaveStateModalSubject a,
      required WaveStateModalSubject b,
      double t = 0.0,
      String? note,
    }) {
      final r = matcher.compare(a: a, b: b, t: t);
      final m = metrics(r);
      return {
        'id': id,
        'family': family,
        't': t,
        if (note != null) 'note': note,
        'resonance_available': r.resonanceAvailable,
        'unavailable_reason': r.unavailableReason,
        'shared_mode_count': r.sharedModeCount,
        'modal_coverage': r.modalCoverage,
        'metrics': m,
        'symmetry_delta_r_wave': () {
          final swap = matcher.compare(a: b, b: a, t: t);
          if (!r.resonanceAvailable || !swap.resonanceAvailable) return null;
          return (r.rWave! - swap.rWave!).abs();
        }(),
      };
    }

    List<Map<String, dynamic>> timeSeries({
      required String id,
      required WaveStateModalSubject a,
      required WaveStateModalSubject b,
      required List<double> times,
    }) {
      return [
        for (final t in times)
          sample(id: '${id}_t=$t', family: id, a: a, b: b, t: t),
      ];
    }

    final cases = <Map<String, dynamic>>[];

    // 1. identical states over time
    {
      final a = subject(
        amplitudes: fill(0.45),
        phases: fill(0.2),
        omegas: fill(1.1),
      );
      final series = timeSeries(
        id: 'identical_over_time',
        a: a,
        b: a,
        times: [0.0, 1.0, 10.0, 100.0, 1000.0],
      );
      cases.addAll(series);
      for (final s in series) {
        expect(s['metrics']['r_wave'], closeTo(1.0, 1e-12));
        expect(s['metrics']['abs_normalized'], closeTo(1.0, 1e-12));
      }
    }

    // 2. global phase offset (gauge on A)
    {
      final amps = fill(0.4);
      final omegas = fill(0.9);
      final a0 = subject(
        amplitudes: amps,
        phases: fill(0.0),
        omegas: omegas,
      );
      for (final alpha in [0.0, 0.3, math.pi / 2, math.pi, 4.2]) {
        final a = subject(
          amplitudes: amps,
          phases: fill(alpha),
          omegas: omegas,
        );
        cases.add(
          sample(
            id: 'global_phase_offset_alpha=$alpha',
            family: 'global_phase_offset',
            a: a,
            b: a0,
            note: 'uniform Δφ=alpha on all modes',
          ),
        );
      }
      final quarter = cases.lastWhere(
        (c) => c['id'] == 'global_phase_offset_alpha=${math.pi / 2}',
      );
      expect(quarter['metrics']['r_wave'], closeTo(0.0, 1e-12));
      expect(quarter['metrics']['abs_normalized'], closeTo(1.0, 1e-12));
    }

    // 3. exact phase opposition
    {
      final a = subject(
        amplitudes: fill(0.5),
        phases: fill(0.0),
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: fill(0.5),
        phases: fill(math.pi),
        omegas: fill(1.0),
      );
      final s = sample(
        id: 'exact_phase_opposition',
        family: 'phase_opposition',
        a: a,
        b: b,
      );
      cases.add(s);
      expect(s['metrics']['r_wave'], closeTo(-1.0, 1e-12));
      expect(s['metrics']['abs_normalized'], closeTo(1.0, 1e-12));
      expect(s['metrics']['abs_normalized_sq'], closeTo(1.0, 1e-12));
    }

    // 4. small phase differences
    {
      final amps = values([0.2, 0.3, 0.4, 0.5, 0.35, 0.25]);
      final omegas = fill(1.0);
      final base = fill(0.0);
      for (final d in [0.01, 0.05, 0.1, 0.2, 0.5]) {
        cases.add(
          sample(
            id: 'small_phase_diff_d=$d',
            family: 'small_phase_diff',
            a: subject(amplitudes: amps, phases: base, omegas: omegas),
            b: subject(amplitudes: amps, phases: fill(d), omegas: omegas),
          ),
        );
      }
    }

    // 5. mixed modes with cancellation
    {
      // Half modes aligned, half opposed → Re ~ 0 if equal energy
      final phasesB = <String, double>{
        for (var i = 0; i < ids.length; i++)
          ids[i]: i.isEven ? 0.0 : math.pi,
      };
      final s = sample(
        id: 'mixed_mode_cancellation',
        family: 'cancellation',
        a: subject(
          amplitudes: fill(1 / math.sqrt(6)),
          phases: fill(0.0),
          omegas: fill(1.0),
        ),
        b: subject(
          amplitudes: fill(1 / math.sqrt(6)),
          phases: phasesB,
          omegas: fill(1.0),
        ),
      );
      cases.add(s);
      expect((s['metrics']['r_wave'] as double).abs(), lessThan(1e-12));
      expect((s['metrics']['abs_normalized'] as double), lessThan(1e-12));
    }

    // 6. one dominant mode
    {
      final ampsA = <String, double>{
        ids[0]: 0.95,
        for (var i = 1; i < ids.length; i++) ids[i]: 0.02,
      };
      final ampsB = Map<String, double>.from(ampsA);
      cases.add(
        sample(
          id: 'one_dominant_mode_aligned',
          family: 'dominant_mode',
          a: subject(
            amplitudes: ampsA,
            phases: fill(0.1),
            omegas: fill(1.0),
          ),
          b: subject(
            amplitudes: ampsB,
            phases: fill(0.1),
            omegas: fill(1.0),
          ),
        ),
      );
      cases.add(
        sample(
          id: 'one_dominant_mode_opposed',
          family: 'dominant_mode',
          a: subject(
            amplitudes: ampsA,
            phases: fill(0.0),
            omegas: fill(1.0),
          ),
          b: subject(
            amplitudes: ampsB,
            phases: {ids[0]: math.pi, for (var i = 1; i < 6; i++) ids[i]: 0.0},
            omegas: fill(1.0),
          ),
        ),
      );
    }

    // 7. equal amplitudes but different omega
    {
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
        omegas: fill(1.3),
      );
      cases.addAll(
        timeSeries(
          id: 'equal_amp_diff_omega',
          a: a,
          b: b,
          times: [0.0, 0.5, 1.0, 2.0, 5.0, 10.0],
        ),
      );
    }

    // 8. gradually diverging omega over time
    {
      final amps = values([0.3, 0.4, 0.2, 0.5, 0.35, 0.45]);
      final phases = fill(0.0);
      final a = subject(
        amplitudes: amps,
        phases: phases,
        omegas: values([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
      );
      final b = subject(
        amplitudes: amps,
        phases: phases,
        omegas: values([1.0, 1.05, 1.1, 1.15, 1.2, 1.25]),
      );
      cases.addAll(
        timeSeries(
          id: 'gradual_omega_divergence',
          a: a,
          b: b,
          times: [0.0, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0],
        ),
      );
    }

    // 9. periodic re-alignment / beating (single Δω)
    {
      const dw = 0.5;
      final a = subject(
        amplitudes: fill(0.5),
        phases: fill(0.0),
        omegas: fill(1.0),
      );
      final b = subject(
        amplitudes: fill(0.5),
        phases: fill(0.0),
        omegas: fill(1.0 + dw),
      );
      // Beat period T = 2π/Δω
      final T = 2 * math.pi / dw;
      final beatTimes = [0.0, T / 4, T / 2, 3 * T / 4, T, 5 * T / 4, 2 * T];
      final series = timeSeries(
        id: 'beating_single_delta_omega',
        a: a,
        b: b,
        times: beatTimes,
      );
      cases.addAll(series);
      expect(series[0]['metrics']['r_wave'], closeTo(1.0, 1e-12));
      expect(series[2]['metrics']['r_wave'], closeTo(-1.0, 1e-12)); // T/2
      expect(series[4]['metrics']['r_wave'], closeTo(1.0, 1e-12)); // T
    }

    // 10. highly different amplitudes
    {
      cases.add(
        sample(
          id: 'highly_different_amplitudes',
          family: 'amplitude_mismatch',
          a: subject(
            amplitudes: values([0.05, 0.1, 0.08, 0.12, 0.07, 0.09]),
            phases: fill(0.0),
            omegas: fill(1.0),
          ),
          b: subject(
            amplitudes: values([0.9, 0.85, 0.95, 0.8, 0.88, 0.92]),
            phases: fill(0.0),
            omegas: fill(1.0),
          ),
        ),
      );
    }

    // 11. partial shared complete modes
    {
      final a = subject(
        amplitudes: {
          ids[0]: 0.5,
          ids[1]: 0.4,
          ids[2]: 0.3,
        },
        phases: {
          ids[0]: 0.1,
          ids[1]: 0.2,
          ids[2]: 0.3,
        },
        omegas: {
          ids[0]: 1.0,
          ids[1]: 1.1,
          ids[2]: 1.2,
        },
      );
      final b = subject(
        amplitudes: {
          ids[1]: 0.4,
          ids[2]: 0.3,
          ids[3]: 0.6, // not shared complete with a
        },
        phases: {
          ids[1]: 0.2,
          ids[2]: 0.3,
          ids[3]: 0.0,
        },
        omegas: {
          ids[1]: 1.1,
          ids[2]: 1.2,
          ids[3]: 1.0,
        },
      );
      final s = sample(
        id: 'partial_shared_complete_modes',
        family: 'partial_coverage',
        a: a,
        b: b,
      );
      cases.add(s);
      expect(s['shared_mode_count'], 2);
      expect(s['resonance_available'], isTrue);
    }

    // 12. random 6-mode states
    final randomRWave = <double>[];
    final randomAbs = <double>[];
    final randomAbsSq = <double>[];
    for (var i = 0; i < 200; i++) {
      Map<String, double> randAmps() => {
            for (final id in ids) id: 0.05 + rng.nextDouble() * 0.95,
          };
      Map<String, double> randPhases() => {
            for (final id in ids) id: (rng.nextDouble() * 2 - 1) * math.pi,
          };
      Map<String, double> randOmegas() => {
            for (final id in ids) id: 0.2 + rng.nextDouble() * 2.0,
          };
      final a = subject(
        amplitudes: randAmps(),
        phases: randPhases(),
        omegas: randOmegas(),
      );
      final b = subject(
        amplitudes: randAmps(),
        phases: randPhases(),
        omegas: randOmegas(),
      );
      final t = rng.nextDouble() * 10;
      final s = sample(
        id: 'random_6mode_$i',
        family: 'random_6mode',
        a: a,
        b: b,
        t: t,
      );
      cases.add(s);
      randomRWave.add(s['metrics']['r_wave'] as double);
      randomAbs.add(s['metrics']['abs_normalized'] as double);
      randomAbsSq.add(s['metrics']['abs_normalized_sq'] as double);
      expect(s['symmetry_delta_r_wave'], lessThan(1e-12));
    }

    // 13. long-time numerical stability
    {
      final a = subject(
        amplitudes: values([0.2, 0.3, 0.4, 0.5, 0.35, 0.25]),
        phases: values([0.1, -0.2, 0.4, 0.0, 1.1, -0.7]),
        omegas: values([1.0, 1.01, 0.99, 1.02, 0.98, 1.0]),
      );
      final b = subject(
        amplitudes: values([0.25, 0.35, 0.3, 0.45, 0.4, 0.2]),
        phases: values([0.2, 0.1, -0.3, 0.5, -0.2, 0.0]),
        omegas: values([1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),
      );
      final times = [0.0, 1e3, 1e4, 1e5, 1e6];
      final series = timeSeries(
        id: 'long_time_stability',
        a: a,
        b: b,
        times: times,
      );
      cases.addAll(series);
      for (final s in series) {
        final m = s['metrics'] as Map<String, double>;
        expect(m['r_wave']!.isFinite, isTrue);
        expect(m['abs_normalized']!.isFinite, isTrue);
        expect(m['r_wave']!, inInclusiveRange(-1.0 - 1e-9, 1.0 + 1e-9));
        expect(m['abs_normalized']!, inInclusiveRange(0.0, 1.0 + 1e-9));
      }
    }

    // 14. symmetry A↔B (explicit sweep)
    {
      var maxDelta = 0.0;
      for (var i = 0; i < 50; i++) {
        final a = subject(
          amplitudes: {
            for (final id in ids) id: 0.1 + rng.nextDouble() * 0.9,
          },
          phases: {
            for (final id in ids) id: (rng.nextDouble() * 2 - 1) * math.pi,
          },
          omegas: {
            for (final id in ids) id: 0.5 + rng.nextDouble(),
          },
        );
        final b = subject(
          amplitudes: {
            for (final id in ids) id: 0.1 + rng.nextDouble() * 0.9,
          },
          phases: {
            for (final id in ids) id: (rng.nextDouble() * 2 - 1) * math.pi,
          },
          omegas: {
            for (final id in ids) id: 0.5 + rng.nextDouble(),
          },
        );
        final t = rng.nextDouble() * 20;
        final ab = matcher.compare(a: a, b: b, t: t);
        final ba = matcher.compare(a: b, b: a, t: t);
        final d = (ab.rWave! - ba.rWave!).abs();
        if (d > maxDelta) maxDelta = d;
      }
      cases.add({
        'id': 'symmetry_sweep',
        'family': 'symmetry',
        'max_abs_delta_r_wave': maxDelta,
      });
      expect(maxDelta, lessThan(1e-12));
    }

    // --- Aggregate analysis ---
    Map<String, num?> dist(List<double> xs) {
      if (xs.isEmpty) {
        return {'n': 0, 'min': null, 'max': null, 'mean': null, 'p50': null};
      }
      final s = List<double>.from(xs)..sort();
      final mean = s.reduce((a, b) => a + b) / s.length;
      final p50 = s[(s.length - 1) ~/ 2];
      return {
        'n': s.length,
        'min': s.first,
        'max': s.last,
        'mean': mean,
        'p50': p50,
      };
    }

    List<double> familyMetric(String family, String key) {
      final out = <double>[];
      for (final c in cases) {
        if (c['family'] != family) continue;
        final m = c['metrics'];
        if (m is Map && m['available'] == 1.0 && m[key] is num) {
          out.add((m[key] as num).toDouble());
        }
      }
      return out;
    }

    // Phase sensitivity curve from small_phase_diff
    final phaseSens = <Map<String, dynamic>>[];
    for (final c in cases) {
      if (c['family'] != 'small_phase_diff') continue;
      phaseSens.add({
        'id': c['id'],
        'r_wave': c['metrics']['r_wave'],
        'abs_normalized': c['metrics']['abs_normalized'],
        'abs_normalized_sq': c['metrics']['abs_normalized_sq'],
      });
    }

    // Global phase gauge: Re varies, abs stays ~1
    final gauge = [
      for (final c in cases)
        if (c['family'] == 'global_phase_offset')
          {
            'id': c['id'],
            'r_wave': c['metrics']['r_wave'],
            'abs_normalized': c['metrics']['abs_normalized'],
          },
    ];

    // Beat envelope
    final beats = [
      for (final c in cases)
        if (c['family'] == 'beating_single_delta_omega')
          {
            't': c['t'],
            'r_wave': c['metrics']['r_wave'],
            'abs_normalized': c['metrics']['abs_normalized'],
          },
    ];

    // Diagnostic comparison: when does Re disagree with abs about "match quality"?
    var oppositionAbsConfusion = 0;
    var gaugeReConfusion = 0;
    for (final c in cases) {
      final m = c['metrics'];
      if (m is! Map || m['available'] != 1.0) continue;
      final re = m['r_wave'] as double;
      final abs = m['abs_normalized'] as double;
      if (re < -0.9 && abs > 0.9) oppositionAbsConfusion++;
      if (c['family'] == 'global_phase_offset' &&
          re.abs() < 0.1 &&
          abs > 0.9) {
        gaugeReConfusion++;
      }
    }

    final findings = <String>[
      'Identical states: r_wave=abs=1 for all tested times (stable).',
      'Global phase offset: |overlap| invariant (=1); Re(overlap)=cos(α) — signed Re is gauge-dependent.',
      'Exact phase opposition: r_wave=-1 but abs=abs^2=1 — magnitude metrics cannot distinguish opposition from identity.',
      'Mixed half-aligned/half-opposed equal-energy modes cancel: Re≈0 and |overlap|≈0.',
      'Single-Δω beating: r_wave oscillates cos(Δω t) with period 2π/Δω; abs stays 1 (pure relative phase rotation).',
      'Multi-mode Δω divergence: |overlap| decays from 1 as modes dephase (informative envelope); Re oscillates inside that envelope.',
      'Partial shared complete modes reduce coverage but remain computable without fabrication.',
      'Long-time samples up to t=1e6 remain finite and within [-1,1] / [0,1].',
      'Symmetry A↔B holds to numerical noise (<1e-12).',
      'Re(normalized) preserves signed constructive/destructive interference but is not U(1)-gauge invariant.',
      '|normalized| / |normalized|^2 are gauge-invariant and capture dephasing envelopes, but discard opposition sign.',
    ];

    final recommendation = <String>[
      'Do NOT replace the production r_wave=Re formula yet.',
      'Before real temporal integration, emit diagnostic companions abs_normalized and abs_normalized_sq alongside r_wave (shadow-only).',
      'Treat absolute/global phase as unobservable: either gauge-fix (e.g. set Δφ of a reference mode to 0) before reading Re, or prefer |overlap| for magnitude-of-alignment and keep signed residual only after gauge-fixing.',
      'For dyadic matching semantics: |⟨Ψ_a|Ψ_b⟩| is the physically gauge-safe scalar; signed Re after fixing a relative-phase gauge can still report opposition-like structure across modes.',
      'Never fabricate φ/ω; keep unavailable gates as-is.',
      'Do not wire into Discover/UI until temporal estimators exist and representation policy is frozen.',
    ];

    final report = {
      'title': 'Wave-State Modal Shadow v1 — synthetic stress',
      'scoring_version': WaveStateModalShadowContract.scoringVersion,
      'policy_status': WaveStateModalShadowContract.policyStatus,
      'shadow_only': true,
      'formula_unchanged': true,
      'affects_discover_ranking': false,
      'representations_seed': 42,
      'case_count': cases.length,
      'distributions': {
        'random_6mode_r_wave': dist(randomRWave),
        'random_6mode_abs_normalized': dist(randomAbs),
        'random_6mode_abs_normalized_sq': dist(randomAbsSq),
        'small_phase_diff_r_wave': dist(familyMetric('small_phase_diff', 'r_wave')),
        'gradual_omega_divergence_r_wave':
            dist(familyMetric('gradual_omega_divergence', 'r_wave')),
        'gradual_omega_divergence_abs':
            dist(familyMetric('gradual_omega_divergence', 'abs_normalized')),
        'equal_amp_diff_omega_r_wave':
            dist(familyMetric('equal_amp_diff_omega', 'r_wave')),
        'equal_amp_diff_omega_abs':
            dist(familyMetric('equal_amp_diff_omega', 'abs_normalized')),
      },
      'phase_sensitivity_curve': phaseSens,
      'global_phase_gauge_sweep': gauge,
      'beating_series': beats,
      'confusion_counts': {
        'opposition_where_abs_near_1': oppositionAbsConfusion,
        'gauge_where_re_near_0_abs_near_1': gaugeReConfusion,
      },
      'representation_comparison': {
        'a_re_normalized_overlap': {
          'role': 'production r_wave',
          'range': '[-1,1]',
          'preserves_opposition_sign': true,
          'global_phase_gauge_invariant': false,
          'captures_dephasing_envelope_alone': false,
        },
        'b_abs_normalized_overlap': {
          'range': '[0,1]',
          'preserves_opposition_sign': false,
          'global_phase_gauge_invariant': true,
          'captures_dephasing_envelope_alone': true,
        },
        'c_abs_normalized_overlap_sq': {
          'range': '[0,1]',
          'preserves_opposition_sign': false,
          'global_phase_gauge_invariant': true,
          'note': 'Fidelity-like magnitude; still not a density-matrix layer',
        },
        'best_for_meaningful_phase_structure':
            'Gauge-fixed Re residual AND |overlap| envelope together; neither alone',
      },
      'findings': findings,
      'recommendation_before_real_temporal_integration': recommendation,
      'cases_sample': [
        for (final c in cases)
          if (c['family'] != 'random_6mode') c,
      ],
      'random_cases_omitted_from_sample':
          '200 random_6mode cases summarized in distributions only',
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final outFile = File(
      'docs/matching/reports/wave_state_modal_shadow_stress_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(report),
    );

    // Core analytical assertions for the harness itself.
    expect(oppositionAbsConfusion, greaterThan(0));
    expect(gaugeReConfusion, greaterThan(0));
    expect(randomRWave.length, 200);
    expect(File(outFile.path).existsSync(), isTrue);
  });
}
