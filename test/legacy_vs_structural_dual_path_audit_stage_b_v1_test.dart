import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_group_normalized_shadow.dart';

/// Stage B dual-path shadow audit:
/// legacy [CompatibilityScoring] vs group-normalized 20D structural distance.
///
/// Offline / debug only. Does **not** change Discover ranking or UI.
/// No fusion weights, temporal, QI, Persona, or RVI.
///
/// Real Discover cohort: **unavailable in this workspace** — see report
/// `data_source.real_discover_dataset_available = false`. Synthetic results
/// are labeled separately and must not be treated as migration evidence alone.
void main() {
  test('stage_b legacy vs structural dual-path audit report', () {
    const structural = Canonical20dGroupNormalizedShadowMatcher();
    final rng = math.Random(77);

    final iq = Canonical20dGroupNormalizedShadowContract.iqDimensionIds;
    final eq = Canonical20dGroupNormalizedShadowContract.eqDimensionIds;
    final freq =
        Canonical20dGroupNormalizedShadowContract.frequencyDimensionIds;
    final all = [...iq, ...eq, ...freq];

    // Legacy Frequency 6D keys ↔ canonical Frequency ids (synthetic mirror only).
    const legacyFreqKeys = CompatibilityScoring.frequencyDimensionKeys;
    final canonToLegacyFreq = <String, String>{
      'depth_preference': 'depth',
      'social_energy': 'socialEnergy',
      'spontaneity': 'spontaneity',
      'stability': 'stability',
      'disclosure_pace': 'emotionalOpenness',
      'communication_pace': 'conversationPace',
    };
    expect(freq.length, 6);
    for (final id in freq) {
      expect(canonToLegacyFreq.containsKey(id), isTrue, reason: id);
      expect(legacyFreqKeys.contains(canonToLegacyFreq[id]), isTrue);
    }

    // --- Real-data probe (explicit) ---
    final realProbe = _probeRealDiscoverDataset();
    expect(realProbe['available'], isFalse);

    // --- Synthetic Discover-eligible cohort ---
    Map<String, double> fillAll(double v) => {for (final id in all) id: v};

    Map<String, double> randScores({
      double center = 0.5,
      double spread = 0.35,
    }) {
      return {
        for (final id in all)
          id: (center + (rng.nextDouble() - 0.5) * 2 * spread).clamp(0.05, 0.95),
      };
    }

    Map<String, double> shiftModule(
      Map<String, double> base, {
      required Iterable<String> dims,
      required double delta,
    }) {
      return {
        for (final id in all)
          id: dims.contains(id)
              ? (base[id]! + delta).clamp(0.05, 0.95)
              : base[id]!,
      };
    }

    Map<String, double> legacyFreqFromCanon(Map<String, double> scores) {
      return {
        for (final id in freq)
          if (scores.containsKey(id)) canonToLegacyFreq[id]!: scores[id]!,
      };
    }

    double meanOf(Map<String, double> scores, Iterable<String> dims) {
      final vals = [for (final id in dims) if (scores[id] != null) scores[id]!];
      if (vals.isEmpty) return double.nan;
      return vals.reduce((a, b) => a + b) / vals.length;
    }

    String bandFromMean01(double m) {
      // CompatibilityScoring bands use ~0–100; H/M/L via ArchetypeCalculator.
      final n = m * 100.0;
      if (n >= 67) return 'H';
      if (n >= 34) return 'M';
      return 'L';
    }

    Map<String, dynamic> legacyUserMap({
      required Map<String, double> scores20d,
      required String category,
      required String archetype,
      List<String> interests = const ['music', 'travel'],
      DateTime? lastActive,
      bool includeIqEq = true,
      bool includeFreqVector = true,
      int? freqDimCap,
    }) {
      final fv = legacyFreqFromCanon(scores20d);
      Map<String, double>? vector;
      if (includeFreqVector) {
        if (freqDimCap != null && freqDimCap < fv.length) {
          vector = {
            for (final e in fv.entries.take(freqDimCap)) e.key: e.value,
          };
        } else {
          vector = fv;
        }
      }
      return {
        'category': category,
        'archetype': archetype,
        if (includeIqEq) 'iq_normalized': meanOf(scores20d, iq) * 100.0,
        if (includeIqEq) 'eq_normalized': meanOf(scores20d, eq) * 100.0,
        if (vector != null) 'frequency_vector': vector,
        'frequency_type': 'Balanced Frequency',
        'frequency_tags': const <String>['steady', 'curious'],
        'interests': interests,
        'last_active_at': lastActive ?? DateTime.utc(2024, 6, 1),
      };
    }

    Canonical20dShadowSubject subject(
      Map<String, double> scores, {
      Set<String>? drop,
    }) {
      final measured = {
        for (final e in scores.entries)
          if (drop == null || !drop.contains(e.key)) e.key: e.value,
      };
      return Canonical20dShadowSubject(
        measuredScores: measured,
        evidenceCounts: const {},
      );
    }

    /// Discover-eligible synthetic user (mirrors DiscoverService local filters).
    bool discoverEligible({
      required bool discoverEligibleFlag,
      required bool active,
      required bool profileCompleted,
      required bool testCompleted,
      required bool hasPhoto,
      required bool swiped,
      required bool blocked,
      required bool isSelf,
    }) {
      if (isSelf) return false;
      if (!discoverEligibleFlag) return false;
      if (!active) return false;
      if (!profileCompleted || !testCompleted) return false;
      if (!hasPhoto) return false;
      if (swiped || blocked) return false;
      return true;
    }

    final viewerScores = fillAll(0.45);
    final viewerLegacy = legacyUserMap(
      scores20d: viewerScores,
      category: 'HH',
      archetype: 'Harmonic Connector',
      lastActive: DateTime.utc(2024, 6, 15),
    );
    final viewerSubject = subject(viewerScores);

    final candidates = <_SynthUser>[];

    void addCandidate({
      required String id,
      required String family,
      required Map<String, double> scores,
      String category = 'HH',
      String archetype = 'Harmonic Connector',
      List<String> interests = const ['music', 'travel'],
      DateTime? lastActive,
      bool includeIqEq = true,
      bool includeFreqVector = true,
      int? freqDimCap,
      Set<String>? dropDims,
      bool discoverEligibleFlag = true,
      bool active = true,
      bool profileCompleted = true,
      bool testCompleted = true,
      bool hasPhoto = true,
      bool swiped = false,
      bool blocked = false,
      bool isSelf = false,
    }) {
      candidates.add(
        _SynthUser(
          id: id,
          family: family,
          scores20d: scores,
          dropDims: dropDims,
          legacyMap: legacyUserMap(
            scores20d: scores,
            category: category,
            archetype: archetype,
            interests: interests,
            lastActive: lastActive,
            includeIqEq: includeIqEq,
            includeFreqVector: includeFreqVector,
            freqDimCap: freqDimCap,
          ),
          discoverEligible: discoverEligible(
            discoverEligibleFlag: discoverEligibleFlag,
            active: active,
            profileCompleted: profileCompleted,
            testCompleted: testCompleted,
            hasPhoto: hasPhoto,
            swiped: swiped,
            blocked: blocked,
            isSelf: isSelf,
          ),
        ),
      );
    }

    // Ineligible noise (must be excluded from audit pairs).
    addCandidate(
      id: 'inelig_not_flagged',
      family: 'ineligible',
      scores: randScores(),
      discoverEligibleFlag: false,
    );
    addCandidate(
      id: 'inelig_no_photo',
      family: 'ineligible',
      scores: randScores(),
      hasPhoto: false,
    );
    addCandidate(
      id: 'inelig_incomplete_profile',
      family: 'ineligible',
      scores: randScores(),
      profileCompleted: false,
    );
    addCandidate(
      id: 'inelig_swiped',
      family: 'ineligible',
      scores: randScores(),
      swiped: true,
    );
    addCandidate(
      id: 'inelig_blocked',
      family: 'ineligible',
      scores: randScores(),
      blocked: true,
    );
    addCandidate(
      id: 'inelig_self',
      family: 'ineligible',
      scores: Map.of(viewerScores),
      isSelf: true,
    );

    // Independent random eligible pairs (viewer vs each).
    for (var i = 0; i < 80; i++) {
      addCandidate(
        id: 'random_$i',
        family: 'random_eligible',
        scores: randScores(center: 0.45 + (rng.nextDouble() - 0.5) * 0.3),
        category: rng.nextBool() ? 'HH' : 'HL',
        archetype: rng.nextBool() ? 'Harmonic Connector' : 'Steady Companion',
        interests: rng.nextBool()
            ? const ['music', 'travel']
            : const ['coding', 'hiking'],
        lastActive: DateTime.utc(2024, 5, 1).add(Duration(days: rng.nextInt(40))),
      );
    }

    // Near-identical structural + legacy-friendly.
    for (var i = 0; i < 12; i++) {
      final near = {
        for (final id in all)
          id: (viewerScores[id]! + (rng.nextDouble() - 0.5) * 0.04)
              .clamp(0.05, 0.95),
      };
      addCandidate(
        id: 'near_$i',
        family: 'struct_near_legacy_high',
        scores: near,
        category: 'HH',
        archetype: 'Harmonic Connector',
      );
    }

    // Structurally far (IQ/EQ poles) but legacy Frequency + archetype aligned.
    for (var i = 0; i < 15; i++) {
      var far = Map<String, double>.from(viewerScores);
      far = shiftModule(far, dims: iq, delta: i.isEven ? 0.45 : -0.45);
      far = shiftModule(far, dims: eq, delta: i.isEven ? -0.45 : 0.45);
      // Keep Frequency close so legacy frequency_vector stays high.
      for (final id in freq) {
        far[id] = (viewerScores[id]! + (rng.nextDouble() - 0.5) * 0.05)
            .clamp(0.05, 0.95);
      }
      addCandidate(
        id: 'legacy_high_struct_far_$i',
        family: 'legacy_high_struct_far',
        scores: far,
        category: 'HH',
        archetype: 'Harmonic Connector',
        interests: const ['music', 'travel'],
        lastActive: DateTime.utc(2024, 6, 14),
      );
    }

    // Structurally close on 20D but legacy weak (sparse Frequency / mismatch).
    for (var i = 0; i < 15; i++) {
      final close = {
        for (final id in all)
          id: (viewerScores[id]! + (rng.nextDouble() - 0.5) * 0.06)
              .clamp(0.05, 0.95),
      };
      addCandidate(
        id: 'struct_close_legacy_low_$i',
        family: 'struct_close_legacy_low',
        scores: close,
        category: 'LL',
        archetype: 'Quiet Analyst',
        interests: const ['chess'],
        includeIqEq: false,
        freqDimCap: 2, // < minComparableFrequencyDimensions → legacy unavailable
        lastActive: DateTime.utc(2023, 1, 1),
      );
    }

    // Partial 20D coverage (missing modules / dims) — no imputation.
    for (var i = 0; i < 12; i++) {
      final base = randScores();
      final drop = <String>{
        ...iq.take(2),
        if (i.isEven) ...eq.take(3),
        if (i % 3 == 0) freq.first,
      };
      addCandidate(
        id: 'partial_20d_$i',
        family: 'partial_canonical_20d',
        scores: base,
        dropDims: drop,
        category: 'MH',
        archetype: 'Balanced Explorer',
      );
    }

    // Opposite Frequency but similar IQ/EQ means → structural mid, legacy low freq.
    for (var i = 0; i < 10; i++) {
      var opp = Map<String, double>.from(viewerScores);
      for (final id in freq) {
        opp[id] = (1.0 - viewerScores[id]!).clamp(0.05, 0.95);
      }
      addCandidate(
        id: 'freq_opposite_$i',
        family: 'freq_opposite',
        scores: opp,
        category: 'LH',
        archetype: 'Energetic Seeker',
        interests: const ['nightlife'],
      );
    }

    final eligible = candidates.where((c) => c.discoverEligible).toList();
    expect(eligible.length, greaterThan(50));
    expect(candidates.length - eligible.length, greaterThanOrEqualTo(5));

    final rows = <Map<String, dynamic>>[];
    for (final c in eligible) {
      final legacy = CompatibilityScoring.calculateCompatibility(
        me: viewerLegacy,
        candidate: c.legacyMap,
      );
      final struct = structural.compareMeasuredPresence(
        a: viewerSubject,
        b: subject(c.scores20d, drop: c.dropDims),
      );
      rows.add({
        'id': c.id,
        'family': c.family,
        'discover_eligible': true,
        'legacy_available': legacy.available,
        'legacy_score': legacy.scoreTotal,
        'legacy_label': legacy.label,
        'legacy_reason': legacy.reason,
        'legacy_comparable_freq_dims': legacy.comparableDimensionCount,
        'structural_available': struct.available,
        'D_structural': struct.combinedDistance,
        'structural_coverage': struct.totalCoverage,
        'structural_comparable_dims': struct.totalComparableDimensionCount,
        'iq_available': struct.iq.available,
        'eq_available': struct.eq.available,
        'frequency_module_available': struct.frequency.available,
        'iq_coverage': struct.iq.coverage,
        'eq_coverage': struct.eq.coverage,
        'frequency_coverage': struct.frequency.coverage,
        'data_kind': 'synthetic',
      });
    }

    final both = rows
        .where((r) => r['legacy_available'] == true && r['structural_available'] == true)
        .toList();
    final legacyOnly = rows
        .where((r) =>
            r['legacy_available'] == true && r['structural_available'] != true)
        .toList();
    final structuralOnly = rows
        .where((r) =>
            r['structural_available'] == true && r['legacy_available'] != true)
        .toList();
    final neither = rows
        .where((r) =>
            r['legacy_available'] != true && r['structural_available'] != true)
        .toList();

    double? pearson(List<double> xs, List<double> ys) {
      if (xs.length != ys.length || xs.length < 3) return null;
      final n = xs.length;
      final mx = xs.reduce((a, b) => a + b) / n;
      final my = ys.reduce((a, b) => a + b) / n;
      var nume = 0.0, dx = 0.0, dy = 0.0;
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

    double? spearman(List<double> xs, List<double> ys) {
      if (xs.length != ys.length || xs.length < 3) return null;
      List<double> ranks(List<double> v) {
        final idx = List.generate(v.length, (i) => i)
          ..sort((a, b) => v[a].compareTo(v[b]));
        final r = List<double>.filled(v.length, 0);
        var i = 0;
        while (i < idx.length) {
          var j = i;
          while (j + 1 < idx.length && v[idx[j + 1]] == v[idx[i]]) {
            j++;
          }
          final avg = (i + j) / 2.0 + 1.0;
          for (var k = i; k <= j; k++) {
            r[idx[k]] = avg;
          }
          i = j + 1;
        }
        return r;
      }

      return pearson(ranks(xs), ranks(ys));
    }

    Map<String, dynamic> distStats(List<double> xs) {
      if (xs.isEmpty) return {'n': 0};
      final s = List<double>.of(xs)..sort();
      double q(double p) {
        final i = ((s.length - 1) * p).round().clamp(0, s.length - 1);
        return s[i];
      }

      final mean = s.reduce((a, b) => a + b) / s.length;
      return {
        'n': s.length,
        'min': s.first,
        'p25': q(0.25),
        'median': q(0.50),
        'p75': q(0.75),
        'max': s.last,
        'mean': mean,
      };
    }

    final legacyScores =
        both.map((r) => (r['legacy_score'] as num).toDouble()).toList();
    final distances =
        both.map((r) => (r['D_structural'] as num).toDouble()).toList();
    final negDistances = [for (final d in distances) -d];

    // Viewer-centric ranking among both-available eligible candidates.
    final byLegacy = List<Map<String, dynamic>>.of(both)
      ..sort((a, b) =>
          ((b['legacy_score'] as num).toDouble())
              .compareTo((a['legacy_score'] as num).toDouble()));
    final byStruct = List<Map<String, dynamic>>.of(both)
      ..sort((a, b) =>
          ((a['D_structural'] as num).toDouble())
              .compareTo((b['D_structural'] as num).toDouble()));

    Map<String, int> rankMap(List<Map<String, dynamic>> ordered) {
      final m = <String, int>{};
      for (var i = 0; i < ordered.length; i++) {
        m[ordered[i]['id'] as String] = i + 1;
      }
      return m;
    }

    final legacyRank = rankMap(byLegacy);
    final structRank = rankMap(byStruct);

    Set<String> topIds(List<Map<String, dynamic>> ordered, int k) => {
          for (final r in ordered.take(k)) r['id'] as String,
        };

    double overlap(Set<String> a, Set<String> b) {
      if (a.isEmpty || b.isEmpty) return 0.0;
      return a.intersection(b).length / math.min(a.length, b.length);
    }

    final top5Legacy = topIds(byLegacy, 5);
    final top5Struct = topIds(byStruct, 5);
    final top10Legacy = topIds(byLegacy, 10);
    final top10Struct = topIds(byStruct, 10);

    // Major disagreements: |Δrank| large among both-available.
    final rankGaps = <Map<String, dynamic>>[];
    for (final r in both) {
      final id = r['id'] as String;
      final lr = legacyRank[id]!;
      final sr = structRank[id]!;
      final gap = (lr - sr).abs();
      rankGaps.add({
        'id': id,
        'family': r['family'],
        'legacy_rank': lr,
        'structural_rank': sr,
        'abs_rank_gap': gap,
        'legacy_score': r['legacy_score'],
        'D_structural': r['D_structural'],
        'structural_coverage': r['structural_coverage'],
      });
    }
    rankGaps.sort(
      (a, b) =>
          ((b['abs_rank_gap'] as num).toDouble())
              .compareTo((a['abs_rank_gap'] as num).toDouble()),
    );

    final nBoth = both.length;
    final highLegacy = both
        .where((r) => (r['legacy_score'] as num) >= 0.70)
        .toList();
    final farStruct = both
        .where((r) => (r['D_structural'] as num) >= 0.28)
        .toList();
    final closeStruct = both
        .where((r) => (r['D_structural'] as num) <= 0.12)
        .toList();
    final lowLegacy = both
        .where((r) => (r['legacy_score'] as num) <= 0.50)
        .toList();

    List<Map<String, dynamic>> summarizePairs(Iterable<Map<String, dynamic>> xs) =>
        [
          for (final r in xs.take(8))
            {
              'id': r['id'],
              'family': r['family'],
              'legacy_score': r['legacy_score'],
              'legacy_rank': legacyRank[r['id'] as String],
              'D_structural': r['D_structural'],
              'structural_rank': structRank[r['id'] as String],
              'structural_coverage': r['structural_coverage'],
            },
        ];

    final legacyHighStructFar = both.where((r) {
      final id = r['id'] as String;
      return (r['legacy_score'] as num) >= 0.70 &&
          (r['D_structural'] as num) >= 0.28 &&
          legacyRank[id]! <= math.max(15, (nBoth * 0.25).round()) &&
          structRank[id]! >= math.max(15, (nBoth * 0.55).round());
    }).toList();

    final structCloseLegacyLow = both.where((r) {
      final id = r['id'] as String;
      return (r['D_structural'] as num) <= 0.12 &&
          structRank[id]! <= math.max(15, (nBoth * 0.25).round()) &&
          (legacyRank[id]! >= math.max(15, (nBoth * 0.55).round()) ||
              (r['legacy_score'] as num) <= 0.55);
    }).toList();

    // Also include structural-available but legacy-unavailable close cases.
    final structCloseLegacyUnavailable = structuralOnly.where((r) {
      return (r['D_structural'] as num?) != null &&
          (r['D_structural'] as num) <= 0.12;
    }).toList();

    final coverages = rows
        .where((r) => r['structural_available'] == true)
        .map((r) => (r['structural_coverage'] as num).toDouble())
        .toList();
    final missingCoverage = {
      'eligible_pair_count': rows.length,
      'structural_available_count':
          rows.where((r) => r['structural_available'] == true).length,
      'structural_unavailable_count':
          rows.where((r) => r['structural_available'] != true).length,
      'legacy_available_count':
          rows.where((r) => r['legacy_available'] == true).length,
      'legacy_unavailable_count':
          rows.where((r) => r['legacy_available'] != true).length,
      'both_available_count': both.length,
      'legacy_only_count': legacyOnly.length,
      'structural_only_count': structuralOnly.length,
      'neither_available_count': neither.length,
      'structural_coverage_distribution': distStats(coverages),
      'partial_canonical_family_count':
          rows.where((r) => r['family'] == 'partial_canonical_20d').length,
      'note':
          'No imputation: missing canonical dims omitted; modules with zero shared dims unavailable.',
    };

    final correlations = {
      'n_both_available': both.length,
      'pearson_legacy_score_vs_D_structural': pearson(legacyScores, distances),
      'pearson_legacy_score_vs_neg_D_structural':
          pearson(legacyScores, negDistances),
      'spearman_legacy_score_vs_D_structural': spearman(legacyScores, distances),
      'spearman_legacy_score_vs_neg_D_structural':
          spearman(legacyScores, negDistances),
      'note':
          'Agreement implies negative Pearson(legacy, D) and positive Spearman(legacy, -D).',
    };

    final rankingOverlap = {
      'top5_overlap_jaccard_min': overlap(top5Legacy, top5Struct),
      'top5_legacy_ids': top5Legacy.toList()..sort(),
      'top5_structural_ids': top5Struct.toList()..sort(),
      'top5_intersection': top5Legacy.intersection(top5Struct).toList()..sort(),
      'top10_overlap_jaccard_min': overlap(top10Legacy, top10Struct),
      'top10_legacy_ids': top10Legacy.toList()..sort(),
      'top10_structural_ids': top10Struct.toList()..sort(),
      'top10_intersection':
          top10Legacy.intersection(top10Struct).toList()..sort(),
      'mean_abs_rank_gap': rankGaps.isEmpty
          ? null
          : rankGaps
                  .map((e) => (e['abs_rank_gap'] as num).toDouble())
                  .reduce((a, b) => a + b) /
              rankGaps.length,
      'median_abs_rank_gap': () {
        if (rankGaps.isEmpty) return null;
        final g = rankGaps
            .map((e) => (e['abs_rank_gap'] as num).toDouble())
            .toList()
          ..sort();
        return g[g.length ~/ 2];
      }(),
    };

    final migrationImplications = {
      'real_data_required_before_cutover': true,
      'synthetic_only_this_run': true,
      'fusion_weights_invented': false,
      'legacy_remains_live': true,
      'structural_status':
          Canonical20dGroupNormalizedShadowContract.policyStatus,
      'implications': [
        'Legacy and structural optimize different objectives (Frequency/archetype/recency blend vs group-normalized 20D MSE); moderate disagreement is expected.',
        'Planted legacy_high_struct_far cases show Discover can promote Frequency/archetype-aligned pairs that are far in IQ/EQ 20D space.',
        'Sparse Frequency makes legacy unavailable while structural can still rank close 20D neighbors — cutover must define eligibility when only one path is available.',
        'Stage B on real Discover-eligible pairs is still required before Stage C feature-flagged cutover.',
        'No fusion with temporal/QI/Persona/RVI in this audit.',
      ],
    };

    final report = {
      'title':
          'Stage B — Legacy CompatibilityScoring vs group-normalized 20D dual-path audit',
      'architecture_ref': 'qmatch_final_matching_architecture_v1',
      'stage': 'B',
      'shadow_only': true,
      'affects_discover_ranking': false,
      'affects_ui': false,
      'fusion_weights': false,
      'temporal_included': false,
      'qi_included': false,
      'persona_included': false,
      'rvi_included': false,
      'imputation': false,
      'legacy_scoring': 'CompatibilityScoring.calculateCompatibility',
      'structural_scoring':
          Canonical20dGroupNormalizedShadowContract.scoringVersion,
      'structural_policy_status':
          Canonical20dGroupNormalizedShadowContract.policyStatus,
      'data_source': {
        'real_discover_dataset_available': false,
        'real_discover_dataset_reason': realProbe['reason'],
        'real_results': null,
        'synthetic_sanity_audit': true,
        'synthetic_label':
            'SYNTHETIC_SANITY_ONLY — not a real Discover cohort; do not treat as cutover evidence',
        'rng_seed': 77,
        'discover_eligible_definition':
            'discover_eligible==true && active && profileCompleted && testCompleted && hasPhoto && !swiped && !blocked && !self (mirrors DiscoverService local filters)',
      },
      'coverage': {
        'synthetic_candidates_generated': candidates.length,
        'synthetic_ineligible_excluded':
            candidates.where((c) => !c.discoverEligible).length,
        'synthetic_eligible_pairs_vs_viewer': rows.length,
        ...missingCoverage,
      },
      'distributions': {
        'legacy_score_both_available': distStats(legacyScores),
        'D_structural_both_available': distStats(distances),
      },
      'correlations': correlations,
      'ranking_overlap': rankingOverlap,
      'disagreements': {
        'major_abs_rank_gap_top': rankGaps.take(12).toList(),
        'legacy_high_struct_far_count': legacyHighStructFar.length,
        'legacy_high_struct_far_examples':
            summarizePairs(legacyHighStructFar),
        'struct_close_legacy_low_count': structCloseLegacyLow.length,
        'struct_close_legacy_low_examples':
            summarizePairs(structCloseLegacyLow),
        'struct_close_legacy_unavailable_count':
            structCloseLegacyUnavailable.length,
        'struct_close_legacy_unavailable_examples': [
          for (final r in structCloseLegacyUnavailable.take(8))
            {
              'id': r['id'],
              'family': r['family'],
              'legacy_available': r['legacy_available'],
              'legacy_reason': r['legacy_reason'],
              'D_structural': r['D_structural'],
              'structural_coverage': r['structural_coverage'],
            },
        ],
        'thresholds': {
          'legacy_high': 0.70,
          // Relative to this synthetic cohort (max D≈0.32 when Frequency held close).
          'struct_far': 0.28,
          'struct_close': 0.12,
          'legacy_low': 0.50,
        },
        'high_legacy_pool_size': highLegacy.length,
        'far_struct_pool_size': farStruct.length,
        'close_struct_pool_size': closeStruct.length,
        'low_legacy_pool_size': lowLegacy.length,
      },
      'migration_implications': migrationImplications,
      'pairs': rows,
    };

    final outDir = Directory('docs/matching/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File(
      'docs/matching/reports/legacy_vs_structural_dual_path_audit_stage_b_v1.json',
    );
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(_jsonSafe(report)),
    );

    // Isolation: harness imports CompatibilityScoring + structural matcher only.
    final importLines = File(
      'test/legacy_vs_structural_dual_path_audit_stage_b_v1_test.dart',
    )
        .readAsLinesSync()
        .where((l) => l.trimLeft().startsWith('import '))
        .toList();
    expect(
      importLines.any((l) => l.contains('/features/discover/')),
      isFalse,
    );
    expect(
      importLines.any((l) => l.contains('persona')),
      isFalse,
    );
    expect(
      importLines.any((l) => l.contains('quantum_mixed_state')),
      isFalse,
    );
    expect(
      importLines.any((l) => l.contains('wave_state')),
      isFalse,
    );

    expect(both, isNotEmpty);
    expect(report['data_source'], isA<Map>());
    expect(
      (report['data_source'] as Map)['real_discover_dataset_available'],
      isFalse,
    );
    expect(
      (report['data_source'] as Map)['synthetic_sanity_audit'],
      isTrue,
    );
  });
}

class _SynthUser {
  _SynthUser({
    required this.id,
    required this.family,
    required this.scores20d,
    required this.legacyMap,
    required this.discoverEligible,
    this.dropDims,
  });

  final String id;
  final String family;
  final Map<String, double> scores20d;
  final Map<String, dynamic> legacyMap;
  final bool discoverEligible;
  final Set<String>? dropDims;
}

Map<String, dynamic> _probeRealDiscoverDataset() {
  final candidates = <String>[
    'docs/matching/reports/real_discover_eligible_pairs_v1.json',
    'docs/matching/fixtures/discover_eligible_pairs_v1.json',
    'test/fixtures/discover_eligible_real_pairs_v1.json',
    'assets/data/discover/eligible_pairs_v1.json',
  ];
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) {
      return {
        'available': true,
        'reason': 'Found $path',
        'path': path,
      };
    }
  }
  return {
    'available': false,
    'reason':
        'No usable real Discover-eligible pair export found in workspace (checked common fixture paths). Firestore live pull is out of scope for this offline audit.',
    'checked_paths': candidates,
  };
}

dynamic _jsonSafe(dynamic v) {
  if (v is double) {
    if (v.isNaN || v.isInfinite) return null;
    return v;
  }
  if (v is Map) {
    return {for (final e in v.entries) e.key.toString(): _jsonSafe(e.value)};
  }
  if (v is List) return [for (final e in v) _jsonSafe(e)];
  return v;
}
