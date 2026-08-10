import 'canonical_persona_shadow_scorer.dart';
import 'persona_dimension_profile.dart';
import 'persona_runtime_handoff_request.dart';
import 'persona_runtime_handoff_result.dart';
import 'persona_shadow_input.dart';

/// Runtime bridge: complete canonical 20D profile → shadow distance assignment.
///
/// * Uses [CanonicalPersonaShadowScorer] only (never the legacy affinity scorer).
/// * No Firestore writes, routes, UI, Matching, or Discover coupling.
/// * No percentages / confidence / affinity / temperature / RVI / quantum.
class PersonaRuntimeHandoffService {
  PersonaRuntimeHandoffService({required this.scorer});

  final CanonicalPersonaShadowScorer scorer;

  /// Build a validated [PersonaShadowInput] from a complete 20D request.
  ///
  /// Rejects incomplete 20D profiles before scoring.
  PersonaShadowInput buildInput(PersonaRuntimeHandoffRequest request) {
    _rejectIncomplete20d(request);
    return PersonaShadowInput(
      dimensionScores: Map<String, double>.unmodifiable(request.dimensionScores),
      dimensionRegistryVersion: request.dimensionRegistryVersion,
      source: PersonaShadowSourceEvidence(
        ownerUid: request.ownerUid,
        iqCompleted: request.iqCompleted,
        eqCompleted: request.eqCompleted,
        frequencyCompleted: request.frequencyCompleted,
        iqScoringPolicyVersion: request.iqScoringPolicyVersion,
        eqScoringPolicyVersion: request.eqScoringPolicyVersion,
        frequencyScoringPolicyVersion: request.frequencyScoringPolicyVersion,
        iqBankOrSessionVersion: request.iqBankOrSessionVersion,
        eqBankOrSessionVersion: request.eqBankOrSessionVersion,
        frequencyBankOrSessionVersion: request.frequencyBankOrSessionVersion,
        dimensionEvidenceCounts:
            Map<String, int>.unmodifiable(request.dimensionEvidenceCounts),
      ),
    );
  }

  /// Score and return primary / secondary / raw Δ_D / versions only.
  PersonaRuntimeHandoffResult assign(PersonaRuntimeHandoffRequest request) {
    final input = buildInput(request);
    final scored = scorer.score(input);
    return PersonaRuntimeHandoffResult(
      primaryPersonaId: scored.primaryCandidateId,
      secondaryPersonaId: scored.secondaryCandidateId,
      rawDeltaD: scored.top2DistanceMargin,
      scoringVersion: scored.scoringVersion,
      configVersion: scored.configVersion,
      prototypeVersion: scored.prototypeVersion,
      policyVersion: scored.policyVersion,
    );
  }

  void _rejectIncomplete20d(PersonaRuntimeHandoffRequest request) {
    final required = scorer.catalog.dimensionOrder;
    if (required.length != PersonaDimensionIds.all.length) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompatibleConfig,
        'Catalog dimension count ${required.length} != canonical 20',
      );
    }

    final missingScores = <String>[];
    for (final d in required) {
      if (!request.dimensionScores.containsKey(d)) {
        missingScores.add(d);
      }
    }
    if (missingScores.isNotEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.incompleteDimensionScores,
        'Incomplete 20D profile; missing scores: ${missingScores.join(', ')}',
      );
    }

    final missingCounts = <String>[];
    for (final d in required) {
      if (!request.dimensionEvidenceCounts.containsKey(d)) {
        missingCounts.add(d);
      }
    }
    if (missingCounts.isNotEmpty) {
      throw PersonaShadowScoringException(
        PersonaShadowFailureCode.missingEvidenceCount,
        'Incomplete evidence counts; missing: ${missingCounts.join(', ')}',
      );
    }

    // Extra keys beyond the registry are rejected (no silent ignore).
    for (final d in request.dimensionScores.keys) {
      if (PersonaDimensionIds.forbiddenAliases.contains(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.legacyDimensionAlias,
          'Legacy alias not allowed: $d',
        );
      }
      if (!PersonaDimensionIds.allSet.contains(d)) {
        throw PersonaShadowScoringException(
          PersonaShadowFailureCode.unknownDimension,
          'Unknown dimension: $d',
        );
      }
    }
  }
}
