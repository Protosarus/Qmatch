import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/match_close_lifecycle_gate.dart';

void main() {
  group('MatchCloseLifecycleGate — close matrix', () {
    test('active → unmatched closes match + thread', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.active.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.unmatched,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'active',
      );
      expect(plan.updateMatch, isTrue);
      expect(plan.newMatchState, MatchState.unmatched.name);
      expect(plan.updateThread, isTrue);
      expect(plan.threadClosedReason, 'unmatched');
      expect(plan.refuseNotMember, isFalse);
      expect(plan.idempotent, isFalse);
    });

    test('active → blocked closes match + thread', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.active.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.blocked,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'active',
      );
      expect(plan.updateMatch, isTrue);
      expect(plan.newMatchState, MatchState.blocked.name);
      expect(plan.updateThread, isTrue);
      expect(plan.threadClosedReason, 'blocked');
    });

    test('retry after unmatched close is idempotent', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.unmatched.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.unmatched,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'closed',
      );
      expect(plan.updateMatch, isFalse);
      expect(plan.updateThread, isFalse);
      expect(plan.idempotent, isTrue);
    });

    test('already blocked + block retry is idempotent', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.blocked.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.blocked,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'closed',
      );
      expect(plan.updateMatch, isFalse);
      expect(plan.updateThread, isFalse);
      expect(plan.idempotent, isTrue);
    });

    test('unmatch does not downgrade blocked match', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.blocked.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.unmatched,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'closed',
      );
      expect(plan.updateMatch, isFalse);
      expect(plan.newMatchState, isNull);
    });

    test('block upgrades unmatched → blocked', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.unmatched.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.blocked,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'closed',
      );
      expect(plan.updateMatch, isTrue);
      expect(plan.newMatchState, MatchState.blocked.name);
      expect(plan.updateThread, isFalse); // already closed
    });

    test('partial/missing thread — match still closes', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.active.name,
        actorIsMatchMember: true,
        target: MatchCloseTarget.unmatched,
        threadExists: false,
        actorIsThreadParticipant: false,
        currentThreadStatus: null,
      );
      expect(plan.updateMatch, isTrue);
      expect(plan.newMatchState, MatchState.unmatched.name);
      expect(plan.updateThread, isFalse);
    });

    test('missing match + active thread — close thread only', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: false,
        currentMatchState: null,
        actorIsMatchMember: false,
        target: MatchCloseTarget.blocked,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'active',
      );
      expect(plan.updateMatch, isFalse);
      expect(plan.updateThread, isTrue);
      expect(plan.threadClosedReason, 'blocked');
    });

    test('no accidental reopen — never plans active', () {
      for (final target in MatchCloseTarget.values) {
        for (final state in [
          MatchState.active.name,
          MatchState.unmatched.name,
          MatchState.blocked.name,
          null,
          'weird',
        ]) {
          final plan = MatchCloseLifecycleGate.plan(
            matchExists: true,
            currentMatchState: state,
            actorIsMatchMember: true,
            target: target,
            threadExists: true,
            actorIsThreadParticipant: true,
            currentThreadStatus: 'closed',
          );
          expect(plan.newMatchState, isNot(MatchState.active.name));
        }
      }
    });

    test('non-member refused', () {
      final plan = MatchCloseLifecycleGate.plan(
        matchExists: true,
        currentMatchState: MatchState.active.name,
        actorIsMatchMember: false,
        target: MatchCloseTarget.unmatched,
        threadExists: true,
        actorIsThreadParticipant: true,
        currentThreadStatus: 'active',
      );
      expect(plan.refuseNotMember, isTrue);
      expect(plan.updateMatch, isFalse);
      expect(plan.updateThread, isFalse);
    });

    test('resolveThreadId prefers match.thread_id then explicit then matchId', () {
      expect(
        MatchCloseLifecycleGate.resolveThreadId(
          matchId: 'a_b',
          matchThreadId: 'a_b',
          explicitThreadId: 'other',
        ),
        'a_b',
      );
      expect(
        MatchCloseLifecycleGate.resolveThreadId(
          matchId: 'a_b',
          matchThreadId: null,
          explicitThreadId: 'a_b',
        ),
        'a_b',
      );
      expect(
        MatchCloseLifecycleGate.resolveThreadId(
          matchId: 'a_b',
          matchThreadId: '',
          explicitThreadId: null,
        ),
        'a_b',
      );
    });
  });

  group('wiring isolation', () {
    test('MatchService unmatch uses transaction + close gate', () {
      final src = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      expect(src.contains('MatchCloseLifecycleGate'), isTrue);
      expect(src.contains('runTransaction'), isTrue);
      expect(src.contains('MatchCloseTarget.unmatched'), isTrue);
      expect(src.contains('CompatibilityScoring'), isFalse);
      expect(src.contains('DiscoverService'), isFalse);
    });

    test('SafetyService block uses atomic close relationship', () {
      final src = File(
        'lib/features/safety/services/safety_service.dart',
      ).readAsStringSync();
      expect(src.contains('closeRelationshipInTransaction'), isTrue);
      expect(src.contains('MatchCloseTarget.blocked'), isTrue);
      expect(src.contains('CompatibilityScoring'), isFalse);
    });

    test('rules allow unmatched→blocked and never rematch to active', () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(rules.contains("resource.data.state == 'unmatched'"), isTrue);
      expect(rules.contains("request.resource.data.state == 'blocked'"), isTrue);
      // Rematch still blocked: no path setting state to active on update except equality.
      expect(
        rules.contains(
          "request.resource.data.state == 'active'\n"
          "          && resource.data.state != 'active'",
        ),
        isFalse,
      );
    });
  });
}
