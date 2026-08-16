import 'package:cloud_functions/cloud_functions.dart';

import 'discover_stage_b2_dual_path_collector.dart';

/// Calls trusted Stage B2 L2 (`compareStageB2Structural`).
///
/// Supplies L1 Discover candidate UIDs only. Does not read peer canonical_v1
/// and does not change Discover ranking.
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

  Future<List<DiscoverStageB2TrustedPairResult>> compareForL1Batch({
    required List<String> candidateUids,
  }) async {
    final raw = await _invoke({
      'candidate_uids': candidateUids,
    });
    final pairs = raw['pairs'];
    if (pairs is! List) {
      return [
        for (final _ in candidateUids)
          DiscoverStageB2TrustedPairResult.unavailable(
            'trusted_l2_callable_failed',
          ),
      ];
    }
    return [
      for (var i = 0; i < candidateUids.length; i++)
        i < pairs.length
            ? DiscoverStageB2TrustedPairResult.fromPublicMap(pairs[i])
            : DiscoverStageB2TrustedPairResult.unavailable(
                'trusted_l2_callable_failed',
              ),
    ];
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
