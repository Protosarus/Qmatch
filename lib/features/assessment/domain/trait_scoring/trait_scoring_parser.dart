import 'dart:convert';

import '../persona_scoring/persona_dimension_profile.dart';
import 'assessment_item_definition.dart';
import 'trait_scoring_config.dart';
import 'trait_scoring_validation_exception.dart';

class TraitScoringParser {
  TraitScoringParser._();

  static final _personaIds = {
    'uygulayici',
    'koruyucu',
    'bilge',
    'lider',
    'muhafiz',
    'sifaci',
    'yargic',
    'empat',
    'cesur',
    'kararli',
    'vizyoner',
    'yaratici',
    'iletisimci',
    'analist',
    'donusturucu',
    'bagimsiz',
    'sezgisel',
    'stratejist',
  };

  static TraitScoringConfig parseConfigJson(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw TraitScoringValidationException('Config root must be object');
    }
    return parseConfigMap(Map<String, dynamic>.from(decoded));
  }

  static TraitScoringConfig parseConfigMap(Map<String, dynamic> j) {
    final errors = <TraitValidationError>[];
    void need(String k) {
      if (!j.containsKey(k)) {
        errors.add(TraitValidationError(
          fieldPath: k,
          reasonCode: 'missing_config_key',
          explanation: 'Missing required config key $k',
        ));
      }
    }

    for (final k in [
      'schema_version',
      'config_version',
      'status',
      'dimension_registry_version',
      'question_schema_version',
      'trait_scoring_version',
      'rvi_version',
      'dimension_requirements',
      'reliability_weights',
      'rvi_weights',
    ]) {
      need(k);
    }
    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Invalid config', errors);
    }

    final dimsRaw =
        Map<String, dynamic>.from(j['dimension_requirements'] as Map);
    final keySet = dimsRaw.keys.toSet();
    // Avoid Set== between LinkedHashSet and const Set (can be false with equal
    // contents on some SDK builds); use length + containsAll instead.
    if (keySet.length != PersonaDimensionIds.allSet.length ||
        !PersonaDimensionIds.allSet.containsAll(keySet) ||
        !keySet.containsAll(PersonaDimensionIds.allSet)) {
      errors.add(TraitValidationError(
        fieldPath: 'dimension_requirements',
        reasonCode: 'dimension_set_mismatch',
        explanation: 'Must define exactly the 20 canonical dimensions',
      ));
    }

    final dims = <String, DimensionRequirement>{};
    for (final e in dimsRaw.entries) {
      final id = e.key;
      if (!PersonaDimensionIds.allSet.contains(id)) {
        errors.add(TraitValidationError(
          fieldPath: 'dimension_requirements.$id',
          reasonCode: 'unknown_dimension',
          explanation: 'Unknown dimension $id',
        ));
        continue;
      }
      if (PersonaDimensionIds.forbiddenAliases.contains(id)) {
        errors.add(TraitValidationError(
          fieldPath: 'dimension_requirements.$id',
          reasonCode: 'retired_alias',
          explanation: 'Retired alias not allowed: $id',
        ));
      }
      final m = Map<String, dynamic>.from(e.value as Map);
      dims[id] = DimensionRequirement(
        module: m['module'] as String,
        minimumPrimaryEvidence:
            (m['minimum_primary_evidence'] as num).toDouble(),
        minimumTotalEvidence: (m['minimum_total_evidence'] as num).toDouble(),
        targetPrimaryEvidence: (m['target_primary_evidence'] as num).toDouble(),
        targetTotalEvidence: (m['target_total_evidence'] as num).toDouble(),
        maximumSingleItemInfluence:
            (m['maximum_single_item_influence'] as num).toDouble(),
        minimumIndependentContexts:
            (m['minimum_independent_contexts'] as num).toDouble(),
        minimumReliability: (m['minimum_reliability'] as num).toDouble(),
        requiredForProfileReadiness:
            m['required_for_profile_readiness'] == true,
        requiredForPersona: m['required_for_persona'] == true,
      );
    }

    final rel = Map<String, dynamic>.from(j['reliability_weights'] as Map);
    final rvi = Map<String, dynamic>.from(j['rvi_weights'] as Map);
    final independence =
        Map<String, dynamic>.from(j['independence'] as Map? ?? {});
    final iq = Map<String, dynamic>.from(j['iq_scoring'] as Map? ?? {});
    final beh =
        Map<String, dynamic>.from(j['behavioral_scoring'] as Map? ?? {});

    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Invalid config', errors);
    }

    return TraitScoringConfig(
      schemaVersion: j['schema_version'] as String,
      configVersion: j['config_version'] as String,
      status: j['status'] as String,
      dimensionRegistryVersion: j['dimension_registry_version'] as String,
      questionSchemaVersion: j['question_schema_version'] as String,
      traitScoringVersion: j['trait_scoring_version'] as String,
      rviVersion: j['rvi_version'] as String,
      dimensionRequirements: Map.unmodifiable(dims),
      reliabilityWeights: {
        for (final e in rel.entries)
          if (e.value is num) e.key: (e.value as num).toDouble(),
      },
      rviWeights: {
        for (final e in rvi.entries)
          if (e.value is num) e.key: (e.value as num).toDouble(),
      },
      renormalizeReliabilityOverAvailable:
          rel['renormalize_over_available_only'] == true,
      renormalizeRviOverAvailable:
          rvi['renormalize_over_available_only'] == true,
      sameContextDiminishingFactor:
          (independence['same_context_diminishing_factor'] as num?)
                  ?.toDouble() ??
              0.5,
      defaultIqItemWeight:
          (iq['default_item_weight'] as num?)?.toDouble() ?? 1.0,
      enableCalibratedIqItemWeights:
          iq['enable_calibrated_item_weights'] == true,
      maxAbsPrimaryDelta:
          (beh['max_abs_primary_delta'] as num?)?.toDouble() ?? 0.85,
      maxDimsPerOption: (beh['max_dims_per_option'] as num?)?.toInt() ?? 3,
      maxL1DeltaMagnitude:
          (beh['max_l1_delta_magnitude'] as num?)?.toDouble() ?? 1.6,
    );
  }

  static List<AssessmentItemDefinition> parseItemBank(
    List<dynamic> items, {
    required String expectedModule,
    String? source,
    required TraitScoringConfig config,
  }) {
    final errors = <TraitValidationError>[];
    final seenQ = <String>{};
    final out = <AssessmentItemDefinition>[];

    for (final raw in items) {
      final j = Map<String, dynamic>.from(raw as Map);
      final qid = j['question_id']?.toString() ?? '';
      void err(String path, String code, String expl) {
        errors.add(TraitValidationError(
          source: source,
          questionId: qid.isEmpty ? null : qid,
          fieldPath: path,
          reasonCode: code,
          explanation: expl,
        ));
      }

      if (qid.isEmpty || !seenQ.add(qid)) {
        err('question_id', 'duplicate_or_missing_question_id',
            'Question id missing or duplicate');
        continue;
      }

      final module = j['module']?.toString() ?? '';
      if (module != expectedModule) {
        err('module', 'module_mismatch', 'Expected $expectedModule');
      }
      if (j['schema_version'] != 'qmatch_question_schema_v3') {
        err('schema_version', 'invalid_schema_version',
            'Must be qmatch_question_schema_v3');
      }

      final primary = j['primary_dimension']?.toString() ?? '';
      if (!PersonaDimensionIds.allSet.contains(primary)) {
        err('primary_dimension', 'unknown_dimension', primary);
      } else if (PersonaDimensionIds.forbiddenAliases.contains(primary) ||
          PersonaDimensionIds.forbiddenLegacyGridIds.contains(primary)) {
        err('primary_dimension', 'retired_or_forbidden_id', primary);
      } else {
        final g = PersonaDimensionIds.groupOf(primary);
        final expectedGroup = module == 'iq'
            ? 'iq'
            : module == 'eq'
                ? 'eq'
                : 'frequency';
        if (g != expectedGroup) {
          err('primary_dimension', 'dimension_module_mismatch',
              '$primary not in $module');
        }
      }

      final secondaries = List<String>.from(
        (j['secondary_dimensions'] as List?) ?? const [],
      );
      for (final s in secondaries) {
        if (!PersonaDimensionIds.allSet.contains(s)) {
          err('secondary_dimensions', 'unknown_dimension', s);
        }
      }

      if (module != 'iq') {
        if (j.containsKey('correct_option_id') ||
            j.containsKey('correctAnswer') ||
            j['correct'] == true) {
          err('correct', 'eq_frequency_correct_forbidden',
              'EQ/Frequency must not use correct-answer fields');
        }
      }

      final separators =
          List<String>.from((j['separator_targets'] as List?) ?? const []);
      for (final p in separators) {
        if (!_personaIds.contains(p)) {
          err('separator_targets', 'invalid_persona_id', p);
        }
      }

      final options = <AssessmentOptionDefinition>[];
      final seenOpt = <String>{};
      final rawOpts = (j['options'] as List?) ?? const [];
      for (final oRaw in rawOpts) {
        final o = Map<String, dynamic>.from(oRaw as Map);
        final oid = o['option_id']?.toString() ?? '';
        if (oid.isEmpty || !seenOpt.add(oid)) {
          err('options.option_id', 'duplicate_or_missing_option_id', oid);
          continue;
        }
        if (o.containsKey('correct') ||
            o.containsKey('correctAnswer') ||
            o.containsKey('persona_id') ||
            o.containsKey('persona_points')) {
          if (module != 'iq' || o.containsKey('persona_id')) {
            err('options', 'forbidden_option_field', oid);
          }
        }
        final deltas = <String, double>{};
        if (module != 'iq') {
          final dRaw = Map<String, dynamic>.from(
            o['dimension_deltas'] as Map? ?? {},
          );
          var l1 = 0.0;
          var nonzero = 0;
          for (final de in dRaw.entries) {
            if (!PersonaDimensionIds.allSet.contains(de.key)) {
              err('dimension_deltas', 'unknown_dimension', de.key);
              continue;
            }
            final v = (de.value as num).toDouble();
            if (v < -1 || v > 1) {
              err('dimension_deltas.${de.key}', 'delta_out_of_range', '$v');
            }
            if (v.abs() > 1e-12) nonzero++;
            l1 += v.abs();
            deltas[de.key] = v;
          }
          if (nonzero > config.maxDimsPerOption) {
            err('dimension_deltas', 'too_many_dimensions', oid);
          }
          if (l1 > config.maxL1DeltaMagnitude + 1e-9) {
            err('dimension_deltas', 'excessive_l1_magnitude', oid);
          }
          final primaryDelta = (deltas[primary] ?? 0).abs();
          if (primaryDelta > config.maxAbsPrimaryDelta + 1e-9) {
            err('dimension_deltas.$primary', 'excessive_primary_delta', oid);
          }
        }
        options.add(
          AssessmentOptionDefinition(
            optionId: oid,
            localizedText: {
              for (final e in Map<String, dynamic>.from(
                o['localized_text'] as Map? ?? {},
              ).entries)
                e.key: e.value.toString(),
            },
            dimensionDeltas: deltas,
            evidenceStrength:
                (o['evidence_strength'] as num?)?.toDouble() ?? 1.0,
            socialDesirabilityRisk:
                o['social_desirability_risk']?.toString() ?? 'low',
            extremity: (o['extremity'] as num?)?.toDouble() ?? 0.0,
            responseStyleRisk: o['response_style_risk']?.toString() ?? 'low',
            status: o['status']?.toString() ?? 'active',
            isCorrect: module == 'iq' &&
                oid == (j['correct_option_id']?.toString() ?? ''),
          ),
        );
      }

      if (module == 'iq') {
        final cid = j['correct_option_id']?.toString();
        if (cid == null || !seenOpt.contains(cid)) {
          err('correct_option_id', 'invalid_correct_option', '$cid');
        }
        if (options.length < 2) {
          err('options', 'insufficient_options', 'IQ needs options');
        }
      }

      final prompt = Map<String, String>.from(
        Map<String, dynamic>.from(j['prompt'] as Map? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
      if (!prompt.containsKey('tr') || !prompt.containsKey('en')) {
        err('prompt', 'missing_locale_prompt', 'tr/en required');
      }

      out.add(
        AssessmentItemDefinition(
          questionId: qid,
          module: module,
          schemaVersion: j['schema_version']?.toString() ?? '',
          contentVersion: j['content_version']?.toString() ?? '',
          itemType: j['item_type']?.toString() ?? 'scenario_mcq',
          primaryDimension: primary,
          secondaryDimensions: secondaries,
          prompt: prompt,
          options: options,
          correctOptionId: j['correct_option_id']?.toString(),
          solutionMethod: j['solution_method']?.toString(),
          difficulty: (j['difficulty'] as num?)?.toInt(),
          anchorGroup: j['anchor_group']?.toString(),
          semanticPairId: j['semantic_pair_id']?.toString(),
          reversePairId: j['reverse_pair_id']?.toString(),
          behavioralIsomorphGroup: j['behavioral_isomorph_group']?.toString(),
          separatorTargets: separators,
          responseValidityRoles: List<String>.from(
            (j['response_validity_roles'] as List?) ?? const [],
          ),
          exposureClass: j['exposure_class']?.toString() ?? 'core_pool',
          securityLevel: j['security_level']?.toString() ?? 'standard',
          estimatedCompletionSeconds:
              (j['estimated_completion_seconds'] as num?)?.toDouble() ?? 20,
          reverseScoredLikert: j['likert_scale'] is Map &&
              (j['likert_scale'] as Map)['reverse_scored'] == true,
          scalePointDeltas: j['likert_scale'] is Map &&
                  (j['likert_scale'] as Map)['scale_point_deltas'] is Map
              ? {
                  for (final e in Map<String, dynamic>.from(
                    (j['likert_scale'] as Map)['scale_point_deltas'] as Map,
                  ).entries)
                    e.key: {
                      for (final d
                          in Map<String, dynamic>.from(e.value as Map).entries)
                        d.key: (d.value as num).toDouble(),
                    },
                }
              : null,
        ),
      );
    }

    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Invalid item bank', errors);
    }
    return out;
  }
}
