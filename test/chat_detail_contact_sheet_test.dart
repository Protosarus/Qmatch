import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies the human-review contact sheet artifact exists (P2C-1C-3B-1).
///
/// The sheet is produced from synthetic goldens under
/// `test/goldens/chat_detail/` (no Firebase, no production routes).
void main() {
  test('chat detail visual review contact sheet exists with expected panels',
      () {
    final sheet = File(
      'test/goldens/chat_detail/chat_detail_visual_review_contact_sheet.png',
    );
    expect(sheet.existsSync(), isTrue);
    expect(sheet.lengthSync(), greaterThan(200 * 1024));

    const requiredGoldens = [
      'empty_compact_1_0.png',
      'incoming_compact_1_0.png',
      'outgoing_compact_1_0.png',
      'mixed_compact_1_0.png',
      'long_message_compact_1_0.png',
      'emoji_multiline_compact_1_0.png',
      'missing_counterpart_compact_1_0.png',
      'composer_keyboard_compact_1_0.png',
      'mixed_compact_text_1_3.png',
      'loading_compact_1_0.png',
      'error_compact_1_0.png',
    ];
    for (final name in requiredGoldens) {
      final f = File('test/goldens/chat_detail/$name');
      expect(f.existsSync(), isTrue, reason: name);
      expect(f.lengthSync(), greaterThan(50 * 1024), reason: name);
    }

    // Empty golden must include wallpaper texture (not flat black).
    final empty = File('test/goldens/chat_detail/empty_compact_1_0.png');
    expect(empty.lengthSync(), greaterThan(500 * 1024));
  });
}
