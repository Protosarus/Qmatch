import 'frequency_session_contract.dart';

/// One planned item — option order frozen for the session.
class FrequencySessionItemPlan {
  const FrequencySessionItemPlan({
    required this.itemId,
    required this.primaryDimension,
    required this.displayedOptionIds,
  });

  final String itemId;

  /// Null for separator / response_quality items (no single primary).
  final String? primaryDimension;
  final List<String> displayedOptionIds;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'primary_dimension': primaryDimension,
        'displayed_option_ids': displayedOptionIds,
      };

  factory FrequencySessionItemPlan.fromJson(Map<String, dynamic> json) {
    return FrequencySessionItemPlan(
      itemId: json['item_id'] as String,
      primaryDimension: json['primary_dimension'] as String?,
      displayedOptionIds: (json['displayed_option_ids'] as List)
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Canonical answer — option ID identity only (never display index).
class FrequencySessionAnswer {
  const FrequencySessionAnswer({
    required this.itemId,
    required this.selectedOptionId,
    required this.answeredAt,
  });

  final String itemId;
  final String selectedOptionId;
  final String answeredAt;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'selected_option_id': selectedOptionId,
        'answered_at': answeredAt,
      };

  factory FrequencySessionAnswer.fromJson(Map<String, dynamic> json) {
    return FrequencySessionAnswer(
      itemId: json['item_id'] as String,
      selectedOptionId: json['selected_option_id'] as String,
      answeredAt: json['answered_at'] as String,
    );
  }
}

/// Durable Frequency session state.
class FrequencyPersistedSessionState {
  const FrequencyPersistedSessionState({
    required this.schemaVersion,
    required this.sessionId,
    required this.ownerUid,
    required this.bankVersion,
    required this.bankLocale,
    required this.selectionPolicyVersion,
    required this.scoringPolicyVersion,
    required this.sessionSeed,
    required this.itemPlans,
    required this.currentQuestionIndex,
    required this.answers,
    required this.startedAt,
    required this.updatedAt,
    required this.status,
    this.completedAt,
    this.remoteFinalized = false,
  });

  final String schemaVersion;
  final String sessionId;
  final String ownerUid;
  final String bankVersion;
  final String bankLocale;
  final String selectionPolicyVersion;
  final String scoringPolicyVersion;
  final String sessionSeed;
  final List<FrequencySessionItemPlan> itemPlans;
  final int currentQuestionIndex;
  final List<FrequencySessionAnswer> answers;
  final String startedAt;
  final String updatedAt;
  final String? completedAt;
  final FrequencyPersistedSessionStatus status;

  /// True only after remote assessments/frequency + progress + canonical_v1 succeed.
  final bool remoteFinalized;

  Map<String, FrequencySessionAnswer> get answersByItemId => {
        for (final a in answers) a.itemId: a,
      };

  FrequencyPersistedSessionState copyWith({
    int? currentQuestionIndex,
    List<FrequencySessionAnswer>? answers,
    String? updatedAt,
    String? completedAt,
    FrequencyPersistedSessionStatus? status,
    bool? remoteFinalized,
  }) {
    return FrequencyPersistedSessionState(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      ownerUid: ownerUid,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      selectionPolicyVersion: selectionPolicyVersion,
      scoringPolicyVersion: scoringPolicyVersion,
      sessionSeed: sessionSeed,
      itemPlans: itemPlans,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      remoteFinalized: remoteFinalized ?? this.remoteFinalized,
    );
  }

  Map<String, dynamic> toJson() {
    final byId = answersByItemId;
    final orderedAnswers = <Map<String, dynamic>>[];
    for (final p in itemPlans) {
      final a = byId[p.itemId];
      if (a != null) orderedAnswers.add(a.toJson());
    }
    return {
      'schema_version': schemaVersion,
      'session_id': sessionId,
      'owner_uid': ownerUid,
      'bank_version': bankVersion,
      'bank_locale': bankLocale,
      'selection_policy_version': selectionPolicyVersion,
      'scoring_policy_version': scoringPolicyVersion,
      'session_seed': sessionSeed,
      'item_plans': [for (final p in itemPlans) p.toJson()],
      'current_question_index': currentQuestionIndex,
      'answers': orderedAnswers,
      'started_at': startedAt,
      'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      'status': status.wireValue,
      'remote_finalized': remoteFinalized,
    };
  }

  factory FrequencyPersistedSessionState.fromJson(Map<String, dynamic> json) {
    return FrequencyPersistedSessionState(
      schemaVersion: json['schema_version'] as String,
      sessionId: json['session_id'] as String,
      ownerUid: json['owner_uid'] as String,
      bankVersion: json['bank_version'] as String,
      bankLocale: json['bank_locale'] as String,
      selectionPolicyVersion: json['selection_policy_version'] as String,
      scoringPolicyVersion: json['scoring_policy_version'] as String? ??
          FrequencySessionContract.scoringPolicyVersion,
      sessionSeed: json['session_seed'] as String,
      itemPlans: (json['item_plans'] as List)
          .map((e) => FrequencySessionItemPlan.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentQuestionIndex: json['current_question_index'] as int,
      answers: (json['answers'] as List? ?? const [])
          .map((e) => FrequencySessionAnswer.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      startedAt: json['started_at'] as String,
      updatedAt: json['updated_at'] as String,
      completedAt: json['completed_at'] as String?,
      status:
          FrequencyPersistedSessionStatus.fromWire(json['status'] as String?),
      remoteFinalized: json['remote_finalized'] as bool? ?? false,
    );
  }
}
