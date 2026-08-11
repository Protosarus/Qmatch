import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Shadow-only wave-state model v2 (phase-reference policy aware).
///
/// New shadow candidate beside v1. No Discover ranking/UI, Persona, RVI,
/// density-matrix/fidelity, questionnaire φ/ω, or gauge-fixing of unanchored phase.
class WaveStateModalShadowV2Contract {
  WaveStateModalShadowV2Contract._();

  static const String scoringVersion = 'wave_state_modal_shadow_v2';
  static const String policyVersion = 'wave_phase_reference_policy_v1';
  static const String policyStatus = 'shadow_only_not_live';
  static const String registryVersion = QmatchProfileContract.registryVersion;

  static const bool shadowOnly = true;
  static const bool shadowCandidate = true;
  static const bool liveDiscoverRanking = false;
  static const bool structuralDistanceCoupled = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
  static const bool densityMatrixEnabled = false;
  static const bool fabricatesMissingPhase = false;
  static const bool fabricatesMissingOmega = false;
  static const bool gaugeFixesUnanchoredPhase = false;
  static const bool cAbsUsedForRanking = false;

  /// Signed overlap requires periodicity status `ok` (sparse not enough).
  static const bool signedRequiresPeriodicityOk = true;

  static const List<String> frequencyDimensionIds =
      QmatchProfileTaxonomy.frequency;

  static const int registryModeCount = 6;
  static const double defaultStringLength = 1.0;

  static const String circadianOscillatorId = 'circadian_24h';
  static const double circadianPeriodSeconds = 86400.0;

  /// Relative tolerance for pairwise ω / period equality.
  static const double omegaRelativeTolerance = 1e-9;

  static const String forbiddenPhaseSourceQuestionnaire = 'questionnaire';

  static int? harmonicIndex(String modeId) {
    final i = frequencyDimensionIds.indexOf(modeId);
    if (i < 0) return null;
    return i + 1;
  }
}
