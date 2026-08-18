import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/super_resonance_send_result.dart';

/// Client for trusted `sendSuperResonance`. Never writes peer/signal docs.
class SuperResonanceSendClient {
  SuperResonanceSendClient({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
    String Function()? requestIdFactory,
  })  : _functions = functions,
        _call = call,
        _requestIdFactory = requestIdFactory;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;
  final String Function()? _requestIdFactory;

  static const String callableName = 'sendSuperResonance';

  String newRequestId() {
    final custom = _requestIdFactory;
    if (custom != null) return custom();
    return createSuperResonanceRequestId();
  }

  Future<SuperResonanceSendResult> send({
    required String targetUid,
    String? requestId,
  }) async {
    final id = (requestId == null || requestId.trim().isEmpty)
        ? newRequestId()
        : requestId.trim();
    final raw = await _invoke({
      'target_uid': targetUid,
      'request_id': id,
    });
    final parsed = SuperResonanceSendResult.fromPublicMap(raw);
    if (parsed == null) {
      throw StateError('Callable $callableName returned an invalid payload.');
    }
    return parsed;
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

String createSuperResonanceRequestId([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String h(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-'
      '${h(6)}${h(7)}-${h(8)}${h(9)}-'
      '${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}
