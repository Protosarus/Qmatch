/// Phase 3O-A3B one-shot: gated publish of Assessment Content RC1 (*_v2 only).
///
/// Invokes [UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2] only —
/// does not bypass write gates, does not touch users/messages/matches, and is
/// not registered as a production UI route.
///
/// **Auth:** Does **not** sign in anonymously. Client SDK publish requires a
/// known admin session (or use Admin SDK outside this tool). See
/// `docs/firestore_publish_auth_safety.md`.
///
/// Run only after an approved auth strategy (debug + dart-define required):
/// ```
/// flutter run -d <ios-or-android> \
///   -t tool/publish_assessment_rc1_v2.dart \
///   --dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qmatch/features/debug/helpers/upload_assessment_sets_helper.dart';
import 'package:qmatch/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
    stderr.writeln('REFUSED: publish one-shot requires kDebugMode.');
    exit(2);
  }

  if (!UploadAssessmentSetsHelper.syncEnabledFromEnvironment) {
    stderr.writeln(
      'REFUSED: missing --dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true',
    );
    exit(2);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Refuse anonymous / missing auth. Do not call signInAnonymously().
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    stderr.writeln(
      'REFUSED: no authenticated Firebase user. '
      'Anonymous auth is disabled for assessment publish. '
      'Sign in as a known admin UID first, or use Admin SDK (see '
      'docs/firestore_publish_auth_safety.md).',
    );
    exit(3);
  }
  if (user.isAnonymous) {
    stderr.writeln(
      'REFUSED: anonymous Firebase user cannot publish assessment sets. '
      'See docs/firestore_publish_auth_safety.md.',
    );
    exit(3);
  }

  stdout.writeln('Authenticated uid (non-anonymous): ${user.uid}');
  stdout.writeln('=== Phase 3O-A3B: gated v2 publish starting ===');
  stdout.writeln(
    'confirmationPhrase: '
    '${UploadAssessmentSetsHelper.requiredConfirmationPhrase}',
  );
  stdout.writeln(
    'targetCollection: ${UploadAssessmentSetsHelper.targetCollection}',
  );
  stdout.writeln(
    'Gates: kDebugMode + QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC + '
    'dryRun:false + phrase SYNC_LOCALIZED_ASSESSMENT_SETS + '
    'collection assessment_sets + IDs *_v2 only (via helper convertToV2).',
  );

  final report =
      await UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2(
    dryRun: false,
    confirmationPhrase:
        UploadAssessmentSetsHelper.requiredConfirmationPhrase,
  );

  stdout.writeln(report.toString());

  final ids = report.documentIds;
  final nonV2 = ids.where((id) => !id.endsWith('_v2')).toList();
  final gateOk = report.mode == 'write' &&
      report.docsConsidered == 150 &&
      report.docsWritten == 150 &&
      report.firestoreWritesPerformed &&
      report.versionedIdCount == 150 &&
      report.legacyIdCount == 0 &&
      nonV2.isEmpty &&
      report.targetCollection == 'assessment_sets' &&
      report.contentVersion == 2 &&
      report.status == 'published' &&
      report.active &&
      report.languageMode == 'localized';

  // Read-only post-publish verification (assessment_sets only).
  final verify = await _verifyPublishedV2();
  stdout.writeln('=== Post-publish read verification ===');
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(verify));

  final payload = {
    'publishReport': report.toJson(),
    'nonV2IdsInReport': nonV2,
    'gateOk': gateOk,
    'postPublishVerify': verify,
    'publishedAt': DateTime.now().toIso8601String(),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(payload);
  stdout.writeln('<<<PUBLISH_RESULT_JSON>>>');
  stdout.writeln(encoded);
  stdout.writeln('<<<END_PUBLISH_RESULT_JSON>>>');

  // Best-effort local artifact (may be unavailable on device sandbox).
  try {
    final outDir = Directory('build');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final outFile = File('build/firestore_publish_rc1_result.json');
    await outFile.writeAsString(encoded);
    stdout.writeln('Wrote ${outFile.path}');
  } catch (e) {
    stdout.writeln('Local result file skipped: $e');
  }

  if (!gateOk || verify['ok'] != true) {
    stderr.writeln('PUBLISH VERIFICATION FAILED');
    exit(1);
  }

  stdout.writeln('=== Phase 3O-A3B publish SUCCESS ===');
  exit(0);
}

Future<Map<String, Object?>> _verifyPublishedV2() async {
  final snap =
      await FirebaseFirestore.instance.collection('assessment_sets').get();

  final v2Docs = snap.docs.where((d) => d.id.endsWith('_v2')).toList();
  final iq = v2Docs.where((d) => d.id.startsWith('iq_set_')).length;
  final eq = v2Docs.where((d) => d.id.startsWith('eq_set_')).length;
  final freq =
      v2Docs.where((d) => d.id.startsWith('frequency_set_')).length;

  var badMeta = 0;
  for (final d in v2Docs) {
    final data = d.data();
    final version = data['version'];
    final active = data['active'];
    final status = data['status'];
    final languageMode = data['language_mode'];
    final versionOk = version == 2 || version == 2.0;
    if (!versionOk ||
        active != true ||
        status != 'published' ||
        languageMode != 'localized') {
      badMeta++;
    }
  }

  final nonV2Sample = snap.docs
      .where((d) => !d.id.endsWith('_v2'))
      .take(5)
      .map((d) => d.id)
      .toList();

  final ok = v2Docs.length >= 150 &&
      iq == 50 &&
      eq == 50 &&
      freq == 50 &&
      badMeta == 0 &&
      v2Docs.every((d) => d.id.endsWith('_v2'));

  return {
    'ok': ok,
    'totalAssessmentSetsDocs': snap.docs.length,
    'v2DocCount': v2Docs.length,
    'iqV2': iq,
    'eqV2': eq,
    'frequencyV2': freq,
    'v2DocsWithBadMetadata': badMeta,
    'sampleNonV2IdsStillPresent': nonV2Sample,
    'note':
        'Non-v2 IDs listed only if pre-existing; helper does not overwrite them.',
  };
}
