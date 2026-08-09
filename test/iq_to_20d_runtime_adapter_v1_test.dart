import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/profile/profile.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_persistence.dart';

IqCanonicalScoringResult _validResult({
  String locale = 'tr-TR',
  String bankVersion = 'tr_v2_340',
  String sessionId = 'sess_1',
  Map<String, double>? scores,
  String policy = IqScoringContract.scoringPolicyVersion,
}) {
  final values = scores ??
      const {
        'logical_reasoning': 0.86,
        'pattern_reasoning': 0.67,
        'verbal_reasoning': 0.83,
        'spatial_reasoning': 0.50,
      };
  return IqCanonicalScoringResult(
    schemaVersion: IqScoringContract.schemaVersion,
    bankVersion: bankVersion,
    bankLocale: locale,
    selectionPolicyVersion: 'iq_session_selection_policy_v1',
    scoringPolicyVersion: policy,
    sessionId: sessionId,
    dimensionScores: [
      for (final id in QmatchProfileTaxonomy.iq)
        IqDimensionScore(
          dimension: id,
          correctCount: 3,
          incorrectCount: 3,
          answeredCount: 6,
          itemCount: 6,
          rawAccuracy: values[id]!,
          provisionalScore: values[id]!,
          calibrationStatus: IqCalibrationStatus.uncalibrated,
        ),
    ],
    totalAnswered: 25,
    createdAt: '2026-08-09T12:00:00.000Z',
    calibrationStatus: IqCalibrationStatus.uncalibrated,
    structuralFlags: const IqScoringStructuralFlags(
      completeSession: true,
      quotaValid: true,
      canonicalBankValid: true,
    ),
  );
}

IqCanonicalScoringResult _resultWithDims(List<String> dims) {
  return IqCanonicalScoringResult(
    schemaVersion: IqScoringContract.schemaVersion,
    bankVersion: 'tr_v2_340',
    bankLocale: 'tr-TR',
    selectionPolicyVersion: 'iq_session_selection_policy_v1',
    scoringPolicyVersion: IqScoringContract.scoringPolicyVersion,
    sessionId: 's',
    dimensionScores: [
      for (final id in dims)
        IqDimensionScore(
          dimension: id,
          correctCount: 1,
          incorrectCount: 0,
          answeredCount: 1,
          itemCount: 1,
          rawAccuracy: 1,
          provisionalScore: 1,
          calibrationStatus: IqCalibrationStatus.uncalibrated,
        ),
    ],
    totalAnswered: dims.length,
    createdAt: '2026-08-09T12:00:00.000Z',
    calibrationStatus: IqCalibrationStatus.uncalibrated,
    structuralFlags: const IqScoringStructuralFlags(
      completeSession: true,
      quotaValid: true,
      canonicalBankValid: true,
    ),
  );
}

void main() {
  const adapter = IqTo20dRuntimeAdapter();

  group('P2C-2A-6 IqTo20dRuntimeAdapter', () {
    test('1-9 valid IQ maps exactly four measured dimensions', () {
      final outcome = adapter.adapt(
        result: _validResult(),
        ownerUid: 'uid_a',
        clock: DateTime.utc(2026, 8, 9, 15),
      );
      expect(outcome.ok, isTrue);
      final f = outcome.fragment!;
      expect(f.measuredDimensionCount, 4);
      expect(f.requiredDimensionCount, 20);
      expect(f.canonicalProfileReady, isFalse);
      expect(f.profileStatus, QmatchProfileStatus.partial);
      expect(f.iqGroupStatus, QmatchGroupCompletionStatus.complete);
      expect(f.eqGroupStatus, QmatchGroupCompletionStatus.notStarted);
      expect(f.frequencyGroupStatus, QmatchGroupCompletionStatus.notStarted);
      expect(
        f.measuredDimensions.map((d) => d.dimensionId).toList(),
        QmatchProfileTaxonomy.iq,
      );
      expect(
        f.measuredDimensions
            .firstWhere((d) => d.dimensionId == 'logical_reasoning')
            .value,
        0.86,
      );
      expect(
        f.measuredDimensions
            .firstWhere((d) => d.dimensionId == 'pattern_reasoning')
            .value,
        0.67,
      );
      expect(
        f.measuredDimensions
            .firstWhere((d) => d.dimensionId == 'verbal_reasoning')
            .value,
        0.83,
      );
      expect(
        f.measuredDimensions
            .firstWhere((d) => d.dimensionId == 'spatial_reasoning')
            .value,
        0.50,
      );
      for (final d in f.measuredDimensions) {
        expect(d.value! >= 0 && d.value! <= 1, isTrue);
        expect(d.measurementState, QmatchMeasurementState.measured);
        expect(d.source, 'canonical_iq');
        expect(d.reliabilityStatus, 'not_calibrated');
      }
    });

    test('7-8 no scalar IQ coordinate', () {
      final f = adapter.adapt(result: _validResult(), ownerUid: 'u').fragment!;
      final ids = f.measuredDimensions.map((d) => d.dimensionId).toSet();
      expect(ids.contains('iq_score'), isFalse);
      expect(ids.contains('overall_iq'), isFalse);
      final json = jsonEncode(f.toJson());
      expect(json.contains('"iq_score"'), isFalse);
      expect(json.contains('correct_option_id'), isFalse);
      expect(json.contains('"prompt"'), isFalse);
    });

    test('10-13 missing dims not fabricated as 0/0.5/50', () {
      final f = adapter.adapt(result: _validResult(), ownerUid: 'u').fragment!;
      expect(f.missingDimensionIds.length, 16);
      expect(f.missingGroups, ['eq', 'frequency']);
      expect(f.measuredDimensions.length, 4);
      expect(
        f.measuredDimensions.any((d) => d.dimensionId == 'empathy'),
        isFalse,
      );
    });

    test('14-18 completeness API after IQ only', () {
      final c = adapter
          .adapt(result: _validResult(), ownerUid: 'u')
          .fragment!
          .completeness;
      expect(c.iqGroupComplete, isTrue);
      expect(c.eqGroupComplete, isFalse);
      expect(c.frequencyGroupComplete, isFalse);
      expect(c.full20dReady, isFalse);
      expect(c.measuredCount, 4);
      expect(c.requiredCount, 20);
      expect(c.incompleteGroups, ['eq', 'frequency']);
      expect(c.completeGroups, ['iq']);
    });

    test('19-24 rejects invalid / malformed inputs', () {
      expect(
        adapter.adapt(result: _validResult(), ownerUid: '').code,
        IqTo20dFailureCode.ownerUnavailable,
      );
      expect(
        adapter
            .adapt(
              result: _resultWithDims([
                'logical_reasoning',
                'pattern_reasoning',
                'verbal_reasoning',
                'bogus_dim',
              ]),
              ownerUid: 'u',
            )
            .code,
        IqTo20dFailureCode.unknownDimension,
      );
      expect(
        adapter
            .adapt(
              result: _resultWithDims([
                'logical_reasoning',
                'logical_reasoning',
                'pattern_reasoning',
                'verbal_reasoning',
              ]),
              ownerUid: 'u',
            )
            .code,
        IqTo20dFailureCode.duplicateDimension,
      );
      expect(
        adapter
            .adapt(
              result: _resultWithDims([
                'logical_reasoning',
                'pattern_reasoning',
                'verbal_reasoning',
              ]),
              ownerUid: 'u',
            )
            .code,
        IqTo20dFailureCode.unexpectedDimensionCount,
      );
      expect(
        adapter
            .adapt(
              result: _validResult(
                scores: {
                  'logical_reasoning': 1.5,
                  'pattern_reasoning': 0.5,
                  'verbal_reasoning': 0.5,
                  'spatial_reasoning': 0.5,
                },
              ),
              ownerUid: 'u',
            )
            .code,
        IqTo20dFailureCode.outOfRange,
      );
      expect(
        adapter
            .adapt(
              result: _validResult(policy: 'other_policy'),
              ownerUid: 'u',
            )
            .code,
        IqTo20dFailureCode.incompatibleScoringPolicy,
      );
      expect(
        adapter.adapt(result: _validResult(sessionId: ''), ownerUid: 'u').code,
        IqTo20dFailureCode.malformedResult,
      );
    });

    test('25-28 calibration; reliability; idempotent', () {
      final a = adapter.adapt(
        result: _validResult(),
        ownerUid: 'uid_a',
        clock: DateTime.utc(2026, 8, 9, 12),
      );
      final b = adapter.adapt(
        result: _validResult(),
        ownerUid: 'uid_a',
        clock: DateTime.utc(2026, 8, 9, 12),
      );
      expect(a.fragment!.calibrationStatus, 'uncalibrated');
      expect(a.fragment!.toJson()['reliability_status'], 'not_calibrated');
      expect(a.fragment!.toJson().containsKey('reliability_estimate'), isFalse);
      expect(
        jsonEncode(a.fragment!.toJson()),
        jsonEncode(b.fragment!.toJson()),
      );
    });

    test('29-30 TR and EN map to same dimension IDs', () {
      final tr = adapter
          .adapt(
            result: _validResult(locale: 'tr-TR', bankVersion: 'tr_v2_340'),
            ownerUid: 'u',
          )
          .fragment!;
      final en = adapter
          .adapt(
            result: _validResult(locale: 'en-US', bankVersion: 'en_v2_340'),
            ownerUid: 'u',
          )
          .fragment!;
      expect(
        tr.measuredDimensions.map((d) => d.dimensionId).toList(),
        en.measuredDimensions.map((d) => d.dimensionId).toList(),
      );
      expect(tr.sourceBankLocale, 'tr-TR');
      expect(en.sourceBankLocale, 'en-US');
    });

    test('31-34 UID isolation + privacy', () {
      final a = adapter.adapt(result: _validResult(), ownerUid: 'uid_a');
      final b = adapter.adapt(result: _validResult(), ownerUid: 'uid_b');
      expect(a.fragment!.ownerUid, 'uid_a');
      expect(b.fragment!.ownerUid, 'uid_b');
      final s = jsonEncode(a.fragment!.toFirestoreFields());
      expect(s.contains('correct_option_id'), isFalse);
      expect(s.contains('"prompt"'), isFalse);
      expect(s.contains('"email"'), isFalse);
      expect(s.contains('"phone"'), isFalse);
    });

    test('35-40 adapter isolation + onboarding still IQ→EQ', () {
      final adapterFile = File(
        'lib/features/assessment/domain/profile/iq_to_20d_runtime_adapter.dart',
      ).readAsStringSync();
      expect(adapterFile.contains('PersonaScoring'), isFalse);
      expect(
        adapterFile.contains("import") &&
            adapterFile.split('\n').any(
                  (l) =>
                      l.contains('import') &&
                      l.toLowerCase().contains('quantum'),
                ),
        isFalse,
      );
      expect(adapterFile.contains('CompatibilityScoring'), isFalse);
      expect(adapterFile.contains('TraitScoringService'), isFalse);
      expect(adapterFile.contains('FrequencyService'), isFalse);

      final screen = File('lib/features/assessment/screens/iq_test_screen.dart')
          .readAsStringSync();
      expect(screen.contains('IqTo20dRuntimeAdapter'), isTrue);
      expect(screen.contains('EQTestIntroScreen'), isTrue);
      expect(screen.contains('upsertCanonicalProfileFragment'), isTrue);
      expect(screen.contains('PersonaReveal'), isFalse);
      expect(screen.contains('DiscoverService'), isFalse);

      final eq = File('lib/features/assessment/screens/eq_test_screen.dart')
          .readAsStringSync();
      expect(eq.contains('IqTo20dRuntimeAdapter'), isFalse);
      final freq =
          File('lib/features/assessment/screens/frequency_test_screen.dart')
              .readAsStringSync();
      expect(freq.contains('IqTo20dRuntimeAdapter'), isFalse);
    });

    test('taxonomy aligns with CanonicalDimensions', () {
      expect(QmatchProfileTaxonomy.all.length, 20);
      expect(CanonicalDimensions.iq, QmatchProfileTaxonomy.iq);
      expect(CanonicalDimensions.eq, QmatchProfileTaxonomy.eq);
      expect(CanonicalDimensions.frequency, QmatchProfileTaxonomy.frequency);
    });

    test('serialization round-trip', () {
      final f = adapter
          .adapt(
            result: _validResult(),
            ownerUid: 'uid_rt',
            clock: DateTime.utc(2026, 8, 9, 12),
          )
          .fragment!;
      final again = QmatchCanonicalProfileFragment.fromJson(f.toJson());
      expect(jsonEncode(again.toJson()), jsonEncode(f.toJson()));
    });
  });
}
