import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Passport preference path is owner doc, not user profile', () {
    final paths = read('lib/core/utils/firestore_paths.dart');
    expect(
      paths.contains(".collection('preferences').doc('discover_passport_v1')"),
      isTrue,
    );
  });

  test('Discover query remains global; L2 has no passport', () {
    final discover = read(
      'lib/features/discover/services/discover_service.dart',
    );
    expect(
      discover.contains("where('discover_eligible', isEqualTo: true)"),
      isTrue,
    );
    expect(discover.contains("where('passport_"), isFalse);

    final l2 = read('functions/src/stage_b2_l2_callable.js');
    expect(l2.contains('passport'), isFalse);

    final ranking = read(
      'lib/features/discover/services/discover_structural_l2_ranking.dart',
    );
    expect(ranking.contains('passport'), isFalse);
  });

  test('rules deny client writes and public list of Passport preference', () {
    final rules = read('firestore.rules');
    expect(rules.contains("match /preferences/{prefId}"), isTrue);
    expect(
      rules.contains("prefId == 'discover_passport_v1'"),
      isTrue,
    );
    expect(
      rules.contains("prefId == 'notification_prefs_v1'"),
      isTrue,
    );
    expect(
      rules.contains('allow list, create, update, delete: if false;'),
      isTrue,
    );

    final callable = read('functions/src/discover_passport_callable.js');
    expect(callable.contains('geohash'), isTrue);
    expect(callable.contains("payload['geohash']"), isFalse);
    expect(callable.contains('super_resonance_balance'), isTrue);
    expect(callable.contains('deriveResonanceAccess'), isFalse);
    expect(callable.contains('normalizeSnapshot'), isTrue);
  });

  test('exports trusted Passport callables without minInstances or EU fork',
      () {
    final index = read('functions/index.js');
    expect(index.contains('exports.getDiscoverPassport = onCall('), isTrue);
    expect(index.contains('exports.setDiscoverPassport = onCall('), isTrue);
    expect(index.contains('exports.disableDiscoverPassport = onCall('), isTrue);
    final start = index.indexOf('exports.getDiscoverPassport = onCall(');
    final block = index.substring(start);
    expect(block.contains("region: 'us-central1'"), isTrue);
    expect(block.contains('minInstances'), isFalse);
    expect(block.contains('compareStageB2StructuralEu'), isFalse);
  });
}
