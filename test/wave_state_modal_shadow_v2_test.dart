import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/wave_state_modal_shadow.dart';

void main() {
  const matcher = WaveStateModalShadowV2Matcher();
  final ids = WaveStateModalShadowV2Contract.frequencyDimensionIds;

  PhaseReferenceV2 circadian({
    required double phase,
    String tz = 'Europe/Istanbul',
    WavePeriodicityStatusV2 status = WavePeriodicityStatusV2.ok,
    String oscillatorId = WaveStateModalShadowV2Contract.circadianOscillatorId,
    WavePhaseTimeBasisV2 timeBasis = WavePhaseTimeBasisV2.localCivil,
    String? timezone,
  }) {
    return PhaseReferenceV2(
      oscillatorId: oscillatorId,
      phaseRadians: phase,
      phaseClass: WavePhaseClassV2.externalAnchored,
      timeBasis: timeBasis,
      periodicityStatus: status,
      periodSeconds: WaveStateModalShadowV2Contract.circadianPeriodSeconds,
      timezone: timezone ??
          (timeBasis == WavePhaseTimeBasisV2.localCivil ? tz : null),
      source: 'temporal_shadow_circadian_v1',
    );
  }

  PhaseReferenceV2 validated({
    required double phase,
    String oscillatorId = 'spectral_peak_demo',
    String epoch = '2024-01-01T00:00:00Z',
    double periodSeconds = 3600,
    WavePhaseTimeBasisV2 timeBasis = WavePhaseTimeBasisV2.utc,
    WavePeriodicityStatusV2 status = WavePeriodicityStatusV2.ok,
  }) {
    return PhaseReferenceV2(
      oscillatorId: oscillatorId,
      phaseRadians: phase,
      phaseClass: WavePhaseClassV2.validatedPeriodic,
      timeBasis: timeBasis,
      periodicityStatus: status,
      periodSeconds: periodSeconds,
      referenceEpoch: epoch,
      source: 'spectral_estimator_shadow_v1',
    );
  }

  WaveStateModalSubjectV2 subjectWithPhase(
    PhaseReferenceV2 Function(String id) phaseFor, {
    double amplitude = 0.4,
  }) {
    return WaveStateModalSubjectV2.fromModes([
      for (final id in ids)
        WaveStateModeV2(
          modeId: id,
          amplitude: amplitude,
          phase: phaseFor(id),
        ),
    ]);
  }

  group('WaveStateModalShadowV2Matcher', () {
    test('compatible circadian phases → signed r_wave + c_abs', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.2));
      final b = subjectWithPhase((_) => circadian(phase: 0.2));
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(1.0, 1e-12));
      expect(r.cAbs, closeTo(1.0, 1e-12));
      expect(r.cAbsSq, closeTo(1.0, 1e-12));
      expect(r.cAbsDiagnosticOnly, isTrue);
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.compatible);
      expect(r.scoringVersion, 'wave_state_modal_shadow_v2');
      expect(r.policyVersion, 'wave_phase_reference_policy_v1');
      expect(r.structuralDistanceCoupled, isFalse);
      expect(r.toWireMap()['c_abs_used_for_ranking'], isFalse);
      expect(r.toWireMap()['gauge_fixes_unanchored_phase'], isFalse);
    });

    test('externally anchored global phase offset remains meaningful', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.0));
      final b = subjectWithPhase((_) => circadian(phase: math.pi));
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(-1.0, 1e-12));
      expect(r.cAbs, closeTo(1.0, 1e-12));
    });

    test('incompatible oscillator IDs → signed unavailable', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.1));
      final b = subjectWithPhase(
        (_) => circadian(phase: 0.1, oscillatorId: 'weekly_7d'),
      );
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isFalse);
      expect(r.rWave, isNull);
      expect(
        r.rWaveUnavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonIncompatibleOscillator,
      );
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.incompatible);
      // Diagnostic magnitude still emitted from numeric inputs.
      expect(r.cAbs, isNotNull);
      expect(r.cAbsDiagnosticOnly, isTrue);
    });

    test('incompatible time bases → signed unavailable', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.3));
      final b = subjectWithPhase(
        (_) => circadian(
          phase: 0.3,
          timeBasis: WavePhaseTimeBasisV2.utc,
          timezone: null,
        ),
      );
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.rWaveUnavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonIncompatibleTimeBasis,
      );
    });

    test('missing provenance (no timezone on local_civil) → unavailable', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.1));
      final b = WaveStateModalSubjectV2.fromModes([
        for (final id in ids)
          WaveStateModeV2(
            modeId: id,
            amplitude: 0.4,
            phase: PhaseReferenceV2(
              oscillatorId:
                  WaveStateModalShadowV2Contract.circadianOscillatorId,
              phaseRadians: 0.1,
              phaseClass: WavePhaseClassV2.externalAnchored,
              timeBasis: WavePhaseTimeBasisV2.localCivil,
              periodicityStatus: WavePeriodicityStatusV2.ok,
              periodSeconds:
                  WaveStateModalShadowV2Contract.circadianPeriodSeconds,
              timezone: null,
              source: 'temporal_shadow_circadian_v1',
            ),
          ),
      ]);
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.rWaveUnavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonMissingProvenance,
      );
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.missingProvenance);
    });

    test('validated periodic reference → signed available when matched', () {
      final a = subjectWithPhase((_) => validated(phase: 0.5));
      final b = subjectWithPhase((_) => validated(phase: 0.5));
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(1.0, 1e-12));
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.compatible);
    });

    test('validated periodic epoch mismatch → signed unavailable', () {
      final a = subjectWithPhase((_) => validated(phase: 0.5, epoch: 'e1'));
      final b = subjectWithPhase((_) => validated(phase: 0.5, epoch: 'e2'));
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isFalse);
      expect(
        r.rWaveUnavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonIncompatibleEpoch,
      );
    });

    test('unanchored phase rejection → signed unavailable, no gauge fix', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.0));
      final b = WaveStateModalSubjectV2.fromModes([
        for (final id in ids)
          WaveStateModeV2(
            modeId: id,
            amplitude: 0.4,
            phase: PhaseReferenceV2(
              oscillatorId: 'latent_free',
              phaseRadians: math.pi,
              phaseClass: WavePhaseClassV2.unanchored,
              timeBasis: WavePhaseTimeBasisV2.utc,
              periodicityStatus: WavePeriodicityStatusV2.ok,
              omega: 1.0,
              source: 'synthetic_latent',
            ),
          ),
      ]);
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isFalse);
      expect(r.rWave, isNull);
      expect(
        r.rWaveUnavailableReason,
        WavePhaseReferenceCompatibilityV2.reasonUnanchored,
      );
      expect(r.phaseCompatibility, WavePhaseCompatibilityV2.unanchored);
      expect(r.toWireMap()['gauge_fixes_unanchored_phase'], isFalse);
      // c_abs may exist diagnostically but must not become signed resonance.
      expect(r.cAbsDiagnosticOnly, isTrue);
    });

    test('symmetry A↔B for compatible circadian', () {
      final a = subjectWithPhase(
        (id) => circadian(phase: ids.indexOf(id) * 0.1),
      );
      final b = subjectWithPhase(
        (id) => circadian(phase: ids.indexOf(id) * 0.05 + 0.2),
      );
      final ab = matcher.compare(a: a, b: b, t: 1.5);
      final ba = matcher.compare(a: b, b: a, t: 1.5);
      expect(ab.signedResonanceAvailable, isTrue);
      expect(ba.signedResonanceAvailable, isTrue);
      expect(ab.rWave, closeTo(ba.rWave!, 1e-12));
      expect(ab.cAbs, closeTo(ba.cAbs!, 1e-12));
    });

    test('c_abs diagnostics present and marked non-ranking', () {
      final a = subjectWithPhase((_) => circadian(phase: 0.0));
      final b = subjectWithPhase((_) => circadian(phase: math.pi / 2));
      final r = matcher.compare(a: a, b: b);
      expect(r.signedResonanceAvailable, isTrue);
      expect(r.rWave, closeTo(0.0, 1e-12));
      expect(r.cAbs, closeTo(1.0, 1e-12));
      expect(r.cAbsSq, closeTo(1.0, 1e-12));
      expect(r.cAbsDiagnosticOnly, isTrue);
      expect(
        WaveStateModalShadowV2Contract.cAbsUsedForRanking,
        isFalse,
      );
    });

    test('v1 remains available for compatibility', () {
      const v1 = WaveStateModalShadowMatcher();
      final a = WaveStateModalSubject.fromMaps(
        amplitudes: {for (final id in ids) id: 0.4},
        phasesRadians: {for (final id in ids) id: 0.1},
        omegas: {for (final id in ids) id: 1.0},
      );
      final r = v1.compare(a: a, b: a);
      expect(r.resonanceAvailable, isTrue);
      expect(r.scoringVersion, 'wave_state_modal_shadow_v1');
    });

    test('no Discover coupling in v2 sources', () {
      final paths = [
        'lib/features/matching/domain/wave_state_modal_shadow_v2.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_v2_contract.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_v2_models.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_v2_compatibility.dart',
        'lib/features/matching/domain/wave_state_modal_shadow_v2_matcher.dart',
      ];
      for (final path in paths) {
        final src = File(path).readAsStringSync();
        expect(src, isNot(contains('features/discover')), reason: path);
        expect(src, isNot(contains('DiscoverService')), reason: path);
        expect(src, isNot(contains('CompatibilityScoring')), reason: path);
      }
      final discover =
          File('lib/features/discover/services/discover_service.dart')
              .readAsStringSync();
      expect(discover, isNot(contains('wave_state_modal_shadow_v2')));
    });
  });
}
