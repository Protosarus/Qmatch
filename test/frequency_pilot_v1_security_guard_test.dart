import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilot bank is not in pubspec; runtime candidates are registered', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('frequency_pilot_tr_v1'), isFalse);
    expect(pub.contains('frequency_bank_tr_v1.json'), isTrue);
    expect(pub.contains('frequency_bank_en_v1.json'), isTrue);
  });

  test('production Frequency screens do not import the pilot', () {
    final screens = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.dart') &&
            (f.path.contains('frequency') ||
                f.path.contains('assessment') ||
                f.path.contains('question')));
    for (final f in screens) {
      // Offline domain packages may reference pilot/candidate paths without
      // wiring them into live screens (P2C-2A-8R1 / R2).
      if (f.path.contains('/domain/trait_scoring/')) continue;
      if (f.path.contains('/domain/frequency_bank/')) continue;
      if (f.path.contains('/domain/frequency_scoring/')) continue;
      if (f.path.contains('/domain/frequency_session/')) continue;
      final text = f.readAsStringSync();
      expect(text.contains('frequency_pilot_tr_v1'), isFalse, reason: f.path);
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

  test('live Frequency sets bank file was not replaced by pilot path', () {
    expect(
      File('assets/data/assessment_sets/frequency_sets.json').existsSync(),
      isTrue,
    );
    expect(
      File('assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json')
          .existsSync(),
      isTrue,
    );
    expect(
      File('assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json')
          .path,
      isNot(File('assets/data/assessment_sets/frequency_sets.json').path),
    );
  });
}
