import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/domain/activity_spectral_omega.dart';
import 'package:qmatch/features/matching/domain/circadian_activity_phase.dart';
import 'package:qmatch/features/matching/domain/l4_temporal_diagnostics_contract.dart';
import 'package:qmatch/features/matching/domain/temporal_shadow.dart';
import 'package:qmatch/features/matching/domain/validated_periodic_phase.dart';
import 'package:qmatch/features/matching/domain/wave_state_amplitude_semantics.dart';

void main() {
  group('L4 v1 production freeze', () {
    test('non-ranking, no fusion, no imputation, no real cohort', () {
      expect(
        L4TemporalDiagnosticsContract.policyStatus,
        'production_diagnostics_non_ranking_v1',
      );
      expect(L4TemporalDiagnosticsContract.affectsDiscoverRanking, isFalse);
      expect(L4TemporalDiagnosticsContract.fusesWithL2, isFalse);
      expect(L4TemporalDiagnosticsContract.fusesWithL3, isFalse);
      expect(L4TemporalDiagnosticsContract.gatesCalibrated, isFalse);
      expect(L4TemporalDiagnosticsContract.realCohortExists, isFalse);
      expect(L4TemporalDiagnosticsContract.lastActiveAtIsL4Signal, isFalse);
      expect(L4TemporalDiagnosticsContract.preMatchInferenceAllowed, isFalse);
      expect(
        L4TemporalDiagnosticsContract.questionnairePhaseOmegaAllowed,
        isFalse,
      );
      expect(L4TemporalDiagnosticsContract.imputationAllowed, isFalse);
      expect(L4TemporalDiagnosticsContract.scope, 'post_match_thread_metadata');
    });

    test('production vs conditional vs research promotion flags', () {
      expect(L4TemporalDiagnosticsContract.cadenceProductionPromoted, isTrue);
      expect(L4TemporalDiagnosticsContract.burstinessProductionPromoted, isTrue);
      expect(L4TemporalDiagnosticsContract.regularityProductionPromoted, isTrue);
      expect(L4TemporalDiagnosticsContract.replyTurnProductionPromoted, isTrue);
      expect(
        L4TemporalDiagnosticsContract.participationCountProductionPromoted,
        isTrue,
      );
      expect(
        L4TemporalDiagnosticsContract.circadianConditionalDiagnostic,
        isTrue,
      );
      expect(
        L4TemporalDiagnosticsContract.circadianUnconditionalProductionPromoted,
        isFalse,
      );
      expect(
        L4TemporalDiagnosticsContract.classBOmegaProductionPromoted,
        isFalse,
      );
      expect(
        L4TemporalDiagnosticsContract.periodicPhaseProductionPromoted,
        isFalse,
      );
      expect(
        L4TemporalDiagnosticsContract.phaseAlignmentProductionPromoted,
        isFalse,
      );
      expect(
        L4TemporalDiagnosticsContract.activityAmplitudeProductionPromoted,
        isFalse,
      );
      expect(
        L4TemporalDiagnosticsContract
            .globalActivityOscillatorComparisonProductionPromoted,
        isFalse,
      );
    });

    test('extractor wire map carries L4 v1 freeze flags', () {
      const extractor = TemporalShadowExtractor();
      final r = extractor.extractThread(
        participantP: 'p',
        participantQ: 'q',
        events: const [
          TemporalShadowEvent(timestampMs: 1000, senderId: 'p'),
          TemporalShadowEvent(timestampMs: 2000, senderId: 'q'),
        ],
        windowStart: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        windowEnd: DateTime.fromMillisecondsSinceEpoch(
          const Duration(days: 2).inMilliseconds,
          isUtc: true,
        ),
      );
      final wire = r.toWireMap();
      expect(wire['policy_status'], 'production_diagnostics_non_ranking_v1');
      expect(wire['affects_discover_ranking'], isFalse);
      expect(wire['fuses_with_l2'], isFalse);
      expect(wire['fuses_with_l3'], isFalse);
      expect(wire['gates_calibrated'], isFalse);
      expect(wire['real_cohort_exists'], isFalse);
      expect(wire['last_active_at_is_l4_signal'], isFalse);
      expect(wire['cadence_production_promoted'], isTrue);
      expect(wire['class_b_omega_production_promoted'], isFalse);
      expect(wire['omega'], {'status': 'unavailable'});
      expect(wire['circadian_conditional_diagnostic'], isTrue);
    });

    test('research-shadow estimators are not production-promoted', () {
      expect(ActivitySpectralOmegaEstimatorContract.productionPromoted, isFalse);
      expect(ActivitySpectralOmegaEstimatorContract.l4V1Role, 'research_shadow');
      expect(ValidatedPeriodicPhaseBinderContract.productionPromoted, isFalse);
      expect(
        WaveStateAmplitudeSemanticsContract.tier1L4ProductionPromoted,
        isFalse,
      );
      expect(
        CircadianActivityPhaseEstimatorContract.conditionalDiagnostic,
        isTrue,
      );
      expect(CircadianActivityPhaseEstimatorContract.productionPromoted, isFalse);
    });

    test('Discover isolation — no L4 ranker coupling', () {
      final discover = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(discover.contains('TemporalShadowExtractor'), isFalse);
      expect(discover.contains('L4TemporalDiagnosticsContract'), isFalse);
      expect(discover.contains('ActivitySpectralOmegaEstimator'), isFalse);
      expect(discover.contains('GlobalActivityPeriodicResonance'), isFalse);

      final extractor = File(
        'lib/features/matching/domain/temporal_shadow_extractor.dart',
      ).readAsStringSync();
      expect(extractor.contains('last_active_at'), isFalse);
      expect(extractor.contains('lastActiveAt'), isFalse);
      expect(extractor.contains('measuredScores'), isFalse);
    });
  });
}
