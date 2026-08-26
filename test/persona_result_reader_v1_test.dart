import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/services/persona_result_reader.dart';

void main() {
  test('reads assigned primary and secondary persona ids', () async {
    final reader = PersonaResultReader(
      loadOverride: (_) async => {
        'primary_persona_id': 'stratejist',
        'secondary_persona_id': 'analist',
      },
    );

    final result = await reader.readForUid('u1');

    expect(result, isNotNull);
    expect(result!.primaryPersonaId, 'stratejist');
    expect(result.secondaryPersonaId, 'analist');
  });

  test('trims uid and persisted persona ids', () async {
    String? capturedUid;

    final reader = PersonaResultReader(
      loadOverride: (uid) async {
        capturedUid = uid;
        return {
          'primary_persona_id': '  sezgisel  ',
          'secondary_persona_id': '  empat  ',
        };
      },
    );

    final result = await reader.readForUid('  u1  ');

    expect(capturedUid, 'u1');
    expect(result, isNotNull);
    expect(result!.primaryPersonaId, 'sezgisel');
    expect(result.secondaryPersonaId, 'empat');
  });

  test('empty uid does not attempt a read', () async {
    var called = false;

    final reader = PersonaResultReader(
      loadOverride: (_) async {
        called = true;
        return const {};
      },
    );

    final result = await reader.readForUid('   ');

    expect(result, isNull);
    expect(called, isFalse);
  });

  test('missing or invalid persona result returns null', () async {
    Future<AssignedPersonaResult?> read(Map<String, dynamic>? doc) {
      return PersonaResultReader(
        loadOverride: (_) async => doc,
      ).readForUid('u1');
    }

    expect(await read(null), isNull);
    expect(await read(const {}), isNull);

    expect(
      await read({
        'primary_persona_id': 'stratejist',
      }),
      isNull,
    );

    expect(
      await read({
        'primary_persona_id': 'stratejist',
        'secondary_persona_id': '',
      }),
      isNull,
    );

    expect(
      await read({
        'primary_persona_id': 'stratejist',
        'secondary_persona_id': 'stratejist',
      }),
      isNull,
    );
  });
}
