import '../persona_scoring/persona_dimension_profile.dart';
import '../persona_scoring/persona_scoring_input.dart';
import '../persona_scoring/persona_scoring_status.dart';
import 'module_trait_result.dart';
import 'response_validity_result.dart';
import 'trait_scoring_config.dart';
import 'trait_scoring_validation_exception.dart';

class CanonicalProfileAssembly {
  final Map<String, double> dimensionScores;
  final Map<String, int> dimensionEvidenceCounts;
  final Map<String, double> dimensionEvidenceSufficiency;
  final Map<String, double> dimensionReliability;
  final Set<String> missingDimensions;
  final Map<String, String> assessmentStatuses;
  final ResponseValidityStatus responseValidityStatus;
  final String dimensionRegistryVersion;
  final String traitScoringVersion;
  final String rviVersion;
  final bool readyForPersona;
  final List<String> reasonCodes;
  final Map<String, ModuleTraitResult> modules;

  const CanonicalProfileAssembly({
    required this.dimensionScores,
    required this.dimensionEvidenceCounts,
    required this.dimensionEvidenceSufficiency,
    required this.dimensionReliability,
    required this.missingDimensions,
    required this.assessmentStatuses,
    required this.responseValidityStatus,
    required this.dimensionRegistryVersion,
    required this.traitScoringVersion,
    required this.rviVersion,
    required this.readyForPersona,
    required this.reasonCodes,
    required this.modules,
  });

  /// Convert to PersonaScoringInput using explicit evidence sufficiency.
  PersonaScoringInput toPersonaScoringInput({
    required String personaProfileVersion,
    required String personaScoringVersion,
  }) {
    return PersonaScoringInput(
      dimensionScores: Map<String, double>.from(dimensionScores),
      dimensionEvidenceCounts: Map<String, int>.from(dimensionEvidenceCounts),
      dimensionEvidenceSufficiency:
          Map<String, double>.from(dimensionEvidenceSufficiency),
      dimensionReliability: Map<String, double>.from(dimensionReliability),
      missingDimensions: Set<String>.from(missingDimensions),
      assessmentStatuses: Map<String, String>.from(assessmentStatuses),
      responseValidityStatus: responseValidityStatus,
      dimensionRegistryVersion: dimensionRegistryVersion,
      personaProfileVersion: personaProfileVersion,
      personaScoringVersion: personaScoringVersion,
      evidenceSufficiencyMode: PersonaEvidenceSufficiencyMode.explicit,
    );
  }
}

class CanonicalProfileAssembler {
  final TraitScoringConfig config;

  const CanonicalProfileAssembler({required this.config});

  CanonicalProfileAssembly assemble({
    ModuleTraitResult? iq,
    ModuleTraitResult? eq,
    ModuleTraitResult? frequency,
  }) {
    final errors = <TraitValidationError>[];
    final modules = <String, ModuleTraitResult>{};
    void add(ModuleTraitResult? m) {
      if (m == null) return;
      if (m.traitScoringVersion != config.traitScoringVersion) {
        errors.add(TraitValidationError(
          fieldPath: 'traitScoringVersion',
          reasonCode: 'version_mismatch',
          explanation: '${m.assessmentType} ${m.traitScoringVersion}',
        ));
      }
      if (modules.containsKey(m.assessmentType)) {
        errors.add(TraitValidationError(
          fieldPath: 'modules',
          reasonCode: 'duplicate_module',
          explanation: m.assessmentType,
        ));
      }
      modules[m.assessmentType] = m;
    }

    add(iq);
    add(eq);
    add(frequency);
    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Assembly failed', errors);
    }

    final scores = <String, double>{};
    final evidence = <String, int>{};
    final sufficiency = <String, double>{};
    final reliability = <String, double>{};
    final missing = <String>{};
    final reasons = <String>[];
    final statuses = <String, String>{};

    for (final d in PersonaDimensionIds.all) {
      final req = config.requireDimension(d);
      final mod = modules[req.module];
      if (mod == null) {
        missing.add(d);
        sufficiency[d] = 0;
        reliability[d] = 0;
        reasons.add('missing_module_${req.module}');
        continue;
      }
      statuses[req.module] = mod.status.name;
      if (mod.dimensionScores.containsKey(d)) {
        if (scores.containsKey(d)) {
          throw TraitScoringValidationException('dimension collision', [
            TraitValidationError(
              fieldPath: d,
              reasonCode: 'duplicate_dimension',
              explanation: 'Dimension appeared twice',
            ),
          ]);
        }
        scores[d] = mod.dimensionScores[d]!;
        evidence[d] = (mod.dimensionEvidenceCounts[d] ?? 0).round();
        sufficiency[d] = mod.dimensionEvidenceSufficiency[d] ?? 0;
        reliability[d] = mod.dimensionReliability[d] ?? 0;
      } else {
        missing.add(d);
        sufficiency[d] = mod.dimensionEvidenceSufficiency[d] ?? 0;
        reliability[d] = mod.dimensionReliability[d] ?? 0;
        evidence[d] = (mod.dimensionEvidenceCounts[d] ?? 0).round();
      }
    }

    // Reject aliases / non-canonical keys
    for (final m in modules.values) {
      for (final k in m.dimensionScores.keys) {
        if (!PersonaDimensionIds.allSet.contains(k)) {
          throw TraitScoringValidationException('non-canonical dimension', [
            TraitValidationError(
              fieldPath: k,
              reasonCode: 'unknown_dimension',
              explanation: k,
            ),
          ]);
        }
      }
    }

    final rviStatuses =
        modules.values.map((m) => m.responseValidity.status).toList();
    ResponseValidityStatus rvi;
    if (rviStatuses.any((s) =>
        s == ResponseValidityStatusBand.lowValidity ||
        s == ResponseValidityStatusBand.insufficientEvidence)) {
      rvi = ResponseValidityStatus.invalid;
    } else if (rviStatuses
        .any((s) => s == ResponseValidityStatusBand.provisional)) {
      rvi = ResponseValidityStatus.suspect;
    } else if (modules.isEmpty) {
      rvi = ResponseValidityStatus.unknown;
    } else {
      rvi = ResponseValidityStatus.valid;
    }

    final freqMissing = PersonaDimensionIds.frequency.any(missing.contains);
    final eqMissing = PersonaDimensionIds.eq.any((d) {
      final req = config.requireDimension(d);
      return req.requiredForPersona && missing.contains(d);
    });
    final ready = !freqMissing &&
        !eqMissing &&
        modules.containsKey('eq') &&
        modules.containsKey('frequency') &&
        rvi != ResponseValidityStatus.invalid &&
        scores.length == 20 - missing.length;

    if (freqMissing) reasons.add('missing_frequency_prevents_persona_ready');
    if (eqMissing) reasons.add('missing_eq_prevents_persona_ready');

    return CanonicalProfileAssembly(
      dimensionScores: scores,
      dimensionEvidenceCounts: evidence,
      dimensionEvidenceSufficiency: sufficiency,
      dimensionReliability: reliability,
      missingDimensions: missing,
      assessmentStatuses: statuses,
      responseValidityStatus: rvi,
      dimensionRegistryVersion: config.dimensionRegistryVersion,
      traitScoringVersion: config.traitScoringVersion,
      rviVersion: config.rviVersion,
      readyForPersona: ready && missing.isEmpty,
      reasonCodes: reasons.toSet().toList()..sort(),
      modules: modules,
    );
  }
}
