// Offline Persona shadow simulation helper (P2C-3A-2). Not runtime-wired.
// Usage: dart run tool/persona_shadow_simulate_v1.dart

import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

void main() {
  final loaded =
      PersonaScoringFileLoader.loadShadowFromRepoRoot(Directory.current.path);
  final scorer = CanonicalPersonaShadowScorer(
    catalog: loaded.catalog,
    config: loaded.config,
  );
  final catalog = loaded.catalog;
  final config = loaded.config;

  Map<String, int> full() => {
        for (final d in catalog.dimensionOrder) d: config.nMin(d),
      };

  PersonaShadowInput inp(Map<String, double> x) => PersonaShadowInput(
        dimensionScores: x,
        source: PersonaShadowSourceEvidence(
          ownerUid: 'sim',
          iqCompleted: true,
          eqCompleted: true,
          frequencyCompleted: true,
          iqScoringPolicyVersion: 'iq_4d_uncalibrated_accuracy_v1',
          eqScoringPolicyVersion: 'eq_10d_uncalibrated_signed_evidence_v1',
          frequencyScoringPolicyVersion:
              'frequency_6d_uncalibrated_signed_evidence_v1',
          iqBankOrSessionVersion: 'iq',
          eqBankOrSessionVersion: 'eq',
          frequencyBankOrSessionVersion: 'f',
          dimensionEvidenceCounts: full(),
        ),
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      );

  final mid = {for (final d in catalog.dimensionOrder) d: 0.5};
  final center = scorer.score(inp(mid));
  final dists = center.candidates.map((c) => c.distance).toList()..sort();
  stdout.writeln(
    'CENTER primary=${center.primaryCandidateId} '
    'secondary=${center.secondaryCandidateId} '
    'margin=${center.top2DistanceMargin}',
  );
  stdout.writeln(
    'CENTER min=${dists.first} median=${dists[dists.length ~/ 2]} '
    'max=${dists.last}',
  );

  final rng = Random(42);
  final primary = <String, int>{
    for (final p in catalog.personas) p.personaId: 0,
  };
  final secondary = <String, int>{
    for (final p in catalog.personas) p.personaId: 0,
  };
  final margins = <double>[];
  const per = 200;
  for (final p in catalog.personas) {
    for (var i = 0; i < per; i++) {
      final x = {
        for (final d in catalog.dimensionOrder)
          d: (p.targetVector[d]! + (rng.nextDouble() - 0.5) * 0.12)
              .clamp(0.0, 1.0),
      };
      final out = scorer.score(inp(x));
      primary[out.primaryCandidateId] = primary[out.primaryCandidateId]! + 1;
      secondary[out.secondaryCandidateId] =
          secondary[out.secondaryCandidateId]! + 1;
      margins.add(out.top2DistanceMargin);
    }
  }
  stdout.writeln('DIST n=${18 * per}');
  for (final p in catalog.personas) {
    stdout.writeln(
      'primary ${p.personaId}=${primary[p.personaId]} '
      'secondary=${secondary[p.personaId]}',
    );
  }
  margins.sort();
  stdout.writeln(
    'margin min=${margins.first} p50=${margins[margins.length ~/ 2]} '
    'max=${margins.last}',
  );
}
