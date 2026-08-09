// Deterministic simulations for directional preference fit v1 (P2B-2.1).
// Usage: dart run tool/simulate_directional_preference_fit_v1.dart
// Scenario count is derived from the scenarios list — never hard-stated.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/directional_preference_fit_simulation_v1_report.json';

void main() {
  final root = Directory.current.path;
  final registry = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/canonical_dimension_registry_v1.json',
  );
  final config = PartnerPreferenceFitConfig.loadFile(
    '$root/assets/data/core_method_v2/directional_preference_fit_config_v1.json',
  );
  final fixture24 = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
  );
  final structCfg = StructuralSimilarityConfig.loadFile(
    '$root/assets/data/core_method_v2/structural_similarity_config_v1.json',
  );
  const prefService = DirectionalPreferenceFitService();
  const structService = StructuralSimilarityService();
  final eqDims = registry.dimsForModule(AssessmentModuleId.eq);
  final dim = eqDims.first.dimensionId;
  final dim2 = eqDims[1].dimensionId;
  final ts = DateTime.utc(2026, 1, 1);

  DimensionMeasurement meas({
    required String id,
    required double? score,
    double confidence = 0.8,
    bool publishability = true,
    DimensionPublicationStatus status = DimensionPublicationStatus.published,
    String scoring = 'trait_scoring_config_v1',
    String registryVersion = 'canonical_dimension_registry_v1',
  }) =>
      DimensionMeasurement(
        dimensionId: id,
        module: AssessmentModuleId.eq,
        normalizedScore:
            status == DimensionPublicationStatus.published ? score : null,
        confidence: confidence,
        uncertainty: 0.2,
        primaryEvidenceCount: 1,
        secondaryEvidenceCount: 0,
        independentContextCount: 1,
        publicationStatus: status,
        publishability: publishability,
        sourceContentVersions: const ['sim'],
        measurementTimestamp: ts,
        scoringContractVersion: scoring,
        registryVersion: registryVersion,
      );

  CompatibilitySubjectSnapshot snap({
    required String id,
    Map<String, DimensionMeasurement>? measurements,
    Map<String, PartnerDimensionPreference>? preferences,
    CanonicalDimensionRegistry? reg,
  }) {
    final r = reg ?? registry;
    final m = measurements ?? {};
    ModuleAssessmentProfile? eq;
    if (m.isNotEmpty) {
      final keys = m.keys.toList()..sort();
      eq = ModuleAssessmentProfile(
        module: AssessmentModuleId.eq,
        measurements: {for (final k in keys) k: m[k]!},
        assessmentFormId: 'eq',
        contentVersion: 'sim',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.partial,
        completedAt: ts,
        moduleConfidence: 0.8,
        evidenceCoverage: 0.1,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: r.registryVersion,
      );
    }
    final assessment = CanonicalUserAssessmentProfile(
      snapshotId: id,
      profileSchemaVersion: 'v1',
      registryVersion: r.registryVersion,
      iq: null,
      eq: eq,
      frequency: null,
      publishedMeasurements:
          CanonicalUserAssessmentProfile.flattenPublished(eq: eq),
      unavailableDimensions: const [],
      createdAt: ts,
      updatedAt: ts,
      sourceAssessmentVersions: const ['sim'],
      overallAssessmentCoverage: 0.1,
      profileReadinessStatus: ProfileReadinessStatus.provisional,
    );
    final prefs = preferences ?? {};
    final pKeys = prefs.keys.toList()..sort();
    return CompatibilitySubjectSnapshot(
      subjectId: id,
      assessmentProfile: assessment,
      partnerPreferenceProfile: PartnerPreferenceProfile(
        preferences: {for (final k in pKeys) k: prefs[k]!},
        profileVersion: 'v1',
        registryVersion: r.registryVersion,
        createdAt: ts,
        updatedAt: ts,
        completionStatus: PreferenceProfileCompletionStatus.partial,
        explicitlyAnsweredDimensions: [
          for (final e in prefs.entries)
            if (e.value.explicitlyProvided) e.key,
        ]..sort(),
        openDimensions: [
          for (final e in prefs.entries)
            if (e.value.preferenceMode == PreferenceMode.open) e.key,
        ]..sort(),
        unavailableDimensions: [
          for (final e in prefs.entries)
            if (e.value.preferenceMode == PreferenceMode.unavailable) e.key,
        ]..sort(),
      ),
      relationshipValueProfile: RelationshipValueProfile(
        responses: const {},
        profileVersion: 'v1',
        registryVersion: 'relationship_value_registry_v1',
        createdAt: null,
        updatedAt: null,
      ),
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: ts,
    );
  }

  PartnerDimensionPreference rangePref(
    String id,
    double L,
    double U, {
    double i = 0.8,
    double f = 0.5,
    bool explicit = true,
    String source = 'explicit_user',
  }) =>
      PartnerDimensionPreference(
        dimensionId: id,
        preferredMin: L,
        preferredMax: U,
        importance: i,
        flexibility: f,
        preferenceMode: PreferenceMode.range,
        source: source,
        explicitlyProvided: explicit,
        updatedAt: ts,
      );

  PartnerDimensionPreference simPref(
    String id, {
    double i = 0.8,
    double f = 0.5,
  }) =>
      PartnerDimensionPreference(
        dimensionId: id,
        preferredMin: null,
        preferredMax: null,
        importance: i,
        flexibility: f,
        preferenceMode: PreferenceMode.similarityToSelf,
        source: 'explicit_user',
        explicitlyProvided: true,
        updatedAt: ts,
      );

  final scenarios = <Map<String, Object?>>[];

  void addScenario({
    required String id,
    required String name,
    required String purpose,
    required String inputSummary,
    required String expected,
    required Object? actual,
    required bool pass,
    List<String> diagnosticCodes = const [],
  }) {
    scenarios.add(cmSortedMap({
      'id': id,
      'name': name,
      'purpose': purpose,
      'input_summary': inputSummary,
      'expected_outcome': expected,
      'actual_outcome': actual,
      'pass': pass,
      'diagnostic_codes': [...diagnosticCodes]..sort(),
    }));
  }

  Map<String, Object?> dirOut(DirectionalPreferenceFitResult r) => {
        'raw_fit': r.rawFitScore,
        'evidence_q': r.evidenceConfidence,
        'status': r.status.wire,
        'comparable': r.comparablePreferenceCount,
        'open_ids': r.openPreferenceIds,
        'exclusion_codes': [
          for (final e in r.excludedPreferences) e.reasonCode,
        ]..sort(),
        'fingerprint': r.deterministicFingerprint,
      };

  // --- 01–09 range ---
  final ownerMid = snap(
    id: 'A',
    measurements: {dim: meas(id: dim, score: 0.5)},
    preferences: {dim: rangePref(dim, 0.4, 0.6)},
  );
  DirectionalPreferenceFitResult evalAt(double score, {double conf = 0.8}) =>
      prefService.evaluateDirectional(
        preferenceOwner: ownerMid,
        evaluatedSubject: snap(
          id: 'B',
          measurements: {dim: meas(id: dim, score: score, confidence: conf)},
        ),
        registry: registry,
        config: config,
      );

  final r01 = evalAt(0.5);
  addScenario(
    id: '01',
    name: 'range_inside',
    purpose: 'Range target exactly inside interval',
    inputSummary: 'pref[0.4,0.6] partner=0.5',
    expected: 'raw_fit == 1',
    actual: dirOut(r01),
    pass: r01.rawFitScore == 1.0,
    diagnosticCodes: r01.diagnostics.codes,
  );
  final r02 = evalAt(0.4);
  addScenario(
    id: '02',
    name: 'range_lower_boundary',
    purpose: 'Range target at lower boundary',
    inputSummary: 'pref[0.4,0.6] partner=0.4',
    expected: 'raw_fit == 1',
    actual: dirOut(r02),
    pass: r02.rawFitScore == 1.0,
  );
  final r03 = evalAt(0.6);
  addScenario(
    id: '03',
    name: 'range_upper_boundary',
    purpose: 'Range target at upper boundary',
    inputSummary: 'pref[0.4,0.6] partner=0.6',
    expected: 'raw_fit == 1',
    actual: dirOut(r03),
    pass: r03.rawFitScore == 1.0,
  );
  final r04 = evalAt(0.35);
  final r05 = evalAt(0.0);
  addScenario(
    id: '04',
    name: 'slightly_below',
    purpose: 'Slightly below preferred range',
    inputSummary: 'partner=0.35',
    expected: '0 < raw_fit < 1',
    actual: dirOut(r04),
    pass: r04.rawFitScore! > 0 && r04.rawFitScore! < 1,
  );
  addScenario(
    id: '05',
    name: 'far_below',
    purpose: 'Far below preferred range',
    inputSummary: 'partner=0.0',
    expected: 'raw_fit < slightly_below',
    actual: dirOut(r05),
    pass: r05.rawFitScore! < r04.rawFitScore!,
  );
  final r06 = evalAt(0.65);
  final r07 = evalAt(1.0);
  addScenario(
    id: '06',
    name: 'slightly_above',
    purpose: 'Slightly above preferred range',
    inputSummary: 'partner=0.65',
    expected: '0 < raw_fit < 1',
    actual: dirOut(r06),
    pass: r06.rawFitScore! > 0 && r06.rawFitScore! < 1,
  );
  addScenario(
    id: '07',
    name: 'far_above',
    purpose: 'Far above preferred range',
    inputSummary: 'partner=1.0',
    expected: 'raw_fit < slightly_above',
    actual: dirOut(r07),
    pass: r07.rawFitScore! < r06.rawFitScore!,
  );

  final strict = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {dim: rangePref(dim, 0.4, 0.6, f: 0.0)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.2)},
    ),
    registry: registry,
    config: config,
  );
  final flex = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {dim: rangePref(dim, 0.4, 0.6, f: 1.0)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.2)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '08',
    name: 'strict_flexibility',
    purpose: 'Strict flexibility increases penalty',
    inputSummary: 'f=0 partner=0.2',
    expected: 'raw_fit < high_flexibility',
    actual: dirOut(strict),
    pass: strict.rawFitScore! < flex.rawFitScore!,
  );
  addScenario(
    id: '09',
    name: 'high_flexibility',
    purpose: 'High flexibility reduces penalty',
    inputSummary: 'f=1 partner=0.2',
    expected: 'raw_fit > strict',
    actual: dirOut(flex),
    pass: flex.rawFitScore! > strict.rawFitScore!,
  );

  // --- 10–12 similarity ---
  final simOwner = snap(
    id: 'A',
    measurements: {dim: meas(id: dim, score: 0.55)},
    preferences: {dim: simPref(dim)},
  );
  final s10 = prefService.evaluateDirectional(
    preferenceOwner: simOwner,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.55)},
    ),
    registry: registry,
    config: config,
  );
  final s11 = prefService.evaluateDirectional(
    preferenceOwner: simOwner,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.60)},
    ),
    registry: registry,
    config: config,
  );
  final s12 = prefService.evaluateDirectional(
    preferenceOwner: simOwner,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.95)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '10',
    name: 'similarity_identical',
    purpose: 'Similarity-to-self identical scores',
    inputSummary: 'self=0.55 partner=0.55',
    expected: 'raw_fit == 1',
    actual: dirOut(s10),
    pass: s10.rawFitScore == 1.0,
  );
  addScenario(
    id: '11',
    name: 'similarity_small_diff',
    purpose: 'Similarity-to-self small difference',
    inputSummary: 'self=0.55 partner=0.60',
    expected: 'raw_fit < 1 and > large_diff',
    actual: dirOut(s11),
    pass: s11.rawFitScore! < 1 && s11.rawFitScore! > s12.rawFitScore!,
  );
  addScenario(
    id: '12',
    name: 'similarity_large_diff',
    purpose: 'Similarity-to-self large difference',
    inputSummary: 'self=0.55 partner=0.95',
    expected: 'raw_fit < small_diff',
    actual: dirOut(s12),
    pass: s12.rawFitScore! < s11.rawFitScore!,
  );

  // --- 13–16 confidence ---
  final hiConf = evalAt(0.2, conf: 0.95);
  final loConf = evalAt(0.2, conf: 0.15);
  addScenario(
    id: '13',
    name: 'high_confidence_partner',
    purpose: 'High-confidence measured partner',
    inputSummary: 'partner score=0.2 conf=0.95',
    expected: 'evidence_q high; raw_fit defined',
    actual: dirOut(hiConf),
    pass: hiConf.evidenceConfidence! > loConf.evidenceConfidence!,
  );
  addScenario(
    id: '14',
    name: 'low_confidence_partner',
    purpose: 'Low-confidence measured partner',
    inputSummary: 'partner score=0.2 conf=0.15',
    expected: 'evidence_q lower than high-conf case',
    actual: dirOut(loConf),
    pass: loConf.evidenceConfidence! < hiConf.evidenceConfidence!,
  );
  final oneHi = evalAt(0.1, conf: 0.9);
  final oneLo = evalAt(0.1, conf: 0.2);
  addScenario(
    id: '15',
    name: 'one_dim_high_confidence',
    purpose: 'One preference dimension with high confidence',
    inputSummary: 'single dim conf=0.9 out-of-range',
    expected: 'raw_fit defined',
    actual: dirOut(oneHi),
    pass: oneHi.rawFitScore != null,
  );
  addScenario(
    id: '16',
    name: 'one_dim_low_confidence',
    purpose: 'Same one preference dimension with low confidence',
    inputSummary: 'single dim conf=0.2 same scores',
    expected: 'raw_fit unchanged; evidence_q decreases',
    actual: {
      ...dirOut(oneLo),
      'raw_fit_equal': (oneHi.rawFitScore! - oneLo.rawFitScore!).abs() < 1e-12,
      'q_decreased': oneHi.evidenceConfidence! > oneLo.evidenceConfidence!,
    },
    pass: (oneHi.rawFitScore! - oneLo.rawFitScore!).abs() < 1e-12 &&
        oneHi.evidenceConfidence! > oneLo.evidenceConfidence!,
  );

  // --- 17–18 multi-dim confidence discrepancy ---
  CompatibilitySubjectSnapshot multiOwner({required double iDisc}) => snap(
        id: 'A',
        measurements: {
          dim: meas(id: dim, score: 0.5),
          dim2: meas(id: dim2, score: 0.5),
        },
        preferences: {
          dim: rangePref(dim, 0.4, 0.6, i: iDisc),
          dim2: rangePref(dim2, 0.4, 0.6, i: 0.5),
        },
      );
  CompatibilitySubjectSnapshot multiPartner({required double confDisc}) => snap(
        id: 'B',
        measurements: {
          dim: meas(id: dim, score: 0.0, confidence: confDisc),
          dim2: meas(id: dim2, score: 0.5, confidence: 0.9),
        },
      );
  final multiHi = prefService.evaluateDirectional(
    preferenceOwner: multiOwner(iDisc: 0.9),
    evaluatedSubject: multiPartner(confDisc: 0.95),
    registry: registry,
    config: config,
  );
  final multiLo = prefService.evaluateDirectional(
    preferenceOwner: multiOwner(iDisc: 0.9),
    evaluatedSubject: multiPartner(confDisc: 0.1),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '17',
    name: 'multi_dim_high_conf_discrepancy',
    purpose: 'Multiple dimensions with one high-confidence discrepancy',
    inputSummary: 'dim discrepant conf=0.95; dim2 matched',
    expected: 'raw_fit < multi_low_conf discrepancy case',
    actual: dirOut(multiHi),
    pass: multiHi.rawFitScore! < multiLo.rawFitScore!,
  );
  addScenario(
    id: '18',
    name: 'multi_dim_low_conf_discrepancy',
    purpose: 'Multiple dimensions with one low-confidence discrepancy',
    inputSummary: 'dim discrepant conf=0.1; dim2 matched',
    expected: 'raw_fit higher than high-conf discrepancy',
    actual: dirOut(multiLo),
    pass: multiLo.rawFitScore! > multiHi.rawFitScore!,
  );

  // --- 19–24 open/unavailable/missing/nonpub/zero importance ---
  final openR = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {
        dim: PartnerDimensionPreference(
          dimensionId: dim,
          preferredMin: null,
          preferredMax: null,
          importance: null,
          flexibility: null,
          preferenceMode: PreferenceMode.open,
          source: 'explicit_user',
          explicitlyProvided: true,
          updatedAt: ts,
        ),
      },
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.9)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '19',
    name: 'explicit_open',
    purpose: 'Explicit open preference',
    inputSummary: 'mode=open',
    expected: 'null raw_fit; open listed; not scored 1/0.5',
    actual: dirOut(openR),
    pass: openR.rawFitScore == null && openR.openPreferenceIds.contains(dim),
  );

  final unavailR = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {
        dim: PartnerDimensionPreference(
          dimensionId: dim,
          preferredMin: null,
          preferredMax: null,
          importance: null,
          flexibility: null,
          preferenceMode: PreferenceMode.unavailable,
          source: 'missing',
          explicitlyProvided: false,
          updatedAt: null,
        ),
      },
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '20',
    name: 'unavailable_preference',
    purpose: 'Unavailable preference',
    inputSummary: 'mode=unavailable',
    expected: 'excluded preference_unavailable',
    actual: dirOut(unavailR),
    pass: unavailR.excludedPreferences
        .any((e) => e.reasonCode == 'preference_unavailable'),
  );

  final missPartner = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(id: 'B'),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '21',
    name: 'missing_partner_measurement',
    purpose: 'Missing partner measurement',
    inputSummary: 'B has no EQ measurement',
    expected: 'missing_partner_measurement',
    actual: dirOut(missPartner),
    pass: missPartner.excludedPreferences
        .any((e) => e.reasonCode == 'missing_partner_measurement'),
  );

  final missSelf = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      preferences: {dim: simPref(dim)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '22',
    name: 'missing_self_measurement_similarity',
    purpose: 'Missing self measurement for similarity mode',
    inputSummary: 'similarity_to_self without A measurement',
    expected: 'missing_self_measurement',
    actual: dirOut(missSelf),
    pass: missSelf.excludedPreferences
        .any((e) => e.reasonCode == 'missing_self_measurement'),
  );

  final nonPub = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {
        dim: meas(id: dim, score: 0.5, publishability: false),
      },
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '23',
    name: 'non_publishable_partner',
    purpose: 'Non-publishable partner measurement',
    inputSummary: 'publishability=false',
    expected: 'non_publishable_partner_measurement',
    actual: dirOut(nonPub),
    pass: nonPub.excludedPreferences
        .any((e) => e.reasonCode == 'non_publishable_partner_measurement'),
  );

  final zeroImp = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {dim: rangePref(dim, 0.4, 0.6, i: 0.0)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '24',
    name: 'zero_importance',
    purpose: 'Zero importance',
    inputSummary: 'importance=0',
    expected: 'zero_importance; null raw_fit',
    actual: dirOut(zeroImp),
    pass: zeroImp.rawFitScore == null &&
        zeroImp.excludedPreferences
            .any((e) => e.reasonCode == 'zero_importance'),
  );

  // --- 25–30 mutual / directions ---
  final aOnly = snap(
    id: 'A',
    measurements: {dim: meas(id: dim, score: 0.5)},
    preferences: {dim: rangePref(dim, 0.4, 0.6)},
  );
  final bNoPref = snap(
    id: 'B',
    measurements: {dim: meas(id: dim, score: 0.5)},
  );
  final oneWay = prefService.evaluateMutual(
    subjectA: aOnly,
    subjectB: bNoPref,
    registry: registry,
    config: config,
  );
  addScenario(
    id: '25',
    name: 'one_way_directional_only',
    purpose: 'One-way directional fit only',
    inputSummary: 'A has prefs; B has none',
    expected: 'mutual null; A<-B available',
    actual: {
      'mutual': oneWay.mutualRawFitScore,
      'A_to_B': oneWay.subjectAToBResult.rawFitScore,
      'B_to_A': oneWay.subjectBToAResult.rawFitScore,
    },
    pass: oneWay.mutualRawFitScore == null &&
        oneWay.subjectAToBResult.rawFitScore != null,
  );

  final aStrong = snap(
    id: 'A',
    measurements: {dim: meas(id: dim, score: 0.5)},
    preferences: {dim: rangePref(dim, 0.4, 0.6)},
  );
  final bWeak = snap(
    id: 'B',
    measurements: {dim: meas(id: dim, score: 0.5)},
    preferences: {dim: rangePref(dim, 0.8, 1.0)},
  );
  final m26 = prefService.evaluateMutual(
    subjectA: aStrong,
    subjectB: bWeak,
    registry: registry,
    config: config,
  );
  addScenario(
    id: '26',
    name: 'strong_A_weak_B',
    purpose: 'Strong A<-B and weak B<-A',
    inputSummary: 'A wants mid; B wants high; both measured mid',
    expected: 'A_to_B > B_to_A; mutual = geometric mean',
    actual: {
      'A_to_B': m26.subjectAToBResult.rawFitScore,
      'B_to_A': m26.subjectBToAResult.rawFitScore,
      'mutual': m26.mutualRawFitScore,
      'asymmetry': m26.directionalAsymmetry,
    },
    pass: m26.subjectAToBResult.rawFitScore! >
            m26.subjectBToAResult.rawFitScore! &&
        (m26.mutualRawFitScore! -
                    math.sqrt(m26.subjectAToBResult.rawFitScore! *
                        m26.subjectBToAResult.rawFitScore!))
                .abs() <
            1e-12,
  );

  final m27 = prefService.evaluateMutual(
    subjectA: bWeak,
    subjectB: aStrong,
    registry: registry,
    config: config,
  );
  addScenario(
    id: '27',
    name: 'weak_A_strong_B',
    purpose: 'Weak A<-B and strong B<-A',
    inputSummary: 'roles swapped vs 26',
    expected: 'A_to_B < B_to_A',
    actual: {
      'A_to_B': m27.subjectAToBResult.rawFitScore,
      'B_to_A': m27.subjectBToAResult.rawFitScore,
      'mutual': m27.mutualRawFitScore,
    },
    pass:
        m27.subjectAToBResult.rawFitScore! < m27.subjectBToAResult.rawFitScore!,
  );

  final bothStrong = prefService.evaluateMutual(
    subjectA: aStrong,
    subjectB: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {dim: rangePref(dim, 0.4, 0.6)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '28',
    name: 'both_directions_strong',
    purpose: 'Both directions strong',
    inputSummary: 'both prefer mid; both measured mid',
    expected: 'both near 1; mutual near 1',
    actual: {
      'A_to_B': bothStrong.subjectAToBResult.rawFitScore,
      'B_to_A': bothStrong.subjectBToAResult.rawFitScore,
      'mutual': bothStrong.mutualRawFitScore,
    },
    pass: bothStrong.subjectAToBResult.rawFitScore! > 0.99 &&
        bothStrong.subjectBToAResult.rawFitScore! > 0.99,
  );

  final bothWeak = prefService.evaluateMutual(
    subjectA: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.0)},
      preferences: {dim: rangePref(dim, 0.8, 1.0)},
    ),
    subjectB: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.0)},
      preferences: {dim: rangePref(dim, 0.8, 1.0)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '29',
    name: 'both_directions_weak',
    purpose: 'Both directions weak',
    inputSummary: 'both prefer high; both measured 0',
    expected: 'both raw_fit low',
    actual: {
      'A_to_B': bothWeak.subjectAToBResult.rawFitScore,
      'B_to_A': bothWeak.subjectBToAResult.rawFitScore,
      'mutual': bothWeak.mutualRawFitScore,
    },
    pass: bothWeak.subjectAToBResult.rawFitScore! < 0.5 &&
        bothWeak.subjectBToAResult.rawFitScore! < 0.5,
  );

  final rev = prefService.evaluateMutual(
    subjectA: bWeak,
    subjectB: aStrong,
    registry: registry,
    config: config,
  );
  addScenario(
    id: '30',
    name: 'pair_input_reversed',
    purpose: 'Pair input reversed',
    inputSummary: 'reverse of scenario 26 pair',
    expected: 'mutual/asymmetry/fingerprint invariant',
    actual: {
      'mutual_equal': m26.mutualRawFitScore == rev.mutualRawFitScore,
      'asymmetry_equal': m26.directionalAsymmetry == rev.directionalAsymmetry,
      'fingerprint_equal':
          m26.deterministicFingerprint == rev.deterministicFingerprint,
      'directions_swapped': m26.subjectAToBResult.rawFitScore ==
          rev.subjectBToAResult.rawFitScore,
    },
    pass: m26.mutualRawFitScore == rev.mutualRawFitScore &&
        m26.directionalAsymmetry == rev.directionalAsymmetry &&
        m26.deterministicFingerprint == rev.deterministicFingerprint,
  );

  // --- 31 map order ---
  final orderedPrefs = {
    dim: rangePref(dim, 0.4, 0.6, i: 0.9),
    dim2: rangePref(dim2, 0.4, 0.6, i: 0.5),
  };
  final shuffledPrefs = {
    dim2: rangePref(dim2, 0.4, 0.6, i: 0.5),
    dim: rangePref(dim, 0.4, 0.6, i: 0.9),
  };
  final mapA = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {
        dim: meas(id: dim, score: 0.5),
        dim2: meas(id: dim2, score: 0.5),
      },
      preferences: orderedPrefs,
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {
        dim: meas(id: dim, score: 0.2),
        dim2: meas(id: dim2, score: 0.5),
      },
    ),
    registry: registry,
    config: config,
  );
  final mapB = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {
        dim2: meas(id: dim2, score: 0.5),
        dim: meas(id: dim, score: 0.5),
      },
      preferences: shuffledPrefs,
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {
        dim2: meas(id: dim2, score: 0.5),
        dim: meas(id: dim, score: 0.2),
      },
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '31',
    name: 'map_order_shuffled',
    purpose: 'Map order shuffled',
    inputSummary: 'preference/measurement insert order reversed',
    expected: 'same raw_fit and fingerprint',
    actual: {
      'fit_a': mapA.rawFitScore,
      'fit_b': mapB.rawFitScore,
      'fp_equal':
          mapA.deterministicFingerprint == mapB.deterministicFingerprint,
    },
    pass: mapA.rawFitScore == mapB.rawFitScore &&
        mapA.deterministicFingerprint == mapB.deterministicFingerprint,
  );

  // --- 32 24-dim ---
  final cfg24 = PartnerPreferenceFitConfig.fromJson({
    ...config.toJson(),
    'registry_version': fixture24.registryVersion,
  });
  final d24 = fixture24.dimsForModule(AssessmentModuleId.eq).first.dimensionId;
  final r32 = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      reg: fixture24,
      measurements: {
        d24: meas(
          id: d24,
          score: 0.5,
          registryVersion: fixture24.registryVersion,
        ),
      },
      preferences: {d24: rangePref(d24, 0.4, 0.6)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      reg: fixture24,
      measurements: {
        d24: meas(
          id: d24,
          score: 0.5,
          registryVersion: fixture24.registryVersion,
        ),
      },
    ),
    registry: fixture24,
    config: cfg24,
  );
  addScenario(
    id: '32',
    name: 'registry_24d',
    purpose: '24-dimension registry',
    inputSummary: 'fixture registry with 24 entries',
    expected: 'raw_fit == 1 without service code changes',
    actual: dirOut(r32),
    pass: r32.rawFitScore == 1.0 && fixture24.dimensions.length == 24,
  );

  // --- 33–39 invalid / mismatch ---
  final invalidScore = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 1.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '33',
    name: 'invalid_score',
    purpose: 'Invalid score',
    inputSummary: 'partner score=1.5',
    expected: 'invalid_partner_score',
    actual: dirOut(invalidScore),
    pass: invalidScore.excludedPreferences
        .any((e) => e.reasonCode == 'invalid_partner_score'),
  );

  // Invalid importance: construct preference that fails domain validate if
  // parsed normally; service eligibility catches out-of-bounds if present.
  // Use importance > 1 via direct construction (bypass profile validate path).
  final badImpPref = PartnerDimensionPreference(
    dimensionId: dim,
    preferredMin: 0.4,
    preferredMax: 0.6,
    importance: 1.5,
    flexibility: 0.5,
    preferenceMode: PreferenceMode.range,
    source: 'explicit_user',
    explicitlyProvided: true,
    updatedAt: ts,
  );
  final invalidImp = prefService.evaluateDirectional(
    preferenceOwner: CompatibilitySubjectSnapshot(
      subjectId: 'A',
      assessmentProfile: ownerMid.assessmentProfile,
      partnerPreferenceProfile: PartnerPreferenceProfile(
        preferences: {dim: badImpPref},
        profileVersion: 'v1',
        registryVersion: registry.registryVersion,
        createdAt: ts,
        updatedAt: ts,
        completionStatus: PreferenceProfileCompletionStatus.partial,
        explicitlyAnsweredDimensions: [dim],
        openDimensions: const [],
        unavailableDimensions: const [],
      ),
      relationshipValueProfile: ownerMid.relationshipValueProfile,
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: ts,
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '34',
    name: 'invalid_importance',
    purpose: 'Invalid importance',
    inputSummary: 'importance=1.5',
    expected: 'invalid_importance',
    actual: dirOut(invalidImp),
    pass: invalidImp.excludedPreferences
        .any((e) => e.reasonCode == 'invalid_importance'),
  );

  final badFlexPref = PartnerDimensionPreference(
    dimensionId: dim,
    preferredMin: 0.4,
    preferredMax: 0.6,
    importance: 0.8,
    flexibility: -0.1,
    preferenceMode: PreferenceMode.range,
    source: 'explicit_user',
    explicitlyProvided: true,
    updatedAt: ts,
  );
  final invalidFlex = prefService.evaluateDirectional(
    preferenceOwner: CompatibilitySubjectSnapshot(
      subjectId: 'A',
      assessmentProfile: ownerMid.assessmentProfile,
      partnerPreferenceProfile: PartnerPreferenceProfile(
        preferences: {dim: badFlexPref},
        profileVersion: 'v1',
        registryVersion: registry.registryVersion,
        createdAt: ts,
        updatedAt: ts,
        completionStatus: PreferenceProfileCompletionStatus.partial,
        explicitlyAnsweredDimensions: [dim],
        openDimensions: const [],
        unavailableDimensions: const [],
      ),
      relationshipValueProfile: ownerMid.relationshipValueProfile,
      hardConstraints: const [],
      snapshotVersion: 'v1',
      createdAt: ts,
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '35',
    name: 'invalid_flexibility',
    purpose: 'Invalid flexibility',
    inputSummary: 'flexibility=-0.1',
    expected: 'invalid_flexibility',
    actual: dirOut(invalidFlex),
    pass: invalidFlex.excludedPreferences
        .any((e) => e.reasonCode == 'invalid_flexibility'),
  );

  final nanR = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: double.nan)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '36',
    name: 'nan_rejection',
    purpose: 'NaN rejection',
    inputSummary: 'partner score=NaN',
    expected: 'invalid_partner_score',
    actual: dirOut(nanR),
    pass: nanR.excludedPreferences
        .any((e) => e.reasonCode == 'invalid_partner_score'),
  );

  final infR = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {
        dim: meas(id: dim, score: 0.5, confidence: double.infinity),
      },
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '37',
    name: 'infinity_rejection',
    purpose: 'Infinity rejection',
    inputSummary: 'partner confidence=+inf',
    expected: 'invalid_partner_confidence',
    actual: dirOut(infR),
    pass: infR.excludedPreferences
        .any((e) => e.reasonCode == 'invalid_partner_confidence'),
  );

  Object? registryMismatchResult;
  var registryMismatchPass = false;
  try {
    prefService.evaluateDirectional(
      preferenceOwner: ownerMid,
      evaluatedSubject: snap(
        id: 'B',
        measurements: {dim: meas(id: dim, score: 0.5)},
      ),
      registry: registry,
      config: PartnerPreferenceFitConfig.fromJson({
        ...config.toJson(),
        'registry_version': 'wrong_registry',
      }),
    );
    registryMismatchResult = 'did_not_throw';
  } catch (e) {
    registryMismatchResult = e.runtimeType.toString();
    registryMismatchPass = true;
  }
  addScenario(
    id: '38',
    name: 'registry_mismatch',
    purpose: 'Registry mismatch',
    inputSummary: 'config.registry_version != registry',
    expected: 'throws validation error',
    actual: {'threw': registryMismatchResult},
    pass: registryMismatchPass,
  );

  final scoringMismatch = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {
        dim: meas(id: dim, score: 0.55, scoring: 'contract_a'),
      },
      preferences: {dim: simPref(dim)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {
        dim: meas(id: dim, score: 0.55, scoring: 'contract_b'),
      },
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '39',
    name: 'scoring_contract_mismatch',
    purpose: 'Scoring-contract mismatch',
    inputSummary: 'similarity mode with differing scoring contracts',
    expected: 'scoring_contract_mismatch',
    actual: dirOut(scoringMismatch),
    pass: scoringMismatch.excludedPreferences
        .any((e) => e.reasonCode == 'scoring_contract_mismatch'),
  );

  // --- 40–41 structural vs preference separation (no aggregation) ---
  CanonicalUserAssessmentProfile fullUniform(double score) {
    ModuleAssessmentProfile mod(AssessmentModuleId m, double s) {
      final dims = registry.dimsForModule(m);
      return ModuleAssessmentProfile(
        module: m,
        measurements: {
          for (final d in dims)
            d.dimensionId: DimensionMeasurement(
              dimensionId: d.dimensionId,
              module: m,
              normalizedScore: s,
              confidence: 0.8,
              uncertainty: 0.2,
              primaryEvidenceCount: 2,
              secondaryEvidenceCount: 1,
              independentContextCount: 2,
              publicationStatus: DimensionPublicationStatus.published,
              publishability: true,
              sourceContentVersions: const ['sim'],
              measurementTimestamp: ts,
              scoringContractVersion: 'trait_scoring_config_v1',
              registryVersion: registry.registryVersion,
            ),
        },
        assessmentFormId: m.wire,
        contentVersion: 'sim',
        scoringContractVersion: 'trait_scoring_config_v1',
        completionStatus: ModuleCompletionStatus.complete,
        completedAt: ts,
        moduleConfidence: 0.8,
        evidenceCoverage: 1,
        unavailableDimensions: const [],
        validationIssues: const [],
        registryVersion: registry.registryVersion,
      );
    }

    final iq = mod(AssessmentModuleId.iq, score);
    final eq = mod(AssessmentModuleId.eq, score);
    final fr = mod(AssessmentModuleId.frequency, score);
    return CanonicalUserAssessmentProfile(
      snapshotId: 's',
      profileSchemaVersion: 'v1',
      registryVersion: registry.registryVersion,
      iq: iq,
      eq: eq,
      frequency: fr,
      publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
        iq: iq,
        eq: eq,
        frequency: fr,
      ),
      unavailableDimensions: const [],
      createdAt: ts,
      updatedAt: ts,
      sourceAssessmentVersions: const ['sim'],
      overallAssessmentCoverage: 1,
      profileReadinessStatus: ProfileReadinessStatus.provisional,
    );
  }

  final structHigh = structService.compare(
    subjectA: fullUniform(0.5),
    subjectB: fullUniform(0.5),
    registry: registry,
    config: structCfg,
    evaluationTimestamp: ts,
  );
  final prefLow = prefService.evaluateDirectional(
    preferenceOwner: snap(
      id: 'A',
      measurements: {dim: meas(id: dim, score: 0.5)},
      preferences: {dim: rangePref(dim, 0.9, 1.0)},
    ),
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '40',
    name: 'high_structural_low_preference',
    purpose: 'High structural similarity with low preference fit',
    inputSummary: 'independent structural + preference evaluations',
    expected: 'structural high AND preference low; not aggregated',
    actual: {
      'structural_eq_similarity': structHigh.eq?.similarityScore,
      'preference_raw_fit': prefLow.rawFitScore,
      'aggregated': false,
    },
    pass: (structHigh.eq?.similarityScore ?? 0) > 0.99 &&
        (prefLow.rawFitScore ?? 1) < 0.5,
  );

  final structLow = structService.compare(
    subjectA: fullUniform(0.0),
    subjectB: fullUniform(1.0),
    registry: registry,
    config: structCfg,
    evaluationTimestamp: ts,
  );
  final prefHigh = prefService.evaluateDirectional(
    preferenceOwner: ownerMid,
    evaluatedSubject: snap(
      id: 'B',
      measurements: {dim: meas(id: dim, score: 0.5)},
    ),
    registry: registry,
    config: config,
  );
  addScenario(
    id: '41',
    name: 'low_structural_high_preference',
    purpose: 'Low structural similarity with high preference fit',
    inputSummary: 'independent structural + preference evaluations',
    expected: 'structural low AND preference high; not aggregated',
    actual: {
      'structural_eq_similarity': structLow.eq?.similarityScore,
      'preference_raw_fit': prefHigh.rawFitScore,
      'aggregated': false,
    },
    pass: (structLow.eq?.similarityScore ?? 1) < 0.05 &&
        prefHigh.rawFitScore == 1.0,
  );

  scenarios.sort((a, b) => a['id']!.toString().compareTo(b['id']!.toString()));
  final ids = [for (final s in scenarios) s['id']!.toString()];
  final passed = scenarios.where((s) => s['pass'] == true).length;
  final failed = scenarios.where((s) => s['pass'] != true).length;

  final fingerprintPayload = cmSortedMap({
    'scenario_ids': ids,
    'pass_flags': [for (final s in scenarios) s['pass']],
    'actuals': [for (final s in scenarios) s['actual_outcome']],
  });
  final encoded = jsonEncode(fingerprintPayload);
  var hash = 0xcbf29ce484222325;
  for (final unit in encoded.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  final fingerprint = hash.toRadixString(16).padLeft(16, '0');

  final report = cmSortedMap({
    'simulator': 'simulate_directional_preference_fit_v1',
    'phase': 'P2B-2.1',
    'status': failed == 0 ? 'COMPLETE' : 'FAILED',
    'synthetic_only': true,
    'not_real_personalities': true,
    'config_version': config.configVersion,
    'registry_version': registry.registryVersion,
    'scenario_count': scenarios.length,
    'scenario_ids': ids,
    'passed_count': passed,
    'failed_count': failed,
    'deterministic_fingerprint': fingerprint,
    'scenarios': scenarios,
  });

  Directory('$root/tool/core_method_v2_out').createSync(recursive: true);
  File('$root/$outPath').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );
  stdout.writeln(jsonEncode({
    'status': report['status'],
    'scenario_count': scenarios.length,
    'passed_count': passed,
    'failed_count': failed,
    'report': '$root/$outPath',
  }));
  exit(failed == 0 ? 0 : 1);
}
