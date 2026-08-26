import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/super_resonance_availability.dart';
import '../domain/super_resonance_send_result.dart';

/// Client for trusted Super Resonance send + availability.
/// Never writes peer/signal docs. Never trusts the device clock for remaining.
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

  // Legacy callable contract — preserved for compatibility/test injection.
  static const String callableName = 'sendSuperResonance';
  static const String availabilityCallableName =
      'getSuperResonanceAvailability';

  // Current production endpoints, colocated with Firestore.
  static const String callableNameEu = 'sendSuperResonanceEu';
  static const String availabilityCallableNameEu =
      'getSuperResonanceAvailabilityEu';
  static const String callableRegionEu = 'europe-west1';

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
    final raw = await _invoke(callableName, {
      'target_uid': targetUid,
      'request_id': id,
    });
    final parsed = SuperResonanceSendResult.fromPublicMap(raw);
    if (parsed == null) {
      throw StateError('Callable $callableName returned an invalid payload.');
    }
    return parsed;
  }

  Future<SuperResonanceAvailability> availability() async {
    final raw = await _invoke(availabilityCallableName, const {});
    final parsed = SuperResonanceAvailability.fromPublicMap(raw);
    if (parsed == null) {
      throw StateError(
        'Callable $availabilityCallableName returned an invalid payload.',
      );
    }
    return parsed;
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) return custom(name, data);

    final productionName = switch (name) {
      callableName => callableNameEu,
      availabilityCallableName => availabilityCallableNameEu,
      _ => name,
    };

    final functions = _functions ??
        FirebaseFunctions.instanceFor(
          region: callableRegionEu,
        );

    final result = await functions.httpsCallable(productionName).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Callable $name returned a non-map payload.');
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
