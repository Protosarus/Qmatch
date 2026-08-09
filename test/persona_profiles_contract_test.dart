import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> document;
  late Map<String, List<String>> dimensionOrder;
  late Map<String, ({String group, int index})> dimensionLocations;
  late Map<String, Map<String, dynamic>> personasById;

  setUpAll(() {
    document = jsonDecode(
      File('assets/data/persona_profiles_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    dimensionOrder = (document['dimensionOrder'] as Map<String, dynamic>).map(
      (group, dimensions) => MapEntry(
        group,
        (dimensions as List<dynamic>).cast<String>(),
      ),
    );
    dimensionLocations = {
      for (final group in dimensionOrder.entries)
        for (final indexed in group.value.indexed)
          indexed.$2: (group: group.key, index: indexed.$1),
    };
    personasById = {
      for (final persona in document['personas'] as List<dynamic>)
        (persona as Map<String, dynamic>)['personaId'] as String: persona,
    };
  });

  test('locks the canonical dimensions and scoring groups', () {
    expect(document['schemaVersion'], 1);
    expect(document['scoringVersion'], 'persona_v1.0.0');
    expect(document['status'], 'locked');
    expect(dimensionOrder, {
      'iqStyle': ['logic', 'pattern', 'verbal', 'spatial', 'numerical'],
      'eqCharacter': [
        'empathy',
        'selfAwareness',
        'emotionalRegulation',
        'boundaries',
        'assertiveness',
        'perspectiveTaking',
        'repairOrientation',
        'autonomy',
        'adaptability',
        'intuitiveSensitivity',
      ],
      'frequencyStyle': [
        'depth',
        'socialEnergy',
        'spontaneity',
        'stability',
        'emotionalOpenness',
        'conversationPace',
      ],
    });

    final definitions =
        document['dimensionDefinitions'] as Map<String, dynamic>;
    expect(definitions.keys.toSet(), dimensionLocations.keys.toSet());
    for (final definition in definitions.values.cast<Map<String, dynamic>>()) {
      for (final pole in ['low', 'high']) {
        final labels = definition[pole] as Map<String, dynamic>;
        expect((labels['tr'] as String).trim(), isNotEmpty);
        expect((labels['en'] as String).trim(), isNotEmpty);
      }
    }

    final scoringContract = document['scoringContract'] as Map<String, dynamic>;
    final groupWeights =
        scoringContract['groupWeights'] as Map<String, dynamic>;
    expect(groupWeights.keys.toSet(), dimensionOrder.keys.toSet());
    expect(
      groupWeights.values
          .cast<num>()
          .fold<double>(0, (sum, value) => sum + value),
      closeTo(1, 0.000001),
    );
  });

  test('defines all 18 personas as complete measurable prototypes', () {
    const canonicalIds = {
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
    };
    expect(personasById.keys.toSet(), canonicalIds);

    for (final persona in personasById.values) {
      final id = persona['personaId'] as String;
      for (final field in ['title', 'description']) {
        final localized = persona[field] as Map<String, dynamic>;
        expect((localized['tr'] as String).trim(), isNotEmpty, reason: id);
        expect((localized['en'] as String).trim(), isNotEmpty, reason: id);
      }

      final traits = persona['traitLabels'] as List<dynamic>;
      expect(traits, hasLength(3), reason: id);
      for (final trait in traits.cast<Map<String, dynamic>>()) {
        expect((trait['tr'] as String).trim(), isNotEmpty, reason: id);
        expect((trait['en'] as String).trim(), isNotEmpty, reason: id);
      }

      final asset = persona['asset'] as String;
      expect(File(asset).existsSync(), isTrue, reason: '$id: $asset');

      final targets = persona['targetVector'] as Map<String, dynamic>;
      final weights = persona['dimensionWeights'] as Map<String, dynamic>;
      expect(targets.keys.toSet(), dimensionOrder.keys.toSet(), reason: id);
      expect(weights.keys.toSet(), dimensionOrder.keys.toSet(), reason: id);

      for (final group in dimensionOrder.entries) {
        final groupTargets = (targets[group.key] as List<dynamic>).cast<num>();
        final groupWeights = (weights[group.key] as List<dynamic>).cast<num>();
        expect(groupTargets, hasLength(group.value.length),
            reason: '$id target ${group.key}');
        expect(groupWeights, hasLength(group.value.length),
            reason: '$id weight ${group.key}');
        expect(
          groupTargets.every((value) => value >= 0 && value <= 1),
          isTrue,
          reason: '$id target ${group.key}',
        );
        expect(
          groupWeights.every((value) => value > 0),
          isTrue,
          reason: '$id weight ${group.key}',
        );
      }

      final signals = (persona['distinguishingSignals'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(signals.length, inInclusiveRange(3, 5), reason: id);
      for (final signal in signals) {
        final dimension = signal['dimension'] as String;
        final direction = signal['direction'] as String;
        final threshold = signal['threshold'] as num;
        final location = dimensionLocations[dimension];
        expect(location, isNotNull, reason: '$id: $dimension');
        expect(direction, anyOf('high', 'low'), reason: '$id: $dimension');
        final target =
            (targets[location!.group] as List<dynamic>)[location.index] as num;
        expect(
          direction == 'high' ? target >= threshold : target <= threshold,
          isTrue,
          reason: '$id: $dimension target=$target threshold=$threshold',
        );
      }
    }
  });

  test('defines symmetric and resolvable distinctions for every near pair', () {
    final pairs = (document['nearPersonaPairs'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final pairKeys = <String>{};
    final actualNeighbors = {
      for (final id in personasById.keys) id: <String>{},
    };

    for (final pair in pairs) {
      final personaA = pair['personaA'] as String;
      final personaB = pair['personaB'] as String;
      expect(personasById, contains(personaA));
      expect(personasById, contains(personaB));
      expect(personaA, isNot(personaB));

      final pairKey = ([personaA, personaB]..sort()).join('|');
      expect(pairKeys.add(pairKey), isTrue, reason: 'duplicate $pairKey');
      actualNeighbors[personaA]!.add(personaB);
      actualNeighbors[personaB]!.add(personaA);

      final criteria =
          (pair['criteria'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(criteria.length, greaterThanOrEqualTo(4), reason: pairKey);
      expect(
        criteria.where((criterion) => criterion['favors'] == personaA).length,
        greaterThanOrEqualTo(2),
        reason: pairKey,
      );
      expect(
        criteria.where((criterion) => criterion['favors'] == personaB).length,
        greaterThanOrEqualTo(2),
        reason: pairKey,
      );

      for (final criterion in criteria) {
        final dimension = criterion['dimension'] as String;
        final favoredPersona = criterion['favors'] as String;
        final minimumAdvantage = criterion['minimumTargetAdvantage'] as num;
        final location = dimensionLocations[dimension];
        expect(location, isNotNull, reason: '$pairKey: $dimension');
        expect(
          favoredPersona,
          anyOf(personaA, personaB),
          reason: '$pairKey: $dimension',
        );
        expect(
          minimumAdvantage,
          inInclusiveRange(0.05, 1),
          reason: '$pairKey: $dimension',
        );

        final targetA = (personasById[personaA]!['targetVector']
            as Map<String, dynamic>)[location!.group][location.index] as num;
        final targetB = (personasById[personaB]!['targetVector']
            as Map<String, dynamic>)[location.group][location.index] as num;
        expect(
          (targetA - targetB).abs() + 0.000001,
          greaterThanOrEqualTo(minimumAdvantage),
          reason: '$pairKey: $dimension is not measurably separated',
        );
      }
    }

    for (final persona in personasById.values) {
      final id = persona['personaId'] as String;
      final declaredNeighbors =
          (persona['nearPersonaIds'] as List<dynamic>).cast<String>().toSet();
      expect(declaredNeighbors, actualNeighbors[id], reason: id);
    }
  });
}
