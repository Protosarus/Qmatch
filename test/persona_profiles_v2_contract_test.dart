import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Contract freeze for provisional canonical 20D persona prototypes (P1B-2B-1).
/// Does not load profiles into production runtime.
void main() {
  late Map<String, dynamic> profiles;
  late Map<String, dynamic> config;
  late List<String> dimensionOrder;
  late List<Map<String, dynamic>> personas;
  late Map<String, Map<String, dynamic>> byId;

  const canonicalIds = [
    'uygulayici',
    'koruyucu',
    'bilge',
    'lider',
    'muhafiz',
    'sifaci',
    'yargic',
    'empat',
    'cesur',
    'kararli',
    'vizyoner',
    'yaratici',
    'iletisimci',
    'analist',
    'donusturucu',
    'bagimsiz',
    'sezgisel',
    'stratejist',
  ];

  const canonicalDims = [
    'logical_reasoning',
    'pattern_reasoning',
    'verbal_reasoning',
    'spatial_reasoning',
    'empathy',
    'perspective_taking',
    'self_awareness',
    'emotion_regulation',
    'emotional_openness',
    'boundary_setting',
    'assertiveness',
    'conflict_approach',
    'repair_orientation',
    'social_awareness',
    'depth_preference',
    'social_energy',
    'spontaneity',
    'stability',
    'disclosure_pace',
    'communication_pace',
  ];

  const forbidden = {
    'numerical',
    'autonomy',
    'adaptability',
    'intuitiveSensitivity',
    'logic',
    'pattern',
    'verbal',
    'spatial',
    'selfAwareness',
    'emotionalRegulation',
    'boundaries',
    'perspectiveTaking',
    'repairOrientation',
    'depth',
    'socialEnergy',
    'conversationPace',
    'emotionalOpenness', // Frequency alias — must be disclosure_pace in Frequency
    'HH',
    'HM',
    'HL',
    'MH',
    'MM',
    'ML',
    'LH',
    'LM',
    'LL',
    'Deep Connector',
    'Social Spark',
    'Balanced Frequency',
  };

  setUpAll(() {
    profiles = jsonDecode(
      File('assets/data/persona_profiles_v2_20d.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    config = jsonDecode(
      File('assets/data/persona_scoring_config_v2.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    dimensionOrder = List<String>.from(profiles['dimension_order'] as List);
    personas = (profiles['personas'] as List).cast<Map<String, dynamic>>();
    byId = {
      for (final p in personas) p['persona_id'] as String: p,
    };
  });

  test('1-3: exactly 18 unique canonical persona IDs', () {
    expect(personas.length, 18);
    expect(byId.keys.toSet(), canonicalIds.toSet());
    expect(byId.length, 18);
  });

  test('4-9: every target/weight map is exactly canonical 20D', () {
    expect(dimensionOrder, canonicalDims);
    expect(dimensionOrder.toSet().length, 20);
    expect(dimensionOrder.contains('numerical'), isFalse);
    for (final p in personas) {
      final tv = (p['target_vector'] as Map).cast<String, dynamic>();
      final dw = (p['dimension_weights'] as Map).cast<String, dynamic>();
      expect(tv.keys.toSet(), canonicalDims.toSet());
      expect(dw.keys.toSet(), canonicalDims.toSet());
      expect(tv.length, 20);
      expect(dw.length, 20);
      for (final d in canonicalDims) {
        final t = (tv[d] as num).toDouble();
        final w = (dw[d] as num).toDouble();
        expect(t, inInclusiveRange(0.0, 1.0));
        expect(w, greaterThanOrEqualTo(0.0));
        expect(forbidden.contains(d), isFalse);
      }
    }
  });

  test(
      '10-17: primary/supporting/neutral/anti/min-evidence/separators canonical',
      () {
    for (final p in personas) {
      for (final key in [
        'primary_dimensions',
        'supporting_dimensions',
        'neutral_dimensions',
      ]) {
        for (final d in List<String>.from(p[key] as List)) {
          expect(canonicalDims.contains(d), isTrue,
              reason: '${p['persona_id']} $key $d');
        }
      }
      expect((p['primary_dimensions'] as List).length, greaterThanOrEqualTo(3));
      for (final a in (p['anti_traits'] as List).cast<Map<String, dynamic>>()) {
        expect(canonicalDims.contains(a['dimension_id']), isTrue);
      }
      final me = p['minimum_evidence'] as Map<String, dynamic>;
      for (final d in List<String>.from(me['critical_dimensions'] as List)) {
        expect(canonicalDims.contains(d), isTrue);
      }
      final seps = p['separator_targets'] as Map<String, dynamic>;
      for (final e in seps.entries) {
        expect(byId.containsKey(e.key), isTrue);
        for (final d
            in List<String>.from((e.value as Map)['dimensions'] as List)) {
          expect(canonicalDims.contains(d), isTrue);
        }
      }
      expect(
          (p['closest_competitors'] as List).length, greaterThanOrEqualTo(2));
      expect(p['status'], 'provisional');
    }
  });

  test('18-19: group / level-shape weights sum to 1', () {
    final gw = (profiles['group_weights'] as Map).cast<String, dynamic>();
    final gSum =
        gw.values.cast<num>().fold<double>(0, (a, b) => a + b.toDouble());
    expect(gSum, closeTo(1.0, 1e-9));
    expect(gw['iq'], 0.15);
    expect(gw['eq'], 0.30);
    expect(gw['frequency'], 0.55);

    final alpha = (config['level_distance_weight'] as num).toDouble();
    final beta = (config['shape_distance_weight'] as num).toDouble();
    expect(alpha + beta, closeTo(1.0, 1e-9));
  });

  test('21-22: no identical target or weighted prototypes', () {
    final targets = <String>{};
    final weighted = <String>{};
    for (final p in personas) {
      final tv = (p['target_vector'] as Map).cast<String, dynamic>();
      final dw = (p['dimension_weights'] as Map).cast<String, dynamic>();
      final tKey =
          canonicalDims.map((d) => (tv[d] as num).toStringAsFixed(6)).join('|');
      final wKey = canonicalDims.map((d) {
        final t = (tv[d] as num).toDouble();
        final w = (dw[d] as num).toDouble();
        return (t * w).toStringAsFixed(6);
      }).join('|');
      expect(targets.add(tKey), isTrue,
          reason: 'duplicate target ${p['persona_id']}');
      expect(weighted.add(wKey), isTrue,
          reason: 'duplicate weighted ${p['persona_id']}');
    }
  });

  test('23-24: no Frequency types or legacy grid IDs as personas', () {
    for (final id in byId.keys) {
      expect(forbidden.contains(id), isFalse);
    }
    final blob = jsonEncode(profiles);
    for (final bad in ['Deep Connector', 'Social Spark', '"HH"', '"LL"']) {
      expect(blob.contains(bad), isFalse);
    }
  });

  test('25-27: provisional status and version agreement', () {
    expect(profiles['status'], 'provisional');
    expect(profiles['calibration_status'], 'synthetic_validation_only');
    expect(config['status'], 'provisional');
    expect(
      profiles['persona_profile_version'],
      config['persona_profile_version'],
    );
    expect(
      profiles['dimension_registry_version'],
      config['dimension_registry_version'],
    );
    expect(profiles['dimension_registry_version'],
        'canonical_dimension_registry_v1');
  });

  test('29: difficult pairs have separator targets', () {
    const pairs = [
      ('koruyucu', 'muhafiz'),
      ('bilge', 'analist'),
      ('empat', 'sifaci'),
      ('lider', 'vizyoner'),
      ('cesur', 'kararli'),
      ('yaratici', 'donusturucu'),
      ('uygulayici', 'stratejist'),
      ('bagimsiz', 'sezgisel'),
      ('iletisimci', 'empat'),
      ('yargic', 'analist'),
      ('lider', 'uygulayici'),
      ('sezgisel', 'yaratici'),
      ('stratejist', 'analist'),
      ('koruyucu', 'sifaci'),
    ];
    for (final (a, b) in pairs) {
      final sa = byId[a]!['separator_targets'] as Map<String, dynamic>;
      final sb = byId[b]!['separator_targets'] as Map<String, dynamic>;
      expect(sa.containsKey(b) || sb.containsKey(a), isTrue, reason: '$a/$b');
    }
  });

  test('30: config declares non-probability and no quota', () {
    final notes = config['calibration_notes'] as Map<String, dynamic>;
    expect(notes['similarity_scores_are_not_probabilities'], isTrue);
    expect(notes['no_persona_quota'], isTrue);
    expect(notes['production_calibration_required'], isTrue);
  });

  test('primary dims have higher mean weight than neutrals', () {
    for (final p in personas) {
      final dw = (p['dimension_weights'] as Map).cast<String, dynamic>();
      final primary = List<String>.from(p['primary_dimensions'] as List);
      final neutral = List<String>.from(p['neutral_dimensions'] as List);
      if (neutral.isEmpty) continue;
      final pMean = primary
              .map((d) => (dw[d] as num).toDouble())
              .fold<double>(0, (a, b) => a + b) /
          primary.length;
      final nMean = neutral
              .map((d) => (dw[d] as num).toDouble())
              .fold<double>(0, (a, b) => a + b) /
          neutral.length;
      expect(pMean, greaterThan(nMean), reason: p['persona_id'] as String);
    }
  });

  test('pairwise Euclidean target distance is non-trivial', () {
    double dist(Map<String, dynamic> a, Map<String, dynamic> b) {
      var s = 0.0;
      for (final d in canonicalDims) {
        final diff = (a[d] as num).toDouble() - (b[d] as num).toDouble();
        s += diff * diff;
      }
      return math.sqrt(s);
    }

    for (var i = 0; i < personas.length; i++) {
      for (var j = i + 1; j < personas.length; j++) {
        final d = dist(
          personas[i]['target_vector'] as Map<String, dynamic>,
          personas[j]['target_vector'] as Map<String, dynamic>,
        );
        expect(d, greaterThan(0.15),
            reason:
                '${personas[i]['persona_id']} vs ${personas[j]['persona_id']}');
      }
    }
  });
}
