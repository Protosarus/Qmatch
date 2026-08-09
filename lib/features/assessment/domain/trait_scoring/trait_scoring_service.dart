import 'dart:math' as math;

import '../persona_scoring/persona_dimension_profile.dart';
import 'assessment_item_definition.dart';
import 'assessment_response.dart';
import 'dimension_score_result.dart';
import 'module_trait_result.dart';
import 'response_validity_input.dart';
import 'response_validity_result.dart';
import 'reverse_pair_descriptor.dart';
import 'trait_scoring_config.dart';
import 'trait_scoring_validation_exception.dart';

/// Pure deterministic trait scoring engine (P2A-2A). Offline / test-only.
class TraitScoringService {
  final TraitScoringConfig config;

  const TraitScoringService({required this.config});

  TraitScoringResult scoreModule(
    TraitScoringSessionInput input, {
    ResponseValidityInput rviInput = const ResponseValidityInput(),
  }) {
    if (input.traitScoringVersion != config.traitScoringVersion) {
      throw TraitScoringValidationException(
        'trait_scoring_version mismatch',
        [
          TraitValidationError(
            fieldPath: 'traitScoringVersion',
            reasonCode: 'version_mismatch',
            explanation:
                '${input.traitScoringVersion} vs ${config.traitScoringVersion}',
          ),
        ],
      );
    }
    if (input.schemaVersion != config.questionSchemaVersion) {
      throw TraitScoringValidationException('schema_version mismatch');
    }

    final byId = {
      for (final q in input.questionDefinitions) q.questionId: q,
    };
    final responses = {
      for (final r in input.submittedResponses) r.questionId: r,
    };

    final moduleDims = PersonaDimensionIds.all
        .where((d) => config.requireDimension(d).module == input.module)
        .toList();

    final tracesByDim = {
      for (final d in moduleDims) d: <DimensionEvidenceTrace>[]
    };
    var correctCount = 0;
    var answered = 0;
    final rawAnswers = <String, Object?>{};

    for (final r in input.submittedResponses) {
      final item = byId[r.questionId];
      if (item == null) continue;
      final rt =
          r.responseTimeMilliseconds ?? input.responseTimes[r.questionId];

      if (input.module == 'iq') {
        if (r.selectedOptionId == null) continue;
        answered++;
        final correct = r.selectedOptionId == item.correctOptionId;
        if (correct) correctCount++;
        rawAnswers[r.questionId] = {
          'selected_option_id': r.selectedOptionId,
          'correct': correct,
          'response_time_ms': rt,
        };
        final weight = config.defaultIqItemWeight;
        tracesByDim[item.primaryDimension]!.add(
          DimensionEvidenceTrace(
            questionId: item.questionId,
            dimensionId: item.primaryDimension,
            delta: correct ? 1.0 : 0.0,
            evidenceStrength: weight,
            primary: true,
            contextIdentity: item.contextIdentity,
            reverseAligned: false,
            appliedWeight: weight,
          ),
        );
      } else {
        Map<String, double>? deltas;
        double strength = 1.0;
        String? oid = r.selectedOptionId;
        if (item.itemType == 'likert' &&
            r.likertValue != null &&
            item.scalePointDeltas != null) {
          deltas = item.scalePointDeltas!['${r.likertValue}'];
          oid = 'likert_${r.likertValue}';
        } else if (oid != null) {
          AssessmentOptionDefinition? opt;
          for (final o in item.options) {
            if (o.optionId == oid) {
              opt = o;
              break;
            }
          }
          if (opt == null) continue;
          deltas = opt.dimensionDeltas;
          strength = opt.evidenceStrength.clamp(0.0, 1.0);
        } else {
          continue;
        }
        if (deltas == null || deltas.isEmpty) continue;
        answered++;
        rawAnswers[r.questionId] = {
          'selected_option_id': oid,
          'likert_value': r.likertValue,
          'response_time_ms': rt,
        };
        for (final e in deltas.entries) {
          if (!tracesByDim.containsKey(e.key)) continue;
          var delta = e.value;
          // Reverse pair alignment: if item is reverse-keyed for primary, flip primary.
          final reverseAligned = item.reversePairId != null &&
              e.key == item.primaryDimension &&
              delta < 0;
          final primary = e.key == item.primaryDimension;
          tracesByDim[e.key]!.add(
            DimensionEvidenceTrace(
              questionId: item.questionId,
              dimensionId: e.key,
              delta: delta,
              evidenceStrength: strength,
              primary: primary,
              contextIdentity: item.contextIdentity,
              reverseAligned: reverseAligned,
              appliedWeight: strength,
            ),
          );
        }
      }
    }

    final dimResults = <DimensionScoreResult>[];
    for (final d in moduleDims) {
      dimResults.add(
        _scoreDimension(
          dimensionId: d,
          module: input.module,
          traces: tracesByDim[d]!,
          items: byId,
          responses: responses,
          input: input,
        ),
      );
    }

    final rvi = _computeRvi(
      input: input,
      items: byId,
      responses: responses,
      rviInput: rviInput,
      dimResults: dimResults,
    );

    final scores = <String, double>{};
    final ev = <String, double>{};
    final prim = <String, double>{};
    final sec = <String, double>{};
    final indep = <String, double>{};
    final suff = <String, double>{};
    final rel = <String, double>{};
    final missing = <String>[];
    final insufficient = <String>[];
    final reasons = <String>[];

    for (final dr in dimResults) {
      ev[dr.dimensionId] = dr.totalEvidenceCount;
      prim[dr.dimensionId] = dr.primaryEvidenceCount;
      sec[dr.dimensionId] = dr.secondaryEvidenceCount;
      indep[dr.dimensionId] = dr.independentContextCount;
      suff[dr.dimensionId] = dr.evidenceSufficiency;
      rel[dr.dimensionId] = dr.reliability;
      if (dr.score == null) {
        missing.add(dr.dimensionId);
      } else if (dr.status == DimensionScoreStatus.insufficient ||
          dr.status == DimensionScoreStatus.unavailable) {
        insufficient.add(dr.dimensionId);
        // Partial internal score may exist but is not published.
      } else {
        scores[dr.dimensionId] = dr.score!;
      }
      reasons.addAll(dr.failedEvidenceRules.map((e) => '${dr.dimensionId}:$e'));
    }

    final req = moduleDims
        .where((d) => config.requireDimension(d).requiredForProfileReadiness);
    final ready = req.every((d) => scores.containsKey(d)) &&
        rvi.publishableRecommendation &&
        input.assessmentStatus != 'incomplete';

    ModuleTraitStatus status;
    if (input.assessmentStatus == 'incomplete' || answered == 0) {
      status = ModuleTraitStatus.incomplete;
    } else if (!ready && (missing.isNotEmpty || insufficient.isNotEmpty)) {
      status = ModuleTraitStatus.insufficientEvidence;
    } else if (ready) {
      status = ModuleTraitStatus.readyForShadowEvaluation;
    } else {
      status = ModuleTraitStatus.provisional;
    }

    final module = ModuleTraitResult(
      assessmentType: input.module,
      schemaVersion: input.schemaVersion,
      contentVersion: input.contentVersion,
      traitScoringVersion: input.traitScoringVersion,
      rviVersion: config.rviVersion,
      setId: input.setId,
      locale: input.locale,
      questionCount: input.questionDefinitions.length,
      answeredCount: answered,
      rawAnswers: rawAnswers,
      legacyRawScore: input.module == 'iq' ? correctCount : null,
      dimensionScores: scores,
      dimensionEvidenceCounts: ev,
      dimensionPrimaryEvidenceCounts: prim,
      dimensionSecondaryEvidenceCounts: sec,
      dimensionIndependentContextCounts: indep,
      dimensionEvidenceSufficiency: suff,
      dimensionReliability: rel,
      missingDimensions: missing..sort(),
      insufficientDimensions: insufficient..sort(),
      responseValidity: rvi,
      canonicalProfileReady: ready,
      status: status,
      startedAt: input.startedAt,
      completedAt: input.completedAt,
      reasonCodes: reasons.toSet().toList()..sort(),
      dimensionDetails: dimResults,
    );
    return TraitScoringResult(module: module);
  }

  DimensionScoreResult _scoreDimension({
    required String dimensionId,
    required String module,
    required List<DimensionEvidenceTrace> traces,
    required Map<String, AssessmentItemDefinition> items,
    required Map<String, AssessmentResponse> responses,
    required TraitScoringSessionInput input,
  }) {
    final req = config.requireDimension(dimensionId);
    if (traces.isEmpty) {
      return DimensionScoreResult(
        dimensionId: dimensionId,
        module: module,
        score: null,
        signedEvidenceMean: 0,
        primaryEvidenceCount: 0,
        secondaryEvidenceCount: 0,
        totalEvidenceCount: 0,
        independentContextCount: 0,
        evidenceSufficiency: 0,
        reliability: 0,
        status: DimensionScoreStatus.unavailable,
        failedEvidenceRules: const ['no_evidence'],
        traces: const [],
        reliabilityComponents: const {},
      );
    }

    // Independence: diminish repeated context identities.
    final byContext = <String, List<DimensionEvidenceTrace>>{};
    for (final t in traces) {
      (byContext[t.contextIdentity] ??= []).add(t);
    }
    var num = 0.0;
    var den = 0.0;
    var primary = 0.0;
    var secondary = 0.0;
    var indepContexts = 0.0;
    final adjusted = <DimensionEvidenceTrace>[];

    for (final entry in byContext.entries) {
      final list = entry.value;
      indepContexts += 1.0;
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        final diminish = i == 0
            ? 1.0
            : math.pow(config.sameContextDiminishingFactor, i).toDouble();
        final w = t.evidenceStrength * diminish;
        // Cap single-item influence later via mass share check.
        num += w * t.delta;
        den += w;
        if (t.primary) {
          primary += diminish;
        } else {
          secondary += diminish;
        }
        adjusted.add(
          DimensionEvidenceTrace(
            questionId: t.questionId,
            dimensionId: t.dimensionId,
            delta: t.delta,
            evidenceStrength: t.evidenceStrength,
            primary: t.primary,
            contextIdentity: t.contextIdentity,
            reverseAligned: t.reverseAligned,
            appliedWeight: w,
          ),
        );
      }
    }

    final total = primary + secondary;
    final signedMean = den <= 1e-12 ? 0.0 : num / den;
    // IQ traces use correctness in [0,1]; EQ/Frequency use signed deltas in [-1,1].
    final double score;
    if (module == 'iq') {
      score = signedMean.clamp(0.0, 1.0);
    } else {
      score = ((signedMean + 1.0) / 2.0).clamp(0.0, 1.0);
    }

    // Single-item dominance check
    final failed = <String>[];
    if (den > 1e-12) {
      for (final t in adjusted) {
        final share = t.appliedWeight / den;
        if (share > req.maximumSingleItemInfluence + 1e-9) {
          failed.add('single_item_dominance');
          break;
        }
      }
    }

    final contextFactor =
        (indepContexts / math.max(1.0, req.minimumIndependentContexts))
            .clamp(0.0, 1.0);
    final independenceFactor = contextFactor;
    // Bound sufficiency by primary/total targets and independent contexts.
    final sufficiency = math
        .min(
          1.0,
          math.min(
            primary / req.targetPrimaryEvidence,
            total / req.targetTotalEvidence,
          ),
        )
        .clamp(0.0, 1.0);
    final sufficiencyFinal = (sufficiency * independenceFactor).clamp(0.0, 1.0);

    if (primary + 1e-9 < req.minimumPrimaryEvidence) {
      failed.add('below_minimum_primary_evidence');
    }
    if (total + 1e-9 < req.minimumTotalEvidence) {
      failed.add('below_minimum_total_evidence');
    }
    if (indepContexts + 1e-9 < req.minimumIndependentContexts) {
      failed.add('below_minimum_independent_contexts');
    }

    final relComponents = <String, double>{
      'evidence_sufficiency': sufficiencyFinal,
      'context_independence': independenceFactor,
      'item_information_quality': den > 0 ? 1.0 : 0.0,
    };
    final reliability = _weightedAvailable(
      relComponents,
      config.reliabilityWeights,
      config.renormalizeReliabilityOverAvailable,
    );

    DimensionScoreStatus status;
    if (failed.isNotEmpty || sufficiencyFinal < 1e-9) {
      status = DimensionScoreStatus.insufficient;
    } else if (reliability + 1e-9 < req.minimumReliability) {
      status = DimensionScoreStatus.provisional;
    } else {
      status = DimensionScoreStatus.readyForShadowEvaluation;
    }

    // Publish score only when not unavailable; insufficient keeps score out of
    // dimensionScores map (caller), but we still return computed value for traces.
    return DimensionScoreResult(
      dimensionId: dimensionId,
      module: module,
      score: score,
      signedEvidenceMean: signedMean,
      primaryEvidenceCount: primary,
      secondaryEvidenceCount: secondary,
      totalEvidenceCount: total,
      independentContextCount: indepContexts,
      evidenceSufficiency: sufficiencyFinal,
      reliability: reliability,
      status: status,
      failedEvidenceRules: failed,
      traces: adjusted,
      reliabilityComponents: relComponents,
    );
  }

  ResponseValidityResult _computeRvi({
    required TraitScoringSessionInput input,
    required Map<String, AssessmentItemDefinition> items,
    required Map<String, AssessmentResponse> responses,
    required ResponseValidityInput rviInput,
    required List<DimensionScoreResult> dimResults,
  }) {
    final components = <String, double>{};
    final missing = <String>[];
    final reasons = <String>[];

    // Semantic pairs
    final sem = <double>[];
    final semGroups = <String, List<AssessmentItemDefinition>>{};
    for (final q in items.values) {
      if (q.semanticPairId != null) {
        (semGroups[q.semanticPairId!] ??= []).add(q);
      }
    }
    for (final g in semGroups.values) {
      if (g.length < 2) continue;
      final a = responses[g[0].questionId];
      final b = responses[g[1].questionId];
      if (a == null || b == null) continue;
      // Agreement if same option polarity on primary deltas when available.
      final agree = _pairAgreement(g[0], a, g[1], b);
      if (agree != null) sem.add(agree);
    }
    if (sem.isEmpty && rviInput.semanticPairAgreements != null) {
      sem.addAll(rviInput.semanticPairAgreements!.values);
    }
    if (sem.isEmpty) {
      missing.add('semantic_consistency');
    } else {
      final v = sem.reduce((a, b) => a + b) / sem.length;
      components['semantic_consistency'] = v.clamp(0.0, 1.0);
      if (v < 0.45) reasons.add('rvi_semantic_low');
    }

    // Reverse pairs — require explicit descriptors; never invent inconsistency.
    final rev = <double>[];
    final descriptorsById = {
      for (final d in input.reversePairDescriptors) d.pairId: d,
    };
    final revGroups = <String, List<AssessmentItemDefinition>>{};
    for (final q in items.values) {
      if (q.reversePairId != null) {
        (revGroups[q.reversePairId!] ??= []).add(q);
      }
    }
    var reversePairsSeen = 0;
    var reversePairsMissingMeta = 0;
    for (final entry in revGroups.entries) {
      final g = entry.value;
      if (g.length < 2) continue;
      reversePairsSeen++;
      final descriptor = descriptorsById[entry.key];
      if (descriptor == null) {
        reversePairsMissingMeta++;
        continue;
      }
      final a = responses[g[0].questionId];
      final b = responses[g[1].questionId];
      if (a == null || b == null) {
        continue; // partial pair → skip, not fabricate
      }
      final agree = _reversePairConsistency(
        g[0],
        a,
        g[1],
        b,
        descriptor,
      );
      if (agree != null) rev.add(agree);
    }
    if (rev.isEmpty && rviInput.reversePairAgreements != null) {
      rev.addAll(rviInput.reversePairAgreements!.values);
    }
    if (rev.isEmpty) {
      missing.add('reverse_consistency');
      if (reversePairsSeen > 0 && reversePairsMissingMeta == reversePairsSeen) {
        reasons.add('rvi_reverse_metadata_unavailable');
      }
    } else {
      final v = rev.reduce((a, b) => a + b) / rev.length;
      components['reverse_consistency'] = v.clamp(0.0, 1.0);
      if (v < 0.45) reasons.add('rvi_reverse_inconsistent');
    }

    // Timing quality
    final times = <double>[];
    for (final r in responses.values) {
      final t = r.responseTimeMilliseconds ?? input.responseTimes[r.questionId];
      if (t != null && t > 0) times.add(t.toDouble());
    }
    if (times.isEmpty) {
      missing.add('timing_quality');
    } else {
      var extremelyFast = 0;
      for (final r in responses.entries) {
        final item = items[r.key];
        final t =
            r.value.responseTimeMilliseconds ?? input.responseTimes[r.key];
        if (item == null || t == null) continue;
        final expectMs = item.estimatedCompletionSeconds * 1000;
        if (t < expectMs * 0.15) extremelyFast++;
      }
      final fastRate = extremelyFast / math.max(1, times.length);
      // Uniformity: low variance relative to mean → suspicious
      final mean = times.reduce((a, b) => a + b) / times.length;
      final varSum =
          times.map((t) => (t - mean) * (t - mean)).reduce((a, b) => a + b) /
              times.length;
      final cv = mean <= 1e-9 ? 0.0 : math.sqrt(varSum) / mean;
      var timing = 1.0 - fastRate;
      if (cv < 0.05 && times.length >= 8) {
        timing *= 0.7;
        reasons.add('rvi_timing_too_uniform');
      }
      if (fastRate > 0.35) reasons.add('rvi_too_fast');
      components['timing_quality'] = timing.clamp(0.0, 1.0);
    }

    // Response variation
    final choices = <String>{};
    for (final r in responses.values) {
      if (r.selectedOptionId != null) choices.add(r.selectedOptionId!);
      if (r.likertValue != null) choices.add('L${r.likertValue}');
    }
    if (responses.length < 5) {
      missing.add('response_variation');
    } else {
      final uniqueRatio = choices.length / responses.length;
      components['response_variation'] = uniqueRatio.clamp(0.0, 1.0);
      if (uniqueRatio < 0.15) reasons.add('rvi_straightlining');
    }

    // Impression risk (bounded, non-moral)
    var highSdr = 0;
    var tagged = 0;
    for (final r in responses.entries) {
      final item = items[r.key];
      if (item == null) continue;
      if (!item.responseValidityRoles.contains('social_impression_risk') &&
          item.options.every((o) => o.socialDesirabilityRisk == 'low')) {
        continue;
      }
      tagged++;
      AssessmentOptionDefinition? opt;
      for (final o in item.options) {
        if (o.optionId == r.value.selectedOptionId) {
          opt = o;
          break;
        }
      }
      if (opt != null &&
          (opt.socialDesirabilityRisk == 'high' || opt.extremity > 0.85)) {
        highSdr++;
      }
    }
    if (tagged == 0 && rviInput.impressionRiskOverride == null) {
      missing.add('social_impression_risk');
    } else {
      final risk = rviInput.impressionRiskOverride ??
          (tagged == 0 ? 0.0 : highSdr / tagged);
      // Store as quality = 1 - risk
      components['social_impression_risk'] = (1.0 - risk).clamp(0.0, 1.0);
      if (risk > 0.7) reasons.add('rvi_impression_management_risk');
    }

    // Repeated-context stability
    if (rviInput.isomorphStability != null &&
        rviInput.isomorphStability!.isNotEmpty) {
      final vals = rviInput.isomorphStability!.values.toList();
      components['repeated_context_stability'] =
          (vals.reduce((a, b) => a + b) / vals.length).clamp(0.0, 1.0);
    } else {
      missing.add('repeated_context_stability');
    }

    // Person-fit deferred
    missing.add('person_fit');

    final overall = _weightedAvailable(
      components,
      config.rviWeights,
      config.renormalizeRviOverAvailable,
    );

    ResponseValidityStatusBand status;
    var publishable = true;
    var retest = false;
    if (components.isEmpty) {
      status = ResponseValidityStatusBand.insufficientEvidence;
      publishable = false;
      retest = true;
    } else if (reasons.contains('rvi_too_fast') &&
        reasons.contains('rvi_straightlining')) {
      status = ResponseValidityStatusBand.lowValidity;
      publishable = false;
      retest = true;
    } else if (overall < 0.45) {
      status = ResponseValidityStatusBand.lowValidity;
      publishable = false;
      retest = true;
    } else if (overall < 0.7) {
      status = ResponseValidityStatusBand.provisional;
      retest = reasons.isNotEmpty;
    } else {
      status = ResponseValidityStatusBand.acceptableForShadowEvaluation;
    }

    return ResponseValidityResult(
      rviVersion: config.rviVersion,
      overallScore: overall,
      componentScores: components,
      availableComponents: components.keys.toList()..sort(),
      missingComponents: missing..sort(),
      status: status,
      reasonCodes: reasons.toSet().toList()..sort(),
      retestRecommended: retest,
      publishableRecommendation: publishable,
    );
  }

  double? _pairAgreement(
    AssessmentItemDefinition a,
    AssessmentResponse ra,
    AssessmentItemDefinition b,
    AssessmentResponse rb,
  ) {
    if (ra.selectedOptionId == null || rb.selectedOptionId == null) return null;
    final oa = a.options.where((o) => o.optionId == ra.selectedOptionId);
    final ob = b.options.where((o) => o.optionId == rb.selectedOptionId);
    if (oa.isEmpty || ob.isEmpty) return null;
    final da = oa.first.dimensionDeltas[a.primaryDimension] ?? 0;
    final db = ob.first.dimensionDeltas[b.primaryDimension] ?? 0;
    if (da == 0 && db == 0) return 0.5;
    return (da.sign == db.sign) ? 1.0 : 0.0;
  }

  /// Evaluates reverse-pair RVI using declared [descriptor] semantics only.
  /// Does not alter trait deltas or scores.
  double? _reversePairConsistency(
    AssessmentItemDefinition a,
    AssessmentResponse ra,
    AssessmentItemDefinition b,
    AssessmentResponse rb,
    ReversePairDescriptor descriptor,
  ) {
    if (ra.selectedOptionId == null || rb.selectedOptionId == null) return null;
    final oa = a.options.where((o) => o.optionId == ra.selectedOptionId);
    final ob = b.options.where((o) => o.optionId == rb.selectedOptionId);
    if (oa.isEmpty || ob.isEmpty) return null;

    switch (descriptor.consistencyMode) {
      case ReversePairConsistencyMode.oppositeTraitSign:
        final da = oa.first.dimensionDeltas[a.primaryDimension] ?? 0;
        final db = ob.first.dimensionDeltas[b.primaryDimension] ?? 0;
        if (da == 0 || db == 0) return 0.5;
        return (da.sign != db.sign) ? 1.0 : 0.0;
      case ReversePairConsistencyMode.behavioralCorrespondence:
        final da = oa.first.dimensionDeltas[a.primaryDimension] ?? 0;
        final db = ob.first.dimensionDeltas[b.primaryDimension] ?? 0;
        if (da == 0 || db == 0) return 0.5;
        return (da.sign == db.sign) ? 1.0 : 0.0;
      case ReversePairConsistencyMode.explicitOptionMapping:
        final corr = descriptor.optionCorrespondence;
        if (corr.isEmpty) return null; // metadata incomplete → unavailable
        final keyAb = '${a.questionId}::${ra.selectedOptionId}';
        final keyBa = '${b.questionId}::${rb.selectedOptionId}';
        final mappedFromA = corr[keyAb];
        final mappedFromB = corr[keyBa];
        if (mappedFromA != null) {
          return mappedFromA == rb.selectedOptionId ? 1.0 : 0.0;
        }
        if (mappedFromB != null) {
          return mappedFromB == ra.selectedOptionId ? 1.0 : 0.0;
        }
        // No declared correspondence for selected options → unavailable.
        return null;
    }
  }

  double _weightedAvailable(
    Map<String, double> values,
    Map<String, double> weights,
    bool renorm,
  ) {
    var num = 0.0;
    var den = 0.0;
    for (final e in values.entries) {
      final w = weights[e.key] ?? 0.0;
      if (w <= 0) continue;
      num += w * e.value;
      den += w;
    }
    if (den <= 1e-12) return 0.0;
    if (!renorm) {
      final totalW =
          weights.values.where((w) => w > 0).fold<double>(0, (a, b) => a + b);
      // Missing components contribute 0 weight mass without inventing perfect scores.
      return (num / math.max(totalW, den)).clamp(0.0, 1.0);
    }
    return (num / den).clamp(0.0, 1.0);
  }
}
