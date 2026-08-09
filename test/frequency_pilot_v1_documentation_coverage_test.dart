import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/frequency_pilot_v1_helpers.dart';

/// Strict documentation coverage for Frequency pilot TR v1 (P2A-2D-1).
/// Fails if evidence/provenance/option-balance docs drop or invent item IDs.
void main() {
  late List<String> bankIds;
  late String evidenceMarkdown;
  late String provenanceMarkdown;
  late String optionBalanceMarkdown;
  late String qualityMarkdown;
  late String separationMarkdown;

  setUpAll(() {
    final form = FrequencyPilotV1Loader.loadForm();
    bankIds = [
      for (final i in form['items'] as List)
        (i as Map)['question_id'] as String,
    ];

    final root = FrequencyPilotV1Loader.repoRoot;
    evidenceMarkdown = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_evidence_mapping_review.md',
    ).readAsStringSync();
    provenanceMarkdown = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_provenance_manifest.md',
    ).readAsStringSync();
    optionBalanceMarkdown = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_option_balance_report.md',
    ).readAsStringSync();
    qualityMarkdown = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_quality_report.md',
    ).readAsStringSync();
    separationMarkdown = File(
      '$root/docs/core_engine/frequency_pilot_tr_v1_construct_separation_report.md',
    ).readAsStringSync();
  });

  test('pilot contains exactly 50 unique ordered item IDs', () {
    expect(bankIds, hasLength(50));
    expect(bankIds.toSet(), hasLength(50));
    expect(bankIds, equals(List<String>.from(bankIds)..sort()));
  });

  test('evidence mapping review covers each bank ID exactly once', () {
    final headingRe = RegExp(
      r'^## Item (\d+): `(frequency_tr_v1_[a-z0-9_]+)`',
      multiLine: true,
    );
    final matches = headingRe.allMatches(evidenceMarkdown).toList();
    expect(matches, hasLength(50));

    final headingIds = <String>[];
    for (var i = 0; i < matches.length; i++) {
      final index = int.parse(matches[i].group(1)!);
      final id = matches[i].group(2)!;
      expect(index, i + 1, reason: 'Item headings must be contiguous 1..50');
      headingIds.add(id);
    }

    expect(headingIds, equals(bankIds));
    expect(headingIds.toSet(), hasLength(50));

    final overviewIds = RegExp(
            r'^\| (\d+) \| `(frequency_tr_v1_[a-z0-9_]+)` \|',
            multiLine: true)
        .allMatches(evidenceMarkdown)
        .map((m) => m.group(2)!)
        .toList();
    expect(overviewIds, equals(bankIds));

    final mentioned = _questionIds(evidenceMarkdown);
    expect(mentioned.toSet(), equals(bankIds.toSet()));
  });

  test('each evidence item section includes review fields 1–20', () {
    final sections = evidenceMarkdown.split(
      RegExp(r'(?=^## Item \d+: )', multiLine: true),
    );
    final itemSections =
        sections.where((s) => s.startsWith('## Item ')).toList();
    expect(itemSections, hasLength(50));
    for (final section in itemSections) {
      for (var n = 1; n <= 20; n++) {
        expect(
          RegExp('^### $n\\. ', multiLine: true).hasMatch(section),
          isTrue,
          reason: 'Missing ### $n. in ${section.split('\n').first}',
        );
      }
    }
  });

  test('provenance manifest covers each bank ID exactly once at item level',
      () {
    final detailIds =
        RegExp(r'^### `(frequency_tr_v1_[a-z0-9_]+)`', multiLine: true)
            .allMatches(provenanceMarkdown)
            .map((m) => m.group(1)!)
            .toList();
    expect(detailIds, equals(bankIds));
    expect(detailIds.toSet(), hasLength(50));

    final tableIds =
        RegExp(r'^\| `(frequency_tr_v1_[a-z0-9_]+)` \|', multiLine: true)
            .allMatches(provenanceMarkdown)
            .map((m) => m.group(1)!)
            .toList();
    expect(tableIds, equals(bankIds));
  });

  test('option balance report has item-level rows for all 50 IDs', () {
    final lengthTableIds = _tableQuestionIdsAfterHeading(
      optionBalanceMarkdown,
      '### Per item',
    );
    expect(lengthTableIds, equals(bankIds));

    final l1TableIds = _tableQuestionIdsAfterHeading(
      optionBalanceMarkdown,
      '## Per-option delta magnitude (L1)',
    );
    expect(l1TableIds, equals(bankIds));

    final mentioned = _questionIds(optionBalanceMarkdown);
    expect(mentioned.toSet(), equals(bankIds.toSet()));
  });

  test('quality and separation reports reference only known bank IDs', () {
    for (final md in [qualityMarkdown, separationMarkdown]) {
      final mentioned = _questionIds(md).toSet();
      expect(mentioned.difference(bankIds.toSet()), isEmpty);
    }
  });

  test('construct separation doc covers disclosure_pace vs emotional_openness',
      () {
    expect(separationMarkdown, contains('disclosure_pace'));
    expect(separationMarkdown, contains('emotional_openness'));
    expect(separationMarkdown, contains('EQ / Frequency module separation'));
  });

  test('documentation coverage fingerprint is deterministic', () {
    final fingerprint = [
      ...bankIds,
      ...RegExp(r'^## Item \d+: `(frequency_tr_v1_[a-z0-9_]+)`',
              multiLine: true)
          .allMatches(evidenceMarkdown)
          .map((m) => m.group(1)!),
      ...RegExp(r'^### `(frequency_tr_v1_[a-z0-9_]+)`', multiLine: true)
          .allMatches(provenanceMarkdown)
          .map((m) => m.group(1)!),
    ].join('|');
    final again = [
      ...bankIds,
      ...RegExp(r'^## Item \d+: `(frequency_tr_v1_[a-z0-9_]+)`',
              multiLine: true)
          .allMatches(evidenceMarkdown)
          .map((m) => m.group(1)!),
      ...RegExp(r'^### `(frequency_tr_v1_[a-z0-9_]+)`', multiLine: true)
          .allMatches(provenanceMarkdown)
          .map((m) => m.group(1)!),
    ].join('|');
    expect(again, fingerprint);
    expect(fingerprint.split('|'), hasLength(150));
  });
}

final _qidRe = RegExp(
  r'frequency_tr_v1_(?:communication_pace|depth_preference|disclosure_pace|'
  r'social_energy|spontaneity|stability)_\d{3}',
);

List<String> _questionIds(String text) =>
    _qidRe.allMatches(text).map((m) => m.group(0)!).toList();

List<String> _tableQuestionIdsAfterHeading(String markdown, String heading) {
  final start = markdown.indexOf(heading);
  expect(start, isNonNegative, reason: 'Missing heading: $heading');
  final from = markdown.substring(start);
  final next = RegExp(r'\n## ').firstMatch(from.substring(heading.length));
  final block =
      next == null ? from : from.substring(0, heading.length + next.start);
  return RegExp(r'^\| `(frequency_tr_v1_[a-z0-9_]+)` \|', multiLine: true)
      .allMatches(block)
      .map((m) => m.group(1)!)
      .toList();
}
