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
  })  : _bankLoader = bankLoader ?? RelationshipBankLoader(),
        _persistence = persistence ?? RelationshipAnalysisPersistence(),
        _scorer = scorer,
        _selector = selector;

  final RelationshipBankLoader _bankLoader;
  final RelationshipAnalysisPersistence _persistence;
  final RelationshipAnalysisScorer _scorer;
  final RelationshipMicroScanSelector _selector;

  Future<RelationshipAnalysisBank> loadBank() => _bankLoader.load();

  Future<RelationshipAnalysisState> loadState(String uid) =>
      _persistence.loadForUid(uid);

  Future<RelationshipAnalysisState> beginMicroScan({
    required String uid,
    required RelationshipAnalysisState state,
    String? sessionId,
  }) async {
    final bank = await loadBank();
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

    final next = state.copyWith(
      activeMicroScanId: sameSession
          ? (state.activeMicroScanId ?? sessionId ?? _newSessionId())
          : (sessionId ?? _newSessionId()),
      activeMicroScanQuestionIds: ids,
      activeMicroScanIndex:
          sameSession ? state.activeMicroScanIndex.clamp(0, ids.length - 1) : 0,
    );
    await _persistence.saveForUid(uid: uid, state: next);
    return next;
  }

  /// Replacing an answer for the same question does not double-count.
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

    final answers = Map<String, String>.from(state.answersByQuestionId);
    answers[questionId] = optionId;

    final snapshot = _scorer.score(
      bank: bank,
      answersByQuestionId: answers,
    );

    final scanIds = List<String>.from(state.activeMicroScanQuestionIds);
    var index = state.activeMicroScanIndex;
    final pos = scanIds.indexOf(questionId);
    if (pos >= 0 && pos >= index) {
      index = (pos + 1).clamp(0, scanIds.length);
    }

    final scanComplete =
        scanIds.isNotEmpty && scanIds.every(answers.containsKey);

    final next = state.copyWith(
      answersByQuestionId: answers,
      dimensionScores: snapshot.dimensionScores,
      dimensionEvidenceCounts: snapshot.dimensionEvidenceCounts,
      dimensionRawSignedEvidence: snapshot.dimensionRawSignedEvidence,
      analysisDepth: snapshot.analysisDepth,
      activeMicroScanIndex: scanComplete ? scanIds.length : index,
      clearActiveMicroScan: scanComplete,
    );

    await _persistence.saveForUid(uid: uid, state: next);
    return next;
  }

  String _newSessionId() =>
      'ra_${DateTime.now().toUtc().millisecondsSinceEpoch}';
}
