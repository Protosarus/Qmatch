import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_quantum_state.dart';
import 'frequency_behavior_v2_scorer.dart';

/// Quantum-inspired mixed-state representation.
///
/// Mixedness comes only from Phase 4B support. It does not rewrite [psi] or
/// [rho_behavior]. Not pair compatibility, entanglement, or quantum psychology.
class FrequencyBehaviorV2MixedStateResult {
  const FrequencyBehaviorV2MixedStateResult({
    required this.ok,
    required this.mixednessVersion,
    required this.encodingVersion,
    required this.confidenceVersion,
    required this.scorerVersion,
    this.bankVersion,
    this.sessionId,
    this.effectiveSupportByDimension = const {},
    this.globalSupport,
    this.lambda,
    this.pureStatePurity,
    this.mixedStatePurity,
    this.analyticMixedPurity,
    this.trace,
    this.behaviorVector12d,
    this.stateVector24d,
    this.rhoBehavior,
    this.rhoUser,
    this.message,
  });

  final bool ok;
  final String mixednessVersion;
  final String encodingVersion;
  final String confidenceVersion;
  final String scorerVersion;
  final String? bankVersion;
  final String? sessionId;
  final Map<String, double> effectiveSupportByDimension;
  final double? globalSupport;
  final double? lambda;
  final double? pureStatePurity;
  final double? mixedStatePurity;
  final double? analyticMixedPurity;
  final double? trace;
  final Map<String, double>? behaviorVector12d;
  final List<double>? stateVector24d;
  final List<List<double>>? rhoBehavior;
  final List<List<double>>? rhoUser;
  final String? message;

  Map<String, dynamic> toJson({bool includeDensityMatrices = false}) {
    return {
      'schema_version': FrequencyBehaviorV2Contract.mixedDensitySchemaVersion,
      'mixedness_version': mixednessVersion,
      'encoding_version': encodingVersion,
      'confidence_version': confidenceVersion,
      'scorer_version': scorerVersion,
      'bank_version': bankVersion,
      'session_id': sessionId,
      'ok': ok,
      'message': message,
      'effective_support_by_dimension': effectiveSupportByDimension,
      'global_support': globalSupport,
      'lambda': lambda,
      'pure_state_purity': pureStatePurity,
      'mixed_state_purity': mixedStatePurity,
      'analytic_mixed_purity': analyticMixedPurity,
      'trace': trace,
      'behavior_vector_12d': behaviorVector12d,
      'state_vector_24d': stateVector24d,
      'density_matrices_omitted': !includeDensityMatrices,
      if (includeDensityMatrices) ...{
        'rho_behavior': rhoBehavior,
        'rho_user': rhoUser,
      },
      'not_claims': const [
        'quantum_personality',
        'quantum_consciousness',
        'quantum_psychology_proof',
        'pair_compatibility',
        'entanglement_between_users',
        'wavefunction_collapse',
        'scientifically_validated_quantum_behavior',
        'probability_of_truth',
        'clinical_certainty',
      ],
    };
  }
}

/// Builds `rho_user = (1-λ) rho_behavior + λ I/24`. Does not edit [psi].
class FrequencyBehaviorV2MixedDensityMixer {
  const FrequencyBehaviorV2MixedDensityMixer();

  static const mixednessVersion =
      FrequencyBehaviorV2Contract.mixedDensityVersion;
  static const hilbertDimension =
      FrequencyBehaviorV2Contract.signedPoleAmplitudeCount;

  FrequencyBehaviorV2MixedStateResult mix({
    required FrequencyBehaviorV2SignedPoleState pure,
    required Map<String, double> provisionalConfidence,
    required Map<String, double> confidenceCompleteness,
    String confidenceVersion =
        FrequencyBehaviorV2Contract.confidenceModelVersion,
  }) {
    final support = <String, double>{};
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final pc = provisionalConfidence[d];
      final cc = confidenceCompleteness[d];
      if (pc == null) {
        return _incomplete(
          pure: pure,
          confidenceVersion: confidenceVersion,
          message: 'incomplete_confidence:$d',
        );
      }
      if (cc == null) {
        return _incomplete(
          pure: pure,
          confidenceVersion: confidenceVersion,
          message: 'incomplete_completeness:$d',
        );
      }
      final pcOk = _unitInterval(pc);
      final ccOk = _unitInterval(cc);
      if (pcOk == null) {
        return _incomplete(
          pure: pure,
          confidenceVersion: confidenceVersion,
          message: 'confidence_out_of_range:$d',
        );
      }
      if (ccOk == null) {
        return _incomplete(
          pure: pure,
          confidenceVersion: confidenceVersion,
          message: 'completeness_out_of_range:$d',
        );
      }
      support[d] = pcOk * ccOk;
    }

    var sum = 0.0;
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      sum += support[d]!;
    }
    final global = sum / FrequencyBehaviorV2Contract.dimensionCount;
    final lambda = 1.0 - global;
    final rhoB = FrequencyBehaviorV2RealMatrix.copy(pure.pureDensityMatrix);
    final rhoU = _depolarize(rhoB, lambda);
    final mixedPurity = FrequencyBehaviorV2RealMatrix.purity(rhoU);
    final analytic = analyticPurity(lambda);
    return FrequencyBehaviorV2MixedStateResult(
      ok: true,
      mixednessVersion: mixednessVersion,
      encodingVersion: pure.encodingVersion,
      confidenceVersion: confidenceVersion,
      scorerVersion: pure.scorerVersion,
      bankVersion: pure.bankVersion,
      sessionId: pure.sessionId,
      effectiveSupportByDimension: support,
      globalSupport: global,
      lambda: lambda,
      pureStatePurity: pure.purity,
      mixedStatePurity: mixedPurity,
      analyticMixedPurity: analytic,
      trace: FrequencyBehaviorV2RealMatrix.trace(rhoU),
      behaviorVector12d: Map<String, double>.from(pure.behaviorVector12d),
      stateVector24d: List<double>.from(pure.stateVector24d),
      rhoBehavior: rhoB,
      rhoUser: rhoU,
    );
  }

  FrequencyBehaviorV2MixedStateResult mixFromScore(
    FrequencyBehaviorV2ScoreResult score,
  ) {
    if (!score.ok) {
      return FrequencyBehaviorV2MixedStateResult(
        ok: false,
        mixednessVersion: mixednessVersion,
        encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
        confidenceVersion: FrequencyBehaviorV2Contract.confidenceModelVersion,
        scorerVersion: score.scorerVersion,
        bankVersion: score.bankVersion,
        sessionId: score.sessionId,
        message: 'score_not_ok:${score.message}',
      );
    }
    late final FrequencyBehaviorV2SignedPoleState pure;
    try {
      pure =
          const FrequencyBehaviorV2SignedPoleEncoder().encodeFromScore(score);
    } on StateError catch (e) {
      return FrequencyBehaviorV2MixedStateResult(
        ok: false,
        mixednessVersion: mixednessVersion,
        encodingVersion: FrequencyBehaviorV2Contract.signedPoleEncodingVersion,
        confidenceVersion: FrequencyBehaviorV2Contract.confidenceModelVersion,
        scorerVersion: score.scorerVersion,
        bankVersion: score.bankVersion,
        sessionId: score.sessionId,
        message: e.message,
      );
    }
    final pc = <String, double>{};
    final cc = <String, double>{};
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final row = score.scoreFor(d);
      if (row?.provisionalConfidence != null) {
        pc[d] = row!.provisionalConfidence!;
      }
      if (row?.confidenceCompleteness != null) {
        cc[d] = row!.confidenceCompleteness!;
      }
    }
    return mix(
      pure: pure,
      provisionalConfidence: pc,
      confidenceCompleteness: cc,
      confidenceVersion: score.confidenceModelVersion,
    );
  }

  /// Tr(ρ²) for ρ = (1-λ)|ψ⟩⟨ψ| + λ I/D.
  static double analyticPurity(double lambda, {int d = hilbertDimension}) {
    final oneMinus = 1.0 - lambda;
    return oneMinus * oneMinus + lambda * (2.0 - lambda) / d;
  }

  static List<List<double>> _depolarize(
    List<List<double>> rhoBehavior,
    double lambda,
  ) {
    final n = hilbertDimension;
    final mixed = FrequencyBehaviorV2RealMatrix.scaled(
      rhoBehavior,
      1.0 - lambda,
    );
    final noise = FrequencyBehaviorV2RealMatrix.scaled(
      FrequencyBehaviorV2RealMatrix.identity(n),
      lambda / n,
    );
    return FrequencyBehaviorV2RealMatrix.add(mixed, noise);
  }

  static double? _unitInterval(double v) {
    if (v.isNaN) return null;
    if (v < -1e-12 || v > 1.0 + 1e-12) return null;
    if (v < 0) return 0.0;
    if (v > 1) return 1.0;
    return v;
  }

  FrequencyBehaviorV2MixedStateResult _incomplete({
    required FrequencyBehaviorV2SignedPoleState pure,
    required String confidenceVersion,
    required String message,
  }) {
    return FrequencyBehaviorV2MixedStateResult(
      ok: false,
      mixednessVersion: mixednessVersion,
      encodingVersion: pure.encodingVersion,
      confidenceVersion: confidenceVersion,
      scorerVersion: pure.scorerVersion,
      bankVersion: pure.bankVersion,
      sessionId: pure.sessionId,
      behaviorVector12d: Map<String, double>.from(pure.behaviorVector12d),
      stateVector24d: List<double>.from(pure.stateVector24d),
      message: message,
    );
  }
}
