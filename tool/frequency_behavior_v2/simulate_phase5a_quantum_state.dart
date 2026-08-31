// ignore_for_file: avoid_print
/// Phase 5A signed-pole quantum-inspired state encoding audit.
///
/// Does not activate V2. Does not define mixedness, pair compatibility,
/// or entanglement. Does not modify scorer, confidence, selector, or evidence.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase5a_quantum_state.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var outPath =
      FrequencyBehaviorV2Contract.phase5aQuantumStateAuditRelativePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
  }

  const encoder = FrequencyBehaviorV2SignedPoleEncoder();
  final mixed = <String, double>{
    'contact_need': 1.0,
    'closeness_pace': -1.0,
    'initiative': 0.5,
    'autonomy': -0.5,
    'reassurance_need': 0.0,
    'uncertainty_tolerance': 0.25,
    'disclosure_pace': -0.25,
    'boundary_firmness': 0.75,
    'repair_style': -0.75,
    'social_energy': 1.0,
    'structure_preference': 0.0,
    'adaptability': -1.0,
  };
  final plusAxis = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0)
    ..['contact_need'] = 1.0;
  final minusAxis = FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0)
    ..['contact_need'] = -1.0;

  final profiles = <String, FrequencyBehaviorV2SignedPoleState>{
    'ALL_POSITIVE': encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      sessionId: 'phase5a-all-positive',
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    ),
    'ALL_NEGATIVE': encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
      sessionId: 'phase5a-all-negative',
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    ),
    'NEUTRAL': encoder.encode(
      behaviorVector12d:
          FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0),
      sessionId: 'phase5a-neutral',
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    ),
    'MIXED_PROFILE': encoder.encode(
      behaviorVector12d: mixed,
      sessionId: 'phase5a-mixed',
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    ),
  };
  final axisPlus = encoder.encode(
    behaviorVector12d: plusAxis,
    sessionId: 'phase5a-axis-plus',
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
  );
  final axisMinus = encoder.encode(
    behaviorVector12d: minusAxis,
    sessionId: 'phase5a-axis-minus',
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
  );

  final pos = profiles['ALL_POSITIVE']!;
  final neg = profiles['ALL_NEGATIVE']!;
  final dot = FrequencyBehaviorV2SignedPoleEncoder.vectorDot(
    pos.stateVector24d,
    neg.stateVector24d,
  );
  final overlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
    pos.pureDensityMatrix,
    neg.pureDensityMatrix,
  );
  final axisDot = FrequencyBehaviorV2SignedPoleEncoder.vectorDot(
    axisPlus.stateVector24d,
    axisMinus.stateVector24d,
  );
  final axisOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
    axisPlus.pureDensityMatrix,
    axisMinus.pureDensityMatrix,
  );

  final repeat = encoder.encode(
    behaviorVector12d: mixed,
    sessionId: 'phase5a-mixed',
    bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
  );
  final deterministic = jsonEncode(profiles['MIXED_PROFILE']!.stateVector24d) ==
      jsonEncode(repeat.stateVector24d);

  var allPure = true;
  for (final s in [...profiles.values, axisPlus, axisMinus]) {
    if (!_isPure(s)) allPure = false;
  }

  final psiDistinct = !_closeVec(pos.stateVector24d, neg.stateVector24d);
  final rhoDistinct = overlap.abs() < 1e-9;
  final naiveWouldCollide = true;

  final buf = StringBuffer();
  buf.writeln(
    '# Frequency V2 Phase 5A — Signed-pole quantum-inspired state encoding',
  );
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'This is a **quantum-inspired mathematical representation**. '
    'It is not quantum psychology, not a claim that a person is a quantum '
    'system, and not pair compatibility.',
  );
  buf.writeln('');
  buf.writeln(
    'encoding_version: `${FrequencyBehaviorV2Contract.signedPoleEncodingVersion}`',
  );
  buf.writeln(
    'scorer_version: `${FrequencyBehaviorV2Contract.scorerVersion}`',
  );
  buf.writeln(
    'bank_version: `${FrequencyBehaviorV2Contract.poolVersionTrDraft1}`',
  );
  buf.writeln(
    'basis size: ${FrequencyBehaviorV2Contract.signedPoleAmplitudeCount}',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln('| Check | Result |');
  buf.writeln('|---|---|');
  buf.writeln(
      '| all example states pure (trace/purity/PSD/rho²≈rho) | **$allPure** |');
  buf.writeln('| same 12D vector → identical psi | **$deterministic** |');
  buf.writeln('| psi_ALL_POSITIVE ≠ psi_ALL_NEGATIVE | **$psiDistinct** |');
  buf.writeln('| rho_ALL_POSITIVE ≠ rho_ALL_NEGATIVE | **$rhoDistinct** |');
  buf.writeln('| opposite-profile state-vector dot product | **${_n(dot)}** |');
  buf.writeln(
      '| opposite-profile density-matrix overlap Tr(ρ_A ρ_B) | **${_n(overlap)}** |');
  buf.writeln(
      '| opposite-profile similarity is not 1 | **${dot.abs() < 0.01 && overlap.abs() < 0.01}** |');
  buf.writeln(
      '| SINGLE_AXIS +1 vs -1 distinct poles | **${axisPlus.poleAmplitudes24d[0] > 0.9 && axisMinus.poleAmplitudes24d[1] > 0.9}** |');
  buf.writeln(
      '| SINGLE_AXIS density overlap ≠ 1 | **${axisOverlap < 0.99}** |');
  buf.writeln(
    '| forbidden 12D-as-psi encoding would make +1/−1 collide | **$naiveWouldCollide** |',
  );
  buf.writeln('| mixedness lambda defined | **false** |');
  buf.writeln('| pair compatibility defined | **false** |');
  buf.writeln('');
  buf.writeln('## Forbidden encoding (why signed poles exist)');
  buf.writeln('');
  buf.writeln(
    'If the signed 12D vector were used as a normalized amplitude vector, '
    'then `psi_all_minus = - psi_all_plus` and `ρ = |psi⟩⟨psi|` would be '
    '**identical** for globally opposite profiles (overlap = 1). '
    'Signed plus/minus poles keep those profiles distinguishable '
    '(overlap ≈ 0).',
  );
  buf.writeln('');

  for (final name in [
    'ALL_POSITIVE',
    'ALL_NEGATIVE',
    'NEUTRAL',
    'MIXED_PROFILE',
  ]) {
    _writeProfile(buf, name, profiles[name]!);
  }

  buf.writeln('## SINGLE_AXIS_OPPOSITES');
  buf.writeln('');
  buf.writeln(
    '`contact_need = +1` versus `contact_need = -1`, all other dimensions 0 '
    '(behavioral center, not missing / not low confidence).',
  );
  buf.writeln('');
  buf.writeln('| | +1 pole | -1 pole |');
  buf.writeln('|---|---|---|');
  buf.writeln(
    '| contact_need:+ amplitude | ${_n(axisPlus.poleAmplitudes24d[0])} | ${_n(axisMinus.poleAmplitudes24d[0])} |',
  );
  buf.writeln(
    '| contact_need:- amplitude | ${_n(axisPlus.poleAmplitudes24d[1])} | ${_n(axisMinus.poleAmplitudes24d[1])} |',
  );
  buf.writeln('| state-vector dot product | ${_n(axisDot)} | |');
  buf.writeln('| density-matrix overlap | ${_n(axisOverlap)} | |');
  buf.writeln(
      '| psi norm (+) | ${_n(FrequencyBehaviorV2SignedPoleEncoder.vectorNorm(axisPlus.stateVector24d))} | |');
  buf.writeln('| trace (+) | ${_n(axisPlus.trace)} | |');
  buf.writeln('| purity (+) | ${_n(axisPlus.purity)} | |');
  buf.writeln('');
  _writeProfile(buf, 'SINGLE_AXIS_+1', axisPlus);
  _writeProfile(buf, 'SINGLE_AXIS_-1', axisMinus);

  buf.writeln('## Neutrality');
  buf.writeln('');
  buf.writeln(
    'For `x = 0`, plus and minus pole amplitudes are equal (`sqrt(0.5)`). '
    'That is behavioral center. It is not unknown, low confidence, or missing.',
  );
  buf.writeln('');
  buf.writeln('## What this phase does not do');
  buf.writeln('');
  buf.writeln('- define mixedness lambda');
  buf.writeln('- inject confidence / evidence / latency into psi');
  buf.writeln('- create pair compatibility or entanglement');
  buf.writeln('- create collapse / measurement metaphors');
  buf.writeln('- claim quantum mechanics validates personality');
  buf.writeln('- modify scorer, confidence, selector, or evidence');
  buf.writeln('- activate V2 or persist the 24×24 matrix');
  buf.writeln(
    '- touch V1 / Firebase / C2 / Discover / Persona / matching',
  );
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 5A SIGNED 24D QUANTUM-INSPIRED BEHAVIORAL STATE READY — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

bool _isPure(FrequencyBehaviorV2SignedPoleState s) {
  const tol = FrequencyBehaviorV2Contract.signedPoleNumericTolerance;
  final norm =
      FrequencyBehaviorV2SignedPoleEncoder.vectorNorm(s.stateVector24d);
  if ((norm - 1.0).abs() > tol) return false;
  if ((s.trace - 1.0).abs() > tol) return false;
  if ((s.purity - 1.0).abs() > 1e-8) return false;
  if (FrequencyBehaviorV2RealMatrix.maxAbsAsymmetry(s.pureDensityMatrix) >
      tol) {
    return false;
  }
  final rho2 = FrequencyBehaviorV2RealMatrix.multiply(
    s.pureDensityMatrix,
    s.pureDensityMatrix,
  );
  final idemp = FrequencyBehaviorV2RealMatrix.frobeniusNorm(
    FrequencyBehaviorV2RealMatrix.subtract(rho2, s.pureDensityMatrix),
  );
  if (idemp > 1e-8) return false;
  final ev = FrequencyBehaviorV2RealMatrix.symmetricEigenvalues(
    s.pureDensityMatrix,
  );
  if (ev.first < -1e-8) return false;
  if ((ev.last - 1.0).abs() > 1e-8) return false;
  return true;
}

bool _closeVec(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 1e-12) return false;
  }
  return true;
}

void _writeProfile(
  StringBuffer buf,
  String name,
  FrequencyBehaviorV2SignedPoleState s,
) {
  buf.writeln('## $name');
  buf.writeln('');
  buf.writeln('12D input:');
  buf.writeln('');
  buf.writeln('| dimension | x |');
  buf.writeln('|---|---|');
  for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) {
    buf.writeln('| $d | ${_n(s.behaviorVector12d[d]!)} |');
  }
  buf.writeln('');
  buf.writeln('24D amplitudes (signed poles, before `/sqrt(12)`):');
  buf.writeln('');
  buf.writeln('| basis | amplitude | psi |');
  buf.writeln('|---|---|---|');
  for (var i = 0; i < s.basisLabels.length; i++) {
    buf.writeln(
      '| ${s.basisLabels[i]} | ${_n(s.poleAmplitudes24d[i])} | ${_n(s.stateVector24d[i])} |',
    );
  }
  buf.writeln('');
  buf.writeln(
    '| norm(psi) | ${_n(FrequencyBehaviorV2SignedPoleEncoder.vectorNorm(s.stateVector24d))} |',
  );
  buf.writeln('| Σ pole² | ${_n(_energy(s.poleAmplitudes24d))} |');
  buf.writeln('| trace | ${_n(s.trace)} |');
  buf.writeln('| purity | ${_n(s.purity)} |');
  buf.writeln('');
}

double _energy(List<double> a) {
  var s = 0.0;
  for (final v in a) {
    s += v * v;
  }
  return s;
}

String _n(double v) {
  if (v.abs() < 1e-12) return '0';
  return v.toStringAsFixed(6);
}
