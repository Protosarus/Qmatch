import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Super Resonance callables use europe-west1', () {
    final client = File(
      'lib/features/discover/services/super_resonance_send_client.dart',
    ).readAsStringSync();

    final index = File(
      'functions/index.js',
    ).readAsStringSync();

    // Legacy API/test contract remains.
    expect(
      client.contains("callableName = 'sendSuperResonance'"),
      isTrue,
    );
    expect(
      client.contains(
        "availabilityCallableName =\n      'getSuperResonanceAvailability'",
      ),
      isTrue,
    );

    // Current production route is EU.
    expect(
      client.contains("callableNameEu = 'sendSuperResonanceEu'"),
      isTrue,
    );
    expect(
      client.contains("'getSuperResonanceAvailabilityEu'"),
      isTrue,
    );
    expect(
      client.contains("callableRegionEu = 'europe-west1'"),
      isTrue,
    );
    expect(
      client.contains('FirebaseFunctions.instanceFor('),
      isTrue,
    );

    // Legacy endpoints remain available.
    expect(
      index.contains('exports.sendSuperResonance = onCall('),
      isTrue,
    );
    expect(
      index.contains('exports.getSuperResonanceAvailability = onCall('),
      isTrue,
    );

    // EU endpoints are added.
    expect(
      index.contains('exports.sendSuperResonanceEu = onCall('),
      isTrue,
    );
    expect(
      index.contains(
        'exports.getSuperResonanceAvailabilityEu = onCall(',
      ),
      isTrue,
    );
  });
}
