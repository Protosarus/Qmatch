/// Phase 3O-A3E runtime QA one-shot (Flutter Firebase **client** only).
///
/// - Resets **current user** assessment assignments via existing helper
/// - Assigns fresh IQ/EQ/Frequency sets and prints source/locale logs
/// - Does **not** write `assessment_sets`, does **not** publish, no Admin SDK
///
/// ```
/// flutter run -d <ios-sim> -t tool/runtime_qa_firestore_source.dart
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qmatch/features/assessment/services/assessment_set_service.dart';
import 'package:qmatch/features/assessment/utils/assessment_language.dart';
import 'package:qmatch/features/assessment/utils/localized_text_resolver.dart';
import 'package:qmatch/features/debug/helpers/assessment_assignment_reset_helper.dart';
import 'package:qmatch/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kDebugMode) {
    stderr.writeln('REFUSED: runtime QA requires kDebugMode');
    exit(2);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    stderr.writeln(
      'BLOCKER: no authenticated Firebase user on this client. '
      'Sign in once in the normal app on this simulator, then re-run.',
    );
    exit(3);
  }
  if (user.isAnonymous) {
    stderr.writeln(
      'BLOCKER: anonymous user not accepted for this QA path. '
      'Use a normal signed-in test account.',
    );
    exit(3);
  }

  debugPrint('Authenticated uid (masked): ${user.uid.substring(0, 6)}…');

  final reset =
      await AssessmentAssignmentResetHelper.resetAllAssignments();
  debugPrint(
    '[RuntimeQA] reset refused=${reset.refused} writes=${reset.writesPerformed} '
    'docsDeleted=${reset.docsDeleted} types=${reset.assignmentTypesReset}',
  );
  if (reset.refused) {
    stderr.writeln('Reset refused: ${reset.refusalReason}');
    exit(4);
  }

  final service = AssessmentSetService();
  final results = <String, Object?>{};

  for (final lang in ['tr', 'en']) {
    // Fresh assign per language: reset again between locales so set re-picks
    // and language metadata is recorded for this locale pass.
    if (lang == 'en') {
      final r2 = await AssessmentAssignmentResetHelper.resetAllAssignments();
      if (r2.refused) {
        stderr.writeln('EN reset refused: ${r2.refusalReason}');
        exit(4);
      }
    }

    final perLang = <String, Object?>{};
    for (final type in ['iq', 'eq', 'frequency']) {
      final set = await service.getOrAssignSet(
        type: type,
        languageCode: lang,
        localeUsed: AssessmentLanguage.localeUsed(locale: Locale(lang)),
      );

      final first = set.questions.isNotEmpty ? set.questions.first : null;
      final qRaw = first == null
          ? null
          : (first.containsKey('text') ? first['text'] : first['question']);
      final resolved = first == null
          ? ''
          : LocalizedTextResolver.resolve(
              qRaw,
              languageCode: lang,
            );
      String? optionPreview;
      if (first != null && first['options'] is List && type != 'frequency') {
        final opts = LocalizedTextResolver.resolveOptionLabels(
          first['options'] as List,
          languageCode: lang,
        );
        if (opts.isNotEmpty) optionPreview = opts.first;
      }

      // Source/locale debug lines come from AssessmentSetService.logSetLoad.
      final qShort =
          resolved.length > 60 ? '${resolved.substring(0, 60)}…' : resolved;
      final optShort = optionPreview ?? '(n/a frequency)';
      debugPrint(
        '[RuntimeQA] type=$type lang=$lang setId=${set.id} '
        'v2=${set.id.endsWith('_v2')} version=${set.version} '
        'q=$qShort opt=$optShort',
      );

      perLang[type] = {
        'setId': set.id,
        'endsWithV2': set.id.endsWith('_v2'),
        'version': set.version,
        'active': set.active,
        'questionPreview': resolved.length > 80
            ? '${resolved.substring(0, 80)}…'
            : resolved,
        'optionPreview': optionPreview,
      };
    }
    results[lang] = perLang;
  }

  stdout.writeln('<<<RUNTIME_QA_RESULT>>>');
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'authPresent': true,
      'resetPerformed': reset.writesPerformed,
      'resetDocsDeleted': reset.docsDeleted,
      'assessmentSetsWrite': false,
      'publishPerformed': false,
      'locales': results,
    }),
  );
  stdout.writeln('<<<END_RUNTIME_QA_RESULT>>>');
  exit(0);
}
