import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IQ/EQ/Frequency loading spinners share Frequency lavender', () {
    const lavender = '0xFFDAC8ED';
    for (final path in [
      'lib/features/assessment/screens/iq_test_screen.dart',
      'lib/features/assessment/screens/eq_test_screen.dart',
      'lib/features/assessment/screens/frequency_test_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains(lavender), isTrue, reason: path);
      expect(
        src.contains('CircularProgressIndicator'),
        isTrue,
        reason: path,
      );
    }

    final iq = File('lib/features/assessment/screens/iq_test_screen.dart')
        .readAsStringSync();
    final eq = File('lib/features/assessment/screens/eq_test_screen.dart')
        .readAsStringSync();
    expect(iq.contains('AppColors.vizIq'), isFalse);
    expect(eq.contains('AppColors.vizEq'), isFalse);
  });
}
