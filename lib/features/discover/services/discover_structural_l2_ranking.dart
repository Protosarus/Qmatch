import '../models/discover_user_model.dart';
import 'discover_stage_b2_dual_path_collector.dart';

/// Ranks an already-filtered L1 Discover batch from trusted L2 pairs.
///
/// Live ranking uses Frequency V2 fusion when available.
///
/// Smaller fusion distance (`1 - compatibility_index/100`) is better.
/// Pairs without a valid V2 fusion fall back to IQ+EQ
/// [DiscoverStageB2TrustedPairResult.structuralDistance].
/// V1 Frequency is never an input. Missing V2 does not crash or fabricate.
class DiscoverStructuralL2Ranking {
  DiscoverStructuralL2Ranking._();

  static const String modeWireValue = 'compatibility_fusion_v2';
  static const String structuralFallbackModeWireValue = 'structural_l2_v1';
  static const String fusionPolicyVersion =
      'qmatch_compatibility_fusion_v2_policy_v1';

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
      return compareFusion(
        aUid: a.uid,
        bUid: b.uid,
        aFusionDistance: pa?.fusionRankDistance,
        bFusionDistance: pb?.fusionRankDistance,
        aStructuralRankable: pa?.isRankable ?? false,
        bStructuralRankable: pb?.isRankable ?? false,
        aStructuralDistance: pa?.structuralDistance,
        bStructuralDistance: pb?.structuralDistance,
        aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
        bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
      );
    });
    return ranked;
  }

  /// Trusted candidate membership for both ranking modes.
  ///
  /// Callable failure fail-closes (empty). Success drops UIDs omitted by
  /// `candidate_uids`. Does not change L2 distance or legacy score formulas.
  static List<DiscoverUserModel> applyTrustedMembership({
    required List<DiscoverUserModel> candidates,
    required bool callableFailed,
    required Iterable<String> returnedUids,
  }) {
    if (callableFailed) return const <DiscoverUserModel>[];
    return dropOmittedUids(
      candidates: candidates,
      returnedUids: returnedUids,
    );
  }

  /// Drop UIDs omitted by the trusted callable (reverse-blocked).
  /// Membership filter only — does not change L2 distance order.
  static List<DiscoverUserModel> dropOmittedUids({
    required List<DiscoverUserModel> candidates,
    required Iterable<String> returnedUids,
  }) {
    final keep = returnedUids.toSet();
    return [
      for (final c in candidates)
        if (keep.contains(c.uid)) c
    ];
  }

  static int compareFusion({
    required String aUid,
    required String bUid,
    required double? aFusionDistance,
    required double? bFusionDistance,
    required bool aStructuralRankable,
    required bool bStructuralRankable,
    required double? aStructuralDistance,
    required double? bStructuralDistance,
    required int aLastActiveMs,
    required int bLastActiveMs,
  }) {
    final aKey = _rankKey(
      fusionDistance: aFusionDistance,
      structuralRankable: aStructuralRankable,
      structuralDistance: aStructuralDistance,
    );
    final bKey = _rankKey(
      fusionDistance: bFusionDistance,
      structuralRankable: bStructuralRankable,
      structuralDistance: bStructuralDistance,
    );
    final aOk = aKey != null;
    final bOk = bKey != null;
    if (aOk != bOk) return aOk ? -1 : 1;
    if (aOk && bOk) {
      final byKey = aKey.compareTo(bKey);
      if (byKey != 0) return byKey;
    }
    final byRecency = bLastActiveMs.compareTo(aLastActiveMs);
    if (byRecency != 0) return byRecency;
    return aUid.compareTo(bUid);
  }

  static double? _rankKey({
    required double? fusionDistance,
    required bool structuralRankable,
    required double? structuralDistance,
  }) {
    if (fusionDistance != null &&
        !fusionDistance.isNaN &&
        !fusionDistance.isInfinite &&
        fusionDistance >= 0) {
      return fusionDistance;
    }
    if (_rankableDistance(structuralRankable, structuralDistance)) {
      return structuralDistance;
    }
    return null;
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
