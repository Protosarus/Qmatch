import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/profile/utils/profile_option_labels.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  test('religion Diğer maps to optReligionOther (not optGenderOther key path)',
      () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final tr = await AppLocalizations.delegate.load(const Locale('tr'));

    expect(en.optReligionOther, 'Other');
    expect(tr.optReligionOther, 'Diğer');

    expect(ProfileOptionLabels.label(en, 'Diğer'), en.optReligionOther);
    expect(ProfileOptionLabels.label(tr, 'Diğer'), tr.optReligionOther);

    // Guard: label helper must not wire religion Diğer through gender key.
    final labelsSrc = File(
      'lib/features/profile/utils/profile_option_labels.dart',
    ).readAsStringSync();
    expect(labelsSrc.contains("case 'Diğer':"), isTrue);
    expect(
      labelsSrc.contains('return l10n.optReligionOther;'),
      isTrue,
    );
    expect(
      labelsSrc.contains("case 'Diğer':\n        return l10n.optGenderOther;"),
      isFalse,
    );
  });

  test('lifestyle religion options still store legacy Diğer', () {
    final lifestyleSrc = File(
      'lib/features/profile/screens/steps/lifestyle_step.dart',
    ).readAsStringSync();
    expect(lifestyleSrc.contains("'Diğer'"), isTrue);
    expect(lifestyleSrc.contains('profileReligion'), isTrue);
  });
}
