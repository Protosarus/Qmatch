import 'package:cloud_firestore/cloud_firestore.dart';

import 'relationship_dimensions.dart';

class RelationshipAnalysisState {
  const RelationshipAnalysisState({
    required this.schemaVersion,
    required this.bankVersion,
    required this.contentVersion,
    required this.scoringPolicyVersion,
    required this.answersByQuestionId,
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.dimensionRawSignedEvidence,
    required this.analysisDepth,
    this.activeMicroScanId,
    this.activeMicroScanQuestionIds = const [],
    this.activeMicroScanIndex = 0,
    this.proactiveNudgeSuppressUntil,
  });

  final String schemaVersion;
  final String bankVersion;
  final String contentVersion;
  final String scoringPolicyVersion;
  final Map<String, String> answersByQuestionId;
  final Map<String, double> dimensionScores;
  final Map<String, int> dimensionEvidenceCounts;
  final Map<String, double> dimensionRawSignedEvidence;
  final double analysisDepth;
  final String? activeMicroScanId;
  final List<String> activeMicroScanQuestionIds;
  final int activeMicroScanIndex;

  /// UTC instant until which Activity proactive prompts are suppressed.
  /// Does not affect Profile voluntary CTA. Null = no cooldown.
  final DateTime? proactiveNudgeSuppressUntil;

  int get answeredCount => answersByQuestionId.length;

  bool get hasActiveMicroScan => activeMicroScanQuestionIds
      .any((id) => !answersByQuestionId.containsKey(id));

  bool get isBankComplete =>
      answeredCount >= RelationshipAnalysisContract.questionCount;

  factory RelationshipAnalysisState.empty() => RelationshipAnalysisState(
        schemaVersion: RelationshipAnalysisContract.schemaVersion,
        bankVersion: RelationshipAnalysisContract.bankVersion,
        contentVersion: RelationshipAnalysisContract.contentVersion,
        scoringPolicyVersion: RelationshipAnalysisContract.scoringPolicyVersion,
        answersByQuestionId: const {},
        dimensionScores: {
          for (final d in RelationshipDimensionIds.all)
            d: RelationshipAnalysisContract.scoreBaseline,
        },
        dimensionEvidenceCounts: {
          for (final d in RelationshipDimensionIds.all) d: 0,
        },
        dimensionRawSignedEvidence: {
          for (final d in RelationshipDimensionIds.all) d: 0.0,
        },
        analysisDepth: 0.0,
      );

  RelationshipAnalysisState copyWith({
    Map<String, String>? answersByQuestionId,
    Map<String, double>? dimensionScores,
    Map<String, int>? dimensionEvidenceCounts,
    Map<String, double>? dimensionRawSignedEvidence,
    double? analysisDepth,
    String? activeMicroScanId,
    List<String>? activeMicroScanQuestionIds,
    int? activeMicroScanIndex,
    bool clearActiveMicroScan = false,
    DateTime? proactiveNudgeSuppressUntil,
    bool clearProactiveNudgeSuppressUntil = false,
  }) {
    return RelationshipAnalysisState(
      schemaVersion: schemaVersion,
      bankVersion: bankVersion,
      contentVersion: contentVersion,
      scoringPolicyVersion: scoringPolicyVersion,
      answersByQuestionId: answersByQuestionId ?? this.answersByQuestionId,
      dimensionScores: dimensionScores ?? this.dimensionScores,
      dimensionEvidenceCounts:
          dimensionEvidenceCounts ?? this.dimensionEvidenceCounts,
      dimensionRawSignedEvidence:
          dimensionRawSignedEvidence ?? this.dimensionRawSignedEvidence,
      analysisDepth: analysisDepth ?? this.analysisDepth,
      activeMicroScanId: clearActiveMicroScan
          ? null
          : (activeMicroScanId ?? this.activeMicroScanId),
      activeMicroScanQuestionIds: clearActiveMicroScan
          ? const []
          : (activeMicroScanQuestionIds ?? this.activeMicroScanQuestionIds),
      activeMicroScanIndex: clearActiveMicroScan
          ? 0
          : (activeMicroScanIndex ?? this.activeMicroScanIndex),
      proactiveNudgeSuppressUntil: clearProactiveNudgeSuppressUntil
          ? null
          : (proactiveNudgeSuppressUntil ?? this.proactiveNudgeSuppressUntil),
    );
  }

  Map<String, dynamic> toPersistenceFields() => {
        'schema_version': schemaVersion,
        'live_result_schema_version':
            RelationshipAnalysisContract.liveResultSchemaVersion,
        'bank_version': bankVersion,
        'content_version': contentVersion,
        'scoring_policy_version': scoringPolicyVersion,
        'analysis_depth_policy_version':
            RelationshipAnalysisContract.analysisDepthPolicyVersion,
        'dimension_registry_version':
            RelationshipAnalysisContract.dimensionRegistryVersion,
        'assessment_type': RelationshipAnalysisContract.assessmentType,
        'status': isBankComplete ? 'completed' : 'in_progress',
        'answered_count': answeredCount,
        'question_count': RelationshipAnalysisContract.questionCount,
        'answers_by_question_id': Map<String, String>.from(answersByQuestionId),
        'answered_question_ids': answersByQuestionId.keys.toList()..sort(),
        'dimension_scores': Map<String, double>.from(dimensionScores),
        'dimension_evidence_counts':
            Map<String, int>.from(dimensionEvidenceCounts),
        'dimension_raw_signed_evidence':
            Map<String, double>.from(dimensionRawSignedEvidence),
        'analysis_depth': analysisDepth,
        'active_micro_scan': activeMicroScanQuestionIds.isEmpty
            ? null
            : {
                'session_id': activeMicroScanId,
                'question_ids': activeMicroScanQuestionIds,
                'current_index': activeMicroScanIndex,
              },
        'proactive_nudge_suppress_until':
            proactiveNudgeSuppressUntil?.toUtc().toIso8601String(),
        'source': 'client_relationship_analysis_v1',
        'matching_input': false,
        'persona_input': false,
        'canonical_20d_merged': false,
      };

  static DateTime? _readUtc(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) {
      final parsed = DateTime.tryParse(raw.trim());
      return parsed?.toUtc();
    }
    return null;
  }

  static RelationshipAnalysisState fromPersistence(Map<String, dynamic>? doc) {
    if (doc == null || doc.isEmpty) return RelationshipAnalysisState.empty();

    final answers = <String, String>{};
    final answersRaw = doc['answers_by_question_id'];
    if (answersRaw is Map) {
      for (final e in answersRaw.entries) {
        final v = e.value?.toString().trim() ?? '';
        if (v.isNotEmpty) answers[e.key.toString()] = v;
      }
    }

    Map<String, double> readDoubles(String key, {double fallback = 0.5}) {
      final out = {
        for (final d in RelationshipDimensionIds.all) d: fallback,
      };
      final raw = doc[key];
      if (raw is Map) {
        for (final e in raw.entries) {
          final k = e.key.toString();
          if (!RelationshipDimensionIds.allSet.contains(k)) continue;
          final v = e.value;
          if (v is num && v.isFinite) {
            out[k] = v.toDouble().clamp(0.0, 1.0);
          }
        }
      }
      return out;
    }

    Map<String, int> readInts(String key) {
      final out = {for (final d in RelationshipDimensionIds.all) d: 0};
      final raw = doc[key];
      if (raw is Map) {
        for (final e in raw.entries) {
          final k = e.key.toString();
          if (!RelationshipDimensionIds.allSet.contains(k)) continue;
          final v = e.value;
          if (v is num) out[k] = v.toInt();
        }
      }
      return out;
    }

    Map<String, double> readRaw(String key) {
      final out = {for (final d in RelationshipDimensionIds.all) d: 0.0};
      final raw = doc[key];
      if (raw is Map) {
        for (final e in raw.entries) {
          final k = e.key.toString();
          if (!RelationshipDimensionIds.allSet.contains(k)) continue;
          final v = e.value;
          if (v is num && v.isFinite) out[k] = v.toDouble();
        }
      }
      return out;
    }

    String? scanId;
    var scanIds = const <String>[];
    var scanIndex = 0;
    final scan = doc['active_micro_scan'];
    if (scan is Map) {
      scanId = scan['session_id']?.toString();
      final qids = scan['question_ids'];
      if (qids is List) {
        scanIds = qids.map((e) => e.toString()).toList(growable: false);
      }
      final idx = scan['current_index'];
      if (idx is num) scanIndex = idx.toInt();
    }

    final depthRaw = doc['analysis_depth'];
    final depth =
        depthRaw is num ? depthRaw.toDouble().clamp(0.0, 1.0).toDouble() : 0.0;

    return RelationshipAnalysisState(
      schemaVersion: doc['schema_version']?.toString() ??
          RelationshipAnalysisContract.schemaVersion,
      bankVersion: doc['bank_version']?.toString() ??
          RelationshipAnalysisContract.bankVersion,
      contentVersion: doc['content_version']?.toString() ??
          RelationshipAnalysisContract.contentVersion,
      scoringPolicyVersion: doc['scoring_policy_version']?.toString() ??
          RelationshipAnalysisContract.scoringPolicyVersion,
      answersByQuestionId: Map.unmodifiable(answers),
      dimensionScores: Map.unmodifiable(readDoubles('dimension_scores')),
      dimensionEvidenceCounts:
          Map.unmodifiable(readInts('dimension_evidence_counts')),
      dimensionRawSignedEvidence:
          Map.unmodifiable(readRaw('dimension_raw_signed_evidence')),
      analysisDepth: depth,
      activeMicroScanId: scanId,
      activeMicroScanQuestionIds: List.unmodifiable(scanIds),
      activeMicroScanIndex: scanIndex,
      proactiveNudgeSuppressUntil:
          _readUtc(doc['proactive_nudge_suppress_until']),
    );
  }
}
