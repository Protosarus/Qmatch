import 'dart:convert';

import 'persona_dimension_profile.dart';
import 'persona_prototype.dart';
import 'persona_scoring_config.dart';

/// Explicit validation failure — never silent repair.
class PersonaScoringParseException implements Exception {
  final String message;
  final List<String> errors;

  PersonaScoringParseException(this.message, [this.errors = const []]);

  @override
  String toString() => 'PersonaScoringParseException: $message'
      '${errors.isEmpty ? '' : ' | ${errors.join('; ')}'}';
}

class PersonaScoringParsers {
  PersonaScoringParsers._();

  static const _requiredPolicy =
      'lowest_tie_break_rank_then_lexicographic_persona_id';

  static PersonaScoringConfig parseConfigJson(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw PersonaScoringParseException('Config root must be an object');
    }
    return parseConfigMap(Map<String, dynamic>.from(decoded));
  }

  static PersonaProfileCatalog parseProfilesJson(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) {
      throw PersonaScoringParseException('Profiles root must be an object');
    }
    return parseProfilesMap(Map<String, dynamic>.from(decoded));
  }

  static PersonaScoringConfig parseConfigMap(Map<String, dynamic> j) {
    final errors = <String>[];

    void req(String k) {
      if (!j.containsKey(k)) errors.add('config missing key: $k');
    }

    for (final k in [
      'config_version',
      'status',
      'persona_profile_version',
      'dimension_registry_version',
      'group_weights',
      'level_distance_weight',
      'shape_distance_weight',
      'anti_trait_penalty_weight',
      'missing_evidence_penalty_weight',
      'similarity_temperature',
      'top2_margin_threshold',
      'low_confidence_threshold',
      'minimum_group_coverage',
      'minimum_total_coverage',
      'deterministic_tie_break_policy',
      'numerical_epsilon',
      'calibration_notes',
    ]) {
      req(k);
    }
    if (errors.isNotEmpty) {
      throw PersonaScoringParseException('Invalid config', errors);
    }

    final gw = Map<String, dynamic>.from(j['group_weights'] as Map);
    final iq = _asDouble(gw['iq'], 'group_weights.iq', errors);
    final eq = _asDouble(gw['eq'], 'group_weights.eq', errors);
    final freq = _asDouble(gw['frequency'], 'group_weights.frequency', errors);
    if ((iq + eq + freq - 1.0).abs() > 1e-9) {
      errors.add('group_weights must sum to 1');
    }

    final alpha =
        _asDouble(j['level_distance_weight'], 'level_distance_weight', errors);
    final beta =
        _asDouble(j['shape_distance_weight'], 'shape_distance_weight', errors);
    if ((alpha + beta - 1.0).abs() > 1e-9) {
      errors.add('level_distance_weight + shape_distance_weight must sum to 1');
    }

    final policy = j['deterministic_tie_break_policy'] as String? ?? '';
    if (policy != _requiredPolicy) {
      errors.add('unsupported deterministic_tie_break_policy: $policy');
    }

    if (j['dimension_registry_version'] != 'canonical_dimension_registry_v1') {
      errors.add('unexpected dimension_registry_version');
    }

    final minGroup = <String, double>{};
    final mg = Map<String, dynamic>.from(j['minimum_group_coverage'] as Map);
    for (final g in ['iq', 'eq', 'frequency']) {
      if (!mg.containsKey(g)) {
        errors.add('minimum_group_coverage missing $g');
      } else {
        minGroup[g] = _asDouble(mg[g], 'minimum_group_coverage.$g', errors);
      }
    }

    final notes = Map<String, Object?>.from(j['calibration_notes'] as Map);
    if (notes['similarity_scores_are_not_probabilities'] != true) {
      errors.add('config must declare similarity_scores_are_not_probabilities');
    }
    if (notes['no_persona_quota'] != true) {
      errors.add('config must declare no_persona_quota');
    }

    final allowPartial = j['allow_partial_group_renormalization'] == true;

    if (errors.isNotEmpty) {
      throw PersonaScoringParseException('Invalid config', errors);
    }

    return PersonaScoringConfig(
      configVersion: j['config_version'] as String,
      status: j['status'] as String,
      personaProfileVersion: j['persona_profile_version'] as String,
      dimensionRegistryVersion: j['dimension_registry_version'] as String,
      iqWeight: iq,
      eqWeight: eq,
      frequencyWeight: freq,
      levelDistanceWeight: alpha,
      shapeDistanceWeight: beta,
      antiTraitPenaltyWeight: _asDouble(
        j['anti_trait_penalty_weight'],
        'anti_trait_penalty_weight',
        errors,
      ),
      missingEvidencePenaltyWeight: _asDouble(
        j['missing_evidence_penalty_weight'],
        'missing_evidence_penalty_weight',
        errors,
      ),
      similarityTemperature: _asDouble(
        j['similarity_temperature'],
        'similarity_temperature',
        errors,
      ),
      top2MarginThreshold: _asDouble(
        j['top2_margin_threshold'],
        'top2_margin_threshold',
        errors,
      ),
      lowConfidenceThreshold: _asDouble(
        j['low_confidence_threshold'],
        'low_confidence_threshold',
        errors,
      ),
      minimumGroupCoverage: Map.unmodifiable(minGroup),
      minimumTotalCoverage: _asDouble(
        j['minimum_total_coverage'],
        'minimum_total_coverage',
        errors,
      ),
      adaptiveSeparatorEnabled: j['adaptive_separator_enabled'] == true,
      adaptiveSeparatorMaxQuestions:
          (j['adaptive_separator_max_questions'] as num?)?.toInt() ?? 0,
      deterministicTieBreakPolicy: policy,
      numericalEpsilon:
          _asDouble(j['numerical_epsilon'], 'numerical_epsilon', errors),
      calibrationNotes: Map.unmodifiable(notes),
      allowPartialGroupRenormalization: allowPartial,
    );
  }

  static PersonaProfileCatalog parseProfilesMap(Map<String, dynamic> j) {
    final errors = <String>[];

    for (final k in [
      'schema_version',
      'persona_profile_version',
      'dimension_registry_version',
      'status',
      'calibration_status',
      'dimension_order',
      'group_weights',
      'personas',
    ]) {
      if (!j.containsKey(k)) errors.add('profiles missing key: $k');
    }
    if (errors.isNotEmpty) {
      throw PersonaScoringParseException('Invalid profiles', errors);
    }

    if (j['dimension_registry_version'] != 'canonical_dimension_registry_v1') {
      errors.add('unexpected dimension_registry_version');
    }

    final dimOrder = List<String>.from(j['dimension_order'] as List);
    if (dimOrder.length != 20) {
      errors.add('dimension_order must have exactly 20 entries');
    }
    if (dimOrder.toSet().length != dimOrder.length) {
      errors.add('dimension_order has duplicates');
    }
    for (final d in dimOrder) {
      if (!PersonaDimensionIds.allSet.contains(d)) {
        errors.add('unknown dimension in dimension_order: $d');
      }
      if (PersonaDimensionIds.forbiddenAliases.contains(d)) {
        errors.add('forbidden alias in dimension_order: $d');
      }
    }
    for (final d in PersonaDimensionIds.all) {
      if (!dimOrder.contains(d)) {
        errors.add('missing canonical dimension: $d');
      }
    }

    final gw = Map<String, dynamic>.from(j['group_weights'] as Map);
    final gSum = ['iq', 'eq', 'frequency']
        .map((k) => _asDouble(gw[k], 'group_weights.$k', errors))
        .fold<double>(0, (a, b) => a + b);
    if ((gSum - 1.0).abs() > 1e-9) {
      errors.add('profiles group_weights must sum to 1');
    }

    final rawPersonas = j['personas'] as List;
    if (rawPersonas.length != 18) {
      errors.add('expected exactly 18 personas, got ${rawPersonas.length}');
    }

    final personas = <PersonaPrototype>[];
    final seen = <String>{};
    for (final raw in rawPersonas) {
      final p = Map<String, dynamic>.from(raw as Map);
      final id = p['persona_id'] as String? ?? '';
      if (id.isEmpty) {
        errors.add('persona missing persona_id');
        continue;
      }
      if (!seen.add(id)) {
        errors.add('duplicate persona_id: $id');
      }
      if (PersonaDimensionIds.forbiddenLegacyGridIds.contains(id) ||
          PersonaDimensionIds.forbiddenFrequencyTypes.contains(id)) {
        errors.add('forbidden persona_id: $id');
      }
      personas.add(_parsePersona(p, dimOrder, errors));
    }

    // Validate separators after all IDs known
    final ids = seen;
    for (final p in personas) {
      for (final other in p.separatorTargets.keys) {
        if (!ids.contains(other)) {
          errors.add('${p.personaId} separator references unknown $other');
        }
      }
      for (final other in p.closestCompetitors) {
        if (!ids.contains(other)) {
          errors.add('${p.personaId} competitor unknown $other');
        }
      }
    }

    if (errors.isNotEmpty) {
      throw PersonaScoringParseException('Invalid profiles', errors);
    }

    final byId = {for (final p in personas) p.personaId: p};
    return PersonaProfileCatalog(
      schemaVersion: j['schema_version'] as String,
      personaProfileVersion: j['persona_profile_version'] as String,
      dimensionRegistryVersion: j['dimension_registry_version'] as String,
      status: j['status'] as String,
      calibrationStatus: j['calibration_status'] as String,
      dimensionOrder: List.unmodifiable(dimOrder),
      groupWeights: {
        for (final e in gw.entries) e.key: (e.value as num).toDouble(),
      },
      personas: List.unmodifiable(personas),
      byId: Map.unmodifiable(byId),
    );
  }

  /// Reject mismatched versions between catalog and config.
  static void assertCompatible(
    PersonaProfileCatalog catalog,
    PersonaScoringConfig config,
  ) {
    final errors = <String>[];
    if (catalog.personaProfileVersion != config.personaProfileVersion) {
      errors.add(
        'persona_profile_version mismatch: '
        '${catalog.personaProfileVersion} vs ${config.personaProfileVersion}',
      );
    }
    if (catalog.dimensionRegistryVersion != config.dimensionRegistryVersion) {
      errors.add('dimension_registry_version mismatch');
    }
    if (errors.isNotEmpty) {
      throw PersonaScoringParseException('Incompatible versions', errors);
    }
  }

  static PersonaPrototype _parsePersona(
    Map<String, dynamic> p,
    List<String> dimOrder,
    List<String> errors,
  ) {
    final id = p['persona_id'] as String;
    final tv = Map<String, dynamic>.from(p['target_vector'] as Map);
    final dw = Map<String, dynamic>.from(p['dimension_weights'] as Map);

    final target = <String, double>{};
    final weights = <String, double>{};
    for (final d in dimOrder) {
      if (!tv.containsKey(d)) {
        errors.add('$id missing target $d');
        continue;
      }
      if (!dw.containsKey(d)) {
        errors.add('$id missing weight $d');
        continue;
      }
      final t = _asDouble(tv[d], '$id.target.$d', errors);
      final w = _asDouble(dw[d], '$id.weight.$d', errors);
      if (t < 0 || t > 1) errors.add('$id target $d out of [0,1]');
      if (w < 0) errors.add('$id weight $d negative');
      target[d] = t;
      weights[d] = w;
    }
    for (final k in tv.keys) {
      if (!dimOrder.contains(k)) {
        errors.add('$id unknown target dimension $k');
      }
    }
    for (final k in dw.keys) {
      if (!dimOrder.contains(k)) {
        errors.add('$id unknown weight dimension $k');
      }
    }

    final anti = <PersonaAntiTrait>[];
    for (final a in (p['anti_traits'] as List? ?? const [])) {
      final m = Map<String, dynamic>.from(a as Map);
      final dim = m['dimension_id'] as String? ?? '';
      if (!PersonaDimensionIds.allSet.contains(dim)) {
        errors.add('$id anti-trait unknown dim $dim');
      }
      final dir = m['direction'] as String? ?? '';
      if (dir != 'below' && dir != 'above') {
        errors.add('$id anti-trait invalid direction $dir');
      }
      anti.add(
        PersonaAntiTrait(
          dimensionId: dim,
          direction: dir,
          threshold: _asDouble(m['threshold'], '$id.anti.threshold', errors),
          severity: _asDouble(m['severity'], '$id.anti.severity', errors),
          rationale: m['rationale'] as String? ?? '',
          minimumEvidenceRequired:
              (m['minimum_evidence_required'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    final me = Map<String, dynamic>.from(p['minimum_evidence'] as Map);
    final crit = List<String>.from(me['critical_dimensions'] as List? ?? []);
    for (final d in crit) {
      if (!PersonaDimensionIds.allSet.contains(d)) {
        errors.add('$id critical dim unknown $d');
      }
    }

    final seps = <String, List<String>>{};
    final rawSep = Map<String, dynamic>.from(p['separator_targets'] as Map);
    for (final e in rawSep.entries) {
      final dims = List<String>.from(
        ((e.value as Map)['dimensions'] as List?) ?? const [],
      );
      for (final d in dims) {
        if (!PersonaDimensionIds.allSet.contains(d)) {
          errors.add('$id separator dim unknown $d');
        }
      }
      seps[e.key] = List.unmodifiable(dims);
    }

    final labels = <String, String>{
      for (final e in Map<String, dynamic>.from(p['labels'] as Map).entries)
        e.key: e.value.toString(),
    };
    final rationale = <String, String>{
      for (final e
          in Map<String, dynamic>.from(p['rationale'] as Map? ?? {}).entries)
        e.key: e.value.toString(),
    };

    return PersonaPrototype(
      personaId: id,
      labels: Map.unmodifiable(labels),
      targetVector: Map.unmodifiable(target),
      dimensionWeights: Map.unmodifiable(weights),
      primaryDimensions:
          List.unmodifiable(List<String>.from(p['primary_dimensions'] as List)),
      supportingDimensions: List.unmodifiable(
        List<String>.from(p['supporting_dimensions'] as List),
      ),
      neutralDimensions:
          List.unmodifiable(List<String>.from(p['neutral_dimensions'] as List)),
      antiTraits: List.unmodifiable(anti),
      minimumEvidence: PersonaMinimumEvidence(
        requiredGroups:
            List.unmodifiable(List<String>.from(me['required_groups'] as List)),
        minimumGroupCoverage: {
          for (final e in Map<String, dynamic>.from(
            me['minimum_group_coverage'] as Map,
          ).entries)
            e.key: (e.value as num).toDouble(),
        },
        criticalDimensions: List.unmodifiable(crit),
        minimumEvidencePerCriticalDimension:
            (me['minimum_evidence_per_critical_dimension'] as num?)?.toInt() ??
                2,
        minimumTotalCoverage: (me['minimum_total_coverage'] as num).toDouble(),
      ),
      closestCompetitors: List.unmodifiable(
        List<String>.from(p['closest_competitors'] as List),
      ),
      separatorTargets: Map.unmodifiable(seps),
      tieBreakRank: (p['tie_break_rank'] as num).toInt(),
      rationale: Map.unmodifiable(rationale),
      status: p['status'] as String? ?? 'provisional',
    );
  }

  static double _asDouble(Object? v, String path, List<String> errors) {
    if (v is num) return v.toDouble();
    errors.add('$path must be a number');
    return 0;
  }
}
