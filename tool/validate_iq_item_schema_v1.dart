// Offline validator entrypoint for canonical IQ items / pilot.
// Usage:
//   dart run tool/validate_iq_item_schema_v1.dart
//   dart run tool/validate_iq_item_schema_v1.dart --pilot
// Exit non-zero on hard errors.

import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';

const _iqDir = 'assets/data/assessment_v3/iq';
const _pilotPath = '$_iqDir/iq_pilot_tr_v1.json';
const _targetBankPath = '$_iqDir/iq_bank_tr_v1.json';

void main(List<String> args) {
  final root = Directory.current.path;
  final pilotMode = args.contains('--pilot');
  final outDir = Directory('$root/$_iqDir/reports');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  if (pilotMode) {
    final form = jsonDecode(
      File('$root/$_pilotPath').readAsStringSync(),
    ) as Map<String, dynamic>;
    final report = IqItemValidator.validatePilotForm(form);
    File('${outDir.path}/iq_pilot_validation_v1_report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report.toJson()),
    );
    File('${outDir.path}/iq_pilot_validation_v1_report.md')
        .writeAsStringSync(report.toHumanReadable());
    stdout.writeln(report.toHumanReadable());
    exit(report.hasErrors ? 1 : 0);
  }

  final bankFile = File('$root/$_targetBankPath');
  if (!bankFile.existsSync()) {
    final absent = {
      'has_errors': false,
      'bank_present': false,
      'message':
          'Canonical bank file absent (expected). Contract target only in P2C-2A-0.',
      'path': _targetBankPath,
      'target_unique_items': IqBankContract.targetUniqueItems,
      'target_per_dimension': IqBankContract.targetPerDimension,
    };
    File('${outDir.path}/iq_bank_validation_v1_report.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(absent),
    );
    stdout.writeln('bank absent (OK for P2C-2A-0 audit)');
    exit(0);
  }

  final decoded = jsonDecode(bankFile.readAsStringSync());
  final items = decoded is Map && decoded['items'] is List
      ? (decoded['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
      : (decoded as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
  final report = IqItemValidator.validateItems(
    items,
    enforceBankTargets: true,
  );
  File('${outDir.path}/iq_bank_validation_v1_report.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
  );
  File('${outDir.path}/iq_bank_validation_v1_report.md')
      .writeAsStringSync(report.toHumanReadable());
  stdout.writeln(report.toHumanReadable());
  exit(report.hasErrors ? 1 : 0);
}
