// ignore_for_file: avoid_print
/// Phase 5C pair-relation primitives audit.
///
/// Does not emit a compatibility score. Does not edit user rho. Does not
/// decide similarity vs complementarity.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase5c_pair_relation.dart
library;

import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var outPath =
      FrequencyBehaviorV2Contract.phase5cPairRelationAuditRelativePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
  }

  const encoder = FrequencyBehaviorV2SignedPoleEncoder();
  const mixer = FrequencyBehaviorV2MixedDensityMixer();
  const pairs = FrequencyBehaviorV2PairRelationComputer();

  FrequencyBehaviorV2MixedStateResult user({
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

  final identical = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-ident-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-ident-b',
    ),
  );
  final opposite = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-opp-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-opp-b',
    ),
  );
  final neutral = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-neu-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-neu-b',
    ),
  );
  final aligned = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.5),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-mod-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.5),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-mod-b',
    ),
  );
  final opposed = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.5),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-mop-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-0.5),
      confidence: 1,
      completeness: 1,
      sessionId: '5c-mop-b',
    ),
  );
  final sameBehHigh = pairs.relate(
    user(
      x: mixedX,
      confidence: 1,
      completeness: 1,
      sessionId: '5c-sb-high-a',
    ),
    user(
      x: mixedX,
      confidence: 1,
      completeness: 1,
      sessionId: '5c-sb-high-b',
    ),
  );
  final sameBehDiff = pairs.relate(
    user(
      x: mixedX,
      confidence: 1,
      completeness: 1,
      sessionId: '5c-sb-diff-a',
    ),
    user(
      x: mixedX,
      confidence: 0.2,
      completeness: 0.5,
      sessionId: '5c-sb-diff-b',
    ),
  );
  final lowOpp = pairs.relate(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      confidence: 0.1,
      completeness: 0.2,
      sessionId: '5c-lowopp-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
      confidence: 0.1,
      completeness: 0.2,
      sessionId: '5c-lowopp-b',
    ),
  );

  final neuRow = neutral.forDimension('contact_need')!;
  final oppRow = opposite.forDimension('contact_need')!;
  final identRow = identical.forDimension('contact_need')!;
  final lowOppRow = lowOpp.forDimension('contact_need')!;
  final highSameRow = sameBehHigh.forDimension('contact_need')!;
  final diffSameRow = sameBehDiff.forDimension('contact_need')!;

  final analyticOk = [
    identical,
    opposite,
    neutral,
    aligned,
    opposed,
  ].every((r) {
    for (final d in r.dimensions) {
      final an = FrequencyBehaviorV2PairRelationComputer.samePoleAnalytic(
        d.xA,
        d.xB,
      );
      if ((d.samePoleExpectation - an).abs() > 1e-10) return false;
      if ((d.samePoleExpectation + d.oppositePoleExpectation - 1).abs() >
          1e-10) {
        return false;
      }
    }
    return true;
  });

  final buf = StringBuffer();
  buf.writeln('# Frequency V2 Phase 5C — Pair-relation primitives');
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'These are quantum-inspired **relation primitives**. '
    'They are **not** a compatibility score. Same pole is not compatible; '
    'opposite pole is not incompatible.',
  );
  buf.writeln('');
  buf.writeln(
    'pair_model_version: `${FrequencyBehaviorV2Contract.pairRelationVersion}`',
  );
  buf.writeln('');
  buf.writeln('## Demonstrations');
  buf.writeln('');
  buf.writeln(
    '- **neutral/neutral:** fidelity=1 but same_pole=0.5 '
    '(got fidelity=${_n(neuRow.axisFidelity)}, '
    'same_pole=${_n(neuRow.samePoleExpectation)}).',
  );
  buf.writeln(
    '- **opposite extremes:** fidelity=0 and same_pole=0 '
    '(got fidelity=${_n(oppRow.axisFidelity)}, '
    'same_pole=${_n(oppRow.samePoleExpectation)}).',
  );
  buf.writeln(
    '- **low support:** behavior relation stays unchanged, '
    'supported relation moves toward neutral '
    '(OPPOSITE_EXTREME same_pole=${_n(oppRow.samePoleExpectation)}, '
    'LOW_SUPPORT_OPPOSITES same_pole=${_n(lowOppRow.samePoleExpectation)}, '
    'supported_same=${_n(lowOppRow.supportedSamePole)}, '
    'pair_support=${_n(lowOppRow.pairSupport)}).',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln('| Check | Result |');
  buf.writeln('|---|---|');
  buf.writeln('| operator same-pole = (1+xA xB)/2 | **$analyticOk** |');
  buf.writeln(
    '| IDENTICAL same_pole=1 fidelity=1 | **${identRow.samePoleExpectation > 0.999 && identRow.axisFidelity > 0.999}** |',
  );
  buf.writeln(
    '| OPPOSITE same_pole=0 fidelity=0 | **${oppRow.samePoleExpectation.abs() < 1e-9 && oppRow.axisFidelity.abs() < 1e-9}** |',
  );
  buf.writeln(
    '| NEUTRAL fidelity=1 same_pole=0.5 | **${(neuRow.axisFidelity - 1).abs() < 1e-9 && (neuRow.samePoleExpectation - 0.5).abs() < 1e-9}** |',
  );
  buf.writeln(
    '| SAME_BEHAVIOR axis_fidelity unchanged under support change | **${(highSameRow.axisFidelity - diffSameRow.axisFidelity).abs() < 1e-12}** |',
  );
  buf.writeln(
    '| SAME_BEHAVIOR same_pole unchanged under support change | **${(highSameRow.samePoleExpectation - diffSameRow.samePoleExpectation).abs() < 1e-12}** |',
  );
  buf.writeln(
    '| SAME_BEHAVIOR supported_same shrinks with lower pair_support | **${diffSameRow.supportedSamePole < highSameRow.supportedSamePole}** |',
  );
  buf.writeln(
    '| LOW_SUPPORT_OPPOSITES supported_same nearer 0.5 | **${(lowOppRow.supportedSamePole - 0.5).abs() < (oppRow.supportedSamePole - 0.5).abs()}** |',
  );
  buf.writeln('| compatibility score emitted | **false** |');
  buf.writeln('| entanglement constructed | **false** |');
  buf.writeln('');

  void writePair(String name, FrequencyBehaviorV2PairRelationResult r) {
    buf.writeln('## $name');
    buf.writeln('');
    buf.writeln(
      '| global | value |',
    );
    buf.writeln('|---|---|');
    buf.writeln('| pure_behavior_overlap | ${_n(r.pureBehaviorOverlap!)} |');
    buf.writeln(
      '| mixed_hilbert_schmidt_overlap | ${_n(r.mixedHilbertSchmidtOverlap!)} |',
    );
    buf.writeln('');
    buf.writeln(
      '| dimension | x_A | x_B | axis_fidelity | same_pole | opposite_pole | pair_support | supported_same_pole |',
    );
    buf.writeln('|---|---|---|---|---|---|---|---|');
    for (final d in r.dimensions) {
      buf.writeln(
        '| ${d.dimensionId} | ${_n(d.xA)} | ${_n(d.xB)} | ${_n(d.axisFidelity)} | '
        '${_n(d.samePoleExpectation)} | ${_n(d.oppositePoleExpectation)} | '
        '${_n(d.pairSupport)} | ${_n(d.supportedSamePole)} |',
      );
    }
    buf.writeln('');
  }

  writePair('IDENTICAL_EXTREME', identical);
  writePair('OPPOSITE_EXTREME', opposite);
  writePair('IDENTICAL_NEUTRAL', neutral);
  writePair('MODERATE_ALIGNED', aligned);
  writePair('MODERATE_OPPOSED', opposed);
  writePair('SAME_BEHAVIOR_DIFFERENT_SUPPORT', sameBehDiff);
  writePair('LOW_SUPPORT_OPPOSITES', lowOpp);

  buf.writeln('## What this phase does not do');
  buf.writeln('');
  buf.writeln('- final compatibility score');
  buf.writeln('- similarity vs complementarity policy');
  buf.writeln('- dimension weights / matching');
  buf.writeln('- entanglement or 576×576 pair matrices');
  buf.writeln('- modify user rho, scorer, confidence, evidence, selector');
  buf.writeln('- activate V2');
  buf.writeln(
    '- touch V1 / Firebase / C2 / Discover / Persona',
  );
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 5C QUANTUM-INSPIRED PAIR RELATION PRIMITIVES READY — NO COMPATIBILITY SCORE YET — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

String _n(double v) {
  if (v.abs() < 1e-12) return '0';
  return v.toStringAsFixed(6);
}
