import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new Like client is colocated with europe-west1 Firestore', () {
    final service = File(
      'lib/features/matching/services/match_service.dart',
    ).readAsStringSync();

    final index = File(
      'functions/index.js',
    ).readAsStringSync();

    // Legacy endpoint remains for backward compatibility.
    expect(
      service.contains(
        "likeCallableName = 'likeAndMaybeCreateMatch'",
      ),
      isTrue,
    );
    expect(
      index.contains('exports.likeAndMaybeCreateMatch = onCall('),
      isTrue,
    );

    // New production path is EU-colocated.
    expect(
      service.contains(
        "likeCallableNameEu = 'likeAndMaybeCreateMatchEu'",
      ),
      isTrue,
    );
    expect(
      service.contains(
        "likeCallableRegionEu = 'europe-west1'",
      ),
      isTrue,
    );
    expect(
      service.contains(
        'FirebaseFunctions.instanceFor(',
      ),
      isTrue,
    );
    expect(
      service.contains(
        'region: likeCallableRegionEu',
      ),
      isTrue,
    );
    expect(
      index.contains('exports.likeAndMaybeCreateMatchEu = onCall('),
      isTrue,
    );
    expect(
      index.contains("{ region: 'europe-west1' }"),
      isTrue,
    );
  });
}
