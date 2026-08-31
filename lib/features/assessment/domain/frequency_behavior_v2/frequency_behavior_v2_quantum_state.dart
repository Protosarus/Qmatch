import 'dart:math' as math;

import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_scorer.dart';

/// Quantum-inspired signed-pole encoding of a 12D behavioral vector.
///
/// This is a mathematical representation only. It is not quantum psychology,
/// pair compatibility, entanglement, or a claim that a person is a quantum
/// system. Confidence, evidence, latency, and mixedness do not enter [psi].
class FrequencyBehaviorV2SignedPoleState {
  const FrequencyBehaviorV2SignedPoleState({
    required this.encodingVersion,
    required this.scorerVersion,
    required this.bankVersion,
    required this.sessionId,
    required this.basisLabels,
    required this.behaviorVector12d,
    required this.poleAmplitudes24d,
    required this.stateVector24d,
    required this.pureDensityMatrix,
    required this.trace,
    required this.purity,
  });

  final String encodingVersion;
  final String scorerVersion;
  final String? bankVersion;
  final String? sessionId;
  final List<String> basisLabels;
  final Map<String, double> behaviorVector12d;
  final List<double> poleAmplitudes24d;
  final List<double> stateVector24d;
  final List<List<double>> pureDensityMatrix;
  final double trace;
  final double purity;

  /// Default JSON omits the 24×24 matrix so it is not persisted.
  Map<String, dynamic> toJson({bool includeDensityMatrix = false}) {
    return {
      'schema_version':
          FrequencyBehaviorV2Contract.signedPoleStateSchemaVersion,
      'encoding_version': encodingVersion,
      'scorer_version': scorerVersion,
      'bank_version': bankVersion,
      'session_id': sessionId,
      'basis_labels': basisLabels,
      'behavior_vector_12d': behaviorVector12d,
      'pole_amplitudes_24d': poleAmplitudes24d,
      'state_vector_24d': stateVector24d,
      'trace': trace,
      'purity': purity,
      'pure_density_matrix_omitted': !includeDensityMatrix,
      if (includeDensityMatrix) 'pure_density_matrix_24x24': pureDensityMatrix,
      'not_claims': const [
        'quantum_psychology',
        'quantum_mechanical_personhood',
        'pair_compatibility',
        'entanglement',
        'mixedness',
        'measurement_collapse',
      ],
    };
  }
}

/// Encodes signed 12D [normalized_behavior] into a 24-amplitude unit vector
/// and its pure outer-product density matrix.
///
/// Forbidden: treating the 12D signed vector itself as a pure-state amplitude
/// vector. [psi] and [-psi] would then share one density matrix, making
/// globally opposite profiles indistinguishable.
class FrequencyBehaviorV2SignedPoleEncoder {
  const FrequencyBehaviorV2SignedPoleEncoder();

  static const encodingVersion =
      FrequencyBehaviorV2Contract.signedPoleEncodingVersion;

  static List<String> get basisLabels => [
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) ...[
          '$d:+',
          '$d:-',
        ],
      ];

  FrequencyBehaviorV2SignedPoleState encode({
    required Map<String, double> behaviorVector12d,
    String scorerVersion = FrequencyBehaviorV2Contract.scorerVersion,
    String? bankVersion,
    String? sessionId,
  }) {
    final x = _requireCompleteVector(behaviorVector12d);
    final poles = <double>[];
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final pair = signedPoles(x[d]!);
      poles.add(pair.plus);
      poles.add(pair.minus);
    }
    final scale =
        math.sqrt(FrequencyBehaviorV2Contract.signedPoleGlobalNormSquared);
    final psi = [for (final a in poles) a / scale];
    final rho = outerProduct(psi);
    return FrequencyBehaviorV2SignedPoleState(
      encodingVersion: encodingVersion,
      scorerVersion: scorerVersion,
      bankVersion: bankVersion,
      sessionId: sessionId,
      basisLabels: basisLabels,
      behaviorVector12d: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          d: x[d]!,
      },
      poleAmplitudes24d: poles,
      stateVector24d: psi,
      pureDensityMatrix: rho,
      trace: FrequencyBehaviorV2RealMatrix.trace(rho),
      purity: FrequencyBehaviorV2RealMatrix.purity(rho),
    );
  }

  /// Uses only [FrequencyBehaviorV2ScoreResult.behavioralMean12d].
  /// Confidence, evidence, and consistency fields are ignored.
  FrequencyBehaviorV2SignedPoleState encodeFromScore(
    FrequencyBehaviorV2ScoreResult score,
  ) {
    if (!score.ok) {
      throw StateError('score_not_ok:${score.message}');
    }
    final raw = <String, double>{};
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final v = score.scoreFor(d)?.normalizedBehavior;
      if (v == null) {
        throw StateError('incomplete_behavior_vector:$d');
      }
      raw[d] = v;
    }
    return encode(
      behaviorVector12d: raw,
      scorerVersion: score.scorerVersion,
      bankVersion: score.bankVersion,
      sessionId: score.sessionId,
    );
  }

  /// Per-dimension signed poles. x=0 is behavioral center, not missing.
  static FrequencyBehaviorV2SignedPoles signedPoles(double x) {
    if (x.isNaN) {
      throw ArgumentError.value(x, 'x', 'nan');
    }
    if (x < -1.0 - 1e-12 || x > 1.0 + 1e-12) {
      throw ArgumentError.value(x, 'x', 'normalized_behavior_out_of_range');
    }
    final clamped = x.clamp(-1.0, 1.0).toDouble();
    final plus = math.sqrt(((1.0 + clamped) / 2.0).clamp(0.0, 1.0));
    final minus = math.sqrt(((1.0 - clamped) / 2.0).clamp(0.0, 1.0));
    return FrequencyBehaviorV2SignedPoles(plus: plus, minus: minus);
  }

  static List<List<double>> outerProduct(List<double> psi) {
    final n = psi.length;
    return [
      for (var i = 0; i < n; i++) [for (var j = 0; j < n; j++) psi[i] * psi[j]],
    ];
  }

  static double vectorDot(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('dot_length_mismatch');
    }
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  static double vectorNorm(List<double> a) => math.sqrt(vectorDot(a, a));

  /// Tr(rhoA rhoB) for real symmetric matrices. Diagnostic only — not
  /// pair compatibility.
  static double densityOverlap(
    List<List<double>> rhoA,
    List<List<double>> rhoB,
  ) {
    return FrequencyBehaviorV2RealMatrix.frobeniusInner(rhoA, rhoB);
  }

  static Map<String, double> uniformBehavior(double x) => {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: x,
      };

  static Map<String, double> _requireCompleteVector(Map<String, double> raw) {
    final out = <String, double>{};
    for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final v = raw[d];
      if (v == null) {
        throw StateError('incomplete_behavior_vector:$d');
      }
      out[d] = v;
    }
    if (raw.length != FrequencyBehaviorV2Contract.dimensionCount) {
      throw StateError('unexpected_behavior_keys');
    }
    return out;
  }
}

class FrequencyBehaviorV2SignedPoles {
  const FrequencyBehaviorV2SignedPoles({
    required this.plus,
    required this.minus,
  });

  final double plus;
  final double minus;
}

/// Real-matrix helpers for the 24×24 pure behavioral density matrix.
class FrequencyBehaviorV2RealMatrix {
  FrequencyBehaviorV2RealMatrix._();

  static double trace(List<List<double>> m) {
    var s = 0.0;
    for (var i = 0; i < m.length; i++) {
      s += m[i][i];
    }
    return s;
  }

  static double frobeniusInner(List<List<double>> a, List<List<double>> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      for (var j = 0; j < a[i].length; j++) {
        s += a[i][j] * b[i][j];
      }
    }
    return s;
  }

  static double frobeniusNorm(List<List<double>> m) =>
      math.sqrt(frobeniusInner(m, m));

  /// Tr(rho^2) for a real matrix.
  static double purity(List<List<double>> rho) {
    return frobeniusInner(rho, rho);
  }

  static List<List<double>> multiply(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final n = a.length;
    final out = List.generate(n, (_) => List<double>.filled(n, 0));
    for (var i = 0; i < n; i++) {
      for (var k = 0; k < n; k++) {
        final aik = a[i][k];
        if (aik == 0) continue;
        for (var j = 0; j < n; j++) {
          out[i][j] += aik * b[k][j];
        }
      }
    }
    return out;
  }

  static List<List<double>> identity(int n) {
    return [
      for (var i = 0; i < n; i++)
        [for (var j = 0; j < n; j++) i == j ? 1.0 : 0.0],
    ];
  }

  static List<List<double>> copy(List<List<double>> m) {
    return [for (final row in m) List<double>.from(row)];
  }

  static List<List<double>> scaled(List<List<double>> m, double s) {
    return [
      for (final row in m) [for (final v in row) v * s],
    ];
  }

  static List<List<double>> add(List<List<double>> a, List<List<double>> b) {
    final n = a.length;
    return [
      for (var i = 0; i < n; i++)
        [for (var j = 0; j < n; j++) a[i][j] + b[i][j]],
    ];
  }

  static double maxAbsEntryDiff(List<List<double>> a, List<List<double>> b) {
    var max = 0.0;
    for (var i = 0; i < a.length; i++) {
      for (var j = 0; j < a[i].length; j++) {
        final d = (a[i][j] - b[i][j]).abs();
        if (d > max) max = d;
      }
    }
    return max;
  }

  static List<List<double>> subtract(
    List<List<double>> a,
    List<List<double>> b,
  ) {
    final n = a.length;
    return [
      for (var i = 0; i < n; i++)
        [for (var j = 0; j < n; j++) a[i][j] - b[i][j]],
    ];
  }

  static double maxAbsAsymmetry(List<List<double>> m) {
    var max = 0.0;
    for (var i = 0; i < m.length; i++) {
      for (var j = i + 1; j < m.length; j++) {
        final d = (m[i][j] - m[j][i]).abs();
        if (d > max) max = d;
      }
    }
    return max;
  }

  /// Jacobi eigenvalues of a real symmetric matrix, ascending.
  static List<double> symmetricEigenvalues(
    List<List<double>> matrix, {
    int maxSweeps = 64,
    double offTol = 1e-24,
  }) {
    final n = matrix.length;
    final a = [for (var i = 0; i < n; i++) List<double>.from(matrix[i])];
    for (var sweep = 0; sweep < maxSweeps; sweep++) {
      var off = 0.0;
      for (var p = 0; p < n; p++) {
        for (var q = p + 1; q < n; q++) {
          off += a[p][q] * a[p][q];
        }
      }
      if (off < offTol) break;
      for (var p = 0; p < n; p++) {
        for (var q = p + 1; q < n; q++) {
          final apq = a[p][q];
          if (apq.abs() < 1e-15) continue;
          final app = a[p][p];
          final aqq = a[q][q];
          final theta = 0.5 * math.atan2(2.0 * apq, aqq - app);
          final c = math.cos(theta);
          final s = math.sin(theta);
          for (var k = 0; k < n; k++) {
            if (k == p || k == q) continue;
            final akp = a[k][p];
            final akq = a[k][q];
            final nkp = c * akp - s * akq;
            final nkq = s * akp + c * akq;
            a[k][p] = nkp;
            a[p][k] = nkp;
            a[k][q] = nkq;
            a[q][k] = nkq;
          }
          final appN = c * c * app - 2 * s * c * apq + s * s * aqq;
          final aqqN = s * s * app + 2 * s * c * apq + c * c * aqq;
          a[p][p] = appN;
          a[q][q] = aqqN;
          a[p][q] = 0.0;
          a[q][p] = 0.0;
        }
      }
    }
    final ev = [for (var i = 0; i < n; i++) a[i][i]]..sort();
    return ev;
  }
}
