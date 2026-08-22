import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../domain/who_liked_you_card.dart';

/// Client for trusted `listSuperResonanceInboxEu` (europe-west1).
///
/// Visible to Free and Resonance. Ordinary likes are never included.
/// Extra / private fields on cards are dropped.
/// US `listSuperResonanceInbox` remains deployed for zero-downtime; this
/// client does not call it.
class SuperResonanceInboxClient {
  SuperResonanceInboxClient({
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
  static const String callableName = 'listSuperResonanceInboxEu';

  Future<List<WhoLikedYouCard>> list() async {
    final raw = await QmatchPerf.trace(
      'alignment_signals.listSuperResonanceInbox_callable',
      () => _invoke(const {}),
    );
    return QmatchPerf.traceSync('alignment_signals.sr_card_enrichment_parse', () {
      final itemsRaw = raw['items'];
      if (itemsRaw is! List) return const <WhoLikedYouCard>[];

      final items = <WhoLikedYouCard>[];
      final seen = <String>{};
      for (final row in itemsRaw) {
        final parsed = WhoLikedYouCard.fromPublicMap(row);
        if (parsed == null || !seen.add(parsed.uid)) continue;
        items.add(parsed.copyWith(superResonance: true));
      }
      return List<WhoLikedYouCard>.unmodifiable(items);
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
