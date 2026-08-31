// ignore_for_file: avoid_print
/// Phase 5D provisional relationship-fit audit.
///
/// Does not wire live matching. Does not claim scientific validation.
///
/// Usage:
///   dart run tool/frequency_behavior_v2/simulate_phase5d_pair_fit.dart
library;

import 'dart:io';

import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

void main(List<String> args) {
  var outPath = FrequencyBehaviorV2Contract.phase5dPairFitAuditRelativePath;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) outPath = args[++i];
  }

  const encoder = FrequencyBehaviorV2SignedPoleEncoder();
  const mixer = FrequencyBehaviorV2MixedDensityMixer();
  const fitComputer = FrequencyBehaviorV2PairFitComputer();

  FrequencyBehaviorV2MixedStateResult user({
    required Map<String, double> x,
    required double confidence,
    double completeness = 1,
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

  final identicalHigh = fitComputer.fitFromUsers(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 1,
      sessionId: '5d-ident-h-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 1,
      sessionId: '5d-ident-h-b',
    ),
  );
  final identicalLow = fitComputer.fitFromUsers(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 0.15,
      completeness: 0.4,
      sessionId: '5d-ident-l-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 0.15,
      completeness: 0.4,
      sessionId: '5d-ident-l-b',
    ),
  );
  final oppositeHigh = fitComputer.fitFromUsers(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(1),
      confidence: 1,
      sessionId: '5d-opp-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-1),
      confidence: 1,
      sessionId: '5d-opp-b',
    ),
  );
  final moderate = fitComputer.fitFromUsers(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.25),
      confidence: 1,
      sessionId: '5d-mod-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(-0.25),
      confidence: 1,
      sessionId: '5d-mod-b',
    ),
  );
  final mixed = fitComputer.fitFromUsers(
    user(x: mixedX, confidence: 0.85, sessionId: '5d-mix-a'),
    user(x: mixedX, confidence: 0.85, sessionId: '5d-mix-b'),
  );
  final sameBehDiff = fitComputer.fitFromUsers(
    user(x: mixedX, confidence: 1, sessionId: '5d-sbd-a'),
    user(x: mixedX, confidence: 0.2, completeness: 0.5, sessionId: '5d-sbd-b'),
  );

  final identicalZero = fitComputer.fitFromUsers(
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 0,
      sessionId: '5d-ident-z-a',
    ),
    user(
      x: FrequencyBehaviorV2SignedPoleEncoder.uniformBehavior(0.7),
      confidence: 0,
      sessionId: '5d-ident-z-b',
    ),
  );

  final modLinear = moderate.forDimension('contact_need')!;
  final modTolerant = moderate.forDimension('initiative')!;

  final buf = StringBuffer();
  buf.writeln('# Frequency V2 Phase 5D — Provisional relationship fit');
  buf.writeln('');
  buf.writeln(
    'Status: **offline / dormant**. `runtime_selectable` remains false.',
  );
  buf.writeln(
    'Provisional **Frequency Fit** index. Not relationship success probability, '
    'soulmate scoring, or scientifically validated prediction.',
  );
  buf.writeln('');
  buf.writeln(
    'pair_fit_policy_version: `${FrequencyBehaviorV2Contract.pairFitPolicyVersion}`',
  );
  buf.writeln(
    'pair_fit_version: `${FrequencyBehaviorV2Contract.pairFitVersion}`',
  );
  buf.writeln('');
  buf.writeln('## Demonstrations');
  buf.writeln('');
  buf.writeln(
    '- **support shrinks toward 50:** IDENTICAL_HIGH index '
    '${_n(identicalHigh.frequencyFitIndex!)} vs IDENTICAL_LOW '
    '${_n(identicalLow.frequencyFitIndex!)} (raw fit both '
    '${_n(identicalHigh.overallRawFit!)}).',
  );
  buf.writeln(
    '- **tolerant vs linear at delta=0.5:** contact_need linear raw '
    '${_n(FrequencyBehaviorV2PairFitComputer.rawFitForPolicy(delta: 0.5, policyType: FrequencyBehaviorV2Contract.pairFitPolicySimilarityLinear))} '
    'vs initiative tolerant '
    '${_n(FrequencyBehaviorV2PairFitComputer.rawFitForPolicy(delta: 0.5, policyType: FrequencyBehaviorV2Contract.pairFitPolicySimilarityTolerant))}.',
  );
  buf.writeln(
    '- **no opposition reward:** OPPOSITE_HIGH raw fit '
    '${_n(oppositeHigh.overallRawFit!)} (index '
    '${_n(oppositeHigh.frequencyFitIndex!)}).',
  );
  buf.writeln(
    '- **density overlap not in score:** fit uses behavior + pair_support only; '
    'pure/mixed overlaps are diagnostic elsewhere.',
  );
  buf.writeln('');
  buf.writeln('## Invariants');
  buf.writeln('');
  buf.writeln('| Check | Result |');
  buf.writeln('|---|---|');
  buf.writeln(
    '| IDENTICAL_HIGH index ≈ 100 | **${(identicalHigh.frequencyFitIndex! - 100).abs() < 1e-6}** |',
  );
  buf.writeln(
    '| IDENTICAL zero-support index = 50 | **${(identicalZero.frequencyFitIndex! - 50).abs() < 1e-6}** |',
  );
  buf.writeln(
    '| IDENTICAL low-support index < 100 | **${identicalLow.frequencyFitIndex! < 100}** |',
  );
  buf.writeln(
    '| OPPOSITE_HIGH raw fit = 0 | **${oppositeHigh.overallRawFit!.abs() < 1e-9}** |',
  );
  buf.writeln(
    '| MODERATE tolerant raw > linear raw | **${modTolerant.rawFit > modLinear.rawFit}** |',
  );
  buf.writeln(
    '| SAME_BEHAVIOR raw fit unchanged under support | **${(mixed.overallRawFit! - sameBehDiff.overallRawFit!).abs() < 1e-12}** |',
  );
  buf.writeln(
    '| SAME_BEHAVIOR supported fit lower with low support | **${sameBehDiff.overallSupportedFit! < mixed.overallSupportedFit!}** |',
  );
  buf.writeln('| complementarity bonus | **false** |');
  buf.writeln('| live matching wired | **false** |');
  buf.writeln('');

  void writePair(String name, FrequencyBehaviorV2PairFitResult r) {
    buf.writeln('## $name');
    buf.writeln('');
    buf.writeln('| global | value |');
    buf.writeln('|---|---|');
    buf.writeln('| overall_raw_fit | ${_n(r.overallRawFit!)} |');
    buf.writeln('| overall_supported_fit | ${_n(r.overallSupportedFit!)} |');
    buf.writeln('| frequency_fit_index | ${_n(r.frequencyFitIndex!)} |');
    buf.writeln('| overall_pair_support | ${_n(r.overallPairSupport!)} |');
    buf.writeln(
      '| top_alignment | ${r.topAlignmentDimensions.join(', ')} |',
    );
    buf.writeln('| top_gap | ${r.topGapDimensions.join(', ')} |');
    buf.writeln('');
    buf.writeln(
      '| dimension | policy | x_A | x_B | delta | raw_fit | pair_support | supported_fit |',
    );
    buf.writeln('|---|---|---|---|---|---|---|---|');
    for (final d in r.dimensions) {
      buf.writeln(
        '| ${d.dimensionId} | ${d.policyType} | ${_n(d.xA)} | ${_n(d.xB)} | '
        '${_n(d.delta)} | ${_n(d.rawFit)} | ${_n(d.pairSupport)} | '
        '${_n(d.supportedFit)} |',
      );
    }
    buf.writeln('');
  }

  writePair('IDENTICAL_HIGH_SUPPORT', identicalHigh);
  writePair('IDENTICAL_LOW_SUPPORT', identicalLow);
  writePair('OPPOSITE_HIGH_SUPPORT', oppositeHigh);
  writePair('MODERATE_DIFFERENCE', moderate);
  writePair('MIXED_REALISTIC_PAIR', mixed);
  writePair('SAME_BEHAVIOR_DIFFERENT_SUPPORT', sameBehDiff);

  buf.writeln('## Policy note');
  buf.writeln('');
  buf.writeln(
    'All policy assignments and curves are **PROVISIONAL** and **UNCALIBRATED**. '
    'Future telemetry may create `frequency_pair_fit_policy_v2`.',
  );
  buf.writeln('');
  buf.writeln('## What this phase does not do');
  buf.writeln('');
  buf.writeln('- wire into live matching');
  buf.writeln('- complementarity bonus or asymmetric need/supply');
  buf.writeln('- learned weights without data');
  buf.writeln('- use density overlap as final score');
  buf.writeln('- activate V2');
  buf.writeln(
    '- touch V1 / Firebase / C2 / Discover / Persona',
  );
  buf.writeln('');
  buf.writeln(
    'FREQUENCY V2 PHASE 5D PROVISIONAL RELATIONSHIP FIT MODEL READY — NO LIVE MATCHING — V2 STILL DORMANT',
  );

  File(outPath).writeAsStringSync(buf.toString());
  stdout.writeln(buf.toString().trimRight());
  stdout.writeln('wrote $outPath');
}

String _n(double v) {
  if (v.abs() < 1e-12) return '0';
  return v.toStringAsFixed(6);
}
