import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Shadow-only string-inspired modal wave-state model (v1).
///
/// Mathematical infrastructure only. No Discover ranking/UI, Persona, RVI,
/// density-matrix/fidelity, or fabricated φ/ω.
class WaveStateModalShadowContract {
  WaveStateModalShadowContract._();

  static const String scoringVersion = 'wave_state_modal_shadow_v1';
  static const String policyVersion = 'wave_state_modal_shadow_policy_v1';
  static const String policyStatus = 'shadow_only_not_live';
  static const String registryVersion = QmatchProfileContract.registryVersion;

  static const bool shadowOnly = true;
  static const bool liveDiscoverRanking = false;
  static const bool structuralDistanceCoupled = false;
  static const bool personaEnabled = false;
  static const bool rviEnabled = false;
  static const bool densityMatrixEnabled = false;
  static const bool fabricatesMissingPhase = false;
  static const bool fabricatesMissingOmega = false;
  static const bool l5V1RetainedCandidate = false;

  /// Canonical Frequency 6D ids (registry order → harmonic index m = 1..6).
  static const List<String> frequencyDimensionIds =
      QmatchProfileTaxonomy.frequency;

  static const int registryModeCount = 6;

  /// Default string length \(L\) for orthonormal modes \(e_m(s)\).
  static const double defaultStringLength = 1.0;

  /// Harmonic index for a Frequency mode id (1-based). Returns null if unknown.
  static int? harmonicIndex(String modeId) {
    final i = frequencyDimensionIds.indexOf(modeId);
    if (i < 0) return null;
    return i + 1;
  }
}
