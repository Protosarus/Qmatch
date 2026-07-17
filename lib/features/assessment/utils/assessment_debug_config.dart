import 'package:flutter/foundation.dart';

/// Debug-only assessment overrides.
///
/// Enable with:
/// ```
/// flutter run --dart-define=QMATCH_DEBUG_FORCE_PILOT_ASSESSMENT_SETS=true
/// ```
///
/// Active only when [kDebugMode] is true AND the dart-define is true.
/// Always disabled in release/profile builds.
class AssessmentDebugConfig {
  const AssessmentDebugConfig._();

  static const bool _forcePilot = bool.fromEnvironment(
    'QMATCH_DEBUG_FORCE_PILOT_ASSESSMENT_SETS',
    defaultValue: false,
  );

  /// When true, IQ/EQ/Frequency load bundled `*_set_001` assets for localization QA.
  static bool get forcePilotAssessmentSets => kDebugMode && _forcePilot;

  /// Pilot set id for an assessment [type], or null if type is unknown.
  static String? pilotSetIdFor(String type) {
    switch (type) {
      case 'iq':
        return 'iq_set_001';
      case 'eq':
        return 'eq_set_001';
      case 'frequency':
        return 'frequency_set_001';
      default:
        return null;
    }
  }
}
