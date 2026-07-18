/// Phase 3P-A6 runtime QA one-shot (Flutter Firebase **client** only).
///
/// Submits **one** account deletion **request** for the current authenticated
/// non-anonymous user. Does **not** delete Auth, Storage, profile, matches,
/// messages, or assessment_sets.
///
/// ```
/// flutter run -d <ios-sim> -t tool/runtime_qa_account_deletion_request.dart
/// ```
///
/// Prerequisite: sign in once in the normal app on the same simulator.
library;

import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qmatch/features/settings/services/account_deletion_request_service.dart';
import 'package:qmatch/firebase_options.dart';
import 'package:qmatch/core/utils/firestore_paths.dart';

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

  final uid = user.uid;
  final uidMasked = '${uid.substring(0, 6)}…';
  debugPrint('[AccountDeletionQA] Authenticated uid (masked): $uidMasked');
  debugPrint(
    '[AccountDeletionQA] isAnonymous=${user.isAnonymous} '
    'providers=${user.providerData.map((p) => p.providerId).join(",")}',
  );

  final service = AccountDeletionRequestService();
  final result = await service.submitRequest(
    localeLanguageCode: 'en',
    appVersion: 'QA-3P-A6',
  );

  debugPrint(
    '[AccountDeletionQA] submit ok=${result.ok} '
    'alreadyRequested=${result.alreadyRequested} '
    'error=${result.errorMessage}',
  );

  final report = <String, Object?>{
    'uid_masked': uidMasked,
    'submit_ok': result.ok,
    'already_requested': result.alreadyRequested,
    'error': result.errorMessage,
    'destructive_deletion': false,
    'assessment_sets_written': false,
  };

  if (!result.ok) {
    final code = result.errorMessage ?? 'unknown';
    final permissionDenied = code == 'permission-denied';
    report['permission_denied'] = permissionDenied;
    report['ui_expectation'] = permissionDenied
        ? 'AccountDeletionRequestScreen shows accountDeletionRequestError '
            '(friendly); no crash'
        : 'Screen maps error to user-friendly copy; no crash';
    stdout.writeln(jsonEncode(report));
    stderr.writeln(
      permissionDenied
          ? 'RESULT: permission-denied (rules likely missing/deny). '
              'No destructive deletion performed.'
          : 'RESULT: submit failed code=$code. No destructive deletion.',
    );
    // Exit 0 so logs are captured even when rules deny — expected launch gap.
    exit(0);
  }

  // Verify only current user's request + marker (read-back).
  try {
    final reqSnap =
        await FirestorePaths.accountDeletionRequestDoc(uid).get();
    final userSnap = await FirestorePaths.userDoc(uid).get();
    final req = reqSnap.data();
    final userData = userSnap.data();

    report['request_exists'] = reqSnap.exists;
    report['request_status'] = req?['status'];
    report['request_source'] = req?['source'];
    report['request_uid_matches'] = req?['uid'] == uid;
    report['user_acknowledged_irreversible'] =
        req?['user_acknowledged_irreversible'];
    report['user_acknowledged_timeline'] = req?['user_acknowledged_timeline'];
    report['user_marker'] = userData?['account_deletion_requested'];
    report['paths_written'] = [
      'account_deletion_requests/$uidMasked',
      'users/$uidMasked (soft marker only)',
    ];

    debugPrint(
      '[AccountDeletionQA] request status=${req?['status']} '
      'source=${req?['source']} '
      'ack_irrev=${req?['user_acknowledged_irreversible']} '
      'ack_time=${req?['user_acknowledged_timeline']}',
    );
    debugPrint(
      '[AccountDeletionQA] user.account_deletion_requested='
      '${userData?['account_deletion_requested']}',
    );
  } on FirebaseException catch (e) {
    report['verify_error'] = e.code;
    debugPrint('[AccountDeletionQA] verify failed: ${e.code} ${e.message}');
  }

  stdout.writeln(jsonEncode(report));
  debugPrint('[AccountDeletionQA] DONE — no Auth/Storage/data wipe.');
  exit(0);
}
