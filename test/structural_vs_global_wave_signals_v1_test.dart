import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_group_normalized_shadow.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_amplitude_semantics.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

/// Offline/shadow comparison: D_structural vs global wave signals.
/// Does **not** combine signals, invent weights, or touch Discover/UI.
void main() {
  test('structural_vs_global_wave_signals synthetic report', () {
    const structural = Canonical20dGroupNormalizedShadowMatcher();
    const wave = GlobalActivityPeriodicResonance();
    final rng = math.Random(23);

    final iq = Canonical20dGroupNormalizedShadowContract.iqDimensionIds;
    final eq = Canonical20dGroupNormalizedShadowContract.eqDimensionIds;
    final freq =
        Canonical20dGroupNormalizedShadowContract.frequencyDimensionIds;
    final all = [...iq, ...eq, ...freq];

    Canonical20dShadowSubject profile(Map<String, double> scores) {
      return Canonical20dShadowSubject(
        measuredScores: scores,
        evidenceCounts: const {},
      );
    }

    Map<String, double> randProfile({double noise = 1.0}) {
      return {
        for (final id in all)
          id: (0.15 + rng.nextDouble() * 0.7 * noise).clamp(0.0, 1.0),
      };
    }

    Map<String, double> shiftProfile(
      Map<String, double> base, {
      required double delta,
      Set<String>? dims,
    }) {
      final target = dims ?? all.toSet();
      return {
        for (final id in all)
          id: target.contains(id)
              ? (base[id]! + delta * (rng.nextBool() ? 1 : -1))
                  .clamp(0.0, 1.0)
              : base[id]!,
      };
    }

    const osc = 'activity_spectral_global_activity_t43200s';
    const T = 43200.0;
    final omegaEst = ActivitySpectralOmegaEstimate(
      status: ActivitySpectralOmegaStatus.ok,
      reason: null,
      eventCount: 60,
      windowSeconds: 21 * 86400.0,
      binWidthSeconds: 3600,
      periodSeconds: T,
      omega: 2 * math.pi / T,
      snr: 100,
      splitHalfRelativeDelta: 0.0,
      binSensitivityRelativeDelta: 0.0,
      nearCivilCollision: false,
      civilCollisionKind: null,
      candidatePeaks: const [],
      oscillatorId: osc,
    );

    ValidatedPeriodicPhaseEstimate phaseOf(double phi) {
      final w = 2 * math.pi / T;
      return ValidatedPeriodicPhaseEstimate(
        available: true,
        unavailableReason: null,
        eventCount: 60,
        thetaBar: phi,
        rBar: 0.95,
        periodSeconds: T,
        omega: w,
        oscillatorId: osc,
        referenceEpoch: '2024-01-01T00:00:00.000Z',
        referenceEpochMs: 1704067200000,
        phaseReference: PhaseReferenceV2(
          oscillatorId: osc,
          phaseRadians: phi,
          phaseClass: WavePhaseClassV2.validatedPeriodic,
          timeBasis: WavePhaseTimeBasisV2.utc,
          periodicityStatus: WavePeriodicityStatusV2.ok,
          periodSeconds: T,
          omega: w,
          referenceEpoch: '2024-01-01T00:00:00.000Z',
          source: ValidatedPeriodicPhaseBinderContract.sourceId,
        ),
        omegaStatus: ActivitySpectralOmegaStatus.ok,
      );
    }

    double pearson(List<double> xs, List<double> ys) {
      expect(xs.length, ys.length);
      final n = xs.length;
      if (n < 3) return double.nan;
      final mx = xs.reduce((a, b) => a + b) / n;
      final my = ys.reduce((a, b) => a + b) / n;
      var num = 0.0;
      var dx = 0.0;
      var dy = 0.0;
      for (var i = 0; i < n; i++) {
        final a = xs[i] - mx;
        final b = ys[i] - my;
        num += a * b;
        dx += a * a;
        dy += b * b;
      }
      final den = math.sqrt(dx * dy);
      if (den <= 1e-15) return double.nan;
      return num / den;
    }

    final cases = <Map<String, dynamic>>[];

    void addPair({
      required String id,
      required String family,
      required Map<String, double> scoresA,
      required Map<String, double> scoresB,
      required double phiA,
      required double phiB,
      required double levelA,
      required double levelB,
    }) {
      final s = structural.compareMeasuredPresence(
        a: profile(scoresA),
        b: profile(scoresB),
      );
      final w = wave.compare(
        omegaA: omegaEst,
        phaseA: phaseOf(phiA),
        activityLevelA: levelA,
        omegaB: omegaEst,
        phaseB: phaseOf(phiB),
        activityLevelB: levelB,
      );
      expect(s.available, isTrue);
      expect(w.available, isTrue);
      cases.add({
        'id': id,
        'family': family,
        'D_structural': s.combinedDistance,
        'phase_alignment': w.phaseAlignment,
        'activity_level_gap': w.activityLevelGap,
        'activity_level_A': w.activityLevelA,
        'activity_level_B': w.activityLevelB,
        'delta_phi': w.deltaPhi,
        'signals_combined': false,
      });
    }

    // Independent generative families (wave ⊥ structural by construction).
    for (var i = 0; i < 120; i++) {
      final a = randProfile();
      final b = randProfile();
      addPair(
        id: 'indep_$i',
        family: 'independent',
        scoresA: a,
        scoresB: b,
        phiA: rng.nextDouble() * 2 * math.pi - math.pi,
        phiB: rng.nextDouble() * 2 * math.pi - math.pi,
        levelA: 0.2 + rng.nextDouble() * 2.0,
        levelB: 0.2 + rng.nextDouble() * 2.0,
      );
    }

    // Structurally close, intentionally phase-misaligned.
    for (var i = 0; i < 20; i++) {
      final a = randProfile();
      final b = shiftProfile(a, delta: 0.02 + rng.nextDouble() * 0.03);
      addPair(
        id: 'close_misaligned_$i',
        family: 'struct_close_phase_misaligned',
        scoresA: a,
        scoresB: b,
        phiA: 0.0,
        phiB: math.pi * (0.85 + 0.15 * rng.nextDouble()),
        levelA: 1.0,
        levelB: 1.05 + rng.nextDouble() * 0.1,
      );
    }

    // Structurally far, intentionally phase-aligned.
    for (var i = 0; i < 20; i++) {
      final a = {
        ...{for (final id in iq) id: 0.15},
        ...{for (final id in eq) id: 0.2},
        ...{for (final id in freq) id: 0.15},
      };
      final b = {
        ...{for (final id in iq) id: 0.85},
        ...{for (final id in eq) id: 0.85},
        ...{for (final id in freq) id: 0.9},
      };
      // Small jitter so pairs aren't identical.
      final aj = shiftProfile(a, delta: 0.02 * rng.nextDouble());
      final bj = shiftProfile(b, delta: 0.02 * rng.nextDouble());
      addPair(
        id: 'far_aligned_$i',
        family: 'struct_far_phase_aligned',
        scoresA: aj,
        scoresB: bj,
        phiA: 0.4 + 0.05 * rng.nextDouble(),
        phiB: 0.4 + 0.05 * rng.nextDouble(),
        levelA: 0.5 + rng.nextDouble(),
        levelB: 1.5 + rng.nextDouble(),
      );
    }

    // Structurally close and phase-aligned (agreement).
    for (var i = 0; i < 15; i++) {
      final a = randProfile();
      final b = shiftProfile(a, delta: 0.01 + rng.nextDouble() * 0.02);
      final phi = rng.nextDouble() * 2 * math.pi - math.pi;
      addPair(
        id: 'close_aligned_$i',
        family: 'struct_close_phase_aligned',
        scoresA: a,
        scoresB: b,
        phiA: phi,
        phiB: phi + (rng.nextDouble() - 0.5) * 0.05,
        levelA: 1.0,
        levelB: 1.0 + rng.nextDouble() * 0.05,
      );
    }

    List<double> col(String key, {String? family}) => [
          for (final c in cases)
            if (family == null || c['family'] == family)
              if (c[key] is num) (c[key] as num).toDouble(),
        ];

    final dAll = col('D_structural');
    final pAll = col('phase_alignment');
    final gAll = col('activity_level_gap');

    final corrDP = pearson(dAll, pAll);
    final corrDG = pearson(dAll, gAll);
    final corrPG = pearson(pAll, gAll);

    final indepD = col('D_structural', family: 'independent');
    final indepP = col('phase_alignment', family: 'independent');
    final indepG = col('activity_level_gap', family: 'independent');
    final corrIndepDP = pearson(indepD, indepP);
    final corrIndepDG = pearson(indepD, indepG);
    final corrIndepPG = pearson(indepP, indepG);

    // Contradiction thresholds (relative within sample).
    final dSorted = [...dAll]..sort();
    final dLow = dSorted[(dSorted.length * 0.25).floor()];
    final dHigh = dSorted[(dSorted.length * 0.75).floor()];

    final closeMisaligned = [
      for (final c in cases)
        if (c['family'] == 'struct_close_phase_misaligned' ||
            ((c['D_structural'] as num) <= dLow &&
                (c['phase_alignment'] as num) < 0.0))
          c,
    ];
    final farAligned = [
      for (final c in cases)
        if (c['family'] == 'struct_far_phase_aligned' ||
            ((c['D_structural'] as num) >= dHigh &&
                (c['phase_alignment'] as num) > 0.85))
          c,
    ];

    double mean(List<double> xs) =>
        xs.isEmpty ? double.nan : xs.reduce((a, b) => a + b) / xs.length;

    // Soft harness asserts — analysis health, not production change.
    expect(cases.length, greaterThan(100));
    // Independent generation ⇒ near-zero structural↔phase correlation.
    expect(corrIndepDP.abs(), lessThan(0.25));
    expect(corrIndepDG.abs(), lessThan(0.25));
    // Planted contradiction families exist and behave as intended.
    final plantedCloseMis = [
      for (final c in cases)
        if (c['family'] == 'struct_close_phase_misaligned') c,
    ];
    final plantedFarAlign = [
      for (final c in cases)
        if (c['family'] == 'struct_far_phase_aligned') c,
    ];
    expect(plantedCloseMis, isNotEmpty);
    expect(plantedFarAlign, isNotEmpty);
    expect(
      mean([
        for (final c in plantedCloseMis) (c['phase_alignment'] as num).toDouble(),
      ]),
      lessThan(-0.5),
    );
    expect(
      mean([
        for (final c in plantedFarAlign) (c['phase_alignment'] as num).toDouble(),
      ]),
      greaterThan(0.9),
    );
    expect(
      mean([
        for (final c in plantedCloseMis) (c['D_structural'] as num).toDouble(),
      ]),
      lessThan(
        mean([
          for (final c in plantedFarAlign)
            (c['D_structural'] as num).toDouble(),
        ]),
      ),
    );

    final phaseAddsIndependentSignal = corrIndepDP.abs() < 0.25 &&
        plantedCloseMis.isNotEmpty &&
        plantedFarAlign.isNotEmpty;

    final findings = <String>[
      'Independent pairs: corr(D_structural, phase_alignment)=$corrIndepDP; '
          'corr(D_structural, activity_level_gap)=$corrIndepDG; '
          'corr(phase_alignment, activity_level_gap)=$corrIndepPG.',
      'All pairs (incl. planted): corr(D,phase)=$corrDP, corr(D,gap)=$corrDG, '
          'corr(phase,gap)=$corrPG.',
      'Structurally close but phase-misaligned planted n=${plantedCloseMis.length}; '
          'mean phase_alignment=${mean([
            for (final c in plantedCloseMis)
              (c['phase_alignment'] as num).toDouble(),
          ])}.',
      'Structurally far but phase-aligned planted n=${plantedFarAlign.length}; '
          'mean phase_alignment=${mean([
            for (final c in plantedFarAlign)
              (c['phase_alignment'] as num).toDouble(),
          ])}.',
      'Signals were never combined; no weights invented.',
      phaseAddsIndependentSignal
          ? 'phase_alignment adds useful independent signal vs D_structural.'
          : 'phase_alignment does not clearly add independent signal in this harness.',
    ];

    final recommendation = phaseAddsIndependentSignal
        ? 'Keep D_structural, phase_alignment, and activity_level_gap as '
            'separate shadow diagnostics. Do not fuse into one score before a '
            'quantum-inspired layer. Next: real-thread shadow joint histograms; '
            'still no Discover weights.'
        : 'Revisit generative assumptions; do not fuse signals.';

    final report = {
      'title': 'Structural vs Global Wave Signals — synthetic shadow comparison',
      'shadow_only': true,
      'signals_combined': false,
      'weights_invented': false,
      'affects_discover_ranking': false,
      'persona_enabled': false,
      'rvi_enabled': false,
      'density_matrix_enabled': false,
      'rng_seed': 23,
      'case_count': cases.length,
      'd_structural_definition':
          'canonical_20d_group_normalized_shadow_distance_v1 combined_distance',
      'phase_alignment_definition': 'cos(delta_phi) via GlobalActivityPeriodicResonance',
      'activity_level_gap_definition': '|A_u - A_v|',
      'methodology': {
        'independent_pairs': 120,
        'planted_struct_close_phase_misaligned': 20,
        'planted_struct_far_phase_aligned': 20,
        'planted_struct_close_phase_aligned': 15,
        'note':
            'Wave phase/levels sampled independently of 20D scores except in planted families designed to create contradictions.',
      },
      'correlations': {
        'independent': {
          'D_vs_phase_alignment': corrIndepDP,
          'D_vs_activity_level_gap': corrIndepDG,
          'phase_alignment_vs_activity_level_gap': corrIndepPG,
        },
        'all_pairs': {
          'D_vs_phase_alignment': corrDP,
          'D_vs_activity_level_gap': corrDG,
          'phase_alignment_vs_activity_level_gap': corrPG,
        },
      },
      'thresholds': {
        'D_low_quartile': dLow,
        'D_high_quartile': dHigh,
      },
      'contradiction_counts': {
        'struct_close_phase_misaligned_examples': closeMisaligned.length,
        'struct_far_phase_aligned_examples': farAligned.length,
      },
      'contradiction_examples': {
        'struct_close_phase_misaligned': [
          for (final c in plantedCloseMis.take(5))
            {
              'id': c['id'],
              'D_structural': c['D_structural'],
              'phase_alignment': c['phase_alignment'],
              'activity_level_gap': c['activity_level_gap'],
            },
        ],
        'struct_far_phase_aligned': [
          for (final c in plantedFarAlign.take(5))
            {
              'id': c['id'],
              'D_structural': c['D_structural'],
              'phase_alignment': c['phase_alignment'],
              'activity_level_gap': c['activity_level_gap'],
            },
        ],
      },
      'redundancy_analysis': {
        'D_and_phase_redundant': corrIndepDP.abs() > 0.7,
        'D_and_gap_redundant': corrIndepDG.abs() > 0.7,
        'phase_and_gap_redundant': corrIndepPG.abs() > 0.7,
        'note':
            'Under independent generation, near-zero correlation ⇒ not redundant. '
            'Planted families prove the signals can contradict.',
      },
      'phase_adds_useful_independent_signal': phaseAddsIndependentSignal,
      'findings': findings,
      'recommendation': recommendation,
      'cases': cases,
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File(
      'docs/matching/reports/structural_vs_global_wave_signals_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(report),
    );
    expect(outFile.existsSync(), isTrue);
  });
}
