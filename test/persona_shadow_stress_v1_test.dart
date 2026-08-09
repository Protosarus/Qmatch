import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

void main() {
  late CanonicalPersonaShadowScorer scorer;
  late PersonaProfileCatalog catalog;
  late PersonaShadowScoringConfig config;
  late PersonaShadowStressSimulator sim;

  setUpAll(() {
    final loaded = PersonaScoringFileLoader.loadShadowFromRepoRoot(
      Directory.current.path,
    );
    catalog = loaded.catalog;
    config = loaded.config;
    scorer = CanonicalPersonaShadowScorer(
      catalog: catalog,
      config: config,
    );
    sim = PersonaShadowStressSimulator(
      scorer: scorer,
      catalog: catalog,
      config: config,
    );
  });

  test('exactly 18 canonical Persona IDs', () {
    expect(catalog.personas.length, 18);
    expect(sim.personaIds.toSet().length, 18);
  });

  test('every Persona is primary at exact own prototype center', () {
    for (final p in catalog.personas) {
      final r = sim.score(Map<String, double>.from(p.targetVector));
      expect(
        r.primaryCandidateId,
        p.personaId,
        reason: 'self-center failure for ${p.personaId}',
      );
      expect(r.top2DistanceMargin, greaterThanOrEqualTo(0));
      expect(r.secondaryCandidateId, isNot(equals(r.primaryCandidateId)));
    }
  });

  test('normalized entropy formula and share sums', () {
    final counts = <String, int>{
      for (final id in sim.personaIds) id: 0,
    };
    final rng = math.Random(7);
    for (var i = 0; i < 180; i++) {
      final x = {
        for (final d in catalog.dimensionOrder) d: rng.nextDouble(),
      };
      final r = sim.score(x);
      counts[r.primaryCandidateId] = counts[r.primaryCandidateId]! + 1;
    }
    final hNorm = PersonaShadowStressSimulator.normalizedEntropy(counts);
    expect(hNorm, inInclusiveRange(0.0, 1.0));
    final shareSum =
        counts.values.map((c) => c / 180).fold<double>(0, (a, b) => a + b);
    expect(shareSum, closeTo(1.0, 1e-12));
  });

  test('primary always argmin D; secondary second argmin; Δ_D >= 0', () {
    final x = {for (final d in catalog.dimensionOrder) d: 0.5};
    final r = sim.score(x);
    final ordered = r.candidates.map((c) => c.distance).toList();
    for (var i = 1; i < ordered.length; i++) {
      expect(ordered[i] + 1e-15, greaterThanOrEqualTo(ordered[i - 1]));
    }
    expect(r.primaryCandidateId, r.candidates.first.personaId);
    expect(r.secondaryCandidateId, r.candidates[1].personaId);
    expect(r.top2DistanceMargin, greaterThanOrEqualTo(0));
  });

  test('midpoint, all-high, all-low deterministic', () {
    Map<String, double> fill(double v) => {
          for (final d in catalog.dimensionOrder) d: v,
        };
    final midA = sim.score(fill(0.5));
    final midB = sim.score(fill(0.5));
    expect(midA.primaryCandidateId, midB.primaryCandidateId);
    expect(midA.secondaryCandidateId, midB.secondaryCandidateId);
    expect(midA.top2DistanceMargin, midB.top2DistanceMargin);
    expect(sim.score(fill(1.0)).candidates.length, 18);
    expect(sim.score(fill(0.0)).candidates.length, 18);
  });

  test('TR/EN numeric invariance for identical 20D scores', () {
    final x = {for (final d in catalog.dimensionOrder) d: 0.37};
    final tr = sim.score(x, locale: 'tr');
    final en = sim.score(x, locale: 'en');
    expect(tr.primaryCandidateId, en.primaryCandidateId);
    expect(tr.secondaryCandidateId, en.secondaryCandidateId);
    expect(tr.top2DistanceMargin, en.top2DistanceMargin);
    expect(tr.allPersonaDistances, en.allPersonaDistances);
  });

  test('local epsilon stability telemetry runs without prototype edits', () {
    for (final eps in [0.01, 0.03, 0.05, 0.10]) {
      final p = catalog.personas.first;
      final rng = math.Random(eps.hashCode);
      for (var i = 0; i < 20; i++) {
        final x = {
          for (final d in catalog.dimensionOrder)
            d: (p.targetVector[d]! + (rng.nextDouble() - 0.5) * 2 * eps)
                .clamp(0.0, 1.0),
        };
        final r = sim.score(x);
        expect(r.top2DistanceMargin, greaterThanOrEqualTo(0));
      }
    }
  });

  test('no temperature/affinity/confidence/percentages on shadow result', () {
    final r = sim.score({for (final d in catalog.dimensionOrder) d: 0.5});
    expect(r.temperatureApplied, isFalse);
    expect(r.affinityNotComputed, isTrue);
    expect(r.confidenceNotComputed, isTrue);
    expect(r.shadowOnly, isTrue);
    expect(r.top2MarginBand, 'not_computed');
  });

  test('collision matrix shape 18x18 with no self-secondary at centers', () {
    final ids = sim.personaIds;
    final matrix = {
      for (final a in ids) a: {for (final b in ids) b: 0},
    };
    for (final p in catalog.personas) {
      final r = sim.score(Map<String, double>.from(p.targetVector));
      matrix[r.primaryCandidateId]![r.secondaryCandidateId] =
          matrix[r.primaryCandidateId]![r.secondaryCandidateId]! + 1;
      expect(r.primaryCandidateId, isNot(equals(r.secondaryCandidateId)));
    }
    expect(matrix.length, 18);
    for (final row in matrix.values) {
      expect(row.length, 18);
    }
  });

  test(
    'deterministic full stress suite >= 100k with fixed seed',
    () {
      final report = sim.runFull();
      expect(report.sampleCounts['overall']!, greaterThanOrEqualTo(100000));
      expect(report.seed, 20260809);
      expect(report.selfCenterFailureCount, 0);
      expect(report.determinismOk, isTrue);
      expect(report.trEnInvariant, isTrue);
      expect(report.overall['self_secondary_count'], 0);
      expect(report.overall['unreachable_persona_count'], 0);

      final primaryShares =
          Map<String, double>.from(report.overall['primary_shares']! as Map);
      final secondaryShares =
          Map<String, double>.from(report.overall['secondary_shares']! as Map);
      expect(
        primaryShares.values.fold<double>(0, (a, b) => a + b),
        closeTo(1.0, 1e-9),
      );
      expect(
        secondaryShares.values.fold<double>(0, (a, b) => a + b),
        closeTo(1.0, 1e-9),
      );

      final matrix = report.overall['collision_matrix']! as Map;
      expect(matrix.length, 18);

      final outDir = Directory('docs/persona/reports');
      outDir.createSync(recursive: true);
      File('${outDir.path}/persona_shadow_stress_v1_aggregate.json')
          .writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(report.toJson()),
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
