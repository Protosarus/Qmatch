import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_canonical_20d_shadow.dart';
import 'package:qmatch/features/discover/services/discover_shadow_distance_attacher.dart';
import 'package:qmatch/features/matching/domain/canonical_20d_shadow_distance.dart';
import 'package:qmatch/core/utils/compatibility_scoring.dart';

DiscoverUserModel _candidate({
  required String uid,
  double? score,
  String? label,
}) {
  return DiscoverUserModel(
    uid: uid,
    name: uid,
    age: 28,
    profilePhotoUrl: 'https://example.com/$uid.jpg',
    profileCompleted: true,
    testCompleted: true,
    compatibilityScore: score,
    compatibilityLabel: label,
  );
}

Map<String, dynamic> _canonicalProfile(Map<String, double> scores) {
  return {
    'measured_dimensions': [
      for (final e in scores.entries)
        {
          'dimension_id': e.key,
          'module': 'iq',
          'measurement_state': 'measured',
          'value': e.value,
          'reliability_status': 'not_calibrated',
        },
    ],
  };
}

void main() {
  final ids = Canonical20dShadowDistanceContract.dimensionIds;

  group('DiscoverCanonical20dShadowSubjectBuilder', () {
    test('maps measured_dimensions; never invents missing scores', () {
      final subject = DiscoverCanonical20dShadowSubjectBuilder
          .fromCanonicalProfile(_canonicalProfile({
        ids[0]: 0.25,
        ids[1]: 0.75,
      }));
      expect(subject, isNotNull);
      expect(subject!.measuredScores.keys.toSet(), {ids[0], ids[1]});
      expect(subject.evidenceCounts[ids[0]], 1);
      expect(subject.measuredScores.containsKey(ids[2]), isFalse);
    });

    test('null/empty profile → null subject', () {
      expect(
        DiscoverCanonical20dShadowSubjectBuilder.fromCanonicalProfile(null),
        isNull,
      );
      expect(
        DiscoverCanonical20dShadowSubjectBuilder.fromCanonicalProfile(const {}),
        isNull,
      );
    });
  });

  group('DiscoverShadowDistanceAttacher isolation', () {
    test('does not change candidate order or live compatibility fields', () {
      final ranked = [
        _candidate(uid: 'a', score: 0.9, label: 'High'),
        _candidate(uid: 'b', score: 0.4, label: 'Low'),
        _candidate(uid: 'c', score: null, label: 'Unavailable'),
      ];
      final beforeUids = ranked.map((c) => c.uid).toList();
      final beforeScores = ranked.map((c) => c.compatibilityScore).toList();
      final beforeLabels = ranked.map((c) => c.compatibilityLabel).toList();

      final me = _canonicalProfile({for (final id in ids) id: 0.5});
      final profiles = {
        'a': _canonicalProfile({for (final id in ids) id: 0.5}),
        'b': _canonicalProfile({for (final id in ids) id: 1.0}),
        'c': null,
      };

      final attached = const DiscoverShadowDistanceAttacher().attach(
        rankedCandidates: ranked,
        meCanonicalProfile: me,
        candidateCanonicalProfiles: profiles,
      );

      expect(attached.candidates.map((c) => c.uid), beforeUids);
      expect(
        attached.candidates.map((c) => c.compatibilityScore),
        beforeScores,
      );
      expect(
        attached.candidates.map((c) => c.compatibilityLabel),
        beforeLabels,
      );

      // Shadow diagnostics exist in the side map only.
      expect(attached.diagnostics['a']?.available, isTrue);
      expect(attached.diagnostics['a']?.distance, 0.0);
      expect(attached.diagnostics['a']?.comparableDimensionCount, 20);
      expect(attached.diagnostics['a']?.unweightedCoverage, 1.0);
      expect(attached.diagnostics['b']?.distance, greaterThan(0));
      expect(attached.diagnostics.containsKey('c'), isFalse);

      // Models themselves have no shadow fields.
      final modelSrc = File(
        'lib/features/discover/models/discover_user_model.dart',
      ).readAsStringSync();
      expect(modelSrc.contains('shadow'), isFalse);
      expect(modelSrc.contains('distance'), isFalse);
    });

    test('legacy ranking comparator ignores shadow diagnostics', () {
      // Prove CompatibilityScoring sort key is score+recency only.
      final order = CompatibilityScoring.compareDiscoverCandidates(
        aScore: 0.2,
        bScore: 0.9,
        aLastActiveMs: 100,
        bLastActiveMs: 1,
      );
      expect(order, greaterThan(0)); // b (0.9) before a

      final src = File('lib/core/utils/compatibility_scoring.dart')
          .readAsStringSync();
      expect(src.contains('shadow'), isFalse);
      expect(src.contains('canonical_20d'), isFalse);
    });
  });

  group('Discover wiring isolation', () {
    test('shadow runs after sort; UI does not read diagnostics', () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      final sortIdx = service.indexOf('out.sort(');
      final shadowIdx = service.indexOf('_computeShadowDiagnostics');
      expect(sortIdx, greaterThanOrEqualTo(0));
      expect(shadowIdx, greaterThan(sortIdx));
      expect(service.contains('lastShadowDiagnostics'), isTrue);
      // Must not re-sort after shadow.
      expect(
        service.indexOf('out.sort(', sortIdx + 1),
        -1,
      );
      expect(service.contains('CompatibilityScoring.calculateCompatibility'),
          isTrue);
      expect(service.contains('persona_scoring'), isFalse);
      expect(service.contains('PersonaScoring'), isFalse);
      expect(service.contains('primary_persona_id'), isFalse);
      expect(service.contains('quantum'), isFalse);
      expect(service.contains('RVI'), isFalse);
      expect(RegExp(r'\brvi\b', caseSensitive: false).hasMatch(service),
          isFalse);

      final card = File(
        'lib/features/discover/widgets/qmatch_candidate_card.dart',
      ).readAsStringSync();
      expect(card.contains('lastShadowDiagnostics'), isFalse);
      expect(card.contains('DiscoverShadowDistance'), isFalse);
      expect(card.contains('canonical_20d_shadow'), isFalse);

      final screen = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(screen.contains('lastShadowDiagnostics'), isFalse);
      expect(screen.contains('DiscoverShadowDistance'), isFalse);
    });

    test('attacher computes distance/coverage without mutating list identity order',
        () {
      final ranked = [
        _candidate(uid: 'x', score: 0.55),
        _candidate(uid: 'y', score: 0.55),
      ];
      final me = _canonicalProfile({
        for (var i = 0; i < 10; i++) ids[i]: 0.1,
      });
      final profiles = {
        'x': _canonicalProfile({
          for (var i = 0; i < 10; i++) ids[i]: 0.1,
        }),
        'y': _canonicalProfile({
          for (var i = 0; i < 10; i++) ids[i]: 0.9,
        }),
      };
      final a = const DiscoverShadowDistanceAttacher().attach(
        rankedCandidates: ranked,
        meCanonicalProfile: me,
        candidateCanonicalProfiles: profiles,
      );
      expect(a.candidates[0].uid, 'x');
      expect(a.candidates[1].uid, 'y');
      expect(a.diagnostics['x']!.comparableDimensionCount, 10);
      expect(a.diagnostics['x']!.unweightedCoverage, 0.5);
      expect(a.diagnostics['y']!.distance, greaterThan(0));
      // Live displayed score unchanged even when shadow distance differs.
      expect(a.candidates[0].compatibilityScore, 0.55);
      expect(a.candidates[1].compatibilityScore, 0.55);
    });
  });
}
