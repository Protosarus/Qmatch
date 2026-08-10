import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy unused EQ intro and dead l10n keys are removed', () {
    const removed = <String>[
      // Legacy EQ intro / pillars
      'eqIntroHeadline',
      'eqIntroDescription',
      'eqBulletQuestions',
      'eqBulletEmpathy',
      'eqBulletDuration',
      'startEqTest',
      'eqTestCompleted',
      'eqTestTitle',
      'eqPillarSelfAwareness',
      'eqPillarEmpathy',
      'eqPillarBalance',
      'eqPillarHarmony',
      'eqQuestionInsightLabel',
      // Legacy IQ / Frequency titles
      'iqTestTitle',
      'startIqTest',
      'iqQuestionLabel',
      'frequencyTestTitle',
      // Unused Likert l10n (bank/runtime supplies labels)
      'stronglyDisagree',
      'disagree',
      'agree',
      'stronglyAgree',
      'neutral',
      // Dead welcome / settings leftovers
      'welcomeMatchMinds',
      'welcomeLogIn',
      'settingsDeleteAccountDialogTitle',
      'privacyPolicyTodo',
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
        expect(src.contains('"$key":'), isFalse, reason: '$path arb $key');
        expect(src.contains('String get $key =>'), isFalse,
            reason: '$path impl $key');
        expect(src.contains('String get $key;'), isFalse,
            reason: '$path decl $key');
      }
    }

    // Live EQ intro + shared CTAs remain.
    final en = File('lib/l10n/app_en.arb').readAsStringSync();
    for (final key in [
      'eqIntroHeadlineLead',
      'eqIntroHeadlineEmphasis',
      'eqIntroLabel',
      'eqIntroMeta',
      'eqIntroStart',
      'assessmentContinue',
      'assessmentFinish',
      'iqIntroStart',
      'frequencyQuestionProgress',
    ]) {
      expect(en.contains('"$key"'), isTrue, reason: 'kept $key');
    }
  });
}
