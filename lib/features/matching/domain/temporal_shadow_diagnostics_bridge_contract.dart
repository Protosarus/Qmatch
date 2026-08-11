/// Privacy-safe temporal diagnostics bridge contract (shadow/debug only).
class TemporalShadowDiagnosticsBridgeContract {
  TemporalShadowDiagnosticsBridgeContract._();

  static const String scoringVersion =
      'temporal_shadow_diagnostics_bridge_v1';
  static const String policyStatus = 'shadow_only_debug_not_live';
  static const bool shadowOnly = true;
  static const bool persistsDerivedFeatures = false;
  static const bool affectsDiscoverRanking = false;

  /// Firestore message keys the bridge may consume.
  static const Set<String> allowedMessageFieldKeys = {
    'sender_id',
    'client_created_at',
    'created_at',
  };

  /// Explicitly forbidden for temporal analysis.
  static const Set<String> forbiddenMessageFieldKeys = {
    'text',
    'body',
    'content',
    'last_message_preview',
    'moderation',
    'read_by',
  };
}
