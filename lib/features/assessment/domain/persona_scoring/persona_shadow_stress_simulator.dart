import 'dart:math' as math;

import 'canonical_persona_shadow_scorer.dart';
import 'persona_dimension_profile.dart';
import 'persona_prototype.dart';
import 'persona_shadow_input.dart';
import 'persona_shadow_result.dart';
import 'persona_shadow_scoring_config.dart';

/// Deterministic offline Persona shadow stress simulator (P2C-3A-3).
///
/// Aggregate telemetry only — no raw profile dumps, no live reveal.
class PersonaShadowStressSimulator {
  PersonaShadowStressSimulator({
    required this.scorer,
    required this.catalog,
    required this.config,
    this.seed = 20260809,
    this.generatorVersion = 'persona_shadow_stress_generator_v1',
  });

  static const String generatorVersionDefault =
      'persona_shadow_stress_generator_v1';

  final CanonicalPersonaShadowScorer scorer;
  final PersonaProfileCatalog catalog;
  final PersonaShadowScoringConfig config;
  final int seed;
  final String generatorVersion;

  List<String> get personaIds =>
      catalog.personas.map((p) => p.personaId).toList(growable: false);

  Map<String, int> _fullEvidence() => {
        for (final d in catalog.dimensionOrder) d: config.nMin(d),
      };

  PersonaShadowInput inputFor(
    Map<String, double> scores, {
    String owner = 'stress_sim',
    String bankLocaleTag = 'tr',
  }) {
    return PersonaShadowInput(
      dimensionScores: scores,
      source: PersonaShadowSourceEvidence(
        ownerUid: owner,
        iqCompleted: true,
        eqCompleted: true,
        frequencyCompleted: true,
        iqScoringPolicyVersion: 'iq_4d_uncalibrated_accuracy_v1',
        eqScoringPolicyVersion: 'eq_10d_uncalibrated_signed_evidence_v1',
        frequencyScoringPolicyVersion:
            'frequency_6d_uncalibrated_signed_evidence_v1',
        iqBankOrSessionVersion: 'iq_bank_${bankLocaleTag}_v1',
        eqBankOrSessionVersion: 'eq_bank_${bankLocaleTag}_v1',
        frequencyBankOrSessionVersion: 'frequency_bank_${bankLocaleTag}_v1',
        dimensionEvidenceCounts: _fullEvidence(),
      ),
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
    );
  }

  PersonaShadowResult score(Map<String, double> x, {String locale = 'tr'}) =>
      scorer.score(inputFor(x, bankLocaleTag: locale));

  /// Full P2C-3A-3 aggregate report (≥100k main distribution profiles).
  PersonaShadowStressReport runFull({
    int uniform = 22000,
    int centerHeavy = 15000,
    int moderateCenter = 15000,
    int extreme = 15000,
    int correlated = 15000,
    int neighborhoodPerPersona = 1000,
  }) {
    final rng = math.Random(seed);
    final families = <String, FamilyAccumulator>{
      'uniform': FamilyAccumulator(personaIds),
      'center_heavy': FamilyAccumulator(personaIds),
      'moderate_center': FamilyAccumulator(personaIds),
      'extreme': FamilyAccumulator(personaIds),
      'correlated': FamilyAccumulator(personaIds),
      'prototype_neighborhood': FamilyAccumulator(personaIds),
    };

    void absorb(String family, PersonaShadowResult r) {
      families[family]!.add(r);
    }

    for (var i = 0; i < uniform; i++) {
      absorb('uniform', score(_uniform(rng)));
    }
    for (var i = 0; i < centerHeavy; i++) {
      absorb('center_heavy', score(_centerHeavy(rng)));
    }
    for (var i = 0; i < moderateCenter; i++) {
      absorb('moderate_center', score(_moderateCenter(rng)));
    }
    for (var i = 0; i < extreme; i++) {
      absorb('extreme', score(_extreme(rng)));
    }
    for (var i = 0; i < correlated; i++) {
      absorb('correlated', score(_correlated(rng)));
    }

    final epsilons = [0.01, 0.03, 0.05, 0.10];
    final perEps = neighborhoodPerPersona ~/ epsilons.length;
    for (final p in catalog.personas) {
      for (final eps in epsilons) {
        for (var i = 0; i < perEps; i++) {
          absorb(
            'prototype_neighborhood',
            score(_neighborhood(p.targetVector, eps, rng)),
          );
        }
      }
    }

    final overall = FamilyAccumulator(personaIds);
    for (final f in families.values) {
      overall.merge(f);
    }

    final selfCenters = <String, Map<String, Object?>>{};
    var selfCenterFailures = 0;
    for (final p in catalog.personas) {
      final r = score(Map<String, double>.from(p.targetVector));
      final ok = r.primaryCandidateId == p.personaId;
      if (!ok) selfCenterFailures++;
      selfCenters[p.personaId] = {
        'primary': r.primaryCandidateId,
        'secondary': r.secondaryCandidateId,
        'd_primary': r.candidates.first.distance,
        'd_secondary': r.candidates[1].distance,
        'delta_d': r.top2DistanceMargin,
        'self_primary_ok': ok,
      };
    }

    final mid = score({for (final d in catalog.dimensionOrder) d: 0.5});
    final allHigh = score({for (final d in catalog.dimensionOrder) d: 1.0});
    final allLow = score({for (final d in catalog.dimensionOrder) d: 0.0});

    final localStability = <String, Map<String, Object?>>{};
    for (final eps in epsilons) {
      localStability['eps_$eps'] = _localStability(eps, drawsPerPersona: 40);
    }

    final midNeighborhood = <String, Map<String, Object?>>{};
    for (final scale in epsilons) {
      midNeighborhood['scale_$scale'] = _midpointNeighborhood(scale, n: 2000);
    }

    final pairwise = _pairwiseSeparation();
    final groupIsolation = {
      'frequency_dominant': _groupIsolation('frequency'),
      'eq_dominant': _groupIsolation('eq'),
      'iq_dominant': _groupIsolation('iq'),
    };

    final tr = score(_uniform(math.Random(seed ^ 0x11)), locale: 'tr');
    final en = score(_uniform(math.Random(seed ^ 0x11)), locale: 'en');
    // Same numeric profile for TR/EN bank tags:
    final xSame = _uniform(math.Random(99));
    final trSame = score(xSame, locale: 'tr');
    final enSame = score(xSame, locale: 'en');

    return PersonaShadowStressReport(
      seed: seed,
      generatorVersion: generatorVersion,
      scoringVersion: config.scoringVersion,
      prototypeVersion: catalog.personaProfileVersion,
      policyVersion: config.qualityPolicyVersion,
      configVersion: config.configVersion,
      sampleCounts: {
        'uniform': uniform,
        'center_heavy': centerHeavy,
        'moderate_center': moderateCenter,
        'extreme': extreme,
        'correlated': correlated,
        'prototype_neighborhood': 18 * epsilons.length * perEps,
        'overall': overall.n,
      },
      families: {
        for (final e in families.entries) e.key: e.value.snapshot(),
      },
      overall: overall.snapshot(),
      selfCenters: selfCenters,
      selfCenterFailureCount: selfCenterFailures,
      midpointExact: _rankingSnapshot(mid),
      allHigh: _rankingSnapshot(allHigh),
      allLow: _rankingSnapshot(allLow),
      localStability: localStability,
      midpointNeighborhood: midNeighborhood,
      pairwiseClosest: pairwise.$1,
      pairwiseFarthest: pairwise.$2,
      groupIsolation: groupIsolation,
      trEnInvariant: trSame.primaryCandidateId == enSame.primaryCandidateId &&
          trSame.secondaryCandidateId == enSame.secondaryCandidateId &&
          (trSame.top2DistanceMargin - enSame.top2DistanceMargin).abs() <
              1e-15 &&
          _mapEq(trSame.allPersonaDistances, enSame.allPersonaDistances),
      determinismOk: () {
        final a = score(xSame);
        final b = score(xSame);
        return a.primaryCandidateId == b.primaryCandidateId &&
            a.secondaryCandidateId == b.secondaryCandidateId &&
            (a.top2DistanceMargin - b.top2DistanceMargin).abs() < 1e-15;
      }(),
      unusedSmoke: {
        'tr_primary': tr.primaryCandidateId,
        'en_primary': en.primaryCandidateId
      },
    );
  }

  Map<String, Object?> _rankingSnapshot(PersonaShadowResult r) => {
        'primary': r.primaryCandidateId,
        'secondary': r.secondaryCandidateId,
        'delta_d': r.top2DistanceMargin,
        'distance_min': r.candidates.first.distance,
        'distance_max': r.candidates.last.distance,
        'ordered': [
          for (var i = 0; i < r.candidates.length; i++)
            {
              'persona': r.candidates[i].personaId,
              'd': r.candidates[i].distance,
              'rank': i + 1,
            },
        ],
      };

  Map<String, double> _uniform(math.Random rng) => {
        for (final d in catalog.dimensionOrder) d: rng.nextDouble(),
      };

  Map<String, double> _centerHeavy(math.Random rng) => {
        for (final d in catalog.dimensionOrder)
          d: (0.5 + (rng.nextDouble() - 0.5) * 0.12).clamp(0.0, 1.0),
      };

  Map<String, double> _moderateCenter(math.Random rng) => {
        for (final d in catalog.dimensionOrder)
          d: (0.5 + (rng.nextDouble() - 0.5) * 0.40).clamp(0.0, 1.0),
      };

  Map<String, double> _extreme(math.Random rng) => {
        for (final d in catalog.dimensionOrder)
          d: rng.nextBool()
              ? rng.nextDouble() * 0.2
              : 0.8 + rng.nextDouble() * 0.2,
      };

  /// Synthetic positive within-group correlation (diagnostic assumption only).
  Map<String, double> _correlated(math.Random rng) {
    final out = <String, double>{};
    for (final g in const ['iq', 'eq', 'frequency']) {
      final base = rng.nextDouble();
      for (final d in PersonaDimensionIds.dimsOf(g)) {
        out[d] = (base + (rng.nextDouble() - 0.5) * 0.25).clamp(0.0, 1.0);
      }
    }
    return out;
  }

  Map<String, double> _neighborhood(
    Map<String, double> center,
    double eps,
    math.Random rng,
  ) =>
      {
        for (final d in catalog.dimensionOrder)
          d: (center[d]! + (rng.nextDouble() - 0.5) * 2 * eps).clamp(0.0, 1.0),
      };

  Map<String, Object?> _localStability(double eps,
      {required int drawsPerPersona}) {
    final rng = math.Random(seed ^ eps.hashCode);
    var retainPrimary = 0;
    var retainTop2 = 0;
    final margins = <double>[];
    final competitor = <String, int>{};
    var n = 0;
    for (final p in catalog.personas) {
      for (var i = 0; i < drawsPerPersona; i++) {
        final r = score(_neighborhood(p.targetVector, eps, rng));
        n++;
        if (r.primaryCandidateId == p.personaId) retainPrimary++;
        if (r.primaryCandidateId == p.personaId ||
            r.secondaryCandidateId == p.personaId) {
          retainTop2++;
        }
        margins.add(r.top2DistanceMargin);
        final rival = r.primaryCandidateId == p.personaId
            ? r.secondaryCandidateId
            : r.primaryCandidateId;
        competitor[rival] = (competitor[rival] ?? 0) + 1;
      }
    }
    margins.sort();
    String? topRival;
    var topCount = -1;
    for (final e in competitor.entries) {
      if (e.value > topCount) {
        topCount = e.value;
        topRival = e.key;
      }
    }
    return {
      'epsilon': eps,
      'n': n,
      'fraction_same_primary': retainPrimary / n,
      'fraction_in_top2': retainTop2 / n,
      'delta_d': _percentiles(margins),
      'most_common_competitor': topRival,
    };
  }

  Map<String, Object?> _midpointNeighborhood(double scale, {required int n}) {
    final rng = math.Random(seed ^ (scale * 1000).round());
    final acc = FamilyAccumulator(personaIds);
    final mid = {for (final d in catalog.dimensionOrder) d: 0.5};
    for (var i = 0; i < n; i++) {
      acc.add(score(_neighborhood(mid, scale, rng)));
    }
    return acc.snapshot();
  }

  Map<String, Object?> _groupIsolation(String focusGroup) {
    final rng = math.Random(seed ^ focusGroup.hashCode);
    final acc = FamilyAccumulator(personaIds);
    for (var i = 0; i < 3000; i++) {
      final x = <String, double>{};
      for (final g in const ['iq', 'eq', 'frequency']) {
        for (final d in PersonaDimensionIds.dimsOf(g)) {
          if (g == focusGroup) {
            x[d] = rng.nextDouble();
          } else {
            x[d] = (0.5 + (rng.nextDouble() - 0.5) * 0.08).clamp(0.0, 1.0);
          }
        }
      }
      acc.add(score(x));
    }
    return {
      'focus_group': focusGroup,
      'intended_weight': focusGroup == 'iq'
          ? 0.15
          : focusGroup == 'eq'
              ? 0.30
              : 0.55,
      'telemetry': acc.snapshot(),
      'note': 'synthetic isolation; weights unchanged',
    };
  }

  (List<Map<String, Object?>>, List<Map<String, Object?>>)
      _pairwiseSeparation() {
    final pairs = <Map<String, Object?>>[];
    for (var i = 0; i < catalog.personas.length; i++) {
      for (var j = i + 1; j < catalog.personas.length; j++) {
        final a = catalog.personas[i];
        final b = catalog.personas[j];
        // Diagnostic: score A's center, read D to B and vice versa mean.
        final ra = score(Map<String, double>.from(a.targetVector));
        final rb = score(Map<String, double>.from(b.targetVector));
        final dab = ra.allPersonaDistances[b.personaId]!;
        final dba = rb.allPersonaDistances[a.personaId]!;
        final sep = 0.5 * (dab + dba);
        final ca = ra.candidates.firstWhere((c) => c.personaId == b.personaId);
        pairs.add({
          'persona_a': a.personaId,
          'persona_b': b.personaId,
          'separation': sep,
          'simulation_diagnostic_only': true,
          'iq_contrib': 0.5 *
              ((ca.levelByGroup['iq'] ?? 0) + (ca.shapeByGroup['iq'] ?? 0)),
          'eq_contrib': 0.5 *
              ((ca.levelByGroup['eq'] ?? 0) + (ca.shapeByGroup['eq'] ?? 0)),
          'frequency_contrib': 0.5 *
              ((ca.levelByGroup['frequency'] ?? 0) +
                  (ca.shapeByGroup['frequency'] ?? 0)),
          'dims': _topDiscriminatingDims(a, b),
        });
      }
    }
    pairs.sort(
      (x, y) =>
          (x['separation']! as double).compareTo(y['separation']! as double),
    );
    return (
      pairs.take(10).toList(),
      pairs.reversed.take(10).toList(),
    );
  }

  List<String> _topDiscriminatingDims(PersonaPrototype a, PersonaPrototype b) {
    final diffs = <MapEntry<String, double>>[];
    for (final d in catalog.dimensionOrder) {
      diffs.add(MapEntry(d, (a.targetVector[d]! - b.targetVector[d]!).abs()));
    }
    diffs.sort((x, y) => y.value.compareTo(x.value));
    return diffs.take(5).map((e) => e.key).toList();
  }

  static bool _mapEq(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if ((e.value - (b[e.key] ?? -1)).abs() > 1e-15) return false;
    }
    return true;
  }

  static Map<String, double> _percentiles(List<double> sorted) {
    if (sorted.isEmpty) {
      return {
        for (final k in [
          'min',
          'p01',
          'p05',
          'p10',
          'p25',
          'p50',
          'p75',
          'p90',
          'p95',
          'p99',
          'max',
          'mean',
        ])
          k: 0.0,
      };
    }
    double at(double p) {
      final i = ((sorted.length - 1) * p).floor().clamp(0, sorted.length - 1);
      return sorted[i];
    }

    final mean = sorted.reduce((a, b) => a + b) / sorted.length;
    return {
      'min': sorted.first,
      'p01': at(0.01),
      'p05': at(0.05),
      'p10': at(0.10),
      'p25': at(0.25),
      'p50': at(0.50),
      'p75': at(0.75),
      'p90': at(0.90),
      'p95': at(0.95),
      'p99': at(0.99),
      'max': sorted.last,
      'mean': mean,
    };
  }

  /// Public helper for tests.
  static double normalizedEntropy(Map<String, int> primaryCounts) {
    final n = primaryCounts.values.fold<int>(0, (a, b) => a + b);
    if (n <= 0) return 0;
    var h = 0.0;
    for (final c in primaryCounts.values) {
      if (c <= 0) continue;
      final p = c / n;
      h -= p * math.log(p);
    }
    return h / math.log(primaryCounts.length);
  }
}

class FamilyAccumulator {
  FamilyAccumulator(List<String> personaIds)
      : primary = {for (final id in personaIds) id: 0},
        secondary = {for (final id in personaIds) id: 0},
        collision = {
          for (final a in personaIds) a: {for (final b in personaIds) b: 0},
        };

  final Map<String, int> primary;
  final Map<String, int> secondary;
  final Map<String, Map<String, int>> collision;
  final List<double> margins = [];
  int n = 0;

  void add(PersonaShadowResult r) {
    n++;
    primary[r.primaryCandidateId] = primary[r.primaryCandidateId]! + 1;
    secondary[r.secondaryCandidateId] = secondary[r.secondaryCandidateId]! + 1;
    collision[r.primaryCandidateId]![r.secondaryCandidateId] =
        collision[r.primaryCandidateId]![r.secondaryCandidateId]! + 1;
    margins.add(r.top2DistanceMargin);
  }

  void merge(FamilyAccumulator other) {
    n += other.n;
    for (final id in primary.keys) {
      primary[id] = primary[id]! + other.primary[id]!;
      secondary[id] = secondary[id]! + other.secondary[id]!;
      for (final b in collision[id]!.keys) {
        collision[id]![b] = collision[id]![b]! + other.collision[id]![b]!;
      }
    }
    margins.addAll(other.margins);
  }

  Map<String, Object?> snapshot() {
    final sortedMargins = List<double>.from(margins)..sort();
    final primaryShare = {
      for (final e in primary.entries) e.key: n == 0 ? 0.0 : e.value / n,
    };
    final secondaryShare = {
      for (final e in secondary.entries) e.key: n == 0 ? 0.0 : e.value / n,
    };
    final unreachable =
        primary.entries.where((e) => e.value == 0).map((e) => e.key).toList();
    String? maxId;
    var maxShare = -1.0;
    for (final e in primaryShare.entries) {
      if (e.value > maxShare) {
        maxShare = e.value;
        maxId = e.key;
      }
    }
    final pairs = <Map<String, Object?>>[];
    for (final a in collision.keys) {
      for (final b in collision[a]!.keys) {
        if (a == b) continue;
        final c = collision[a]![b]!;
        if (c == 0) continue;
        pairs.add({'primary': a, 'secondary': b, 'count': c, 'share': c / n});
      }
    }
    pairs.sort((x, y) => (y['count']! as int).compareTo(x['count']! as int));

    return {
      'n': n,
      'primary_counts': primary,
      'primary_shares': primaryShare,
      'secondary_counts': secondary,
      'secondary_shares': secondaryShare,
      'normalized_entropy':
          PersonaShadowStressSimulator.normalizedEntropy(primary),
      'max_persona_id': maxId,
      'max_persona_share': maxShare,
      'unreachable_persona_count': unreachable.length,
      'unreachable_personas': unreachable,
      'delta_d': PersonaShadowStressSimulator._percentiles(sortedMargins),
      'collision_matrix': collision,
      'top_collision_pairs': pairs.take(20).toList(),
      'self_secondary_count': [
        for (final id in primary.keys) collision[id]![id]!,
      ].fold<int>(0, (a, b) => a + b),
    };
  }
}

class PersonaShadowStressReport {
  PersonaShadowStressReport({
    required this.seed,
    required this.generatorVersion,
    required this.scoringVersion,
    required this.prototypeVersion,
    required this.policyVersion,
    required this.configVersion,
    required this.sampleCounts,
    required this.families,
    required this.overall,
    required this.selfCenters,
    required this.selfCenterFailureCount,
    required this.midpointExact,
    required this.allHigh,
    required this.allLow,
    required this.localStability,
    required this.midpointNeighborhood,
    required this.pairwiseClosest,
    required this.pairwiseFarthest,
    required this.groupIsolation,
    required this.trEnInvariant,
    required this.determinismOk,
    required this.unusedSmoke,
  });

  final int seed;
  final String generatorVersion;
  final String scoringVersion;
  final String prototypeVersion;
  final String policyVersion;
  final String configVersion;
  final Map<String, int> sampleCounts;
  final Map<String, Map<String, Object?>> families;
  final Map<String, Object?> overall;
  final Map<String, Map<String, Object?>> selfCenters;
  final int selfCenterFailureCount;
  final Map<String, Object?> midpointExact;
  final Map<String, Object?> allHigh;
  final Map<String, Object?> allLow;
  final Map<String, Map<String, Object?>> localStability;
  final Map<String, Map<String, Object?>> midpointNeighborhood;
  final List<Map<String, Object?>> pairwiseClosest;
  final List<Map<String, Object?>> pairwiseFarthest;
  final Map<String, Map<String, Object?>> groupIsolation;
  final bool trEnInvariant;
  final bool determinismOk;
  final Map<String, Object?> unusedSmoke;

  Map<String, Object?> toJson() => {
        'seed': seed,
        'generator_version': generatorVersion,
        'scoring_version': scoringVersion,
        'prototype_version': prototypeVersion,
        'policy_version': policyVersion,
        'config_version': configVersion,
        'sample_counts': sampleCounts,
        'families': families,
        'overall': overall,
        'self_centers': selfCenters,
        'self_center_failure_count': selfCenterFailureCount,
        'midpoint_exact': midpointExact,
        'all_high': allHigh,
        'all_low': allLow,
        'local_stability': localStability,
        'midpoint_neighborhood': midpointNeighborhood,
        'pairwise_closest': pairwiseClosest,
        'pairwise_farthest': pairwiseFarthest,
        'group_isolation': groupIsolation,
        'tr_en_numeric_invariance': trEnInvariant,
        'determinism_ok': determinismOk,
      };
}
