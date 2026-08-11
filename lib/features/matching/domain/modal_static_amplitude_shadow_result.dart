/// Shadow-only static Frequency 6D modal amplitude result.
///
/// [rModalShape] and [dModalLevel] are separate — never fused.
/// No phase / omega / similarity % / Persona / quantum / RVI.
class ModalStaticAmplitudeShadowResult {
  const ModalStaticAmplitudeShadowResult({
    required this.shapeAvailable,
    required this.levelAvailable,
    required this.rModalShape,
    required this.dModalLevel,
    required this.sharedModeCount,
    required this.registryModeCount,
    required this.modalCoverage,
    required this.sharedModeIds,
    required this.excludedModeIds,
    required this.shapeUnavailableReason,
    required this.scoringVersion,
    required this.policyVersion,
    required this.policyStatus,
    required this.registryVersion,
    required this.shadowOnly,
    required this.staticAmplitudeOnly,
    required this.phaseEnabled,
    required this.omegaEnabled,
  });

  /// True when cosine shape is defined (shared ≥ 2 and both norms > 0).
  final bool shapeAvailable;

  /// True when RMSE level distance is defined (shared ≥ 1).
  final bool levelAvailable;

  /// Cosine of shared amplitude vectors; null if shape unavailable.
  final double? rModalShape;

  /// RMSE over shared amplitudes; null if level unavailable.
  final double? dModalLevel;

  final int sharedModeCount;
  final int registryModeCount;

  /// sharedModeCount / registryModeCount.
  final double modalCoverage;

  final List<String> sharedModeIds;
  final List<String> excludedModeIds;

  /// Null when shape available; else a stable reason code.
  final String? shapeUnavailableReason;

  final String scoringVersion;
  final String policyVersion;
  final String policyStatus;
  final String registryVersion;
  final bool shadowOnly;
  final bool staticAmplitudeOnly;
  final bool phaseEnabled;
  final bool omegaEnabled;

  Map<String, dynamic> toWireMap() => {
        'shape_available': shapeAvailable,
        'level_available': levelAvailable,
        if (rModalShape != null) 'r_modal_shape': rModalShape,
        if (dModalLevel != null) 'd_modal_level': dModalLevel,
        'shared_mode_count': sharedModeCount,
        'registry_mode_count': registryModeCount,
        'modal_coverage': modalCoverage,
        'shared_mode_ids': sharedModeIds,
        'excluded_mode_ids': excludedModeIds,
        if (shapeUnavailableReason != null)
          'shape_unavailable_reason': shapeUnavailableReason,
        'scoring_version': scoringVersion,
        'policy_version': policyVersion,
        'policy_status': policyStatus,
        'registry_version': registryVersion,
        'shadow_only': shadowOnly,
        'static_amplitude_only': staticAmplitudeOnly,
        'phase_enabled': phaseEnabled,
        'omega_enabled': omegaEnabled,
      };
}
