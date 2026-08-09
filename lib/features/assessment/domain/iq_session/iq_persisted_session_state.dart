import 'iq_session_contract.dart';
import 'iq_session_models.dart';

/// Persisted session lifecycle (wire values: in_progress / completed / abandoned).
enum IqPersistedSessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned');

  const IqPersistedSessionStatus(this.wireValue);
  final String wireValue;

  static IqPersistedSessionStatus fromWire(String? raw) {
    final v = raw ?? 'in_progress';
    for (final e in IqPersistedSessionStatus.values) {
      if (e.wireValue == v || e.name == v) return e;
    }
    return IqPersistedSessionStatus.inProgress;
  }
}

/// Canonical answer — option ID identity only (never display position).
class IqSessionAnswer {
  const IqSessionAnswer({
    required this.itemId,
    required this.selectedOptionId,
    required this.answeredAt,
  });

  final String itemId;
  final String selectedOptionId;

  /// ISO-8601 UTC.
  final String answeredAt;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'selected_option_id': selectedOptionId,
        'answered_at': answeredAt,
      };

  factory IqSessionAnswer.fromJson(Map<String, dynamic> json) {
    return IqSessionAnswer(
      itemId: json['item_id'] as String,
      selectedOptionId: json['selected_option_id'] as String,
      answeredAt: json['answered_at'] as String,
    );
  }
}

/// Durable IQ session state (P2C-2A-3). Does not store question text or scores.
class IqPersistedSessionState {
  const IqPersistedSessionState({
    required this.schemaVersion,
    required this.sessionId,
    required this.ownerUid,
    required this.bankVersion,
    required this.bankLocale,
    required this.selectionPolicyVersion,
    required this.sessionSeed,
    required this.itemPlans,
    required this.currentQuestionIndex,
    required this.answers,
    required this.startedAt,
    required this.updatedAt,
    required this.status,
    this.completedAt,
    this.eligibilityMode =
        IqSessionEligibilityMode.offlineDeskReviewedCandidate,
    this.freshnessMode = IqSessionFreshnessMode.strictUnseenFamilies,
    this.balanceDisplayedCorrectPositions = true,
    this.createdFromBankItemCount = 340,
  });

  static const String schemaVersionValue = 'qmatch_iq_persisted_session_v1';

  final String schemaVersion;
  final String sessionId;
  final String ownerUid;
  final String bankVersion;
  final String bankLocale;
  final String selectionPolicyVersion;
  final String sessionSeed;
  final List<IqSessionItemPlan> itemPlans;
  final int currentQuestionIndex;

  /// Answers ordered by session plan item order (deterministic).
  final List<IqSessionAnswer> answers;

  final String startedAt;
  final String updatedAt;
  final String? completedAt;
  final IqPersistedSessionStatus status;
  final IqSessionEligibilityMode eligibilityMode;
  final IqSessionFreshnessMode freshnessMode;
  final bool balanceDisplayedCorrectPositions;
  final int createdFromBankItemCount;

  Map<String, IqSessionAnswer> get answersByItemId => {
        for (final a in answers) a.itemId: a,
      };

  IqSessionPlan toSessionPlan() {
    return IqSessionPlan(
      schemaVersion: IqSessionContract.schemaVersion,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      sessionSeed: sessionSeed,
      itemPlans: itemPlans,
      dimensionCounts: {
        for (final d in const [
          'logical_reasoning',
          'pattern_reasoning',
          'verbal_reasoning',
          'spatial_reasoning',
        ])
          d: itemPlans.where((p) => p.dimension == d).length,
      },
      createdFromBankItemCount: createdFromBankItemCount,
      selectionPolicyVersion: selectionPolicyVersion,
      balanceDisplayedCorrectPositions: balanceDisplayedCorrectPositions,
      eligibilityMode: eligibilityMode,
      freshnessMode: freshnessMode,
    );
  }

  IqPersistedSessionState copyWith({
    List<IqSessionItemPlan>? itemPlans,
    int? currentQuestionIndex,
    List<IqSessionAnswer>? answers,
    String? updatedAt,
    String? completedAt,
    IqPersistedSessionStatus? status,
  }) {
    return IqPersistedSessionState(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      ownerUid: ownerUid,
      bankVersion: bankVersion,
      bankLocale: bankLocale,
      selectionPolicyVersion: selectionPolicyVersion,
      sessionSeed: sessionSeed,
      itemPlans: itemPlans ?? this.itemPlans,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      eligibilityMode: eligibilityMode,
      freshnessMode: freshnessMode,
      balanceDisplayedCorrectPositions: balanceDisplayedCorrectPositions,
      createdFromBankItemCount: createdFromBankItemCount,
    );
  }

  /// Fill [IqSessionItemPlan.displayedCorrectPosition] from the bank.
  /// Persisted drafts omit that field (privacy — no correct-answer storage).
  IqPersistedSessionState rehydrateDisplayedCorrectPositions(
    Map<String, String> itemIdToCorrectOptionId,
  ) {
    final nextPlans = <IqSessionItemPlan>[];
    for (final p in itemPlans) {
      final correctId = itemIdToCorrectOptionId[p.itemId];
      final pos =
          correctId == null ? -1 : p.displayedOptionIds.indexOf(correctId);
      nextPlans.add(
        IqSessionItemPlan(
          itemId: p.itemId,
          dimension: p.dimension,
          templateFamilyId: p.templateFamilyId,
          displayedOptionIds: p.displayedOptionIds,
          displayedCorrectPosition: pos,
        ),
      );
    }
    return copyWith(itemPlans: nextPlans);
  }

  Map<String, dynamic> toJson() {
    // Answers ordered by plan order for deterministic serialization.
    final byId = answersByItemId;
    final orderedAnswers = <Map<String, dynamic>>[];
    for (final p in itemPlans) {
      final a = byId[p.itemId];
      if (a != null) orderedAnswers.add(a.toJson());
    }
    // Persist item plans without displayed_correct_position / prompts.
    final slimPlans = itemPlans
        .map(
          (e) => <String, dynamic>{
            'item_id': e.itemId,
            'dimension': e.dimension,
            'template_family_id': e.templateFamilyId,
            'displayed_option_ids': e.displayedOptionIds,
          },
        )
        .toList();
    return {
      'schema_version': schemaVersion,
      'session_id': sessionId,
      'owner_uid': ownerUid,
      'bank_version': bankVersion,
      'bank_locale': bankLocale,
      'selection_policy_version': selectionPolicyVersion,
      'session_seed': sessionSeed,
      'item_plans': slimPlans,
      'current_question_index': currentQuestionIndex,
      'answers': orderedAnswers,
      'started_at': startedAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
      'status': status.wireValue,
      'eligibility_mode': eligibilityMode.name,
      'freshness_mode': freshnessMode.name,
      'balance_displayed_correct_positions': balanceDisplayedCorrectPositions,
      'created_from_bank_item_count': createdFromBankItemCount,
    };
  }

  factory IqPersistedSessionState.fromJson(Map<String, dynamic> json) {
    final status = IqPersistedSessionStatus.fromWire(json['status'] as String?);
    final eligName = json['eligibility_mode'] as String? ??
        IqSessionEligibilityMode.offlineDeskReviewedCandidate.name;
    final freshName = json['freshness_mode'] as String? ??
        IqSessionFreshnessMode.strictUnseenFamilies.name;
    return IqPersistedSessionState(
      schemaVersion: json['schema_version'] as String,
      sessionId: json['session_id'] as String,
      ownerUid: json['owner_uid'] as String,
      bankVersion: json['bank_version'] as String,
      bankLocale: json['bank_locale'] as String,
      selectionPolicyVersion: json['selection_policy_version'] as String,
      sessionSeed: json['session_seed'] as String,
      itemPlans: (json['item_plans'] as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return IqSessionItemPlan(
          itemId: m['item_id'] as String,
          dimension: m['dimension'] as String,
          templateFamilyId: m['template_family_id'] as String,
          displayedOptionIds: (m['displayed_option_ids'] as List)
              .map((x) => x.toString())
              .toList(),
          // Rehydrated from bank before validation; never trusted from disk.
          displayedCorrectPosition:
              m['displayed_correct_position'] as int? ?? -1,
        );
      }).toList(),
      currentQuestionIndex: json['current_question_index'] as int,
      answers: (json['answers'] as List? ?? const [])
          .map((e) =>
              IqSessionAnswer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      startedAt: json['started_at'] as String,
      updatedAt: json['updated_at'] as String,
      completedAt: json['completed_at'] as String?,
      status: status,
      eligibilityMode: IqSessionEligibilityMode.values.firstWhere(
        (e) => e.name == eligName,
        orElse: () => IqSessionEligibilityMode.offlineDeskReviewedCandidate,
      ),
      freshnessMode: IqSessionFreshnessMode.values.firstWhere(
        (e) => e.name == freshName,
        orElse: () => IqSessionFreshnessMode.strictUnseenFamilies,
      ),
      balanceDisplayedCorrectPositions:
          json['balance_displayed_correct_positions'] as bool? ?? true,
      createdFromBankItemCount:
          json['created_from_bank_item_count'] as int? ?? 340,
    );
  }
}

/// Typed load outcomes — no silent repair.
enum IqSessionLoadCode {
  loaded,
  notFound,
  ownerMismatch,
  ownerUnavailable,
  incompatibleSchema,
  incompatibleBank,
  incompatiblePolicy,
  corrupt,
}

class IqSessionLoadResult {
  const IqSessionLoadResult({
    required this.code,
    this.state,
    this.message,
  });

  final IqSessionLoadCode code;
  final IqPersistedSessionState? state;
  final String? message;

  bool get isLoaded => code == IqSessionLoadCode.loaded && state != null;
}

class IqSessionWriteResult {
  const IqSessionWriteResult({
    required this.ok,
    this.code,
    this.message,
    this.state,
  });

  final bool ok;
  final String? code;
  final String? message;
  final IqPersistedSessionState? state;
}
