import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

/// Verifies simulator and service share one canonical formula.
void main() {
  late PersonaScoringService service;
  late PersonaProfileCatalog catalog;

  setUpAll(() {
    final loaded =
        PersonaScoringFileLoader.loadFromRepoRoot(Directory.current.path);
    catalog = loaded.catalog;
    service = PersonaScoringService(
      catalog: loaded.catalog,
      config: loaded.config,
    );
  });

  PersonaScoringInput inputFor(Map<String, double> x) =>
      PersonaScoringInput.fullEvidence(
        dimensionScores: x,
        dimensionOrder: catalog.dimensionOrder,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      );

  test('26 service fingerprints are stable and self-consistent', () {
    final rng = Random(42);
    final lines = <String>[];
    for (var i = 0; i < 200; i++) {
      final x = {
        for (final d in catalog.dimensionOrder) d: rng.nextDouble(),
      };
      lines.add(service.score(inputFor(x)).fingerprintLine());
    }
    // Replay
    final rng2 = Random(42);
    for (var i = 0; i < 200; i++) {
      final x = {
        for (final d in catalog.dimensionOrder) d: rng2.nextDouble(),
      };
      expect(service.score(inputFor(x)).fingerprintLine(), lines[i]);
    }
  });

  test('27 prototype recovery does not regress materially', () {
    var exact = 0;
    for (final p in catalog.personas) {
      final r = service.score(inputFor(p.targetVector));
      if (r.primaryPersonaId == p.personaId) exact++;
    }
    expect(exact / catalog.personas.length, 1.0);

    final rng = Random(99);
    var nearHits = 0;
    var nearTotal = 0;
    for (final p in catalog.personas) {
      for (var i = 0; i < 30; i++) {
        final x = {
          for (final d in catalog.dimensionOrder)
            d: (p.targetVector[d]! + (rng.nextDouble() - 0.5) * 0.16)
                .clamp(0.0, 1.0),
        };
        nearTotal++;
        if (service.score(inputFor(x)).primaryPersonaId == p.personaId) {
          nearHits++;
        }
      }
    }
    expect(nearHits / nearTotal, greaterThan(0.97));
  });

  test('28 seed-42 mini distribution remains diversified', () {
    // Lightweight reproducibility check (full 200k runs offline via tool).
    final rng = Random(42);
    final counts = <String, int>{
      for (final p in catalog.personas) p.personaId: 0
    };
    var insufficient = 0;
    const n = 5000;
    for (var i = 0; i < n; i++) {
      final x = {
        for (final d in catalog.dimensionOrder) d: rng.nextDouble(),
      };
      final r = service.score(inputFor(x));
      if (r.insufficientEvidence || r.primaryPersonaId == null) {
        insufficient++;
        continue;
      }
      counts[r.primaryPersonaId!] = counts[r.primaryPersonaId!]! + 1;
    }
    final assigned = counts.values.fold<int>(0, (a, b) => a + b);
    expect(assigned + insufficient, n);
    final nonzero = counts.values.where((v) => v > 0).length;
    expect(nonzero, greaterThanOrEqualTo(15));
    final shares = [
      for (final v in counts.values) assigned == 0 ? 0.0 : v / assigned,
    ];
    var entropy = 0.0;
    for (final s in shares) {
      if (s > 0) entropy -= s * (log(s) / ln2);
    }
    final norm = entropy / (log(18) / ln2);
    expect(norm, greaterThan(0.85));
  });

  test('simulator tool delegates to PersonaScoringService', () {
    final src =
        File('tool/persona_prototype_simulator.dart').readAsStringSync();
    expect(src.contains('PersonaScoringService'), isTrue);
    expect(src.contains('class PersonaEngine'), isFalse);
    expect(src.contains('SimConfig.fromJson'), isFalse);
  });
}
