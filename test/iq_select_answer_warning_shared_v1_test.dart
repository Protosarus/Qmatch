import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IQ select-answer warning uses shared FrequencySelectAnswerWarning', () {
    final iqSrc =
        File('lib/features/assessment/screens/iq_test_screen.dart').readAsStringSync();
    final eqSrc =
        File('lib/features/assessment/screens/eq_test_screen.dart').readAsStringSync();

    expect(iqSrc.contains('FrequencySelectAnswerWarning'), isTrue);
    expect(iqSrc.contains('_IqSelectAnswerWarningBanner'), isFalse);
    expect(eqSrc.contains('FrequencySelectAnswerWarning'), isTrue);
    expect(
      iqSrc.contains('l10n.iqPleaseSelectAnswerToContinue'),
      isTrue,
    );
  });
}
