import 'dart:math' as math;

import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_mixed_state.dart';
import 'frequency_behavior_v2_quantum_state.dart';

/// Per-dimension pair-relation primitives. Not a compatibility score.
class FrequencyBehaviorV2PairDimensionRelation {
  const FrequencyBehaviorV2PairDimensionRelation({
    required this.dimensionId,
    required this.xA,
    required this.xB,
    required this.axisFidelity,
    required this.samePoleExpectation,
    required this.oppositePoleExpectation,
    required this.effectiveSupportA,
    required this.effectiveSupportB,
    required this.pairSupport,
    required this.supportedSamePole,
    required this.supportedOppositePole,
  });

  final String dimensionId;
  final double xA;
  final double xB;
  final double axisFidelity;
  final double samePoleExpectation;
  final double oppositePoleExpectation;
  final double effectiveSupportA;
  final double effectiveSupportB;
  final double pairSupport;
  final double supportedSamePole;
  final double supportedOppositePole;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'x_a': xA,
        'x_b': xB,
        'axis_fidelity': axisFidelity,
        'same_pole_expectation': samePoleExpectation,
        'opposite_pole_expectation': oppositePoleExpectation,
        'effective_support_a': effectiveSupportA,
        'effective_support_b': effectiveSupportB,
        'pair_support': pairSupport,
        'supported_same_pole': supportedSamePole,
        'supported_opposite_pole': supportedOppositePole,
      };
}

/// Dormant A/B relation measurements. No final compatibility field.
class FrequencyBehaviorV2PairRelationResult {
  const FrequencyBehaviorV2PairRelationResult({
    required this.ok,
    required this.pairModelVersion,
    required this.encodingVersion,
    required this.mixednessVersion,
    required this.scorerVersion,
    this.userASessionId,
    this.userBSessionId,
    this.dimensions = const [],
    this.pureBehaviorOverlap,
    this.mixedHilbertSchmidtOverlap,
    this.message,
  });

  final bool ok;
  final String pairModelVersion;
  final String encodingVersion;
  final String mixednessVersion;
  final String scorerVersion;
  final String? userASessionId;
  final String? userBSessionId;
  final List<FrequencyBehaviorV2PairDimensionRelation> dimensions;
  final double? pureBehaviorOverlap;
  final double? mixedHilbertSchmidtOverlap;
  final String? message;

  FrequencyBehaviorV2PairDimensionRelation? forDimension(String id) {
    for (final d in dimensions) {
      if (d.dimensionId == id) return d;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'schema_version': FrequencyBehaviorV2Contract.pairRelationSchemaVersion,
        'pair_model_version': pairModelVersion,
        'encoding_version': encodingVersion,
        'mixedness_version': mixednessVersion,
        'scorer_version': scorerVersion,
        'user_a_session_id': userASessionId,
        'user_b_session_id': userBSessionId,
        'ok': ok,
        'message': message,
        'dimensions': [for (final d in dimensions) d.toJson()],
        'pure_behavior_overlap': pureBehaviorOverlap,
        'mixed_hilbert_schmidt_overlap': mixedHilbertSchmidtOverlap,
        'not_claims': const [
          'compatibility_score',
          'same_pole_means_compatible',
          'opposite_pole_means_incompatible',
          'entanglement_between_users',
          'quantum_personality',
          'truth_probability',
        ],
      };
}

/// Local 4D pair primitives on the Phase 5A signed poles.
///
/// Does not build a 24⊗24 pair state, does not edit either user's ρ, and does
/// not emit a compatibility score.
class FrequencyBehaviorV2PairRelationComputer {
  const FrequencyBehaviorV2PairRelationComputer();

  static const pairModelVersion =
      FrequencyBehaviorV2Contract.pairRelationVersion;

  static const pairBasisLabels = ['++', '+-', '-+', '--'];

  /// Π_SAME = |++⟩⟨++| + |--⟩⟨--|
  static const piSame = [
    [1.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 0.0],
    [0.0, 0.0, 0.0, 1.0],
  ];

  /// Π_OPPOSITE = |+-⟩⟨+-| + |-+⟩⟨-+|
  static const piOpposite = [
    [0.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 0.0],
  ];

  FrequencyBehaviorV2PairRelationResult relate(
    FrequencyBehaviorV2MixedStateResult a,
    FrequencyBehaviorV2MixedStateResult b,
  ) {
    if (!a.ok || a.behaviorVector12d == null || a.rhoBehavior == null) {
      return _incomplete('incomplete_user_a:${a.message ?? 'not_ok'}');
    }
    if (!b.ok || b.behaviorVector12d == null || b.rhoBehavior == null) {
      return _incomplete('incomplete_user_b:${b.message ?? 'not_ok'}');
    }
    final dims = <FrequencyBehaviorV2PairDimensionRelation>[];
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final xA = a.behaviorVector12d![d];
      final xB = b.behaviorVector12d![d];
      final sA = a.effectiveSupportByDimension[d];
      final sB = b.effectiveSupportByDimension[d];
      if (xA == null || xB == null) {
        return _incomplete('incomplete_behavior:$d');
      }
      if (sA == null || sB == null) {
        return _incomplete('incomplete_support:$d');
      }
      dims.add(dimensionRelation(
        dimensionId: d,
        xA: xA,
        xB: xB,
        effectiveSupportA: sA,
        effectiveSupportB: sB,
      ));
    }
    final pureOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
      a.rhoBehavior!,
      b.rhoBehavior!,
    );
    double? mixedOverlap;
    if (a.rhoUser != null && b.rhoUser != null) {
      mixedOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
        a.rhoUser!,
        b.rhoUser!,
      );
    }
    return FrequencyBehaviorV2PairRelationResult(
      ok: true,
      pairModelVersion: pairModelVersion,
      encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
      mixednessVersion: FrequencyBehaviorV2Contract.mixedDensityVersion,
      scorerVersion: a.scorerVersion,
      userASessionId: a.sessionId,
      userBSessionId: b.sessionId,
      dimensions: dims,
      pureBehaviorOverlap: pureOverlap,
      mixedHilbertSchmidtOverlap: mixedOverlap,
    );
  }

  FrequencyBehaviorV2PairDimensionRelation dimensionRelation({
    required String dimensionId,
    required double xA,
    required double xB,
    required double effectiveSupportA,
    required double effectiveSupportB,
  }) {
    final same = samePoleOperatorExpectation(xA, xB);
    final opposite = 1.0 - same;
    final pairSupport =
        math.sqrt((effectiveSupportA * effectiveSupportB).clamp(0.0, 1.0));
    final supportedSame = 0.5 + pairSupport * (same - 0.5);
    return FrequencyBehaviorV2PairDimensionRelation(
      dimensionId: dimensionId,
      xA: xA,
      xB: xB,
      axisFidelity: axisFidelity(xA, xB),
      samePoleExpectation: same,
      oppositePoleExpectation: opposite,
      effectiveSupportA: effectiveSupportA,
      effectiveSupportB: effectiveSupportB,
      pairSupport: pairSupport,
      supportedSamePole: supportedSame,
      supportedOppositePole: 1.0 - supportedSame,
    );
  }

  /// Analytic: (1 + x_A x_B) / 2
  static double samePoleAnalytic(double xA, double xB) => (1.0 + xA * xB) / 2.0;

  /// ⟨Φ| Π_SAME |Φ⟩ on the local 4D pair state.
  static double samePoleOperatorExpectation(double xA, double xB) {
    final phi = localPairState(xA, xB);
    return _expectation(phi, piSame);
  }

  static double oppositePoleOperatorExpectation(double xA, double xB) {
    final phi = localPairState(xA, xB);
    return _expectation(phi, piOpposite);
  }

  static double axisFidelity(double xA, double xB) {
    final a = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(xA);
    final b = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(xB);
    final inner = a.plus * b.plus + a.minus * b.minus;
    return inner * inner;
  }

  /// |phi_A⟩ ⊗ |phi_B⟩ in order |++⟩, |+-⟩, |-+⟩, |--⟩.
  static List<double> localPairState(double xA, double xB) {
    final a = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(xA);
    final b = FrequencyBehaviorV2SignedPoleEncoder.signedPoles(xB);
    return [
      a.plus * b.plus,
      a.plus * b.minus,
      a.minus * b.plus,
      a.minus * b.minus,
    ];
  }

  static double _expectation(List<double> phi, List<List<double>> op) {
    var acc = 0.0;
    for (var i = 0; i < 4; i++) {
      var vi = 0.0;
      for (var j = 0; j < 4; j++) {
        vi += op[i][j] * phi[j];
      }
      acc += phi[i] * vi;
    }
    return acc;
  }

  FrequencyBehaviorV2PairRelationResult _incomplete(String message) {
    return FrequencyBehaviorV2PairRelationResult(
      ok: false,
      pairModelVersion: pairModelVersion,
      encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
      mixednessVersion: FrequencyBehaviorV2Contract.mixedDensityVersion,
      scorerVersion: FrequencyBehaviorV2Contract.scorerVersion,
      message: message,
    );
  }
}
