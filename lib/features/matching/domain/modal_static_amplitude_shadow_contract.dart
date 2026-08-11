import '../../assessment/domain/profile/qmatch_profile_contract.dart';
import '../../assessment/domain/profile/qmatch_profile_models.dart';

/// Shadow-only static Frequency 6D modal amplitude model (not true resonance).
///
/// Emits separate shape alignment and level distance over shared measured
/// Frequency dimensions. No phase, omega, temporal fabrication, Persona,
/// quantum, RVI, or Discover ranking/UI coupling.
class ModalStaticAmplitudeShadowContract {
  ModalStaticAmplitudeShadowContract._();

  static const String scoringVersion = 'modal_static_amplitude_shadow_v1';

  static const String policyVersion =
      'modal_static_amplitude_shadow_policy_v1';

  /// Not live; static amplitude-only (not modal resonance with phase).
  static const String policyStatus = 'shadow_only_static_amplitude_not_live';

  static const String registryVersion = QmatchProfileContract.registryVersion;

  static const bool shadowOnly = true;
  static const bool staticAmplitudeOnly = true;
  static const bool phaseEnabled = false;
  static const bool omegaEnabled = false;
  static const bool liveDiscoverRanking = false;

  /// Canonical Frequency 6D ids (registry order).
  static const List<String> frequencyDimensionIds =
      QmatchProfileTaxonomy.frequency;

  static const int registryModeCount = 6;

  /// Shape cosine requires at least this many shared measured modes.
  static const int minSharedModesForShape = 2;
}
