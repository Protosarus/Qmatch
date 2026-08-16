import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_l1_eligibility_gate.dart';

void main() {
  group('DiscoverL1EligibilityGate — blocks (L1 hard safety)', () {
    test('viewer blocks candidate → excluded', () {
      expect(
        DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: true,
          candidateBlockedViewer: false,
        ),
        isTrue,
      );
    });

    test('candidate blocks viewer (reverse-block) → excluded', () {
      expect(
        DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: false,
          candidateBlockedViewer: true,
        ),
        isTrue,
      );
    });

    test('neither blocks → not excluded', () {
      expect(
        DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: false,
          candidateBlockedViewer: false,
        ),
        isFalse,
      );
    });

    test('both directions blocked → excluded', () {
      expect(
        DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: true,
          candidateBlockedViewer: true,
        ),
        isTrue,
      );
    });
  });

  group('DiscoverL1EligibilityGate — assessment completion OR', () {
    test('test_completed=true alone → assessments completed', () {
      expect(
        DiscoverL1EligibilityGate.assessmentsCompleted(
          testCompleted: true,
          assessmentFlowCompleted: false,
        ),
        isTrue,
      );
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: true,
          profileCompleted: true,
          testCompleted: true,
          assessmentFlowCompleted: false,
          hasPhoto: true,
        ),
        isTrue,
      );
    });

    test('assessment_flow_completed=true alone → assessments completed', () {
      expect(
        DiscoverL1EligibilityGate.assessmentsCompleted(
          testCompleted: false,
          assessmentFlowCompleted: true,
        ),
        isTrue,
      );
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: true,
          profileCompleted: true,
          testCompleted: false,
          assessmentFlowCompleted: true,
          hasPhoto: true,
        ),
        isTrue,
      );
    });

    test('both completion flags false → not eligible', () {
      expect(
        DiscoverL1EligibilityGate.assessmentsCompleted(
          testCompleted: false,
          assessmentFlowCompleted: false,
        ),
        isFalse,
      );
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: true,
          profileCompleted: true,
          testCompleted: false,
          assessmentFlowCompleted: false,
          hasPhoto: true,
        ),
        isFalse,
      );
    });

    test('both completion flags true → eligible', () {
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: true,
          profileCompleted: true,
          testCompleted: true,
          assessmentFlowCompleted: true,
          hasPhoto: true,
        ),
        isTrue,
      );
    });
  });

  group('DiscoverUserModel assessment_flow_completed mapping', () {
    test('maps assessment_flow_completed from Firestore', () {
      final onlyFlow = DiscoverUserModel.fromFirestore('u1', {
        'name': 'A',
        'age': 30,
        'profile_completed': true,
        'test_completed': false,
        'assessment_flow_completed': true,
        'profile_photo_url': 'https://example.com/a.jpg',
        'active': true,
      });
      expect(onlyFlow.testCompleted, isFalse);
      expect(onlyFlow.assessmentFlowCompleted, isTrue);
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: onlyFlow.active,
          profileCompleted: onlyFlow.profileCompleted,
          testCompleted: onlyFlow.testCompleted,
          assessmentFlowCompleted: onlyFlow.assessmentFlowCompleted,
          hasPhoto: onlyFlow.hasPhoto,
        ),
        isTrue,
      );

      final neither = DiscoverUserModel.fromFirestore('u2', {
        'name': 'B',
        'age': 30,
        'profile_completed': true,
        'test_completed': false,
        'assessment_flow_completed': false,
        'profile_photo_url': 'https://example.com/b.jpg',
        'active': true,
      });
      expect(
        DiscoverL1EligibilityGate.passesLocalAccountGates(
          active: neither.active,
          profileCompleted: neither.profileCompleted,
          testCompleted: neither.testCompleted,
          assessmentFlowCompleted: neither.assessmentFlowCompleted,
          hasPhoto: neither.hasPhoto,
        ),
        isFalse,
      );
    });
  });

  group('DiscoverService L1 wiring', () {
    test('uses owner-block + assessment OR gate; reverse-block via trusted omit',
        () {
      final src = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(src.contains('DiscoverL1EligibilityGate'), isTrue);
      expect(src.contains('getMyBlockedUserIds'), isTrue);
      expect(src.contains('getUidsWhoBlockedMe'), isFalse);
      expect(src.contains('isBlockedByUser'), isFalse);
      expect(src.contains('applyTrustedMembership'), isTrue);
      expect(src.contains('candidateBlockedViewer: false'), isTrue);
      expect(src.contains('excludedByBlocks'), isTrue);
      expect(src.contains('passesLocalAccountGates'), isTrue);
      expect(src.contains('assessmentFlowCompleted'), isTrue);
      // Must not require only testCompleted anymore.
      expect(
        src.contains('!candidate.testCompleted || !candidate.profileCompleted'),
        isFalse,
      );
      // No L1 preference filters (L3 soft shadow is post-rank diagnostics only).
      expect(src.contains('age_range'), isFalse);
      expect(src.contains('distance_preference'), isFalse);
      expect(src.contains('interested_in'), isFalse);
      // L3 soft shadow must not participate in L1 gates.
      expect(src.contains('DiscoverL3SoftPreference'), isTrue);
      expect(
        src.indexOf('passesLocalAccountGates') <
            src.indexOf('_l3ShadowAttacher.attach'),
        isTrue,
      );

      final safety = File(
        'lib/features/safety/services/safety_service.dart',
      ).readAsStringSync();
      expect(safety.contains('getUidsWhoBlockedMe'), isFalse);
      expect(safety.contains('isBlockedByUser'), isFalse);
      expect(safety.contains('getMyBlockedUserIds'), isTrue);
    });
  });
}

