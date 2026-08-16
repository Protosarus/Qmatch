import 'l4_temporal_diagnostics_contract.dart';
import 'temporal_shadow_extractor_contract.dart';

/// Lightweight message metadata event (no text / questionnaire fields).
class TemporalShadowEvent {
  const TemporalShadowEvent({
    required this.timestampMs,
    required this.senderId,
  });

  /// Epoch milliseconds (`client_created_at` preferred by callers).
  final int timestampMs;
  final String senderId;
}

enum TemporalFeatureStatus {
  ok,
  sparse,
  unavailable,
}

/// Gated scalar (or null when unavailable).
class GatedDouble {
  const GatedDouble({
    required this.status,
    this.value,
  });

  final TemporalFeatureStatus status;
  final double? value;

  Map<String, dynamic> toWireMap() => {
        'status': status.name,
        if (value != null) 'value': value,
      };
}

class TemporalShadowUserFeatures {
  const TemporalShadowUserFeatures({
    required this.userId,
    required this.eventCount,
    required this.interEventIntervalsSeconds,
    required this.cadenceMeanPerSecond,
    required this.cadenceMedianPerSecond,
    required this.burstiness,
    required this.regularity,
    required this.hourHistogramStatus,
    required this.hourOfDayHistogram,
    required this.circadianThetaBar,
    required this.circadianRBar,
  });

  final String userId;
  final int eventCount;
  final List<double> interEventIntervalsSeconds;
  final GatedDouble cadenceMeanPerSecond;
  final GatedDouble cadenceMedianPerSecond;
  final GatedDouble burstiness;
  final GatedDouble regularity;

  /// Length-24 normalized histogram when available; empty if unavailable.
  final GatedDouble hourHistogramStatus;
  final List<double>? hourOfDayHistogram;

  /// Circadian 24h phase only (`oscillator_id=circadian_24h`). Not general φ_m.
  final GatedDouble circadianThetaBar;
  final GatedDouble circadianRBar;

  Map<String, dynamic> toWireMap() => {
        'user_id': userId,
        'event_count': eventCount,
        'inter_event_intervals_seconds': interEventIntervalsSeconds,
        'cadence_mean_per_second': cadenceMeanPerSecond.toWireMap(),
        'cadence_median_per_second': cadenceMedianPerSecond.toWireMap(),
        'burstiness': burstiness.toWireMap(),
        'regularity': regularity.toWireMap(),
        'hour_of_day_histogram': {
          ...hourHistogramStatus.toWireMap(),
          if (hourOfDayHistogram != null) 'bins': hourOfDayHistogram,
        },
        'circadian_24h': {
          'oscillator_id': TemporalShadowExtractorContract.circadianOscillatorId,
          'theta_bar': circadianThetaBar.toWireMap(),
          'r_bar': circadianRBar.toWireMap(),
        },
      };
}

class TemporalShadowDyadicFeatures {
  const TemporalShadowDyadicFeatures({
    required this.eventCountP,
    required this.eventCountQ,
    required this.eventCountTotal,
    required this.participationShareP,
    required this.dyadicParticipationBalance,
    required this.medianReplyGapPFromQSeconds,
    required this.medianReplyGapQFromPSeconds,
    required this.medianTurnGapSeconds,
    required this.replyGapCountPFromQ,
    required this.replyGapCountQFromP,
    required this.turnGapCount,
    required this.circadianDeltaTheta,
  });

  final int eventCountP;
  final int eventCountQ;
  final int eventCountTotal;
  final GatedDouble participationShareP;
  final GatedDouble dyadicParticipationBalance;
  final GatedDouble medianReplyGapPFromQSeconds;
  final GatedDouble medianReplyGapQFromPSeconds;
  final GatedDouble medianTurnGapSeconds;
  final int replyGapCountPFromQ;
  final int replyGapCountQFromP;
  final int turnGapCount;
  final GatedDouble circadianDeltaTheta;

  Map<String, dynamic> toWireMap() => {
        'event_count_p': eventCountP,
        'event_count_q': eventCountQ,
        'event_count_total': eventCountTotal,
        'participation_share_p': participationShareP.toWireMap(),
        'dyadic_participation_balance': dyadicParticipationBalance.toWireMap(),
        'median_reply_gap_p_from_q_seconds':
            medianReplyGapPFromQSeconds.toWireMap(),
        'median_reply_gap_q_from_p_seconds':
            medianReplyGapQFromPSeconds.toWireMap(),
        'median_turn_gap_seconds': medianTurnGapSeconds.toWireMap(),
        'reply_gap_count_p_from_q': replyGapCountPFromQ,
        'reply_gap_count_q_from_p': replyGapCountQFromP,
        'turn_gap_count': turnGapCount,
        'circadian_delta_theta': circadianDeltaTheta.toWireMap(),
      };
}

class TemporalShadowThreadResult {
  const TemporalShadowThreadResult({
    required this.participantP,
    required this.participantQ,
    required this.windowStartMs,
    required this.windowEndMs,
    required this.windowSeconds,
    required this.userP,
    required this.userQ,
    required this.dyadic,
    required this.localTimeZoneAvailable,
  });

  final String participantP;
  final String participantQ;
  final int windowStartMs;
  final int windowEndMs;
  final double windowSeconds;
  final TemporalShadowUserFeatures userP;
  final TemporalShadowUserFeatures userQ;
  final TemporalShadowDyadicFeatures dyadic;
  final bool localTimeZoneAvailable;

  static const bool gatesCalibrated =
      TemporalShadowExtractorContract.gatesCalibrated;
  static const bool shadowOnly = TemporalShadowExtractorContract.shadowOnly;
  static const String scoringVersion =
      TemporalShadowExtractorContract.scoringVersion;
  static const String policyStatus =
      TemporalShadowExtractorContract.policyStatus;

  /// Periodic omega is always unavailable in v1.
  static const TemporalFeatureStatus omegaStatus =
      TemporalFeatureStatus.unavailable;

  Map<String, dynamic> toWireMap() => {
        'scoring_version': scoringVersion,
        'policy_version': TemporalShadowExtractorContract.policyVersion,
        'policy_status': policyStatus,
        'gates_calibrated': gatesCalibrated,
        'shadow_only': shadowOnly,
        'affects_discover_ranking':
            L4TemporalDiagnosticsContract.affectsDiscoverRanking,
        'fuses_with_l2': L4TemporalDiagnosticsContract.fusesWithL2,
        'fuses_with_l3': L4TemporalDiagnosticsContract.fusesWithL3,
        'scope': L4TemporalDiagnosticsContract.scope,
        'real_cohort_exists': L4TemporalDiagnosticsContract.realCohortExists,
        'last_active_at_is_l4_signal':
            L4TemporalDiagnosticsContract.lastActiveAtIsL4Signal,
        'cadence_production_promoted':
            L4TemporalDiagnosticsContract.cadenceProductionPromoted,
        'burstiness_production_promoted':
            L4TemporalDiagnosticsContract.burstinessProductionPromoted,
        'regularity_production_promoted':
            L4TemporalDiagnosticsContract.regularityProductionPromoted,
        'reply_turn_production_promoted':
            L4TemporalDiagnosticsContract.replyTurnProductionPromoted,
        'participation_count_production_promoted':
            L4TemporalDiagnosticsContract.participationCountProductionPromoted,
        'circadian_conditional_diagnostic':
            L4TemporalDiagnosticsContract.circadianConditionalDiagnostic,
        'class_b_omega_production_promoted':
            L4TemporalDiagnosticsContract.classBOmegaProductionPromoted,
        'omega': {'status': omegaStatus.name},
        'local_timezone_available': localTimeZoneAvailable,
        'window': {
          'start_ms': windowStartMs,
          'end_ms': windowEndMs,
          'seconds': windowSeconds,
        },
        'participant_p': participantP,
        'participant_q': participantQ,
        'user_features': {
          participantP: userP.toWireMap(),
          participantQ: userQ.toWireMap(),
        },
        'dyadic_features': dyadic.toWireMap(),
      };
}
