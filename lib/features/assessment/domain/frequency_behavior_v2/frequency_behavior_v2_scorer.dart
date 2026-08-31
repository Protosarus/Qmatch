import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';

/// Per-dimension dormant V2 score and confidence primitives.
///
/// [normalizedBehavior] is a signed opportunity-aware direction in [-1, +1].
/// It is not a moral, health, personality-strength, or lie score.
class FrequencyBehaviorV2DimensionScore {
  const FrequencyBehaviorV2DimensionScore({
    required this.dimensionId,
    required this.rawSum,
    required this.capacity,
    required this.primaryQuestionCount,
    required this.nonzeroPrimarySignalCount,
    required this.zeroPrimarySignalCount,
    required this.absoluteSelectedSignal,
    required this.eligibleCrossContextPairCount,
    required this.possibleCrossContextPairCount,
    this.normalizedBehavior,
    this.primarySignalCoverage,
    this.signalUtilization,
    this.crossContextConsistency,
    this.crossContextCoverage,
    this.meanDiagnosticValue,
    this.meanBehavioralPlausibility,
    this.meanAmbiguity,
    this.meanSocialDesirability,
    this.meanObviousness,
    this.meanSelfPresentationRisk,
    this.semanticClarity,
    this.evidenceQuality,
    this.primaryObservability,
    this.presentationPressure,
    this.presentationAdjustment,
    this.contextComponent,
    this.baseConfidence,
    this.provisionalConfidence,
    this.confidenceCompleteness,
    this.confidenceFlags = const [],
  });

  final String dimensionId;
  final double rawSum;
  final double capacity;
  final double? normalizedBehavior;
  final int primaryQuestionCount;
  final int nonzeroPrimarySignalCount;
  final int zeroPrimarySignalCount;
  final double? primarySignalCoverage;
  final double absoluteSelectedSignal;
  final double? signalUtilization;
  final double? crossContextConsistency;
  final int eligibleCrossContextPairCount;
  final int possibleCrossContextPairCount;
  final double? crossContextCoverage;
  final double? meanDiagnosticValue;
  final double? meanBehavioralPlausibility;
  final double? meanAmbiguity;
  final double? meanSocialDesirability;
  final double? meanObviousness;
  final double? meanSelfPresentationRisk;
  final double? semanticClarity;
  final double? evidenceQuality;
  final double? primaryObservability;
  final double? presentationPressure;
  final double? presentationAdjustment;
  final double? contextComponent;
  final double? baseConfidence;
  final double? provisionalConfidence;
  final double? confidenceCompleteness;
  final List<String> confidenceFlags;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'raw_sum': rawSum,
        'capacity': capacity,
        'normalized_behavior': normalizedBehavior,
        'primary_question_count': primaryQuestionCount,
        'nonzero_primary_signal_count': nonzeroPrimarySignalCount,
        'zero_primary_signal_count': zeroPrimarySignalCount,
        'primary_signal_coverage': primarySignalCoverage,
        'absolute_selected_signal': absoluteSelectedSignal,
        'signal_utilization': signalUtilization,
        'cross_context_consistency': crossContextConsistency,
        'eligible_cross_context_pair_count': eligibleCrossContextPairCount,
        'possible_cross_context_pair_count': possibleCrossContextPairCount,
        'cross_context_coverage': crossContextCoverage,
        'mean_diagnostic_value': meanDiagnosticValue,
        'mean_behavioral_plausibility': meanBehavioralPlausibility,
        'mean_ambiguity': meanAmbiguity,
        'mean_social_desirability': meanSocialDesirability,
        'mean_obviousness': meanObviousness,
        'mean_self_presentation_risk': meanSelfPresentationRisk,
        'semantic_clarity': semanticClarity,
        'evidence_quality': evidenceQuality,
        'primary_observability': primaryObservability,
        'presentation_pressure': presentationPressure,
        'presentation_adjustment': presentationAdjustment,
        'context_component': contextComponent,
        'base_confidence': baseConfidence,
        'provisional_confidence': provisionalConfidence,
        'confidence_completeness': confidenceCompleteness,
        'confidence_flags': confidenceFlags,
      };
}

/// Dormant 12D session score. Not a user-facing Frequency number.
class FrequencyBehaviorV2ScoreResult {
  const FrequencyBehaviorV2ScoreResult({
    required this.ok,
    required this.dimensionScores,
    this.schemaVersion = FrequencyBehaviorV2Contract.sessionScoreSchemaVersion,
    this.scorerVersion = FrequencyBehaviorV2Contract.scorerVersion,
    this.bankVersion,
    this.selectorVersion,
    this.sessionId,
    this.message,
    this.confidenceModelVersion =
        FrequencyBehaviorV2Contract.confidenceModelVersion,
  });

  final bool ok;
  final String schemaVersion;
  final String scorerVersion;
  final String? bankVersion;
  final String? selectorVersion;
  final String? sessionId;
  final List<FrequencyBehaviorV2DimensionScore> dimensionScores;
  final String? message;
  final String confidenceModelVersion;

  FrequencyBehaviorV2DimensionScore? scoreFor(String dimensionId) {
    for (final d in dimensionScores) {
      if (d.dimensionId == dimensionId) return d;
    }
    return null;
  }

  /// Signed opportunity-aware 12D direction. Null when capacity is 0.
  /// Range [-1, +1]. Not a 0–1 V1 Frequency slot.
  Map<String, double?> get behavioralMean12d => {
        for (final d in dimensionScores) d.dimensionId: d.normalizedBehavior,
      };

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'scorer_version': scorerVersion,
        'confidence_model_version': confidenceModelVersion,
        'bank_version': bankVersion,
        'selector_version': selectorVersion,
        'session_id': sessionId,
        'ok': ok,
        'message': message,
        'dimensions': [for (final d in dimensionScores) d.toJson()],
      };
}

/// Offline 12D scorer and confidence primitives.
///
/// Scores by stable [FrequencyBehaviorV2Response.optionId], never display
/// index. Behavioral direction uses only `behavioral_weights`. Evidence
/// priors are reported as separate means and never move the signed score.
/// Provisional confidence is an engineering heuristic on those primitives.
/// Does not write Frequency 6D or canonical_v1.
class FrequencyBehaviorV2Scorer {
  const FrequencyBehaviorV2Scorer();

  FrequencyBehaviorV2ScoreResult score({
    required FrequencyBehaviorV2PoolDocument pool,
    required List<FrequencyBehaviorV2Response> responses,
    FrequencyBehaviorV2SessionManifest? manifest,
    List<List<String>> nearDuplicateClusters = const [],
  }) {
    if (pool.scoringPolicyVersion !=
        FrequencyBehaviorV2Contract.scoringPolicyVersion) {
      return const FrequencyBehaviorV2ScoreResult(
        ok: false,
        dimensionScores: [],
        message: 'Incompatible scoring policy',
      );
    }
    if (manifest != null && manifest.bankVersion != pool.poolVersion) {
      return FrequencyBehaviorV2ScoreResult(
        ok: false,
        dimensionScores: const [],
        bankVersion: pool.poolVersion,
        selectorVersion: manifest.selectorVersion,
        sessionId: manifest.sessionId,
        message: 'Manifest bank_version ${manifest.bankVersion} != '
            'pool ${pool.poolVersion}',
      );
    }

    final byId = pool.itemsById;
    final presentedIds = <String>[
      if (manifest != null)
        ...manifest.questionIds
      else
        for (final r in responses) r.itemId,
    ];
    final seenPresented = <String>{};
    for (final id in presentedIds) {
      if (!seenPresented.add(id)) {
        return FrequencyBehaviorV2ScoreResult(
          ok: false,
          dimensionScores: const [],
          bankVersion: pool.poolVersion,
          selectorVersion: manifest?.selectorVersion,
          sessionId: manifest?.sessionId,
          message: 'Duplicate presented question $id',
        );
      }
      if (byId[id] == null) {
        return FrequencyBehaviorV2ScoreResult(
          ok: false,
          dimensionScores: const [],
          bankVersion: pool.poolVersion,
          selectorVersion: manifest?.selectorVersion,
          sessionId: manifest?.sessionId,
          message: 'Unknown item $id',
        );
      }
    }

    final seenAnswers = <String>{};
    final answerByItem = <String, FrequencyBehaviorV2Option>{};
    for (final r in responses) {
      if (!seenAnswers.add(r.itemId)) {
        return FrequencyBehaviorV2ScoreResult(
          ok: false,
          dimensionScores: const [],
          bankVersion: pool.poolVersion,
          selectorVersion: manifest?.selectorVersion,
          sessionId: manifest?.sessionId,
          message: 'Duplicate answer for ${r.itemId}',
        );
      }
      final item = byId[r.itemId];
      if (item == null) {
        return FrequencyBehaviorV2ScoreResult(
          ok: false,
          dimensionScores: const [],
          bankVersion: pool.poolVersion,
          selectorVersion: manifest?.selectorVersion,
          sessionId: manifest?.sessionId,
          message: 'Unknown item ${r.itemId}',
        );
      }
      final option = item.optionById(r.optionId);
      if (option == null) {
        return FrequencyBehaviorV2ScoreResult(
          ok: false,
          dimensionScores: const [],
          bankVersion: pool.poolVersion,
          selectorVersion: manifest?.selectorVersion,
          sessionId: manifest?.sessionId,
          message: 'Option ${r.optionId} not in ${r.itemId}',
        );
      }
      for (final key in option.behavioralWeights.keys) {
        if (!FrequencyBehaviorV2Contract.isCanonicalDimension(key)) {
          return FrequencyBehaviorV2ScoreResult(
            ok: false,
            dimensionScores: const [],
            bankVersion: pool.poolVersion,
            selectorVersion: manifest?.selectorVersion,
            sessionId: manifest?.sessionId,
            message: 'Unknown dimension $key',
          );
        }
      }
      answerByItem[r.itemId] = option;
    }

    final nearDupIndex = _nearDupIndex(nearDuplicateClusters, seenPresented);
    final dims = FrequencyBehaviorV2Contract.canonicalDimensions;
    final rawSum = <String, double>{for (final d in dims) d: 0.0};
    final capacity = <String, double>{for (final d in dims) d: 0.0};
    final absSelected = <String, double>{for (final d in dims) d: 0.0};
    final primaryCount = <String, int>{for (final d in dims) d: 0};
    final nonzeroPrimary = <String, int>{for (final d in dims) d: 0};
    final zeroPrimary = <String, int>{for (final d in dims) d: 0};
    final primaryRows = <String, List<_PrimaryRow>>{
      for (final d in dims) d: <_PrimaryRow>[],
    };
    final evidenceSums = <String, Map<String, double>>{
      for (final d in dims) d: <String, double>{},
    };
    final evidenceNs = <String, Map<String, int>>{
      for (final d in dims) d: <String, int>{},
    };

    for (final id in presentedIds) {
      final item = byId[id]!;
      for (final d in dims) {
        capacity[d] = capacity[d]! + _questionCapacity(item, d);
      }
      final selected = answerByItem[id];
      if (selected != null) {
        for (final d in dims) {
          final w = selected.behavioralWeights[d] ?? 0.0;
          rawSum[d] = rawSum[d]! + w;
          absSelected[d] = absSelected[d]! + w.abs();
        }
      }
      if (item.primaryDimensions.length != 1) continue;
      final primary = item.primaryDimensions.single;
      if (!FrequencyBehaviorV2Contract.isCanonicalDimension(primary)) {
        continue;
      }
      primaryCount[primary] = primaryCount[primary]! + 1;
      final signal =
          selected == null ? 0.0 : (selected.behavioralWeights[primary] ?? 0.0);
      if (signal == 0.0) {
        zeroPrimary[primary] = zeroPrimary[primary]! + 1;
      } else {
        nonzeroPrimary[primary] = nonzeroPrimary[primary]! + 1;
      }
      primaryRows[primary]!.add(
        _PrimaryRow(
          itemId: id,
          cluster: item.semanticCluster,
          signal: signal,
        ),
      );
      if (selected != null) {
        _accumulateEvidence(
          evidenceSums[primary]!,
          evidenceNs[primary]!,
          selected.evidenceMeta,
        );
      }
    }

    final scores = <FrequencyBehaviorV2DimensionScore>[];
    for (final d in dims) {
      final cap = capacity[d]!;
      final raw = rawSum[d]!;
      final absSig = absSelected[d]!;
      final pCount = primaryCount[d]!;
      double? normalized;
      if (cap > 0) {
        normalized = (raw / cap).clamp(-1.0, 1.0);
      }
      double? utilization;
      if (cap > 0) {
        utilization = (absSig / cap).clamp(0.0, 1.0);
      }
      double? primaryCoverage;
      if (pCount > 0) {
        primaryCoverage = nonzeroPrimary[d]! / pCount;
      }
      final pairStats = _crossContext(primaryRows[d]!, nearDupIndex);
      final meanDv =
          _meanOrNull(evidenceSums[d]!, evidenceNs[d]!, 'diagnostic_value');
      final meanPlaus = _meanOrNull(
        evidenceSums[d]!,
        evidenceNs[d]!,
        'behavioral_plausibility',
      );
      final meanAmb =
          _meanOrNull(evidenceSums[d]!, evidenceNs[d]!, 'ambiguity');
      final meanSd = _meanOrNull(
        evidenceSums[d]!,
        evidenceNs[d]!,
        'social_desirability',
      );
      final meanObv =
          _meanOrNull(evidenceSums[d]!, evidenceNs[d]!, 'obviousness');
      final meanSpr = _meanOrNull(
        evidenceSums[d]!,
        evidenceNs[d]!,
        'self_presentation_risk',
      );
      final conf = deriveProvisionalConfidence(
        meanDiagnosticValue: meanDv,
        meanBehavioralPlausibility: meanPlaus,
        meanAmbiguity: meanAmb,
        meanSocialDesirability: meanSd,
        meanObviousness: meanObv,
        meanSelfPresentationRisk: meanSpr,
        primarySignalCoverage: primaryCoverage,
        crossContextConsistency: pairStats.consistency,
        crossContextCoverage: pairStats.coverage,
      );
      scores.add(
        FrequencyBehaviorV2DimensionScore(
          dimensionId: d,
          rawSum: raw,
          capacity: cap,
          normalizedBehavior: normalized,
          primaryQuestionCount: pCount,
          nonzeroPrimarySignalCount: nonzeroPrimary[d]!,
          zeroPrimarySignalCount: zeroPrimary[d]!,
          primarySignalCoverage: primaryCoverage,
          absoluteSelectedSignal: absSig,
          signalUtilization: utilization,
          crossContextConsistency: pairStats.consistency,
          eligibleCrossContextPairCount: pairStats.eligible,
          possibleCrossContextPairCount: pairStats.possible,
          crossContextCoverage: pairStats.coverage,
          meanDiagnosticValue: meanDv,
          meanBehavioralPlausibility: meanPlaus,
          meanAmbiguity: meanAmb,
          meanSocialDesirability: meanSd,
          meanObviousness: meanObv,
          meanSelfPresentationRisk: meanSpr,
          semanticClarity: conf.semanticClarity,
          evidenceQuality: conf.evidenceQuality,
          primaryObservability: conf.primaryObservability,
          presentationPressure: conf.presentationPressure,
          presentationAdjustment: conf.presentationAdjustment,
          contextComponent: conf.contextComponent,
          baseConfidence: conf.baseConfidence,
          provisionalConfidence: conf.provisionalConfidence,
          confidenceCompleteness: conf.confidenceCompleteness,
          confidenceFlags: conf.flags,
        ),
      );
    }

    return FrequencyBehaviorV2ScoreResult(
      ok: true,
      schemaVersion: FrequencyBehaviorV2Contract.sessionScoreSchemaVersion,
      scorerVersion: FrequencyBehaviorV2Contract.scorerVersion,
      bankVersion: pool.poolVersion,
      selectorVersion: manifest?.selectorVersion ??
          FrequencyBehaviorV2Contract.selectorVersion,
      sessionId: manifest?.sessionId,
      confidenceModelVersion:
          FrequencyBehaviorV2Contract.confidenceModelVersion,
      dimensionScores: scores,
    );
  }

  static double _questionCapacity(FrequencyBehaviorV2Item item, String dim) {
    var maxAbs = 0.0;
    for (final o in item.options) {
      final w = o.behavioralWeights[dim];
      if (w == null) continue;
      final a = w.abs();
      if (a > maxAbs) maxAbs = a;
    }
    return maxAbs;
  }

  /// Engineering heuristic. Does not read weights or change direction.
  static FrequencyBehaviorV2ProvisionalConfidence deriveProvisionalConfidence({
    required double? meanDiagnosticValue,
    required double? meanBehavioralPlausibility,
    required double? meanAmbiguity,
    required double? meanSocialDesirability,
    required double? meanObviousness,
    required double? meanSelfPresentationRisk,
    required double? primarySignalCoverage,
    required double? crossContextConsistency,
    required double? crossContextCoverage,
  }) {
    final semanticClarity =
        meanAmbiguity == null ? null : (1.0 - meanAmbiguity).clamp(0.0, 1.0);
    final evidenceQuality = _meanOf([
      meanDiagnosticValue,
      meanBehavioralPlausibility,
      semanticClarity,
    ]);
    final primaryObservability = primarySignalCoverage;
    double? contextComponent;
    if (crossContextConsistency != null && crossContextCoverage != null) {
      contextComponent = (0.75 * crossContextConsistency.clamp(0.0, 1.0) +
              0.25 * crossContextCoverage.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);
    }
    final presentationPressure = _meanOf([
      meanSocialDesirability,
      meanObviousness,
      meanSelfPresentationRisk,
    ]);
    final presentationAdjustment = presentationPressure == null
        ? 1.0
        : (1.0 -
                FrequencyBehaviorV2Contract.presentationPressureMaxDiscount *
                    presentationPressure.clamp(0.0, 1.0))
            .clamp(
            1.0 - FrequencyBehaviorV2Contract.presentationPressureMaxDiscount,
            1.0,
          );
    double? baseConfidence;
    if (evidenceQuality != null && primaryObservability != null) {
      if (contextComponent != null) {
        baseConfidence =
            (FrequencyBehaviorV2Contract.confidenceEvidenceWeight *
                        evidenceQuality +
                    FrequencyBehaviorV2Contract.confidenceObservabilityWeight *
                        primaryObservability +
                    FrequencyBehaviorV2Contract.confidenceContextWeight *
                        contextComponent)
                .clamp(0.0, 1.0);
      } else {
        baseConfidence = ((FrequencyBehaviorV2Contract
                            .confidenceEvidenceWeight *
                        evidenceQuality +
                    FrequencyBehaviorV2Contract.confidenceObservabilityWeight *
                        primaryObservability) /
                (FrequencyBehaviorV2Contract.confidenceEvidenceWeight +
                    FrequencyBehaviorV2Contract.confidenceObservabilityWeight))
            .clamp(0.0, 1.0);
      }
    }
    final provisional = baseConfidence == null
        ? null
        : (baseConfidence * presentationAdjustment).clamp(0.0, 1.0);
    final completeness = contextComponent == null ? 0.80 : 1.00;
    final flags = <String>[];
    if (evidenceQuality != null &&
        evidenceQuality <
            FrequencyBehaviorV2Contract.flagLowEvidenceQualityMax) {
      flags.add(FrequencyBehaviorV2Contract.flagLowEvidenceQuality);
    }
    if (presentationPressure != null &&
        presentationPressure >=
            FrequencyBehaviorV2Contract.flagHighPresentationPressureMin) {
      flags.add(FrequencyBehaviorV2Contract.flagHighPresentationPressure);
    }
    if (primaryObservability != null &&
        primaryObservability <
            FrequencyBehaviorV2Contract.flagLowPrimaryObservabilityMax) {
      flags.add(FrequencyBehaviorV2Contract.flagLowPrimaryObservability);
    }
    final limitedContext = contextComponent == null ||
        (crossContextCoverage != null &&
            crossContextCoverage <
                FrequencyBehaviorV2Contract.flagLimitedCrossContextCoverageMax);
    if (limitedContext) {
      flags.add(FrequencyBehaviorV2Contract.flagLimitedCrossContext);
    }
    if (crossContextConsistency != null &&
        crossContextCoverage != null &&
        crossContextConsistency <
            FrequencyBehaviorV2Contract.flagContextSensitiveConsistencyMax &&
        crossContextCoverage >=
            FrequencyBehaviorV2Contract.flagContextSensitiveCoverageMin) {
      flags.add(FrequencyBehaviorV2Contract.flagContextSensitive);
    }
    return FrequencyBehaviorV2ProvisionalConfidence(
      semanticClarity: semanticClarity,
      evidenceQuality: evidenceQuality,
      primaryObservability: primaryObservability,
      presentationPressure: presentationPressure,
      presentationAdjustment: presentationAdjustment,
      contextComponent: contextComponent,
      baseConfidence: baseConfidence,
      provisionalConfidence: provisional,
      confidenceCompleteness: completeness,
      flags: flags,
    );
  }

  static double? _meanOf(List<double?> values) {
    var sum = 0.0;
    var n = 0;
    for (final v in values) {
      if (v == null) return null;
      sum += v;
      n++;
    }
    if (n == 0) return null;
    return sum / n;
  }

  static void _accumulateEvidence(
    Map<String, double> sums,
    Map<String, int> ns,
    FrequencyBehaviorV2EvidenceMeta meta,
  ) {
    void add(String key, double? value) {
      if (value == null) return;
      sums[key] = (sums[key] ?? 0) + value;
      ns[key] = (ns[key] ?? 0) + 1;
    }

    add('diagnostic_value', meta.diagnosticValue);
    add('behavioral_plausibility', meta.behavioralPlausibility);
    add('ambiguity', meta.ambiguity);
    add('social_desirability', meta.socialDesirability);
    add('obviousness', meta.obviousness);
    add('self_presentation_risk', meta.selfPresentationRisk);
  }

  static double? _meanOrNull(
    Map<String, double> sums,
    Map<String, int> ns,
    String key,
  ) {
    final n = ns[key] ?? 0;
    if (n == 0) return null;
    return sums[key]! / n;
  }

  static Map<String, int> _nearDupIndex(
    List<List<String>> clusters,
    Set<String> presentedIds,
  ) {
    final out = <String, int>{};
    for (var i = 0; i < clusters.length; i++) {
      final members = [
        for (final id in clusters[i])
          if (presentedIds.contains(id)) id,
      ];
      if (members.length < 2) continue;
      for (final id in members) {
        out.putIfAbsent(id, () => i);
      }
    }
    return out;
  }

  static _PairStats _crossContext(
    List<_PrimaryRow> rows,
    Map<String, int> nearDupIndex,
  ) {
    var possible = 0;
    var eligible = 0;
    var simSum = 0.0;
    for (var i = 0; i < rows.length; i++) {
      for (var j = i + 1; j < rows.length; j++) {
        if (rows[i].cluster == rows[j].cluster) continue;
        possible++;
        final ndi = nearDupIndex[rows[i].itemId];
        final ndj = nearDupIndex[rows[j].itemId];
        if (ndi != null && ndi == ndj) continue;
        eligible++;
        simSum += 1.0 - (rows[i].signal - rows[j].signal).abs() / 4.0;
      }
    }
    return _PairStats(
      possible: possible,
      eligible: eligible,
      consistency: eligible == 0 ? null : simSum / eligible,
      coverage: possible == 0 ? null : eligible / possible,
    );
  }
}

class _PrimaryRow {
  const _PrimaryRow({
    required this.itemId,
    required this.cluster,
    required this.signal,
  });

  final String itemId;
  final String cluster;
  final double signal;
}

class _PairStats {
  const _PairStats({
    required this.possible,
    required this.eligible,
    required this.consistency,
    required this.coverage,
  });

  final int possible;
  final int eligible;
  final double? consistency;
  final double? coverage;
}

/// Derived Phase 4B confidence layer. Not a probability.
class FrequencyBehaviorV2ProvisionalConfidence {
  const FrequencyBehaviorV2ProvisionalConfidence({
    required this.semanticClarity,
    required this.evidenceQuality,
    required this.primaryObservability,
    required this.presentationPressure,
    required this.presentationAdjustment,
    required this.contextComponent,
    required this.baseConfidence,
    required this.provisionalConfidence,
    required this.confidenceCompleteness,
    required this.flags,
  });

  final double? semanticClarity;
  final double? evidenceQuality;
  final double? primaryObservability;
  final double? presentationPressure;
  final double presentationAdjustment;
  final double? contextComponent;
  final double? baseConfidence;
  final double? provisionalConfidence;
  final double confidenceCompleteness;
  final List<String> flags;
}
