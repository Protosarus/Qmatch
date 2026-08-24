import '../domain/relationship_analysis_state.dart';
import '../domain/relationship_bank_loader.dart';
import '../domain/relationship_bank_models.dart';
import '../domain/relationship_dimensions.dart';
import '../domain/relationship_micro_scan_selector.dart';
import '../domain/relationship_scorer.dart';
import 'relationship_analysis_persistence.dart';

class RelationshipAnalysisService {
  RelationshipAnalysisService({
    RelationshipBankLoader? bankLoader,
    RelationshipAnalysisPersistence? persistence,
    RelationshipAnalysisScorer scorer = const RelationshipAnalysisScorer(),
    RelationshipMicroScanSelector selector =
        const RelationshipMicroScanSelector(),
    DateTime Function()? clock,
  })  : _bankLoader = bankLoader ?? RelationshipBankLoader(),
        _persistence = persistence ?? RelationshipAnalysisPersistence(),
        _scorer = scorer,
        _selector = selector,
        _clock = clock ?? DateTime.now;

  final RelationshipBankLoader _bankLoader;
  final RelationshipAnalysisPersistence _persistence;
  final RelationshipAnalysisScorer _scorer;
  final RelationshipMicroScanSelector _selector;
  final DateTime Function() _clock;

  Future<RelationshipAnalysisBank> loadBank() => _bankLoader.load();

  Future<RelationshipAnalysisState> loadState(String uid) =>
      _persistence.loadForUid(uid);

  bool isBankComplete(RelationshipAnalysisState state) => state.isBankComplete;

  Future<RelationshipAnalysisState> beginMicroScan({
    required String uid,
    required RelationshipAnalysisState state,
    String? sessionId,
  }) async {
    final bank = await loadBank();

    if (isBankComplete(state)) {
      final cleared = state.copyWith(clearActiveMicroScan: true);
      await _persistence.saveForUid(uid: uid, state: cleared);
      return cleared;
    }

    final ids = _selector.selectOrResume(
      bank: bank,
      answeredQuestionIds: state.answersByQuestionId.keys.toSet(),
      dimensionEvidenceCounts: state.dimensionEvidenceCounts,
      activeQuestionIds: state.activeMicroScanQuestionIds,
      size: RelationshipAnalysisContract.microScanSize,
    );

    if (ids.isEmpty) {
      final cleared = state.copyWith(clearActiveMicroScan: true);
      await _persistence.saveForUid(uid: uid, state: cleared);
      return cleared;
    }

    final sameSession = state.activeMicroScanQuestionIds.length == ids.length &&
        List.generate(
          ids.length,
          (i) => state.activeMicroScanQuestionIds[i] == ids[i],
        ).every((e) => e);

    final firstUnansweredIndex = ids.indexWhere(
      (id) => !state.answersByQuestionId.containsKey(id),
    );

    final next = state.copyWith(
      activeMicroScanId: sameSession
          ? (state.activeMicroScanId ?? sessionId ?? _newSessionId())
          : (sessionId ?? _newSessionId()),
      activeMicroScanQuestionIds: ids,
      activeMicroScanIndex:
          sameSession && firstUnansweredIndex >= 0 ? firstUnansweredIndex : 0,
    );
    await _persistence.saveForUid(uid: uid, state: next);
    return next;
  }

  /// Replacing an answer for the same question does not double-count.
  /// Completing a micro-scan starts the Activity proactive nudge cooldown.
  Future<RelationshipAnalysisState> submitAnswer({
    required String uid,
    required RelationshipAnalysisState state,
    required String questionId,
    required String optionId,
  }) async {
    final bank = await loadBank();
    final question = bank.byId[questionId];
    if (question == null) {
      throw StateError('Unknown relationship question: $questionId');
    }
    if (!question.options.any((o) => o.id == optionId)) {
      throw StateError('Unknown option $optionId for $questionId');
    }

    final latest = await loadState(uid);
    final latestIds = latest.activeMicroScanQuestionIds;
    final latestIndex = latest.activeMicroScanIndex;

    final isCurrentQuestion = latestIndex >= 0 &&
        latestIndex < latestIds.length &&
        latestIds[latestIndex] == questionId;

    if (state.activeMicroScanId == null ||
        latest.activeMicroScanId != state.activeMicroScanId ||
        !isCurrentQuestion) {
      throw StateError(
        'Relationship Analysis session changed. Reopen the scan.',
      );
    }

    final answers = Map<String, String>.from(latest.answersByQuestionId);
    answers[questionId] = optionId;

    final snapshot = _scorer.score(
      bank: bank,
      answersByQuestionId: answers,
    );

    final scanIds = List<String>.from(latestIds);
    var index = latest.activeMicroScanIndex;
    final pos = scanIds.indexOf(questionId);
    if (pos >= 0 && pos >= index) {
      index = (pos + 1).clamp(0, scanIds.length);
    }

    final scanComplete =
        scanIds.isNotEmpty && scanIds.every(answers.containsKey);

    final next = latest.copyWith(
      answersByQuestionId: answers,
      dimensionScores: snapshot.dimensionScores,
      dimensionEvidenceCounts: snapshot.dimensionEvidenceCounts,
      dimensionRawSignedEvidence: snapshot.dimensionRawSignedEvidence,
      analysisDepth: snapshot.analysisDepth,
      activeMicroScanIndex: scanComplete ? scanIds.length : index,
      clearActiveMicroScan: scanComplete,
      proactiveNudgeSuppressUntil: scanComplete
          ? _clock()
              .toUtc()
              .add(RelationshipAnalysisContract.proactiveNudgeCooldown)
          : null,
    );

    await _persistence.saveForUid(uid: uid, state: next);
    return next;
  }

  String _newSessionId() => 'ra_${_clock().toUtc().millisecondsSinceEpoch}';
}
