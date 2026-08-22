import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../domain/who_liked_you_card.dart';

/// Client for trusted `listWhoLikedYouEu` (europe-west1).
///
/// Identities come only from a `resonance_access == true` payload.
/// Extra fields on cards are dropped. Forged / missing access → locked.
/// US `listWhoLikedYou` remains deployed for zero-downtime; this client
/// does not call it.
class WhoLikedYouClient {
  WhoLikedYouClient({
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

  static const String region = 'europe-west1';
  static const String callableName = 'listWhoLikedYouEu';

  Future<WhoLikedYouResult> list() async {
    final raw = await QmatchPerf.trace(
      'alignment_signals.listWhoLikedYou_callable',
      () => _invoke(const {}),
    );
    return QmatchPerf.traceSync('alignment_signals.card_enrichment_parse', () {
      if (raw['resonance_access'] != true) {
        return WhoLikedYouResult.locked;
      }

      final itemsRaw = raw['items'];
      if (itemsRaw is! List) {
        return const WhoLikedYouResult(resonanceAccess: true, items: []);
      }

      final items = <WhoLikedYouCard>[];
      final seen = <String>{};
      for (final row in itemsRaw) {
        final card = WhoLikedYouCard.fromPublicMap(row);
        if (card == null || !seen.add(card.uid)) continue;
        items.add(card);
      }
      return WhoLikedYouResult(resonanceAccess: true, items: items);
    });
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> data) async {
    final custom = _call;
    if (custom != null) return custom(callableName, data);
    final functions =
        _functions ?? FirebaseFunctions.instanceFor(region: region);
    final result = await functions.httpsCallable(callableName).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Callable $callableName returned a non-map payload.');
  }
}
