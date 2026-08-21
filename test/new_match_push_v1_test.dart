import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/notifications/message_push_tap_router.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';

Map<String, String> matchPayload({
  String matchId = 'userA_userB',
  String threadId = 'userA_userB',
  String otherUid = 'userB',
}) {
  return {
    'type': 'match',
    'match_id': matchId,
    'thread_id': threadId,
    'other_uid': otherUid,
  };
}

ChatThreadModel activeThread({
  String id = 'userA_userB',
  List<String> participants = const ['userA', 'userB'],
  ThreadStatus status = ThreadStatus.active,
}) {
  return ChatThreadModel(
    threadId: id,
    participants: participants,
    status: status,
  );
}

MatchModel activeMatch({
  String id = 'userA_userB',
  List<String> users = const ['userA', 'userB'],
  MatchState state = MatchState.active,
  String threadId = 'userA_userB',
}) {
  return MatchModel(
    matchId: id,
    userA: users[0],
    userB: users[1],
    users: users,
    threadId: threadId,
    createdBy: 'system',
    state: state,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String read(String path) => File(path).readAsStringSync();

  late MessagePushTapRouter router;

  setUp(() {
    router = MessagePushTapRouter();
  });

  test('match tap opens the correct chat', () async {
    final result = await router.handle(
      data: matchPayload(),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      loadMatch: (_) async => activeMatch(),
      blockExists: (_, __) async => false,
    );
    expect(result.outcome, MessagePushTapOutcome.openChat);
    expect(result.threadId, 'userA_userB');
    expect(result.otherUserId, 'userB');
  });

  test('invalid match tap falls back safely', () async {
    final closed = await router.handle(
      data: matchPayload(),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(status: ThreadStatus.closed),
      loadMatch: (_) async => activeMatch(),
      blockExists: (_, __) async => false,
    );
    expect(closed.outcome, MessagePushTapOutcome.fallbackMessages);

    final router2 = MessagePushTapRouter();
    final inactiveMatch = await router2.handle(
      data: matchPayload(matchId: 'm2'),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      loadMatch: (_) async => activeMatch(state: MatchState.unmatched),
      blockExists: (_, __) async => false,
    );
    expect(inactiveMatch.outcome, MessagePushTapOutcome.fallbackMessages);

    final router3 = MessagePushTapRouter();
    final blocked = await router3.handle(
      data: matchPayload(matchId: 'm3'),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      loadMatch: (_) async => activeMatch(),
      blockExists: (from, to) async => from == 'userA' && to == 'userB',
    );
    expect(blocked.outcome, MessagePushTapOutcome.fallbackMessages);
  });

  test('duplicate match tap navigates once', () async {
    final first = await router.handle(
      data: matchPayload(),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      loadMatch: (_) async => activeMatch(),
      blockExists: (_, __) async => false,
    );
    final second = await router.handle(
      data: matchPayload(),
      currentUid: 'userA',
      loadThread: (_) async => activeThread(),
      loadMatch: (_) async => activeMatch(),
      blockExists: (_, __) async => false,
    );
    expect(first.outcome, MessagePushTapOutcome.openChat);
    expect(second.outcome, MessagePushTapOutcome.ignore);
  });

  test('match push trigger is europe-west1 on matches create', () {
    final index = read('functions/index.js');
    final start =
        index.indexOf('exports.sendNewMatchPush = onDocumentCreated(');
    expect(start, greaterThan(0));
    final end = index.indexOf('exports.handleMatchCreated', start);
    expect(end, greaterThan(start));
    final block = index.substring(start, end);
    expect(block.contains("document: 'matches/{matchId}'"), isTrue);
    expect(block.contains("region: 'europe-west1'"), isTrue);

    final src = read('functions/src/new_match_push.js');
    expect(src.contains("type: PUSH_TYPE"), isTrue);
    expect(src.contains("match_id: String(matchId)"), isTrue);
    expect(src.contains("thread_id: String(threadId)"), isTrue);
    expect(src.contains("other_uid: String(otherUid)"), isTrue);
    expect(src.contains('You have a new match.'), isTrue);
    expect(src.contains('handleLikeAndMaybeCreateMatch'), isFalse);
    expect(src.contains('sendSuperResonance'), isFalse);
  });
}
