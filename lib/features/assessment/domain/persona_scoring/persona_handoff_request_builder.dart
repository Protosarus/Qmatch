import '../profile/qmatch_profile_contract.dart';
import '../profile/qmatch_profile_models.dart';
import 'persona_dimension_profile.dart';
import 'persona_runtime_handoff_request.dart';
import 'persona_shadow_input.dart';

/// Builds a [PersonaRuntimeHandoffRequest] from canonical 20D + module docs.
class PersonaHandoffRequestBuilder {
  PersonaHandoffRequestBuilder._();

  static PersonaRuntimeHandoffRequest fromCanonicalSources({
    required String ownerUid,
    required Map<String, dynamic> canonicalProfile,
    required Map<String, dynamic> iqAssessment,
    required Map<String, dynamic> eqAssessment,
    required Map<String, dynamic> frequencyAssessment,
  }) {
    if (ownerUid.trim().isEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.ownerUnavailable,
        'Owner UID unavailable',
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
      final map = Map<String, dynamic>.from(row);
      final dim = QmatchProfileDimension.fromJson(map);
      if (dim.measurementState != QmatchMeasurementState.measured) continue;
      final value = dim.value;
      if (value == null) continue;
      scores[dim.dimensionId] = value;
    }
    for (final id in PersonaDimensionIds.all) {
      if (!scores.containsKey(id)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.incompleteDimensionScores,
          'Incomplete 20D profile; missing score for $id',
        );
      }
    }

    final evidence = <String, int>{
      ..._evidenceFrom(iqAssessment),
      ..._evidenceFrom(eqAssessment),
      ..._evidenceFrom(frequencyAssessment),
    };
    for (final id in PersonaDimensionIds.all) {
      if (!evidence.containsKey(id)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.missingEvidenceCount,
          'Missing evidence_count for $id',
        );
      }
    }

    final iqPolicy = _requireString(iqAssessment, 'scoring_policy_version');
    final eqPolicy = _requireString(eqAssessment, 'scoring_policy_version');
    final freqPolicy =
        _requireString(frequencyAssessment, 'scoring_policy_version');
    final iqBank = _bankOrSessionVersion(iqAssessment);
    final eqBank = _bankOrSessionVersion(eqAssessment);
    final freqBank = _bankOrSessionVersion(frequencyAssessment);

    final registry = canonicalProfile['registry_version']?.toString() ??
        QmatchProfileContract.registryVersion;

    return PersonaRuntimeHandoffRequest(
      ownerUid: ownerUid,
      dimensionScores: scores,
      dimensionEvidenceCounts: evidence,
      iqCompleted: true,
      eqCompleted: true,
      frequencyCompleted: true,
      iqScoringPolicyVersion: iqPolicy,
      eqScoringPolicyVersion: eqPolicy,
      frequencyScoringPolicyVersion: freqPolicy,
      iqBankOrSessionVersion: iqBank,
      eqBankOrSessionVersion: eqBank,
      frequencyBankOrSessionVersion: freqBank,
      dimensionRegistryVersion: registry,
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
}
