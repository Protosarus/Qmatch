import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

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

  PersonaScoringInput full(Map<String, double> scores) =>
      PersonaScoringInput.fullEvidence(
        dimensionScores: scores,
        dimensionOrder: catalog.dimensionOrder,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      );

  test('11 same input produces identical results', () {
    final x = catalog.byId['vizyoner']!.targetVector;
    final a = service.score(full(x));
    final b = service.score(full(x));
    expect(a.fingerprintLine(), b.fingerprintLine());
    expect(a.primarySimilarity, b.primarySimilarity);
    expect(
      a.candidates.map((c) => '${c.personaId}:${c.similarity}').toList(),
      b.candidates.map((c) => '${c.personaId}:${c.similarity}').toList(),
    );
  });

  test('12 JSON map ordering does not change results', () {
    final profilesText =
        File('assets/data/persona_profiles_v2_20d.json').readAsStringSync();
    final configText =
        File('assets/data/persona_scoring_config_v2.json').readAsStringSync();
    final profiles = Map<String, dynamic>.from(jsonDecode(profilesText) as Map);
    final config = Map<String, dynamic>.from(jsonDecode(configText) as Map);

    final shuffledProfiles =
        PersonaScoringFileLoader.shuffleMapOrder(profiles, 1);
    // Shuffle persona list order
    final personas = List<Map<String, dynamic>>.from(
      (shuffledProfiles['personas'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    shuffledProfiles['personas'] = personas.reversed.toList();

    final catalogB = PersonaScoringParsers.parseProfilesMap(shuffledProfiles);
    final configB = PersonaScoringParsers.parseConfigMap(
      PersonaScoringFileLoader.shuffleMapOrder(config, 2),
    );
    final serviceB = PersonaScoringService(catalog: catalogB, config: configB);

    final x = {
      for (final d in catalog.dimensionOrder) d: 0.61,
    };
    final a = service.score(full(x));
    final b = serviceB.score(
      PersonaScoringInput.fullEvidence(
        dimensionScores: x,
        dimensionOrder: catalogB.dimensionOrder,
        dimensionRegistryVersion: catalogB.dimensionRegistryVersion,
        personaProfileVersion: catalogB.personaProfileVersion,
        personaScoringVersion: serviceB.scoringVersion,
      ),
    );
    expect(a.primaryPersonaId, b.primaryPersonaId);
    expect(a.secondaryPersonaId, b.secondaryPersonaId);
    expect(a.primarySimilarity, closeTo(b.primarySimilarity!, 1e-12));
    final byIdA = {for (final c in a.candidates) c.personaId: c.similarity};
    final byIdB = {for (final c in b.candidates) c.personaId: c.similarity};
    expect(byIdA.keys.toSet(), byIdB.keys.toSet());
    for (final id in byIdA.keys) {
      expect(byIdA[id], closeTo(byIdB[id]!, 1e-12), reason: id);
    }
  });

  test('13 persona order in source JSON does not change candidate scores', () {
    final profiles = Map<String, dynamic>.from(
      jsonDecode(
        File('assets/data/persona_profiles_v2_20d.json').readAsStringSync(),
      ) as Map,
    );
    final personas = List.from(profiles['personas'] as List);
    profiles['personas'] = personas.reversed.toList();
    final catalogB = PersonaScoringParsers.parseProfilesMap(profiles);
    final serviceB = PersonaScoringService(
      catalog: catalogB,
      config: service.config,
    );
    final x = catalog.byId['empat']!.targetVector;
    final a = service.score(full(x));
    final b = serviceB.score(
      PersonaScoringInput.fullEvidence(
        dimensionScores: x,
        dimensionOrder: catalogB.dimensionOrder,
        dimensionRegistryVersion: catalogB.dimensionRegistryVersion,
        personaProfileVersion: catalogB.personaProfileVersion,
        personaScoringVersion: serviceB.scoringVersion,
      ),
    );
    expect(a.primaryPersonaId, b.primaryPersonaId);
    for (final c in a.candidates) {
      final other = b.candidates.firstWhere((e) => e.personaId == c.personaId);
      expect(c.similarity, closeTo(other.similarity, 1e-12));
    }
  });

  test('14 locale does not alter mathematical results', () {
    final x = catalog.byId['analist']!.targetVector;
    final a = service.score(full(x));
    // No locale-sensitive number parsing in scoring path.
    expect(a.primarySimilarity.toString().contains(','), isFalse);
    expect(a.fingerprintLine().contains(','), isFalse);
  });

  test('15-16 exact ties remain ambiguous with deterministic order', () {
    // Construct midpoint between two personas — often tiny margin.
    final a = catalog.byId['empat']!;
    final b = catalog.byId['sifaci']!;
    final x = {
      for (final d in catalog.dimensionOrder)
        d: 0.5 * (a.targetVector[d]! + b.targetVector[d]!),
    };
    final r1 = service.score(full(x));
    final r2 = service.score(full(x));
    expect(r1.fingerprintLine(), r2.fingerprintLine());
    expect(r1.primaryPersonaId, r2.primaryPersonaId);
    expect(r1.secondaryPersonaId, r2.secondaryPersonaId);
    if (r1.top2Margin != null &&
        r1.top2Margin! < service.config.top2MarginThreshold) {
      expect(r1.ambiguous, isTrue);
      expect(r1.status, PersonaScoringStatus.ambiguous);
    }
    // Deterministic ordering among equal sims via tie_break_rank then id.
    final sims =
        r1.candidates.where((c) => c.eligibleForPublishableRanking).toList();
    for (var i = 1; i < sims.length; i++) {
      final prev = sims[i - 1];
      final cur = sims[i];
      if ((prev.similarity - cur.similarity).abs() <=
          service.config.numericalEpsilon) {
        final rankOk = prev.tieBreakRank < cur.tieBreakRank ||
            (prev.tieBreakRank == cur.tieBreakRank &&
                prev.personaId.compareTo(cur.personaId) <= 0);
        expect(rankOk, isTrue);
      }
    }
  });

  test('20 no random selection across repeated calls', () {
    final x = {for (final d in catalog.dimensionOrder) d: 0.5};
    final ids = <String?>{};
    for (var i = 0; i < 50; i++) {
      ids.add(service.score(full(x)).primaryPersonaId);
    }
    expect(ids.length, 1);
  });
}
