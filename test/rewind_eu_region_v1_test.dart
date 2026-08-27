import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Rewind callables use europe-west1', () {
    final service = File(
      'lib/features/matching/services/swipe_service.dart',
    ).readAsStringSync();

    final index = File(
      'functions/index.js',
    ).readAsStringSync();

    // Legacy contract remains.
    expect(
      service.contains(
        "rewindCallableName = 'rewindPass'",
      ),
      isTrue,
    );
    expect(
      service.contains(
        "rewindLikeCallableName = 'rewindLike'",
      ),
      isTrue,
    );

    // Current production path is EU.
    expect(
      service.contains(
        "rewindCallableNameEu = 'rewindPassEu'",
      ),
      isTrue,
    );
    expect(
      service.contains(
        "rewindLikeCallableNameEu = 'rewindLikeEu'",
      ),
      isTrue,
    );
    expect(
      service.contains(
        "rewindCallableRegionEu = 'europe-west1'",
      ),
      isTrue,
    );
    expect(
      service.contains('FirebaseFunctions.instanceFor('),
      isTrue,
    );

    // Legacy endpoints stay available.
    expect(index.contains('exports.rewindPass = onCall('), isTrue);
    expect(index.contains('exports.rewindLike = onCall('), isTrue);

    // Current-client endpoints are EU.
    expect(index.contains('exports.rewindPassEu = onCall('), isTrue);
    expect(index.contains('exports.rewindLikeEu = onCall('), isTrue);
  });
}
