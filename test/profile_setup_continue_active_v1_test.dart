import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/widgets/frequency_question_chrome.dart';

void main() {
  testWidgets(
    'FrequencyContinueButton active:false is visual-only (still tappable)',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FrequencyContinueButton(
              key: const Key('cta'),
              label: 'Continue',
              active: false,
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('cta')));
      await tester.pump();
      expect(taps, 1);
    },
  );

  test('Profile Setup Continue active mirrors always-enabled CTA', () {
    final src = File('lib/features/profile/screens/profile_setup_screen.dart')
        .readAsStringSync();
    expect(src.contains("Key('qmatch-profile-setup-continue')"), isTrue);
    expect(src.contains('onPressed: _nextStep'), isTrue);
    expect(src.contains('active: true'), isTrue);
    expect(src.contains('active: false'), isFalse);

    final chrome =
        File('lib/features/assessment/widgets/frequency_question_chrome.dart')
            .readAsStringSync();
    // Contract: active dims visuals; saving is what nulls onTap.
    expect(chrome.contains('onTap: saving ? null : onPressed'), isTrue);
    expect(chrome.contains('opacity: active ? 1 : 0.92'), isTrue);
  });
}
