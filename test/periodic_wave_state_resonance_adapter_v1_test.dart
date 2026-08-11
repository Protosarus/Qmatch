import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/periodic_wave_state_resonance.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_compatibility.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow_v2_models.dart';

void main() {
  const adapter = PeriodicWaveStateResonanceAdapter();

  ActivitySpectralOmegaEstimate okOmega({
    required String oscillatorId,
    required double periodSeconds,
    ActivitySpectralOmegaStatus status = ActivitySpectralOmegaStatus.ok,
    String? reason,
  }) {
    final omega = 2 * math.pi / periodSeconds;
    return ActivitySpectralOmegaEstimate(
      status: status,
      reason: reason,
      eventCount: 60,
      windowSeconds: 21 * 86400,
      binWidthSeconds: 3600,
      periodSeconds: periodSeconds,
      omega: status == ActivitySpectralOmegaStatus.ok ? omega : null,
      snr: 100,
      splitHalfRelativeDelta: 0.0,
      binSensitivityRelativeDelta: 0.0,
      nearCivilCollision: status == ActivitySpectralOmegaStatus.civilCollision,
      civilCollisionKind:
          status == ActivitySpectralOmegaStatus.civilCollision ? 'near_24h' : null,
      candidatePeaks: const [],
      oscillatorId:
          status == ActivitySpectralOmegaStatus.ok ? oscillatorId : oscillatorId,
    );
  }

  ValidatedPeriodicPhaseEstimate okPhase({
    required String oscillatorId,
    required double periodSeconds,
    required double phaseRadians,
    String epoch = '2024-01-01T00:00:00.000Z',
    ActivitySpectralOmegaStatus omegaStatus = ActivitySpectralOmegaStatus.ok,
    bool available = true,
    String? unavailableReason,
  }) {
    final omega = 2 * math.pi / periodSeconds;
    final pref = available
        ? PhaseReferenceV2(
            oscillatorId: oscillatorId,
            phaseRadians: phaseRadians,
            phaseClass: WavePhaseClassV2.validatedPeriodic,
            timeBasis: WavePhaseTimeBasisV2.utc,
            periodicityStatus: WavePeriodicityStatusV2.ok,
            periodSeconds: periodSeconds,
            omega: omega,
            referenceEpoch: epoch,
            source: ValidatedPeriodicPhaseBinderContract.sourceId,
          )
        : null;
    return ValidatedPeriodicPhaseEstimate(
      available: available,
      unavailableReason: unavailableReason,
      eventCount: 60,
      thetaBar: available ? phaseRadians : null,
      rBar: available ? 0.95 : null,
      periodSeconds: periodSeconds,
      omega: available ? omega : null,
      oscillatorId: oscillatorId,
      referenceEpoch: available ? epoch : null,
      referenceEpochMs: available ? 1704067200000 : null,
      phaseReference: pref,
      omegaStatus: omegaStatus,
    );
  }

  group('PeriodicWaveStateResonanceAdapter', () {
    test('identical oscillator/state → r_wave = 1', () {
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final oa = okOmega(oscillatorId: osc, periodSeconds: T);
      final pa = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.3);
      final r = adapter.compare(
        omegaA: oa,
        phaseA: pa,
        modalAmplitudesA: const [0.4, 0.5, 0.3],
        omegaB: oa,
        phaseB: pa,
        modalAmplitudesB: const [0.4, 0.5, 0.3],
      );
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(1.0, 1e-12));
      expect(r.cAbs, closeTo(1.0, 1e-12));
      expect(r.cAbsSq, closeTo(1.0, 1e-12));
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.compatible);
      expect(r.oscillatorId, osc);
      expect(r.toWireMap()['shadow_only'], isTrue);
      expect(r.toWireMap()['gates_calibrated'], isFalse);
      expect(r.toWireMap()['attaches_to_frequency_modes'], isFalse);
      expect(r.toWireMap()['structural_distance_coupled'], isFalse);
      expect(r.toWireMap()['c_abs_used_for_ranking'], isFalse);
    });

    test('same period different phase → signed opposition / quadrature', () {
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      final a = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.0);
      final b = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: math.pi);
      final r = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [1.0],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [1.0],
      );
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(-1.0, 1e-12));
      expect(r.cAbs, closeTo(1.0, 1e-12));

      final q = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [1.0],
        omegaB: omega,
        phaseB: okPhase(
          oscillatorId: osc,
          periodSeconds: T,
          phaseRadians: math.pi / 2,
        ),
        modalAmplitudesB: const [1.0],
      );
      expect(q.rWave!.abs(), lessThan(1e-12));
      expect(q.cAbs, closeTo(1.0, 1e-12));
    });

    test('same phase different valid omega → unavailable (incompatible period)', () {
      final a = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: 36000,
      );
      final b = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
      );
      final pa = okPhase(
        oscillatorId: a.oscillatorId!,
        periodSeconds: 36000,
        phaseRadians: 0.2,
      );
      final pb = okPhase(
        oscillatorId: b.oscillatorId!,
        periodSeconds: 43200,
        phaseRadians: 0.2,
      );
      final r = adapter.compare(
        omegaA: a,
        phaseA: pa,
        modalAmplitudesA: const [0.5],
        omegaB: b,
        phaseB: pb,
        modalAmplitudesB: const [0.5],
      );
      expect(r.signedResonanceAvailable, isFalse);
      expect(r.rWave, isNull);
      expect(
        r.unavailableReason,
        anyOf(
          WavePhaseReferenceCompatibilityV2.reasonIncompatibleOscillator,
          WavePhaseReferenceCompatibilityV2.reasonIncompatiblePeriod,
        ),
      );
    });

    test('periodic relative phase is time-invariant when Δω = 0', () {
      const osc = 'activity_spectral_global_activity_t28800s';
      const T = 28800.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      final a = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.4);
      final b = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 1.1);
      final r0 = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [0.7, 0.2],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [0.7, 0.2],
        t: 0,
      );
      final r1 = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [0.7, 0.2],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [0.7, 0.2],
        t: T / 4,
      );
      final r2 = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [0.7, 0.2],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [0.7, 0.2],
        t: T / 2,
      );
      expect(r0.signedResonanceAvailable, isTrue);
      expect(r1.rWave, closeTo(r0.rWave!, 1e-12));
      expect(r2.rWave, closeTo(r0.rWave!, 1e-12));
      expect(r0.rWave, closeTo(math.cos(0.4 - 1.1), 1e-12));
    });

    test('provenance mismatch (phase osc ≠ omega osc) → unavailable', () {
      final omega = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
      );
      final phase = okPhase(
        oscillatorId: 'activity_spectral_global_activity_t36000s',
        periodSeconds: 43200,
        phaseRadians: 0.1,
      );
      final other = okPhase(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
        phaseRadians: 0.1,
      );
      final r = adapter.compare(
        omegaA: omega,
        phaseA: phase,
        modalAmplitudesA: const [1.0],
        omegaB: omega,
        phaseB: other,
        modalAmplitudesB: const [1.0],
      );
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.unavailableReason,
        PeriodicWaveStateResonanceAdapterContract.reasonProvenanceMismatch,
      );
      expect(r.rWave, isNull);
      expect(r.cAbs, isNull);
    });

    test('rejected omega → unavailable', () {
      final bad = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
        status: ActivitySpectralOmegaStatus.ambiguous,
        reason: 'multiple_competing_peaks',
      );
      final good = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
      );
      final phase = okPhase(
        oscillatorId: good.oscillatorId!,
        periodSeconds: 43200,
        phaseRadians: 0.0,
      );
      final r = adapter.compare(
        omegaA: bad,
        phaseA: phase,
        modalAmplitudesA: const [1.0],
        omegaB: good,
        phaseB: phase,
        modalAmplitudesB: const [1.0],
      );
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.unavailableReason,
        PeriodicWaveStateResonanceAdapterContract.reasonOmegaAmbiguous,
      );
    });

    test('civil collision → unavailable', () {
      final civil = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t86400s',
        periodSeconds: 86400,
        status: ActivitySpectralOmegaStatus.civilCollision,
        reason: 'civil_collision',
      );
      final phase = ValidatedPeriodicPhaseEstimate(
        available: false,
        unavailableReason: ValidatedPeriodicPhaseBinderContract.reasonCivilCollision,
        eventCount: 40,
        thetaBar: null,
        rBar: null,
        periodSeconds: 86400,
        omega: null,
        oscillatorId: null,
        referenceEpoch: null,
        referenceEpochMs: null,
        phaseReference: null,
        omegaStatus: ActivitySpectralOmegaStatus.civilCollision,
      );
      final good = okOmega(
        oscillatorId: 'activity_spectral_global_activity_t43200s',
        periodSeconds: 43200,
      );
      final goodPhase = okPhase(
        oscillatorId: good.oscillatorId!,
        periodSeconds: 43200,
        phaseRadians: 0.0,
      );
      final r = adapter.compare(
        omegaA: civil,
        phaseA: phase,
        modalAmplitudesA: const [1.0],
        omegaB: good,
        phaseB: goodPhase,
        modalAmplitudesB: const [1.0],
      );
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.unavailableReason,
        PeriodicWaveStateResonanceAdapterContract.reasonCivilCollision,
      );
      expect(r.rWave, isNull);
    });

    test('symmetry: compare(A,B) == compare(B,A) for r_wave cosine', () {
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      final a = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 0.2);
      final b = okPhase(oscillatorId: osc, periodSeconds: T, phaseRadians: 1.5);
      final ab = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [0.3, 0.6],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [0.3, 0.6],
      );
      final ba = adapter.compare(
        omegaA: omega,
        phaseA: b,
        modalAmplitudesA: const [0.3, 0.6],
        omegaB: omega,
        phaseB: a,
        modalAmplitudesB: const [0.3, 0.6],
      );
      expect(ab.signedResonanceAvailable && ba.signedResonanceAvailable, isTrue);
      // cos is even in Δφ; signed r_wave is symmetric under A↔B.
      expect(ab.rWave, closeTo(ba.rWave!, 1e-12));
      expect(ab.cAbs, closeTo(ba.cAbs!, 1e-12));
    });

    test('incompatible reference epoch → unavailable', () {
      const osc = 'activity_spectral_global_activity_t43200s';
      const T = 43200.0;
      final omega = okOmega(oscillatorId: osc, periodSeconds: T);
      final a = okPhase(
        oscillatorId: osc,
        periodSeconds: T,
        phaseRadians: 0.1,
        epoch: '2024-01-01T00:00:00.000Z',
      );
      final b = okPhase(
        oscillatorId: osc,
        periodSeconds: T,
        phaseRadians: 0.1,
        epoch: '2024-06-01T00:00:00.000Z',
      );
      final r = adapter.compare(
        omegaA: omega,
        phaseA: a,
        modalAmplitudesA: const [1.0],
        omegaB: omega,
        phaseB: b,
        modalAmplitudesB: const [1.0],
      );
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.unavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonIncompatibleEpoch,
      );
    });

    test('contract freezes no Discover / Frequency attach / Persona', () {
      expect(
        PeriodicWaveStateResonanceAdapterContract.attachesToFrequencyModes,
        isFalse,
      );
      expect(
        PeriodicWaveStateResonanceAdapterContract.liveDiscoverRanking,
        isFalse,
      );
      expect(PeriodicWaveStateResonanceAdapterContract.personaEnabled, isFalse);
      expect(PeriodicWaveStateResonanceAdapterContract.rviEnabled, isFalse);
      expect(
        PeriodicWaveStateResonanceAdapterContract.densityMatrixEnabled,
        isFalse,
      );
      expect(PeriodicWaveStateResonanceAdapterContract.gatesCalibrated, isFalse);
      final paths = [
        'lib/features/matching/domain/periodic_wave_state_resonance_adapter.dart',
        'lib/features/matching/domain/periodic_wave_state_resonance_adapter_contract.dart',
        'lib/features/matching/domain/periodic_wave_state_resonance_adapter_models.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('depth_preference')), reason: path);
        expect(src, isNot(contains('WaveStateModeV2')), reason: path);
      }
    });
  });
}
