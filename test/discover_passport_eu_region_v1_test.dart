import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Passport client is colocated with europe-west1 Firestore',
      () {
    final client = File(
      'lib/features/discover/services/discover_passport_client.dart',
    ).readAsStringSync();

    final index = File(
      'functions/index.js',
    ).readAsStringSync();

    // Legacy contract remains.
    expect(client.contains("getCallableName = 'getDiscoverPassport'"), isTrue);
    expect(client.contains("setCallableName = 'setDiscoverPassport'"), isTrue);
    expect(
      client.contains("disableCallableName = 'disableDiscoverPassport'"),
      isTrue,
    );

    // Production client uses EU endpoints.
    expect(
      client.contains("getCallableNameEu = 'getDiscoverPassportEu'"),
      isTrue,
    );
    expect(
      client.contains("setCallableNameEu = 'setDiscoverPassportEu'"),
      isTrue,
    );
    expect(
      client.contains("disableCallableNameEu = 'disableDiscoverPassportEu'"),
      isTrue,
    );
    expect(client.contains("callableRegionEu = 'europe-west1'"), isTrue);
    expect(client.contains('FirebaseFunctions.instanceFor('), isTrue);

    // Backend exposes EU endpoints while preserving legacy ones.
    expect(index.contains('exports.getDiscoverPassport = onCall('), isTrue);
    expect(index.contains('exports.setDiscoverPassport = onCall('), isTrue);
    expect(index.contains('exports.disableDiscoverPassport = onCall('), isTrue);

    expect(index.contains('exports.getDiscoverPassportEu = onCall('), isTrue);
    expect(index.contains('exports.setDiscoverPassportEu = onCall('), isTrue);
    expect(
      index.contains('exports.disableDiscoverPassportEu = onCall('),
      isTrue,
    );

    expect(index.contains("{ region: 'europe-west1' }"), isTrue);
  });

  test('Discover measures Passport latency separately', () {
    final service = File(
      'lib/features/discover/services/discover_service.dart',
    ).readAsStringSync();

    expect(service.contains("'discover.passport_get'"), isTrue);
    expect(service.contains('() => _passportClient.get()'), isTrue);
  });
}
