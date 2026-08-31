import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_mixed_state.dart';
import 'frequency_behavior_v2_pair_relation.dart';

/// Per-dimension provisional relationship-fit row.
class FrequencyBehaviorV2PairFitDimension {
  const FrequencyBehaviorV2PairFitDimension({
    required this.dimensionId,
    required this.policyType,
    required this.xA,
    required this.xB,
    required this.delta,
    required this.linearProximity,
    required this.rawFit,
    required this.pairSupport,
    required this.supportedFit,
    required this.supportedAlignmentStrength,
    required this.supportedGapStrength,
    required this.axisFidelity,
    required this.samePoleExpectation,
    required this.oppositePoleExpectation,
    required this.supportedSamePole,
  });

  final String dimensionId;
  final String policyType;
  final double xA;
  final double xB;
  final double delta;
  final double linearProximity;
  final double rawFit;
  final double pairSupport;
  final double supportedFit;
  final double supportedAlignmentStrength;
  final double supportedGapStrength;
  final double axisFidelity;
  final double samePoleExpectation;
  final double oppositePoleExpectation;
  final double supportedSamePole;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'policy_type': policyType,
        'x_a': xA,
        'x_b': xB,
        'delta': delta,
        'linear_proximity': linearProximity,
        'raw_fit': rawFit,
        'pair_support': pairSupport,
        'supported_fit': supportedFit,
        'supported_alignment_strength': supportedAlignmentStrength,
        'supported_gap_strength': supportedGapStrength,
        'axis_fidelity': axisFidelity,
        'same_pole_expectation': samePoleExpectation,
        'opposite_pole_expectation': oppositePoleExpectation,
        'supported_same_pole': supportedSamePole,
      };
}

/// Dormant provisional Frequency relationship-fit result.
///
/// Engineering heuristic only. Not relationship success probability,
/// soulmate scoring, or scientifically validated prediction.
class FrequencyBehaviorV2PairFitResult {
  const FrequencyBehaviorV2PairFitResult({
    required this.ok,
    required this.pairFitVersion,
    required this.pairFitPolicyVersion,
    required this.pairRelationVersion,
    required this.encodingVersion,
    required this.mixednessVersion,
    required this.confidenceVersion,
    required this.scorerVersion,
    this.userASessionId,
    this.userBSessionId,
    this.dimensions = const [],
    this.overallRawFit,
    this.overallSupportedFit,
    this.frequencyFitIndex,
    this.overallPairSupport,
    this.topAlignmentDimensions = const [],
    this.topGapDimensions = const [],
    this.message,
  });

  final bool ok;
  final String pairFitVersion;
  final String pairFitPolicyVersion;
  final String pairRelationVersion;
  final String encodingVersion;
  final String mixednessVersion;
  final String confidenceVersion;
  final String scorerVersion;
  final String? userASessionId;
  final String? userBSessionId;
  final List<FrequencyBehaviorV2PairFitDimension> dimensions;
  final double? overallRawFit;
  final double? overallSupportedFit;
  final double? frequencyFitIndex;
  final double? overallPairSupport;
  final List<String> topAlignmentDimensions;
  final List<String> topGapDimensions;
  final String? message;

  FrequencyBehaviorV2PairFitDimension? forDimension(String id) {
    for (final d in dimensions) {
      if (d.dimensionId == id) return d;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'schema_version': FrequencyBehaviorV2Contract.pairFitSchemaVersion,
        'pair_fit_version': pairFitVersion,
        'pair_fit_policy_version': pairFitPolicyVersion,
        'pair_relation_version': pairRelationVersion,
        'encoding_version': encodingVersion,
        'mixedness_version': mixednessVersion,
        'confidence_version': confidenceVersion,
        'scorer_version': scorerVersion,
        'user_a_session_id': userASessionId,
        'user_b_session_id': userBSessionId,
        'ok': ok,
        'message': message,
        'dimensions': [for (final d in dimensions) d.toJson()],
        'overall_raw_fit': overallRawFit,
        'overall_supported_fit': overallSupportedFit,
        'frequency_fit_index': frequencyFitIndex,
        'overall_pair_support': overallPairSupport,
        'top_alignment_dimensions': topAlignmentDimensions,
        'top_gap_dimensions': topGapDimensions,
        'not_claims': const [
          'relationship_success_probability',
          'match_probability',
          'love_percentage',
          'soulmate_percentage',
          'scientifically_validated_relationship_prediction',
          'personality_truth',
          'complementarity_bonus',
        ],
      };
}

/// Provisional uncalibrated relationship-fit model (policy v1).
///
/// Uses signed behavioral distance and Phase 5C pair support only.
/// Does not consume density-matrix overlaps or same-pole expectations
/// in the fit formula.
class FrequencyBehaviorV2PairFitComputer {
  const FrequencyBehaviorV2PairFitComputer({
    this.relationComputer = const FrequencyBehaviorV2PairRelationComputer(),
    this.topRankCount = 3,
  });

  final FrequencyBehaviorV2PairRelationComputer relationComputer;
  final int topRankCount;

  static const pairFitVersion = FrequencyBehaviorV2Contract.pairFitVersion;
  static const pairFitPolicyVersion =
      FrequencyBehaviorV2Contract.pairFitPolicyVersion;

  FrequencyBehaviorV2PairFitResult fitFromUsers(
    FrequencyBehaviorV2MixedStateResult a,
    FrequencyBehaviorV2MixedStateResult b,
  ) {
    return fitFromRelation(relationComputer.relate(a, b));
  }

  FrequencyBehaviorV2PairFitResult fitFromRelation(
    FrequencyBehaviorV2PairRelationResult relation,
  ) {
    if (!relation.ok) {
      return FrequencyBehaviorV2PairFitResult(
        ok: false,
        pairFitVersion: pairFitVersion,
        pairFitPolicyVersion: pairFitPolicyVersion,
        pairRelationVersion: relation.pairModelVersion,
        encodingVersion: relation.encodingVersion,
        mixednessVersion: relation.mixednessVersion,
        confidenceVersion: FrequencyBehaviorV2Contract.confidenceModelVersion,
        scorerVersion: relation.scorerVersion,
        userASessionId: relation.userASessionId,
        userBSessionId: relation.userBSessionId,
        message: 'pair_relation_not_ok:${relation.message}',
      );
    }
    final rows = <FrequencyBehaviorV2PairFitDimension>[];
    var rawSum = 0.0;
    var supportedSum = 0.0;
    var supportSum = 0.0;
    for (final rel in relation.dimensions) {
      final row = dimensionFit(rel);
      rows.add(row);
      rawSum += row.rawFit;
      supportedSum += row.supportedFit;
      supportSum += row.pairSupport;
    }
    final n = FrequencyBehaviorV2Contract.dimensionCount.toDouble();
    final overallRaw = rawSum / n;
    final overallSupported = supportedSum / n;
    final alignRank = [...rows]..sort((a, b) {
        final c = b.supportedAlignmentStrength
            .compareTo(a.supportedAlignmentStrength);
        if (c != 0) return c;
        return a.dimensionId.compareTo(b.dimensionId);
      });
    final gapRank = [...rows]..sort((a, b) {
        final c = b.supportedGapStrength.compareTo(a.supportedGapStrength);
        if (c != 0) return c;
        return a.dimensionId.compareTo(b.dimensionId);
      });
    return FrequencyBehaviorV2PairFitResult(
      ok: true,
      pairFitVersion: pairFitVersion,
      pairFitPolicyVersion: pairFitPolicyVersion,
      pairRelationVersion: relation.pairModelVersion,
      encodingVersion: relation.encodingVersion,
      mixednessVersion: relation.mixednessVersion,
      confidenceVersion: FrequencyBehaviorV2Contract.confidenceModelVersion,
      scorerVersion: relation.scorerVersion,
      userASessionId: relation.userASessionId,
      userBSessionId: relation.userBSessionId,
      dimensions: rows,
      overallRawFit: overallRaw,
      overallSupportedFit: overallSupported,
      frequencyFitIndex: 100.0 * overallSupported,
      overallPairSupport: supportSum / n,
      topAlignmentDimensions: [
        for (final r in alignRank.take(topRankCount)) r.dimensionId,
      ],
      topGapDimensions: [
        for (final r in gapRank.take(topRankCount)) r.dimensionId,
      ],
    );
  }

  FrequencyBehaviorV2PairFitDimension dimensionFit(
    FrequencyBehaviorV2PairDimensionRelation rel,
  ) {
    final delta = (rel.xA - rel.xB).abs();
    final linearProximity = 1.0 - delta / 2.0;
    final policy = policyForDimension(rel.dimensionId);
    final rawFit = rawFitForPolicy(delta: delta, policyType: policy);
    final supportedFit = 0.5 + rel.pairSupport * (rawFit - 0.5);
    return FrequencyBehaviorV2PairFitDimension(
      dimensionId: rel.dimensionId,
      policyType: policy,
      xA: rel.xA,
      xB: rel.xB,
      delta: delta,
      linearProximity: linearProximity,
      rawFit: rawFit,
      pairSupport: rel.pairSupport,
      supportedFit: supportedFit,
      supportedAlignmentStrength: rel.pairSupport * rawFit,
      supportedGapStrength: rel.pairSupport * (1.0 - rawFit),
      axisFidelity: rel.axisFidelity,
      samePoleExpectation: rel.samePoleExpectation,
      oppositePoleExpectation: rel.oppositePoleExpectation,
      supportedSamePole: rel.supportedSamePole,
    );
  }

  static String policyForDimension(String dimensionId) {
    if (FrequencyBehaviorV2Contract.pairFitLinearPolicyDimensions
        .contains(dimensionId)) {
      return FrequencyBehaviorV2Contract.pairFitPolicySimilarityLinear;
    }
    if (FrequencyBehaviorV2Contract.pairFitTolerantPolicyDimensions
        .contains(dimensionId)) {
      return FrequencyBehaviorV2Contract.pairFitPolicySimilarityTolerant;
    }
    throw StateError('unknown_dimension_policy:$dimensionId');
  }

  static double rawFitForPolicy({
    required double delta,
    required String policyType,
  }) {
    final halfDelta = (delta / 2.0).clamp(0.0, 1.0);
    switch (policyType) {
      case FrequencyBehaviorV2Contract.pairFitPolicySimilarityLinear:
        return 1.0 - halfDelta;
      case FrequencyBehaviorV2Contract.pairFitPolicySimilarityTolerant:
        return 1.0 - halfDelta * halfDelta;
      default:
        throw ArgumentError.value(policyType, 'policyType', 'unknown_policy');
    }
  }

  /// Neutral explanation primitive for UI/audit. Not a moral label.
  static String alignmentExplanationLabel(String dimensionId) {
    return 'similar ${_humanizeDimension(dimensionId)} preference';
  }

  static String gapExplanationLabel(String dimensionId) {
    return 'larger difference in ${_humanizeDimension(dimensionId)} preference';
  }

  static String _humanizeDimension(String id) => id.replaceAll('_', ' ');
}
