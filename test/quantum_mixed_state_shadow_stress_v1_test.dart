import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/quantum_mixed_state_shadow.dart';

/// Offline synthetic stress for `quantum_mixed_state_shadow_v1`.
/// Does **not** change production code, fuse signals, or touch Discover/UI.
void main() {
  test('quantum_mixed_state_shadow_v1 synthetic stress report', () {
    const matcher = QuantumMixedStateShadowMatcher();
    final rng = math.Random(41);

    const osc = 'activity_spectral_global_activity_t43200s';
    const T = 43200.0;
    const epoch = '2024-01-01T00:00:00.000Z';

    QuantumMixedStatePhaseMember member(
      double phi, {
      String oscillatorId = osc,
      double? periodSeconds,
      double? omegaOverride,
      String referenceEpoch = epoch,
    }) {
      final p = periodSeconds ?? T;
      return QuantumMixedStatePhaseMember(
        phaseRadians: phi,
        oscillatorId: oscillatorId,
        omega: omegaOverride ?? (2 * math.pi / p),
        periodSeconds: p,
        referenceEpoch: referenceEpoch,
      );
    }

    List<QuantumMixedStatePhaseMember> ensemble(
      List<double> phis, {
      String oscillatorId = osc,
      double? periodSeconds,
      String referenceEpoch = epoch,
    }) =>
        [
          for (final p in phis)
            member(
              p,
              oscillatorId: oscillatorId,
              periodSeconds: periodSeconds,
              referenceEpoch: referenceEpoch,
            ),
        ];

    List<double> wrapPhases(List<double> raw) => [
          for (final p in raw) _wrapPi(p),
        ];

    /// Circular mean phase via atan2(Σsin, Σcos).
    double? meanPhase(List<double> phis) {
      if (phis.isEmpty) return null;
      var s = 0.0;
      var c = 0.0;
      for (final p in phis) {
        s += math.sin(p);
        c += math.cos(p);
      }
      if (s * s + c * c < 1e-18) return null; // undefined mean when canceled
      return math.atan2(s, c);
    }

    /// phase_alignment from mean phases: cos(Δφ̄). Null if either mean undefined.
    double? phaseAlignmentFromMeans(List<double> a, List<double> b) {
      final ma = meanPhase(a);
      final mb = meanPhase(b);
      if (ma == null || mb == null) return null;
      return math.cos(ma - mb);
    }

    double? circularSpread(List<double> phis) {
      if (phis.isEmpty) return null;
      var s = 0.0;
      var c = 0.0;
      for (final p in phis) {
        s += math.sin(p);
        c += math.cos(p);
      }
      final r = math.sqrt(s * s + c * c) / phis.length;
      return 1.0 - r; // 0 = perfectly concentrated
    }

    final cases = <Map<String, dynamic>>[];

    void addCase({
      required String id,
      required String family,
      required List<double> phasesA,
      required List<double> phasesB,
      List<QuantumMixedStatePhaseMember>? ensembleAOverride,
      List<QuantumMixedStatePhaseMember>? ensembleBOverride,
      Map<String, dynamic>? meta,
    }) {
      final aPh = wrapPhases(phasesA);
      final bPh = wrapPhases(phasesB);
      final ensA = ensembleAOverride ?? ensemble(aPh);
      final ensB = ensembleBOverride ?? ensemble(bPh);
      final result = matcher.compare(ensembleA: ensA, ensembleB: ensB);
      final pa = phaseAlignmentFromMeans(
        ensA.map((e) => e.phaseRadians).toList(),
        ensB.map((e) => e.phaseRadians).toList(),
      );
      cases.add({
        'id': id,
        'family': family,
        if (meta != null) ...meta,
        'ensemble_size_A': ensA.length,
        'ensemble_size_B': ensB.length,
        'spread_A': circularSpread(ensA.map((e) => e.phaseRadians).toList()),
        'spread_B': circularSpread(ensB.map((e) => e.phaseRadians).toList()),
        'phase_alignment_mean': pa,
        'available': result.available,
        'unavailable_reason': result.unavailableReason,
        'purity_A': result.purityA,
        'purity_B': result.purityB,
        'qi_mixed_fidelity': result.qiMixedFidelity,
        'qi_trace_distance': result.qiTraceDistance,
        'bloch_norm_A': result.blochA == null
            ? null
            : math.sqrt(result.blochA!.normSquared),
        'bloch_norm_B': result.blochB == null
            ? null
            : math.sqrt(result.blochB!.normSquared),
        'weight_policy_id': result.weightPolicyId,
        'shadow_only': true,
        'signals_fused': false,
      });
    }

    // --- identical stable phases ---
    for (var i = 0; i < 12; i++) {
      final phi = -math.pi + rng.nextDouble() * 2 * math.pi;
      final k = 2 + rng.nextInt(6);
      final phis = List.filled(k, phi);
      addCase(
        id: 'identical_stable_$i',
        family: 'identical_stable',
        phasesA: phis,
        phasesB: List.of(phis),
      );
    }

    // --- same mean phase, different phase spread ---
    for (var i = 0; i < 20; i++) {
      final mean = -math.pi + rng.nextDouble() * 2 * math.pi;
      final k = 4 + rng.nextInt(5);
      final sharp = List.generate(
        k,
        (_) => mean + (rng.nextDouble() - 0.5) * 0.05,
      );
      final wide = List.generate(
        k,
        (_) => mean + (rng.nextDouble() - 0.5) * (1.2 + rng.nextDouble()),
      );
      addCase(
        id: 'same_mean_diff_spread_$i',
        family: 'same_mean_diff_spread',
        phasesA: sharp,
        phasesB: wide,
        meta: {'planted_mean': mean},
      );
    }

    // --- same spread, different mean phase ---
    for (var i = 0; i < 20; i++) {
      final delta = rng.nextDouble() * math.pi;
      final spread = 0.15 + rng.nextDouble() * 0.9;
      final k = 4 + rng.nextInt(4);
      final base = -math.pi + rng.nextDouble() * 2 * math.pi;
      final a = List.generate(
        k,
        (_) => base + (rng.nextDouble() - 0.5) * spread,
      );
      final b = List.generate(
        k,
        (_) => base + delta + (rng.nextDouble() - 0.5) * spread,
      );
      addCase(
        id: 'same_spread_diff_mean_$i',
        family: 'same_spread_diff_mean',
        phasesA: a,
        phasesB: b,
        meta: {'planted_delta': delta, 'planted_spread_width': spread},
      );
    }

    // --- coherent vs dispersed ---
    for (var i = 0; i < 16; i++) {
      final mean = -math.pi + rng.nextDouble() * 2 * math.pi;
      final k = 4 + rng.nextInt(4);
      final coherent = List.filled(k, mean);
      // Near-uniform on circle → low purity.
      final dispersed = List.generate(
        k,
        (j) => -math.pi + (j + rng.nextDouble()) * (2 * math.pi / k),
      );
      addCase(
        id: 'coherent_vs_dispersed_$i',
        family: 'coherent_vs_dispersed',
        phasesA: coherent,
        phasesB: dispersed,
      );
    }

    // --- bimodal phase distributions ---
    for (var i = 0; i < 16; i++) {
      final m1 = -math.pi + rng.nextDouble() * 2 * math.pi;
      final gap = math.pi * (0.6 + 0.4 * rng.nextDouble()); // near opposite
      final m2 = m1 + gap;
      final kHalf = 2 + rng.nextInt(3);
      final a = [
        ...List.generate(kHalf, (_) => m1 + (rng.nextDouble() - 0.5) * 0.1),
        ...List.generate(kHalf, (_) => m2 + (rng.nextDouble() - 0.5) * 0.1),
      ];
      // B: bimodal with same modes or swapped amplitude ratio.
      final b = [
        ...List.generate(kHalf, (_) => m1 + (rng.nextDouble() - 0.5) * 0.1),
        ...List.generate(kHalf, (_) => m2 + (rng.nextDouble() - 0.5) * 0.1),
      ];
      addCase(
        id: 'bimodal_same_$i',
        family: 'bimodal',
        phasesA: a,
        phasesB: b,
        meta: {'mode_gap': gap},
      );
    }
    for (var i = 0; i < 12; i++) {
      final m1 = -math.pi + rng.nextDouble() * 2 * math.pi;
      final a = [
        ...List.filled(4, m1),
        ...List.filled(4, m1 + math.pi),
      ];
      final bMean = m1 + (rng.nextDouble() - 0.5) * math.pi;
      final b = List.filled(8, bMean); // unimodal vs bimodal
      addCase(
        id: 'bimodal_vs_unimodal_$i',
        family: 'bimodal_vs_unimodal',
        phasesA: a,
        phasesB: b,
      );
    }

    // --- opposite phase ensembles ---
    for (var i = 0; i < 12; i++) {
      final phi = -math.pi + rng.nextDouble() * 2 * math.pi;
      final k = 2 + rng.nextInt(5);
      final noise = rng.nextDouble() * 0.08;
      addCase(
        id: 'opposite_$i',
        family: 'opposite_phase',
        phasesA: List.generate(k, (_) => phi + (rng.nextDouble() - 0.5) * noise),
        phasesB: List.generate(
          k,
          (_) => phi + math.pi + (rng.nextDouble() - 0.5) * noise,
        ),
      );
    }

    // --- random multi-window ensembles ---
    for (var i = 0; i < 80; i++) {
      final kA = 2 + rng.nextInt(10);
      final kB = 2 + rng.nextInt(10);
      final a = List.generate(
        kA,
        (_) => -math.pi + rng.nextDouble() * 2 * math.pi,
      );
      final b = List.generate(
        kB,
        (_) => -math.pi + rng.nextDouble() * 2 * math.pi,
      );
      addCase(
        id: 'random_multi_$i',
        family: 'random_multi_window',
        phasesA: a,
        phasesB: b,
      );
    }

    // --- different ensemble sizes (same generative process) ---
    for (var i = 0; i < 16; i++) {
      final mean = -math.pi + rng.nextDouble() * 2 * math.pi;
      final width = 0.2 + rng.nextDouble() * 0.8;
      final kA = 2 + rng.nextInt(3);
      final kB = 8 + rng.nextInt(8);
      addCase(
        id: 'diff_size_$i',
        family: 'different_ensemble_sizes',
        phasesA: List.generate(
          kA,
          (_) => mean + (rng.nextDouble() - 0.5) * width,
        ),
        phasesB: List.generate(
          kB,
          (_) => mean + 0.4 + (rng.nextDouble() - 0.5) * width,
        ),
      );
    }

    // --- provenance rejection cases ---
    addCase(
      id: 'reject_k1',
      family: 'provenance_rejection',
      phasesA: [0.1],
      phasesB: [0.1, 0.2],
      meta: {'expected_reason': 'insufficient_ensemble'},
    );
    addCase(
      id: 'reject_empty',
      family: 'provenance_rejection',
      phasesA: const [],
      phasesB: [0.1, 0.2],
      ensembleAOverride: const [],
      meta: {'expected_reason': 'empty_ensemble'},
    );
    addCase(
      id: 'reject_oscillator_mismatch',
      family: 'provenance_rejection',
      phasesA: [0.0, 0.1],
      phasesB: [0.0, 0.1],
      ensembleBOverride: ensemble(
        [0.0, 0.1],
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: 36000,
      ),
      meta: {'expected_reason': 'provenance_mismatch'},
    );
    addCase(
      id: 'reject_epoch_mismatch',
      family: 'provenance_rejection',
      phasesA: [0.2, 0.3],
      phasesB: [0.2, 0.3],
      ensembleBOverride: ensemble(
        [0.2, 0.3],
        referenceEpoch: '2024-06-01T00:00:00.000Z',
      ),
      meta: {'expected_reason': 'provenance_mismatch'},
    );
    addCase(
      id: 'reject_inconsistent_ensemble',
      family: 'provenance_rejection',
      phasesA: [0.0, 0.1],
      phasesB: [0.0, 0.1],
      ensembleAOverride: [
        member(0.0),
        member(0.1, oscillatorId: 'other_osc', periodSeconds: 36000),
      ],
      meta: {'expected_reason': 'inconsistent_ensemble'},
    );

    // ---------- analysis ----------
    final available = cases.where((c) => c['available'] == true).toList();
    final rejected = cases.where((c) => c['available'] != true).toList();
    final withAlign = available
        .where((c) => c['phase_alignment_mean'] != null)
        .toList();

    final fidelities =
        available.map((c) => (c['qi_mixed_fidelity'] as num).toDouble()).toList()
          ..sort();
    final traces =
        available.map((c) => (c['qi_trace_distance'] as num).toDouble()).toList()
          ..sort();

    Map<String, dynamic> distStats(List<double> xs) {
      if (xs.isEmpty) {
        return {'n': 0};
      }
      final sorted = List<double>.of(xs)..sort();
      double q(double p) {
        final i = ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
        return sorted[i];
      }

      final mean = sorted.reduce((a, b) => a + b) / sorted.length;
      var varSum = 0.0;
      for (final x in sorted) {
        varSum += (x - mean) * (x - mean);
      }
      return {
        'n': sorted.length,
        'min': sorted.first,
        'p10': q(0.10),
        'p25': q(0.25),
        'median': q(0.50),
        'p75': q(0.75),
        'p90': q(0.90),
        'max': sorted.last,
        'mean': mean,
        'stdev': math.sqrt(varSum / sorted.length),
      };
    }

    double? pearson(List<double> xs, List<double> ys) {
      if (xs.length != ys.length || xs.length < 3) return null;
      final n = xs.length;
      final mx = xs.reduce((a, b) => a + b) / n;
      final my = ys.reduce((a, b) => a + b) / n;
      var nume = 0.0;
      var dx = 0.0;
      var dy = 0.0;
      for (var i = 0; i < n; i++) {
        final a = xs[i] - mx;
        final b = ys[i] - my;
        nume += a * b;
        dx += a * a;
        dy += b * b;
      }
      if (dx < 1e-18 || dy < 1e-18) return null;
      return nume / math.sqrt(dx * dy);
    }

    final align = <double>[];
    final fid = <double>[];
    final tr = <double>[];
    final purityMin = <double>[];
    final purityGap = <double>[];
    final spreadMax = <double>[];
    for (final c in withAlign) {
      align.add((c['phase_alignment_mean'] as num).toDouble());
      fid.add((c['qi_mixed_fidelity'] as num).toDouble());
      tr.add((c['qi_trace_distance'] as num).toDouble());
      final pa = (c['purity_A'] as num).toDouble();
      final pb = (c['purity_B'] as num).toDouble();
      purityMin.add(math.min(pa, pb));
      purityGap.add((pa - pb).abs());
      final sa = (c['spread_A'] as num?)?.toDouble() ?? 0.0;
      final sb = (c['spread_B'] as num?)?.toDouble() ?? 0.0;
      spreadMax.add(math.max(sa, sb));
    }

    // Pure-ish subset: both purities > 0.95 → expect F ≈ (1+cosΔ)/2
    final purePairs = withAlign.where((c) {
      final pa = (c['purity_A'] as num).toDouble();
      final pb = (c['purity_B'] as num).toDouble();
      return pa > 0.95 && pb > 0.95;
    }).toList();
    final pureAlign = purePairs
        .map((c) => (c['phase_alignment_mean'] as num).toDouble())
        .toList();
    final pureFid =
        purePairs.map((c) => (c['qi_mixed_fidelity'] as num).toDouble()).toList();
    final pureExpected = pureAlign.map((c) => 0.5 * (1.0 + c)).toList();
    var pureResidualRmse = 0.0;
    if (pureFid.isNotEmpty) {
      var s = 0.0;
      for (var i = 0; i < pureFid.length; i++) {
        final d = pureFid[i] - pureExpected[i];
        s += d * d;
      }
      pureResidualRmse = math.sqrt(s / pureFid.length);
    }

    // Same phase_alignment (±eps) but different fidelity
    const alignBin = 0.05;
    final sameAlignDiffFid = <Map<String, dynamic>>[];
    final byAlignBin = <int, List<Map<String, dynamic>>>{};
    for (final c in withAlign) {
      final a = (c['phase_alignment_mean'] as num).toDouble();
      final bin = (a / alignBin).round();
      byAlignBin.putIfAbsent(bin, () => []).add(c);
    }
    for (final entry in byAlignBin.entries) {
      final group = entry.value;
      if (group.length < 2) continue;
      final fids =
          group.map((c) => (c['qi_mixed_fidelity'] as num).toDouble()).toList();
      final fMin = fids.reduce(math.min);
      final fMax = fids.reduce(math.max);
      if (fMax - fMin < 0.08) continue;
      // pick extremes
      group.sort(
        (a, b) => ((a['qi_mixed_fidelity'] as num).toDouble())
            .compareTo((b['qi_mixed_fidelity'] as num).toDouble()),
      );
      sameAlignDiffFid.add({
        'align_bin_center': entry.key * alignBin,
        'n_in_bin': group.length,
        'fidelity_span': fMax - fMin,
        'low': _caseSummary(group.first),
        'high': _caseSummary(group.last),
      });
    }
    sameAlignDiffFid
        .sort((a, b) => (b['fidelity_span'] as num).compareTo(a['fidelity_span'] as num));

    // Similar fidelity (±eps) but different phase_alignment
    const fidBin = 0.05;
    final sameFidDiffAlign = <Map<String, dynamic>>[];
    final byFidBin = <int, List<Map<String, dynamic>>>{};
    for (final c in withAlign) {
      final f = (c['qi_mixed_fidelity'] as num).toDouble();
      final bin = (f / fidBin).round();
      byFidBin.putIfAbsent(bin, () => []).add(c);
    }
    for (final entry in byFidBin.entries) {
      final group = entry.value;
      if (group.length < 2) continue;
      final aligns =
          group.map((c) => (c['phase_alignment_mean'] as num).toDouble()).toList();
      final aMin = aligns.reduce(math.min);
      final aMax = aligns.reduce(math.max);
      if (aMax - aMin < 0.15) continue;
      group.sort(
        (a, b) => ((a['phase_alignment_mean'] as num).toDouble())
            .compareTo((b['phase_alignment_mean'] as num).toDouble()),
      );
      sameFidDiffAlign.add({
        'fidelity_bin_center': entry.key * fidBin,
        'n_in_bin': group.length,
        'alignment_span': aMax - aMin,
        'low_align': _caseSummary(group.first),
        'high_align': _caseSummary(group.last),
      });
    }
    sameFidDiffAlign.sort(
      (a, b) =>
          (b['alignment_span'] as num).compareTo(a['alignment_span'] as num),
    );

    // Undefined mean-phase alignment but available QI (maximally mixed means)
    final undefinedAlign = available
        .where((c) => c['phase_alignment_mean'] == null)
        .map(_caseSummary)
        .toList();

    // Family-level correlations / summaries
    final families = <String>{};
    for (final c in cases) {
      families.add(c['family'] as String);
    }
    final familyStats = <String, dynamic>{};
    for (final fam in families) {
      final sub = available.where((c) => c['family'] == fam).toList();
      final subAlign = sub.where((c) => c['phase_alignment_mean'] != null).toList();
      final fa = subAlign
          .map((c) => (c['phase_alignment_mean'] as num).toDouble())
          .toList();
      final ff = subAlign
          .map((c) => (c['qi_mixed_fidelity'] as num).toDouble())
          .toList();
      familyStats[fam] = {
        'available_n': sub.length,
        'with_phase_alignment_n': subAlign.length,
        'fidelity': distStats(
          sub
              .map((c) => (c['qi_mixed_fidelity'] as num).toDouble())
              .toList(),
        ),
        'corr_fidelity_vs_phase_alignment': pearson(fa, ff),
      };
    }

    // Provenance rejection check
    final rej = rejected.map((c) {
      return {
        'id': c['id'],
        'unavailable_reason': c['unavailable_reason'],
        'expected_reason': c['expected_reason'],
        'matched_expected': c['expected_reason'] == null ||
            c['expected_reason'] == c['unavailable_reason'],
      };
    }).toList();

    final corrFidAlign = pearson(align, fid);
    final corrTrAlign = pearson(align, tr);
    final corrFidPurityMin = pearson(fid, purityMin);
    final corrFidPurityGap = pearson(fid, purityGap);
    final corrFidSpreadMax = pearson(fid, spreadMax);

    // Residual of F after regressing on phase_alignment alone (simple linear).
    // F ≈ α + β * cosΔ; residual variance / total = independent fraction proxy.
    Map<String, dynamic> residualAnalysis() {
      if (align.length < 5 || corrFidAlign == null) {
        return {'ok': false};
      }
      final n = align.length;
      final mx = align.reduce((a, b) => a + b) / n;
      final my = fid.reduce((a, b) => a + b) / n;
      var sxx = 0.0;
      var sxy = 0.0;
      for (var i = 0; i < n; i++) {
        sxx += (align[i] - mx) * (align[i] - mx);
        sxy += (align[i] - mx) * (fid[i] - my);
      }
      final beta = sxx < 1e-18 ? 0.0 : sxy / sxx;
      final alpha = my - beta * mx;
      var ssTot = 0.0;
      var ssRes = 0.0;
      for (var i = 0; i < n; i++) {
        final pred = alpha + beta * align[i];
        ssTot += (fid[i] - my) * (fid[i] - my);
        ssRes += (fid[i] - pred) * (fid[i] - pred);
      }
      final r2 = ssTot < 1e-18 ? 1.0 : 1.0 - ssRes / ssTot;
      return {
        'ok': true,
        'linear_model': 'F ~ alpha + beta * phase_alignment_mean',
        'alpha': alpha,
        'beta': beta,
        'r2_fidelity_explained_by_phase_alignment': r2,
        'residual_variance_fraction': 1.0 - r2,
        'note':
            'Residual fraction is a lower-bound proxy for information not captured by mean-phase cos(Δ).',
      };
    }

    final residual = residualAnalysis();

    // Pathological / redundant observations
    final pathologies = <Map<String, dynamic>>[
      {
        'id': 'pure_state_reduces_to_half_one_plus_cos',
        'detail':
            'When both ensembles are nearly pure, qi_mixed_fidelity ≈ (1+phase_alignment)/2; RMSE=$pureResidualRmse on n=${purePairs.length}.',
        'redundant_with_phase_alignment': true,
      },
      {
        'id': 'identical_ensembles_always_fidelity_one',
        'detail':
            'Identical dispersed ensembles yield F=1 even when purity≈0.5; mean phase may be undefined.',
        'redundant_with_phase_alignment': false,
      },
      {
        'id': 'maximally_mixed_phase_alignment_undefined',
        'detail':
            'When Σe^{iφ}≈0, phase_alignment_mean is undefined while QI still returns purity/F/trace.',
        'count': undefinedAlign.length,
        'redundant_with_phase_alignment': false,
      },
    ];

    // Recommendation heuristic
    final residualFrac = (residual['residual_variance_fraction'] as num?)?.toDouble();
    final sameAlignSpanMax = sameAlignDiffFid.isEmpty
        ? 0.0
        : (sameAlignDiffFid.first['fidelity_span'] as num).toDouble();
    final keep =
        (residualFrac != null && residualFrac > 0.15) || sameAlignSpanMax > 0.15;
    final recommendation = {
      'keep_qi_layer_as_shadow_signal': keep,
      'promote_to_live_ranking': false,
      'fuse_with_phase_alignment': false,
      'rationale': keep
          ? 'Mixed-state fidelity varies materially at fixed mean-phase alignment when purity/spread differ; residual vs phase_alignment is non-trivial. Keep as separate shadow diagnostic, not fused.'
          : 'Fidelity is largely a monotone transform of mean-phase alignment on this synthetic mix; QI layer adds little independent information beyond purity diagnostics.',
      'use_purity_as_separate_diagnostic': true,
      'reject_for_discover': true,
    };

    final analysis = {
      'A_fidelity_distribution': distStats(fidelities),
      'A_trace_distance_distribution': distStats(traces),
      'B_correlation_with_phase_alignment': {
        'n_pairs_with_defined_mean_alignment': withAlign.length,
        'corr_qi_mixed_fidelity_vs_phase_alignment': corrFidAlign,
        'corr_qi_trace_distance_vs_phase_alignment': corrTrAlign,
        'pure_subset': {
          'n': purePairs.length,
          'corr_fidelity_vs_phase_alignment': pearson(pureAlign, pureFid),
          'rmse_vs_half_one_plus_cos': pureResidualRmse,
        },
      },
      'C_same_phase_alignment_different_fidelity': {
        'bin_width': alignBin,
        'bin_count_with_span_ge_0_08': sameAlignDiffFid.length,
        'max_fidelity_span': sameAlignSpanMax,
        'top_examples': sameAlignDiffFid.take(8).toList(),
      },
      'D_similar_fidelity_different_phase_alignment': {
        'bin_width': fidBin,
        'bin_count_with_span_ge_0_15': sameFidDiffAlign.length,
        'top_examples': sameFidDiffAlign.take(8).toList(),
      },
      'E_purity_spread_effects': {
        'corr_fidelity_vs_min_purity': corrFidPurityMin,
        'corr_fidelity_vs_purity_gap': corrFidPurityGap,
        'corr_fidelity_vs_max_circular_spread': corrFidSpreadMax,
        'note':
            'Holding mean phase fixed, higher purity mismatch / spread drives F below the pure-state (1+cosΔ)/2 curve via the sqrt((1-|r|^2)...) term and reduced |r|.',
      },
      'F_independent_information': {
        'linear_residual_vs_phase_alignment': residual,
        'undefined_mean_alignment_but_qi_available': undefinedAlign.take(10).toList(),
        'same_align_diff_fidelity_max_span': sameAlignSpanMax,
        'verdict': keep
            ? 'YES — mixed-state QI carries purity/spread geometry beyond cos(Δφ̄).'
            : 'WEAK — mostly redundant with mean-phase alignment on this draw.',
      },
      'G_pathological_redundant_cases': pathologies,
      'H_recommendation': recommendation,
      'family_stats': familyStats,
      'provenance_rejection_audit': {
        'rejected_n': rejected.length,
        'all_matched_expected': rej.every((r) => r['matched_expected'] == true),
        'cases': rej,
      },
    };

    final report = {
      'title': 'Quantum Mixed-State Shadow v1 — synthetic stress',
      'scoring_version': QuantumMixedStateShadowContract.scoringVersion,
      'policy_version': QuantumMixedStateShadowContract.policyVersion,
      'policy_status': QuantumMixedStateShadowContract.policyStatus,
      'shadow_only': true,
      'validated_shadow_research_signal':
          QuantumMixedStateShadowContract.validatedShadowResearchSignal,
      'specification_only_not_live':
          QuantumMixedStateShadowContract.specificationOnlyNotLive,
      'real_data_validation_pending':
          QuantumMixedStateShadowContract.realDataValidationPending,
      'signals_fused': false,
      'affects_discover_ranking': false,
      'persona_enabled': false,
      'rvi_enabled': false,
      'free_lambda': false,
      'ranking_weights_allowed': false,
      'pure_state_qi_as_separate_signal': false,
      'weight_policy_id': QuantumMixedStateShadowContract.weightPolicyId,
      'rng_seed': 41,
      'case_count': cases.length,
      'available_count': available.length,
      'rejected_count': rejected.length,
      'phase_alignment_definition':
          'cos(mean_phase_A - mean_phase_B) with circular mean atan2(Σsin,Σcos); null if resultant length ≈ 0',
      'comparisons': {
        'phase_alignment_mean': true,
        'purity_A': true,
        'purity_B': true,
        'qi_mixed_fidelity': true,
        'qi_trace_distance': true,
      },
      'analysis': analysis,
      'cases': cases,
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File(
      'docs/matching/reports/quantum_mixed_state_shadow_stress_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(_jsonSafe(report)),
    );

    // Hard assertions: no production bugs expected; provenance must reject.
    expect(available, isNotEmpty);
    expect(rej.every((r) => r['matched_expected'] == true), isTrue);
    expect(fidelities.first, greaterThanOrEqualTo(0.0));
    expect(fidelities.last, lessThanOrEqualTo(1.0));
    expect(traces.first, greaterThanOrEqualTo(0.0));
    expect(traces.last, lessThanOrEqualTo(1.0));
    // Sanity: identical_stable family should sit near F=1.
    final identicalFid = available
        .where((c) => c['family'] == 'identical_stable')
        .map((c) => (c['qi_mixed_fidelity'] as num).toDouble());
    expect(identicalFid.every((f) => f > 0.999), isTrue);
  });
}

double _wrapPi(double x) {
  var v = x;
  while (v <= -math.pi) {
    v += 2 * math.pi;
  }
  while (v > math.pi) {
    v -= 2 * math.pi;
  }
  return v;
}

Map<String, dynamic> _caseSummary(Map<String, dynamic> c) => {
      'id': c['id'],
      'family': c['family'],
      'phase_alignment_mean': c['phase_alignment_mean'],
      'purity_A': c['purity_A'],
      'purity_B': c['purity_B'],
      'qi_mixed_fidelity': c['qi_mixed_fidelity'],
      'qi_trace_distance': c['qi_trace_distance'],
      'spread_A': c['spread_A'],
      'spread_B': c['spread_B'],
    };

/// Replace NaN/Infinity so JSON encoding cannot fail.
dynamic _jsonSafe(dynamic v) {
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return v;
  }
  if (v is Map) {
    return {
      for (final e in v.entries) e.key.toString(): _jsonSafe(e.value),
    };
  }
  if (v is List) {
    return [for (final e in v) _jsonSafe(e)];
  }
  return v;
}
