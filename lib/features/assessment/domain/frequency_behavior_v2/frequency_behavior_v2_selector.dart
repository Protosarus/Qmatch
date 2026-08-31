import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';
import 'frequency_behavior_v2_rng.dart';

/// Dormant 50-of-405 Frequency V2 session composer.
///
/// Not wired to live Frequency routing. Does not read age, profession,
/// location, gender, previous answers, personality estimates, behavioral
/// vectors, or response speed. Evidence scores and weight magnitudes are
/// not pick keys. Semantic-cluster mix is a bounded lookahead preference,
/// not a hard quota.
class FrequencyBehaviorV2SessionComposer {
  const FrequencyBehaviorV2SessionComposer();

  static const int perDimensionQuota =
      FrequencyBehaviorV2Contract.sessionBasePerDimension;
  static const int flexSlots = FrequencyBehaviorV2Contract.sessionFlexSlots;

  List<FrequencyBehaviorV2SessionItemPlan> compose({
    required FrequencyBehaviorV2PoolDocument pool,
    required String sessionSeed,
    Map<String, Map<String, dynamic>> reviewByItemId = const {},
    List<List<String>> nearDuplicateClusters = const [],
    bool excludeUnresolvedReview = true,
    String? sessionId,
    String? createdAt,
  }) {
    return composeManifest(
      pool: pool,
      sessionSeed: sessionSeed,
      reviewByItemId: reviewByItemId,
      nearDuplicateClusters: nearDuplicateClusters,
      excludeUnresolvedReview: excludeUnresolvedReview,
      sessionId: sessionId,
      createdAt: createdAt,
    ).itemPlans;
  }

  FrequencyBehaviorV2SessionManifest composeManifest({
    required FrequencyBehaviorV2PoolDocument pool,
    required String sessionSeed,
    Map<String, Map<String, dynamic>> reviewByItemId = const {},
    List<List<String>> nearDuplicateClusters = const [],
    bool excludeUnresolvedReview = true,
    String? sessionId,
    String? createdAt,
  }) {
    final selectorVersion = FrequencyBehaviorV2Contract.selectorVersion;
    final bankVersion = pool.poolVersion;
    final eligible = <FrequencyBehaviorV2Item>[
      for (final item in pool.items)
        if (!excludeUnresolvedReview || _isSelectable(item, reviewByItemId))
          item,
    ];
    final byId = {for (final i in eligible) i.itemId: i};
    final nearDupIndex =
        _nearDupIndex(nearDuplicateClusters, byId.keys.toSet());

    final extraRng = FrequencyBehaviorV2Rng.forStream(
      selectorVersion: selectorVersion,
      bankVersion: bankVersion,
      sessionSeed: sessionSeed,
      stream: 'extra_slots',
    );
    final extraOrder = extraRng.shuffledCopy(
      FrequencyBehaviorV2Contract.canonicalDimensions,
    );
    final extraDims = <String>{extraOrder[0], extraOrder[1]};

    final pickedByDim = <String, List<FrequencyBehaviorV2Item>>{};
    final usedNearDup = <int>{};

    for (final dim in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final quota =
          extraDims.contains(dim) ? perDimensionQuota + 1 : perDimensionQuota;
      final ranked = [
        for (final item in eligible)
          if (item.primaryDimensions.single == dim) item,
      ];
      ranked.sort((a, b) {
        final ra = _candidateRank(
          selectorVersion: selectorVersion,
          bankVersion: bankVersion,
          sessionSeed: sessionSeed,
          dimension: dim,
          questionId: a.itemId,
        );
        final rb = _candidateRank(
          selectorVersion: selectorVersion,
          bankVersion: bankVersion,
          sessionSeed: sessionSeed,
          dimension: dim,
          questionId: b.itemId,
        );
        if (ra != rb) return ra.compareTo(rb);
        return a.itemId.compareTo(b.itemId);
      });
      if (ranked.length < quota) {
        throw StateError(
          'insufficient_candidates:$dim have=${ranked.length} need=$quota',
        );
      }
      final lookahead = FrequencyBehaviorV2Contract.softClusterLookahead;
      final picked = <FrequencyBehaviorV2Item>[];
      final clusterCounts = <String, int>{};
      final pickedSet = <String>{};

      bool nearDupBlocked(FrequencyBehaviorV2Item c) {
        final nd = nearDupIndex[c.itemId];
        return nd != null && usedNearDup.contains(nd);
      }

      void absorb(FrequencyBehaviorV2Item c) {
        pickedSet.add(c.itemId);
        picked.add(c);
        clusterCounts[c.semanticCluster] =
            (clusterCounts[c.semanticCluster] ?? 0) + 1;
        final nd = nearDupIndex[c.itemId];
        if (nd != null) usedNearDup.add(nd);
      }

      // Seed rank is primary. Repeating a cluster only prefers another
      // unused cluster inside a short lookahead; it never scans the bank
      // to satisfy a diversity quota.
      while (picked.length < quota) {
        final remaining = [
          for (final c in ranked)
            if (!pickedSet.contains(c.itemId) && !nearDupBlocked(c)) c,
        ];
        if (remaining.isEmpty) {
          throw StateError(
            'underfilled:$dim have=${picked.length} need=$quota',
          );
        }
        final head = remaining.first;
        var chosen = head;
        if ((clusterCounts[head.semanticCluster] ?? 0) > 0) {
          final altLimit = lookahead < remaining.length - 1
              ? lookahead
              : remaining.length - 1;
          for (var i = 1; i <= altLimit; i++) {
            final alt = remaining[i];
            if ((clusterCounts[alt.semanticCluster] ?? 0) == 0) {
              chosen = alt;
              break;
            }
          }
        }
        absorb(chosen);
      }
      pickedByDim[dim] = picked;
    }

    final queues = <String, List<FrequencyBehaviorV2Item>>{};
    for (final dim in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final qRng = FrequencyBehaviorV2Rng.forStream(
        selectorVersion: selectorVersion,
        bankVersion: bankVersion,
        sessionSeed: sessionSeed,
        stream: 'queue|$dim',
      );
      queues[dim] = qRng.shuffledCopy(pickedByDim[dim]!);
    }

    final interleaveRng = FrequencyBehaviorV2Rng.forStream(
      selectorVersion: selectorVersion,
      bankVersion: bankVersion,
      sessionSeed: sessionSeed,
      stream: 'interleave_order',
    );
    final dimOrder = interleaveRng.shuffledCopy(
      FrequencyBehaviorV2Contract.canonicalDimensions,
    );

    final sequence = <FrequencyBehaviorV2Item>[];
    for (var round = 0; round < perDimensionQuota; round++) {
      for (final dim in dimOrder) {
        sequence.add(queues[dim]!.removeAt(0));
      }
    }
    final extras = <FrequencyBehaviorV2Item>[];
    for (final dim in dimOrder) {
      extras.addAll(queues[dim]!);
    }
    for (final extra in extras) {
      _insertExtra(sequence, extra);
    }
    _softenAdjacentFamilies(sequence);

    if (sequence.length != FrequencyBehaviorV2Contract.sessionItemCount) {
      throw StateError('session_length_${sequence.length}');
    }
    if (!_consecutivePrimaryOk(sequence)) {
      throw StateError('consecutive_primary_violation');
    }

    final derivedId = sessionId ??
        'frequency_v2_${FrequencyBehaviorV2Rng.fnv1a32('$selectorVersion|$bankVersion|$sessionSeed').toRadixString(16).padLeft(8, '0')}';

    final questions = <FrequencyBehaviorV2SessionQuestion>[];
    for (var i = 0; i < sequence.length; i++) {
      final item = sequence[i];
      final optRng = FrequencyBehaviorV2Rng.forStream(
        selectorVersion: selectorVersion,
        bankVersion: bankVersion,
        sessionSeed: sessionSeed,
        stream: 'options|${item.itemId}',
      );
      final authored = [for (final o in item.options) o.optionId];
      final presented = optRng.shuffledCopy(authored);
      questions.add(
        FrequencyBehaviorV2SessionQuestion(
          questionId: item.itemId,
          primaryDimension: item.primaryDimensions.single,
          presentationIndex: i,
          presentedOptionOrder: presented,
        ),
      );
    }

    return FrequencyBehaviorV2SessionManifest(
      schemaVersion: FrequencyBehaviorV2Contract.sessionManifestSchemaVersion,
      selectorVersion: selectorVersion,
      bankVersion: bankVersion,
      sessionId: derivedId,
      sessionSeed: sessionSeed,
      locale: pool.locale,
      createdAt: createdAt,
      questionIds: [for (final q in questions) q.questionId],
      questions: questions,
    );
  }

  static int _candidateRank({
    required String selectorVersion,
    required String bankVersion,
    required String sessionSeed,
    required String dimension,
    required String questionId,
  }) {
    return FrequencyBehaviorV2Rng.fromParts([
      selectorVersion,
      bankVersion,
      sessionSeed,
      dimension,
      questionId,
    ]).nextUint32();
  }

  static Map<String, int> _nearDupIndex(
    List<List<String>> clusters,
    Set<String> eligibleIds,
  ) {
    final out = <String, int>{};
    for (var i = 0; i < clusters.length; i++) {
      final members = [
        for (final id in clusters[i])
          if (eligibleIds.contains(id)) id,
      ];
      if (members.length < 2) continue;
      for (final id in members) {
        out.putIfAbsent(id, () => i);
      }
    }
    return out;
  }

  static bool _keyGreater(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static String _contextFamily(FrequencyBehaviorV2Item item) {
    if (item.context.isEmpty) return 'unclassified';
    return item.context.first;
  }

  static String? _thematicTag(FrequencyBehaviorV2Item item) {
    final text = '${item.prompt} ${item.semanticCluster}'.toLowerCase();
    if (RegExp(r'aile|anne|baba|kayın|çocuk|cocuk').hasMatch(text)) {
      return 'family';
    }
    if (RegExp(r'para|fatura|hesap|ödeme|odeme|borç|borc').hasMatch(text)) {
      return 'payment';
    }
    if (item.context.contains('conflict') ||
        item.semanticCluster.contains('conflict')) {
      return 'conflict';
    }
    return null;
  }

  static void _insertExtra(
    List<FrequencyBehaviorV2Item> sequence,
    FrequencyBehaviorV2Item extra,
  ) {
    List<int>? bestKey;
    var bestPos = -1;
    for (var pos = 0; pos <= sequence.length; pos++) {
      if (_runLengthIfInsert(sequence, pos, extra) >
          FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary) {
        continue;
      }
      final prev = pos == 0 ? null : sequence[pos - 1];
      final next = pos == sequence.length ? null : sequence[pos];
      final key = [
        _neighborDimOk(prev, extra) ? 1 : 0,
        _neighborDimOk(next, extra) ? 1 : 0,
        _neighborContextOk(prev, extra) ? 1 : 0,
        _neighborContextOk(next, extra) ? 1 : 0,
        _neighborClusterOk(prev, extra) ? 1 : 0,
        _neighborClusterOk(next, extra) ? 1 : 0,
      ];
      if (bestKey == null || _keyGreater(key, bestKey)) {
        bestKey = key;
        bestPos = pos;
      }
    }
    if (bestPos < 0) {
      throw StateError('no_valid_extra_insert_pos:${extra.itemId}');
    }
    sequence.insert(bestPos, extra);
  }

  static bool _neighborDimOk(
    FrequencyBehaviorV2Item? neighbor,
    FrequencyBehaviorV2Item extra,
  ) {
    if (neighbor == null) return true;
    return neighbor.primaryDimensions.single != extra.primaryDimensions.single;
  }

  static bool _neighborContextOk(
    FrequencyBehaviorV2Item? neighbor,
    FrequencyBehaviorV2Item extra,
  ) {
    if (neighbor == null) return true;
    return _contextFamily(neighbor) != _contextFamily(extra);
  }

  static bool _neighborClusterOk(
    FrequencyBehaviorV2Item? neighbor,
    FrequencyBehaviorV2Item extra,
  ) {
    if (neighbor == null) return true;
    return neighbor.semanticCluster != extra.semanticCluster;
  }

  static int _runLengthIfInsert(
    List<FrequencyBehaviorV2Item> sequence,
    int pos,
    FrequencyBehaviorV2Item extra,
  ) {
    final dim = extra.primaryDimensions.single;
    var run = 1;
    for (var i = pos - 1; i >= 0; i--) {
      if (sequence[i].primaryDimensions.single != dim) break;
      run++;
    }
    for (var i = pos; i < sequence.length; i++) {
      if (sequence[i].primaryDimensions.single != dim) break;
      run++;
    }
    return run;
  }

  static void _softenAdjacentFamilies(List<FrequencyBehaviorV2Item> sequence) {
    for (var i = 1; i < sequence.length; i++) {
      if (!_similarFamily(sequence[i - 1], sequence[i])) continue;
      for (var j = i + 1; j < sequence.length; j++) {
        _swap(sequence, i, j);
        final improved = _consecutivePrimaryOk(sequence) &&
            !_similarFamily(sequence[i - 1], sequence[i]);
        if (improved) break;
        _swap(sequence, i, j);
      }
    }
  }

  static bool _similarFamily(
    FrequencyBehaviorV2Item a,
    FrequencyBehaviorV2Item b,
  ) {
    if (a.semanticCluster == b.semanticCluster) return true;
    final ta = _thematicTag(a);
    final tb = _thematicTag(b);
    return ta != null && ta == tb;
  }

  static void _swap(List<FrequencyBehaviorV2Item> sequence, int i, int j) {
    final tmp = sequence[i];
    sequence[i] = sequence[j];
    sequence[j] = tmp;
  }

  static bool _consecutivePrimaryOk(List<FrequencyBehaviorV2Item> sequence) {
    var run = 1;
    for (var i = 1; i < sequence.length; i++) {
      if (sequence[i].primaryDimensions.single ==
          sequence[i - 1].primaryDimensions.single) {
        run++;
        if (run > FrequencyBehaviorV2Contract.maxConsecutiveSamePrimary) {
          return false;
        }
      } else {
        run = 1;
      }
    }
    return true;
  }

  bool _isSelectable(
    FrequencyBehaviorV2Item item,
    Map<String, Map<String, dynamic>> reviewByItemId,
  ) {
    if (item.primaryDimensions.length != 1) return false;
    if (!FrequencyBehaviorV2Contract.isCanonicalDimension(
      item.primaryDimensions.single,
    )) {
      return false;
    }
    final review = reviewByItemId[item.itemId];
    if (review != null) {
      if (review['selector_eligible'] != true) return false;
      if (review['rewrite_pending'] == true) return false;
      if (review['drop_from_selectable'] == true) return false;
      if (review['processing_style_present'] == true) return false;
      if (review['primary_review_pending'] == true) return false;
      final unresolved = review['unresolved_dimension_labels'];
      if (unresolved is List && unresolved.isNotEmpty) return false;
      final status = review['review_status']?.toString();
      if (status == 'manual_review' ||
          status == 'rewrite_pending' ||
          status == 'dropped_from_selectable') {
        return false;
      }
    }
    return item.options.every((o) => o.behavioralWeights.isNotEmpty);
  }
}
