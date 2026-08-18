import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/periodic_wave_state_resonance.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_compatibility.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

/// Offline synthetic stress harness for periodic Wave-State resonance v1.
/// Does **not** change production adapter behavior or Discover wiring.
void main() {
  test('periodic_wave_state_resonance_v1 synthetic stress report', () {
    const adapter = PeriodicWaveStateResonanceAdapter();
    final rng = math.Random(17);

    ActivitySpectralOmegaEstimate okOmega({
      required String oscillatorId,
      required double periodSeconds,
      ActivitySpectralOmegaStatus status = ActivitySpectralOmegaStatus.ok,
      String? reason,
    }) {
      final omega = 2 * math.pi / periodSeconds;
      return ActivitySpectralOmegaEstimate(
        status: status,
        reason: reason,
        eventCount: 60,
        windowSeconds: 21 * 86400.0,
        binWidthSeconds: 3600,
        periodSeconds: periodSeconds,
        omega: status == ActivitySpectralOmegaStatus.ok ? omega : null,
        snr: 100,
        splitHalfRelativeDelta: 0.0,
        binSensitivityRelativeDelta: 0.0,
        nearCivilCollision:
            status == ActivitySpectralOmegaStatus.civilCollision,
        civilCollisionKind:
            status == ActivitySpectralOmegaStatus.civilCollision
                ? 'near_24h'
                : null,
        candidatePeaks: const [],
        oscillatorId: oscillatorId,
      );
    }

    ValidatedPeriodicPhaseEstimate okPhase({
      required String oscillatorId,
      required double periodSeconds,
      required double phaseRadians,
      String epoch = '2024-01-01T00:00:00.000Z',
      ActivitySpectralOmegaStatus omegaStatus = ActivitySpectralOmegaStatus.ok,
      bool available = true,
      String? unavailableReason,
    }) {
      final omega = 2 * math.pi / periodSeconds;
      final pref = available
          ? PhaseReferenceV2(
              oscillatorId: oscillatorId,
              phaseRadians: phaseRadians,
              phaseClass: WavePhaseClassV2.validatedPeriodic,
              timeBasis: WavePhaseTimeBasisV2.utc,
              periodicityStatus: WavePeriodicityStatusV2.ok,
              periodSeconds: periodSeconds,
              omega: omega,
              referenceEpoch: epoch,
              source: ValidatedPeriodicPhaseBinderContract.sourceId,
            )
          : null;
      return ValidatedPeriodicPhaseEstimate(
        available: available,
        unavailableReason: unavailableReason,
        eventCount: 60,
        thetaBar: available ? phaseRadians : null,
        rBar: available ? 0.95 : null,
        periodSeconds: periodSeconds,
        omega: available ? omega : null,
        oscillatorId: oscillatorId,
        referenceEpoch: available ? epoch : null,
        referenceEpochMs: available ? 1704067200000 : null,
        phaseReference: pref,
        omegaStatus: omegaStatus,
      );
    }

    double l2(List<double> xs) {
      var s = 0.0;
      for (final x in xs) {
        s += x * x;
      }
      return math.sqrt(s);
    }

    double cosineSim(List<double> a, List<double> b) {
      final na = l2(a);
      final nb = l2(b);
      if (na <= 0 || nb <= 0) return double.nan;
      var dot = 0.0;
      for (var i = 0; i < a.length; i++) {
        dot += a[i] * b[i];
      }
      return dot / (na * nb);
    }

    List<double> randAmp(int dim, {bool sparseDominant = false}) {
      if (sparseDominant) {
        final out = List<double>.filled(dim, 0.0);
        out[rng.nextInt(dim)] = 0.2 + rng.nextDouble();
        return out;
      }
      return [for (var i = 0; i < dim; i++) rng.nextDouble()];
    }

    const osc = 'activity_spectral_global_activity_t43200s';
    const T = 43200.0;
    final omega = okOmega(oscillatorId: osc, periodSeconds: T);

    final cases = <Map<String, dynamic>>[];

    void addCase({
      required String id,
      required String family,
      required ValidatedPeriodicPhaseEstimate phaseA,
      required ValidatedPeriodicPhaseEstimate phaseB,
      required List<double> ampsA,
      required List<double> ampsB,
      ActivitySpectralOmegaEstimate? omegaA,
      ActivitySpectralOmegaEstimate? omegaB,
      double t = 0.0,
      double? expectedCosDeltaPhi,
    }) {
      final oa = omegaA ?? omega;
      final ob = omegaB ?? omega;
      final r = adapter.compare(
        omegaA: oa,
        phaseA: phaseA,
        modalAmplitudesA: ampsA,
        omegaB: ob,
        phaseB: phaseB,
        modalAmplitudesB: ampsB,
        t: t,
      );
      final dPhi = (phaseA.thetaBar ?? 0) - (phaseB.thetaBar ?? 0);
      final cosD = math.cos(dPhi);
      final ampCos = cosineSim(ampsA, ampsB);
      final predictedR =
          r.signedResonanceAvailable ? cosD * ampCos : null;
      final predictedCAbs =
          r.signedResonanceAvailable ? ampCos.abs() : null;
      cases.add({
        'id': id,
        'family': family,
        'available': r.signedResonanceAvailable,
        'reason': r.unavailableReason,
        'r_wave': r.rWave,
        'c_abs': r.cAbs,
        'c_abs_sq': r.cAbsSq,
        'delta_phi': dPhi,
        'cos_delta_phi': cosD,
        'amp_cosine': ampCos.isNaN ? null : ampCos,
        'predicted_r_wave': predictedR,
        'predicted_c_abs': predictedCAbs,
        'err_r_vs_cos_dphi':
            r.rWave == null ? null : (r.rWave! - cosD).abs(),
        'err_r_vs_cos_dphi_times_ampcos': predictedR == null || r.rWave == null
            ? null
            : (r.rWave! - predictedR).abs(),
        'err_cabs_vs_ampcos':
            predictedCAbs == null || r.cAbs == null
                ? null
                : (r.cAbs! - predictedCAbs).abs(),
        't': t,
        'amp_dim': ampsA.length,
      });
    }

    // 1. identical phases
    for (final amps in [
      [1.0],
      [0.5, 0.5, 0.5],
      [1.0, 0.0, 0.0],
      [0.2, 0.4, 0.6, 0.8],
    ]) {
      addCase(
        id: 'identical_phi_amps_${amps.join("_")}',
        family: 'identical_phases',
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.7),
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.7),
        ampsA: amps,
        ampsB: List<double>.from(amps),
      );
    }

    // 2. small / medium / opposite phase offsets (parallel amps)
    for (final entry in [
      ('small', 0.1),
      ('medium', math.pi / 3),
      ('opposite', math.pi),
      ('quad', math.pi / 2),
    ]) {
      addCase(
        id: 'offset_${entry.$1}_parallel',
        family: 'phase_offsets_parallel_amps',
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        phaseB: okPhase(
          oscillatorId: osc,
          periodSeconds: T,
          phaseRadians: entry.$2,
        ),
        ampsA: const [0.4, 0.5, 0.3],
        ampsB: const [0.4, 0.5, 0.3],
        expectedCosDeltaPhi: math.cos(entry.$2),
      );
    }

    // 3. different amplitude envelopes (fixed Δφ)
    const dPhiFixed = 0.4;
    for (var i = 0; i < 12; i++) {
      addCase(
        id: 'diff_amps_$i',
        family: 'different_amplitude_envelopes',
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        phaseB: okPhase(
          oscillatorId: osc,
          periodSeconds: T,
          phaseRadians: dPhiFixed,
        ),
        ampsA: randAmp(4),
        ampsB: randAmp(4),
      );
    }

    // 4. dominant-mode amplitudes
    for (var i = 0; i < 8; i++) {
      addCase(
        id: 'dominant_$i',
        family: 'dominant_mode_amplitudes',
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.2),
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.9),
        ampsA: randAmp(6, sparseDominant: true),
        ampsB: randAmp(6, sparseDominant: true),
      );
    }

    // 5. partial / canceling modal envelopes
    addCase(
      id: 'orthogonal_amps',
      family: 'partial_canceling_envelopes',
      phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0, 0.0, 0.0],
      ampsB: const [0.0, 1.0, 0.0],
    );
    addCase(
      id: 'anti_aligned_amps',
      family: 'partial_canceling_envelopes',
      phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0, 1.0],
      ampsB: const [1.0, -1.0],
    );
    addCase(
      id: 'partial_overlap_amps',
      family: 'partial_canceling_envelopes',
      phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: math.pi / 4),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0, 1.0, 0.0],
      ampsB: const [1.0, 0.0, 1.0],
    );

    // 6. random compatible pairs
    for (var i = 0; i < 80; i++) {
      final dim = 3 + rng.nextInt(4);
      final phiA = rng.nextDouble() * 2 * math.pi - math.pi;
      final phiB = rng.nextDouble() * 2 * math.pi - math.pi;
      addCase(
        id: 'random_compatible_$i',
        family: 'random_compatible',
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: phiA),
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: phiB),
        ampsA: randAmp(dim),
        ampsB: randAmp(dim),
      );
    }

    // 7. provenance rejection cases
    addCase(
      id: 'reject_civil',
      family: 'provenance_rejection',
      omegaA: okOmega(
        oscillatorId: osc,
        periodSeconds: T,
        status: ActivitySpectralOmegaStatus.civilCollision,
        reason: 'civil_collision',
      ),
      phaseA: ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason: 'civil_collision',
        eventCount: 40,
        thetaBar: null,
        rBar: null,
        periodSeconds: 86400,
        omega: null,
        oscillatorId: null,
        referenceEpoch: null,
        referenceEpochMs: null,
        phaseReference: null,
        omegaStatus: ActivitySpectralOmegaStatus.civilCollision,
      ),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0],
      ampsB: const [1.0],
    );
    addCase(
      id: 'reject_ambiguous',
      family: 'provenance_rejection',
      omegaA: okOmega(
        oscillatorId: osc,
        periodSeconds: T,
        status: ActivitySpectralOmegaStatus.ambiguous,
        reason: 'multiple_competing_peaks',
      ),
      phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0],
      ampsB: const [1.0],
    );
    addCase(
      id: 'reject_osc_mismatch',
      family: 'provenance_rejection',
      phaseA: okPhase(
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: 36000,
        phaseRadians: 0.1,
      ),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.1),
      omegaA: okOmega(
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: 36000,
      ),
      omegaB: omega,
      ampsA: const [1.0],
      ampsB: const [1.0],
    );
    addCase(
      id: 'reject_epoch_mismatch',
      family: 'provenance_rejection',
      phaseA: okPhase(
        oscillatorId: osc,
        periodSeconds: T,
        phaseRadians: 0.1,
        epoch: '2024-01-01T00:00:00.000Z',
      ),
      phaseB: okPhase(
        oscillatorId: osc,
        periodSeconds: T,
        phaseRadians: 0.1,
        epoch: '2024-06-01T00:00:00.000Z',
      ),
      ampsA: const [1.0],
      ampsB: const [1.0],
    );
    addCase(
      id: 'reject_phase_osc_ne_omega',
      family: 'provenance_rejection',
      phaseA: okPhase(
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: T,
        phaseRadians: 0.0,
      ),
      phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
      ampsA: const [1.0],
      ampsB: const [1.0],
    );

    // 8. long-time evaluation (same ω → time invariance)
    final baseA = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.3);
    final baseB = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 1.2);
    const amps = [0.5, 0.4, 0.7];
    for (final t in [0.0, T / 4, T / 2, T, 10 * T, 1000 * T]) {
      addCase(
        id: 'long_time_t_${t.round()}',
        family: 'long_time_evaluation',
        phaseA: baseA,
        phaseB: baseB,
        ampsA: amps,
        ampsB: amps,
        t: t,
      );
    }

    // --- Aggregates ---
    List<Map<String, dynamic>> fam(String f) =>
        [for (final c in cases) if (c['family'] == f) c];

    List<double> nums(List<Map<String, dynamic>> xs, String key) => [
          for (final c in xs)
            if (c[key] is num) (c[key] as num).toDouble(),
        ];

    double? mean(List<double> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;
    double? maxAbs(List<double> xs) =>
        xs.isEmpty ? null : xs.map((e) => e.abs()).reduce(math.max);

    final parallel = fam('phase_offsets_parallel_amps');
    final parallelErrCos = nums(parallel, 'err_r_vs_cos_dphi');
    final parallelErrFactor = nums(parallel, 'err_r_vs_cos_dphi_times_ampcos');

    final available = [
      for (final c in cases)
        if (c['available'] == true) c,
    ];
    final reductionErr = nums(available, 'err_r_vs_cos_dphi_times_ampcos');
    final cosOnlyErr = nums(available, 'err_r_vs_cos_dphi');
    final cAbsErr = nums(available, 'err_cabs_vs_ampcos');

    final random = fam('random_compatible');
    final rWaves = nums(random, 'r_wave');
    final cAbses = nums(random, 'c_abs');
    final cAbsSqs = nums(random, 'c_abs_sq');
    final ampCosines = nums(random, 'amp_cosine');

    final long = fam('long_time_evaluation');
    final longRwaves = nums(long, 'r_wave');
    final longSpread = longRwaves.isEmpty
        ? null
        : longRwaves.reduce(math.max) - longRwaves.reduce(math.min);

    final rejects = fam('provenance_rejection');
    final rejectOkCount =
        rejects.where((c) => c['available'] == true).length;

    final cancel = fam('partial_canceling_envelopes');

    // Soft harness health asserts (not production changes).
    expect(cases.length, greaterThan(50));
    expect(maxAbs(reductionErr)!, lessThan(1e-10));
    expect(maxAbs(cAbsErr)!, lessThan(1e-10));
    // Parallel unit-aligned amps → r_wave = cos(Δφ).
    expect(maxAbs(parallelErrCos)!, lessThan(1e-10));
    expect(maxAbs(parallelErrFactor)!, lessThan(1e-10));
    // Time invariance under same ω.
    expect(longSpread!, lessThan(1e-10));
    // Provenance gates must not silently accept.
    expect(rejectOkCount, equals(0));
    // Amplitude matters: cos-only error is large in random set.
    expect(mean(cosOnlyErr)!, greaterThan(0.05));

    final identical = fam('identical_phases');
    final identicalR = nums(identical, 'r_wave');

    final findings = <String>[
      'Exact reduction (compatible, Δω=0): r_wave = cos(Δφ) · cos∠(A,B); '
          'c_abs = |cos∠(A,B)|. Max |r − cosΔφ·ampCos|=${maxAbs(reductionErr)}.',
      'Parallel equal envelopes: r_wave collapses to cos(Δφ) '
          '(max |r−cosΔφ|=${maxAbs(parallelErrCos)}).',
      'Random compatible: mean |r−cosΔφ|=${mean(cosOnlyErr)} '
          '(amplitudes contribute); mean |r−cosΔφ·ampCos|=${mean(reductionErr)}.',
      'c_abs is phase-blind under same ω: equals |amp cosine|; '
          'c_abs_sq = ampCos².',
      'Long-time same-ω: r_wave spread across t∈[0,1000T] = $longSpread '
          '(time invariance appropriate for Δω=0).',
      'Provenance rejects available=$rejectOkCount/${rejects.length}.',
      'Orthogonal identical-phase envelopes → r_wave=0, c_abs=0 '
          '(amplitude cancellation independent of phase).',
    ];

    final ampAddsInfo = mean(cosOnlyErr)! > 0.05 && maxAbs(reductionErr)! < 1e-9;
    final reducesOnlyToCosDphi = maxAbs(cosOnlyErr)! < 1e-9; // false if amps vary

    final scientificallyUsefulAsIs = ampAddsInfo &&
        !reducesOnlyToCosDphi &&
        longSpread < 1e-9 &&
        rejectOkCount == 0;

    final recommendation = scientificallyUsefulAsIs
        ? 'Keep Wave-State shadow as a phase×amplitude-geometry product under '
            'strict same-ω Class-B gates. Before a quantum-inspired layer: '
            '(1) treat c_abs as amplitude-alignment diagnostic only, '
            '(2) do not market c_abs as phase resonance, '
            '(3) decide whether multi-mode envelopes are justified without '
            'mode-specific oscillators, '
            '(4) do not loosen ω/phase compatibility yet.'
        : 'Model is largely redundant with cos(Δφ) under parallel envelopes; '
            'clarify amplitude semantics before quantum-inspired extensions.';

    final report = {
      'title': 'Periodic Wave-State Resonance v1 — synthetic stress',
      'scoring_version':
          PeriodicWaveStateResonanceAdapterContract.scoringVersion,
      'shadow_only': true,
      'gates_calibrated': false,
      'formula_unchanged': true,
      'affects_discover_ranking': false,
      'rng_seed': 17,
      'case_count': cases.length,
      'mathematical_reduction': {
        'formula': 'r_wave = cos(delta_phi) * cosine_similarity(A,B)  when Δω=0',
        'c_abs_formula': 'c_abs = |cosine_similarity(A,B)|  (phase-blind)',
        'reduces_entirely_to_cos_delta_phi': reducesOnlyToCosDphi,
        'max_abs_err_r_vs_cos_dphi_times_ampcos': maxAbs(reductionErr),
        'max_abs_err_cabs_vs_ampcos': maxAbs(cAbsErr),
        'parallel_amps_max_abs_err_r_vs_cos_dphi': maxAbs(parallelErrCos),
      },
      'amplitude_contribution': {
        'adds_meaningful_information': ampAddsInfo,
        'random_mean_abs_err_r_vs_cos_dphi_alone': mean(cosOnlyErr),
        'random_mean_abs_err_r_vs_full_reduction': mean(reductionErr),
        'random_amp_cosine_mean': mean(ampCosines),
        'random_amp_cosine_min':
            ampCosines.isEmpty ? null : ampCosines.reduce(math.min),
        'random_amp_cosine_max':
            ampCosines.isEmpty ? null : ampCosines.reduce(math.max),
      },
      'distributions_random_compatible': {
        'n': random.length,
        'r_wave_mean': mean(rWaves),
        'r_wave_min': rWaves.isEmpty ? null : rWaves.reduce(math.min),
        'r_wave_max': rWaves.isEmpty ? null : rWaves.reduce(math.max),
        'c_abs_mean': mean(cAbses),
        'c_abs_min': cAbses.isEmpty ? null : cAbses.reduce(math.min),
        'c_abs_max': cAbses.isEmpty ? null : cAbses.reduce(math.max),
        'c_abs_sq_mean': mean(cAbsSqs),
      },
      'identical_phases': {
        'n': identical.length,
        'r_wave_values': identicalR,
        'all_near_amp_cosine': identical.every(
          (c) =>
              c['r_wave'] is num &&
              c['amp_cosine'] is num &&
              ((c['r_wave'] as num) - (c['amp_cosine'] as num)).abs() < 1e-10,
        ),
      },
      'partial_canceling': [
        for (final c in cancel)
          {
            'id': c['id'],
            'r_wave': c['r_wave'],
            'c_abs': c['c_abs'],
            'amp_cosine': c['amp_cosine'],
            'cos_delta_phi': c['cos_delta_phi'],
          },
      ],
      'long_time': {
        'r_wave_values': longRwaves,
        'spread': longSpread,
        'time_invariance_appropriate_for_same_omega': true,
      },
      'provenance_rejection': {
        'cases': rejects.length,
        'available_count': rejectOkCount,
      },
      'findings': findings,
      'scientifically_useful_as_is': scientificallyUsefulAsIs,
      'recommendation': recommendation,
      'cases': cases,
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File(
      'docs/matching/reports/periodic_wave_state_resonance_stress_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(report),
    );
    expect(outFile.existsSync(), isTrue);

    // Contract isolation freeze.
    expect(
      PeriodicWaveStateResonanceAdapterContract.attachesToFrequencyModes,
      isFalse,
    );
    expect(
      PeriodicWaveStateResonanceAdapterContract.liveDiscoverRanking,
      isFalse,
    );
  });
}
