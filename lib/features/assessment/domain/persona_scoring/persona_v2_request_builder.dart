import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import '../frequency_v2_runtime/frequency_v2_result_authority.dart';
import '../profile/qmatch_profile_contract.dart';
import '../profile/qmatch_profile_models.dart';
import 'persona_shadow_input.dart';
import 'persona_v2_contract.dart';
import 'persona_v2_request.dart';

/// Builds a Persona V2 request from IQ + EQ + authoritative Frequency V2.
///
/// Reads IQ/EQ measured rows from `canonical_v1` and ignores any Frequency
/// 6D rows. Frequency input is only the strict `frequency_v2` result.
class PersonaV2RequestBuilder {
  PersonaV2RequestBuilder._();

  static PersonaV2HandoffRequest fromAuthoritativeSources({
    required String ownerUid,
    required Map<String, dynamic> canonicalProfile,
    required Map<String, dynamic> iqAssessment,
    required Map<String, dynamic> eqAssessment,
    required Map<String, dynamic> frequencyV2Assessment,
  }) {
    if (ownerUid.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.ownerUnavailable,
        'Owner UID unavailable',
      );
    }
    if (!FrequencyV2ResultAuthority.isAuthoritativeCompleted(
      frequencyV2Assessment,
    )) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteAssessments,
        'Authoritative Frequency V2 result required',
      );
    }

    final scores = <String, double>{};
    final rows = canonicalProfile['measured_dimensions'];
    if (rows is! List) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteDimensionScores,
        'canonical measured_dimensions missing',
      );
    }
    for (final row in rows) {
      if (row is! Map) continue;
      final dim = QmatchProfileDimension.fromJson(
        Map<String, dynamic>.from(row),
      );
      if (dim.measurementState != QmatchMeasurementState.measured) continue;
      final value = dim.value;
      if (value == null) continue;
      if (PersonaV2Contract.iq.contains(dim.dimensionId) ||
          PersonaV2Contract.eq.contains(dim.dimensionId)) {
        scores[dim.dimensionId] = value;
      }
    }
    for (final id in [...PersonaV2Contract.iq, ...PersonaV2Contract.eq]) {
      if (!scores.containsKey(id)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.incompleteDimensionScores,
          'Incomplete IQ/EQ profile; missing score for $id',
        );
      }
    }

    final signed = FrequencyV2ResultAuthority.signedScores(
      frequencyV2Assessment,
    );
    if (signed == null) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteAssessments,
        'Frequency V2 scores unavailable',
      );
    }
    for (final id in PersonaV2Contract.frequencyV2) {
      final v = signed[id];
      if (v == null) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.incompleteDimensionScores,
          'Missing Frequency V2 score for $id',
        );
      }
      scores[id] = PersonaV2Contract.unitIntervalFromSignedBehavior(v);
    }

    final evidence = <String, int>{
      ..._evidenceFrom(iqAssessment),
      ..._evidenceFrom(eqAssessment),
      for (final id in PersonaV2Contract.frequencyV2) id: 1,
    };
    for (final id in PersonaV2Contract.all) {
      if (!evidence.containsKey(id) || evidence[id]! <= 0) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.missingEvidenceCount,
          'Missing evidence_count for $id',
        );
      }
    }

    return PersonaV2HandoffRequest(
      ownerUid: ownerUid,
      dimensionScores: scores,
      dimensionEvidenceCounts: evidence,
      iqScoringPolicyVersion: _requireString(
        iqAssessment,
        'scoring_policy_version',
      ),
      eqScoringPolicyVersion: _requireString(
        eqAssessment,
        'scoring_policy_version',
      ),
      frequencyV2ScoringPolicyVersion:
          FrequencyBehaviorV2Contract.scoringPolicyVersion,
      iqBankOrSessionVersion: _bankOrSessionVersion(iqAssessment),
      eqBankOrSessionVersion: _bankOrSessionVersion(eqAssessment),
      frequencyV2BankOrSessionVersion: _v2Bank(frequencyV2Assessment),
    );
  }

  static Map<String, int> _evidenceFrom(Map<String, dynamic> assessment) {
    final raw = assessment['dimension_evidence_counts'];
    if (raw is! Map) return {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is num) out[e.key.toString()] = v.toInt();
    }
    return out;
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final v = map[key]?.toString().trim() ?? '';
    if (v.isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.missingPolicyVersions,
        'Missing $key',
      );
    }
    return v;
  }

  static String _bankOrSessionVersion(Map<String, dynamic> assessment) {
    final bank = assessment['bank_version']?.toString().trim() ?? '';
    if (bank.isNotEmpty) return bank;
    final content = assessment['content_version']?.toString().trim() ?? '';
    if (content.isNotEmpty) return content;
    throw PersonaShadowScoringException(
      PersonaShadowFailureCode.missingBankOrSessionVersions,
      'Missing bank_version',
    );
  }

  static String _v2Bank(Map<String, dynamic> assessment) {
    final bank = assessment['bank_version']?.toString().trim() ?? '';
    if (bank.isNotEmpty) return bank;
    return FrequencyBehaviorV2Contract.poolVersionTrDraft1;
  }
}
