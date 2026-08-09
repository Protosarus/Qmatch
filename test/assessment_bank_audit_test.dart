import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      '22-23 audit output deterministic and banks unmodified by audit artifact',
      () {
    final reportPath = 'tool/assessment_bank_audit_out/audit_report.json';
    expect(File(reportPath).existsSync(), isTrue,
        reason: 'Run: dart run tool/audit_assessment_banks.dart');

    final a = File(reportPath).readAsStringSync();
    // Re-run audit
    final result = Process.runSync(
      'dart',
      ['run', 'tool/audit_assessment_banks.dart'],
      workingDirectory: Directory.current.path,
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());
    final b = File(reportPath).readAsStringSync();
    expect(b, a);

    final report = jsonDecode(b) as Map<String, dynamic>;
    expect(report['banks_modified'], isFalse);
    expect(report['audit_content_version'], 'assessment_bank_audit_v1');

    final totals = report['totals']['classification_counts'] as Map;
    expect(totals.containsKey('REWRITE'), isTrue);
    expect(totals.containsKey('KEEP_WITH_METADATA'), isTrue);

    // Existing bank files still parse and were not emptied.
    for (final p in [
      'assets/data/assessment_sets/iq_sets.json',
      'assets/data/assessment_sets/eq_sets.json',
      'assets/data/assessment_sets/frequency_sets.json',
    ]) {
      final data =
          jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;
      expect((data['sets'] as List).length, greaterThan(0));
    }
  });

  test('12 every audited item has stable question id in report', () {
    final report = jsonDecode(
      File('tool/assessment_bank_audit_out/audit_report.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final modules = report['modules'] as Map<String, dynamic>;
    for (final mod in modules.values) {
      final items = (mod as Map)['items'] as List;
      for (final raw in items) {
        final id = (raw as Map)['question_id'] as String;
        expect(id.isNotEmpty, isTrue);
      }
    }
  });

  test('IQ unmappable without domain metadata; Frequency mappable via aliases',
      () {
    final report = jsonDecode(
      File('tool/assessment_bank_audit_out/audit_report.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final iq = report['modules']['iq'] as Map<String, dynamic>;
    final freq = report['modules']['frequency'] as Map<String, dynamic>;
    expect(iq['dimension_unmappable_count'], iq['total_item_count']);
    expect(freq['dimension_mappable_count'], freq['total_item_count']);
    final dist = Map<String, dynamic>.from(
      freq['canonical_dimension_distribution'] as Map,
    );
    expect(dist.length, 6);
  });
}
