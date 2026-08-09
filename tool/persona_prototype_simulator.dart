// Offline provisional persona prototype simulator (P1B-2B-2).
//
// Uses the pure PersonaScoringService as the single canonical formula.
// - No Firebase / network
// - Does not load into Flutter runtime
// - Similarity is NOT probability
//
// Usage:
//   dart run tool/persona_prototype_simulator.dart
//   dart run tool/persona_prototype_simulator.dart --seed=42 --count=200000

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';
import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring_file_loader.dart';

const defaultSeed = 42;
const defaultCount = 200000;

typedef Vec = Map<String, double>;

class SeededRng {
  final Random _r;
  SeededRng(int seed) : _r = Random(seed);
  double next() => _r.nextDouble();
  int nextInt(int max) => _r.nextInt(max);
  double uniform(double a, double b) => a + (b - a) * next();
  double clamp01(double v) => v.clamp(0.0, 1.0);
}

Map<String, int> fullEvidence(List<String> dims) =>
    {for (final d in dims) d: 3};

Vec fullVec(List<String> dims, double Function(String d) f) =>
    {for (final d in dims) d: f(d)};

void main(List<String> args) {
  var seed = defaultSeed;
  var count = defaultCount;
  // compatibility = deprecated min(1, ev/3); explicit = per-dim sufficiency map
  var evidenceMode = 'explicit';
  for (final a in args) {
    if (a.startsWith('--seed=')) seed = int.parse(a.substring(7));
    if (a.startsWith('--count=')) count = int.parse(a.substring(8));
    if (a.startsWith('--evidence-mode=')) {
      evidenceMode = a.substring('--evidence-mode='.length);
    }
  }
  if (evidenceMode != 'explicit' && evidenceMode != 'compatibility') {
    stderr.writeln(
      'Unknown --evidence-mode=$evidenceMode (use explicit|compatibility)',
    );
    exit(2);
  }

  final root = Directory.current.path;
  final service = PersonaScoringFileLoader.serviceFromRepoRoot(root);
  final catalog = service.catalog;
  final dims = catalog.dimensionOrder;
  final personas = catalog.personas;

  PersonaScoringInput toInput(Vec x, Map<String, int> ev) {
    if (evidenceMode == 'compatibility') {
      return PersonaScoringInput.withDeprecatedGlobalEvidenceDenominator(
        dimensionScores: x,
        dimensionEvidenceCounts: ev,
        dimensionReliability: {
          for (final d in x.keys) d: 1.0,
        },
        missingDimensions: {
          for (final d in dims)
            if (!x.containsKey(d) || (ev[d] ?? 0) <= 0) d,
        },
        assessmentStatuses: const {
          'iq': 'complete',
          'eq': 'complete',
          'frequency': 'complete',
        },
        responseValidityStatus: ResponseValidityStatus.valid,
        dimensionRegistryVersion: catalog.dimensionRegistryVersion,
        personaProfileVersion: catalog.personaProfileVersion,
        personaScoringVersion: service.scoringVersion,
      );
    }
    return PersonaScoringInput(
      dimensionScores: x,
      dimensionEvidenceCounts: ev,
      dimensionEvidenceSufficiency: {
        for (final d in x.keys)
          if ((ev[d] ?? 0) > 0) d: 1.0,
      },
      dimensionReliability: {
        for (final d in x.keys) d: 1.0,
      },
      missingDimensions: {
        for (final d in dims)
          if (!x.containsKey(d) || (ev[d] ?? 0) <= 0) d,
      },
      assessmentStatuses: const {
        'iq': 'complete',
        'eq': 'complete',
        'frequency': 'complete',
      },
      responseValidityStatus: ResponseValidityStatus.valid,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringVersion: service.scoringVersion,
      evidenceSufficiencyMode: PersonaEvidenceSufficiencyMode.explicit,
    );
  }

  final rng = SeededRng(seed);
  final byPersona = <String, int>{for (final p in personas) p.personaId: 0};
  var insufficient = 0;
  var lowConf = 0;
  var exactTie = 0;
  var nearTie = 0;
  final margins = <double>[];
  final pairConfusion = <String, int>{};
  var nearProtoHits = 0;
  var nearProtoTotal = 0;
  var exactProtoHits = 0;
  final generatorCounts = <String, int>{};
  final centralAssign = <String, int>{};
  final centralNonAmbiguousAssign = <String, int>{};
  var centralTotalSeen = 0;
  var centralAmbiguous = 0;
  final extremeAssign = <String, int>{};
  final fingerprint = StringBuffer();

  void record(String gen, PersonaScoringResult r,
      {bool central = false, bool extreme = false}) {
    generatorCounts[gen] = (generatorCounts[gen] ?? 0) + 1;
    if (central) centralTotalSeen++;
    if (r.insufficientEvidence || r.primaryPersonaId == null) {
      insufficient++;
      return;
    }
    byPersona[r.primaryPersonaId!] = (byPersona[r.primaryPersonaId!] ?? 0) + 1;
    if (r.confidenceLevel == PersonaConfidenceLevel.low) lowConf++;
    if (r.top2Margin != null) {
      margins.add(r.top2Margin!);
      if (r.top2Margin! < 1e-9) exactTie++;
      if (r.ambiguous) nearTie++;
    }
    if (r.secondaryPersonaId != null) {
      final a = [r.primaryPersonaId!, r.secondaryPersonaId!]..sort();
      final key = '${a[0]}|${a[1]}';
      pairConfusion[key] = (pairConfusion[key] ?? 0) + 1;
    }
    if (central) {
      centralAssign[r.primaryPersonaId!] =
          (centralAssign[r.primaryPersonaId!] ?? 0) + 1;
      if (r.ambiguous) {
        centralAmbiguous++;
      } else {
        centralNonAmbiguousAssign[r.primaryPersonaId!] =
            (centralNonAmbiguousAssign[r.primaryPersonaId!] ?? 0) + 1;
      }
    }
    if (extreme) {
      extremeAssign[r.primaryPersonaId!] =
          (extremeAssign[r.primaryPersonaId!] ?? 0) + 1;
    }
  }

  final quotas = <String, int>{
    'uniform': (count * 0.18).round(),
    'cluster_0_5': (count * 0.10).round(),
    'low_variance_central': (count * 0.08).round(),
    'high_variance': (count * 0.08).round(),
    'all_high': (count * 0.03).round(),
    'all_low': (count * 0.03).round(),
    'alternating': (count * 0.05).round(),
    'correlated_eq': (count * 0.05).round(),
    'correlated_freq': (count * 0.05).round(),
    'near_prototype': (count * 0.12).round(),
    'between_pairs': (count * 0.08).round(),
    'exact_prototype': personas.length,
    'missing_iq': (count * 0.03).round(),
    'missing_eq': (count * 0.03).round(),
    'missing_frequency': (count * 0.03).round(),
    'random_missing': (count * 0.04).round(),
    'exact_tie_synth': (count * 0.01).round(),
    'near_tie_synth': (count * 0.01).round(),
  };
  quotas['exact_prototype'] = max(personas.length, (count * 0.02).round());
  final allocated = quotas.values.fold<int>(0, (a, b) => a + b);
  quotas['uniform'] = quotas['uniform']! + (count - allocated);

  Vec noiseAround(Vec base, double sigma) {
    return {
      for (final d in dims)
        d: rng.clamp01((base[d] ?? 0.5) + rng.uniform(-sigma, sigma)),
    };
  }

  var processed = 0;
  void maybeFingerprint(PersonaScoringResult r) {
    if (processed < 1000 || processed >= count - 1000) {
      fingerprint.writeln(r.fingerprintLine());
    }
  }

  PersonaScoringResult runOne(Vec x, Map<String, int> ev) {
    final r = service.score(toInput(x, ev));
    maybeFingerprint(r);
    processed++;
    return r;
  }

  for (var i = 0; i < quotas['uniform']!; i++) {
    final x = fullVec(dims, (_) => rng.next());
    record('uniform', runOne(x, fullEvidence(dims)));
  }
  for (var i = 0; i < quotas['cluster_0_5']!; i++) {
    final x = fullVec(dims, (_) => rng.clamp01(0.5 + rng.uniform(-0.12, 0.12)));
    record('cluster_0_5', runOne(x, fullEvidence(dims)), central: true);
  }
  for (var i = 0; i < quotas['low_variance_central']!; i++) {
    final x = fullVec(dims, (_) => rng.clamp01(0.5 + rng.uniform(-0.05, 0.05)));
    record('low_variance_central', runOne(x, fullEvidence(dims)),
        central: true);
  }
  for (var i = 0; i < quotas['high_variance']!; i++) {
    final x = fullVec(dims,
        (_) => rng.next() < 0.5 ? rng.uniform(0, 0.25) : rng.uniform(0.75, 1));
    record('high_variance', runOne(x, fullEvidence(dims)), extreme: true);
  }
  for (var i = 0; i < quotas['all_high']!; i++) {
    final x = fullVec(dims, (_) => rng.uniform(0.82, 1.0));
    record('all_high', runOne(x, fullEvidence(dims)), extreme: true);
  }
  for (var i = 0; i < quotas['all_low']!; i++) {
    final x = fullVec(dims, (_) => rng.uniform(0.0, 0.18));
    record('all_low', runOne(x, fullEvidence(dims)), extreme: true);
  }
  for (var i = 0; i < quotas['alternating']!; i++) {
    final x = <String, double>{};
    for (var di = 0; di < dims.length; di++) {
      x[dims[di]] =
          di.isEven ? rng.uniform(0.75, 0.95) : rng.uniform(0.05, 0.25);
    }
    record('alternating', runOne(x, fullEvidence(dims)), extreme: true);
  }
  for (var i = 0; i < quotas['correlated_eq']!; i++) {
    final base = rng.uniform(0.25, 0.85);
    final x = fullVec(dims, (d) {
      if (PersonaDimensionIds.eq.contains(d)) {
        return rng.clamp01(base + rng.uniform(-0.08, 0.08));
      }
      return rng.next();
    });
    record('correlated_eq', runOne(x, fullEvidence(dims)));
  }
  for (var i = 0; i < quotas['correlated_freq']!; i++) {
    final base = rng.uniform(0.2, 0.85);
    final x = fullVec(dims, (d) {
      if (PersonaDimensionIds.frequency.contains(d)) {
        return rng.clamp01(base + rng.uniform(-0.1, 0.1));
      }
      return rng.next();
    });
    record('correlated_freq', runOne(x, fullEvidence(dims)));
  }

  for (var i = 0; i < quotas['near_prototype']!; i++) {
    final p = personas[rng.nextInt(personas.length)];
    final x = noiseAround(p.targetVector, 0.08);
    final r = runOne(x, fullEvidence(dims));
    nearProtoTotal++;
    if (r.primaryPersonaId == p.personaId) nearProtoHits++;
    record('near_prototype', r);
  }

  for (var i = 0; i < quotas['between_pairs']!; i++) {
    final p = personas[rng.nextInt(personas.length)];
    final comps = p.separatorTargets.keys.toList();
    if (comps.isEmpty) continue;
    final otherId = comps[rng.nextInt(comps.length)];
    final other = catalog.byId[otherId]!;
    final t = rng.next();
    final x = {
      for (final d in dims)
        d: rng.clamp01(
          (1 - t) * p.targetVector[d]! + t * other.targetVector[d]!,
        ),
    };
    record('between_pairs', runOne(x, fullEvidence(dims)));
  }

  for (var i = 0; i < quotas['exact_prototype']!; i++) {
    final p = personas[i % personas.length];
    final r =
        runOne(Map<String, double>.from(p.targetVector), fullEvidence(dims));
    if (r.primaryPersonaId == p.personaId) exactProtoHits++;
    record('exact_prototype', r);
  }

  for (var i = 0; i < quotas['missing_iq']!; i++) {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in dims) {
      if (PersonaDimensionIds.iq.contains(d)) continue;
      x[d] = rng.next();
      ev[d] = 3;
    }
    record('missing_iq', runOne(x, ev));
  }
  for (var i = 0; i < quotas['missing_eq']!; i++) {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in dims) {
      if (PersonaDimensionIds.eq.contains(d)) continue;
      x[d] = rng.next();
      ev[d] = 3;
    }
    record('missing_eq', runOne(x, ev));
  }
  for (var i = 0; i < quotas['missing_frequency']!; i++) {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in dims) {
      if (PersonaDimensionIds.frequency.contains(d)) continue;
      x[d] = rng.next();
      ev[d] = 3;
    }
    record('missing_frequency', runOne(x, ev));
  }
  for (var i = 0; i < quotas['random_missing']!; i++) {
    final x = <String, double>{};
    final ev = <String, int>{};
    for (final d in dims) {
      if (rng.next() < 0.35) continue;
      x[d] = rng.next();
      ev[d] = 3;
    }
    record('random_missing', runOne(x, ev));
  }

  for (var i = 0; i < quotas['exact_tie_synth']!; i++) {
    final p = personas[rng.nextInt(personas.length)];
    final other = catalog.byId[p.separatorTargets.keys.first]!;
    final x = {
      for (final d in dims)
        d: 0.5 * (p.targetVector[d]! + other.targetVector[d]!),
    };
    record('exact_tie_synth', runOne(x, fullEvidence(dims)));
  }
  for (var i = 0; i < quotas['near_tie_synth']!; i++) {
    final p = personas[rng.nextInt(personas.length)];
    final other = catalog.byId[p.separatorTargets.keys.first]!;
    final t = 0.48 + rng.uniform(0, 0.04);
    final x = {
      for (final d in dims)
        d: (1 - t) * p.targetVector[d]! + t * other.targetVector[d]!,
    };
    record('near_tie_synth', runOne(x, fullEvidence(dims)));
  }

  final assigned = byPersona.values.fold<int>(0, (a, b) => a + b);
  final shares = {
    for (final e in byPersona.entries)
      e.key: assigned == 0 ? 0.0 : e.value / assigned,
  };
  final shareVals = shares.values.toList()..sort();
  final maxShare = shareVals.isEmpty ? 0.0 : shareVals.last;
  final minShare = shareVals.isEmpty ? 0.0 : shareVals.first;
  final unreachable = [
    for (final e in byPersona.entries)
      if (e.value == 0) e.key,
  ];

  var entropy = 0.0;
  for (final s in shares.values) {
    if (s > 0) entropy -= s * log(s) / ln2;
  }
  final maxEntropy = log(personas.length) / ln2;
  final normEntropy = maxEntropy == 0 ? 0.0 : entropy / maxEntropy;

  margins.sort();
  double pct(List<double> xs, double p) {
    if (xs.isEmpty) return 0;
    final i = ((xs.length - 1) * p).round().clamp(0, xs.length - 1);
    return xs[i];
  }

  final topConfused = pairConfusion.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final centralTotal = centralAssign.values.fold<int>(0, (a, b) => a + b);
  String? centralMaxId;
  var centralMaxShare = 0.0;
  for (final e in centralAssign.entries) {
    final s = centralTotal == 0 ? 0.0 : e.value / centralTotal;
    if (s > centralMaxShare) {
      centralMaxShare = s;
      centralMaxId = e.key;
    }
  }
  final centralNonAmbTotal =
      centralNonAmbiguousAssign.values.fold<int>(0, (a, b) => a + b);
  String? centralNonAmbMaxId;
  var centralNonAmbMaxShare = 0.0;
  for (final e in centralNonAmbiguousAssign.entries) {
    final s = centralNonAmbTotal == 0 ? 0.0 : e.value / centralNonAmbTotal;
    if (s > centralNonAmbMaxShare) {
      centralNonAmbMaxShare = s;
      centralNonAmbMaxId = e.key;
    }
  }
  final centralAmbRate =
      centralTotalSeen == 0 ? 0.0 : centralAmbiguous / centralTotalSeen;

  final report = {
    'seed': seed,
    'profile_count': count,
    'processed': processed,
    'persona_profile_version': catalog.personaProfileVersion,
    'config_version': service.config.configVersion,
    'scoring_implementation': 'PersonaScoringService',
    'generator_counts': generatorCounts,
    'assigned_count': assigned,
    'insufficient_evidence_count': insufficient,
    'low_confidence_count': lowConf,
    'exact_tie_count': exactTie,
    'near_tie_count': nearTie,
    'persona_assignment_counts': byPersona,
    'persona_assignment_shares': shares,
    'normalized_entropy': normEntropy,
    'max_persona_share': maxShare,
    'min_persona_share': minShare,
    'unreachable_personas': unreachable,
    'near_prototype_recovery_accuracy':
        nearProtoTotal == 0 ? 0.0 : nearProtoHits / nearProtoTotal,
    'exact_prototype_recovery_accuracy': quotas['exact_prototype'] == 0
        ? 0.0
        : exactProtoHits / quotas['exact_prototype']!,
    'top2_margin_p50': pct(margins, 0.50),
    'top2_margin_p10': pct(margins, 0.10),
    'top2_margin_p90': pct(margins, 0.90),
    'most_confused_pairs': [
      for (final e in topConfused.take(12)) {'pair': e.key, 'count': e.value},
    ],
    'central_max_persona': centralMaxId,
    'central_max_share': centralMaxShare,
    'central_ambiguous_rate': centralAmbRate,
    'central_non_ambiguous_count': centralNonAmbTotal,
    'central_non_ambiguous_max_persona': centralNonAmbMaxId,
    'central_non_ambiguous_max_share': centralNonAmbMaxShare,
    'central_assignment_counts': centralAssign,
    'extreme_assignment_counts': extremeAssign,
    'evidence_sufficiency_mode': evidenceMode,
    'fingerprint_sha_like': fingerprint.toString().hashCode,
    'fingerprint_lines': fingerprint.toString().split('\n').length,
    'notes': {
      'provisional': true,
      'similarity_is_not_probability': true,
      'no_quota': true,
      'canonical_formula': 'lib/.../persona_scoring_service.dart',
      'evidence_sufficiency': evidenceMode == 'compatibility'
          ? 'deprecated min(1, evidenceCount/3) adapter'
          : 'explicit dimensionEvidenceSufficiency map (no global /3)',
      'central_label_collapse_vs_confidence':
          'Central forced primary labels may concentrate when margins are tiny; use central_ambiguous_rate and central_non_ambiguous_max_share for gate 4.',
    },
  };

  final outDir = Directory('$root/tool/persona_sim_out');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final modeTag = evidenceMode == 'compatibility' ? 'compat' : 'explicit';
  final outFile =
      File('${outDir.path}/sim_seed_${seed}_n_${count}_$modeTag.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  final fpFile =
      File('${outDir.path}/fingerprint_seed_${seed}_n_${count}_$modeTag.txt');
  fpFile.writeAsStringSync(fingerprint.toString());

  stdout.writeln('=== Persona prototype simulation (PROVISIONAL) ===');
  stdout.writeln('seed=$seed count=$count processed=$processed');
  stdout.writeln('evidence_mode=$evidenceMode');
  stdout.writeln('scoring=PersonaScoringService');
  stdout.writeln('assigned=$assigned insufficient=$insufficient');
  stdout.writeln('normalized_entropy=${normEntropy.toStringAsFixed(4)}');
  stdout.writeln(
      'max_share=${maxShare.toStringAsFixed(4)} min_share=${minShare.toStringAsFixed(4)}');
  stdout.writeln('unreachable=$unreachable');
  stdout.writeln(
    'exact_proto_acc=${report['exact_prototype_recovery_accuracy']} near_proto_acc=${report['near_prototype_recovery_accuracy']}',
  );
  stdout.writeln(
      'central_max=$centralMaxId share=${centralMaxShare.toStringAsFixed(4)}');
  stdout.writeln(
    'central_amb_rate=${centralAmbRate.toStringAsFixed(4)} nonamb_max=$centralNonAmbMaxId share=${centralNonAmbMaxShare.toStringAsFixed(4)}',
  );
  stdout.writeln('fingerprint_sha_like=${report['fingerprint_sha_like']}');
  stdout.writeln('wrote ${outFile.path}');
}
