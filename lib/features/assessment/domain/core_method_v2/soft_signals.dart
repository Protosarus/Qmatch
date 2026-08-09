import 'core_method_v2_validation.dart';

class SoftPreference {
  final String id;
  final String targetId;
  final double? importance;
  final double? tolerance;
  final String status;

  SoftPreference({
    required this.id,
    required this.targetId,
    required this.importance,
    required this.tolerance,
    required this.status,
  }) {
    if (importance != null) {
      cmRequireFinite01(importance, 'importance', allowNull: false);
    }
    if (tolerance != null) {
      cmRequireFinite01(tolerance, 'tolerance', allowNull: false);
    }
  }

  factory SoftPreference.fromJson(Map<String, dynamic> j) => SoftPreference(
        id: j['id']?.toString() ?? '',
        targetId: j['target_id']?.toString() ?? '',
        importance: (j['importance'] as num?)?.toDouble(),
        tolerance: (j['tolerance'] as num?)?.toDouble(),
        status: j['status']?.toString() ?? 'provisional',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'id': id,
        'target_id': targetId,
        'importance': importance,
        'tolerance': tolerance,
        'status': status,
      });
}

/// Soft conflict signal contract only — no penalty calculation in P2B-0.
class SoftConflictSignal {
  final String id;
  final String targetId;
  final double? observedDifference;
  final double? importance;
  final double? tolerance;
  final double? severity;
  final double? evidenceConfidence;
  final String explanationCode;
  final String status;

  SoftConflictSignal({
    required this.id,
    required this.targetId,
    required this.observedDifference,
    required this.importance,
    required this.tolerance,
    required this.severity,
    required this.evidenceConfidence,
    required this.explanationCode,
    required this.status,
  }) {
    for (final e in [
      ['observedDifference', observedDifference],
      ['importance', importance],
      ['tolerance', tolerance],
      ['severity', severity],
      ['evidenceConfidence', evidenceConfidence],
    ]) {
      final v = e[1] as double?;
      if (v != null) cmRequireFinite01(v, e[0] as String, allowNull: false);
    }
  }

  factory SoftConflictSignal.fromJson(Map<String, dynamic> j) =>
      SoftConflictSignal(
        id: j['id']?.toString() ?? '',
        targetId: j['target_id']?.toString() ?? '',
        observedDifference: (j['observed_difference'] as num?)?.toDouble(),
        importance: (j['importance'] as num?)?.toDouble(),
        tolerance: (j['tolerance'] as num?)?.toDouble(),
        severity: (j['severity'] as num?)?.toDouble(),
        evidenceConfidence: (j['evidence_confidence'] as num?)?.toDouble(),
        explanationCode: j['explanation_code']?.toString() ?? '',
        status: j['status']?.toString() ?? 'provisional',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'id': id,
        'target_id': targetId,
        'observed_difference': observedDifference,
        'importance': importance,
        'tolerance': tolerance,
        'severity': severity,
        'evidence_confidence': evidenceConfidence,
        'explanation_code': explanationCode,
        'status': status,
      });
}
