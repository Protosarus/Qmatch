import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orphan-screen l10n keys are removed from arb + generated localizations',
      () {
    const removed = <String>[
      'iqReasoningProfileTitle',
      'iqReasoningProfileSubtitle',
      'iqToEqMessage',
      'iqTestCompleted',
      'continueToEqAssessment',
      'iqUncalibratedDisclaimer',
      'yourFrequency',
      'balancedFrequency',
      'frequencyScore',
      'seeMyFrequency',
      'emailSignupTitle',
      'socialCreateAccountSubtitle',
      'emailVerificationResend',
    ];

    for (final path in [
      'lib/l10n/app_en.arb',
      'lib/l10n/app_tr.arb',
      'lib/l10n/app_localizations.dart',
      'lib/l10n/app_localizations_en.dart',
      'lib/l10n/app_localizations_tr.dart',
    ]) {
      final src = File(path).readAsStringSync();
      for (final key in removed) {
        expect(src.contains(key), isFalse, reason: '$path still has $key');
      }
    }

    // Live Frequency chrome still localized.
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    expect(en.contains('"assessmentStageFrequency"'), isTrue);
    expect(en.contains('"iqCanonicalSessionError"'), isTrue);
    expect(en.contains('"eqIntroStart"'), isTrue);
  });

  test('docs describe live onboarding without Reasoning Profile / IQ→EQ transition',
      () {
    final contract =
        File('docs/assessment/qmatch_iq_runtime_contract_v1.md').readAsStringSync();
    expect(contract.contains('EQTestIntroScreen'), isTrue);
    expect(contract.contains('IqReasoningProfileScreen'), isTrue); // noted as removed
    expect(
      contract.contains('Removed from live onboarding'),
      isTrue,
    );

    final gap =
        File('docs/assessment/qmatch_iq_runtime_gap_v1.md').readAsStringSync();
    expect(gap.contains('EQTestIntroScreen → EQ → Frequency'), isTrue);
    expect(gap.contains('Orphan UI removed'), isTrue);

    final adapter = File('docs/profile/qmatch_iq_to_20d_runtime_adapter_v1.md')
        .readAsStringSync();
    expect(
      adapter.contains('EQ Intro → EQ → Frequency → Complete'),
      isTrue,
    );
    expect(adapter.contains('Reasoning Profile → EQ'), isFalse);
  });
}
