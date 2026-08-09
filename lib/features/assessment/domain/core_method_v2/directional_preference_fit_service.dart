import 'dart:convert';
import 'dart:math' as math;

import 'canonical_dimension_registry.dart';
import 'canonical_user_assessment_profile.dart';
import 'compatibility_pair_input.dart';
import 'core_method_v2_validation.dart';
import 'dimension_measurement.dart';
import 'dimension_publication_status.dart';
import 'directional_preference_fit_config.dart';
import 'directional_preference_fit_models.dart';
import 'partner_dimension_preference.dart';

/// Offline directional partner-preference fit (P2B-2).
///
/// Does not call structural similarity, values, hard constraints,
/// persona scoring, or final compatibility aggregation.
class DirectionalPreferenceFitService {
  const DirectionalPreferenceFitService();

  DirectionalPreferenceFitResult evaluateDirectional({
    required CompatibilitySubjectSnapshot preferenceOwner,
    required CompatibilitySubjectSnapshot evaluatedSubject,
    required CanonicalDimensionRegistry registry,
    required PartnerPreferenceFitConfig config,
    DateTime? evaluationTimestamp,
  }) {
    _validateConfigAgainstRegistry(config, registry);

    final ownerPrefs = preferenceOwner.partnerPreferenceProfile;
    final ownerAssessment = preferenceOwner.assessmentProfile;
    final partnerAssessment = evaluatedSubject.assessmentProfile;

    final preferenceSupportDims = [
      for (final d in registry.activeDimensions)
        if (d.supportsPartnerPreference) d,
    ]..sort((a, b) => a.dimensionId.compareTo(b.dimensionId));

    final prefKeys = ownerPrefs.preferences.keys.toList()..sort();
    final exclusions = <DirectionalPreferenceFitExclusion>[];
    final fits = <PreferenceDimensionFit>[];
    final openIds = <String>[];
    var unavailableCount = 0;
    var declaredScoreableCount = 0;
    var declaredImportanceMass = 0.0;

    for (final id in prefKeys) {
      final pref = ownerPrefs.preferences[id]!;
      final def = registry.dimensionsById[id];

      if (pref.preferenceMode == PreferenceMode.open) {
        if (pref.explicitlyProvided) {
          openIds.add(id);
          exclusions.add(DirectionalPreferenceFitExclusion(
            dimensionId: id,
            reasonCode: 'preference_open',
            explanation: 'explicit open preference excluded from scoring',
          ));
        } else {
          exclusions.add(DirectionalPreferenceFitExclusion(
            dimensionId: id,
            reasonCode: 'preference_not_explicit',
            explanation: 'open preference not explicitly provided',
          ));
        }
        continue;
      }

      if (pref.preferenceMode == PreferenceMode.unavailable) {
        unavailableCount++;
        exclusions.add(DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'preference_unavailable',
          explanation: 'unavailable preference excluded',
        ));
        continue;
      }

      // Scoreable modes: range / similarity_to_self
      if (pref.preferenceMode == PreferenceMode.range ||
          pref.preferenceMode == PreferenceMode.similarityToSelf) {
        if (pref.explicitlyProvided &&
            pref.importance != null &&
            pref.importance! > 0 &&
            pref.importance!.isFinite) {
          declaredScoreableCount++;
          declaredImportanceMass += pref.importance!;
        }
      }

      final exclusion = _eligibilityExclusion(
        preference: pref,
        def: def,
        ownerAssessment: ownerAssessment,
        partnerAssessment: partnerAssessment,
        config: config,
        registry: registry,
      );
      if (exclusion != null) {
        exclusions.add(exclusion);
        continue;
      }

      final partnerMeas = _measurementFor(partnerAssessment, id)!;
      final selfMeas = pref.preferenceMode == PreferenceMode.similarityToSelf
          ? _measurementFor(ownerAssessment, id)
          : null;

      final muB = partnerMeas.normalizedScore!;
      final importance = pref.importance!;
      final flexibility = pref.flexibility!;
      final sigma = config.flexibilityScale(flexibility);

      double distance;
      double? selfScore;
      double evidenceQ;
      final diag = <String>[];

      if (pref.preferenceMode == PreferenceMode.range) {
        final L = pref.preferredMin!;
        final U = pref.preferredMax!;
        if (muB < L) {
          distance = L - muB;
          diag.add('preference_target_below_range');
        } else if (muB > U) {
          distance = muB - U;
          diag.add('preference_target_above_range');
        } else {
          distance = 0;
          diag.add('preference_target_inside_range');
        }
        evidenceQ = partnerMeas.confidence;
      } else {
        // similarity_to_self
        selfScore = selfMeas!.normalizedScore!;
        distance = (selfScore - muB).abs();
        evidenceQ = math.sqrt(selfMeas.confidence * partnerMeas.confidence);
        if (distance <= 0.15) {
          diag.add('preference_similarity_close');
        } else if (distance >= 0.4) {
          diag.add('preference_similarity_distant');
        }
      }

      if (importance >= 0.7) diag.add('preference_high_importance');
      if (flexibility >= 0.7) {
        diag.add('preference_high_flexibility');
      } else if (flexibility <= 0.3) {
        diag.add('preference_low_flexibility');
      }
      if (evidenceQ < 0.4) diag.add('preference_low_measurement_confidence');

      final p = math.exp(-(distance * distance) / (2 * sigma * sigma));
      final a = importance * evidenceQ;
      final contracts = <String>{
        partnerMeas.scoringContractVersion,
        if (selfMeas != null) selfMeas.scoringContractVersion,
      }.toList()
        ..sort();

      fits.add(PreferenceDimensionFit(
        dimensionId: id,
        module: def!.module,
        preferenceMode: pref.preferenceMode,
        preferenceOwnerId: preferenceOwner.subjectId,
        evaluatedSubjectId: evaluatedSubject.subjectId,
        evaluatedScore: muB,
        selfScore: selfScore,
        preferredMin: pref.preferredMin,
        preferredMax: pref.preferredMax,
        distanceToTarget: distance,
        importance: importance,
        flexibility: flexibility,
        flexibilityScale: sigma,
        evidenceConfidence: evidenceQ,
        rawDimensionFit: p,
        effectiveWeight: a,
        weightedContribution: a * p,
        registryVersion: registry.registryVersion,
        scoringContractVersions: contracts,
        diagnosticCodes: diag.toSet().toList()..sort(),
      ));
    }

    // Preferences completely missing from profile for support dims are not
    // auto-added; only declared preferences are considered.

    fits.sort((a, b) => a.dimensionId.compareTo(b.dimensionId));
    exclusions.sort((a, b) {
      final c = a.dimensionId.compareTo(b.dimensionId);
      if (c != 0) return c;
      return a.reasonCode.compareTo(b.reasonCode);
    });
    openIds.sort();

    final comparableIds = [for (final f in fits) f.dimensionId];
    final comparableCount = fits.length;
    final comparableImportanceMass =
        fits.fold<double>(0, (s, f) => s + f.importance);
    final effectiveWeightSum =
        fits.fold<double>(0, (s, f) => s + f.effectiveWeight);

    double? coverage;
    if (declaredImportanceMass > 0) {
      coverage = comparableImportanceMass / declaredImportanceMass;
    }

    double? meanQ;
    double? evidenceConfidence;
    if (comparableCount > 0 && comparableImportanceMass > 0) {
      meanQ = fits.fold<double>(
            0,
            (s, f) => s + f.importance * f.evidenceConfidence,
          ) /
          comparableImportanceMass;
      evidenceConfidence = (coverage ?? 0) * meanQ;
    }

    double? rawFit;
    DirectionalPreferenceFitStatus status;
    if (comparableCount < config.minimumComparablePreferences) {
      status = DirectionalPreferenceFitStatus.insufficientEvidence;
    } else if (effectiveWeightSum <= 0) {
      status = DirectionalPreferenceFitStatus.insufficientEvidence;
    } else {
      final numerator =
          fits.fold<double>(0, (s, f) => s + f.weightedContribution);
      rawFit = numerator / effectiveWeightSum;
      if (rawFit < 0) rawFit = 0;
      if (rawFit > 1) rawFit = 1;
      final allScoreableComparable =
          comparableCount == declaredScoreableCount &&
              declaredScoreableCount > 0 &&
              exclusions
                  .where((e) =>
                      e.reasonCode != 'preference_open' &&
                      e.reasonCode != 'preference_unavailable')
                  .isEmpty;
      status = allScoreableComparable
          ? DirectionalPreferenceFitStatus.complete
          : DirectionalPreferenceFitStatus.partial;
    }

    final supportCount = preferenceSupportDims.length;
    final answered = ownerPrefs.explicitlyAnsweredDimensions.toSet();
    // Also count explicit prefs keys if answered list incomplete.
    for (final id in prefKeys) {
      if (ownerPrefs.preferences[id]!.explicitlyProvided) answered.add(id);
    }
    final breadth = supportCount == 0
        ? 0.0
        : answered
                .where((id) =>
                    preferenceSupportDims.any((d) => d.dimensionId == id))
                .length /
            supportCount;

    final diagnostics = _buildDiagnostics(
      status: status,
      fits: fits,
      openIds: openIds,
    );

    final provisional = DirectionalPreferenceFitResult(
      preferenceOwnerId: preferenceOwner.subjectId,
      evaluatedSubjectId: evaluatedSubject.subjectId,
      rawFitScore: rawFit,
      evidenceConfidence: evidenceConfidence,
      declaredScoreablePreferenceCount: declaredScoreableCount,
      comparablePreferenceCount: comparableCount,
      explicitlyOpenPreferenceCount: openIds.length,
      unavailablePreferenceCount: unavailableCount,
      comparablePreferenceIds: comparableIds,
      openPreferenceIds: openIds,
      excludedPreferences: exclusions,
      dimensionFits: fits,
      declaredImportanceMass: declaredImportanceMass,
      comparableImportanceMass: comparableImportanceMass,
      effectiveWeightSum: effectiveWeightSum,
      evaluationCoverage: coverage,
      profileDeclarationBreadth: breadth,
      status: status,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      deterministicFingerprint: '',
      diagnostics: diagnostics,
    );
    return DirectionalPreferenceFitResult(
      preferenceOwnerId: provisional.preferenceOwnerId,
      evaluatedSubjectId: provisional.evaluatedSubjectId,
      rawFitScore: provisional.rawFitScore,
      evidenceConfidence: provisional.evidenceConfidence,
      declaredScoreablePreferenceCount:
          provisional.declaredScoreablePreferenceCount,
      comparablePreferenceCount: provisional.comparablePreferenceCount,
      explicitlyOpenPreferenceCount: provisional.explicitlyOpenPreferenceCount,
      unavailablePreferenceCount: provisional.unavailablePreferenceCount,
      comparablePreferenceIds: provisional.comparablePreferenceIds,
      openPreferenceIds: provisional.openPreferenceIds,
      excludedPreferences: provisional.excludedPreferences,
      dimensionFits: provisional.dimensionFits,
      declaredImportanceMass: provisional.declaredImportanceMass,
      comparableImportanceMass: provisional.comparableImportanceMass,
      effectiveWeightSum: provisional.effectiveWeightSum,
      evaluationCoverage: provisional.evaluationCoverage,
      profileDeclarationBreadth: provisional.profileDeclarationBreadth,
      status: provisional.status,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
      deterministicFingerprint: _fingerprintDirectional(provisional),
      diagnostics: provisional.diagnostics,
    );
  }

  MutualPreferenceFitResult evaluateMutual({
    required CompatibilitySubjectSnapshot subjectA,
    required CompatibilitySubjectSnapshot subjectB,
    required CanonicalDimensionRegistry registry,
    required PartnerPreferenceFitConfig config,
    DateTime? evaluationTimestamp,
  }) {
    final aToB = evaluateDirectional(
      preferenceOwner: subjectA,
      evaluatedSubject: subjectB,
      registry: registry,
      config: config,
      evaluationTimestamp: evaluationTimestamp,
    );
    final bToA = evaluateDirectional(
      preferenceOwner: subjectB,
      evaluatedSubject: subjectA,
      registry: registry,
      config: config,
      evaluationTimestamp: evaluationTimestamp,
    );

    double? mutualRaw;
    double? mutualQ;
    double? asymmetry;
    MutualPreferenceFitStatus status;
    final codes = <String>[];

    final aOk = aToB.rawFitScore != null;
    final bOk = bToA.rawFitScore != null;
    if (aOk && bOk) {
      mutualRaw = math.sqrt(aToB.rawFitScore! * bToA.rawFitScore!);
      if (aToB.evidenceConfidence != null && bToA.evidenceConfidence != null) {
        mutualQ =
            math.sqrt(aToB.evidenceConfidence! * bToA.evidenceConfidence!);
      }
      asymmetry = (aToB.rawFitScore! - bToA.rawFitScore!).abs();
      status = (aToB.status == DirectionalPreferenceFitStatus.complete &&
              bToA.status == DirectionalPreferenceFitStatus.complete)
          ? MutualPreferenceFitStatus.complete
          : MutualPreferenceFitStatus.partial;
      codes.add('mutual_fit_available');
      if (asymmetry >= 0.2) codes.add('mutual_fit_asymmetric');
    } else if (aOk || bOk) {
      status = MutualPreferenceFitStatus.partial;
      codes.add('mutual_fit_unavailable');
    } else {
      status = MutualPreferenceFitStatus.insufficientEvidence;
      codes.add('mutual_fit_unavailable');
    }

    if (aToB.status == DirectionalPreferenceFitStatus.invalidInput ||
        bToA.status == DirectionalPreferenceFitStatus.invalidInput) {
      status = MutualPreferenceFitStatus.invalidInput;
    }

    codes.sort();
    final provisional = MutualPreferenceFitResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      mutualRawFitScore: mutualRaw,
      mutualEvidenceConfidence: mutualQ,
      directionalAsymmetry: asymmetry,
      status: status,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      deterministicFingerprint: '',
      diagnostics:
          DirectionalPreferenceFitDiagnostics(codes: codes, notes: const []),
    );
    return MutualPreferenceFitResult(
      subjectAToBResult: aToB,
      subjectBToAResult: bToA,
      mutualRawFitScore: mutualRaw,
      mutualEvidenceConfidence: mutualQ,
      directionalAsymmetry: asymmetry,
      status: status,
      configVersion: config.configVersion,
      registryVersion: registry.registryVersion,
      deterministicFingerprint: _fingerprintMutual(provisional),
      diagnostics: provisional.diagnostics,
    );
  }

  void _validateConfigAgainstRegistry(
    PartnerPreferenceFitConfig config,
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

  DimensionMeasurement? _measurementFor(
    CanonicalUserAssessmentProfile profile,
    String dimensionId,
  ) {
    return profile.publishedMeasurements[dimensionId] ??
        profile.iq?.measurements[dimensionId] ??
        profile.eq?.measurements[dimensionId] ??
        profile.frequency?.measurements[dimensionId];
  }

  DirectionalPreferenceFitExclusion? _eligibilityExclusion({
    required PartnerDimensionPreference preference,
    required CanonicalDimensionDefinition? def,
    required CanonicalUserAssessmentProfile ownerAssessment,
    required CanonicalUserAssessmentProfile partnerAssessment,
    required PartnerPreferenceFitConfig config,
    required CanonicalDimensionRegistry registry,
  }) {
    final id = preference.dimensionId;
    if (def == null || !registry.contains(id)) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'unsupported_partner_preference_dimension',
        explanation: 'dimension not in active registry',
      );
    }
    if (!def.supportsPartnerPreference) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'unsupported_partner_preference_dimension',
        explanation: 'supports_partner_preference is false',
      );
    }
    if (!config.supportsMode(preference.preferenceMode)) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'unsupported_preference_mode',
        explanation: preference.preferenceMode.wire,
      );
    }
    if (!preference.explicitlyProvided) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'preference_not_explicit',
        explanation: 'explicitly_provided is false',
      );
    }
    if (config.inferredPreferencePolicy == 'prohibited_by_default' &&
        preference.source == 'inferred_from_self_score') {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'inferred_preference_prohibited',
        explanation: 'inferred preferences prohibited by default',
      );
    }
    if (preference.preferenceMode != PreferenceMode.range &&
        preference.preferenceMode != PreferenceMode.similarityToSelf) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'unsupported_preference_mode',
        explanation: preference.preferenceMode.wire,
      );
    }
    if (preference.importance == null || !preference.importance!.isFinite) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'invalid_importance',
        explanation: 'importance missing or non-finite',
      );
    }
    if (preference.importance! <= 0) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'zero_importance',
        explanation: 'importance must be > 0',
      );
    }
    if (preference.importance! < config.importanceMin ||
        preference.importance! > config.importanceMax) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'invalid_importance',
        explanation: 'importance out of bounds',
      );
    }
    if (preference.flexibility == null ||
        !preference.flexibility!.isFinite ||
        preference.flexibility! < config.flexibilityMin ||
        preference.flexibility! > config.flexibilityMax) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'invalid_flexibility',
        explanation: 'flexibility missing or out of bounds',
      );
    }

    final partner = _measurementFor(partnerAssessment, id);
    if (partner == null) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'missing_partner_measurement',
        explanation: 'evaluated subject has no measurement',
      );
    }
    if (partner.publicationStatus != DimensionPublicationStatus.published) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'unpublished_partner_measurement',
        explanation: partner.publicationStatus.wire,
      );
    }
    if (!partner.publishability) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'non_publishable_partner_measurement',
        explanation: 'publishability false',
      );
    }
    if (partner.normalizedScore == null ||
        !partner.normalizedScore!.isFinite ||
        partner.normalizedScore! < config.scoreMin ||
        partner.normalizedScore! > config.scoreMax) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'invalid_partner_score',
        explanation: 'partner score invalid',
      );
    }
    if (!partner.confidence.isFinite ||
        partner.confidence < config.confidenceMin ||
        partner.confidence > config.confidenceMax) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'invalid_partner_confidence',
        explanation: 'partner confidence invalid',
      );
    }

    if (preference.preferenceMode == PreferenceMode.similarityToSelf) {
      final self = _measurementFor(ownerAssessment, id);
      if (self == null) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'missing_self_measurement',
          explanation: 'owner has no self measurement',
        );
      }
      if (self.publicationStatus != DimensionPublicationStatus.published) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'unpublished_self_measurement',
          explanation: self.publicationStatus.wire,
        );
      }
      if (self.normalizedScore == null ||
          !self.normalizedScore!.isFinite ||
          self.normalizedScore! < config.scoreMin ||
          self.normalizedScore! > config.scoreMax) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'invalid_self_score',
          explanation: 'self score invalid',
        );
      }
      if (!self.confidence.isFinite ||
          self.confidence < config.confidenceMin ||
          self.confidence > config.confidenceMax) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'invalid_self_confidence',
          explanation: 'self confidence invalid',
        );
      }
    }

    if (config.versionCompatibilityPolicy ==
        'require_matching_registry_and_scoring_contract') {
      if (partner.registryVersion != registry.registryVersion) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'registry_version_mismatch',
          explanation: partner.registryVersion,
        );
      }
      if (preference.preferenceMode == PreferenceMode.similarityToSelf) {
        final self = _measurementFor(ownerAssessment, id)!;
        if (self.registryVersion != registry.registryVersion) {
          return DirectionalPreferenceFitExclusion(
            dimensionId: id,
            reasonCode: 'registry_version_mismatch',
            explanation: self.registryVersion,
          );
        }
        if (self.scoringContractVersion != partner.scoringContractVersion ||
            self.scoringContractVersion.isEmpty) {
          return DirectionalPreferenceFitExclusion(
            dimensionId: id,
            reasonCode: 'scoring_contract_mismatch',
            explanation:
                'self=${self.scoringContractVersion} partner=${partner.scoringContractVersion}',
          );
        }
      } else if (partner.scoringContractVersion.isEmpty) {
        return DirectionalPreferenceFitExclusion(
          dimensionId: id,
          reasonCode: 'scoring_contract_mismatch',
          explanation: 'empty scoring contract',
        );
      }
    }

    final q = preference.preferenceMode == PreferenceMode.range
        ? partner.confidence
        : math.sqrt(
            _measurementFor(ownerAssessment, id)!.confidence *
                partner.confidence,
          );
    if (q <= 0) {
      return DirectionalPreferenceFitExclusion(
        dimensionId: id,
        reasonCode: 'zero_evidence_confidence',
        explanation: 'evidence confidence must be > 0',
      );
    }
    return null;
  }

  DirectionalPreferenceFitDiagnostics _buildDiagnostics({
    required DirectionalPreferenceFitStatus status,
    required List<PreferenceDimensionFit> fits,
    required List<String> openIds,
  }) {
    final codes = <String>[];
    switch (status) {
      case DirectionalPreferenceFitStatus.complete:
        codes.add('directional_fit_available');
      case DirectionalPreferenceFitStatus.partial:
        codes.add('directional_fit_partial');
      case DirectionalPreferenceFitStatus.insufficientEvidence:
        codes.add('directional_fit_insufficient');
      case DirectionalPreferenceFitStatus.invalidInput:
        codes.add('directional_fit_insufficient');
    }
    if (openIds.isNotEmpty) codes.add('preference_open_explicitly');
    for (final f in fits) {
      codes.addAll(f.diagnosticCodes);
    }
    return DirectionalPreferenceFitDiagnostics(
      codes: codes.toSet().toList()..sort(),
      notes: const [],
    );
  }

  String _fingerprintDirectional(DirectionalPreferenceFitResult r) {
    final payload = cmSortedMap({
      'preference_owner_id': r.preferenceOwnerId,
      'evaluated_subject_id': r.evaluatedSubjectId,
      'raw_fit_score': r.rawFitScore,
      'evidence_confidence': r.evidenceConfidence,
      'comparable_preference_ids': r.comparablePreferenceIds,
      'open_preference_ids': r.openPreferenceIds,
      'excluded': [
        for (final e in r.excludedPreferences)
          cmSortedMap({
            'dimension_id': e.dimensionId,
            'reason_code': e.reasonCode,
          }),
      ],
      'fits': [
        for (final f in r.dimensionFits)
          cmSortedMap({
            'dimension_id': f.dimensionId,
            'raw_dimension_fit': f.rawDimensionFit,
            'effective_weight': f.effectiveWeight,
            'evidence_confidence': f.evidenceConfidence,
            'distance_to_target': f.distanceToTarget,
            'importance': f.importance,
            'flexibility': f.flexibility,
          }),
      ],
      'status': r.status.wire,
      'config_version': r.configVersion,
      'registry_version': r.registryVersion,
    });
    return _hash(payload);
  }

  String _fingerprintMutual(MutualPreferenceFitResult r) {
    // Order-invariant: sort the two directional fingerprints.
    final dirs = [
      r.subjectAToBResult.deterministicFingerprint,
      r.subjectBToAResult.deterministicFingerprint,
    ]..sort();
    final payload = cmSortedMap({
      'directional_fingerprints_sorted': dirs,
      'mutual_raw_fit_score': r.mutualRawFitScore,
      'mutual_evidence_confidence': r.mutualEvidenceConfidence,
      'directional_asymmetry': r.directionalAsymmetry,
      'status': r.status.wire,
      'config_version': r.configVersion,
      'registry_version': r.registryVersion,
    });
    return _hash(payload);
  }

  String _hash(Map<String, dynamic> json) {
    final encoded = jsonEncode(cmSortedMap(json));
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
