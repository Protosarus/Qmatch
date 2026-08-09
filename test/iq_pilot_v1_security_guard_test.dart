import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilot bank is not in pubspec', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('iq_pilot_tr_v1'), isFalse);
    expect(pub.contains('assessment_v3/iq'), isFalse);
  });

  test('production IQ screens do not import the pilot', () {
    final screens = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') &&
            (f.path.contains('iq') ||
                f.path.contains('assessment') ||
                f.path.contains('question')));
    for (final f in screens) {
      // Skip the pure trait domain and this test tree.
      if (f.path.contains('/domain/trait_scoring/')) continue;
      if (f.path.contains('/domain/iq_bank/')) continue;
      final text = f.readAsStringSync();
      expect(text.contains('iq_pilot_tr_v1'), isFalse, reason: f.path);
      expect(text.contains('assessment_v3/iq'), isFalse, reason: f.path);
    }
  });

  test('pure trait domain has no Firebase imports', () {
    for (final f in Directory('lib/features/assessment/domain/trait_scoring')
        .listSync()
        .whereType<File>()) {
      final text = f.readAsStringSync();
      expect(text.contains('firebase'), isFalse);
      expect(text.contains('cloud_firestore'), isFalse);
    }
  });

  test('live IQ questions bank file was not modified by pilot path presence',
      () {
    expect(File('assets/data/iq_questions.json').existsSync(), isTrue);
    final pilot =
        File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json').existsSync();
    expect(pilot, isTrue);
    // Distinct paths — pilot is additive only.
    expect(
      File('assets/data/assessment_v3/iq/iq_pilot_tr_v1.json').path,
      isNot(File('assets/data/iq_questions.json').path),
    );
  });
}
