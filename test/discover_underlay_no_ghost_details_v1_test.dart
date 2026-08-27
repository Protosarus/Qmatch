import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Discover underlay suppresses details without changing current card',
      () {
    final screen = File(
      'lib/features/discover/screens/discover_screen.dart',
    ).readAsStringSync();

    final card = File(
      'lib/features/discover/widgets/qmatch_candidate_card.dart',
    ).readAsStringSync();

    expect(card.contains('this.showDetails = true'), isTrue);
    expect(card.contains('final bool showDetails;'), isTrue);
    expect(card.contains('child: showDetails'), isTrue);

    final underlay = screen.indexOf(
      "'qmatch-discover-underlay-",
    );
    final current = screen.indexOf(
      'QMatchDiscoverSwipeableCard(',
      underlay,
    );

    expect(underlay, greaterThanOrEqualTo(0));
    expect(current, greaterThan(underlay));

    final underlayBody = screen.substring(underlay, current);
    expect(underlayBody.contains('showDetails: false'), isTrue);

    final currentBody = screen.substring(current);
    expect(currentBody.contains('candidate: c,'), isTrue);
    expect(currentBody.contains('showDetails: false'), isFalse);
  });
}
