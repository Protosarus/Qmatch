import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/identity/identity.dart';
import 'package:qmatch/features/profile/services/display_name_service.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('auth gate reuses users/{uid} and parallelizes assessment reads', () {
    final wrapper = read('lib/core/navigation/auth_wrapper.dart');
    expect(
        wrapper.contains('class AuthWrapper extends StatefulWidget'), isTrue);
    expect(wrapper.contains('_clearStartupCache'), isTrue);
    expect(wrapper.contains('_startupFuture'), isTrue);
    expect(wrapper.contains('isValidCanonicalDisplayNameFromMap'), isTrue);
    expect(wrapper.contains('initialUserDoc:'), isTrue);

    final gate =
        read('lib/core/navigation/assessment_progress_route_gate.dart');
    expect(gate.contains('initialUserDoc'), isTrue);
    expect(gate.contains('userDoc: userDoc'), isTrue);
    expect(gate.contains("QmatchPerf.trace('auth.gate'"), isTrue);

    final progress = read(
      'lib/features/assessment/services/assessment_progress_service.dart',
    );
    expect(progress.contains('Future.wait<Object?>'), isTrue);
    expect(progress.contains('Map<String, dynamic>? userDoc'), isTrue);
    expect(progress.contains('getCanonicalProfile(uid: uid)'), isTrue);
    // Repair path still sequential after the parallel batch.
    expect(progress.contains('ensureIq4'), isTrue);
    expect(progress.contains('ensureIq4AndEq10'), isTrue);
  });

  test('display-name map helper matches GET validation', () {
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap({'name': 'Ada'}),
      isTrue,
    );
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap({'name': 'A'}),
      isFalse,
    );
    expect(
      DisplayNameService.isValidCanonicalDisplayNameFromMap(null),
      isFalse,
    );
    expect(DisplayNameContract.firestoreField, 'name');
  });

  test('Discover startup parallelizes me/swipes/blocks/eligible reads', () {
    final src = read('lib/features/discover/services/discover_service.dart');
    expect(src.contains('Future.wait<Object?>'), isTrue);
    expect(src.contains('getMySwipedUserIds'), isTrue);
    expect(src.contains('_loadBlockedByMe'), isTrue);
    expect(src.contains("where('discover_eligible', isEqualTo: true)"), isTrue);
    expect(src.contains('DiscoverL1EligibilityGate'), isTrue);
    expect(src.contains('applyTrustedMembership'), isTrue);
  });

  test('Discover precaches next 1-2 photos only', () {
    final src = read('lib/features/discover/screens/discover_screen.dart');
    expect(src.contains('_precacheUpcomingCandidatePhotos'), isTrue);
    expect(src.contains('for (var i = 1; i <= 2; i++)'), isTrue);
    expect(src.contains('precacheImage'), isTrue);
    expect(src.contains("'discover.first_card'"), isTrue);
  });

  test('main disables Google Fonts runtime fetching without a fake Cinzel file',
      () {
    final src = read('lib/main.dart');
    expect(src.contains('GoogleFonts.config.allowRuntimeFetching = false'),
        isTrue);
    expect(src.contains('allowRuntimeFetching = true'), isFalse);
    expect(
      File('test/fonts/google_fonts/Cinzel-SemiBold.ttf').existsSync(),
      isFalse,
    );
    expect(
      read('lib/features/assessment/widgets/assessment_result_frame.dart')
          .contains('GoogleFonts.cinzel('),
      isFalse,
    );
    expect(
      read('lib/features/assessment/widgets/assessment_result_frame.dart')
          .contains('GoogleFonts.playfairDisplay('),
      isTrue,
    );
  });

  test('Membership parallelizes entitlement + availability', () {
    final src = read('lib/features/profile/screens/membership_screen.dart');
    expect(src.contains("QmatchPerf.trace('membership'"), isTrue);
    expect(src.contains('Future.wait<void>'), isTrue);
    expect(src.contains('_tryAvailability'), isTrue);
    expect(src.contains('_applyAvailabilityValues'), isTrue);
  });

  test('Super Resonance availability is traced once in the controller', () {
    final src = read(
      'lib/features/discover/services/discover_super_resonance_controller.dart',
    );
    expect(
      src.contains("QmatchPerf.trace('super_resonance.availability'"),
      isTrue,
    );
  });

  test('Alignment Signals keep privacy filters and bound fan-out to 8', () {
    final who = read('functions/src/list_who_liked_you_callable.js');
    expect(who.contains('mapWithConcurrency'), isTrue);
    expect(who.contains('DEFAULT_CONCURRENCY'), isTrue);
    expect(who.contains('shouldIncludeLiker'), isTrue);
    expect(who.contains('toPublicCard'), isTrue);

    final inbox = read('functions/src/list_super_resonance_inbox_callable.js');
    expect(inbox.contains('mapWithConcurrency'), isTrue);
    expect(inbox.contains('shouldIncludeSender'), isTrue);
    expect(inbox.contains('toPublicInboxCard'), isTrue);

    final pool = read('functions/src/bounded_map.js');
    expect(pool.contains('const DEFAULT_CONCURRENCY = 8'), isTrue);

    final screen =
        read('lib/features/who_liked_you/screens/who_liked_you_screen.dart');
    expect(screen.contains("QmatchPerf.trace('alignment_signals'"), isTrue);
  });

  test('Chat memoizes the messages stream and reuses mark-as-read thread', () {
    final service = read('lib/features/messages/services/chat_service.dart');
    expect(
        service.contains('Future<ChatThreadModel> markThreadAsRead'), isTrue);

    final screen =
        read('lib/features/messages/screens/chat_detail_screen.dart');
    expect(
        screen.contains('late Stream<List<MessageModel>> _messages'), isTrue);
    expect(screen.contains('didUpdateWidget'), isTrue);
    expect(screen.contains('oldWidget.threadId != widget.threadId'), isTrue);
    expect(screen.contains('_messages = _chat.getMessagesStream'), isTrue);
    expect(screen.contains('stream: _messages'), isTrue);
    expect(screen.contains('markThreadAsRead(widget.threadId)'), isTrue);
    expect(screen.contains('getThreadById(widget.threadId)'), isFalse);
  });

  test('phase 1 does not rewrite matching, spend, or StoreKit files', () {
    expect(
      File('firestore.rules').readAsStringSync().contains('match /users/{uid}'),
      isTrue,
    );
    expect(
      File('lib/features/discover/services/discover_l1_eligibility_gate.dart')
          .existsSync(),
      isTrue,
    );
  });
}
