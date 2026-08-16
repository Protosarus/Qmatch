import '../models/discover_user_model.dart';
import 'discover_stage_b2_dual_path_collector.dart';

/// Ranks an already-filtered L1 Discover batch from trusted L2 pairs.
///
/// Smaller [DiscoverStageB2TrustedPairResult.structuralDistance] is better.
/// Missing or failed L2 is never coerced to a neutral fill score.
/// Persona, RVI, and later matching layers are not inputs.
class DiscoverStructuralL2Ranking {
  DiscoverStructuralL2Ranking._();

  static const String modeWireValue = 'structural_l2_v1';

  static Map<String, DiscoverStageB2TrustedPairResult> pairsByUid({
    required List<String> candidateUids,
    required List<DiscoverStageB2TrustedPairResult> pairs,
  }) {
    final map = <String, DiscoverStageB2TrustedPairResult>{};
    for (var i = 0; i < candidateUids.length; i++) {
      map[candidateUids[i]] = i < pairs.length
          ? pairs[i]
          : DiscoverStageB2TrustedPairResult.unavailable(
              'trusted_l2_callable_failed',
            );
    }
    return map;
  }

  /// Same L1 membership; order only. Never drops unavailable L2 pairs.
  static List<DiscoverUserModel> rankL1Batch({
    required List<DiscoverUserModel> l1Eligible,
    required Map<String, DiscoverStageB2TrustedPairResult> pairsByUid,
  }) {
    final ranked = List<DiscoverUserModel>.of(l1Eligible);
    ranked.sort((a, b) {
      final pa = pairsByUid[a.uid];
      final pb = pairsByUid[b.uid];
      return compare(
        aUid: a.uid,
        bUid: b.uid,
        aRankable: pa?.isRankable ?? false,
        bRankable: pb?.isRankable ?? false,
        aDistance: pa?.structuralDistance,
        bDistance: pb?.structuralDistance,
        aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
        bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
      );
    });
    return ranked;
  }

  static int compare({
    required String aUid,
    required String bUid,
    required bool aRankable,
    required bool bRankable,
    required double? aDistance,
    required double? bDistance,
    required int aLastActiveMs,
    required int bLastActiveMs,
  }) {
    final aOk = _rankableDistance(aRankable, aDistance);
    final bOk = _rankableDistance(bRankable, bDistance);
    if (aOk != bOk) return aOk ? -1 : 1;
    if (aOk && bOk) {
      final byDistance = aDistance!.compareTo(bDistance!);
      if (byDistance != 0) return byDistance;
    }
    final byRecency = bLastActiveMs.compareTo(aLastActiveMs);
    if (byRecency != 0) return byRecency;
    return aUid.compareTo(bUid);
  }

  static bool _rankableDistance(bool flagged, double? distance) {
    if (!flagged || distance == null) return false;
    if (distance.isNaN || distance.isInfinite) return false;
    if (distance < 0) return false;
    return true;
  }
}
