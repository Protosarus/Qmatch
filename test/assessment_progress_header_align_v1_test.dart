import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IQ/EQ/Frequency progress headers share · format and Playfair style', () {
    const pattern = r'[A-Za-zÇçĞğİıÖöŞşÜü]+ · \{current\} / \{total\}';

    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    final tr = File('lib/l10n/app_tr.arb').readAsStringSync();
    expect(en.contains('"iqQuestionProgress": "IQ · {current} / {total}"'),
        isTrue);
    expect(en.contains('"eqQuestionProgress": "EQ · {current} / {total}"'),
        isTrue);
    expect(
      en.contains(
        '"frequencyQuestionProgress": "Frequency · {current} / {total}"',
      ),
      isTrue,
    );
    expect(
      tr.contains(
        '"frequencyQuestionProgress": "Frekans · {current} / {total}"',
      ),
      isTrue,
    );
    expect(RegExp(pattern).hasMatch('IQ · {current} / {total}'), isTrue);

    final freqChrome =
        File('lib/features/assessment/widgets/frequency_question_chrome.dart')
            .readAsStringSync();
    final iqChrome =
        File('lib/features/assessment/widgets/iq_question_chrome.dart')
            .readAsStringSync();
    final eqChrome =
        File('lib/features/assessment/widgets/eq_question_chrome.dart')
            .readAsStringSync();

    const sharedStyle = '''
          style: GoogleFonts.playfairDisplay(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),''';
    expect(freqChrome.contains(sharedStyle), isTrue);
    expect(iqChrome.contains(sharedStyle), isTrue);
    expect(eqChrome.contains(sharedStyle), isTrue);
    expect(freqChrome.contains('label.toUpperCase()'), isFalse);
    expect(freqChrome.contains('letterSpacing: 2.2'), isFalse);

    final freqScreen =
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .readAsStringSync();
    expect(freqScreen.contains('l10n.frequencyQuestionProgress('), isTrue);
    expect(freqScreen.contains("assessmentStageFrequency} •"), isFalse);
    // Same top gap under chrome as IQ/EQ.
    expect(
      freqScreen.contains('const FrequencyQuestionTopBar(),\n'
          '                  const SizedBox(height: 2),'),
      isTrue,
    );
  });
}
