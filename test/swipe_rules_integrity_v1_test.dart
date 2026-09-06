import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('swipe rules integrity v1', () {
    late String swipeRules;

    setUpAll(() {
      final rules = File('firestore.rules').readAsStringSync();

      final start = rules.indexOf('match /swipes/{targetUid}');
      final end = rules.indexOf('match /blocks/{blockedUid}', start);

      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));

      swipeRules = rules.substring(start, end);
    });

    test('client may create only a Pass swipe', () {
      expect(
        swipeRules.contains('allow create: if isVerifiedOwner(uid)'),
        isTrue,
      );
      expect(
        swipeRules.contains(
          "request.resource.data.direction == 'pass'",
        ),
        isTrue,
      );
    });

    test('client cannot downgrade an Admin Like into Pass', () {
      expect(
        swipeRules.contains('allow update: if isVerifiedOwner(uid)'),
        isTrue,
      );
      expect(
        swipeRules.contains("resource.data.direction == 'pass'"),
        isTrue,
      );
      expect(
        swipeRules.contains(
          "request.resource.data.direction == 'pass'",
        ),
        isTrue,
      );
    });

    test('client swipe deletion remains forbidden', () {
      expect(
        swipeRules.contains('allow delete: if false;'),
        isTrue,
      );
    });

    test('legacy permissive create/update rule is gone', () {
      expect(
        swipeRules.contains('allow create, update:'),
        isFalse,
      );
      expect(
        swipeRules.contains(
          "request.resource.data.direction != 'like'",
        ),
        isFalse,
      );
    });
  });
}
