import 'dart:math' as math;

import 'quantum_mixed_state_shadow_contract.dart';
import 'quantum_mixed_state_shadow_models.dart';

/// Shadow-only mixed-state quantum-inspired matcher v1.
///
/// Equal-window ensemble on one Class-B oscillator:
/// \[
/// r_x=\sum_k p_k\cos\phi_k,\quad
/// r_y=\sum_k p_k\sin\phi_k,\quad
/// p_k=1/K
/// \]
/// \[
/// \rho=\tfrac12\begin{pmatrix}1&r_x-ir_y\\ r_x+ir_y&1\end{pmatrix}
/// \]
/// Purity \((1+|r|^2)/2\); qubit fidelity and trace distance as contracted.
///
/// Does **not** fuse with \(D_{\mathrm{structural}}\), `phase_alignment`, or
/// `activity_level_gap`. No Discover / Persona / RVI / free \(\lambda\).
class QuantumMixedStateShadowMatcher {
  const QuantumMixedStateShadowMatcher();

  QuantumMixedStateShadowResult compare({
    required List<QuantumMixedStatePhaseMember> ensembleA,
    required List<QuantumMixedStatePhaseMember> ensembleB,
  }) {
    final builtA = _buildEnsemble(ensembleA);
    if (builtA.error != null) {
      return _unavailable(
        reason: builtA.error!,
        countA: ensembleA.length,
        countB: ensembleB.length,
      );
    }
    final builtB = _buildEnsemble(ensembleB);
    if (builtB.error != null) {
      return _unavailable(
        reason: builtB.error!,
        countA: ensembleA.length,
        countB: ensembleB.length,
        oscillatorId: builtA.oscillatorId,
        periodSeconds: builtA.periodSeconds,
        omega: builtA.omega,
        referenceEpoch: builtA.referenceEpoch,
      );
    }

    // Pairwise provenance must match.
    if (builtA.oscillatorId != builtB.oscillatorId ||
        !_near(
          builtA.omega!,
          builtB.omega!,
          QuantumMixedStateShadowContract.omegaRelativeTolerance,
        ) ||
        !_near(
          builtA.periodSeconds!,
          builtB.periodSeconds!,
          QuantumMixedStateShadowContract.periodRelativeTolerance,
        ) ||
        builtA.referenceEpoch != builtB.referenceEpoch) {
      return _unavailable(
        reason: QuantumMixedStateShadowContract.reasonProvenanceMismatch,
        countA: ensembleA.length,
        countB: ensembleB.length,
        oscillatorId: builtA.oscillatorId,
        periodSeconds: builtA.periodSeconds,
        omega: builtA.omega,
        referenceEpoch: builtA.referenceEpoch,
      );
    }

    final rA = builtA.bloch!;
    final rB = builtB.bloch!;
    if (!_validateRho(rA) || !_validateRho(rB)) {
      return _unavailable(
        reason: QuantumMixedStateShadowContract.reasonInvalidRho,
        countA: ensembleA.length,
        countB: ensembleB.length,
        oscillatorId: builtA.oscillatorId,
        periodSeconds: builtA.periodSeconds,
        omega: builtA.omega,
        referenceEpoch: builtA.referenceEpoch,
      );
    }

    final nA2 = rA.normSquared;
    final nB2 = rB.normSquared;
    final purityA = (1.0 + nA2) / 2.0;
    final purityB = (1.0 + nB2) / 2.0;
    final dot = rA.rx * rB.rx + rA.ry * rB.ry;
    final spread = math.sqrt(
      math.max(0.0, 1.0 - nA2) * math.max(0.0, 1.0 - nB2),
    );
    final fidelity = 0.5 * (1.0 + dot + spread);
    final drx = rA.rx - rB.rx;
    final dry = rA.ry - rB.ry;
    final traceDistance = 0.5 * math.sqrt(drx * drx + dry * dry);

    return QuantumMixedStateShadowResult(
      available: true,
      unavailableReason: null,
      purityA: purityA,
      purityB: purityB,
      qiMixedFidelity: fidelity.clamp(0.0, 1.0),
      qiTraceDistance: traceDistance.clamp(0.0, 1.0),
      blochA: rA,
      blochB: rB,
      ensembleCountA: ensembleA.length,
      ensembleCountB: ensembleB.length,
      oscillatorId: builtA.oscillatorId,
      periodSeconds: builtA.periodSeconds,
      omega: builtA.omega,
      referenceEpoch: builtA.referenceEpoch,
      weightPolicyId: QuantumMixedStateShadowContract.weightPolicyId,
    );
  }

  /// Build Bloch vector for a single ensemble (diagnostics / tests).
  static ({
    QuantumMixedStateBlochVector? bloch,
    double? purity,
    String? error,
    String? oscillatorId,
    double? periodSeconds,
    double? omega,
    String? referenceEpoch,
  }) buildEnsemble(List<QuantumMixedStatePhaseMember> members) {
    final b = const QuantumMixedStateShadowMatcher()._buildEnsemble(members);
    if (b.error != null) {
      return (
        bloch: null,
        purity: null,
        error: b.error,
        oscillatorId: b.oscillatorId,
        periodSeconds: b.periodSeconds,
        omega: b.omega,
        referenceEpoch: b.referenceEpoch,
      );
    }
    return (
      bloch: b.bloch,
      purity: (1.0 + b.bloch!.normSquared) / 2.0,
      error: null,
      oscillatorId: b.oscillatorId,
      periodSeconds: b.periodSeconds,
      omega: b.omega,
      referenceEpoch: b.referenceEpoch,
    );
  }

  _BuiltEnsemble _buildEnsemble(List<QuantumMixedStatePhaseMember> members) {
    if (members.isEmpty) {
      return const _BuiltEnsemble(
        error: QuantumMixedStateShadowContract.reasonEmptyEnsemble,
      );
    }
    if (members.length < QuantumMixedStateShadowContract.minEnsembleSize) {
      return _BuiltEnsemble(
        error: QuantumMixedStateShadowContract.reasonInsufficientEnsemble,
        oscillatorId: members.first.oscillatorId,
        periodSeconds: members.first.periodSeconds,
        omega: members.first.omega,
        referenceEpoch: members.first.referenceEpoch,
      );
    }

    final first = members.first;
    if (first.oscillatorId.isEmpty ||
        first.referenceEpoch.isEmpty ||
        !first.omega.isFinite ||
        !first.periodSeconds.isFinite ||
        first.periodSeconds <= 0 ||
        !first.phaseRadians.isFinite) {
      return const _BuiltEnsemble(
        error: QuantumMixedStateShadowContract.reasonInconsistentEnsemble,
      );
    }

    for (final m in members) {
      if (m.oscillatorId != first.oscillatorId ||
          m.referenceEpoch != first.referenceEpoch ||
          !_near(
            m.omega,
            first.omega,
            QuantumMixedStateShadowContract.omegaRelativeTolerance,
          ) ||
          !_near(
            m.periodSeconds,
            first.periodSeconds,
            QuantumMixedStateShadowContract.periodRelativeTolerance,
          ) ||
          !m.phaseRadians.isFinite) {
        return _BuiltEnsemble(
          error: QuantumMixedStateShadowContract.reasonInconsistentEnsemble,
          oscillatorId: first.oscillatorId,
          periodSeconds: first.periodSeconds,
          omega: first.omega,
          referenceEpoch: first.referenceEpoch,
        );
      }
    }

    // Equal-window weights p_k = 1/K.
    final p = 1.0 / members.length;
    var rx = 0.0;
    var ry = 0.0;
    for (final m in members) {
      rx += p * math.cos(m.phaseRadians);
      ry += p * math.sin(m.phaseRadians);
    }
    // Numerical clamp: |r| cannot exceed 1 for a valid mixture of unit Bloch vectors.
    final n = math.sqrt(rx * rx + ry * ry);
    if (n > 1.0 + QuantumMixedStateShadowContract.rhoNumericalTolerance) {
      return _BuiltEnsemble(
        error: QuantumMixedStateShadowContract.reasonInvalidRho,
        oscillatorId: first.oscillatorId,
        periodSeconds: first.periodSeconds,
        omega: first.omega,
        referenceEpoch: first.referenceEpoch,
      );
    }
    if (n > 1.0) {
      rx /= n;
      ry /= n;
    }

    return _BuiltEnsemble(
      bloch: QuantumMixedStateBlochVector(rx: rx, ry: ry),
      oscillatorId: first.oscillatorId,
      periodSeconds: first.periodSeconds,
      omega: first.omega,
      referenceEpoch: first.referenceEpoch,
    );
  }

  /// Validate equatorial \(\rho=\frac12(I+\mathbf{r}\cdot\sigma)\): Hermitian, PSD, Tr=1.
  static bool _validateRho(QuantumMixedStateBlochVector r) {
    final n2 = r.normSquared;
    if (!n2.isFinite || !r.rx.isFinite || !r.ry.isFinite) return false;
    // |r| <= 1 ⇒ eigenvalues (1±|r|)/2 >= 0; Tr ρ = 1 by construction.
    return n2 <=
        1.0 + QuantumMixedStateShadowContract.rhoNumericalTolerance;
  }

  static bool _near(double a, double b, double relTol) {
    final scale = math.max(a.abs(), math.max(b.abs(), 1.0));
    return (a - b).abs() <= relTol * scale;
  }

  static QuantumMixedStateShadowResult _unavailable({
    required String reason,
    required int countA,
    required int countB,
    String? oscillatorId,
    double? periodSeconds,
    double? omega,
    String? referenceEpoch,
  }) {
    return QuantumMixedStateShadowResult(
      available: false,
      unavailableReason: reason,
      purityA: null,
      purityB: null,
      qiMixedFidelity: null,
      qiTraceDistance: null,
      blochA: null,
      blochB: null,
      ensembleCountA: countA,
      ensembleCountB: countB,
      oscillatorId: oscillatorId,
      periodSeconds: periodSeconds,
      omega: omega,
      referenceEpoch: referenceEpoch,
      weightPolicyId: QuantumMixedStateShadowContract.weightPolicyId,
    );
  }
}

class _BuiltEnsemble {
  const _BuiltEnsemble({
    this.bloch,
    this.error,
    this.oscillatorId,
    this.periodSeconds,
    this.omega,
    this.referenceEpoch,
  });

  final QuantumMixedStateBlochVector? bloch;
  final String? error;
  final String? oscillatorId;
  final double? periodSeconds;
  final double? omega;
  final String? referenceEpoch;
}
