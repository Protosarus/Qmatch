import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/eq_scoring/eq_scoring.dart';
import 'package:qmatch/features/assessment/domain/profile/profile.dart';
import 'package:qmatch/features/assessment/services/canonical_assessment_profile_reconciler.dart';

void main() {
  group('HOTFIX2 CanonicalAssessmentProfileReconciler', () {
    test('parses exact IQ4 from canonical assessment doc', () {
      final doc = _validIqAssessmentDoc();
      final parsed =
          CanonicalAssessmentProfileReconciler.tryParseIqResultFromAssessment(
        doc,
        ownerUid: 'uid_a',
      );
      expect(parsed, isNotNull);
      expect(parsed!.dimensionScores.length, 4);
      expect(
        parsed.dimensionScores.map((e) => e.dimension).toList(),
        QmatchProfileTaxonomy.iq,
      );
      final adapted = const IqTo20dRuntimeAdapter().adapt(
        result: parsed,
        ownerUid: 'uid_a',
      );
      expect(adapted.ok, isTrue);
      expect(adapted.fragment!.measuredDimensionCount, 4);
      expect(adapted.fragment!.canonicalProfileReady, isFalse);
    });

    test('rejects legacy scalar-only IQ assessment', () {
      final doc = <String, dynamic>{
        'status': 'completed',
        'iq_score': 18,
        'raw_score': 18,
        'scoring_policy_version': 'iq_4d_uncalibrated_accuracy_v1',
      };
      expect(
        CanonicalAssessmentProfileReconciler.tryParseIqResultFromAssessment(
          doc,
          ownerUid: 'uid_a',
        ),
        isNull,
      );
    });

    test('rejects incomplete IQ dimension set', () {
      final doc = _validIqAssessmentDoc();
      (doc['canonical_dimensions'] as List).removeLast();
      expect(
        CanonicalAssessmentProfileReconciler.tryParseIqResultFromAssessment(
          doc,
          ownerUid: 'uid_a',
        ),
        isNull,
      );
    });

    test('inspectProfileMap validates exact registry sets', () {
      final r = CanonicalAssessmentProfileReconciler();
      final missing = r.inspectProfileMap(null);
      expect(missing.hasExactIq4, isFalse);

      final profile = {
        'measured_dimensions': [
          for (final id in QmatchProfileTaxonomy.iq)
            {
              'dimension_id': id,
              'module': 'iq',
              'measurement_state': 'measured',
              'value': 0.5,
              'reliability_status': 'not_calibrated',
            },
        ],
      };
      final ok = r.inspectProfileMap(profile);
      expect(ok.hasExactIq4, isTrue);
      expect(ok.hasExact14, isFalse);

      final dup = {
        'measured_dimensions': [
          ...profile['measured_dimensions'] as List,
          {
            'dimension_id': 'logical_reasoning',
            'module': 'iq',
            'measurement_state': 'measured',
            'value': 0.1,
            'reliability_status': 'not_calibrated',
          },
        ],
      };
      expect(r.inspectProfileMap(dup).code,
          CanonicalProfileRepairCode.invalidRegistrySet);
    });

    test('parses EQ10 from canonical assessment and merges with IQ4', () {
      final iq =
          CanonicalAssessmentProfileReconciler.tryParseIqResultFromAssessment(
        _validIqAssessmentDoc(),
        ownerUid: 'uid_a',
      )!;
      final iqFrag = const IqTo20dRuntimeAdapter()
          .adapt(result: iq, ownerUid: 'uid_a')
          .fragment!;
      final eq =
          CanonicalAssessmentProfileReconciler.tryParseEqResultFromAssessment(
              _validEqAssessmentDoc())!;
      expect(eq.dimensionScores.length, 10);

      final adapted = const EqTo20dRuntimeAdapter().adapt(
        result: eq,
        ownerUid: 'uid_a',
        sessionId: 'eq_sess_1',
        existingIqDimensions: iqFrag.measuredDimensions,
      );
      expect(adapted.ok, isTrue);
      expect(adapted.fragment!.measuredDimensionCount, 14);
      expect(adapted.fragment!.canonicalProfileReady, isFalse);
      expect(adapted.fragment!.missingDimensionIds.length, 6);
    });

    test('EQ adapter still rejects missing IQ4 (precondition intact)', () {
      final eq =
          CanonicalAssessmentProfileReconciler.tryParseEqResultFromAssessment(
              _validEqAssessmentDoc())!;
      final fail = const EqTo20dRuntimeAdapter().adapt(
        result: eq,
        ownerUid: 'uid_a',
        sessionId: 'eq_sess_1',
        existingIqDimensions: const [],
      );
      expect(fail.ok, isFalse);
      expect(fail.code, EqTo20dFailureCode.iqPreservationFailed);
      expect(fail.message, 'Existing IQ measured dimensions incomplete');
    });
  });
}

Map<String, dynamic> _validIqAssessmentDoc() {
  return {
    'status': 'completed',
    'scoring_policy_version': 'iq_4d_uncalibrated_accuracy_v1',
    'bank_version': 'iq_bank_v1',
    'bank_locale': 'tr-TR',
    'selection_policy_version': 'iq_session_selection_v1',
    'session_id': 'iq_sess_1',
    'answered_count': 25,
    'calibration_status': 'uncalibrated',
    'structural_flags': {
      'complete_session': true,
      'quota_valid': true,
      'canonical_bank_valid': true,
    },
    'canonical_dimensions': [
      for (final e in [
        ('logical_reasoning', 7, 5),
        ('pattern_reasoning', 6, 3),
        ('verbal_reasoning', 6, 4),
        ('spatial_reasoning', 6, 2),
      ])
        {
          'dimension': e.$1,
          'item_count': e.$2,
          'correct_count': e.$3,
          'incorrect_count': e.$2 - e.$3,
          'answered_count': e.$2,
          'raw_accuracy': e.$3 / e.$2,
          'provisional_score': e.$3 / e.$2,
          'calibration_status': 'uncalibrated',
        },
    ],
  };
}

Map<String, dynamic> _validEqAssessmentDoc() {
  return {
    'status': 'completed',
    'scoring_policy_version': 'eq_10d_uncalibrated_signed_evidence_v1',
    'bank_version': 'eq_bank_v1',
    'bank_locale': 'tr-TR',
    'session_id': 'eq_sess_1',
    'answered_count': 30,
    'calibration_status': 'uncalibrated',
    'reliability_status': 'not_calibrated',
    'response_validity': {
      'rvi_runtime_gate': EqScoringContract.rviRuntimeGate,
    },
    'structural_flags': {
      'complete_session': true,
      'canonical_bank_valid': true,
      'all_dimensions_measured': true,
    },
    'canonical_dimensions': [
      for (final id in QmatchProfileTaxonomy.eq)
        {
          'dimension_id': id,
          'evidence_status': 'measured',
          'evidence_count': 3,
          'raw_signed_evidence': 0.2,
          'normalized_score': 0.6,
          'calibration_status': 'uncalibrated',
          'reliability_status': 'not_calibrated',
        },
    ],
  };
}
