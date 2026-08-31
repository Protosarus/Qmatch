import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2.dart';

FrequencyBehaviorV2EvidenceMeta _reviewed({
  double socialDesirability = 0.25,
  double obviousness = 0.50,
  double behavioralPlausibility = 0.75,
  double selfPresentationRisk = 0.00,
  double diagnosticValue = 1.00,
  double ambiguity = 0.25,
}) {
  return FrequencyBehaviorV2EvidenceMeta(
    reviewStatus: FrequencyBehaviorV2Contract.evidenceReviewReviewed,
    socialDesirability: socialDesirability,
    obviousness: obviousness,
    behavioralPlausibility: behavioralPlausibility,
    selfPresentationRisk: selfPresentationRisk,
    diagnosticValue: diagnosticValue,
    ambiguity: ambiguity,
  );
}

void main() {
  const validator = FrequencyBehaviorV2PoolValidator();

  test('allowed evidence grid accepts only 0.00/0.25/0.50/0.75/1.00', () {
    for (final v in FrequencyBehaviorV2Contract.evidenceAllowedValues) {
      expect(FrequencyBehaviorV2Contract.isAllowedEvidenceValue(v), isTrue);
    }
    expect(FrequencyBehaviorV2Contract.isAllowedEvidenceValue(0.33), isFalse);
    expect(FrequencyBehaviorV2Contract.isAllowedEvidenceValue(0.1), isFalse);
    expect(FrequencyBehaviorV2Contract.isAllowedEvidenceValue(-0.25), isFalse);
    expect(FrequencyBehaviorV2Contract.isAllowedEvidenceValue(1.25), isFalse);

    final ok = validator.validateEvidenceMetaOnly(_reviewed());
    expect(ok.ok, isTrue, reason: ok.issues.join('; '));

    final bad = validator.validateEvidenceMetaOnly(
      _reviewed(socialDesirability: 0.33),
    );
    expect(bad.ok, isFalse);
    expect(
      bad.issues.any((e) => e.contains('evidence_meta_not_allowed_value')),
      isTrue,
    );
  });

  test('incomplete reviewed metadata is rejected', () {
    const incomplete = FrequencyBehaviorV2EvidenceMeta(
      reviewStatus: FrequencyBehaviorV2Contract.evidenceReviewReviewed,
      socialDesirability: 0.50,
      obviousness: 0.25,
    );
    final r = validator.validateEvidenceMetaOnly(incomplete);
    expect(r.ok, isFalse);
    expect(
      r.issues.any((e) => e.contains('incomplete_reviewed_evidence_meta')),
      isTrue,
    );
  });

  test('pending null metadata remains valid', () {
    const pending = FrequencyBehaviorV2EvidenceMeta();
    expect(pending.isPendingNull, isTrue);
    expect(pending.isResolved, isFalse);
    final r = validator.validateEvidenceMetaOnly(pending);
    expect(r.ok, isTrue, reason: r.issues.join('; '));
  });

  test('mixed null and numeric evidence is rejected', () {
    const mixed = FrequencyBehaviorV2EvidenceMeta(
      socialDesirability: 0.50,
    );
    final r = validator.validateEvidenceMetaOnly(mixed);
    expect(r.ok, isFalse);
    expect(
      r.issues.any((e) => e.contains('incomplete_evidence_meta_set')),
      isTrue,
    );
  });

  test('evidence contract documents relative uncalibrated priors', () {
    final doc = File(
      '${Directory.current.path}/${FrequencyBehaviorV2Contract.evidenceContractRelativePath}',
    ).readAsStringSync();
    expect(doc.contains('relative to the other three options'), isTrue);
    expect(doc.contains('High `social_desirability` does **not** mean'), isTrue);
    expect(doc.contains('UNCALIBRATED'), isTrue);
    expect(doc.contains('discrimination_power'), isTrue);
    expect(doc.contains('Do **not** infer deception'), isTrue);
    expect(
      FrequencyBehaviorV2Contract.evidenceMetaKeys,
      [
        'social_desirability',
        'obviousness',
        'behavioral_plausibility',
        'self_presentation_risk',
        'diagnostic_value',
        'ambiguity',
      ],
    );
  });

  test('12D scorer reads evidence only as separate means, not direction', () {
    final src = File(
      '${Directory.current.path}/lib/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_scorer.dart',
    ).readAsStringSync();
    expect(src.contains('behavioralWeights'), isTrue);
    expect(src.contains('normalizedBehavior'), isTrue);
    expect(src.contains('_accumulateEvidence'), isTrue);
    expect(src.contains('meanSelfPresentationRisk'), isTrue);
    expect(src.contains('never move the signed score'), isTrue);
  });
}
