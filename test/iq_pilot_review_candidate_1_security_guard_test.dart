import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review candidate is not in pubspec', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('review_candidate_1'), isFalse);
    expect(pub.contains('iq_pilot_tr_v1_review_candidate'), isFalse);
    expect(pub.contains('assessment_v3/iq'), isFalse);
  });

  test('production code does not import review candidate assets', () {
    final screens = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final f in screens) {
      if (f.path.contains('/domain/trait_scoring/')) continue;
      if (f.path.contains('/domain/iq_bank/')) continue;
      final text = f.readAsStringSync();
      expect(text.contains('review_candidate_1'), isFalse, reason: f.path);
      expect(text.contains('iq_pilot_tr_v1_review'), isFalse, reason: f.path);
      expect(text.contains('assessment_v3/iq'), isFalse, reason: f.path);
    }
  });

  test('no Firebase dependency in trait scoring domain', () {
    for (final f in Directory('lib/features/assessment/domain/trait_scoring')
        .listSync()
        .whereType<File>()) {
      final text = f.readAsStringSync();
      expect(text.contains('firebase'), isFalse);
      expect(text.contains('cloud_firestore'), isFalse);
      expect(text.contains('PersonaScoringService'), isFalse);
    }
  });

  test('original v1 pilot was not overwritten by candidate', () {
    final v1 = File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json')
        .readAsStringSync();
    final cand = File(
            'assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json')
        .readAsStringSync();
    expect(v1.contains('"content_version": "iq-tr-pilot-v1"'), isTrue);
    expect(v1.contains('iq-tr-pilot-v1-review-candidate-1'), isFalse);
    expect(cand.contains('iq-tr-pilot-v1-review-candidate-1'), isTrue);
    expect(v1.contains('iq_tr_v1_spatial_003'), isTrue);
    expect(cand.contains('"question_id": "iq_tr_v1_spatial_003"'), isFalse);
  });
}
