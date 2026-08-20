import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/debug/qmatch_perf.dart';
import 'discover_stage_b2_dual_path_collector.dart';
import 'discover_structural_l2_ranking.dart';

/// Calls trusted Stage B2 L2.
///
/// Supplies L1 Discover candidate UIDs only. Does not read peer canonical_v1
/// or peer block docs. Production ranking (`structural_l2_v1`) uses the
/// returned distances; `legacy_v1` uses CompatibilityScoring for order only
/// after this membership filter. Reverse-blocked UIDs are omitted from
/// [DiscoverStageB2TrustedBatch.returnedUids]. Callable failure must
/// fail-close — never show the unverified L1 batch.
///
/// Release/default uses [euCallableName] in [euRegion] via
/// [FirebaseFunctions.instanceFor]. Debug/internal may roll back to
/// [callableName] in [usRegion] via [useUsCentral1], [debugUseUsCentral1],
/// or `--dart-define=QMATCH_DISCOVER_L2_US=true`.
class DiscoverStageB2TrustedL2Client {
  DiscoverStageB2TrustedL2Client({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
    bool useUsCentral1 = false,
  })  : _functions = functions,
        _call = call,
        _useUsCentral1 = useUsCentral1;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;
  final bool _useUsCentral1;

  /// US rollback callable. Production does not use this by default.
  static const String callableName = 'compareStageB2Structural';
  static const String euCallableName = 'compareStageB2StructuralEu';
  static const String usRegion = 'us-central1';
  static const String euRegion = 'europe-west1';

  static const bool _usFromDefine = bool.fromEnvironment(
    'QMATCH_DISCOVER_L2_US',
    defaultValue: false,
  );

  /// Debug/internal runtime rollback to us-central1. Ignored in release.
  static bool debugUseUsCentral1 = false;

  /// Production/default is Europe. US only when an explicit debug rollback is on.
  bool get usesEuropeWest1 {
    if (!kDebugMode) return true;
    if (_useUsCentral1 || debugUseUsCentral1 || _usFromDefine) return false;
    return true;
  }

  String get resolvedCallableName =>
      usesEuropeWest1 ? euCallableName : callableName;

  String get resolvedRegion => usesEuropeWest1 ? euRegion : usRegion;

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
    final useEu = usesEuropeWest1;
    final name = useEu ? euCallableName : callableName;
    final region = useEu ? euRegion : usRegion;
    final traceName = useEu ? 'discover.l2_eu' : 'discover.l2_us';
    return QmatchPerf.trace(traceName, () async {
      final custom = _call;
      if (custom != null) return custom(name, data);
      final functions =
          _functions ?? FirebaseFunctions.instanceFor(region: region);
      final result = await functions.httpsCallable(name).call(data);
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      throw StateError('Callable $name returned a non-map payload.');
    });
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
