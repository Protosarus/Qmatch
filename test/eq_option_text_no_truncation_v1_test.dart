import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/widgets/eq_question_chrome.dart';

void main() {
  test('EqAnswerOptionRow.displayLabel keeps full EQ bank option text', () {
    final data = jsonDecode(
      File('assets/data/assessment_v3/eq/eq_bank_tr_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    var checked = 0;
    var longerThanOldCap = 0;
    for (final item in items) {
      final options =
          (item as Map<String, dynamic>)['options'] as List<dynamic>;
      for (final option in options) {
        final text =
            ((option as Map<String, dynamic>)['text'] as String).trim();
        final shown = EqAnswerOptionRow.displayLabel(text);
        final normalized = text.replaceAll(RegExp(r'\s+'), ' ');
        expect(shown, normalized);
        expect(shown.contains('…'), isFalse);
        if (normalized.length > 64) longerThanOldCap++;
        checked++;
      }
    }
    expect(checked, 120);
    expect(longerThanOldCap, greaterThan(0));
  });

  test('eq chrome does not reintroduce char-cap truncation', () {
    final src = File(
      'lib/features/assessment/widgets/eq_question_chrome.dart',
    ).readAsStringSync();
    expect(src.contains('maxChars'), isFalse);
    expect(src.contains(r"return '$base…';"), isFalse);
    expect(
      src.contains('maxLines: 2,\n                      overflow: TextOverflow.ellipsis'),
      isFalse,
    );
  });
}
