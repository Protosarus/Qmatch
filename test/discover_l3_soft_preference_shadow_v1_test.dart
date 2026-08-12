import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_l1_eligibility_gate.dart';
import 'package:qmatch/features/discover/services/discover_l3_soft_preference_shadow.dart';
import 'package:qmatch/features/matching/domain/l3_soft_preference_signal.dart';

DiscoverUserModel _candidate({
  required String uid,
  double? score,
  int age = 28,
}) {
  return DiscoverUserModel(
    uid: uid,
    name: uid,
    age: age,
    profilePhotoUrl: 'https://example.com/$uid.jpg',
    profileCompleted: true,
    testCompleted: true,
    compatibilityScore: score,
  );
}

void main() {
  const parser = DiscoverL3SoftPreferenceInputParser();
  const attacher = DiscoverL3SoftPreferenceShadowAttacher();

  group('DiscoverL3SoftPreferenceInputParser — no imputation', () {
    test('missing age / age_range / location / prefs / interests → null', () {
      const empty = <String, dynamic>{};
      expect(parser.age(empty), isNull);
      expect(parser.ageRange(empty), isNull);
      expect(parser.location(empty), isNull);
      expect(parser.distancePreferenceKm(empty), isNull);
      expect(parser.interests(empty), isNull);
    });

    test('present empty interests is empty list, not null', () {
      expect(parser.interests({'interests': <String>[]}), isEmpty);
    });

    test('map location shape accepted', () {
      final loc = parser.location({
        'location': {'latitude': 41.0, 'longitude': 29.0},
      });
      expect(loc?.latitude, 41.0);
      expect(loc?.longitude, 29.0);
    });
  });

  group('DiscoverL3SoftPreferenceShadowAttacher', () {
    test('computes L3 values for eligible ranked pairs', () {
      final me = <String, dynamic>{
        'age': 30,
        'age_range': [25, 35],
        'location': {'latitude': 41.0082, 'longitude': 28.9784},
        'distance_preference': 50,
        'interests': ['Music', 'Travel'],
      };
      final ranked = [
        _candidate(uid: 'near', score: 0.9, age: 28),
        _candidate(uid: 'far', score: 0.4, age: 40),
      ];
      final candData = <String, Map<String, dynamic>>{
        'near': {
          'age': 28,
          'age_range': [27, 40],
          'location': {'latitude': 41.06, 'longitude': 29.01},
          'distance_preference': 40,
          'interests': ['music', 'Hiking'],
        },
        'far': {
          'age': 40,
          'age_range': [20, 30], // does not accept me=30? 30 is in range
          'location': {'latitude': 41.5, 'longitude': 29.5},
          'distance_preference': 5,
          'interests': ['Coding'],
        },
      };

      final attached = attacher.attach(
        meUserData: me,
        rankedCandidates: ranked,
        candidateUserData: candData,
      );

      expect(attached.candidates.map((c) => c.uid).toList(), ['near', 'far']);
      expect(attached.candidates[0].compatibilityScore, 0.9);
      expect(attached.candidates[1].compatibilityScore, 0.4);

      final near = attached.diagnostics['near']!;
      expect(near.legacyRank, 1);
      expect(near.age.available, isTrue);
      expect(near.age.mutualFit, isTrue);
      expect(near.distance.available, isTrue);
      expect(near.distance.withinMutualCap, isTrue);
      expect(near.interests.available, isTrue);
      expect(near.interests.jaccard, closeTo(1 / 3, 1e-12)); // music ∩; union 3

      final far = attached.diagnostics['far']!;
      expect(far.legacyRank, 2);
      expect(far.age.available, isTrue);
      // me accepts far? 40 in [25,35]? false; far accepts me? 30 in [20,30]? true
      expect(far.age.aAcceptsB, isFalse);
      expect(far.age.bAcceptsA, isTrue);
      expect(far.age.mutualFit, isFalse);
      expect(far.distance.available, isTrue);
      expect(far.distance.withinMutualCap, isFalse);
      expect(far.interests.available, isTrue);
      expect(far.interests.jaccard, 0.0);

      final export = near.toExportMap();
      expect(export.containsKey('combined_l3_score'), isTrue);
      expect(export['combined_l3_score'], isNull);
      expect(export['looking_for_active'], isFalse);
      expect(export['affects_discover_ranking'], isFalse);
      expect(export['is_l1_eligibility_gate'], isFalse);
    });

    test('missing data stays unavailable with reason', () {
      final me = <String, dynamic>{
        'age': 30,
        'age_range': [25, 35],
        // no location / distance / interests
      };
      final ranked = [_candidate(uid: 'c1', score: 0.7)];
      final candData = <String, Map<String, dynamic>>{
        'c1': {
          // no age / ranges / geo / interests
        },
      };

      final d = attacher
          .attach(
            meUserData: me,
            rankedCandidates: ranked,
            candidateUserData: candData,
          )
          .diagnostics['c1']!;

      expect(d.age.available, isFalse);
      expect(
        d.age.unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingAgeB,
      );
      expect(d.distance.available, isFalse);
      expect(
        d.distance.unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingLocationA,
      );
      expect(d.interests.available, isFalse);
      expect(
        d.interests.unavailableReason,
        L3SoftPreferenceSignalContract.reasonMissingInterestsA,
      );
    });

    test('candidate ordering and compat fields unchanged', () {
      final me = {
        'age': 30,
        'age_range': [25, 35],
        'interests': ['a'],
      };
      final ranked = [
        _candidate(uid: 'a', score: 0.95),
        _candidate(uid: 'b', score: 0.2),
        _candidate(uid: 'c', score: null),
      ];
      final beforeUids = ranked.map((c) => c.uid).toList();
      final beforeScores = ranked.map((c) => c.compatibilityScore).toList();

      final attached = attacher.attach(
        meUserData: me,
        rankedCandidates: ranked,
        candidateUserData: {
          'a': {'age': 28, 'age_range': [25, 35], 'interests': ['a']},
          'b': {'age': 29, 'age_range': [25, 35], 'interests': ['b']},
          'c': {'age': 31, 'age_range': [25, 35], 'interests': ['c']},
        },
      );

      expect(attached.candidates.map((c) => c.uid).toList(), beforeUids);
      expect(
        attached.candidates.map((c) => c.compatibilityScore).toList(),
        beforeScores,
      );
      // L3 ranks mirror legacy order only as diagnostics.
      expect(attached.diagnostics['a']!.legacyRank, 1);
      expect(attached.diagnostics['b']!.legacyRank, 2);
      expect(attached.diagnostics['c']!.legacyRank, 3);

      // Prove live CompatibilityScoring order helper still prefers higher score
      // (L3 does not participate).
      final ordered = [...ranked]..sort(
          (x, y) => CompatibilityScoring.compareDiscoverCandidates(
            aScore: x.compatibilityScore,
            bScore: y.compatibilityScore,
            aLastActiveMs: 0,
            bLastActiveMs: 0,
          ),
        );
      expect(ordered.map((c) => c.uid).toList(), ['a', 'b', 'c']);
    });

    test('L1 eligibility gate logic unchanged by L3 wiring', () {
      // Soft age miss must not become an L1 fail — gates stay independent.
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

      final me = {
        'age': 50,
        'age_range': [18, 25], // will miss mutual fit vs young candidate
      };
      final ranked = [
        _candidate(uid: 'young', score: 0.8, age: 22),
      ];
      final d = attacher
          .attach(
            meUserData: me,
            rankedCandidates: ranked,
            candidateUserData: {
              'young': {
                'age': 22,
                'age_range': [18, 30],
              },
            },
          )
          .diagnostics['young']!;

      expect(d.age.available, isTrue);
      expect(d.age.mutualFit, isFalse);
      // Candidate remains in ranked list (L3 is diagnostic only).
      expect(ranked.length, 1);
      expect(
        DiscoverL1EligibilityGate.excludedByBlocks(
          viewerBlockedCandidate: false,
          candidateBlockedViewer: false,
        ),
        isFalse,
      );
    });
  });

  group('DiscoverService L3 export API + isolation', () {
    test('export helper + post-rank L3 hook present; shadow-gated', () {
      final serviceSrc = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(
        serviceSrc.contains('exportLastL3SoftPreferenceDiagnosticsMap'),
        isTrue,
      );
      expect(serviceSrc.contains('lastL3SoftPreferenceDiagnostics'), isTrue);
      expect(serviceSrc.contains('_l3ShadowAttacher.attach'), isTrue);
      expect(serviceSrc.contains('enableShadowDiagnostics = true'), isTrue);

      final sortIdx = serviceSrc.indexOf('out.sort(');
      final l3AttachIdx = serviceSrc.indexOf('_l3ShadowAttacher.attach');
      expect(sortIdx, greaterThanOrEqualTo(0));
      expect(l3AttachIdx, greaterThan(sortIdx));
      expect(serviceSrc.indexOf('out.sort(', sortIdx + 1), -1);
    });

    test('source isolation — no L3 ranking / CompatibilityScoring / looking_for',
        () {
      final shadowSrc = File(
        'lib/features/discover/services/discover_l3_soft_preference_shadow.dart',
      ).readAsStringSync();
      expect(shadowSrc.contains('CompatibilityScoring'), isFalse);
      expect(shadowSrc.contains('compareDiscoverCandidates'), isFalse);
      expect(shadowSrc.contains("data['looking_for']"), isFalse);
      expect(shadowSrc.contains('interested_in'), isFalse);
      expect(shadowSrc.contains('persona'), isFalse);
      expect(shadowSrc.contains('rvi'), isFalse);
      expect(shadowSrc.contains('temporal'), isFalse);
      expect(shadowSrc.contains('quantum'), isFalse);
      expect(shadowSrc.contains("'looking_for_active': false"), isTrue);

      final serviceSrc = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      // Hook exists after ranking.
      expect(serviceSrc.contains('_l3ShadowAttacher.attach'), isTrue);
      expect(serviceSrc.contains('lastL3SoftPreferenceDiagnostics'), isTrue);
      // Sort still only CompatibilityScoring.
      expect(
        serviceSrc.contains('CompatibilityScoring.compareDiscoverCandidates'),
        isTrue,
      );
      // L3 must not appear inside the sort comparator block as a key.
      expect(serviceSrc.contains('l3Attached.candidates.sort'), isFalse);
      expect(serviceSrc.contains('mutualFit'), isFalse);
      expect(serviceSrc.contains('withinMutualCap'), isFalse);
      expect(serviceSrc.contains('jaccard'), isFalse);
    });
  });
}
