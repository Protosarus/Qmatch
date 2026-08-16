import 'package:cloud_functions/cloud_functions.dart';

import 'discover_stage_b2_dual_path_collector.dart';
import 'discover_structural_l2_ranking.dart';

/// Calls trusted Stage B2 L2 (`compareStageB2Structural`).
///
/// Supplies L1 Discover candidate UIDs only. Does not read peer canonical_v1
/// or peer block docs. Production ranking (`structural_l2_v1`) uses the
/// returned distances; `legacy_v1` uses CompatibilityScoring for order only
/// after this membership filter. Reverse-blocked UIDs are omitted from
/// [DiscoverStageB2TrustedBatch.returnedUids]. Callable failure must
/// fail-close — never show the unverified L1 batch.
class DiscoverStageB2TrustedL2Client {
  DiscoverStageB2TrustedL2Client({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
  })  : _functions = functions,
        _call = call;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  static const String callableName = 'compareStageB2Structural';

  Future<DiscoverStageB2TrustedBatch> compareForL1Batch({
    required List<String> candidateUids,
  }) async {
    final raw = await _invoke({
      'candidate_uids': candidateUids,
    });
    final pairsRaw = raw['pairs'];
    if (pairsRaw is! List) {
      return DiscoverStageB2TrustedBatch.callableFailed(candidateUids);
    }

    final returnedUids = _parseReturnedUids(
      raw['candidate_uids'],
      fallback: candidateUids,
    );
    final pairs = <DiscoverStageB2TrustedPairResult>[
      for (var i = 0; i < returnedUids.length; i++)
        i < pairsRaw.length
            ? DiscoverStageB2TrustedPairResult.fromPublicMap(pairsRaw[i])
            : DiscoverStageB2TrustedPairResult.unavailable(
                'trusted_l2_callable_failed',
              ),
    ];
    return DiscoverStageB2TrustedBatch(
      returnedUids: returnedUids,
      pairs: pairs,
      callableFailed: false,
    );
  }

  static List<String> _parseReturnedUids(
    Object? raw, {
    required List<String> fallback,
  }) {
    if (raw is! List) return List<String>.of(fallback);
    final out = <String>[];
    for (final item in raw) {
      if (item is String && item.isNotEmpty) out.add(item);
    }
    return out;
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> data) async {
    final custom = _call;
    if (custom != null) return custom(callableName, data);
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(callableName).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Callable $callableName returned a non-map payload.');
  }
}

/// Included UIDs + pair diagnostics from the trusted L2 callable.
///
/// [returnedUids] omits reverse-blocked candidates. Never carries block docs.
class DiscoverStageB2TrustedBatch {
  const DiscoverStageB2TrustedBatch({
    required this.returnedUids,
    required this.pairs,
    required this.callableFailed,
  });

  factory DiscoverStageB2TrustedBatch.callableFailed(List<String> requested) {
    return DiscoverStageB2TrustedBatch(
      returnedUids: List<String>.of(requested),
      pairs: [
        for (final _ in requested)
          DiscoverStageB2TrustedPairResult.unavailable(
            'trusted_l2_callable_failed',
          ),
      ],
      callableFailed: true,
    );
  }

  final List<String> returnedUids;
  final List<DiscoverStageB2TrustedPairResult> pairs;
  final bool callableFailed;

  Map<String, DiscoverStageB2TrustedPairResult> get pairsByUid =>
      DiscoverStructuralL2Ranking.pairsByUid(
        candidateUids: returnedUids,
        pairs: pairs,
      );
}
