import 'relationship_bank_models.dart';
import 'relationship_dimensions.dart';

class RelationshipMicroScanSelector {
  const RelationshipMicroScanSelector();

  List<String> selectOrResume({
    required RelationshipAnalysisBank bank,
    required Set<String> answeredQuestionIds,
    required Map<String, int> dimensionEvidenceCounts,
    List<String>? activeQuestionIds,
    int size = RelationshipAnalysisContract.microScanSize,
  }) {
    if (size <= 0) return const [];

    if (activeQuestionIds != null && activeQuestionIds.isNotEmpty) {
      final valid = <String>[];
      final byId = bank.byId;
      for (final id in activeQuestionIds) {
        if (!byId.containsKey(id)) continue;
        if (answeredQuestionIds.contains(id)) continue;
        valid.add(id);
      }
      if (valid.isNotEmpty) {
        return List.unmodifiable(valid.take(size));
      }
    }

    return selectNext(
      bank: bank,
      answeredQuestionIds: answeredQuestionIds,
      dimensionEvidenceCounts: dimensionEvidenceCounts,
      size: size,
    );
  }

  List<String> selectNext({
    required RelationshipAnalysisBank bank,
    required Set<String> answeredQuestionIds,
    required Map<String, int> dimensionEvidenceCounts,
    int size = RelationshipAnalysisContract.microScanSize,
  }) {
    final unanswered = bank.items
        .where((q) => !answeredQuestionIds.contains(q.id))
        .toList(growable: false);
    if (unanswered.isEmpty) return const [];

    int evidenceFor(String dim) => dimensionEvidenceCounts[dim] ?? 0;

    double underMeasurementScore(RelationshipQuestion q) {
      final dims = <String>{};
      for (final o in q.options) {
        dims.addAll(o.dimensionDeltas.keys);
      }
      if (dims.isEmpty) return 0.0;
      var score = 0.0;
      var n = 0;
      for (final d in dims) {
        if (!RelationshipDimensionIds.allSet.contains(d)) continue;
        score += 1.0 / (1 + evidenceFor(d));
        n += 1;
      }
      if (n == 0) return 0.0;
      return score / n;
    }

    final ranked = [...unanswered]..sort((a, b) {
        final byScore =
            underMeasurementScore(b).compareTo(underMeasurementScore(a));
        if (byScore != 0) return byScore;
        return a.id.compareTo(b.id);
      });

    return List.unmodifiable(
      ranked.take(size).map((q) => q.id).toList(growable: false),
    );
  }
}
