import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import 'frequency_v2_runtime_contract.dart';

enum FrequencyV2PersistedSessionStatus {
  inProgress('in_progress'),
  completedPendingPersistence('completed_pending_persistence'),
  completed('completed'),
  abandoned('abandoned');

  const FrequencyV2PersistedSessionStatus(this.wireValue);
  final String wireValue;

  bool get isAnswerEditable =>
      this == FrequencyV2PersistedSessionStatus.inProgress;

  bool get keepsActivePointer =>
      this == FrequencyV2PersistedSessionStatus.inProgress ||
      this == FrequencyV2PersistedSessionStatus.completedPendingPersistence;

  static FrequencyV2PersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in FrequencyV2PersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return FrequencyV2PersistedSessionStatus.inProgress;
  }
}

class FrequencyV2SessionItemPlan {
  const FrequencyV2SessionItemPlan({
    required this.itemId,
    required this.primaryDimension,
    required this.presentedOptionOrder,
  });

  final String itemId;
  final String primaryDimension;
  final List<String> presentedOptionOrder;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'primary_dimension': primaryDimension,
        'presented_option_order': presentedOptionOrder,
      };

  factory FrequencyV2SessionItemPlan.fromJson(Map<String, dynamic> json) {
    final order =
        json['presented_option_order'] ?? json['displayed_option_ids'];
    return FrequencyV2SessionItemPlan(
      itemId: json['item_id'] as String,
      primaryDimension: json['primary_dimension'] as String? ?? '',
      presentedOptionOrder: (order as List).map((e) => e.toString()).toList(),
    );
  }
}

class FrequencyV2SessionAnswer {
  const FrequencyV2SessionAnswer({
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

  factory FrequencyV2SessionAnswer.fromJson(Map<String, dynamic> json) {
    return FrequencyV2SessionAnswer(
      itemId: json['item_id'] as String,
      selectedOptionId: json['selected_option_id'] as String,
      answeredAt: json['answered_at'] as String? ?? '',
    );
  }
}

/// Dedicated V2 persisted session. Distinct from Frequency V1 prefs blobs.
class FrequencyV2PersistedSessionState {
  const FrequencyV2PersistedSessionState({
    required this.schemaVersion,
    required this.sessionId,
    required this.ownerUid,
    required this.sessionSeed,
    required this.bankVersion,
    required this.bankLocale,
    required this.selectionPolicyVersion,
    required this.selectorVersion,
    required this.itemPlans,
    required this.currentQuestionIndex,
    required this.answers,
    required this.startedAt,
    required this.updatedAt,
    required this.status,
    this.translationVersion,
    this.completedAt,
    this.remoteFinalized = false,
  });

  final String schemaVersion;
  final String sessionId;
  final String ownerUid;
  final String sessionSeed;
  final String bankVersion;
  final String bankLocale;
  final String? translationVersion;
  final String selectionPolicyVersion;
  final String selectorVersion;
  final List<FrequencyV2SessionItemPlan> itemPlans;
  final int currentQuestionIndex;
  final List<FrequencyV2SessionAnswer> answers;
  final String startedAt;
  final String updatedAt;
  final String? completedAt;
  final FrequencyV2PersistedSessionStatus status;
  final bool remoteFinalized;

  Map<String, FrequencyV2SessionAnswer> get answersByItemId => {
        for (final a in answers) a.itemId: a,
      };

  int get firstUnansweredIndex {
    final byId = answersByItemId;
    for (var i = 0; i < itemPlans.length; i++) {
      if (!byId.containsKey(itemPlans[i].itemId)) return i;
    }
    return itemPlans.length;
  }

  FrequencyV2PersistedSessionState copyWith({
    int? currentQuestionIndex,
    List<FrequencyV2SessionAnswer>? answers,
    String? updatedAt,
    String? completedAt,
    FrequencyV2PersistedSessionStatus? status,
    bool? remoteFinalized,
  }) {
    return FrequencyV2PersistedSessionState(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      ownerUid: ownerUid,
      sessionSeed: sessionSeed,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      translationVersion: translationVersion,
      selectionPolicyVersion: selectionPolicyVersion,
      selectorVersion: selectorVersion,
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
    final ordered = <Map<String, dynamic>>[];
    for (final p in itemPlans) {
      final a = byId[p.itemId];
      if (a != null) ordered.add(a.toJson());
    }
    return {
      'schema_version': schemaVersion,
      'session_id': sessionId,
      'owner_uid': ownerUid,
      'session_seed': sessionSeed,
      'bank_version': bankVersion,
      'bank_locale': bankLocale,
      if (translationVersion != null) 'translation_version': translationVersion,
      'selection_policy_version': selectionPolicyVersion,
      'selector_version': selectorVersion,
      'item_plans': [for (final p in itemPlans) p.toJson()],
      'current_question_index': currentQuestionIndex,
      'answers': ordered,
      'started_at': startedAt,
      'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      'status': status.wireValue,
      'remote_finalized': remoteFinalized,
    };
  }

  factory FrequencyV2PersistedSessionState.fromJson(Map<String, dynamic> json) {
    return FrequencyV2PersistedSessionState(
      schemaVersion: json['schema_version'] as String,
      sessionId: json['session_id'] as String,
      ownerUid: json['owner_uid'] as String,
      sessionSeed: json['session_seed'] as String,
      bankVersion: json['bank_version'] as String,
      bankLocale: json['bank_locale'] as String,
      translationVersion: json['translation_version'] as String?,
      selectionPolicyVersion: json['selection_policy_version'] as String,
      selectorVersion: json['selector_version'] as String? ??
          FrequencyBehaviorV2Contract.selectorVersion,
      itemPlans: (json['item_plans'] as List)
          .map(
            (e) => FrequencyV2SessionItemPlan.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      currentQuestionIndex: json['current_question_index'] as int,
      answers: (json['answers'] as List? ?? const [])
          .map(
            (e) => FrequencyV2SessionAnswer.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      startedAt: json['started_at'] as String,
      updatedAt: json['updated_at'] as String,
      completedAt: json['completed_at'] as String?,
      status: FrequencyV2PersistedSessionStatus.fromWire(
        json['status'] as String?,
      ),
      remoteFinalized: json['remote_finalized'] as bool? ?? false,
    );
  }

  bool get hasLockedManifest =>
      itemPlans.length == FrequencyV2RuntimeContract.sessionItemCount;
}
