import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/periodic_wave_state_resonance.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_amplitude_semantics.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_contract.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

void main() {
  const resonance = GlobalActivityPeriodicResonance();
  const multimodeGate = WaveStateMultimodeRealUserGate();

  ActivitySpectralOmegaEstimate okOmega({
    required String oscillatorId,
    required double periodSeconds,
  }) {
    final omega = 2 * math.pi / periodSeconds;
    return ActivitySpectralOmegaEstimate(
      status: ActivitySpectralOmegaStatus.ok,
      reason: null,
      eventCount: 60,
      windowSeconds: 21 * 86400.0,
      binWidthSeconds: 3600,
      periodSeconds: periodSeconds,
      omega: omega,
      snr: 100,
      splitHalfRelativeDelta: 0.0,
      binSensitivityRelativeDelta: 0.0,
      nearCivilCollision: false,
      civilCollisionKind: null,
      candidatePeaks: const [],
      oscillatorId: oscillatorId,
    );
  }

  ValidatedPeriodicPhaseEstimate okPhase({
    required String oscillatorId,
    required double periodSeconds,
    required double phaseRadians,
    String epoch = '2024-01-01T00:00:00.000Z',
  }) {
    final omega = 2 * math.pi / periodSeconds;
    return ValidatedPeriodicPhaseEstimate(
      available: true,
      unavailableReason: null,
      eventCount: 60,
      thetaBar: phaseRadians,
      rBar: 0.95,
      periodSeconds: periodSeconds,
      omega: omega,
      oscillatorId: oscillatorId,
      referenceEpoch: epoch,
      referenceEpochMs: 1704067200000,
      phaseReference: PhaseReferenceV2(
        oscillatorId: oscillatorId,
        phaseRadians: phaseRadians,
        phaseClass: WavePhaseClassV2.validatedPeriodic,
        timeBasis: WavePhaseTimeBasisV2.utc,
        periodicityStatus: WavePeriodicityStatusV2.ok,
        periodSeconds: periodSeconds,
        omega: omega,
        referenceEpoch: epoch,
        source: ValidatedPeriodicPhaseBinderContract.sourceId,
      ),
      omegaStatus: ActivitySpectralOmegaStatus.ok,
    );
  }

  group('GlobalActivityPeriodicResonance (Tier 1)', () {
    test('scalar phase alignment = cos(delta_phi)', () {
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      for (final dPhi in [0.0, 0.3, math.pi / 2, math.pi, -1.1]) {
        final r = resonance.compare(
          omegaA: omega,
          phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
          activityLevelA: 1.0,
          omegaB: omega,
          phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: dPhi),
          activityLevelB: 1.0,
        );
        expect(r.available, isTrue);
        expect(r.phaseAlignment, closeTo(math.cos(dPhi), 1e-12));
        expect(r.toWireMap()['fuses_activity_into_phase_alignment'], isFalse);
      }
    });

    test('amplitude magnitude does not alter phase alignment', () {
      const osc = 'activity_spectral_global_activity_t28800s';
      const T = 28800.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      const dPhi = 0.75;
      final low = resonance.compare(
        omegaA: omega,
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        activityLevelA: 0.1,
        omegaB: omega,
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: dPhi),
        activityLevelB: 0.2,
      );
      final high = resonance.compare(
        omegaA: omega,
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        activityLevelA: 9.0,
        omegaB: omega,
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: dPhi),
        activityLevelB: 12.0,
      );
      expect(low.available && high.available, isTrue);
      expect(low.phaseAlignment, closeTo(math.cos(dPhi), 1e-12));
      expect(high.phaseAlignment, closeTo(low.phaseAlignment!, 1e-12));
      expect(low.activityLevelA, 0.1);
      expect(high.activityLevelA, 9.0);
    });

    test('level gap remains separate from phase alignment', () {
      const osc = 'activity_spectral_global_activity_t36000s';
      const T = 36000.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      final r = resonance.compare(
        omegaA: omega,
        phaseA: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        activityLevelA: 2.0,
        omegaB: omega,
        phaseB: okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0),
        activityLevelB: 5.0,
      );
      expect(r.available, isTrue);
      expect(r.phaseAlignment, closeTo(1.0, 1e-12));
      expect(r.activityLevelA, 2.0);
      expect(r.activityLevelB, 5.0);
      expect(r.activityLevelGap, 3.0);
      // Not fused: product would be 2*5*1=10; we return cos only.
      expect(r.phaseAlignment, isNot(10.0));
      final wire = r.toWireMap();
      expect(wire.containsKey('phase_alignment'), isTrue);
      expect(wire.containsKey('activity_level_gap'), isTrue);
      expect(wire['phase_alignment'], isNot(wire['activity_level_gap']));
    });
  });

  group('Multi-mode real-user gate (Tier 2)', () {
    test('multi-mode real-user path unavailable without mode-specific oscillators', () {
      final gated = multimodeGate.evaluate(
        hasModeSpecificOscillatorsForAllModes: false,
      );
      expect(gated.available, isFalse);
      expect(
        gated.reason,
        WaveStateAmplitudeSemanticsContract.reasonMultimodeRealUserUnavailable,
      );
      expect(
        WaveStateAmplitudeSemanticsContract.tier2RealUserResonanceEnabled,
        isFalse,
      );
      expect(
        WaveStateModalShadowV2Contract.realUserMultimodeResonanceEnabled,
        isFalse,
      );
      expect(
        WaveStateModalShadowV2Contract.multimodeRealUserStatus,
        'research_only_unavailable',
      );
    });

    test('copying global activity phase into Frequency modes is forbidden', () {
      final r = multimodeGate.evaluate(
        hasModeSpecificOscillatorsForAllModes: true,
        copiesGlobalActivityPhaseIntoFrequencyModes: true,
      );
      expect(r.available, isFalse);
      expect(
        r.reason,
        WaveStateAmplitudeSemanticsContract.reasonCopiesGlobalPhaseForbidden,
      );
      expect(
        WaveStateAmplitudeSemanticsContract.tier2MayCopyGlobalPhaseToFrequencyModes,
        isFalse,
      );
    });

    test('c_abs is not called resonance', () {
      expect(WaveStateAmplitudeSemanticsContract.cAbsIsResonance, isFalse);
      expect(
        WaveStateAmplitudeSemanticsContract.cAbsIsAmplitudeEnvelopeDiagnosticOnly,
        isTrue,
      );
      expect(WaveStateModalShadowV2Contract.cAbsIsResonance, isFalse);
      expect(
        PeriodicWaveStateResonanceAdapterContract.researchEnvelopeDiagnosticOnly,
        isTrue,
      );
      expect(
        PeriodicWaveStateResonanceAdapterContract.realUserUsablePath,
        isFalse,
      );
    });
  });

  group('contract isolation', () {
    test('no Discover / Persona / Frequency attach on tier-1 sources', () {
      expect(WaveStateAmplitudeSemanticsContract.liveDiscoverRanking, isFalse);
      expect(WaveStateAmplitudeSemanticsContract.personaEnabled, isFalse);
      expect(
        WaveStateAmplitudeSemanticsContract.tier1AttachesToFrequencyModes,
        isFalse,
      );
      final paths = [
        'lib/features/matching/domain/global_activity_periodic_resonance.dart',
        'lib/features/matching/domain/wave_state_amplitude_semantics_contract.dart',
        'lib/features/matching/domain/wave_state_multimode_real_user_gate.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('depth_preference')), reason: path);
      }
    });
  });
}
