/// Contract for the debug-only real temporal diagnostics runner.
class TemporalShadowDebugDiagnosticsRunnerContract {
  TemporalShadowDebugDiagnosticsRunnerContract._();

  static const String scoringVersion =
      'temporal_shadow_debug_diagnostics_runner_v1';
  static const String policyStatus = 'debug_only_shadow_not_live';
  static const bool debugOnly = true;
  static const bool shadowOnly = true;
  static const bool persistsDerivedFeatures = false;
  static const bool affectsDiscoverRanking = false;
  static const bool productionUiExposed = false;

  static const String refusalRequiresDebugMode = 'requires_k_debug_mode';
}
