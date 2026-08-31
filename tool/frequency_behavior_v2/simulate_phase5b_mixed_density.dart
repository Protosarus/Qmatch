// ignore_for_file: avoid_print
/// Phase 5B confidence-aware mixed density audit.
///
/// Does not activate V2. Does not define pair compatibility. Does not edit
/// psi, the 12D vector, Phase 4B confidence, evidence, or the selector.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase5b_mixed_density.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var outPath =
      FrequencyBehaviorV2Contract.phase5bMixedDensityAuditRelativePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
  }

  const encoder = FrequencyBehaviorV2SignedPoleEncoder();
  const mixer = FrequencyBehaviorV2MixedDensityMixer();
  final mixedX = <String, double>{
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

  FrequencyBehaviorV2MixedStateResult mixAt({
    required Map<String, double> x,
    required double confidence,
    required double completeness,
    required String sessionId,
  }) {
    final pure = encoder.encode(
      behaviorVector12d: x,
      sessionId: sessionId,
      bankVersion: FrequencyBehaviorV2Contract.poolVersionTrDraft1,
    );
    return mixer.mix(
      pure: pure,
      provisionalConfidence: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          d: confidence,
      },
      confidenceCompleteness: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          d: completeness,
      },
    );
  }

  final high = mixAt(
    x: mixedX,
    confidence: 1.0,
    completeness: 1.0,
    sessionId: 'phase5b-high',
  );
  final medium = mixAt(
    x: mixedX,
    confidence: 0.6,
    completeness: 0.8,
    sessionId: 'phase5b-medium',
  );
  final low = mixAt(
    x: mixedX,
    confidence: 0.25,
    completeness: 0.4,
    sessionId: 'phase5b-low',
  );
  final none = mixAt(
    x: mixedX,
    confidence: 0.0,
    completeness: 1.0,
    sessionId: 'phase5b-none',
  );
  final sameHigh = mixAt(
    x: mixedX,
    confidence: 0.95,
    completeness: 1.0,
    sessionId: 'phase5b-same-high',
  );
  final sameLow = mixAt(
    x: mixedX,
    confidence: 0.2,
    completeness: 0.5,
    sessionId: 'phase5b-same-low',
  );
  final oppA = mixAt(
    x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
    confidence: 0.7,
    completeness: 1.0,
    sessionId: 'phase5b-opp-a',
  );
  final oppB = mixAt(
    x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
    confidence: 0.7,
    completeness: 1.0,
    sessionId: 'phase5b-opp-b',
  );
  final oppAMax = mixAt(
    x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
    confidence: 0.0,
    completeness: 0.0,
    sessionId: 'phase5b-opp-a-maxmix',
  );
  final oppBMax = mixAt(
    x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
    confidence: 0.0,
    completeness: 0.0,
    sessionId: 'phase5b-opp-b-maxmix',
  );

  final incomplete = mixer.mix(
    pure: encoder.encode(behaviorVector12d: mixedX),
    provisionalConfidence: {
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
        if (d != 'repair_style') d: 0.8,
    },
    confidenceCompleteness: {
      for (final d in FrequencyBehaviorV2Contract.canonicalDimensions) d: 1.0,
    },
  );

  final psiSame =
      jsonEncode(sameHigh.stateVector24d) == jsonEncode(sameLow.stateVector24d);
  final rhoBSame = FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        sameHigh.rhoBehavior!,
        sameLow.rhoBehavior!,
      ) <
      1e-12;
  final lambdaOrder = sameHigh.lambda! < sameLow.lambda!;
  final purityOrder = sameHigh.mixedStatePurity! > sameLow.mixedStatePurity!;
  final oppDistinct = FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        oppA.rhoUser!,
        oppB.rhoUser!,
      ) >
      1e-6;
  final oppMaxIdent = FrequencyBehaviorV2RealMatrix.maxAbsEntryDiff(
        oppAMax.rhoUser!,
        oppBMax.rhoUser!,
      ) <
      1e-12;
  final analyticOk = [
    high,
    medium,
    low,
    none,
    sameHigh,
    sameLow,
    oppA,
    oppB,
  ].every(
    (r) => (r.mixedStatePurity! - r.analyticMixedPurity!).abs() < 1e-10,
  );

  final pureOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
    oppA.rhoBehavior!,
    oppB.rhoBehavior!,
  );
  final mixedOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
    oppA.rhoUser!,
    oppB.rhoUser!,
  );
  final maxmixOverlap = FrequencyBehaviorV2SignedPoleEncoder.densityOverlap(
    oppAMax.rhoUser!,
    oppBMax.rhoUser!,
  );

  final buf = StringBuffer();
  buf.writeln('# Frequency V2 Phase 5B — Confidence-aware mixed density');
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'This is a **quantum-inspired mixed-state representation**. '
    'Overlap is a Hilbert–Schmidt diagnostic, not compatibility. '
    'Lambda is mixedness, not dishonesty or psychological entropy.',
  );
  buf.writeln('');
  buf.writeln(
    'mixedness_version: `${FrequencyBehaviorV2Contract.mixedDensityVersion}`',
  );
  buf.writeln(
    'encoding_version: `${FrequencyBehaviorV2Contract.signedPoleEncodingVersion}`',
  );
  buf.writeln(
    'confidence_version: `${FrequencyBehaviorV2Contract.confidenceModelVersion}`',
  );
  buf.writeln(
    'formula: `rho_user = (1-λ) rho_behavior + λ I/24`',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln('| Check | Result |');
  buf.writeln('|---|---|');
  buf.writeln('| analytic purity matches Tr(ρ²) | **$analyticOk** |');
  buf.writeln('| HIGH_SUPPORT lambda=0 | **${high.lambda! < 1e-12}** |');
  buf.writeln(
      '| NO_SUPPORT lambda=1 | **${(none.lambda! - 1).abs() < 1e-12}** |');
  buf.writeln(
    '| HIGH mixed purity ≈ 1 | **${(high.mixedStatePurity! - 1).abs() < 1e-10}** |',
  );
  buf.writeln(
    '| NO_SUPPORT mixed purity = 1/24 | **${(none.mixedStatePurity! - 1 / 24).abs() < 1e-10}** |',
  );
  buf.writeln(
      '| same psi / rho_behavior across HIGH vs LOW support | **${psiSame && rhoBSame}** |');
  buf.writeln('| lambda_high < lambda_low | **$lambdaOrder** |');
  buf.writeln('| mixed purity high > low | **$purityOrder** |');
  buf.writeln('| opposite profiles distinct at lambda<1 | **$oppDistinct** |');
  buf.writeln('| opposite profiles identical at lambda=1 | **$oppMaxIdent** |');
  buf.writeln(
      '| missing confidence refuses rho_user | **${!incomplete.ok && incomplete.rhoUser == null}** |');
  buf.writeln('| pair compatibility defined | **false** |');
  buf.writeln('| dimension-specific lambda defined | **false** |');
  buf.writeln('');

  void writeProfile(String name, FrequencyBehaviorV2MixedStateResult r) {
    final ev = FrequencyBehaviorV2RealMatrix.symmetricEigenvalues(r.rhoUser!);
    buf.writeln('## $name');
    buf.writeln('');
    buf.writeln('| field | value |');
    buf.writeln('|---|---|');
    buf.writeln('| global_support | ${_n(r.globalSupport!)} |');
    buf.writeln('| lambda | ${_n(r.lambda!)} |');
    buf.writeln('| pure purity | ${_n(r.pureStatePurity!)} |');
    buf.writeln('| mixed purity | ${_n(r.mixedStatePurity!)} |');
    buf.writeln('| analytic mixed purity | ${_n(r.analyticMixedPurity!)} |');
    buf.writeln('| trace | ${_n(r.trace!)} |');
    buf.writeln('| minimum eigenvalue | ${_n(ev.first)} |');
    buf.writeln('| maximum eigenvalue | ${_n(ev.last)} |');
    buf.writeln('');
  }

  writeProfile('HIGH_SUPPORT', high);
  writeProfile('MEDIUM_SUPPORT', medium);
  writeProfile('LOW_SUPPORT', low);
  writeProfile('NO_SUPPORT', none);

  buf.writeln('## SAME_BEHAVIOR_HIGH_VS_LOW_SUPPORT');
  buf.writeln('');
  buf.writeln(
    'Identical mixed 12D `normalized_behavior`. Support differs. '
    '`psi` and `rho_behavior` stay the same; only mixedness changes.',
  );
  buf.writeln('');
  buf.writeln('| | HIGH | LOW |');
  buf.writeln('|---|---|---|');
  buf.writeln(
      '| global_support | ${_n(sameHigh.globalSupport!)} | ${_n(sameLow.globalSupport!)} |');
  buf.writeln('| lambda | ${_n(sameHigh.lambda!)} | ${_n(sameLow.lambda!)} |');
  buf.writeln(
      '| mixed purity | ${_n(sameHigh.mixedStatePurity!)} | ${_n(sameLow.mixedStatePurity!)} |');
  buf.writeln('| psi identical | **$psiSame** | |');
  buf.writeln('| rho_behavior identical | **$rhoBSame** | |');
  buf.writeln('');

  buf.writeln('## OPPOSITE_BEHAVIOR_EQUAL_SUPPORT');
  buf.writeln('');
  buf.writeln(
    'All dimensions `+1` versus all `-1`, same confidence/completeness '
    '(`lambda < 1`). Hilbert–Schmidt overlap is **not** compatibility.',
  );
  buf.writeln('');
  buf.writeln('| | A (+1) | B (−1) |');
  buf.writeln('|---|---|---|');
  buf.writeln('| lambda | ${_n(oppA.lambda!)} | ${_n(oppB.lambda!)} |');
  buf.writeln(
      '| mixed purity | ${_n(oppA.mixedStatePurity!)} | ${_n(oppB.mixedStatePurity!)} |');
  buf.writeln(
      '| pure-state overlap Tr(ρ_behavior_A ρ_behavior_B) | ${_n(pureOverlap)} | |');
  buf.writeln(
      '| mixed-state Hilbert–Schmidt overlap Tr(ρ_user_A ρ_user_B) | ${_n(mixedOverlap)} | |');
  buf.writeln('| lambda=1 overlap (both I/24) | ${_n(maxmixOverlap)} | |');
  buf.writeln('');
  writeProfile('OPPOSITE_A_EQUAL_SUPPORT', oppA);
  writeProfile('OPPOSITE_B_EQUAL_SUPPORT', oppB);

  buf.writeln('## Missing data');
  buf.writeln('');
  buf.writeln('ok: **${incomplete.ok}**');
  buf.writeln('message: `${incomplete.message}`');
  buf.writeln('rho_user constructed: **${incomplete.rhoUser != null}**');
  buf.writeln('');
  buf.writeln('## What this phase does not do');
  buf.writeln('');
  buf.writeln('- pair compatibility or matching');
  buf.writeln('- dimension-specific lambda');
  buf.writeln('- alter psi or the 12D behavioral vector');
  buf.writeln('- alter Phase 4B confidence, evidence, or selector');
  buf.writeln('- entanglement / collapse / quantum personality claims');
  buf.writeln('- activate V2');
  buf.writeln(
    '- touch V1 / Firebase / C2 / Discover / Persona / matching',
  );
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 5B CONFIDENCE-AWARE MIXED DENSITY MATRIX READY — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

String _n(double v) {
  if (v.abs() < 1e-12) return '0';
  return v.toStringAsFixed(8);
}
