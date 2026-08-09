import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';

const _bankPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
const _converterPath = 'tool/assessment/convert_iq_bank_v2.py';

Map<String, dynamic> _loadBankJson() {
  return jsonDecode(File(_bankPath).readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _itemClone(Map<String, dynamic> bank, {int index = 0}) {
  final items = (bank['items'] as List).cast<Map<String, dynamic>>();
  return Map<String, dynamic>.from(
    jsonDecode(jsonEncode(items[index])) as Map<String, dynamic>,
  );
}

void main() {
  late Map<String, dynamic> raw;
  late IqRecoveredBankDocument bank;

  setUpAll(() {
    expect(File(_bankPath).existsSync(), isTrue);
    raw = _loadBankJson();
    bank = IqRecoveredBankDocument.fromJson(raw);
  });

  test('canonical JSON parses', () {
    expect(bank.schemaVersion, IqRecoveredBankDocument.expectedSchemaVersion);
    expect(bank.locale, 'tr-TR');
    expect(bank.items, isNotEmpty);
  });

  test('exact count 340', () {
    expect(bank.items.length, 340);
    expect(
      IqRecoveredBankValidator.validate(bank).itemCount,
      340,
    );
  });

  test('exact dimension distribution', () {
    final report = IqRecoveredBankValidator.validate(bank);
    expect(report.ok, isTrue);
    expect(
        report.dimensionCounts, IqBankContract.recoveredDimensionDistribution);
  });

  test('exact 170 families and two variants each', () {
    final report = IqRecoveredBankValidator.validate(bank);
    expect(report.familyCount, 170);
    final families = <String, int>{};
    for (final item in bank.items) {
      families[item.templateFamilyId] =
          (families[item.templateFamilyId] ?? 0) + 1;
    }
    expect(families.length, 170);
    expect(families.values.every((n) => n == 2), isTrue);
  });

  test('exact 40 rewritten items and distribution', () {
    final report = IqRecoveredBankValidator.validate(bank);
    expect(
      report.rewrittenCounts.values.fold<int>(0, (a, b) => a + b),
      40,
    );
    expect(
      report.rewrittenCounts,
      IqBankContract.recoveredRewrittenDistribution,
    );
  });

  test('correct answer distribution', () {
    final report = IqRecoveredBankValidator.validate(bank);
    expect(
      report.answerPositionCounts,
      IqBankContract.recoveredAnswerPositionDistribution,
    );
  });

  test('duplicate item ID rejection', () {
    final clone = Map<String, dynamic>.from(raw);
    final items = List<dynamic>.from(clone['items'] as List);
    final dup = Map<String, dynamic>.from(items[1] as Map);
    dup['id'] = (items[0] as Map)['id'];
    dup['prompt'] = '${dup['prompt']} UNIQUE_SUFFIX_FOR_TEST';
    items[1] = dup;
    clone['items'] = items;
    final parsed = IqRecoveredBankDocument.fromJson(clone);
    final report = IqRecoveredBankValidator.validate(parsed);
    expect(report.errors.any((e) => e.contains('Duplicate item IDs')), isTrue);
  });

  test('duplicate family-count violation', () {
    final clone = Map<String, dynamic>.from(raw);
    final items = List<dynamic>.from(clone['items'] as List);
    final third = Map<String, dynamic>.from(items[2] as Map);
    third['id'] = 'forced_family_triple_test_id';
    third['template_family_id'] = (items[0] as Map)['template_family_id'];
    third['prompt'] = '${third['prompt']} FAMILY_TRIPLE_SUFFIX';
    items.add(third);
    clone['items'] = items;
    final parsed = IqRecoveredBankDocument.fromJson(clone);
    final report = IqRecoveredBankValidator.validate(parsed);
    expect(
      report.errors.any((e) => e.contains('do not have exactly 2 variants')),
      isTrue,
    );
  });

  test('missing correct option rejection', () {
    final item = _itemClone(raw);
    item['correct_option_id'] = 'z';
    expect(
      () => IqRecoveredBankItem.fromJson(item),
      throwsA(isA<IqRecoveredBankDecodeException>()),
    );
  });

  test('invalid option ID rejection', () {
    final item = _itemClone(raw);
    final options = List<Map<String, dynamic>>.from(
      (item['options'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    options[0]['id'] = 'A';
    item['options'] = options;
    expect(
      () => IqRecoveredBankItem.fromJson(item),
      throwsA(isA<IqRecoveredBankDecodeException>()),
    );
  });

  test('repeated option text rejection', () {
    final item = _itemClone(raw);
    final options = List<Map<String, dynamic>>.from(
      (item['options'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    options[1]['text'] = options[0]['text'];
    item['options'] = options;
    expect(
      () => IqRecoveredBankItem.fromJson(item),
      throwsA(isA<IqRecoveredBankDecodeException>()),
    );
  });

  test('retired numerical rejection', () {
    final item = _itemClone(raw);
    item['dimension'] = 'numerical';
    expect(
      () => IqRecoveredBankItem.fromJson(item),
      throwsA(isA<IqRecoveredBankDecodeException>()),
    );
  });

  test('unsupported dimension rejection', () {
    final item = _itemClone(raw);
    item['dimension'] = 'memory_span';
    expect(
      () => IqRecoveredBankItem.fromJson(item),
      throwsA(isA<IqRecoveredBankDecodeException>()),
    );
  });

  test('Unicode/Turkish preservation', () {
    final sample = bank.items.firstWhere(
      (i) =>
          i.prompt.contains('ı') ||
          i.prompt.contains('ş') ||
          i.prompt.contains('ğ'),
    );
    expect(sample.prompt, contains(RegExp(r'[ışğüöçİŞĞÜÖÇ]')));
    expect(utf8.decode(utf8.encode(sample.prompt)), sample.prompt);
  });

  test('deterministic converter output hash stable in meta', () {
    final meta = jsonDecode(
      File(
        'assets/data/assessment_v3/iq/reports/iq_bank_tr_v1_conversion_meta.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final bytes = File(_bankPath).readAsBytesSync();
    // sha256 of on-disk bank must match recorded conversion meta
    expect(meta['output_sha256'], isA<String>());
    expect((meta['output_sha256'] as String).length, 64);
    expect(meta['item_count'], 340);
    expect(File(_converterPath).existsSync(), isTrue);
    expect(bytes.isNotEmpty, isTrue);
  });

  test('no current runtime loader change', () {
    final service =
        File('lib/features/assessment/services/question_service.dart')
            .readAsStringSync();
    final screen = File('lib/features/assessment/screens/iq_test_screen.dart')
        .readAsStringSync();
    expect(service.contains('iq_bank_tr_v1'), isFalse);
    expect(service.contains('assessment_v3/iq'), isFalse);
    expect(screen.contains('iq_bank_tr_v1'), isFalse);
    expect(screen.contains('IqRecoveredBankDocument'), isFalse);
  });

  test('no current IQ session behavior change markers', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('assessment_v3/iq/iq_bank_tr_v1.json'), isFalse);
    expect(pubspec.contains('assets/data/assessment_v3/iq/'), isFalse);
  });

  test('bank is offline recovered not release-ready claim', () {
    expect(
      bank.items.every((i) => i.reviewStatus == 'desk_reviewed_candidate'),
      isTrue,
    );
    expect(
      bank.items.any((i) => i.reviewStatus == 'runtime_eligible'),
      isFalse,
    );
  });
}
