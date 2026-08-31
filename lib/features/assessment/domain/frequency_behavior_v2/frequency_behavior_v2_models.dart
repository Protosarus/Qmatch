import 'frequency_behavior_v2_contract.dart';

/// Second-layer evidence descriptors. Not moral, clinical, or lie scores.
/// Null numeric fields = not reviewed. Authored values stay uncalibrated.
class FrequencyBehaviorV2EvidenceMeta {
  const FrequencyBehaviorV2EvidenceMeta({
    this.version = FrequencyBehaviorV2Contract.evidenceMetaVersion,
    this.calibrationStatus =
        FrequencyBehaviorV2Contract.evidenceCalibrationUncalibrated,
    this.reviewStatus = FrequencyBehaviorV2Contract.evidenceReviewPending,
    this.socialDesirability,
    this.obviousness,
    this.behavioralPlausibility,
    this.selfPresentationRisk,
    this.diagnosticValue,
    this.ambiguity,
  });

  final String version;
  final String calibrationStatus;
  final String reviewStatus;
  final double? socialDesirability;
  final double? obviousness;
  final double? behavioralPlausibility;
  final double? selfPresentationRisk;
  final double? diagnosticValue;
  final double? ambiguity;

  List<double?> get numericFields => [
        socialDesirability,
        obviousness,
        behavioralPlausibility,
        selfPresentationRisk,
        diagnosticValue,
        ambiguity,
      ];

  bool get isPendingNull =>
      reviewStatus == FrequencyBehaviorV2Contract.evidenceReviewPending &&
      numericFields.every((v) => v == null);

  bool get hasCompleteNumeric => numericFields.every((v) => v != null);

  bool get isResolved =>
      reviewStatus == FrequencyBehaviorV2Contract.evidenceReviewReviewed &&
      hasCompleteNumeric;

  factory FrequencyBehaviorV2EvidenceMeta.fromJson(Map<String, dynamic> json) {
    double? numOrNull(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      throw FormatException('evidence_meta.$key must be number or null');
    }

    return FrequencyBehaviorV2EvidenceMeta(
      version: (json['version'] as String?) ??
          FrequencyBehaviorV2Contract.evidenceMetaVersion,
      calibrationStatus: (json['calibration_status'] as String?) ??
          FrequencyBehaviorV2Contract.evidenceCalibrationUncalibrated,
      reviewStatus: (json['review_status'] as String?) ??
          FrequencyBehaviorV2Contract.evidenceReviewPending,
      socialDesirability: numOrNull('social_desirability'),
      obviousness: numOrNull('obviousness'),
      behavioralPlausibility: numOrNull('behavioral_plausibility'),
      selfPresentationRisk: numOrNull('self_presentation_risk'),
      diagnosticValue: numOrNull('diagnostic_value'),
      ambiguity: numOrNull('ambiguity'),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'calibration_status': calibrationStatus,
        'review_status': reviewStatus,
        'social_desirability': socialDesirability,
        'obviousness': obviousness,
        'behavioral_plausibility': behavioralPlausibility,
        'self_presentation_risk': selfPresentationRisk,
        'diagnostic_value': diagnosticValue,
        'ambiguity': ambiguity,
      };
}

class FrequencyBehaviorV2Option {
  const FrequencyBehaviorV2Option({
    required this.optionId,
    required this.text,
    required this.behavioralWeights,
    required this.evidenceMeta,
  });

  final String optionId;
  final String text;

  /// Explicit signed weights only. Missing key ≠ explicit 0.
  final Map<String, double> behavioralWeights;
  final FrequencyBehaviorV2EvidenceMeta evidenceMeta;

  factory FrequencyBehaviorV2Option.fromJson(Map<String, dynamic> json) {
    final raw = json['behavioral_weights'];
    if (raw is! Map) {
      throw FormatException('option.behavioral_weights must be a map');
    }
    final weights = <String, double>{};
    for (final e in raw.entries) {
      final val = e.value;
      if (val is! num) {
        throw FormatException('weight for ${e.key} must be numeric');
      }
      weights[e.key.toString()] = val.toDouble();
    }
    return FrequencyBehaviorV2Option(
      optionId: json['option_id'] as String,
      text: json['text'] as String,
      behavioralWeights: weights,
      evidenceMeta: FrequencyBehaviorV2EvidenceMeta.fromJson(
        Map<String, dynamic>.from(json['evidence_meta'] as Map? ?? const {}),
      ),
    );
  }
}

class FrequencyBehaviorV2Item {
  const FrequencyBehaviorV2Item({
    required this.itemId,
    required this.locale,
    required this.prompt,
    required this.context,
    required this.primaryDimensions,
    required this.secondaryDimensions,
    required this.semanticCluster,
    required this.crosscheckGroupIds,
    required this.options,
  });

  final String itemId;
  final String locale;
  final String prompt;
  final List<String> context;
  final List<String> primaryDimensions;
  final List<String> secondaryDimensions;
  final String semanticCluster;
  final List<String> crosscheckGroupIds;
  final List<FrequencyBehaviorV2Option> options;

  FrequencyBehaviorV2Option? optionById(String optionId) {
    for (final o in options) {
      if (o.optionId == optionId) return o;
    }
    return null;
  }

  factory FrequencyBehaviorV2Item.fromJson(Map<String, dynamic> json) {
    return FrequencyBehaviorV2Item(
      itemId: json['item_id'] as String,
      locale: json['locale'] as String,
      prompt: json['prompt'] as String,
      context: [
        for (final e in json['context'] as List? ?? const []) e.toString(),
      ],
      primaryDimensions: [
        for (final e in json['primary_dimensions'] as List? ?? const [])
          e.toString(),
      ],
      secondaryDimensions: [
        for (final e in json['secondary_dimensions'] as List? ?? const [])
          e.toString(),
      ],
      semanticCluster: json['semantic_cluster'] as String? ?? '',
      crosscheckGroupIds: [
        for (final e in json['crosscheck_group_ids'] as List? ?? const [])
          e.toString(),
      ],
      options: [
        for (final e in json['options'] as List)
          FrequencyBehaviorV2Option.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
      ],
    );
  }
}

class FrequencyBehaviorV2PoolDocument {
  const FrequencyBehaviorV2PoolDocument({
    required this.schemaVersion,
    required this.poolVersion,
    required this.scoringPolicyVersion,
    required this.locale,
    required this.status,
    required this.runtimeSelectable,
    required this.items,
  });

  final String schemaVersion;
  final String poolVersion;
  final String scoringPolicyVersion;
  final String locale;
  final String status;
  final bool runtimeSelectable;
  final List<FrequencyBehaviorV2Item> items;

  Map<String, FrequencyBehaviorV2Item> get itemsById => {
        for (final i in items) i.itemId: i,
      };

  factory FrequencyBehaviorV2PoolDocument.fromJson(Map<String, dynamic> json) {
    return FrequencyBehaviorV2PoolDocument(
      schemaVersion: json['schema_version'] as String,
      poolVersion: json['pool_version'] as String,
      scoringPolicyVersion: json['scoring_policy_version'] as String,
      locale: json['locale'] as String,
      status: json['status'] as String,
      runtimeSelectable: json['runtime_selectable'] as bool? ?? false,
      items: [
        for (final e in json['items'] as List)
          FrequencyBehaviorV2Item.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}

class FrequencyBehaviorV2Response {
  const FrequencyBehaviorV2Response({
    required this.itemId,
    required this.optionId,
  });

  final String itemId;
  final String optionId;
}

/// Boundary object for a future quantum-inspired compatibility layer.
///
/// Carries behavioral evidence only. Does not compute density matrices,
/// amplitudes, entanglement, or claim that a person is a quantum system.
class FrequencyBehaviorV2LatentHandoff {
  const FrequencyBehaviorV2LatentHandoff({
    required this.schemaVersion,
    required this.modelVersion,
    required this.poolVersion,
    required this.scoringPolicyVersion,
    required this.behavioralMean12d,
    required this.behavioralUncertainty12d,
    this.crossContextStability,
    this.socialDesirabilityPressure,
    this.responseQuality,
    this.responseConfidence,
  });

  final String schemaVersion;
  final String modelVersion;
  final String poolVersion;
  final String scoringPolicyVersion;
  final Map<String, double?> behavioralMean12d;
  final Map<String, double?> behavioralUncertainty12d;
  final double? crossContextStability;
  final double? socialDesirabilityPressure;
  final double? responseQuality;
  final double? responseConfidence;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'model_version': modelVersion,
        'pool_version': poolVersion,
        'scoring_policy_version': scoringPolicyVersion,
        'behavioral_mean_12d': behavioralMean12d,
        'behavioral_uncertainty_12d': behavioralUncertainty12d,
        'cross_context_stability': crossContextStability,
        'social_desirability_pressure': socialDesirabilityPressure,
        'response_quality': responseQuality,
        'response_confidence': responseConfidence,
        'not_claims': const [
          'quantum_mechanical_personhood',
          'true_personality',
          'lie_detection',
          'canonical_frequency_6d',
        ],
      };

  static FrequencyBehaviorV2LatentHandoff emptyDraft({
    required String poolVersion,
  }) {
    return FrequencyBehaviorV2LatentHandoff(
      schemaVersion: FrequencyBehaviorV2Contract.latentHandoffSchemaVersion,
      modelVersion: 'not_implemented',
      poolVersion: poolVersion,
      scoringPolicyVersion: FrequencyBehaviorV2Contract.scoringPolicyVersion,
      behavioralMean12d: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          d: null,
      },
      behavioralUncertainty12d: {
        for (final d in FrequencyBehaviorV2Contract.canonicalDimensions)
          d: null,
      },
    );
  }
}

class FrequencyBehaviorV2SessionItemPlan {
  const FrequencyBehaviorV2SessionItemPlan({
    required this.itemId,
    required this.displayedOptionIds,
  });

  final String itemId;
  final List<String> displayedOptionIds;
}

/// Dormant V2 session question row. Scores are not stored here.
class FrequencyBehaviorV2SessionQuestion {
  const FrequencyBehaviorV2SessionQuestion({
    required this.questionId,
    required this.primaryDimension,
    required this.presentationIndex,
    required this.presentedOptionOrder,
  });

  final String questionId;
  final String primaryDimension;
  final int presentationIndex;
  final List<String> presentedOptionOrder;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'primary_dimension': primaryDimension,
        'presentation_index': presentationIndex,
        'presented_option_order': presentedOptionOrder,
      };
}

/// Dormant V2 50-question session manifest. Not a live Frequency payload.
class FrequencyBehaviorV2SessionManifest {
  const FrequencyBehaviorV2SessionManifest({
    required this.schemaVersion,
    required this.selectorVersion,
    required this.bankVersion,
    required this.sessionId,
    required this.sessionSeed,
    required this.locale,
    required this.questionIds,
    required this.questions,
    this.createdAt,
  });

  final String schemaVersion;
  final String selectorVersion;
  final String bankVersion;
  final String sessionId;
  final String sessionSeed;
  final String locale;
  final String? createdAt;
  final List<String> questionIds;
  final List<FrequencyBehaviorV2SessionQuestion> questions;

  List<FrequencyBehaviorV2SessionItemPlan> get itemPlans => [
        for (final q in questions)
          FrequencyBehaviorV2SessionItemPlan(
            itemId: q.questionId,
            displayedOptionIds: q.presentedOptionOrder,
          ),
      ];

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'selector_version': selectorVersion,
        'bank_version': bankVersion,
        'session_id': sessionId,
        'session_seed': sessionSeed,
        'locale': locale,
        'created_at': createdAt,
        'question_ids': questionIds,
        'questions': [for (final q in questions) q.toJson()],
      };
}
