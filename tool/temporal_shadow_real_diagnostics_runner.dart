/// Debug-only one-shot: real-thread temporal shadow diagnostics (metadata only).
///
/// ```
/// flutter run -d <device> -t tool/temporal_shadow_real_diagnostics_runner.dart
/// ```
///
/// Requires a signed-in Firebase user on the device. Refuses outside kDebugMode.
/// Never writes Firestore, never prints message bodies, never touches Discover.
library;

import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:qmatch/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner.dart';
import 'package:qmatch/features/matching/diagnostics/temporal_shadow_debug_diagnostics_runner_contract.dart';
import 'package:qmatch/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
    stderr.writeln(
      'REFUSED: ${TemporalShadowDebugDiagnosticsRunnerContract.refusalRequiresDebugMode}',
    );
    exit(2);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final report = await TemporalShadowDebugDiagnosticsRunner().run(
    localTimeZoneOffset: DateTime.now().timeZoneOffset,
  );

  // Aggregate wire map only — never message bodies / previews.
  stdout.writeln(
    const JsonEncoder.withIndent(' ').convert(report.toWireMap()),
  );

  if (report.refused) {
    exit(2);
  }
  // Clear no-data is a successful diagnostic outcome.
  exit(0);
}
