/// Explicit reverse-pair consistency semantics for RVI only.
///
/// Trait scoring never uses these descriptors to invert or alter deltas.
/// Modes must be declared; they are never inferred from wording or option
/// letter position.
enum ReversePairConsistencyMode {
  /// Consistency when selected options yield opposite primary-delta signs.
  oppositeTraitSign,

  /// Consistency when selected options yield the same primary-delta sign
  /// (behaviorally keyed reverse scenarios).
  behavioralCorrespondence,

  /// Consistency when selected option IDs match an explicit correspondence map.
  explicitOptionMapping,
}

/// Form/session-level reverse-pair metadata (module-neutral).
class ReversePairDescriptor {
  final String pairId;
  final List<String> questionIds;
  final ReversePairConsistencyMode consistencyMode;

  /// For [ReversePairConsistencyMode.explicitOptionMapping] only.
  ///
  /// Keys are `"$questionIdA::$optionIdA"` and values are the corresponding
  /// option ID on the other member. Bidirectional lookup is supported by also
  /// storing the reverse mapping, or by matching either direction at eval time.
  final Map<String, String> optionCorrespondence;

  const ReversePairDescriptor({
    required this.pairId,
    required this.questionIds,
    required this.consistencyMode,
    this.optionCorrespondence = const {},
  });

  static ReversePairConsistencyMode? parseMode(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'opposite_trait_sign':
        return ReversePairConsistencyMode.oppositeTraitSign;
      case 'behavioral_correspondence':
        return ReversePairConsistencyMode.behavioralCorrespondence;
      case 'explicit_option_mapping':
        return ReversePairConsistencyMode.explicitOptionMapping;
      default:
        return null;
    }
  }

  static String modeWireName(ReversePairConsistencyMode mode) {
    switch (mode) {
      case ReversePairConsistencyMode.oppositeTraitSign:
        return 'opposite_trait_sign';
      case ReversePairConsistencyMode.behavioralCorrespondence:
        return 'behavioral_correspondence';
      case ReversePairConsistencyMode.explicitOptionMapping:
        return 'explicit_option_mapping';
    }
  }

  /// Parse descriptors from a form-level `pair_registry.reverse_pairs` list.
  ///
  /// Entries without a recognized `consistency_mode` are skipped (caller treats
  /// those pairs as metadata-unavailable for RVI).
  static List<ReversePairDescriptor> parseRegistry(Object? rawPairs) {
    if (rawPairs is! List) return const [];
    final out = <ReversePairDescriptor>[];
    for (final entry in rawPairs) {
      if (entry is! Map) continue;
      final m = Map<String, dynamic>.from(entry);
      final pairId = m['pair_id']?.toString() ?? '';
      final qids = [
        for (final q in (m['question_ids'] as List?) ?? const []) q.toString(),
      ];
      final mode = parseMode(m['consistency_mode']?.toString());
      if (pairId.isEmpty || qids.length < 2 || mode == null) continue;
      final corr = <String, String>{};
      final rawCorr = m['option_correspondence'];
      if (rawCorr is Map) {
        for (final e in rawCorr.entries) {
          corr[e.key.toString()] = e.value.toString();
        }
      }
      out.add(
        ReversePairDescriptor(
          pairId: pairId,
          questionIds: qids,
          consistencyMode: mode,
          optionCorrespondence: corr,
        ),
      );
    }
    return out;
  }
}
