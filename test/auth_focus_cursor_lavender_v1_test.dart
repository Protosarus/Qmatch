import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login and phone signup focus/cursor accents use lavender not softGold',
      () {
    const lavender = '0xFFDAC8ED';
    for (final path in [
      'lib/features/auth/screens/login_screen.dart',
      'lib/features/auth/screens/phone_signup_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains(lavender), isTrue, reason: path);
      expect(src.contains('cursorColor'), isTrue, reason: path);
      // Focus/floating-label path must not use softGold.
      expect(
        src.contains('focused ? AppColors.softGold'),
        isFalse,
        reason: path,
      );
      expect(
        src.contains('const accent = AppColors.softGold'),
        isFalse,
        reason: path,
      );
      expect(
        src.contains('searchFieldCursorColor: accent'),
        path.contains('phone'),
        reason: 'phone country search keeps cursor via accent',
      );
    }
  });
}
