import 'dart:math' as math;

import 'persona_dimension_profile.dart';
import 'persona_prototype.dart';
import 'persona_shadow_input.dart';
import 'persona_shadow_result.dart';
import 'persona_shadow_scoring_config.dart';

/// Pure offline Persona shadow-distance scorer (P2C-3A-2).
///
/// * Uses `q_j^(shadow) = E_j` — no fabricated reliability.
/// * No temperature / affinity / confidence.
/// * No network persistence or UI side effects.
class CanonicalPersonaShadowScorer {
  CanonicalPersonaShadowScorer({
    required this.catalog,
    required this.config,
  }) {
    if (catalog.personaProfileVersion != config.personaProfileVersion) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompatiblePrototypeVersion,
        'Catalog ${catalog.personaProfileVersion} != '
        'config ${config.personaProfileVersion}',
      );
    }
    if (catalog.dimensionRegistryVersion != config.dimensionRegistryVersion) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompatibleConfig,
        'Dimension registry mismatch',
      );
    }
    config.assertCanonicalShadowCoefficients();
  }

  final PersonaProfileCatalog catalog;
  final PersonaShadowScoringConfig config;

  /// Score a fully-sourced canonical 20D profile for shadow candidates only.
  PersonaShadowResult score(PersonaShadowInput input) {
    _validateEligibility(input);
    final e = _evidenceSufficiency(input);
    _assertGroupsScorable(e);

    final userMeans = <String, double>{
      for (final g in const ['iq', 'eq', 'frequency'])
        g: _wavg(
          values: {
            for (final d in PersonaDimensionIds.dimsOf(g))
              d: input.dimensionScores[d]!,
          },
          weights: {
            for (final d in PersonaDimensionIds.dimsOf(g)) d: e[d]!,
          },
          context: 'user_mean_$g',
        ),
    };
    final userShape = <String, double>{
      for (final d in catalog.dimensionOrder)
        d: input.dimensionScores[d]! -
            userMeans[PersonaDimensionIds.groupOf(d)]!,
    };

    final candidates = <PersonaShadowCandidate>[];
    for (final p in _personasStable()) {
      candidates.add(_scorePersona(p, input, e, userShape));
    }
    candidates.sort(_compare);

    final primary = candidates.first;
    final secondary = candidates[1];
    final margin = secondary.distance - primary.distance;
    if (margin < -config.numericalEpsilon) {
      throw StateError('Δ_D must be >= 0');
    }

    return PersonaShadowResult(
      scoringVersion: config.scoringVersion,
      prototypeVersion: catalog.personaProfileVersion,
      policyVersion: config.qualityPolicyVersion,
      configVersion: config.configVersion,
      primaryCandidateId: primary.personaId,
      secondaryCandidateId: secondary.personaId,
      allPersonaDistances: {
        for (final c in candidates) c.personaId: c.distance,
      },
      top2DistanceMargin: math.max(0.0, margin),
      candidates: List.unmodifiable(candidates),
      dimensionEvidenceSufficiency: Map.unmodifiable(e),
      shadowOnly: true,
    );
  }

  /// E_j = min(1, n_j / n_j_min) for sourced inputs.
  Map<String, double> evidenceSufficiencyFor(PersonaShadowInput input) {
    _validateEligibility(input);
    return _evidenceSufficiency(input);
  }

  void _validateEligibility(PersonaShadowInput input) {
    final src = input.source;
    if (!src.hasAuthenticatedOwner) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.ownerUnavailable,
        'Authenticated owner_uid required',
      );
    }
    if (!src.allModulesCompleted) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteAssessments,
        'IQ+EQ+Frequency must be completed',
      );
    }
    if (!src.hasPolicyVersions) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.missingPolicyVersions,
        'Canonical scoring-policy versions required',
      );
    }
    if (!src.hasBankOrSessionVersions) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.missingBankOrSessionVersions,
        'Bank/session versions required',
      );
    }
    if (input.dimensionRegistryVersion != catalog.dimensionRegistryVersion) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompatibleConfig,
        'Input registry ${input.dimensionRegistryVersion} incompatible',
      );
    }

    for (final d in catalog.dimensionOrder) {
      if (!input.dimensionScores.containsKey(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.incompleteDimensionScores,
          'Missing score for $d',
        );
      }
      final x = input.dimensionScores[d]!;
      if (!x.isFinite || x < 0.0 || x > 1.0) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.outOfRangeScore,
          'Score out of [0,1] for $d: $x',
        );
      }
      if (!src.dimensionEvidenceCounts.containsKey(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.missingEvidenceCount,
          'Missing evidence_count for $d',
        );
      }
    }
    for (final d in input.dimensionScores.keys) {
      if (PersonaDimensionIds.forbiddenAliases.contains(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.legacyDimensionAlias,
          'Legacy alias not allowed: $d',
        );
      }
      if (!PersonaDimensionIds.allSet.contains(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.unknownDimension,
          'Unknown dimension: $d',
        );
      }
    }
  }

  Map<String, double> _evidenceSufficiency(PersonaShadowInput input) {
    final out = <String, double>{};
    for (final d in catalog.dimensionOrder) {
      final n = input.source.dimensionEvidenceCounts[d] ?? 0;
      final nMin = config.nMin(d);
      if (nMin <= 0) {
        throw StateError('n_min must be > 0 for $d');
      }
      final e = math.min(1.0, n / nMin);
      out[d] = e;
    }
    return out;
  }

  void _assertGroupsScorable(Map<String, double> e) {
    for (final g in const ['iq', 'eq', 'frequency']) {
      var den = 0.0;
      for (final d in PersonaDimensionIds.dimsOf(g)) {
        den += e[d]!;
      }
      if (den <= config.numericalEpsilon) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.insufficientGroupEvidence,
          'insufficient_evidence for group $g (ΣE=0)',
        );
      }
    }
  }

  PersonaShadowCandidate _scorePersona(
    PersonaPrototype p,
    PersonaShadowInput input,
    Map<String, double> e,
    Map<String, double> userShape,
  ) {
    final levelByGroup = <String, double>{};
    final shapeByGroup = <String, double>{};

    for (final g in const ['iq', 'eq', 'frequency']) {
      final dims = PersonaDimensionIds.dimsOf(g);
      final targetMean = _wavg(
        values: {for (final d in dims) d: p.targetVector[d]!},
        weights: {for (final d in dims) d: p.dimensionWeights[d]!},
        context: 'persona_mean_${p.personaId}_$g',
      );
      final personaShape = <String, double>{
        for (final d in dims) d: p.targetVector[d]! - targetMean,
      };

      final levelWeights = <String, double>{
        for (final d in dims) d: e[d]! * p.dimensionWeights[d]!,
      };
      final levelVals = <String, double>{
        for (final d in dims)
          d: _sq(input.dimensionScores[d]! - p.targetVector[d]!),
      };
      levelByGroup[g] = _wavg(
        values: levelVals,
        weights: levelWeights,
        context: 'level_${p.personaId}_$g',
      );

      final shapeVals = <String, double>{
        for (final d in dims) d: _sq(userShape[d]! - personaShape[d]!),
      };
      shapeByGroup[g] = _wavg(
        values: shapeVals,
        weights: levelWeights,
        context: 'shape_${p.personaId}_$g',
      );
    }

    final dLevel = config.iqWeight * levelByGroup['iq']! +
        config.eqWeight * levelByGroup['eq']! +
        config.frequencyWeight * levelByGroup['frequency']!;
    final dShape = config.iqWeight * shapeByGroup['iq']! +
        config.eqWeight * shapeByGroup['eq']! +
        config.frequencyWeight * shapeByGroup['frequency']!;
    final dCore = config.levelDistanceWeight * dLevel +
        config.shapeDistanceWeight * dShape;

    final a = _antiTraitPenalty(p, input, e);
    final omega = _minimumEvidencePenalty(p, e);
    // Core Engine shadow form: clip(0.85 D_core + 0.10 A + 0.05 Ω, 0, 1)
    final total = _clip01(
      (1.0 -
                  config.antiTraitPenaltyWeight -
                  config.minimumEvidencePenaltyWeight) *
              dCore +
          config.antiTraitPenaltyWeight * a +
          config.minimumEvidencePenaltyWeight * omega,
    );

    return PersonaShadowCandidate(
      personaId: p.personaId,
      distance: total,
      coreDistance: dCore,
      levelDistance: dLevel,
      shapeDistance: dShape,
      antiTraitPenalty: a,
      minimumEvidencePenalty: omega,
      tieBreakRank: p.tieBreakRank,
      levelByGroup: Map.unmodifiable(levelByGroup),
      shapeByGroup: Map.unmodifiable(shapeByGroup),
    );
  }

  /// Existing v2 anti-trait rules; weighted by severity * E_j (no R_j).
  double _antiTraitPenalty(
    PersonaPrototype p,
    PersonaShadowInput input,
    Map<String, double> e,
  ) {
    if (p.antiTraits.isEmpty) return 0.0;
    final nums = <double>[];
    final dens = <double>[];
    for (final at in p.antiTraits) {
      final d = at.dimensionId;
      final count = input.source.dimensionEvidenceCounts[d] ?? 0;
      if (count < at.minimumEvidenceRequired) continue;
      final ej = e[d] ?? 0.0;
      if (ej <= config.numericalEpsilon) continue;
      final x = input.dimensionScores[d];
      if (x == null) continue;
      final sigma = at.direction == 'below' ? -1.0 : 1.0;
      final nu = _clip01(sigma * (x - at.threshold));
      final h = at.severity;
      nums.add(nu * h * ej);
      dens.add(h * ej);
    }
    if (dens.isEmpty) return 0.0;
    final den = dens.fold<double>(0.0, (a, b) => a + b);
    if (den <= config.numericalEpsilon) return 0.0;
    final num = nums.fold<double>(0.0, (a, b) => a + b);
    return _clip01(num / den);
  }

  /// Maps v2 critical count floors onto sufficiency space via n_min.
  ///
  /// `e_min_p,j = min(1, minimum_evidence_per_critical_dimension / n_j_min)`
  /// using only existing v2 fields + frozen shadow n_min (no invented thresholds).
  double _minimumEvidencePenalty(
    PersonaPrototype p,
    Map<String, double> e,
  ) {
    final crit = p.minimumEvidence.criticalDimensions;
    if (crit.isEmpty) return 0.0;
    final floorCount = p.minimumEvidence.minimumEvidencePerCriticalDimension;
    final nums = <double>[];
    final dens = <double>[];
    for (final d in crit) {
      final nMin = config.nMin(d);
      final eMin = math.min(1.0, floorCount / nMin);
      final ej = e[d] ?? 0.0;
      final omega = math.max(0.0, eMin - ej);
      // Equal critical weights when v2 does not define per-dim w_min.
      const wMin = 1.0;
      nums.add(omega * wMin);
      dens.add(wMin);
    }
    final den = dens.fold<double>(0.0, (a, b) => a + b);
    if (den <= config.numericalEpsilon) return 0.0;
    return _clip01(nums.fold<double>(0.0, (a, b) => a + b) / den);
  }

  double _wavg({
    required Map<String, double> values,
    required Map<String, double> weights,
    required String context,
  }) {
    var num = 0.0;
    var den = 0.0;
    for (final e in values.entries) {
      final w = weights[e.key] ?? 0.0;
      if (w < 0) {
        throw StateError('Negative weight in $context for ${e.key}');
      }
      num += w * e.value;
      den += w;
    }
    if (den <= config.numericalEpsilon) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.insufficientGroupEvidence,
        'insufficient_evidence ($context)',
      );
    }
    return num / den;
  }

  List<PersonaPrototype> _personasStable() {
    final list = List<PersonaPrototype>.of(catalog.personas);
    list.sort((a, b) {
      final r = a.tieBreakRank.compareTo(b.tieBreakRank);
      if (r != 0) return r;
      return a.personaId.compareTo(b.personaId);
    });
    return list;
  }

  int _compare(PersonaShadowCandidate a, PersonaShadowCandidate b) {
    final d = a.distance.compareTo(b.distance);
    if ((a.distance - b.distance).abs() > config.numericalEpsilon) return d;
    final r = a.tieBreakRank.compareTo(b.tieBreakRank);
    if (r != 0) return r;
    return a.personaId.compareTo(b.personaId);
  }

  static double _sq(double v) => v * v;

  static double _clip01(double v) => v.clamp(0.0, 1.0);
}
