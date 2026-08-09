import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_bank/frequency_bank.dart';
import 'package:qmatch/features/assessment/domain/frequency_scoring/frequency_scoring.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_persistence.dart';

FrequencyCanonicalBankDocument _load(String path) {
  return FrequencyCanonicalBankDocument.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

List<FrequencyCanonicalResponse> _pick(
  FrequencyCanonicalBankDocument bank,
  String optionId,
) {
  return [
    for (final i in bank.items)
      FrequencyCanonicalResponse(
        itemId: i.itemId,
        optionId: i.optionById(optionId)?.optionId ?? i.options.first.optionId,
      ),
  ];
}

void main() {
  late FrequencyCanonicalBankDocument fixture;

  setUpAll(() {
    fixture = _load('test/fixtures/frequency/frequency_math_fixture_v1.json');
  });

  group('Canonical Frequency taxonomy freeze', () {
    test('registry matches frozen six IDs; no legacy aliases', () {
      expect(
        FrequencyCanonicalDimensions.all,
        CanonicalDimensions.frequency,
      );
      expect(FrequencyCanonicalDimensions.all.length, 6);
      for (final id in FrequencyCanonicalDimensions.forbiddenLegacy) {
        expect(FrequencyCanonicalDimensions.isCanonical(id), isFalse);
      }
    });
  });

  group('Pilot coverage audit (no runtime candidate)', () {
    test('pilot has signed deltas but no separator / quality-only roles', () {
      final raw = jsonDecode(
        File(FrequencyBankContract.pilotTrPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final items = (raw['items'] as List).cast<Map<String, dynamic>>();
      expect(items.length, 50);

      final dims = <String>{};
      var sep = 0;
      var qualityOnly = 0;
      for (final it in items) {
        final primary = it['primary_dimension'] as String;
        expect(FrequencyCanonicalDimensions.isCanonical(primary), isTrue);
        expect(
          FrequencyCanonicalDimensions.isForbiddenLegacy(primary),
          isFalse,
        );
        dims.add(primary);
        final targets = it['separator_targets'];
        if (targets is List && targets.isNotEmpty) sep++;
        final opts = (it['options'] as List).cast<Map<String, dynamic>>();
        final anyTrait = opts.any((o) {
          final d = o['dimension_deltas'];
          return d is Map && d.isNotEmpty;
        });
        if (!anyTrait) qualityOnly++;
        for (final o in opts) {
          expect(o.containsKey('correctAnswer'), isFalse);
          expect(o.containsKey('correct_option_id'), isFalse);
          final deltas =
              Map<String, dynamic>.from(o['dimension_deltas'] as Map);
          for (final e in deltas.entries) {
            expect(FrequencyCanonicalDimensions.isCanonical(e.key), isTrue);
            final v = (e.value as num).toDouble();
            expect(v, inInclusiveRange(-1.0, 1.0));
          }
        }
      }
      expect(dims, FrequencyCanonicalDimensions.allSet);
      expect(sep, 0, reason: 'BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE');
      expect(qualityOnly, 0, reason: 'BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE');

      final iso =
          ((raw['pair_registry'] as Map)['behavioral_isomorph_groups'] as List)
              .length;
      expect(iso, 6);

      // Runtime candidate assets must not exist yet.
      expect(File(FrequencyBankContract.trAssetPath).existsSync(), isFalse);
      expect(File(FrequencyBankContract.enAssetPath).existsSync(), isFalse);
      expect(FrequencyBankContract.registeredInPubspec, isFalse);
    });

    test('full blueprint validator rejects empty candidate bank', () {
      final empty = FrequencyCanonicalBankDocument(
        schemaVersion: FrequencyBankContract.schemaVersion,
        bankVersion: 'empty',
        contentVersion: 'empty',
        locale: 'tr-TR',
        status: FrequencyBankContract.statusRuntimeCandidate,
        calibrationStatus: FrequencyBankContract.calibrationUncalibrated,
        reliabilityStatus: FrequencyBankContract.reliabilityNotCalibrated,
        scoringPolicyVersion: FrequencyBankContract.scoringPolicyVersion,
        items: const [],
        pairRegistry: const {},
        rviRuntimeGate: FrequencyBankContract.rviGateNotActive,
      );
      final v = const FrequencyCanonicalBankValidator().validate(empty);
      expect(v.ok, isFalse);
      expect(
        v.issues.any((e) => e.contains('BLOCKED_FREQUENCY_SEPARATOR_ITEM')),
        isTrue,
      );
      expect(
        v.issues.any((e) => e.contains('BLOCKED_FREQUENCY_QUALITY_ITEM')),
        isTrue,
      );
      expect(
        v.issues.any((e) => e.contains('BLOCKED_FREQUENCY_CORE_EVIDENCE')),
        isTrue,
      );
    });
  });

  group('Mathematical fixtures (a_ij=1)', () {
    test('[-1,-1,-1] → z=-1 x=0', () {
      final m = FrequencySignedEvidenceMath.meanSignedEvidence([-1, -1, -1])!;
      expect(m.z, closeTo(-1.0, 1e-12));
      expect(m.x, closeTo(0.0, 1e-12));
      expect(m.n, 3);
    });

    test('[0,0,0] → z=0 x=0.5', () {
      final m = FrequencySignedEvidenceMath.meanSignedEvidence([0, 0, 0])!;
      expect(m.z, closeTo(0.0, 1e-12));
      expect(m.x, closeTo(0.5, 1e-12));
    });

    test('[1,1,1] → z=1 x=1', () {
      final m = FrequencySignedEvidenceMath.meanSignedEvidence([1, 1, 1])!;
      expect(m.z, closeTo(1.0, 1e-12));
      expect(m.x, closeTo(1.0, 1e-12));
    });

    test('[-1,0,1] → z=0 x=0.5', () {
      final m = FrequencySignedEvidenceMath.meanSignedEvidence([-1, 0, 1])!;
      expect(m.z, closeTo(0.0, 1e-12));
      expect(m.x, closeTo(0.5, 1e-12));
    });

    test('[-0.5,0.5,1] → z=1/3 x=2/3', () {
      final m = FrequencySignedEvidenceMath.meanSignedEvidence([-0.5, 0.5, 1])!;
      expect(m.z, closeTo(1 / 3, 1e-12));
      expect(m.x, closeTo(2 / 3, 1e-12));
    });

    test('empty evidence is insufficient — not 0 / 0.5 / 50', () {
      expect(FrequencySignedEvidenceMath.meanSignedEvidence(const []), isNull);
      final d = CanonicalFrequencyScorer.scoreDimensionFromDeltas(
        dimensionId: 'spontaneity',
        deltas: const [],
      );
      expect(
        d.evidenceStatus,
        FrequencyDimensionEvidenceStatus.insufficientEvidence,
      );
      expect(d.rawSignedEvidence, isNull);
      expect(d.normalizedScore, isNull);
      expect(d.evidenceCount, 0);
      expect(d.normalizedScore, isNot(0.5));
      expect(d.normalizedScore, isNot(0.0));
      expect(d.normalizedScore, isNot(50));
    });
  });

  group('Canonical Frequency scorer', () {
    test('returns exactly 6 dims in canonical order; no scalar Frequency', () {
      DateTime clock() => DateTime.utc(2026, 8, 9, 16);
      final out = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: _pick(fixture, 'C'),
        clock: clock,
      );
      expect(out.ok, isTrue, reason: out.message);
      final r = out.result!;
      expect(r.dimensionScores.length, 6);
      for (var i = 0; i < 6; i++) {
        expect(
          r.dimensionScores[i].dimensionId,
          FrequencyCanonicalDimensions.all[i],
        );
      }
      final json = r.toJson();
      expect(json['overall_frequency_score'], isNull);
      expect(json['percentile'], isNull);
      expect(json['cronbach_alpha'], isNull);
      expect(json['rvi_runtime_gate'], FrequencyScoringContract.rviRuntimeGate);
      expect(r.reliabilityStatus, FrequencyReliabilityStatus.notCalibrated);
      expect(r.calibrationStatus, FrequencyCalibrationStatus.uncalibrated);
    });

    test('explicit deltas are scoring truth; reverse_scored does not invert',
        () {
      // fx_depth has reverse_scored=true but option C delta is already +1.
      final responses = <FrequencyCanonicalResponse>[
        const FrequencyCanonicalResponse(itemId: 'fx_depth', optionId: 'C'),
        const FrequencyCanonicalResponse(itemId: 'fx_social', optionId: 'B'),
        const FrequencyCanonicalResponse(
            itemId: 'fx_spontaneity', optionId: 'B'),
        const FrequencyCanonicalResponse(itemId: 'fx_stability', optionId: 'B'),
        const FrequencyCanonicalResponse(
            itemId: 'fx_disclosure', optionId: 'B'),
        const FrequencyCanonicalResponse(itemId: 'fx_comm', optionId: 'B'),
        const FrequencyCanonicalResponse(itemId: 'fx_quality', optionId: 'A'),
      ];
      final out = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: responses,
      );
      expect(out.ok, isTrue, reason: out.message);
      final depth = out.result!.scoreFor('depth_preference');
      expect(depth.rawSignedEvidence, closeTo(1.0, 1e-12));
      expect(depth.normalizedScore, closeTo(1.0, 1e-12));
    });

    test('quality-only item does not increase trait evidence', () {
      final a = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: _pick(fixture, 'B'),
      );
      expect(a.ok, isTrue);
      for (final d in a.result!.dimensionScores) {
        // One core contribution per dimension except stability gets fx_stability
        // + secondary from fx_comm when option B (stability 0).
        expect(d.evidenceCount, greaterThan(0));
      }
      final depth = a.result!.scoreFor('depth_preference');
      expect(depth.evidenceCount, 1);
    });

    test('option order / presentation order do not change scores', () {
      final responses = _pick(fixture, 'A');
      final reversed = responses.reversed.toList();
      final a = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: responses,
        clock: () => DateTime.utc(2026, 1, 1),
      );
      final b = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: reversed,
        clock: () => DateTime.utc(2026, 1, 1),
      );
      expect(a.ok && b.ok, isTrue);
      for (final id in FrequencyCanonicalDimensions.all) {
        expect(
          a.result!.scoreFor(id).normalizedScore,
          b.result!.scoreFor(id).normalizedScore,
        );
      }
    });

    test('repeated scoring is deterministic', () {
      final responses = _pick(fixture, 'C');
      final a = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final b = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(jsonEncode(a.result!.toJson()), jsonEncode(b.result!.toJson()));
    });

    test('rejects duplicate, unknown item, bad option, incomplete', () {
      final scorer = const CanonicalFrequencyScorer();
      final base = _pick(fixture, 'A');
      final dup = [
        base.first,
        base.first,
        ...base.sublist(2),
      ];
      expect(
        scorer.score(bank: fixture, responses: dup).code,
        FrequencyScoringFailureCode.duplicateAnswer,
      );
      final badItem = [
        ...base.sublist(1),
        const FrequencyCanonicalResponse(itemId: 'nope', optionId: 'A'),
      ];
      expect(
        scorer.score(bank: fixture, responses: badItem).code,
        FrequencyScoringFailureCode.unknownItem,
      );
      final badOpt = [
        for (final r in base)
          FrequencyCanonicalResponse(itemId: r.itemId, optionId: 'ZZ'),
      ];
      expect(
        scorer.score(bank: fixture, responses: badOpt).code,
        FrequencyScoringFailureCode.optionNotInItem,
      );
      expect(
        scorer.score(bank: fixture, responses: base.sublist(1)).code,
        FrequencyScoringFailureCode.incompleteSession,
      );
    });

    test('no Persona / matching / quantum side effects in result payload', () {
      final out = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: _pick(fixture, 'A'),
      );
      final raw = jsonEncode(out.result!.toJson());
      expect(raw.contains('persona'), isFalse);
      expect(raw.contains('qrcf'), isFalse);
      expect(raw.contains('density_matrix'), isFalse);
      expect(raw.contains('fidelity'), isFalse);
    });
  });
}
