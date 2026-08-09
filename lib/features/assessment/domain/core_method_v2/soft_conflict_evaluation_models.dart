import 'core_method_v2_validation.dart';

class DirectionalSoftConflictSignal {
  final String fieldId;
  final String ownerId;
  final String evaluatedSubjectId;
  final double baseCompatibility;
  final double adjustedDirectionalFit;
  final double importance;
  final double flexibility;
  final double severity;
  final String severityBand;
  final double evidenceConfidence;
  final List<String> diagnosticCodes;

  DirectionalSoftConflictSignal({
    required this.fieldId,
    required this.ownerId,
    required this.evaluatedSubjectId,
    required this.baseCompatibility,
    required this.adjustedDirectionalFit,
    required this.importance,
    required this.flexibility,
    required this.severity,
    required this.severityBand,
    required this.evidenceConfidence,
    required this.diagnosticCodes,
  }) {
    cmRequireFinite01(severity, 'severity', allowNull: false);
  }

  factory DirectionalSoftConflictSignal.fromJson(Map<String, dynamic> j) =>
      DirectionalSoftConflictSignal(
        fieldId: j['field_id']?.toString() ?? '',
        ownerId: j['owner_id']?.toString() ?? '',
        evaluatedSubjectId: j['evaluated_subject_id']?.toString() ?? '',
        baseCompatibility: (j['base_compatibility'] as num).toDouble(),
        adjustedDirectionalFit:
            (j['adjusted_directional_fit'] as num).toDouble(),
        importance: (j['importance'] as num).toDouble(),
        flexibility: (j['flexibility'] as num).toDouble(),
        severity: (j['severity'] as num).toDouble(),
        severityBand: j['severity_band']?.toString() ?? '',
        evidenceConfidence: (j['evidence_confidence'] as num).toDouble(),
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'owner_id': ownerId,
        'evaluated_subject_id': evaluatedSubjectId,
        'base_compatibility': baseCompatibility,
        'adjusted_directional_fit': adjustedDirectionalFit,
        'importance': importance,
        'flexibility': flexibility,
        'severity': severity,
        'severity_band': severityBand,
        'evidence_confidence': evidenceConfidence,
        'diagnostic_codes': diagnosticCodes,
      });
}

class MutualSoftConflictSignal {
  final String fieldId;
  final double? subjectAToBSeverity;
  final double? subjectBToASeverity;
  final double? mutualSeverity;
  final String severityBand;
  final double? directionalAsymmetry;
  final List<String> diagnosticCodes;

  MutualSoftConflictSignal({
    required this.fieldId,
    required this.subjectAToBSeverity,
    required this.subjectBToASeverity,
    required this.mutualSeverity,
    required this.severityBand,
    required this.directionalAsymmetry,
    required this.diagnosticCodes,
  });

  factory MutualSoftConflictSignal.fromJson(Map<String, dynamic> j) =>
      MutualSoftConflictSignal(
        fieldId: j['field_id']?.toString() ?? '',
        subjectAToBSeverity: (j['subject_a_to_b_severity'] as num?)?.toDouble(),
        subjectBToASeverity: (j['subject_b_to_a_severity'] as num?)?.toDouble(),
        mutualSeverity: (j['mutual_severity'] as num?)?.toDouble(),
        severityBand: j['severity_band']?.toString() ?? '',
        directionalAsymmetry: (j['directional_asymmetry'] as num?)?.toDouble(),
        diagnosticCodes: [
          for (final e in (j['diagnostic_codes'] as List?) ?? const [])
            e.toString(),
        ]..sort(),
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'field_id': fieldId,
        'subject_a_to_b_severity': subjectAToBSeverity,
        'subject_b_to_a_severity': subjectBToASeverity,
        'mutual_severity': mutualSeverity,
        'severity_band': severityBand,
        'directional_asymmetry': directionalAsymmetry,
        'diagnostic_codes': diagnosticCodes,
      });
}

class SoftConflictEvaluationResult {
  final List<DirectionalSoftConflictSignal> subjectAToBSignals;
  final List<DirectionalSoftConflictSignal> subjectBToASignals;
  final List<MutualSoftConflictSignal> mutualSignals;
  final String deterministicFingerprint;
  final List<String> diagnostics;
  final String configVersion;
  final String registryVersion;

  const SoftConflictEvaluationResult({
    required this.subjectAToBSignals,
    required this.subjectBToASignals,
    required this.mutualSignals,
    required this.deterministicFingerprint,
    required this.diagnostics,
    required this.configVersion,
    required this.registryVersion,
  });

  factory SoftConflictEvaluationResult.fromJson(Map<String, dynamic> j) =>
      SoftConflictEvaluationResult(
        subjectAToBSignals: [
          for (final e in (j['subject_a_to_b_signals'] as List?) ?? const [])
            DirectionalSoftConflictSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        subjectBToASignals: [
          for (final e in (j['subject_b_to_a_signals'] as List?) ?? const [])
            DirectionalSoftConflictSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        mutualSignals: [
          for (final e in (j['mutual_signals'] as List?) ?? const [])
            MutualSoftConflictSignal.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
        ],
        deterministicFingerprint:
            j['deterministic_fingerprint']?.toString() ?? '',
        diagnostics: [
          for (final e in (j['diagnostics'] as List?) ?? const []) e.toString(),
        ]..sort(),
        configVersion: j['config_version']?.toString() ?? '',
        registryVersion: j['registry_version']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'subject_a_to_b_signals': [
          for (final s in subjectAToBSignals) s.toJson(),
        ],
        'subject_b_to_a_signals': [
          for (final s in subjectBToASignals) s.toJson(),
        ],
        'mutual_signals': [for (final s in mutualSignals) s.toJson()],
        'deterministic_fingerprint': deterministicFingerprint,
        'diagnostics': diagnostics,
        'config_version': configVersion,
        'registry_version': registryVersion,
      });
}
