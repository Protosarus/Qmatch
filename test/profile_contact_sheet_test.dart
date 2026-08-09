import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies Profile visual review contact sheet (P2C-1C-4B).
void main() {
  test('profile visual review contact sheet exists with expected panels', () {
    final sheet = File(
      'test/goldens/profile/profile_visual_review_contact_sheet.png',
    );
    expect(sheet.existsSync(), isTrue);
    expect(sheet.lengthSync(), greaterThan(100 * 1024));

    const requiredGoldens = [
      'full_compact_1_0.png',
      'name_only_compact_1_0.png',
      'missing_photo_compact_1_0.png',
      'missing_bio_compact_1_0.png',
      'empty_interests_compact_1_0.png',
      'many_interests_compact_1_0.png',
      'long_turkish_name_compact_1_0.png',
      'long_cyrillic_name_compact_1_0.png',
      'long_bio_compact_1_0.png',
      'loading_compact_1_0.png',
      'error_compact_1_0.png',
      'full_compact_1_3.png',
      'full_standard_1_0.png',
    ];
    for (final name in requiredGoldens) {
      final f = File('test/goldens/profile/$name');
      expect(f.existsSync(), isTrue, reason: name);
      expect(f.lengthSync(), greaterThan(40 * 1024), reason: name);
    }
  });
}
