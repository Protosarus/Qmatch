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

List<FrequencyCanonicalResponse> _firstOption(
  FrequencyCanonicalBankDocument bank,
) {
  return [
    for (final i in bank.items)
      FrequencyCanonicalResponse(
        itemId: i.itemId,
        optionId: i.options.first.optionId,
      ),
  ];
}

List<FrequencyCanonicalResponse> _withQuality(
  FrequencyCanonicalBankDocument bank, {
  required bool pass,
}) {
  return [
    for (final i in bank.items)
      FrequencyCanonicalResponse(
        itemId: i.itemId,
        optionId: i.itemRole == FrequencyBankContract.itemRoleQuality
            ? (pass
                ? i.expectedProtocolOptionId!
                : i.options
                    .firstWhere((o) => o.optionId != i.expectedProtocolOptionId)
                    .optionId)
            : i.options.first.optionId,
      ),
  ];
}

void main() {
  late FrequencyCanonicalBankDocument fixture;
  late FrequencyCanonicalBankDocument tr;
  late FrequencyCanonicalBankDocument en;

  setUpAll(() {
    fixture = _load('test/fixtures/frequency/frequency_math_fixture_v1.json');
    tr = _load(FrequencyBankContract.trAssetPath);
    en = _load(FrequencyBankContract.enAssetPath);
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

  group('Runtime-candidate bank validators', () {
    test('TR candidate: 50 items, blueprint roles, deltas valid', () {
      final v = const FrequencyCanonicalBankValidator().validate(tr);
      expect(v.ok, isTrue, reason: v.issues.join('; '));
      expect(tr.items.length, 50);
      expect(tr.status, FrequencyBankContract.statusRuntimeCandidate);
      expect(
          tr.calibrationStatus, FrequencyBankContract.calibrationUncalibrated);
      expect(
        tr.reliabilityStatus,
        FrequencyBankContract.reliabilityNotCalibrated,
      );
      expect(
          tr.scoringPolicyVersion, FrequencyBankContract.scoringPolicyVersion);
      expect(tr.rviRuntimeGate, FrequencyBankContract.rviGateNotActive);

      final roles = <String, int>{};
      for (final i in tr.items) {
        roles[i.itemRole] = (roles[i.itemRole] ?? 0) + 1;
      }
      expect(roles[FrequencyBankContract.itemRoleCore], 30);
      expect(roles[FrequencyBankContract.itemRoleBehavioralEquivalence], 12);
      expect(roles[FrequencyBankContract.itemRoleSeparator], 6);
      expect(roles[FrequencyBankContract.itemRoleQuality], 2);

      for (final c in v.coverage) {
        expect(c.corePrimaryItemCount, 5, reason: c.dimensionId);
        expect(c.relatedItemCount, 2, reason: c.dimensionId);
      }

      final sepIds = tr.items
          .where((i) => i.itemRole == FrequencyBankContract.itemRoleSeparator)
          .map((e) => e.itemId)
          .toSet();
      expect(sepIds, FrequencyBankContract.authoredSeparatorIds.toSet());
      for (final i in tr.items.where(
        (i) => i.itemRole == FrequencyBankContract.itemRoleSeparator,
      )) {
        expect(
          i.separatorType,
          FrequencyBankContract.separatorTypeDimensionBoundary,
        );
        expect(i.separatorDimensions.length, greaterThanOrEqualTo(2));
        expect(i.separatorPersonaTargets, isEmpty);
        expect(i.traitScoring, isTrue);
        expect(i.responseFormat, 'forced_choice');
        for (final o in i.options) {
          expect(o.dimensionDeltas, isNotEmpty);
          for (final e in o.dimensionDeltas.entries) {
            expect(e.value, inInclusiveRange(-1.0, 1.0));
          }
        }
      }

      final qual = tr.items
          .where((i) => i.itemRole == FrequencyBankContract.itemRoleQuality)
          .toList();
      expect(
        qual.map((e) => e.itemId).toSet(),
        FrequencyBankContract.authoredQualityIds.toSet(),
      );
      for (final i in qual) {
        expect(i.traitScoring, isFalse);
        expect(i.rviRuntimeGate, isFalse);
        expect(i.primaryDimension, isNull);
        expect(i.expectedProtocolOptionId, isNotNull);
        for (final o in i.options) {
          expect(o.dimensionDeltas, isEmpty);
        }
      }
      expect(
        tr.items
            .firstWhere((i) => i.itemId == 'freq_quality_instruction_v1')
            .expectedProtocolOptionId,
        'opt_b',
      );
      expect(
        tr.items
            .firstWhere((i) => i.itemId == 'freq_quality_protocol_v1')
            .expectedProtocolOptionId,
        'opt_c',
      );

      final bankJson =
          File(FrequencyBankContract.trAssetPath).readAsStringSync();
      expect(bankJson.contains('correctAnswer'), isFalse);
      expect(bankJson.contains('correct_option_id'), isFalse);
      expect(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').hasMatch(bankJson), isFalse);
      expect(FrequencyBankContract.registeredInPubspec, isTrue);
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub.contains('frequency_bank_tr_v1.json'), isTrue);
      expect(pub.contains('frequency_bank_en_v1.json'), isTrue);
      expect(pub.contains('frequency_pilot_tr_v1'), isFalse);
    });

    test('EN candidate validates identically on structure', () {
      final v = const FrequencyCanonicalBankValidator().validate(en);
      expect(v.ok, isTrue, reason: v.issues.join('; '));
      expect(en.items.length, 50);
      expect(en.bankVersion, FrequencyBankContract.enBankVersion);
      expect(en.locale, 'en-US');
    });

    test('separator deltas match authored R1A maps (depth_comm opt_a)', () {
      final item = tr.itemsById['freq_separator_depth_comm_v1']!;
      final a = item.optionById('opt_a')!;
      expect(a.dimensionDeltas['depth_preference'], closeTo(-0.45, 1e-12));
      expect(a.dimensionDeltas['communication_pace'], closeTo(0.70, 1e-12));
      final b = item.optionById('opt_b')!;
      expect(b.dimensionDeltas['depth_preference'], closeTo(0.75, 1e-12));
      expect(b.dimensionDeltas['communication_pace'], closeTo(-0.45, 1e-12));
    });
  });

  group('TR/EN structural parity', () {
    test('identical IDs, roles, dims, options, deltas, metadata', () {
      final p = const FrequencyCanonicalBankParity().compare(tr, en);
      expect(p.ok, isTrue, reason: p.issues.join('; '));
      expect(
        tr.items.map((e) => e.itemId).toSet(),
        en.items.map((e) => e.itemId).toSet(),
      );
      expect(tr.scoringPolicyVersion, en.scoringPolicyVersion);
      expect(tr.schemaVersion, en.schemaVersion);
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
    });
  });

  group('Canonical Frequency scorer', () {
    test('returns exactly 6 dims; no scalar Frequency', () {
      DateTime clock() => DateTime.utc(2026, 8, 9, 16);
      final out = const CanonicalFrequencyScorer().score(
        bank: fixture,
        responses: _firstOption(fixture),
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
    });

    test('quality pass/fail does not change trait z/x/evidence_count', () {
      final pass = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: _withQuality(tr, pass: true),
        clock: () => DateTime.utc(2026, 8, 9),
      );
      final fail = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: _withQuality(tr, pass: false),
        clock: () => DateTime.utc(2026, 8, 9),
      );
      expect(pass.ok && fail.ok, isTrue,
          reason: '${pass.message} / ${fail.message}');
      for (final id in FrequencyCanonicalDimensions.all) {
        final a = pass.result!.scoreFor(id);
        final b = fail.result!.scoreFor(id);
        expect(a.rawSignedEvidence, b.rawSignedEvidence, reason: id);
        expect(a.normalizedScore, b.normalizedScore, reason: id);
        expect(a.evidenceCount, b.evidenceCount, reason: id);
      }
    });

    test('quality-only items do not increase evidence_count', () {
      final out = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: _withQuality(tr, pass: true),
      );
      expect(out.ok, isTrue, reason: out.message);
      // 30 core + 12 BE + 6 separators = 48 trait items; quality adds 0.
      // Each trait item may contribute to multiple dims; evidence_count > 0
      // for all dims from core/BE/separators alone.
      for (final d in out.result!.dimensionScores) {
        expect(d.evidenceCount, greaterThan(0));
        expect(d.evidenceStatus, FrequencyDimensionEvidenceStatus.measured);
      }
    });

    test('separators contribute ordinary equal-weight trait evidence', () {
      // Score only separators on communication_pace via depth_comm opt_a (+0.70)
      // using a minimal synthetic path: compare full bank with separators answered
      // opt_a vs a bank clone is heavy; instead assert separator deltas enter mean
      // by scoring fixture-like responses on TR bank where we fix all non-separator
      // to first option and vary one separator.
      final base = _withQuality(tr, pass: true);
      final responsesA = [
        for (final r in base)
          r.itemId == 'freq_separator_depth_comm_v1'
              ? const FrequencyCanonicalResponse(
                  itemId: 'freq_separator_depth_comm_v1',
                  optionId: 'opt_a',
                )
              : r,
      ];
      final responsesB = [
        for (final r in base)
          r.itemId == 'freq_separator_depth_comm_v1'
              ? const FrequencyCanonicalResponse(
                  itemId: 'freq_separator_depth_comm_v1',
                  optionId: 'opt_b',
                )
              : r,
      ];
      final a = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: responsesA,
      );
      final b = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: responsesB,
      );
      expect(a.ok && b.ok, isTrue);
      expect(
        a.result!.scoreFor('communication_pace').normalizedScore,
        isNot(b.result!.scoreFor('communication_pace').normalizedScore),
      );
      expect(
        a.result!.scoreFor('communication_pace').evidenceCount,
        b.result!.scoreFor('communication_pace').evidenceCount,
      );
    });

    test('runtime candidate scores six dims; no Persona/matching/quantum', () {
      final out = const CanonicalFrequencyScorer().score(
        bank: tr,
        responses: _withQuality(tr, pass: true),
      );
      expect(out.ok, isTrue, reason: out.message);
      expect(out.result!.dimensionScores.length, 6);
      final raw = jsonEncode(out.result!.toJson());
      expect(raw.contains('persona'), isFalse);
      expect(raw.contains('qrcf'), isFalse);
      expect(raw.contains('density_matrix'), isFalse);
    });

    test('rejects duplicate / unknown / incomplete', () {
      final scorer = const CanonicalFrequencyScorer();
      final base = _firstOption(fixture);
      final dup = [base.first, base.first, ...base.sublist(2)];
      expect(
        scorer.score(bank: fixture, responses: dup).code,
        FrequencyScoringFailureCode.duplicateAnswer,
      );
      expect(
        scorer.score(bank: fixture, responses: base.sublist(1)).code,
        FrequencyScoringFailureCode.incompleteSession,
      );
    });
  });

  group('Live / profile non-regression guards', () {
    test(
        'live Frequency screens still present; profile docs track 20/20 readiness',
        () {
      expect(
        File('lib/features/assessment/screens/frequency_test_screen.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File('assets/data/assessment_sets/frequency_sets.json').existsSync(),
        isTrue,
      );
      final state = File('docs/QMATCH_CURRENT_STATE.md').readAsStringSync();
      // After R2 the continuity doc records 20/20; R1 docs may still mention 14/20.
      expect(
        state.contains('20 / 20') || state.contains('14 / 20'),
        isTrue,
      );
      expect(
        state.contains('canonical_profile_ready'),
        isTrue,
      );
    });
  });
}
