// Deterministic synthetic CompatibilitySubjectSnapshot families.
// CLI/test-only. Artificial identifiers only. No real demographics.

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

import '../../../test/support/directional_preference_fit_helpers.dart';
import '../../../test/support/relationship_value_layer_helpers.dart';
import '../../../test/support/structural_similarity_helpers.dart';
import 'robustness_rng.dart';

class SyntheticSubject {
  final CompatibilitySubjectSnapshot snapshot;
  final String familyId;
  final String opaqueCohortLabel;
  final Map<String, dynamic> generationMeta;

  SyntheticSubject({
    required this.snapshot,
    required this.familyId,
    required this.opaqueCohortLabel,
    required this.generationMeta,
  });

  String get subjectId => snapshot.subjectId;
}

class SyntheticPopulation {
  final String familyId;
  final int seed;
  final List<SyntheticSubject> subjects;

  SyntheticPopulation({
    required this.familyId,
    required this.seed,
    required this.subjects,
  });

  int get size => subjects.length;
}

/// All declared synthetic profile families (Task 3).
const kSyntheticFamilyIds = <String>[
  'independent_uniform',
  'central_normal_like_bounded',
  'two_cluster',
  'three_cluster',
  'positively_correlated_dimensions',
  'negatively_correlated_dimensions',
  'correlated_within_modules',
  'independent_between_modules',
  'frequency_preference_correlated',
  'frequency_preference_independent',
  'values_preference_correlated',
  'values_preference_independent',
  'high_confidence_population',
  'mixed_confidence_population',
  'low_confidence_population',
  'complete_profiles',
  'random_partial_profiles',
  'structured_missing_modules',
  'structured_missing_dimensions',
  'narrow_score_range',
  'wide_score_range',
  'boundary_heavy',
  'hard_constraint_sparse',
  'hard_constraint_dense',
  'soft_conflict_sparse',
  'soft_conflict_dense',
];

class CoreMethodV2SyntheticGenerator {
  final CanonicalDimensionRegistry dimRegistry;
  final RelationshipValueRegistry valueRegistry;

  CoreMethodV2SyntheticGenerator({
    required this.dimRegistry,
    required this.valueRegistry,
  });

  SyntheticPopulation generateFamily({
    required String familyId,
    required int seed,
    required int count,
    String opaqueCohortLabel = 'cohort_alpha',
  }) {
    if (!kSyntheticFamilyIds.contains(familyId)) {
      throw ArgumentError('unknown synthetic family: $familyId');
    }
    final rng = RobustnessRng(seed ^ familyId.hashCode);
    final subjects = <SyntheticSubject>[];
    for (var i = 0; i < count; i++) {
      subjects.add(
        _generateOne(
          familyId: familyId,
          index: i,
          seed: seed,
          rng: rng,
          opaqueCohortLabel: opaqueCohortLabel,
        ),
      );
    }
    return SyntheticPopulation(
      familyId: familyId,
      seed: seed,
      subjects: subjects,
    );
  }

  SyntheticSubject _generateOne({
    required String familyId,
    required int index,
    required int seed,
    required RobustnessRng rng,
    required String opaqueCohortLabel,
  }) {
    final id = 'syn_${familyId}_${seed.toRadixString(16)}_$index';
    if (_looksLikeRealUserData(id)) {
      throw StateError('synthetic id rejected: $id');
    }

    final latent = _latentForFamily(familyId, index, rng);
    final confidence = _confidenceForFamily(familyId, rng);
    final assessment = _buildAssessment(
      familyId: familyId,
      latent: latent,
      confidence: confidence,
      rng: rng,
      index: index,
    );
    final prefs = _buildPreferences(
      familyId: familyId,
      assessment: assessment,
      latent: latent,
      rng: rng,
    );
    final values = _buildValues(
      familyId: familyId,
      latent: latent,
      rng: rng,
    );
    final constraints = _buildConstraints(
      familyId: familyId,
      values: values,
      rng: rng,
      index: index,
    );

    final snap = CompatibilitySubjectSnapshot(
      subjectId: id,
      assessmentProfile: assessment,
      partnerPreferenceProfile: prefs,
      relationshipValueProfile: values,
      hardConstraints: constraints,
      snapshotVersion: 'synthetic_v1',
      createdAt: DateTime.utc(2026, 7, 24),
    );

    return SyntheticSubject(
      snapshot: snap,
      familyId: familyId,
      opaqueCohortLabel: opaqueCohortLabel,
      generationMeta: {
        'family_id': familyId,
        'seed': seed,
        'index': index,
        'opaque_cohort_label': opaqueCohortLabel,
        'latent': latent,
        'note': 'artificial_engineering_profile_only',
      },
    );
  }

  bool _looksLikeRealUserData(String id) {
    final lower = id.toLowerCase();
    return lower.contains('@') ||
        lower.contains('gmail') ||
        lower.contains('phone') ||
        RegExp(r'\b\d{10,}\b').hasMatch(lower);
  }

  double _latentForFamily(String familyId, int index, RobustnessRng rng) {
    switch (familyId) {
      case 'two_cluster':
        return index.isEven ? 0.25 : 0.75;
      case 'three_cluster':
        return [0.2, 0.5, 0.8][index % 3];
      case 'narrow_score_range':
        return 0.48 + rng.nextBounded(0, 0.04);
      case 'wide_score_range':
      case 'boundary_heavy':
        return rng.nextBool(0.5)
            ? rng.nextBounded(0, 0.08)
            : rng.nextBounded(0.92, 1.0);
      case 'central_normal_like_bounded':
        // Box-Muller-ish via sum of uniforms, clamped.
        var s = 0.0;
        for (var i = 0; i < 6; i++) {
          s += rng.nextDouble();
        }
        return ((s / 6.0 - 0.5) * 0.6 + 0.5).clamp(0.0, 1.0);
      default:
        return rng.nextDouble();
    }
  }

  double _confidenceForFamily(String familyId, RobustnessRng rng) {
    switch (familyId) {
      case 'high_confidence_population':
        return rng.nextBounded(0.85, 1.0);
      case 'low_confidence_population':
        return rng.nextBounded(0.15, 0.40);
      case 'mixed_confidence_population':
        return rng.nextBounded(0.2, 0.95);
      default:
        return rng.nextBounded(0.55, 0.95);
    }
  }

  CanonicalUserAssessmentProfile _buildAssessment({
    required String familyId,
    required double latent,
    required double confidence,
    required RobustnessRng rng,
    required int index,
  }) {
    ModuleAssessmentProfile? iq;
    ModuleAssessmentProfile? eq;
    ModuleAssessmentProfile? freq;

    Map<String, double> scoresFor(AssessmentModuleId module) {
      final dims = dimRegistry.dimsForModule(module);
      final out = <String, double>{};
      var dimIndex = 0;
      for (final d in dims) {
        var score = latent;
        switch (familyId) {
          case 'independent_uniform':
          case 'complete_profiles':
          case 'high_confidence_population':
          case 'low_confidence_population':
          case 'mixed_confidence_population':
          case 'hard_constraint_sparse':
          case 'hard_constraint_dense':
          case 'soft_conflict_sparse':
          case 'soft_conflict_dense':
            score = rng.nextDouble();
            break;
          case 'positively_correlated_dimensions':
            score = (latent + rng.nextBounded(-0.05, 0.05)).clamp(0.0, 1.0);
            break;
          case 'negatively_correlated_dimensions':
            score = dimIndex.isEven
                ? (latent + rng.nextBounded(-0.05, 0.05)).clamp(0.0, 1.0)
                : ((1.0 - latent) + rng.nextBounded(-0.05, 0.05))
                    .clamp(0.0, 1.0);
            break;
          case 'correlated_within_modules':
            final moduleOffset = switch (module) {
              AssessmentModuleId.iq => 0.0,
              AssessmentModuleId.eq => 0.07,
              AssessmentModuleId.frequency => 0.14,
            };
            final moduleLatent = latent + moduleOffset;
            score = ((moduleLatent % 1.0) + rng.nextBounded(-0.04, 0.04))
                .clamp(0.0, 1.0);
            break;
          case 'independent_between_modules':
            score = rng.nextDouble();
            break;
          case 'narrow_score_range':
            score = (0.48 + rng.nextBounded(0, 0.04)).clamp(0.0, 1.0);
            break;
          case 'wide_score_range':
          case 'boundary_heavy':
            score = rng.nextBool()
                ? rng.nextBounded(0.0, 0.1)
                : rng.nextBounded(0.9, 1.0);
            break;
          case 'two_cluster':
          case 'three_cluster':
          case 'central_normal_like_bounded':
            score = (latent + rng.nextBounded(-0.08, 0.08)).clamp(0.0, 1.0);
            break;
          case 'frequency_preference_correlated':
          case 'frequency_preference_independent':
          case 'values_preference_correlated':
          case 'values_preference_independent':
            score = (latent + rng.nextBounded(-0.1, 0.1)).clamp(0.0, 1.0);
            break;
          case 'random_partial_profiles':
          case 'structured_missing_modules':
          case 'structured_missing_dimensions':
            score = rng.nextDouble();
            break;
          default:
            score = rng.nextDouble();
        }
        out[d.dimensionId] = score;
        dimIndex++;
      }
      return out;
    }

    ModuleAssessmentProfile buildMod(
      AssessmentModuleId module, {
      bool include = true,
      double keepRate = 1.0,
    }) {
      if (!include) {
        return buildModuleProfile(
          module: module,
          registry: dimRegistry,
          measurements: {},
          completion: ModuleCompletionStatus.unavailable,
        );
      }
      final scores = scoresFor(module);
      final measurements = <String, DimensionMeasurement>{};
      for (final e in scores.entries) {
        if (keepRate < 1.0 && rng.nextDouble() > keepRate) continue;
        var conf = confidence;
        if (familyId == 'mixed_confidence_population') {
          conf = rng.nextBounded(0.2, 0.95);
        }
        measurements[e.key] = ssPublished(
          dimensionId: e.key,
          module: module,
          score: e.value,
          confidence: conf,
          registryVersion: dimRegistry.registryVersion,
        );
      }
      return buildModuleProfile(
        module: module,
        registry: dimRegistry,
        measurements: measurements,
      );
    }

    switch (familyId) {
      case 'structured_missing_modules':
        final drop = index % 3;
        iq = buildMod(AssessmentModuleId.iq, include: drop != 0);
        eq = buildMod(AssessmentModuleId.eq, include: drop != 1);
        freq = buildMod(AssessmentModuleId.frequency, include: drop != 2);
        break;
      case 'structured_missing_dimensions':
      case 'random_partial_profiles':
        iq = buildMod(AssessmentModuleId.iq, keepRate: 0.6);
        eq = buildMod(AssessmentModuleId.eq, keepRate: 0.6);
        freq = buildMod(AssessmentModuleId.frequency, keepRate: 0.6);
        break;
      case 'independent_between_modules':
        // Independent module latents via separate RNG draws already.
        iq = buildMod(AssessmentModuleId.iq);
        eq = buildMod(AssessmentModuleId.eq);
        freq = buildMod(AssessmentModuleId.frequency);
        break;
      default:
        iq = buildMod(AssessmentModuleId.iq);
        eq = buildMod(AssessmentModuleId.eq);
        freq = buildMod(AssessmentModuleId.frequency);
    }

    final profile = buildUserProfile(
      registry: dimRegistry,
      iq: iq,
      eq: eq,
      frequency: freq,
    );
    return CanonicalUserAssessmentProfile(
      snapshotId: 'syn_assess_$index',
      profileSchemaVersion: profile.profileSchemaVersion,
      registryVersion: profile.registryVersion,
      iq: profile.iq,
      eq: profile.eq,
      frequency: profile.frequency,
      publishedMeasurements: profile.publishedMeasurements,
      unavailableDimensions: profile.unavailableDimensions,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      sourceAssessmentVersions: const ['synthetic_offline_v1'],
      overallAssessmentCoverage: profile.overallAssessmentCoverage,
      profileReadinessStatus: profile.profileReadinessStatus,
    );
  }

  PartnerPreferenceProfile _buildPreferences({
    required String familyId,
    required CanonicalUserAssessmentProfile assessment,
    required double latent,
    required RobustnessRng rng,
  }) {
    final prefs = <String, PartnerDimensionPreference>{};
    final allDims = [
      ...dimRegistry.dimsForModule(AssessmentModuleId.iq),
      ...dimRegistry.dimsForModule(AssessmentModuleId.eq),
      ...dimRegistry.dimsForModule(AssessmentModuleId.frequency),
    ];

    for (final d in allDims) {
      final isFreq = d.module == AssessmentModuleId.frequency;
      final useSimilarity =
          (familyId == 'frequency_preference_correlated' && isFreq) ||
              (familyId == 'values_preference_correlated' &&
                  !isFreq &&
                  rng.nextBool(0.3)) ||
              (familyId.contains('preference') && rng.nextBool(0.25));

      if (familyId == 'frequency_preference_independent' && isFreq) {
        final center = rng.nextDouble();
        prefs[d.dimensionId] = rangePref(
          dimensionId: d.dimensionId,
          min: (center - 0.15).clamp(0.0, 1.0),
          max: (center + 0.15).clamp(0.0, 1.0),
          flexibility: rng.nextBounded(0.3, 0.8),
        );
        continue;
      }

      if (useSimilarity ||
          (familyId == 'frequency_preference_correlated' && isFreq)) {
        prefs[d.dimensionId] = similarityPref(
          dimensionId: d.dimensionId,
          flexibility: rng.nextBounded(0.3, 0.8),
        );
        continue;
      }

      if (rng.nextBool(0.15)) {
        prefs[d.dimensionId] = openPref(d.dimensionId);
        continue;
      }

      final center = familyId.startsWith('frequency_preference') && isFreq
          ? (assessment.publishedMeasurements[d.dimensionId]?.normalizedScore ??
              latent)
          : (latent + rng.nextBounded(-0.2, 0.2)).clamp(0.0, 1.0);
      prefs[d.dimensionId] = rangePref(
        dimensionId: d.dimensionId,
        min: (center - 0.2).clamp(0.0, 1.0),
        max: (center + 0.2).clamp(0.0, 1.0),
        flexibility: rng.nextBounded(0.2, 0.9),
      );
    }

    return prefsProfile(registry: dimRegistry, preferences: prefs);
  }

  RelationshipValueProfile _buildValues({
    required String familyId,
    required double latent,
    required RobustnessRng rng,
  }) {
    final responses = <String, RelationshipValueResponse>{};
    final fields = valueRegistry.fields;
    for (final f in fields) {
      final allowed = f.allowedValues;
      if (allowed.isEmpty) continue;

      String selected;
      if (familyId == 'soft_conflict_dense' ||
          familyId == 'values_preference_correlated') {
        // Bias toward a consistent bucket for denser soft conflicts.
        selected = allowed[
            (latent * allowed.length).floor().clamp(0, allowed.length - 1)];
      } else if (familyId == 'soft_conflict_sparse') {
        selected = allowed.first;
      } else {
        selected = rng.choose(allowed);
      }

      var importance = rng.nextBounded(0.4, 1.0);
      var flexibility = rng.nextBounded(0.2, 0.8);
      if (familyId == 'soft_conflict_dense') {
        importance = rng.nextBounded(0.8, 1.0);
        flexibility = rng.nextBounded(0.05, 0.25);
      }
      if (familyId == 'soft_conflict_sparse') {
        importance = rng.nextBounded(0.2, 0.5);
        flexibility = rng.nextBounded(0.6, 0.95);
      }

      responses[f.fieldId] = valueResponse(
        fieldId: f.fieldId,
        registry: valueRegistry,
        selectedValue: selected,
        importance: importance,
        flexibility: flexibility,
      );
    }
    return valueProfile(registry: valueRegistry, responses: responses);
  }

  List<HardConstraint> _buildConstraints({
    required String familyId,
    required RelationshipValueProfile values,
    required RobustnessRng rng,
    required int index,
  }) {
    if (familyId == 'hard_constraint_sparse' && index % 5 != 0) {
      return const [];
    }
    if (familyId != 'hard_constraint_sparse' &&
        familyId != 'hard_constraint_dense' &&
        !rng.nextBool(0.08)) {
      return const [];
    }

    final fields =
        valueRegistry.fields.where((f) => f.allowedValues.isNotEmpty).toList();
    if (fields.isEmpty) return const [];

    final count = familyId == 'hard_constraint_dense' ? 1 + rng.nextInt(3) : 1;
    final out = <HardConstraint>[];
    for (var i = 0; i < count; i++) {
      final f = fields[rng.nextInt(fields.length)];
      final accepted = <String>[rng.choose(f.allowedValues)];
      // Sometimes accept self value to increase pass rate.
      final self = values.responses[f.fieldId]?.selectedValue;
      if (self != null && rng.nextBool(0.6) && !accepted.contains(self)) {
        accepted.add(self);
      }
      out.add(
        hardConstraint(
          id: 'hc_${f.fieldId}_$i',
          fieldId: f.fieldId,
          registry: valueRegistry,
          accepted: accepted..sort(),
          enabled: true,
        ),
      );
    }
    return out;
  }
}
