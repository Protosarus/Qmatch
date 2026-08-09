import 'dart:math' as math;

import 'persona_candidate_score.dart';
import 'persona_dimension_profile.dart';
import 'persona_prototype.dart';
import 'persona_scoring_config.dart';
import 'persona_scoring_input.dart';
import 'persona_scoring_parsers.dart';
import 'persona_scoring_result.dart';
import 'persona_scoring_status.dart';

/// Pure, deterministic, side-effect-free persona scoring library.
///
/// Similarity is NOT probability. Not production-wired. No Firebase / UI.
class PersonaScoringService {
  final PersonaProfileCatalog catalog;
  final PersonaScoringConfig config;

  PersonaScoringService({
    required this.catalog,
    required this.config,
  }) {
    PersonaScoringParsers.assertCompatible(catalog, config);
  }

  String get scoringVersion =>
      '${catalog.personaProfileVersion}+${config.configVersion}';

  /// Score a profile. Identical inputs → identical outputs.
  PersonaScoringResult score(PersonaScoringInput input) {
    _assertFiniteInput(input);

    final missing = _resolveMissing(input);
    final q = _qualityWeights(input, missing);
    final groupCoverage = {
      for (final g in const ['iq', 'eq', 'frequency'])
        g: _groupCoverage(input, missing, g),
    };
    final totalCoverage = _totalCoverage(input, missing);
    final unavailableGroups = <String>[
      for (final g in const ['iq', 'eq', 'frequency'])
        if (!_groupHasScorableDenominator(input, missing, q, g, /*any*/ null))
          g,
    ];

    // Global config coverage gate (before persona ranking).
    final failedRules = <String>[];
    final reasonCodes = <String>[];

    if (totalCoverage + config.numericalEpsilon < config.minimumTotalCoverage) {
      failedRules.add('minimum_total_coverage');
      reasonCodes.add('total_coverage_below_minimum');
    }
    for (final g in const ['iq', 'eq', 'frequency']) {
      final need = config.minimumGroupCoverage[g] ?? 0.0;
      if (groupCoverage[g]! + config.numericalEpsilon < need) {
        failedRules.add('minimum_group_coverage_$g');
        reasonCodes.add('group_coverage_below_minimum_$g');
      }
    }
    if (input.responseValidityStatus == ResponseValidityStatus.invalid) {
      failedRules.add('response_validity_invalid');
      reasonCodes.add('rvi_invalid');
    }

    final allCandidates = <PersonaCandidateScore>[];
    for (final persona in _personasInStableOrder()) {
      final eligibility = _personaEligibility(
          persona, input, missing, totalCoverage, groupCoverage);
      final scored = _scorePersona(
        persona,
        input,
        missing,
        q,
        eligible: eligibility.ok,
      );
      allCandidates.add(scored);
      if (!eligibility.ok) {
        failedRules.addAll(
            eligibility.failedRules.map((r) => '${persona.personaId}:$r'));
      }
    }

    // Deterministic sort of all candidates (for diagnostics).
    allCandidates.sort(_compareCandidates);

    final publishable = allCandidates
        .where((c) => c.eligibleForPublishableRanking)
        .toList(growable: false);

    final globalInsufficient = failedRules.any((r) =>
            r == 'minimum_total_coverage' ||
            r.startsWith('minimum_group_coverage_') ||
            r == 'response_validity_invalid') ||
        publishable.isEmpty;

    if (globalInsufficient) {
      if (publishable.isEmpty && !reasonCodes.contains('no_eligible_persona')) {
        reasonCodes.add('no_eligible_persona');
      }
      return _insufficientResult(
        input: input,
        missing: missing,
        groupCoverage: groupCoverage,
        totalCoverage: totalCoverage,
        unavailableGroups: unavailableGroups,
        failedRules: failedRules.toSet().toList()..sort(),
        reasonCodes: reasonCodes.toSet().toList()..sort(),
        candidates: allCandidates,
      );
    }

    final primary = publishable[0];
    final secondary = publishable.length > 1 ? publishable[1] : null;
    final margin = secondary == null
        ? primary.similarity
        : primary.similarity - secondary.similarity;
    final exactTie =
        secondary != null && margin.abs() <= config.numericalEpsilon;
    final ambiguous = exactTie || margin < config.top2MarginThreshold;

    final separatorTargets = <String>{};
    if (secondary != null) {
      separatorTargets.addAll(
        catalog.byId[primary.personaId]
                ?.separatorTargets[secondary.personaId] ??
            const [],
      );
      separatorTargets.addAll(
        catalog.byId[secondary.personaId]
                ?.separatorTargets[primary.personaId] ??
            const [],
      );
    }

    final status = ambiguous
        ? PersonaScoringStatus.ambiguous
        : (catalog.isSyntheticValidationOnly
            ? PersonaScoringStatus.validForShadowEvaluation
            : PersonaScoringStatus.provisional);

    final confidence = _confidence(
      input: input,
      totalCoverage: totalCoverage,
      groupCoverage: groupCoverage,
      margin: margin,
      ambiguous: ambiguous,
      insufficient: false,
      primary: primary,
    );

    return PersonaScoringResult(
      status: status,
      primaryPersonaId: primary.personaId,
      secondaryPersonaId: secondary?.personaId,
      primarySimilarity: primary.similarity,
      secondarySimilarity: secondary?.similarity,
      top2Margin: margin,
      ambiguous: ambiguous,
      insufficientEvidence: false,
      totalCoverage: totalCoverage,
      groupCoverage: groupCoverage,
      missingDimensions: missing.toList()..sort(),
      unavailableGroups: unavailableGroups,
      failedEvidenceRules: const [],
      reasonCodes: ambiguous
          ? (exactTie
              ? const ['exact_tie', 'top2_margin_below_threshold']
              : const ['top2_margin_below_threshold'])
          : const ['shadow_evaluation_only'],
      confidenceLevel: confidence.level,
      confidenceScore: confidence.score,
      confidenceComponents: confidence.components,
      confidenceReasonCodes: confidence.reasonCodes,
      candidates: allCandidates,
      separatorTargetsForTopPair: separatorTargets.toList()..sort(),
      ambiguityReason: ambiguous
          ? (exactTie ? 'exact_similarity_tie' : 'top2_margin_below_threshold')
          : '',
      scoringVersion: scoringVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringConfigVersion: config.configVersion,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      calibrationStatus: catalog.calibrationStatus,
      productionValid: false,
      publishablePrimary: true,
    );
  }

  List<PersonaPrototype> _personasInStableOrder() {
    final list = [...catalog.personas];
    list.sort((a, b) {
      final r = a.tieBreakRank.compareTo(b.tieBreakRank);
      if (r != 0) return r;
      return a.personaId.compareTo(b.personaId);
    });
    return list;
  }

  int _compareCandidates(PersonaCandidateScore a, PersonaCandidateScore b) {
    // Publishable first for ranking views; within class: sim desc, rank asc, id.
    if (a.eligibleForPublishableRanking != b.eligibleForPublishableRanking) {
      return a.eligibleForPublishableRanking ? -1 : 1;
    }
    final s = b.similarity.compareTo(a.similarity);
    if (s != 0) return s;
    final r = a.tieBreakRank.compareTo(b.tieBreakRank);
    if (r != 0) return r;
    return a.personaId.compareTo(b.personaId);
  }

  Set<String> _resolveMissing(PersonaScoringInput input) {
    final missing = <String>{...input.missingDimensions};
    for (final d in catalog.dimensionOrder) {
      final hasScore = input.dimensionScores.containsKey(d);
      final ev = input.dimensionEvidenceCounts[d] ?? 0;
      if (!hasScore || ev <= 0) missing.add(d);
    }
    // Never invent scores for missing dims.
    return missing;
  }

  Map<String, double> _qualityWeights(
    PersonaScoringInput input,
    Set<String> missing,
  ) {
    final q = <String, double>{};
    for (final d in catalog.dimensionOrder) {
      if (missing.contains(d) || !input.dimensionScores.containsKey(d)) {
        q[d] = 0.0;
        continue;
      }
      final ev = input.dimensionEvidenceCounts[d] ?? 0;
      if (ev <= 0) {
        q[d] = 0.0;
        continue;
      }
      final evidenceSufficiency = _evidenceSufficiency(input, d, ev);
      final reliability =
          (input.dimensionReliability[d] ?? 1.0).clamp(0.0, 1.0);
      q[d] = reliability * evidenceSufficiency;
    }
    return q;
  }

  /// Canonical: explicit per-dimension sufficiency.
  /// Deprecated offline adapter: `min(1, evidenceCount / 3)`.
  double _evidenceSufficiency(
    PersonaScoringInput input,
    String dimensionId,
    int evidenceCount,
  ) {
    switch (input.evidenceSufficiencyMode) {
      case PersonaEvidenceSufficiencyMode.explicit:
        final s = input.dimensionEvidenceSufficiency[dimensionId];
        if (s == null) {
          // Explicit mode without a value must not invent sufficiency via /3.
          return 0.0;
        }
        return s.clamp(0.0, 1.0);
      case PersonaEvidenceSufficiencyMode.deprecatedGlobalDenominator:
        return math.min(1.0, evidenceCount / 3.0);
    }
  }

  double _totalCoverage(PersonaScoringInput input, Set<String> missing) {
    var present = 0;
    for (final d in catalog.dimensionOrder) {
      if (!missing.contains(d) &&
          input.dimensionScores.containsKey(d) &&
          (input.dimensionEvidenceCounts[d] ?? 0) > 0) {
        present++;
      }
    }
    return present / catalog.dimensionOrder.length;
  }

  double _groupCoverage(
    PersonaScoringInput input,
    Set<String> missing,
    String group,
  ) {
    final ds = PersonaDimensionIds.dimsOf(group);
    var present = 0;
    for (final d in ds) {
      if (!missing.contains(d) &&
          input.dimensionScores.containsKey(d) &&
          (input.dimensionEvidenceCounts[d] ?? 0) > 0) {
        present++;
      }
    }
    return present / ds.length;
  }

  ({bool ok, List<String> failedRules}) _personaEligibility(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
    double totalCoverage,
    Map<String, double> groupCoverage,
  ) {
    final failed = <String>[];
    final needTotal = math.max(
      p.minimumEvidence.minimumTotalCoverage,
      config.minimumTotalCoverage,
    );
    if (totalCoverage + config.numericalEpsilon < needTotal) {
      failed.add('persona_total_coverage');
    }
    for (final g in const ['iq', 'eq', 'frequency']) {
      final need = math.max(
        p.minimumEvidence.minimumGroupCoverage[g] ?? 0.0,
        config.minimumGroupCoverage[g] ?? 0.0,
      );
      if (groupCoverage[g]! + config.numericalEpsilon < need) {
        failed.add('persona_group_coverage_$g');
      }
    }
    final minCrit = p.minimumEvidence.minimumEvidencePerCriticalDimension;
    for (final d in p.minimumEvidence.criticalDimensions) {
      if (missing.contains(d) ||
          !input.dimensionScores.containsKey(d) ||
          (input.dimensionEvidenceCounts[d] ?? 0) < minCrit) {
        failed.add('critical_dimension_$d');
      }
    }
    return (ok: failed.isEmpty, failedRules: failed);
  }

  bool _groupHasScorableDenominator(
    PersonaScoringInput input,
    Set<String> missing,
    Map<String, double> q,
    String group,
    PersonaPrototype? persona,
  ) {
    var den = 0.0;
    for (final d in PersonaDimensionIds.dimsOf(group)) {
      final qq = q[d] ?? 0.0;
      final w = persona?.dimensionWeights[d] ?? 1.0;
      if (qq > 0 && w > 0 && !missing.contains(d)) den += qq * w;
    }
    return den > config.numericalEpsilon;
  }

  /// Group-normalized level distance. Returns null when unavailable.
  double? levelDistance(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
    Map<String, double> q,
    String group,
  ) {
    var num = 0.0;
    var den = 0.0;
    for (final d in PersonaDimensionIds.dimsOf(group)) {
      final qq = q[d] ?? 0.0;
      final w = p.dimensionWeights[d] ?? 0.0;
      if (qq <= 0 || w <= 0 || missing.contains(d)) continue;
      final x = input.dimensionScores[d];
      if (x == null) continue;
      final t = p.targetVector[d]!;
      final diff = x - t;
      num += qq * w * diff * diff;
      den += qq * w;
    }
    if (den <= config.numericalEpsilon) return null;
    final v = num / den;
    if (!v.isFinite) {
      throw StateError('Non-finite level distance for ${p.personaId}/$group');
    }
    return v;
  }

  /// Group-normalized shape distance. Returns null when unavailable.
  double? shapeDistance(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
    Map<String, double> q,
    String group,
  ) {
    final ds = PersonaDimensionIds.dimsOf(group);
    var xNum = 0.0, xDen = 0.0, tNum = 0.0, tDen = 0.0;
    for (final d in ds) {
      final qq = q[d] ?? 0.0;
      if (qq <= 0 || missing.contains(d)) continue;
      final x = input.dimensionScores[d];
      if (x == null) continue;
      xNum += qq * x;
      xDen += qq;
      tNum += qq * p.targetVector[d]!;
      tDen += qq;
    }
    if (xDen <= config.numericalEpsilon || tDen <= config.numericalEpsilon) {
      return null;
    }
    final xBar = xNum / xDen;
    final tBar = tNum / tDen;

    var num = 0.0;
    var den = 0.0;
    for (final d in ds) {
      final qq = q[d] ?? 0.0;
      final w = p.dimensionWeights[d] ?? 0.0;
      if (qq <= 0 || w <= 0 || missing.contains(d)) continue;
      final x = input.dimensionScores[d];
      if (x == null) continue;
      final s = x - xBar;
      final sp = p.targetVector[d]! - tBar;
      final diff = s - sp;
      num += qq * w * diff * diff;
      den += qq * w;
    }
    if (den <= config.numericalEpsilon) return null;
    final v = num / den;
    if (!v.isFinite) {
      throw StateError('Non-finite shape distance for ${p.personaId}/$group');
    }
    return v;
  }

  PersonaCandidateScore _scorePersona(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
    Map<String, double> q, {
    required bool eligible,
  }) {
    final breakdowns = <PersonaGroupDistanceBreakdown>[];
    var dBase = 0.0;
    final availableWeights = <String, double>{};

    for (final g in const ['iq', 'eq', 'frequency']) {
      final gw = config.groupWeight(g);
      final dl = levelDistance(p, input, missing, q, g);
      final ds = shapeDistance(p, input, missing, q, g);
      final available = dl != null && ds != null;
      if (available) {
        final combined =
            config.levelDistanceWeight * dl + config.shapeDistanceWeight * ds;
        availableWeights[g] = gw;
        breakdowns.add(
          PersonaGroupDistanceBreakdown(
            group: g,
            available: true,
            levelDistance: dl,
            shapeDistance: ds,
            combinedDistance: combined,
            configuredGroupWeight: gw,
            appliedGroupWeight: gw, // filled after renorm decision
          ),
        );
      } else {
        breakdowns.add(
          PersonaGroupDistanceBreakdown(
            group: g,
            available: false,
            levelDistance: null,
            shapeDistance: null,
            combinedDistance: null,
            configuredGroupWeight: gw,
            appliedGroupWeight: 0.0,
          ),
        );
      }
    }

    // Combine groups: do NOT renorm unless config explicitly allows.
    // Unavailable groups contribute nothing (same numeric effect as D=0
    // under fixed weights without claiming a fabricated distance).
    final renorm =
        config.allowPartialGroupRenormalization && availableWeights.isNotEmpty;
    final weightSum = availableWeights.values.fold<double>(0, (a, b) => a + b);
    final adjusted = <PersonaGroupDistanceBreakdown>[];
    for (final b in breakdowns) {
      if (!b.available || b.combinedDistance == null) {
        adjusted.add(b);
        continue;
      }
      final applied = renorm
          ? (b.configuredGroupWeight / weightSum)
          : b.configuredGroupWeight;
      dBase += applied * b.combinedDistance!;
      adjusted.add(
        PersonaGroupDistanceBreakdown(
          group: b.group,
          available: true,
          levelDistance: b.levelDistance,
          shapeDistance: b.shapeDistance,
          combinedDistance: b.combinedDistance,
          configuredGroupWeight: b.configuredGroupWeight,
          appliedGroupWeight: applied,
        ),
      );
    }

    final anti = _antiPenalty(p, input, missing);
    final missPen = _missingPenalty(p, input, missing);
    final distance = dBase +
        config.antiTraitPenaltyWeight * anti.total +
        config.missingEvidencePenaltyWeight * missPen;
    if (!distance.isFinite) {
      throw StateError('Non-finite distance for ${p.personaId}');
    }
    final similarity = math.exp(-distance / config.similarityTemperature);
    if (!similarity.isFinite || similarity <= 0 || similarity > 1.0 + 1e-12) {
      throw StateError('Invalid similarity for ${p.personaId}: $similarity');
    }

    final supportCounter = _supportAndCounter(p, input, missing, q);

    return PersonaCandidateScore(
      personaId: p.personaId,
      similarity: similarity.clamp(0.0, 1.0),
      distance: distance,
      baseDistance: dBase,
      antiTraitPenalty: anti.total,
      missingEvidencePenalty: missPen,
      tieBreakRank: p.tieBreakRank,
      eligibleForPublishableRanking: eligible,
      nonPublishableDiagnosticOnly: !eligible,
      groupDistances: adjusted,
      strongestSupportingDimensions: supportCounter.support,
      strongestCounterEvidenceDimensions: supportCounter.counter,
      appliedAntiTraits: anti.applied,
      missingCriticalEvidence: [
        for (final d in p.minimumEvidence.criticalDimensions)
          if (missing.contains(d) ||
              !input.dimensionScores.containsKey(d) ||
              (input.dimensionEvidenceCounts[d] ?? 0) <
                  p.minimumEvidence.minimumEvidencePerCriticalDimension)
            d,
      ],
      closestCompetitors: p.closestCompetitors,
      separatorTargets: p.separatorTargets,
    );
  }

  ({double total, List<AppliedAntiTraitEvidence> applied}) _antiPenalty(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
  ) {
    var a = 0.0;
    final applied = <AppliedAntiTraitEvidence>[];
    for (final at in p.antiTraits) {
      if (missing.contains(at.dimensionId)) continue;
      final e = input.dimensionEvidenceCounts[at.dimensionId] ?? 0;
      if (e < at.minimumEvidenceRequired) continue;
      final v = input.dimensionScores[at.dimensionId];
      if (v == null) continue;
      final hit = at.direction == 'below' ? v < at.threshold : v > at.threshold;
      if (!hit) continue;
      a += at.severity;
      applied.add(
        AppliedAntiTraitEvidence(
          dimensionId: at.dimensionId,
          direction: at.direction,
          threshold: at.threshold,
          observedValue: v,
          severity: at.severity,
          rationale: at.rationale,
        ),
      );
    }
    return (total: math.min(1.0, a), applied: applied);
  }

  double _missingPenalty(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
  ) {
    var miss = 0.0;
    for (final d in p.minimumEvidence.criticalDimensions) {
      if (missing.contains(d) ||
          !input.dimensionScores.containsKey(d) ||
          (input.dimensionEvidenceCounts[d] ?? 0) <= 0) {
        miss += 0.25;
      }
    }
    final cov = _totalCoverage(input, missing);
    miss += math.max(0.0, 0.45 - cov);
    return math.min(1.0, miss);
  }

  ({List<String> support, List<String> counter}) _supportAndCounter(
    PersonaPrototype p,
    PersonaScoringInput input,
    Set<String> missing,
    Map<String, double> q,
  ) {
    final scored = <({String d, double err, double w})>[];
    for (final d in catalog.dimensionOrder) {
      if (missing.contains(d)) continue;
      final x = input.dimensionScores[d];
      if (x == null) continue;
      final qq = q[d] ?? 0.0;
      if (qq <= 0) continue;
      final w = p.dimensionWeights[d] ?? 0.0;
      final t = p.targetVector[d]!;
      final err = (x - t) * (x - t);
      scored.add((d: d, err: err, w: w * qq));
    }
    final support = [...scored]..sort((a, b) {
        final c = a.err.compareTo(b.err);
        if (c != 0) return c;
        return b.w.compareTo(a.w);
      });
    final counter = [...scored]..sort((a, b) {
        final c = (b.err * b.w).compareTo(a.err * a.w);
        if (c != 0) return c;
        return a.d.compareTo(b.d);
      });
    return (
      support: support.take(5).map((e) => e.d).toList(),
      counter: counter.take(5).map((e) => e.d).toList(),
    );
  }

  ({
    PersonaConfidenceLevel level,
    double score,
    PersonaConfidenceComponents components,
    List<String> reasonCodes,
  }) _confidence({
    required PersonaScoringInput input,
    required double totalCoverage,
    required Map<String, double> groupCoverage,
    required double? margin,
    required bool ambiguous,
    required bool insufficient,
    required PersonaCandidateScore? primary,
  }) {
    final reasonCodes = <String>[];
    var critCov = 1.0;
    if (primary != null) {
      final p = catalog.byId[primary.personaId]!;
      if (p.minimumEvidence.criticalDimensions.isEmpty) {
        critCov = 1.0;
      } else {
        var ok = 0;
        for (final d in p.minimumEvidence.criticalDimensions) {
          if ((input.dimensionEvidenceCounts[d] ?? 0) >=
              p.minimumEvidence.minimumEvidencePerCriticalDimension) {
            ok++;
          }
        }
        critCov = ok / p.minimumEvidence.criticalDimensions.length;
      }
    } else {
      critCov = 0.0;
    }

    var relSum = 0.0;
    var relN = 0;
    for (final d in catalog.dimensionOrder) {
      if (input.dimensionScores.containsKey(d) &&
          (input.dimensionEvidenceCounts[d] ?? 0) > 0) {
        relSum += input.dimensionReliability[d] ?? 1.0;
        relN++;
      }
    }
    final meanRel = relN == 0 ? 0.0 : relSum / relN;

    final components = PersonaConfidenceComponents(
      totalCoverage: totalCoverage,
      groupCoverage: groupCoverage,
      criticalDimensionCoverage: critCov,
      meanReliability: meanRel,
      responseValidityStatus: input.responseValidityStatus,
      top2Margin: margin,
      prototypeCalibrationStatus: catalog.calibrationStatus,
      provisionalCalibrationMarker: catalog.isSyntheticValidationOnly,
    );

    if (insufficient) {
      reasonCodes
          .addAll(const ['insufficient_evidence', 'confidence_insufficient']);
      return (
        level: PersonaConfidenceLevel.insufficient,
        score: 0.0,
        components: components,
        reasonCodes: reasonCodes,
      );
    }

    // Transparent linear blend in [0,1] — not psychological certainty.
    final marginTerm = margin == null
        ? 0.0
        : (margin / (config.top2MarginThreshold * 2)).clamp(0.0, 1.0);
    var score = 0.30 * totalCoverage +
        0.20 * ((groupCoverage['eq']! + groupCoverage['frequency']!) / 2.0) +
        0.20 * critCov +
        0.15 * meanRel +
        0.15 * marginTerm;
    if (ambiguous) {
      score *= 0.55;
      reasonCodes.add('ambiguity_reduces_confidence');
    }
    if (catalog.isSyntheticValidationOnly) {
      reasonCodes.add('synthetic_validation_only');
    }
    if (input.responseValidityStatus == ResponseValidityStatus.suspect) {
      score *= 0.85;
      reasonCodes.add('rvi_suspect');
    }

    score = score.clamp(0.0, 1.0);
    PersonaConfidenceLevel level;
    if (ambiguous || score < 0.40) {
      level = PersonaConfidenceLevel.low;
      reasonCodes.add('confidence_low');
    } else if (margin != null &&
        margin >= config.top2MarginThreshold * 2 &&
        score >= config.lowConfidenceThreshold) {
      // High is allowed only with explicit provisional marker in components.
      level = PersonaConfidenceLevel.high;
      reasonCodes.add('confidence_high_provisional');
    } else {
      level = PersonaConfidenceLevel.moderate;
      reasonCodes.add('confidence_moderate');
    }

    return (
      level: level,
      score: score,
      components: components,
      reasonCodes: reasonCodes,
    );
  }

  PersonaScoringResult _insufficientResult({
    required PersonaScoringInput input,
    required Set<String> missing,
    required Map<String, double> groupCoverage,
    required double totalCoverage,
    required List<String> unavailableGroups,
    required List<String> failedRules,
    required List<String> reasonCodes,
    required List<PersonaCandidateScore> candidates,
  }) {
    final confidence = _confidence(
      input: input,
      totalCoverage: totalCoverage,
      groupCoverage: groupCoverage,
      margin: null,
      ambiguous: false,
      insufficient: true,
      primary: null,
    );
    return PersonaScoringResult(
      status: PersonaScoringStatus.insufficientEvidence,
      primaryPersonaId: null,
      secondaryPersonaId: null,
      primarySimilarity: null,
      secondarySimilarity: null,
      top2Margin: null,
      ambiguous: false,
      insufficientEvidence: true,
      totalCoverage: totalCoverage,
      groupCoverage: groupCoverage,
      missingDimensions: missing.toList()..sort(),
      unavailableGroups: unavailableGroups,
      failedEvidenceRules: failedRules,
      reasonCodes: reasonCodes,
      confidenceLevel: PersonaConfidenceLevel.insufficient,
      confidenceScore: 0.0,
      confidenceComponents: confidence.components,
      confidenceReasonCodes: confidence.reasonCodes,
      candidates: candidates,
      separatorTargetsForTopPair: const [],
      ambiguityReason: '',
      scoringVersion: scoringVersion,
      personaProfileVersion: catalog.personaProfileVersion,
      personaScoringConfigVersion: config.configVersion,
      dimensionRegistryVersion: catalog.dimensionRegistryVersion,
      calibrationStatus: catalog.calibrationStatus,
      productionValid: false,
      publishablePrimary: false,
    );
  }

  void _assertFiniteInput(PersonaScoringInput input) {
    for (final e in input.dimensionScores.entries) {
      if (!PersonaDimensionIds.allSet.contains(e.key)) {
        throw ArgumentError('Unknown dimension score: ${e.key}');
      }
      if (!e.value.isFinite || e.value < 0 || e.value > 1) {
        throw ArgumentError('Invalid score for ${e.key}: ${e.value}');
      }
    }
    for (final e in input.dimensionReliability.entries) {
      if (!e.value.isFinite || e.value < 0 || e.value > 1) {
        throw ArgumentError('Invalid reliability for ${e.key}');
      }
    }
  }
}
