import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/like_match_atomicity_gate.dart';
import 'package:qmatch/features/matching/services/match_create_lifecycle_gate.dart';
import 'package:qmatch/features/matching/services/match_live_user_validity_gate.dart';

Map<String, dynamic> _validUser({
  bool active = true,
  bool discoverEligible = true,
  bool profileCompleted = true,
  bool testCompleted = true,
  bool assessmentFlowCompleted = false,
  String? photoUrl = 'https://example.com/p.jpg',
  List<String>? photos,
}) {
  return <String, dynamic>{
    'active': active,
    'discover_eligible': discoverEligible,
    'profile_completed': profileCompleted,
    'test_completed': testCompleted,
    'assessment_flow_completed': assessmentFlowCompleted,
    if (photoUrl != null) 'profile_photo_url': photoUrl,
    if (photos != null) 'photos': photos,
  };
}

void main() {
  group('MatchLiveUserValidityGate', () {
    test('missing target / non-existent doc is invalid', () {
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(exists: false, data: null),
        isFalse,
      );
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(exists: true, data: null),
        isFalse,
      );
    });

    test('inactive target is invalid', () {
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(active: false),
        ),
        isFalse,
      );
    });

    test('discover_eligible=false is invalid', () {
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(discoverEligible: false),
        ),
        isFalse,
      );
    });

    test('incomplete assessment/profile is invalid', () {
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(profileCompleted: false),
        ),
        isFalse,
      );
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(
            testCompleted: false,
            assessmentFlowCompleted: false,
          ),
        ),
        isFalse,
      );
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(photoUrl: null, photos: const []),
        ),
        isFalse,
      );
    });

    test('valid target passes (photo url or photos list)', () {
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(),
        ),
        isTrue,
      );
      expect(
        MatchLiveUserValidityGate.isValidLiveUser(
          exists: true,
          data: _validUser(
            photoUrl: null,
            photos: const ['https://example.com/alt.jpg'],
            testCompleted: false,
            assessmentFlowCompleted: true,
          ),
        ),
        isTrue,
      );
    });
  });

  group('stale-card Like rejected', () {
    test('invalid target — no Like persist, no match create', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: true,
        targetLiveEligible: false,
      );
      expect(plan.persistOwnLike, isFalse);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.matched, isFalse);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.refuseInvalidLiveUser,
      );
    });

    test('invalid viewer — no Like persist, no match create', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: false,
        targetLiveEligible: true,
      );
      expect(plan.persistOwnLike, isFalse);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.refuseInvalidLiveUser,
      );
    });

    test('valid mutual Like still creates', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: true,
        targetLiveEligible: true,
      );
      expect(plan.persistOwnLike, isTrue);
      expect(plan.writeMatchArtifacts, isTrue);
      expect(plan.matchDecision, MatchCreateLifecycleDecision.createNew);
    });
  });

  group('existing active chat remains untouched', () {
    test('invalid target with active match — no Like write, chat stays active',
        () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: true,
        matchState: MatchState.active.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: true,
        targetLiveEligible: false,
      );
      expect(plan.persistOwnLike, isFalse);
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.matched, isTrue);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.idempotentActiveSuccess,
      );
    });

    test('MatchService invalid path does not close match/thread (source)', () {
      final src = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      final likeIdx = src.indexOf('Future<bool> likeAndMaybeCreateMatch');
      final unmatchIdx = src.indexOf('Future<void> unmatch');
      expect(likeIdx, greaterThanOrEqualTo(0));
      expect(unmatchIdx, greaterThan(likeIdx));
      final likeBody = src.substring(likeIdx, unmatchIdx);
      expect(likeBody.contains('MatchLiveUserValidityGate'), isTrue);
      expect(likeBody.contains('persistOwnLike'), isTrue);
      expect(likeBody.contains('MatchCloseLifecycleGate'), isFalse);
      expect(likeBody.contains("state': 'unmatched'"), isFalse);
      expect(likeBody.contains("status': 'closed'"), isFalse);
      expect(likeBody.contains('closeRelationship'), isFalse);
    });
  });

  group('deletion request clears discover_eligible', () {
    test('AccountDeletionRequestService soft marker revokes eligibility', () {
      final src = File(
        'lib/features/settings/services/account_deletion_request_service.dart',
      ).readAsStringSync();
      expect(src.contains("'account_deletion_requested': true"), isTrue);
      expect(src.contains("'discover_eligible': false"), isTrue);
      // Soft request only — no match/thread teardown on submit.
      expect(src.contains('MatchCloseLifecycleGate'), isFalse);
      expect(src.contains('unmatch'), isFalse);
      expect(src.contains('threads/'), isFalse);
    });
  });
}
