import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_bank/eq_bank.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring.dart';

EqCanonicalBankDocument _load(String path) {
  return EqCanonicalBankDocument.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

List<EqCanonicalResponse> _allOptionA(EqCanonicalBankDocument bank) {
  return [
    for (final i in bank.items)
      EqCanonicalResponse(itemId: i.itemId, optionId: i.options.first.optionId),
  ];
}

void main() {
  late EqCanonicalBankDocument tr;
  late EqCanonicalBankDocument en;

  setUpAll(() {
    tr = _load(EqBankContract.trAssetPath);
    en = _load(EqBankContract.enAssetPath);
  });

  group('EQ bank validators', () {
    test('TR candidate: 30 items, 10 dims, 3 primary each, deltas valid', () {
      final v = const EqCanonicalBankValidator().validate(tr);
      expect(v.ok, isTrue, reason: v.issues.join('; '));
      expect(tr.items.length, 30);
      expect(tr.bankVersion, EqBankContract.trBankVersion);
      expect(tr.status, EqBankContract.statusRuntimeCandidate);
      expect(tr.calibrationStatus, EqBankContract.calibrationUncalibrated);
      expect(tr.reliabilityStatus, EqBankContract.reliabilityNotCalibrated);
      expect(tr.scoringPolicyVersion, EqBankContract.scoringPolicyVersion);
      expect(tr.rviRuntimeGate, EqBankContract.rviGateNotActive);

      final ids = tr.items.map((e) => e.itemId).toSet();
      expect(ids.length, 30);
      for (final c in v.coverage) {
        expect(c.primaryItemCount, 3, reason: c.dimensionId);
        expect(c.totalPossibleEvidenceCount, greaterThanOrEqualTo(3));
      }
      for (final item in tr.items) {
        expect(item.prompt.trim().isNotEmpty, isTrue);
        expect(item.options.length, 4);
        final optIds = item.options.map((o) => o.optionId).toSet();
        expect(optIds.length, 4);
        for (final o in item.options) {
          expect(o.text.trim().isNotEmpty, isTrue);
          expect(o.dimensionDeltas.containsKey(item.primaryDimension), isTrue);
          for (final e in o.dimensionDeltas.entries) {
            expect(EqCanonicalDimensions.isCanonical(e.key), isTrue);
            expect(EqCanonicalDimensions.isForbiddenLegacy(e.key), isFalse);
            expect(e.value.isFinite, isTrue);
            expect(e.value, inInclusiveRange(-1.0, 1.0));
          }
        }
        final raw = jsonEncode(item.toJson());
        expect(raw.contains('correctAnswer'), isFalse);
        expect(raw.contains('correct_option_id'), isFalse);
        expect(raw.contains('answer_key'), isFalse);
      }
      final bankJson = File(EqBankContract.trAssetPath).readAsStringSync();
      expect(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(bankJson), isFalse);
    });

    test('EN candidate validates identically on structure', () {
      final v = const EqCanonicalBankValidator().validate(en);
      expect(v.ok, isTrue, reason: v.issues.join('; '));
      expect(en.items.length, 30);
      expect(en.bankVersion, EqBankContract.enBankVersion);
      expect(en.locale, 'en-US');
    });

    test('no legacy dimension IDs anywhere', () {
      for (final bank in [tr, en]) {
        for (final item in bank.items) {
          expect(
            EqCanonicalDimensions.forbiddenLegacy
                .contains(item.primaryDimension),
            isFalse,
          );
          for (final o in item.options) {
            for (final d in o.dimensionDeltas.keys) {
              expect(
                  EqCanonicalDimensions.forbiddenLegacy.contains(d), isFalse);
            }
          }
        }
      }
    });
    test('runtime candidates registered in pubspec (R2 live)', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub.contains('eq_bank_tr_v1.json'), isTrue);
      expect(pub.contains('eq_bank_en_v1.json'), isTrue);
      expect(EqBankContract.registeredInPubspec, isTrue);
    });
  });

  group('TR/EN structural parity', () {
    test('identical IDs, dims, options, deltas, scoring metadata', () {
      final p = const EqCanonicalBankParity().compare(tr, en);
      expect(p.ok, isTrue, reason: p.issues.join('; '));
      expect(
        tr.items.map((e) => e.itemId).toSet(),
        en.items.map((e) => e.itemId).toSet(),
      );
      expect(tr.scoringPolicyVersion, en.scoringPolicyVersion);
      expect(tr.schemaVersion, en.schemaVersion);
      expect(tr.pairRegistry.keys, en.pairRegistry.keys);
    });

    test('EN has no Turkish letters; TR has Turkish content', () {
      final trChars = RegExp(r'[ğüşıöçĞÜŞİÖÇ]');
      var trHits = 0;
      for (final i in tr.items) {
        if (trChars.hasMatch(i.prompt)) trHits++;
        for (final o in i.options) {
          if (trChars.hasMatch(o.text)) trHits++;
        }
      }
      expect(trHits, greaterThan(0));
      for (final i in en.items) {
        expect(trChars.hasMatch(i.prompt), isFalse, reason: i.itemId);
        for (final o in i.options) {
          expect(trChars.hasMatch(o.text), isFalse,
              reason: '${i.itemId}:${o.optionId}');
        }
        expect(i.prompt.contains('EN equivalent pending'), isFalse);
      }
    });
  });

  group('Mathematical fixtures (a_ij=1)', () {
    test('[-1,-1,-1] → z=-1 x=0', () {
      final m = EqSignedEvidenceMath.meanSignedEvidence([-1, -1, -1])!;
      expect(m.z, closeTo(-1.0, 1e-12));
      expect(m.x, closeTo(0.0, 1e-12));
      expect(m.n, 3);
    });

    test('[0,0,0] → z=0 x=0.5', () {
      final m = EqSignedEvidenceMath.meanSignedEvidence([0, 0, 0])!;
      expect(m.z, closeTo(0.0, 1e-12));
      expect(m.x, closeTo(0.5, 1e-12));
    });

    test('[1,1,1] → z=1 x=1', () {
      final m = EqSignedEvidenceMath.meanSignedEvidence([1, 1, 1])!;
      expect(m.z, closeTo(1.0, 1e-12));
      expect(m.x, closeTo(1.0, 1e-12));
    });

    test('[-1,0,1] → z=0 x=0.5', () {
      final m = EqSignedEvidenceMath.meanSignedEvidence([-1, 0, 1])!;
      expect(m.z, closeTo(0.0, 1e-12));
      expect(m.x, closeTo(0.5, 1e-12));
    });

    test('[-0.5,0.5,1] → z=1/3 x=2/3', () {
      final m = EqSignedEvidenceMath.meanSignedEvidence([-0.5, 0.5, 1])!;
      expect(m.z, closeTo(1 / 3, 1e-12));
      expect(m.x, closeTo(2 / 3, 1e-12));
    });

    test('empty evidence is insufficient — not 0 / 0.5', () {
      expect(EqSignedEvidenceMath.meanSignedEvidence(const []), isNull);
    });
  });

  group('Canonical EQ scorer', () {
    test('returns exactly 10 dims in canonical order; no scalar EQ', () {
      DateTime clock() => DateTime.utc(2026, 8, 9, 16);
      final out = const CanonicalEqScorer().score(
        bank: tr,
        responses: _allOptionA(tr),
        clock: clock,
      );
      expect(out.ok, isTrue, reason: out.message);
      final r = out.result!;
      expect(r.dimensionScores.length, 10);
      for (var i = 0; i < 10; i++) {
        expect(
          r.dimensionScores[i].dimensionId,
          EqCanonicalDimensions.all[i],
        );
        expect(r.dimensionScores[i].evidenceStatus,
            EqDimensionEvidenceStatus.measured);
        expect(r.dimensionScores[i].evidenceCount, greaterThan(0));
        expect(r.dimensionScores[i].rawSignedEvidence, inInclusiveRange(-1, 1));
        expect(r.dimensionScores[i].normalizedScore, inInclusiveRange(0, 1));
        expect(
          r.dimensionScores[i].calibrationStatus,
          EqCalibrationStatus.uncalibrated,
        );
        expect(
          r.dimensionScores[i].reliabilityStatus,
          EqReliabilityStatus.notCalibrated,
        );
      }
      final json = r.toJson();
      expect(json['overall_eq_score'], isNull);
      expect(json['percentile'], isNull);
      expect(json['correct_count'], isNull);
      expect(json['reliability_estimate'], isNull);
      expect(json['cronbach_alpha'], isNull);
      expect(json['rvi_runtime_gate'], EqScoringContract.rviRuntimeGate);
      expect(r.scoringPolicyVersion, EqScoringContract.scoringPolicyVersion);
    });

    test('TR and EN equivalent response IDs → identical numeric output', () {
      final responses = _allOptionA(tr);
      final trOut = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final enOut = const CanonicalEqScorer().score(
        bank: en,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(trOut.ok && enOut.ok, isTrue);
      for (final dim in EqCanonicalDimensions.all) {
        final a = trOut.result!.scoreFor(dim);
        final b = enOut.result!.scoreFor(dim);
        expect(a.evidenceCount, b.evidenceCount);
        expect(a.rawSignedEvidence, closeTo(b.rawSignedEvidence!, 1e-12));
        expect(a.normalizedScore, closeTo(b.normalizedScore!, 1e-12));
      }
    });

    test('option presentation order does not change score', () {
      final base = _allOptionA(tr);
      final shuffledBank = EqCanonicalBankDocument(
        schemaVersion: tr.schemaVersion,
        bankVersion: tr.bankVersion,
        contentVersion: tr.contentVersion,
        locale: tr.locale,
        status: tr.status,
        calibrationStatus: tr.calibrationStatus,
        reliabilityStatus: tr.reliabilityStatus,
        scoringPolicyVersion: tr.scoringPolicyVersion,
        pairRegistry: tr.pairRegistry,
        rviRuntimeGate: tr.rviRuntimeGate,
        items: [
          for (final item in tr.items)
            EqCanonicalItem(
              itemId: item.itemId,
              primaryDimension: item.primaryDimension,
              secondaryDimensions: item.secondaryDimensions,
              prompt: item.prompt,
              semanticPairId: item.semanticPairId,
              reversePairId: item.reversePairId,
              sourcePilotQuestionId: item.sourcePilotQuestionId,
              responseFormat: item.responseFormat,
              options: [...item.options.reversed],
            ),
        ],
      );
      final a = const CanonicalEqScorer().score(
        bank: tr,
        responses: base,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final b = const CanonicalEqScorer().score(
        bank: shuffledBank,
        responses: base,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(a.ok && b.ok, isTrue);
      for (final dim in EqCanonicalDimensions.all) {
        expect(
          a.result!.scoreFor(dim).normalizedScore,
          closeTo(b.result!.scoreFor(dim).normalizedScore!, 1e-12),
        );
      }
    });

    test('item presentation order does not change score', () {
      final responses = _allOptionA(tr);
      final reversedItems = [...tr.items.reversed];
      final bank2 = EqCanonicalBankDocument(
        schemaVersion: tr.schemaVersion,
        bankVersion: tr.bankVersion,
        contentVersion: tr.contentVersion,
        locale: tr.locale,
        status: tr.status,
        calibrationStatus: tr.calibrationStatus,
        reliabilityStatus: tr.reliabilityStatus,
        scoringPolicyVersion: tr.scoringPolicyVersion,
        pairRegistry: tr.pairRegistry,
        rviRuntimeGate: tr.rviRuntimeGate,
        items: reversedItems,
      );
      final shuffledResponses = [...responses]..shuffle(Random(7));
      final a = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final b = const CanonicalEqScorer().score(
        bank: bank2,
        responses: shuffledResponses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(a.ok && b.ok, isTrue);
      for (final dim in EqCanonicalDimensions.all) {
        expect(
          a.result!.scoreFor(dim).rawSignedEvidence,
          closeTo(b.result!.scoreFor(dim).rawSignedEvidence!, 1e-12),
        );
      }
    });

    test('rejects incomplete, duplicate, unknown item/option', () {
      final full = _allOptionA(tr);
      expect(
        const CanonicalEqScorer()
            .score(bank: tr, responses: full.sublist(0, 29))
            .code,
        EqScoringFailureCode.incompleteSession,
      );
      expect(
        const CanonicalEqScorer().score(
          bank: tr,
          responses: [...full, full.first],
        ).code,
        EqScoringFailureCode.incompleteSession,
      );
      final dup = [
        ...full.sublist(0, 29),
        EqCanonicalResponse(itemId: full.first.itemId, optionId: 'A'),
      ];
      expect(
        const CanonicalEqScorer().score(bank: tr, responses: dup).code,
        EqScoringFailureCode.duplicateAnswer,
      );
      final badItem = [
        ...full.sublist(0, 29),
        const EqCanonicalResponse(itemId: 'nope', optionId: 'A'),
      ];
      expect(
        const CanonicalEqScorer().score(bank: tr, responses: badItem).code,
        EqScoringFailureCode.unknownItem,
      );
      final badOpt = [
        for (final r in full)
          r.itemId == full.first.itemId
              ? EqCanonicalResponse(itemId: r.itemId, optionId: 'Z')
              : r,
      ];
      expect(
        const CanonicalEqScorer().score(bank: tr, responses: badOpt).code,
        EqScoringFailureCode.optionNotInItem,
      );
    });

    test('rejects incompatible policy', () {
      final bad = EqCanonicalBankDocument(
        schemaVersion: tr.schemaVersion,
        bankVersion: tr.bankVersion,
        contentVersion: tr.contentVersion,
        locale: tr.locale,
        status: tr.status,
        calibrationStatus: tr.calibrationStatus,
        reliabilityStatus: tr.reliabilityStatus,
        scoringPolicyVersion: 'fake_policy',
        pairRegistry: tr.pairRegistry,
        rviRuntimeGate: tr.rviRuntimeGate,
        items: tr.items,
      );
      expect(
        const CanonicalEqScorer()
            .score(bank: bad, responses: _allOptionA(tr))
            .code,
        EqScoringFailureCode.incompatiblePolicy,
      );
    });

    test('deterministic across repeated calls', () {
      final responses = _allOptionA(tr);
      final a = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final b = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(jsonEncode(a.result!.toJson()), jsonEncode(b.result!.toJson()));
    });

    test('exact z formula uses only explicit deltas (mean)', () {
      // Pick empathy primary items; force options and recompute mean manually.
      final empathyItems =
          tr.items.where((i) => i.primaryDimension == 'empathy').toList();
      expect(empathyItems.length, 3);
      final chosen = <String, String>{};
      final expected = <double>[];
      for (final item in empathyItems) {
        final opt = item.options.first;
        chosen[item.itemId] = opt.optionId;
        expected.add(opt.dimensionDeltas['empathy']!);
      }
      final responses = [
        for (final i in tr.items)
          EqCanonicalResponse(
            itemId: i.itemId,
            optionId: chosen[i.itemId] ?? i.options.first.optionId,
          ),
      ];
      // Collect ALL explicit empathy deltas from selected options (incl secondary).
      final allEmpathy = <double>[];
      final byId = tr.itemsById;
      for (final r in responses) {
        final d = byId[r.itemId]!.optionById(r.optionId)!.dimensionDeltas;
        if (d.containsKey('empathy')) allEmpathy.add(d['empathy']!);
      }
      final out = const CanonicalEqScorer().score(
        bank: tr,
        responses: responses,
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(out.ok, isTrue);
      final z = allEmpathy.reduce((a, b) => a + b) / allEmpathy.length;
      expect(
          out.result!.scoreFor('empathy').rawSignedEvidence, closeTo(z, 1e-12));
      expect(
        out.result!.scoreFor('empathy').normalizedScore,
        closeTo((z + 1) / 2, 1e-12),
      );
      expect(out.result!.scoreFor('empathy').evidenceCount, allEmpathy.length);
    });
  });
}
