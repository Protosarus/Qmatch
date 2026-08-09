import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilot bank is not in pubspec', () {
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub.contains('frequency_pilot_tr_v1'), isFalse);
    expect(pub.contains('assessment_v3/frequency'), isFalse);
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
      if (f.path.contains('/domain/trait_scoring/')) continue;
      final text = f.readAsStringSync();
      expect(text.contains('frequency_pilot_tr_v1'), isFalse, reason: f.path);
      expect(text.contains('assessment_v3/frequency'), isFalse, reason: f.path);
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
