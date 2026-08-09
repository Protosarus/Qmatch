import 'dart:convert';
import 'dart:math' as math;

import 'assessment_module_id.dart';
import 'canonical_dimension_registry.dart';
import 'canonical_user_assessment_profile.dart';
import 'core_method_v2_validation.dart';
import 'dimension_measurement.dart';
import 'dimension_publication_status.dart';
import 'module_assessment_profile.dart';
import 'structural_similarity_config.dart';
import 'structural_similarity_models.dart';

/// Offline, deterministic structural-profile similarity (P2B-1).
///
/// No Firebase, UI, persona, preference, values, hard-constraint, or module
/// aggregation. Does not shrink similarity toward neutral.
class StructuralSimilarityService {
  const StructuralSimilarityService();

  StructuralProfileSimilarityResult compare({
    required CanonicalUserAssessmentProfile subjectA,
    required CanonicalUserAssessmentProfile subjectB,
    required CanonicalDimensionRegistry registry,
    required StructuralSimilarityConfig config,
    List<AssessmentModuleId>? requestedModules,
    DateTime? evaluationTimestamp,
  }) {
    _validateConfigAgainstRegistry(config, registry);

    final modules = requestedModules ??
        const [
          AssessmentModuleId.iq,
          AssessmentModuleId.eq,
          AssessmentModuleId.frequency,
        ];

    final evaluated = <String>[];
    final missing = <String>[];
    StructuralModuleSimilarityResult? iq;
    StructuralModuleSimilarityResult? eq;
    StructuralModuleSimilarityResult? frequency;

    for (final module in modules) {
      final profileA = _moduleProfile(subjectA, module);
      final profileB = _moduleProfile(subjectB, module);
      if (profileA == null || profileB == null) {
        missing.add(module.wire);
        continue;
      }
      final result = compareModule(
        module: module,
        profileA: profileA,
        profileB: profileB,
        registry: registry,
        config: config,
      );
      evaluated.add(module.wire);
      switch (module) {
        case AssessmentModuleId.iq:
          iq = result;
        case AssessmentModuleId.eq:
          eq = result;
        case AssessmentModuleId.frequency:
          frequency = result;
      }
    }

    evaluated.sort();
    missing.sort();

    final overall = _overallStatus(
      results: [iq, eq, frequency],
      missingModules: missing,
      requestedCount: modules.length,
    );

    final provisional = StructuralProfileSimilarityResult(
      iq: iq,
      eq: eq,
      frequency: frequency,
      evaluatedModules: evaluated,
      missingModules: missing,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: '',
      overallStatus: overall,
    );
    final fingerprint = _fingerprintSymmetric(provisional);
    return StructuralProfileSimilarityResult(
      iq: iq,
      eq: eq,
      frequency: frequency,
      evaluatedModules: evaluated,
      missingModules: missing,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      evaluationTimestamp: evaluationTimestamp,
      deterministicFingerprint: fingerprint,
      overallStatus: overall,
    );
  }

  StructuralModuleSimilarityResult compareModule({
    required AssessmentModuleId module,
    required ModuleAssessmentProfile profileA,
    required ModuleAssessmentProfile profileB,
    required CanonicalDimensionRegistry registry,
    required StructuralSimilarityConfig config,
  }) {
    cmRequire(profileA.module == module, 'profileA.module', 'module_mismatch',
        profileA.module.wire);
    cmRequire(profileB.module == module, 'profileB.module', 'module_mismatch',
        profileB.module.wire);

    final active = registry.dimsForModule(module);
    final similarityEnabled = [
      for (final d in active)
        if (d.supportsSimilarity) d,
    ];
    // Stable order by dimension_id (not map insertion).
    similarityEnabled.sort((a, b) => a.dimensionId.compareTo(b.dimensionId));

    final exclusions = <StructuralSimilarityExclusion>[];
    final comparisons = <StructuralDimensionComparison>[];

    var eligibleCount = 0;
    for (final def in similarityEnabled) {
      final id = def.dimensionId;
      final ma = profileA.measurements[id];
      final mb = profileB.measurements[id];

      final exclusion = _eligibilityExclusion(
        dimensionId: id,
        module: module,
        defSupportsSimilarity: def.supportsSimilarity,
        defModule: def.module,
        measurementA: ma,
        measurementB: mb,
        config: config,
        registry: registry,
      );
      if (exclusion != null) {
        exclusions.add(exclusion);
        continue;
      }
      eligibleCount++;

      final qa = ma!.confidence;
      final qb = mb!.confidence;
      final pairQ = math.sqrt(qa * qb);
      if (pairQ <= 0) {
        exclusions.add(StructuralSimilarityExclusion(
          dimensionId: id,
          reasonCode: 'zero_pair_confidence',
          explanation: 'pair confidence must be > 0',
        ));
        continue;
      }

      final muA = ma.normalizedScore!;
      final muB = mb.normalizedScore!;
      final delta = (muA - muB).abs();
      final sq = (muA - muB) * (muA - muB);
      final w = config.baseWeightFor(id);
      final a = w * pairQ;

      comparisons.add(StructuralDimensionComparison(
        dimensionId: id,
        module: module,
        subjectAScore: muA,
        subjectBScore: muB,
        absoluteDifference: delta,
        subjectAConfidence: qa,
        subjectBConfidence: qb,
        pairConfidence: pairQ,
        baseWeight: w,
        effectiveWeight: a,
        squaredDifference: sq,
        weightedSquaredContribution: a * sq,
        registryVersion: registry.registryVersion,
        scoringContractVersions: [
          ma.scoringContractVersion,
          mb.scoringContractVersion,
        ]..sort(),
      ));
    }

    comparisons.sort((a, b) => a.dimensionId.compareTo(b.dimensionId));
    exclusions.sort((a, b) {
      final c = a.dimensionId.compareTo(b.dimensionId);
      if (c != 0) return c;
      return a.reasonCode.compareTo(b.reasonCode);
    });

    final comparableIds = [
      for (final c in comparisons) c.dimensionId,
    ];
    final comparableCount = comparisons.length;
    final minRequired = config.minimumComparableFor(module);
    final scale = config.scaleFor(module);

    final totalSimEnabled = similarityEnabled.length;
    final unweightedCoverage =
        totalSimEnabled == 0 ? 0.0 : comparableCount / totalSimEnabled;

    final denomBase = similarityEnabled.fold<double>(
      0,
      (s, d) => s + config.baseWeightFor(d.dimensionId),
    );
    final numBase = comparisons.fold<double>(0, (s, c) => s + c.baseWeight);
    final weightedCoverage = denomBase == 0 ? 0.0 : numBase / denomBase;

    double? meanPairConfidence;
    double? evidenceConfidence;
    if (comparableCount > 0 && numBase > 0) {
      final weightedQ = comparisons.fold<double>(
          0, (s, c) => s + c.baseWeight * c.pairConfidence);
      meanPairConfidence = weightedQ / numBase;
      evidenceConfidence = weightedCoverage * meanPairConfidence;
    }

    final effectiveWeightSum =
        comparisons.fold<double>(0, (s, c) => s + c.effectiveWeight);

    double? distanceSquared;
    double? distance;
    double? similarity;
    StructuralModuleStatus status;

    if (comparableCount < minRequired) {
      status = StructuralModuleStatus.insufficientEvidence;
    } else if (effectiveWeightSum <= 0) {
      status = StructuralModuleStatus.insufficientEvidence;
    } else {
      final numerator = comparisons.fold<double>(
        0,
        (s, c) => s + c.weightedSquaredContribution,
      );
      distanceSquared = numerator / effectiveWeightSum;
      // Numerical clamp for floating-point noise within [0,1].
      if (distanceSquared < 0) distanceSquared = 0;
      if (distanceSquared > 1) distanceSquared = 1;
      distance = math.sqrt(distanceSquared);
      similarity = math.exp(-distanceSquared / (2 * scale * scale));
      status = comparableCount == totalSimEnabled
          ? StructuralModuleStatus.complete
          : StructuralModuleStatus.partial;
    }

    final diagnostics = _buildDiagnostics(
      comparisons: comparisons,
      comparableCount: comparableCount,
      totalSimEnabled: totalSimEnabled,
      minRequired: minRequired,
      status: status,
      effectiveWeightSum: effectiveWeightSum,
    );

    return StructuralModuleSimilarityResult(
      module: module,
      similarityScore: similarity,
      distanceSquared: distanceSquared,
      distance: distance,
      comparableDimensionCount: comparableCount,
      eligibleDimensionCount: eligibleCount,
      totalActiveModuleDimensionCount: active.length,
      comparableDimensionIds: comparableIds,
      excludedDimensions: exclusions,
      dimensionComparisons: comparisons,
      unweightedCoverage: unweightedCoverage,
      weightedCoverage: weightedCoverage,
      meanPairConfidence: meanPairConfidence,
      evidenceConfidence: evidenceConfidence,
      effectiveWeightSum: effectiveWeightSum,
      scaleParameter: scale,
      status: status,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      diagnostics: diagnostics,
    );
  }

  void _validateConfigAgainstRegistry(
    StructuralSimilarityConfig config,
    CanonicalDimensionRegistry registry,
  ) {
    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_and_scoring_contract') {
      cmRequire(
        config.registryVersion == registry.registryVersion,
        'registry_version',
        'registry_version_mismatch',
        'config ${config.registryVersion} vs registry ${registry.registryVersion}',
      );
    }
  }

  ModuleAssessmentProfile? _moduleProfile(
    CanonicalUserAssessmentProfile profile,
    AssessmentModuleId module,
  ) {
    switch (module) {
      case AssessmentModuleId.iq:
        return profile.iq;
      case AssessmentModuleId.eq:
        return profile.eq;
      case AssessmentModuleId.frequency:
        return profile.frequency;
    }
  }

  StructuralSimilarityExclusion? _eligibilityExclusion({
    required String dimensionId,
    required AssessmentModuleId module,
    required bool defSupportsSimilarity,
    required AssessmentModuleId defModule,
    required DimensionMeasurement? measurementA,
    required DimensionMeasurement? measurementB,
    required StructuralSimilarityConfig config,
    required CanonicalDimensionRegistry registry,
  }) {
    if (!registry.contains(dimensionId)) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'unsupported_for_similarity',
        explanation: 'dimension not in active registry',
      );
    }
    if (defModule != module) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'module_mismatch',
        explanation: 'registry module ${defModule.wire} != ${module.wire}',
      );
    }
    if (!defSupportsSimilarity) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'unsupported_for_similarity',
        explanation: 'supports_similarity is false',
      );
    }
    if (measurementA == null) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'missing_subject_a',
        explanation: 'subject A has no measurement',
      );
    }
    if (measurementB == null) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'missing_subject_b',
        explanation: 'subject B has no measurement',
      );
    }
    if (measurementA.publicationStatus !=
        DimensionPublicationStatus.published) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'unpublished_subject_a',
        explanation: measurementA.publicationStatus.wire,
      );
    }
    if (measurementB.publicationStatus !=
        DimensionPublicationStatus.published) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'unpublished_subject_b',
        explanation: measurementB.publicationStatus.wire,
      );
    }
    if (!measurementA.publishability) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'not_publishable_subject_a',
        explanation: 'publishability false',
      );
    }
    if (!measurementB.publishability) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'not_publishable_subject_b',
        explanation: 'publishability false',
      );
    }
    if (measurementA.normalizedScore == null ||
        !measurementA.normalizedScore!.isFinite ||
        measurementA.normalizedScore! < config.scoreMin ||
        measurementA.normalizedScore! > config.scoreMax) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'invalid_score',
        explanation: 'subject A score invalid',
      );
    }
    if (measurementB.normalizedScore == null ||
        !measurementB.normalizedScore!.isFinite ||
        measurementB.normalizedScore! < config.scoreMin ||
        measurementB.normalizedScore! > config.scoreMax) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'invalid_score',
        explanation: 'subject B score invalid',
      );
    }
    if (!measurementA.confidence.isFinite ||
        measurementA.confidence < config.confidenceMin ||
        measurementA.confidence > config.confidenceMax ||
        !measurementB.confidence.isFinite ||
        measurementB.confidence < config.confidenceMin ||
        measurementB.confidence > config.confidenceMax) {
      return StructuralSimilarityExclusion(
        dimensionId: dimensionId,
        reasonCode: 'invalid_confidence',
        explanation: 'confidence out of bounds or non-finite',
      );
    }
    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_and_scoring_contract') {
      if (measurementA.registryVersion != registry.registryVersion ||
          measurementB.registryVersion != registry.registryVersion) {
        return StructuralSimilarityExclusion(
          dimensionId: dimensionId,
          reasonCode: 'registry_version_mismatch',
          explanation:
              'A=${measurementA.registryVersion} B=${measurementB.registryVersion} registry=${registry.registryVersion}',
        );
      }
      if (measurementA.scoringContractVersion !=
              measurementB.scoringContractVersion ||
          measurementA.scoringContractVersion.isEmpty) {
        return StructuralSimilarityExclusion(
          dimensionId: dimensionId,
          reasonCode: 'scoring_contract_mismatch',
          explanation:
              'A=${measurementA.scoringContractVersion} B=${measurementB.scoringContractVersion}',
        );
      }
    }
    return null;
  }

  StructuralSimilarityDiagnostics _buildDiagnostics({
    required List<StructuralDimensionComparison> comparisons,
    required int comparableCount,
    required int totalSimEnabled,
    required int minRequired,
    required StructuralModuleStatus status,
    required double effectiveWeightSum,
  }) {
    const highQ = 0.6;
    const closeDelta = 0.15;
    const farDelta = 0.4;

    final closeHigh = <String>[];
    final distantHigh = <String>[];
    final closeLow = <String>[];
    final distantLow = <String>[];
    final codes = <String>[];

    for (final c in comparisons) {
      final high = c.pairConfidence >= highQ;
      if (c.absoluteDifference <= closeDelta) {
        if (high) {
          closeHigh.add(c.dimensionId);
        } else {
          closeLow.add(c.dimensionId);
        }
      } else if (c.absoluteDifference >= farDelta) {
        if (high) {
          distantHigh.add(c.dimensionId);
        } else {
          distantLow.add(c.dimensionId);
        }
      }
    }

    if (status == StructuralModuleStatus.insufficientEvidence) {
      codes.add('insufficient_module_coverage');
    } else if (status == StructuralModuleStatus.complete) {
      codes.add('similarity_available');
    } else if (status == StructuralModuleStatus.partial) {
      codes.add('similarity_partial');
    }
    if (comparableCount > 0 && comparableCount < totalSimEnabled) {
      codes.add('insufficient_module_coverage');
    }
    if (comparableCount >= minRequired && effectiveWeightSum <= 0) {
      codes.add('low_effective_weight');
    }
    if (closeHigh.isNotEmpty) {
      codes.add('close_high_confidence_dimension');
    }
    if (distantHigh.isNotEmpty) {
      codes.add('distant_high_confidence_dimension');
    }
    if (closeLow.isNotEmpty) {
      codes.add('close_low_confidence_dimension');
    }
    if (distantLow.isNotEmpty) {
      codes.add('distant_low_confidence_dimension');
    }

    final uniqueCodes = codes.toSet().toList()..sort();
    closeHigh.sort();
    distantHigh.sort();
    closeLow.sort();
    distantLow.sort();

    return StructuralSimilarityDiagnostics(
      codes: uniqueCodes,
      closeHighConfidenceDimensions: closeHigh,
      distantHighConfidenceDimensions: distantHigh,
      closeLowConfidenceDimensions: closeLow,
      distantLowConfidenceDimensions: distantLow,
      notes: const [],
    );
  }

  StructuralProfileStatus _overallStatus({
    required List<StructuralModuleSimilarityResult?> results,
    required List<String> missingModules,
    required int requestedCount,
  }) {
    final present = [
      for (final r in results)
        if (r != null) r
    ];
    if (present.any((r) => r.status == StructuralModuleStatus.invalidInput)) {
      return StructuralProfileStatus.invalidInput;
    }
    if (present.isEmpty) {
      return StructuralProfileStatus.insufficientEvidence;
    }
    if (missingModules.isNotEmpty ||
        present.any((r) =>
            r.status == StructuralModuleStatus.partial ||
            r.status == StructuralModuleStatus.insufficientEvidence)) {
      if (present.every(
          (r) => r.status == StructuralModuleStatus.insufficientEvidence)) {
        return StructuralProfileStatus.insufficientEvidence;
      }
      return StructuralProfileStatus.partial;
    }
    if (present.length == requestedCount &&
        present.every((r) => r.status == StructuralModuleStatus.complete)) {
      return StructuralProfileStatus.complete;
    }
    return StructuralProfileStatus.partial;
  }

  String _fingerprintSymmetric(StructuralProfileSimilarityResult result) {
    Map<String, dynamic>? mod(StructuralModuleSimilarityResult? m) {
      if (m == null) return null;
      final comps = [
        for (final c in m.dimensionComparisons)
          cmSortedMap({
            'dimension_id': c.dimensionId,
            'scores_sorted': ([c.subjectAScore, c.subjectBScore]..sort()),
            'absolute_difference': c.absoluteDifference,
            'confidences_sorted': ([c.subjectAConfidence, c.subjectBConfidence]
              ..sort()),
            'pair_confidence': c.pairConfidence,
            'base_weight': c.baseWeight,
            'effective_weight': c.effectiveWeight,
            'squared_difference': c.squaredDifference,
            'weighted_squared_contribution': c.weightedSquaredContribution,
          }),
      ];
      final excl = [
        for (final e in m.excludedDimensions)
          cmSortedMap({
            'dimension_id': e.dimensionId,
            'reason_code': e.reasonCode,
          }),
      ];
      return cmSortedMap({
        'module': m.module.wire,
        'similarity_score': m.similarityScore,
        'distance_squared': m.distanceSquared,
        'comparable_dimension_ids': m.comparableDimensionIds,
        'excluded': excl,
        'comparisons': comps,
        'unweighted_coverage': m.unweightedCoverage,
        'weighted_coverage': m.weightedCoverage,
        'mean_pair_confidence': m.meanPairConfidence,
        'evidence_confidence': m.evidenceConfidence,
        'status': m.status.wire,
        'scale_parameter': m.scaleParameter,
      });
    }

    final payload = cmSortedMap({
      'config_version': result.configVersion,
      'registry_version': result.registryVersion,
      'evaluated_modules': result.evaluatedModules,
      'missing_modules': result.missingModules,
      'overall_status': result.overallStatus.wire,
      'iq': mod(result.iq),
      'eq': mod(result.eq),
      'frequency': mod(result.frequency),
    });
    return _fingerprint(payload);
  }

  String _fingerprint(Map<String, dynamic> json) {
    final encoded = jsonEncode(cmSortedMap(json));
    // Stable non-crypto fingerprint for engineering determinism checks.
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
