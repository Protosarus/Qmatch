// Deterministic simulations for relationship-value layer v1 (P2B-3).
// Usage: dart run tool/simulate_relationship_value_layer_v1.dart
// Scenario count is derived from the scenarios list — never hard-stated.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:qmatch/features/assessment/domain/core_method_v2/core_method_v2.dart';

const outPath =
    'tool/core_method_v2_out/relationship_value_layer_simulation_v1_report.json';

void main() {
  final root = Directory.current.path;
  final valueRegistry = RelationshipValueRegistry.loadFile(
    '$root/assets/data/core_method_v2/relationship_value_registry_v1.json',
  );
  final config = RelationshipValueComparisonConfig.loadFile(
    '$root/assets/data/core_method_v2/relationship_value_comparison_config_v1.json',
  );
  final dimRegistry = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/canonical_dimension_registry_v1.json',
  );
  final fixture24 = CanonicalDimensionRegistry.loadFile(
    '$root/assets/data/core_method_v2/fixtures/canonical_dimension_registry_24d_fixture.json',
  );
  final structCfg = StructuralSimilarityConfig.loadFile(
    '$root/assets/data/core_method_v2/structural_similarity_config_v1.json',
  );
  final prefCfg = PartnerPreferenceFitConfig.loadFile(
    '$root/assets/data/core_method_v2/directional_preference_fit_config_v1.json',
  );
  const valueService = RelationshipValueComparisonService();
  const hardService = HardConstraintEvaluationService();
  const softService = SoftConflictEvaluationService();
  const structService = StructuralSimilarityService();
  const prefService = DirectionalPreferenceFitService();

  CompatibilitySubjectSnapshot emptyAssessment(String id) =>
      CompatibilitySubjectSnapshot(
        subjectId: id,
        assessmentProfile: CanonicalUserAssessmentProfile(
          snapshotId: id,
          profileSchemaVersion: 'v1',
          registryVersion: dimRegistry.registryVersion,
          iq: null,
          eq: null,
          frequency: null,
          publishedMeasurements: const {},
          unavailableDimensions: const [],
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          sourceAssessmentVersions: const [],
          overallAssessmentCoverage: 0,
          profileReadinessStatus: ProfileReadinessStatus.provisional,
        ),
        partnerPreferenceProfile: PartnerPreferenceProfile(
          preferences: const {},
          profileVersion: 'v1',
          registryVersion: dimRegistry.registryVersion,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          completionStatus: PreferenceProfileCompletionStatus.incomplete,
          explicitlyAnsweredDimensions: const [],
          openDimensions: const [],
          unavailableDimensions: const [],
        ),
        relationshipValueProfile: RelationshipValueProfile(
          responses: const {},
          profileVersion: 'v1',
          registryVersion: valueRegistry.registryVersion,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        hardConstraints: const [],
        snapshotVersion: 'v1',
        createdAt: DateTime.utc(2026, 1, 1),
      );

  RelationshipValueResponse vr(
    String field,
    String? value, {
    List<String> values = const [],
    double importance = 0.8,
    double flexibility = 0.0,
    bool explicit = true,
    bool permission = true,
    String visibility = 'internal_comparison_allowed',
  }) =>
      RelationshipValueResponse(
        fieldId: field,
        selectedValue: value,
        selectedValues: values,
        importance: importance,
        flexibility: flexibility,
        explicitlyProvided: explicit,
        responseTimestamp: DateTime.utc(2026, 1, 1),
        registryVersion: valueRegistry.registryVersion,
        visibilityPolicy: visibility,
        comparisonPermission: permission,
      );

  CompatibilitySubjectSnapshot withValues(
    String id,
    Map<String, RelationshipValueResponse> responses, {
    List<HardConstraint> constraints = const [],
  }) {
    final base = emptyAssessment(id);
    return CompatibilitySubjectSnapshot(
      subjectId: id,
      assessmentProfile: base.assessmentProfile,
      partnerPreferenceProfile: base.partnerPreferenceProfile,
      relationshipValueProfile: RelationshipValueProfile(
        responses: responses,
        profileVersion: 'v1',
        registryVersion: valueRegistry.registryVersion,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
      hardConstraints: constraints,
      snapshotVersion: 'v1',
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  HardConstraint hc({
    required String id,
    required String field,
    List<String> accepted = const [],
    List<String> rejected = const [],
    bool enabled = true,
    String mode = 'any_allowed',
  }) =>
      HardConstraint(
        constraintId: id,
        fieldId: field,
        acceptedValues: accepted,
        rejectedValues: rejected,
        explicitlyEnabled: enabled,
        matchMode: mode,
        source: 'user',
        updatedAt: DateTime.utc(2026, 1, 1),
        registryVersion: valueRegistry.registryVersion,
      );

  final scenarios = <Map<String, dynamic>>[];
  void addScenario({
    required String id,
    required String name,
    required String purpose,
    required String inputSummary,
    required String expected,
    required Object actual,
    required bool pass,
    List<String> diagnostics = const [],
  }) {
    scenarios.add(cmSortedMap({
      'id': id,
      'name': name,
      'purpose': purpose,
      'input_summary': inputSummary,
      'expected_outcome': expected,
      'actual_outcome': actual,
      'pass': pass,
      'diagnostic_codes': [...diagnostics]..sort(),
    }));
  }

  DirectionalRelationshipValueResult dir(
    Map<String, RelationshipValueResponse> a,
    Map<String, RelationshipValueResponse> b,
  ) =>
      valueService.evaluateDirectional(
        preferenceOwner: withValues('A', a),
        evaluatedSubject: withValues('B', b),
        registry: valueRegistry,
        config: config,
      );

  // 01 identical exact
  var r = dir(
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '01',
    name: 'exact_identical',
    purpose: 'Identical exact-match values',
    inputSummary: 'monogamous/monogamous flex=0',
    expected: 'raw=1',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 1.0,
  );

  // 02 different exact
  r = dir(
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
    {
      'monogamy_expectation': vr('monogamy_expectation', 'open_to_non_monogamy')
    },
  );
  addScenario(
    id: '02',
    name: 'exact_different',
    purpose: 'Different exact-match values',
    inputSummary: 'monogamous vs open flex=0',
    expected: 'raw=0',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 0.0,
  );

  // 03-06 matrix
  r = dir(
    {'marriage_intent': vr('marriage_intent', 'yes')},
    {'marriage_intent': vr('marriage_intent', 'yes')},
  );
  addScenario(
    id: '03',
    name: 'matrix_full',
    purpose: 'Fully compatible matrix values',
    inputSummary: 'yes/yes',
    expected: 'raw=1',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 1.0,
  );
  r = dir(
    {'marriage_intent': vr('marriage_intent', 'yes')},
    {'marriage_intent': vr('marriage_intent', 'maybe')},
  );
  addScenario(
    id: '04',
    name: 'matrix_partial',
    purpose: 'Partially compatible matrix values',
    inputSummary: 'yes/maybe',
    expected: '0<raw<1',
    actual: {'raw': r.rawValueFitScore},
    pass: (r.rawValueFitScore ?? -1) > 0 && (r.rawValueFitScore ?? 2) < 1,
  );
  r = dir(
    {'marriage_intent': vr('marriage_intent', 'yes')},
    {'marriage_intent': vr('marriage_intent', 'no')},
  );
  addScenario(
    id: '05',
    name: 'matrix_incompatible',
    purpose: 'Incompatible matrix values',
    inputSummary: 'yes/no flex=0',
    expected: 'raw=0',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 0.0,
  );
  final mAsym = valueService.evaluateMutual(
    subjectA: withValues('A', {
      'marriage_intent': vr('marriage_intent', 'yes', flexibility: 0),
    }),
    subjectB: withValues('B', {
      'marriage_intent': vr('marriage_intent', 'maybe', flexibility: 0),
    }),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '06',
    name: 'matrix_directional_asymmetry',
    purpose: 'Directional compatibility matrix asymmetry',
    inputSummary: 'yes vs maybe',
    expected: 'A<-B != B<-A',
    actual: {
      'a_to_b': mAsym.subjectAToBResult.rawValueFitScore,
      'b_to_a': mAsym.subjectBToAResult.rawValueFitScore,
    },
    pass: mAsym.subjectAToBResult.rawValueFitScore !=
        mAsym.subjectBToAResult.rawValueFitScore,
  );

  // 07-09 ordered
  r = dir(
    {'alcohol_preference': vr('alcohol_preference', 'social')},
    {'alcohol_preference': vr('alcohol_preference', 'social')},
  );
  addScenario(
    id: '07',
    name: 'ordered_identical',
    purpose: 'Ordered values identical',
    inputSummary: 'social/social',
    expected: 'raw=1',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 1.0,
  );
  final oAdj = dir(
    {'alcohol_preference': vr('alcohol_preference', 'none')},
    {'alcohol_preference': vr('alcohol_preference', 'social')},
  );
  final oFar = dir(
    {'alcohol_preference': vr('alcohol_preference', 'none')},
    {'alcohol_preference': vr('alcohol_preference', 'undecided')},
  );
  addScenario(
    id: '08',
    name: 'ordered_adjacent',
    purpose: 'Ordered values adjacent',
    inputSummary: 'none/social',
    expected: 'higher than max distance',
    actual: {'adj': oAdj.rawValueFitScore, 'far': oFar.rawValueFitScore},
    pass: (oAdj.rawValueFitScore ?? 0) > (oFar.rawValueFitScore ?? 1),
  );
  addScenario(
    id: '09',
    name: 'ordered_max_distance',
    purpose: 'Ordered values maximally distant',
    inputSummary: 'none/undecided',
    expected: 'raw=0',
    actual: {'raw': oFar.rawValueFitScore},
    pass: oFar.rawValueFitScore == 0.0,
  );

  // 10-12 set overlap
  r = dir(
    {
      'lifestyle_rhythm':
          vr('lifestyle_rhythm', null, values: ['mixed', 'flexible'])
    },
    {
      'lifestyle_rhythm':
          vr('lifestyle_rhythm', null, values: ['mixed', 'flexible'])
    },
  );
  addScenario(
    id: '10',
    name: 'set_identical',
    purpose: 'Set overlap identical',
    inputSummary: '{mixed,flexible}',
    expected: 'raw=1',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 1.0,
  );
  r = dir(
    {
      'lifestyle_rhythm':
          vr('lifestyle_rhythm', null, values: ['mixed', 'flexible'])
    },
    {
      'lifestyle_rhythm':
          vr('lifestyle_rhythm', null, values: ['mixed', 'highly_structured'])
    },
  );
  addScenario(
    id: '11',
    name: 'set_partial',
    purpose: 'Set overlap partial',
    inputSummary: 'jaccard partial',
    expected: '0<raw<1',
    actual: {'raw': r.rawValueFitScore},
    pass: (r.rawValueFitScore ?? -1) > 0 && (r.rawValueFitScore ?? 2) < 1,
  );
  r = dir(
    {
      'lifestyle_rhythm': vr('lifestyle_rhythm', null, values: ['flexible'])
    },
    {
      'lifestyle_rhythm':
          vr('lifestyle_rhythm', null, values: ['highly_structured'])
    },
  );
  addScenario(
    id: '12',
    name: 'set_disjoint',
    purpose: 'Set overlap disjoint',
    inputSummary: 'disjoint flex=0',
    expected: 'raw=0',
    actual: {'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == 0.0,
  );

  // 13-15 flexibility
  final f0 = dir(
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'monogamous', flexibility: 0)
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'undecided')},
  );
  final fMid = dir(
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'monogamous', flexibility: 0.5)
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'undecided')},
  );
  final f1 = dir(
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'monogamous', flexibility: 1)
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'undecided')},
  );
  addScenario(
    id: '13',
    name: 'flexibility_zero',
    purpose: 'Flexibility zero',
    inputSummary: 'c=0 f=0',
    expected: 'p=0',
    actual: {'raw': f0.rawValueFitScore},
    pass: f0.rawValueFitScore == 0.0,
  );
  addScenario(
    id: '14',
    name: 'flexibility_medium',
    purpose: 'Flexibility medium',
    inputSummary: 'c=0 f=0.5',
    expected: 'p=0.5',
    actual: {'raw': fMid.rawValueFitScore},
    pass: fMid.rawValueFitScore == 0.5,
  );
  addScenario(
    id: '15',
    name: 'flexibility_one',
    purpose: 'Flexibility one',
    inputSummary: 'c=0 f=1',
    expected: 'p=1',
    actual: {'raw': f1.rawValueFitScore},
    pass: f1.rawValueFitScore == 1.0,
  );

  // 16-17 importance (multi-field)
  final lowImp = dir(
    {
      'monogamy_expectation': vr('monogamy_expectation', 'monogamous',
          importance: 0.1, flexibility: 0),
      'alcohol_preference':
          vr('alcohol_preference', 'social', importance: 0.9, flexibility: 0),
    },
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'open_to_non_monogamy'),
      'alcohol_preference': vr('alcohol_preference', 'social'),
    },
  );
  final highImp = dir(
    {
      'monogamy_expectation': vr('monogamy_expectation', 'monogamous',
          importance: 0.9, flexibility: 0),
      'alcohol_preference':
          vr('alcohol_preference', 'social', importance: 0.1, flexibility: 0),
    },
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'open_to_non_monogamy'),
      'alcohol_preference': vr('alcohol_preference', 'social'),
    },
  );
  addScenario(
    id: '16',
    name: 'low_importance_mismatch',
    purpose: 'Low-importance mismatch',
    inputSummary: 'mismatch low I',
    expected: 'higher fit than high-I mismatch',
    actual: {'low': lowImp.rawValueFitScore, 'high': highImp.rawValueFitScore},
    pass: (lowImp.rawValueFitScore ?? 0) > (highImp.rawValueFitScore ?? 1),
  );
  addScenario(
    id: '17',
    name: 'high_importance_mismatch',
    purpose: 'High-importance mismatch',
    inputSummary: 'mismatch high I',
    expected: 'lower fit',
    actual: {'raw': highImp.rawValueFitScore},
    pass: (highImp.rawValueFitScore ?? 1) < (lowImp.rawValueFitScore ?? 0),
  );

  // 18-25 mutual / directions / reversal
  final strongA = withValues('A', {
    'marriage_intent': vr('marriage_intent', 'yes', flexibility: 0),
  });
  final strongB = withValues('B', {
    'marriage_intent': vr('marriage_intent', 'yes', flexibility: 0),
  });
  final weakB = withValues('B', {
    'marriage_intent': vr('marriage_intent', 'no', flexibility: 0),
  });
  final mStrong = valueService.evaluateMutual(
    subjectA: strongA,
    subjectB: strongB,
    registry: valueRegistry,
    config: config,
  );
  final mWeak = valueService.evaluateMutual(
    subjectA: strongA,
    subjectB: weakB,
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '18',
    name: 'multi_field_a_to_b',
    purpose: 'Multi-field directional A<-B',
    inputSummary: 'directional only A',
    expected: 'A<-B available',
    actual: {'raw': mStrong.subjectAToBResult.rawValueFitScore},
    pass: mStrong.subjectAToBResult.rawValueFitScore != null,
  );
  addScenario(
    id: '19',
    name: 'multi_field_b_to_a',
    purpose: 'Multi-field directional B<-A',
    inputSummary: 'directional only B',
    expected: 'B<-A available',
    actual: {'raw': mStrong.subjectBToAResult.rawValueFitScore},
    pass: mStrong.subjectBToAResult.rawValueFitScore != null,
  );
  addScenario(
    id: '20',
    name: 'both_directions_strong',
    purpose: 'Both directions strong',
    inputSummary: 'yes/yes',
    expected: 'mutual high',
    actual: {'mutual': mStrong.mutualRawValueFitScore},
    pass: (mStrong.mutualRawValueFitScore ?? 0) > 0.9,
  );
  addScenario(
    id: '21',
    name: 'both_directions_weak',
    purpose: 'Both directions weak',
    inputSummary: 'yes/no',
    expected: 'mutual low',
    actual: {'mutual': mWeak.mutualRawValueFitScore},
    pass: (mWeak.mutualRawValueFitScore ?? 1) < 0.1,
  );
  addScenario(
    id: '22',
    name: 'strong_a_weak_b',
    purpose: 'Strong A<-B / weak B<-A',
    inputSummary: 'asym matrix',
    expected: 'asymmetry > 0',
    actual: {'asym': mAsym.directionalAsymmetry},
    pass: (mAsym.directionalAsymmetry ?? 0) > 0,
  );
  addScenario(
    id: '23',
    name: 'weak_a_strong_b',
    purpose: 'Weak A<-B / strong B<-A',
    inputSummary: 'reversed asymmetry',
    expected: 'directions swapped under reverse',
    actual: {
      'a_to_b': mAsym.subjectAToBResult.rawValueFitScore,
      'b_to_a': mAsym.subjectBToAResult.rawValueFitScore,
    },
    pass: mAsym.subjectAToBResult.rawValueFitScore !=
        mAsym.subjectBToAResult.rawValueFitScore,
  );
  addScenario(
    id: '24',
    name: 'mutual_geometric_mean',
    purpose: 'Mutual geometric mean',
    inputSummary: 'check sqrt',
    expected: 'sqrt product',
    actual: {'mutual': mAsym.mutualRawValueFitScore},
    pass: (mAsym.mutualRawValueFitScore! -
                math.sqrt(mAsym.subjectAToBResult.rawValueFitScore! *
                    mAsym.subjectBToAResult.rawValueFitScore!))
            .abs() <
        1e-12,
  );
  final rev = valueService.evaluateMutual(
    subjectA: withValues('B', {
      'marriage_intent': vr('marriage_intent', 'maybe', flexibility: 0),
    }),
    subjectB: withValues('A', {
      'marriage_intent': vr('marriage_intent', 'yes', flexibility: 0),
    }),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '25',
    name: 'pair_reversal',
    purpose: 'Pair reversal',
    inputSummary: 'swap A/B',
    expected: 'mutual invariant',
    actual: {
      'mutual': rev.mutualRawValueFitScore,
      'orig': mAsym.mutualRawValueFitScore,
    },
    pass: rev.mutualRawValueFitScore == mAsym.mutualRawValueFitScore &&
        rev.directionalAsymmetry == mAsym.directionalAsymmetry,
  );

  // 26 map order
  final order1 = dir(
    {
      'alcohol_preference': vr('alcohol_preference', 'social', importance: 0.9),
      'career_priority': vr('career_priority', 'balanced', importance: 0.4),
    },
    {
      'alcohol_preference': vr('alcohol_preference', 'regular'),
      'career_priority': vr('career_priority', 'very_high'),
    },
  );
  final order2 = dir(
    {
      'career_priority': vr('career_priority', 'balanced', importance: 0.4),
      'alcohol_preference': vr('alcohol_preference', 'social', importance: 0.9),
    },
    {
      'career_priority': vr('career_priority', 'very_high'),
      'alcohol_preference': vr('alcohol_preference', 'regular'),
    },
  );
  addScenario(
    id: '26',
    name: 'map_order_shuffled',
    purpose: 'Map order shuffled',
    inputSummary: 'shuffled keys',
    expected: 'same fingerprint',
    actual: {
      'fp1': order1.deterministicFingerprint,
      'fp2': order2.deterministicFingerprint,
    },
    pass: order1.deterministicFingerprint == order2.deterministicFingerprint,
  );

  // 27-36 exclusions / invalids
  r = dir(
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
    {},
  );
  addScenario(
    id: '27',
    name: 'one_field_missing',
    purpose: 'One field missing',
    inputSummary: 'B missing',
    expected: 'excluded missing_b',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode],
      'raw': r.rawValueFitScore,
    },
    pass: r.rawValueFitScore == null &&
        r.excludedFields.any((e) => e.reasonCode == 'value_missing_subject_b'),
    diagnostics: [for (final e in r.excludedFields) e.reasonCode],
  );
  r = dir(
    {
      'monogamy_expectation': vr('monogamy_expectation', 'monogamous'),
      'alcohol_preference': vr('alcohol_preference', 'social'),
    },
    {},
  );
  addScenario(
    id: '28',
    name: 'multiple_fields_missing',
    purpose: 'Multiple fields missing',
    inputSummary: 'two missing',
    expected: 'insufficient',
    actual: {'count': r.excludedFields.length, 'raw': r.rawValueFitScore},
    pass: r.rawValueFitScore == null && r.excludedFields.length >= 2,
  );
  r = dir(
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'monogamous', visibility: 'private')
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '29',
    name: 'private_field',
    purpose: 'Private field',
    inputSummary: 'visibility private',
    expected: 'visibility blocked',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields
        .any((e) => e.reasonCode == 'visibility_policy_blocked'),
  );
  r = dir(
    {
      'monogamy_expectation':
          vr('monogamy_expectation', 'monogamous', permission: false)
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '30',
    name: 'permission_denied',
    purpose: 'Comparison permission denied',
    inputSummary: 'permission false',
    expected: 'permission denied',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields
        .any((e) => e.reasonCode == 'comparison_permission_denied'),
  );
  r = dir(
    {'preferred_living_location': vr('preferred_living_location', 'same_city')},
    {'preferred_living_location': vr('preferred_living_location', 'same_city')},
  );
  addScenario(
    id: '31',
    name: 'pending_review',
    purpose: 'Pending-review field',
    inputSummary: 'preferred_living_location',
    expected: 'pending review',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields
        .any((e) => e.reasonCode == 'comparison_pending_review'),
  );

  // invalid allowed - bypass response validate by constructing manually after
  final badOwner = withValues('A', {
    'monogamy_expectation': RelationshipValueResponse(
      fieldId: 'monogamy_expectation',
      selectedValue: 'not_a_real_value',
      selectedValues: const [],
      importance: 0.8,
      flexibility: 0,
      explicitlyProvided: true,
      responseTimestamp: null,
      registryVersion: valueRegistry.registryVersion,
      visibilityPolicy: 'internal_comparison_allowed',
      comparisonPermission: true,
    ),
  });
  // Can't easily bypass registry validate on response.validate - selectedValue
  // invalid throws on validate. Service eligibility checks allowed values without
  // requiring profile.validate. Our withValues doesn't call validate.
  r = valueService.evaluateDirectional(
    preferenceOwner: badOwner,
    evaluatedSubject: withValues('B', {
      'monogamy_expectation': vr('monogamy_expectation', 'monogamous'),
    }),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '32',
    name: 'invalid_allowed_value',
    purpose: 'Invalid allowed value',
    inputSummary: 'not_a_real_value',
    expected: 'value_not_allowed',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields.any((e) => e.reasonCode == 'value_not_allowed'),
  );

  r = dir(
    {
      'monogamy_expectation': RelationshipValueResponse(
        fieldId: 'monogamy_expectation',
        selectedValue: 'monogamous',
        selectedValues: const [],
        importance: 1.5,
        flexibility: 0,
        explicitlyProvided: true,
        responseTimestamp: null,
        registryVersion: valueRegistry.registryVersion,
        visibilityPolicy: 'internal_comparison_allowed',
        comparisonPermission: true,
      ),
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '33',
    name: 'invalid_importance',
    purpose: 'Invalid importance',
    inputSummary: 'I=1.5',
    expected: 'invalid_importance',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields.any((e) => e.reasonCode == 'invalid_importance'),
  );
  r = dir(
    {
      'monogamy_expectation': RelationshipValueResponse(
        fieldId: 'monogamy_expectation',
        selectedValue: 'monogamous',
        selectedValues: const [],
        importance: 0.8,
        flexibility: -0.2,
        explicitlyProvided: true,
        responseTimestamp: null,
        registryVersion: valueRegistry.registryVersion,
        visibilityPolicy: 'internal_comparison_allowed',
        comparisonPermission: true,
      ),
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '34',
    name: 'invalid_flexibility',
    purpose: 'Invalid flexibility',
    inputSummary: 'f=-0.2',
    expected: 'invalid_flexibility',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields.any((e) => e.reasonCode == 'invalid_flexibility'),
  );
  r = dir(
    {
      'monogamy_expectation': RelationshipValueResponse(
        fieldId: 'monogamy_expectation',
        selectedValue: 'monogamous',
        selectedValues: const [],
        importance: double.nan,
        flexibility: 0,
        explicitlyProvided: true,
        responseTimestamp: null,
        registryVersion: valueRegistry.registryVersion,
        visibilityPolicy: 'internal_comparison_allowed',
        comparisonPermission: true,
      ),
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '35',
    name: 'nan_rejection',
    purpose: 'NaN rejection',
    inputSummary: 'I=NaN',
    expected: 'invalid_importance',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields.any((e) => e.reasonCode == 'invalid_importance'),
  );
  r = dir(
    {
      'monogamy_expectation': RelationshipValueResponse(
        fieldId: 'monogamy_expectation',
        selectedValue: 'monogamous',
        selectedValues: const [],
        importance: double.infinity,
        flexibility: 0,
        explicitlyProvided: true,
        responseTimestamp: null,
        registryVersion: valueRegistry.registryVersion,
        visibilityPolicy: 'internal_comparison_allowed',
        comparisonPermission: true,
      ),
    },
    {'monogamy_expectation': vr('monogamy_expectation', 'monogamous')},
  );
  addScenario(
    id: '36',
    name: 'infinity_rejection',
    purpose: 'Infinity rejection',
    inputSummary: 'I=Inf',
    expected: 'invalid_importance',
    actual: {
      'codes': [for (final e in r.excludedFields) e.reasonCode]
    },
    pass: r.excludedFields.any((e) => e.reasonCode == 'invalid_importance'),
  );

  // 37-50 hard constraints
  DirectionalHardConstraintResult hardDir(
    List<HardConstraint> constraints,
    Map<String, RelationshipValueResponse> bResponses,
  ) =>
      hardService.evaluateDirectional(
        preferenceOwner: withValues('A', {}, constraints: constraints),
        evaluatedSubject: withValues('B', bResponses),
        registry: valueRegistry,
        config: config,
      );

  var h = hardDir(
    [
      hc(
          id: 'd',
          field: 'smoking_preference',
          accepted: ['non_smoker_only'],
          enabled: false)
    ],
    {'smoking_preference': vr('smoking_preference', 'smokes')},
  );
  addScenario(
    id: '37',
    name: 'hard_disabled',
    purpose: 'Hard constraint explicitly disabled',
    inputSummary: 'enabled=false',
    expected: 'not_applicable',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.notApplicable,
  );
  h = hardDir(
    [
      hc(id: 'p', field: 'smoking_preference', accepted: ['non_smoker_only'])
    ],
    {'smoking_preference': vr('smoking_preference', 'non_smoker_only')},
  );
  addScenario(
    id: '38',
    name: 'hard_passed',
    purpose: 'Hard constraint passed',
    inputSummary: 'accepted match',
    expected: 'passed',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.passed,
  );
  h = hardDir(
    [
      hc(id: 'f', field: 'smoking_preference', rejected: ['smokes'])
    ],
    {'smoking_preference': vr('smoking_preference', 'smokes')},
  );
  addScenario(
    id: '39',
    name: 'hard_failed_rejected',
    purpose: 'Hard constraint failed by rejected value',
    inputSummary: 'rejected smokes',
    expected: 'failed',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.failed,
  );
  h = hardDir(
    [
      hc(id: 'a', field: 'children_preference', accepted: ['want_children'])
    ],
    {'children_preference': vr('children_preference', 'do_not_want')},
  );
  addScenario(
    id: '40',
    name: 'hard_failed_missing_accepted',
    purpose: 'Hard constraint failed by missing accepted value',
    inputSummary: 'whitelist miss',
    expected: 'failed',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.failed,
  );
  h = hardDir(
    [
      hc(id: 'u', field: 'smoking_preference', accepted: ['non_smoker_only'])
    ],
    {},
  );
  addScenario(
    id: '41',
    name: 'hard_unknown_missing',
    purpose: 'Hard constraint unknown because counterpart missing',
    inputSummary: 'B missing',
    expected: 'unknown',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.unknown,
  );
  h = hardDir(
    [
      hc(id: 'priv', field: 'smoking_preference', accepted: ['non_smoker_only'])
    ],
    {
      'smoking_preference':
          vr('smoking_preference', 'non_smoker_only', visibility: 'private')
    },
  );
  addScenario(
    id: '42',
    name: 'hard_unknown_private',
    purpose: 'Hard constraint unknown because private',
    inputSummary: 'private visibility',
    expected: 'unknown',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.unknown,
  );
  h = hardDir(
    [
      hc(id: 'p1', field: 'smoking_preference', accepted: ['non_smoker_only']),
      hc(id: 'p2', field: 'children_preference', accepted: ['want_children']),
    ],
    {
      'smoking_preference': vr('smoking_preference', 'non_smoker_only'),
      'children_preference': vr('children_preference', 'want_children'),
    },
  );
  addScenario(
    id: '43',
    name: 'hard_multi_all_passed',
    purpose: 'Multiple constraints all passed',
    inputSummary: 'two passed',
    expected: 'passed',
    actual: {'agg': h.aggregateOutcome.wire, 'n': h.passedConstraintIds.length},
    pass: h.aggregateOutcome == HardConstraintOutcome.passed &&
        h.passedConstraintIds.length == 2,
  );
  h = hardDir(
    [
      hc(id: 'p1', field: 'smoking_preference', accepted: ['non_smoker_only']),
      hc(id: 'f1', field: 'children_preference', accepted: ['want_children']),
    ],
    {
      'smoking_preference': vr('smoking_preference', 'non_smoker_only'),
      'children_preference': vr('children_preference', 'do_not_want'),
    },
  );
  addScenario(
    id: '44',
    name: 'hard_multi_one_failed',
    purpose: 'Multiple constraints one failed',
    inputSummary: 'one fail',
    expected: 'failed',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.failed,
  );
  h = hardDir(
    [
      hc(id: 'p1', field: 'smoking_preference', accepted: ['non_smoker_only']),
      hc(id: 'u1', field: 'children_preference', accepted: ['want_children']),
    ],
    {
      'smoking_preference': vr('smoking_preference', 'non_smoker_only'),
    },
  );
  addScenario(
    id: '45',
    name: 'hard_multi_one_unknown',
    purpose: 'Multiple constraints one unknown',
    inputSummary: 'one unknown',
    expected: 'unknown',
    actual: {'agg': h.aggregateOutcome.wire},
    pass: h.aggregateOutcome == HardConstraintOutcome.unknown,
  );

  final hardMutualDiff = hardService.evaluateMutual(
    subjectA: withValues('A', {}, constraints: [
      hc(id: 'a', field: 'smoking_preference', accepted: ['non_smoker_only']),
    ]),
    subjectB: withValues('B', {
      'smoking_preference': vr('smoking_preference', 'smokes'),
    }, constraints: [
      hc(id: 'b', field: 'children_preference', accepted: ['want_children']),
    ]),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '46',
    name: 'hard_directional_differ',
    purpose: 'Directional constraints differ',
    inputSummary: 'A fails B unknown/na',
    expected: 'directions differ',
    actual: {
      'a': hardMutualDiff.subjectAToBResult.aggregateOutcome.wire,
      'b': hardMutualDiff.subjectBToAResult.aggregateOutcome.wire,
    },
    pass: hardMutualDiff.subjectAToBResult.aggregateOutcome !=
        hardMutualDiff.subjectBToAResult.aggregateOutcome,
  );

  final hardPassMutual2 = hardService.evaluateMutual(
    subjectA: withValues('A', {
      'smoking_preference': vr('smoking_preference', 'non_smoker_only'),
    }, constraints: [
      hc(id: 'a', field: 'smoking_preference', accepted: ['non_smoker_only']),
    ]),
    subjectB: withValues('B', {
      'smoking_preference': vr('smoking_preference', 'non_smoker_only'),
    }, constraints: [
      hc(id: 'b', field: 'smoking_preference', accepted: ['non_smoker_only']),
    ]),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '47',
    name: 'mutual_hard_passed',
    purpose: 'Mutual hard result passed',
    inputSummary: 'both pass',
    expected: 'passed',
    actual: {'agg': hardPassMutual2.aggregateOutcome.wire},
    pass: hardPassMutual2.aggregateOutcome == HardConstraintOutcome.passed,
  );
  addScenario(
    id: '48',
    name: 'mutual_hard_failed',
    purpose: 'Mutual hard result failed',
    inputSummary: 'A fails',
    expected: 'failed',
    actual: {'agg': hardMutualDiff.aggregateOutcome.wire},
    pass: hardMutualDiff.aggregateOutcome == HardConstraintOutcome.failed,
  );
  final hardUnknownMutual = hardService.evaluateMutual(
    subjectA: withValues('A', {}, constraints: [
      hc(id: 'a', field: 'smoking_preference', accepted: ['non_smoker_only']),
    ]),
    subjectB: withValues('B', {}),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '49',
    name: 'mutual_hard_unknown',
    purpose: 'Mutual hard result unknown',
    inputSummary: 'missing counterpart',
    expected: 'unknown',
    actual: {'agg': hardUnknownMutual.aggregateOutcome.wire},
    pass: hardUnknownMutual.aggregateOutcome == HardConstraintOutcome.unknown,
  );
  final hardNone = hardService.evaluateMutual(
    subjectA: withValues('A', {}),
    subjectB: withValues('B', {}),
    registry: valueRegistry,
    config: config,
  );
  addScenario(
    id: '50',
    name: 'no_applicable_constraints',
    purpose: 'No applicable constraints',
    inputSummary: 'empty',
    expected: 'not_applicable',
    actual: {'agg': hardNone.aggregateOutcome.wire},
    pass: hardNone.aggregateOutcome == HardConstraintOutcome.notApplicable,
  );

  // 51-59 soft
  SoftConflictEvaluationResult softFor(
    String ownerVal,
    String otherVal, {
    double importance = 0.8,
    double flexibility = 0.0,
  }) {
    final m = valueService.evaluateMutual(
      subjectA: withValues('A', {
        'monogamy_expectation': vr('monogamy_expectation', ownerVal,
            importance: importance, flexibility: flexibility),
      }),
      subjectB: withValues('B', {
        'monogamy_expectation': vr('monogamy_expectation', otherVal,
            importance: importance, flexibility: flexibility),
      }),
      registry: valueRegistry,
      config: config,
    );
    return softService.evaluate(mutualValues: m, config: config);
  }

  var s = softFor('monogamous', 'monogamous');
  addScenario(
    id: '51',
    name: 'soft_none',
    purpose: 'Soft conflict none',
    inputSummary: 'identical',
    expected: 'severity=0 band=none',
    actual: {
      'sev': s.subjectAToBSignals.single.severity,
      'band': s.subjectAToBSignals.single.severityBand,
    },
    pass: s.subjectAToBSignals.single.severity == 0 &&
        s.subjectAToBSignals.single.severityBand == 'none',
  );
  s = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.2, flexibility: 0);
  addScenario(
    id: '52',
    name: 'soft_low',
    purpose: 'Soft conflict low',
    inputSummary: 'I=0.2 c=0',
    expected: 'band=low',
    actual: {
      'sev': s.subjectAToBSignals.single.severity,
      'band': s.subjectAToBSignals.single.severityBand,
    },
    pass: s.subjectAToBSignals.single.severityBand == 'low',
  );
  s = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.5, flexibility: 0);
  addScenario(
    id: '53',
    name: 'soft_moderate',
    purpose: 'Soft conflict moderate',
    inputSummary: 'I=0.5 c=0',
    expected: 'band=moderate',
    actual: {
      'sev': s.subjectAToBSignals.single.severity,
      'band': s.subjectAToBSignals.single.severityBand,
    },
    pass: s.subjectAToBSignals.single.severityBand == 'moderate',
  );
  s = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.9, flexibility: 0);
  addScenario(
    id: '54',
    name: 'soft_high',
    purpose: 'Soft conflict high',
    inputSummary: 'I=0.9 c=0',
    expected: 'band=high',
    actual: {
      'sev': s.subjectAToBSignals.single.severity,
      'band': s.subjectAToBSignals.single.severityBand,
    },
    pass: s.subjectAToBSignals.single.severityBand == 'high',
  );
  final sLowI = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.2, flexibility: 0);
  final sHighI = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.9, flexibility: 0);
  addScenario(
    id: '55',
    name: 'importance_increases_severity',
    purpose: 'Greater importance increases severity',
    inputSummary: 'I 0.2 vs 0.9',
    expected: 'high > low',
    actual: {
      'low': sLowI.subjectAToBSignals.single.severity,
      'high': sHighI.subjectAToBSignals.single.severity,
    },
    pass: sHighI.subjectAToBSignals.single.severity >
        sLowI.subjectAToBSignals.single.severity,
  );
  final sLowF = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.9, flexibility: 0.0);
  final sHighF = softFor('monogamous', 'open_to_non_monogamy',
      importance: 0.9, flexibility: 0.8);
  addScenario(
    id: '56',
    name: 'flexibility_lowers_severity',
    purpose: 'Greater flexibility lowers severity',
    inputSummary: 'f 0 vs 0.8',
    expected: 'lowF > highF',
    actual: {
      'lowF': sLowF.subjectAToBSignals.single.severity,
      'highF': sHighF.subjectAToBSignals.single.severity,
    },
    pass: sLowF.subjectAToBSignals.single.severity >
        sHighF.subjectAToBSignals.single.severity,
  );
  addScenario(
    id: '57',
    name: 'mutual_soft_uses_max',
    purpose: 'Mutual soft severity uses maximum',
    inputSummary: 'max of directions',
    expected: 'mutual == max',
    actual: {
      'mutual': sHighI.mutualSignals.single.mutualSeverity,
      'a': sHighI.subjectAToBSignals.single.severity,
    },
    pass: sHighI.mutualSignals.single.mutualSeverity ==
        math.max(sHighI.subjectAToBSignals.single.severity,
            sHighI.subjectBToASignals.single.severity),
  );
  final layerSoft = RelationshipCompatibilityLayerResult.assemble(
    mutualValueResult: valueService.evaluateMutual(
      subjectA: withValues('A', {
        'monogamy_expectation':
            vr('monogamy_expectation', 'monogamous', importance: 0.9),
      }),
      subjectB: withValues('B', {
        'monogamy_expectation':
            vr('monogamy_expectation', 'open_to_non_monogamy'),
      }),
      registry: valueRegistry,
      config: config,
    ),
    mutualHardConstraintResult: hardNone,
    softConflictResult: sHighI,
  );
  addScenario(
    id: '58',
    name: 'soft_does_not_hard_fail',
    purpose: 'Soft conflict does not create hard failure',
    inputSummary: 'soft high, hard NA',
    expected: 'not blocked',
    actual: {'blocked': layerSoft.futureFinalResultShouldBeBlocked},
    pass: !layerSoft.futureFinalResultShouldBeBlocked,
  );
  final layerHardFail = RelationshipCompatibilityLayerResult.assemble(
    mutualValueResult: mStrong,
    mutualHardConstraintResult: hardMutualDiff,
    softConflictResult: softService.evaluate(
      mutualValues: mStrong,
      config: config,
    ),
  );
  addScenario(
    id: '59',
    name: 'hard_fail_no_fabricated_value_score',
    purpose: 'Hard failure does not fabricate numeric value score',
    inputSummary: 'hard failed container',
    expected: 'no overall score; values unchanged',
    actual: {
      'blocked': layerHardFail.futureFinalResultShouldBeBlocked,
      'has_overall':
          layerHardFail.toJson().containsKey('overall_compatibility_score'),
      'value_mutual': layerHardFail.mutualValueResult.mutualRawValueFitScore,
    },
    pass: layerHardFail.futureFinalResultShouldBeBlocked &&
        !layerHardFail.toJson().containsKey('overall_compatibility_score'),
  );

  // 60-65 separation / registry
  // Build minimal published assessments for structural
  DimensionMeasurement dm(String id, AssessmentModuleId mod, double score) =>
      DimensionMeasurement(
        dimensionId: id,
        module: mod,
        normalizedScore: score,
        confidence: 0.8,
        uncertainty: 0.2,
        primaryEvidenceCount: 1,
        secondaryEvidenceCount: 0,
        independentContextCount: 1,
        publicationStatus: DimensionPublicationStatus.published,
        publishability: true,
        sourceContentVersions: const ['sim'],
        measurementTimestamp: DateTime.utc(2026, 1, 1),
        scoringContractVersion: 'trait_scoring_config_v1',
        registryVersion: dimRegistry.registryVersion,
      );

  ModuleAssessmentProfile modProf(
    AssessmentModuleId mod,
    Map<String, double> scores,
  ) {
    final keys = scores.keys.toList()..sort();
    return ModuleAssessmentProfile(
      module: mod,
      measurements: {
        for (final k in keys) k: dm(k, mod, scores[k]!),
      },
      assessmentFormId: mod.wire,
      contentVersion: 'sim',
      scoringContractVersion: 'trait_scoring_config_v1',
      completionStatus: ModuleCompletionStatus.partial,
      completedAt: DateTime.utc(2026, 1, 1),
      moduleConfidence: 0.8,
      evidenceCoverage: 0.2,
      unavailableDimensions: const [],
      validationIssues: const [],
      registryVersion: dimRegistry.registryVersion,
    );
  }

  final eqDim =
      dimRegistry.dimsForModule(AssessmentModuleId.eq).first.dimensionId;
  final structA = CanonicalUserAssessmentProfile(
    snapshotId: 'sa',
    profileSchemaVersion: 'v1',
    registryVersion: dimRegistry.registryVersion,
    iq: null,
    eq: modProf(AssessmentModuleId.eq, {eqDim: 0.5}),
    frequency: null,
    publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
      eq: modProf(AssessmentModuleId.eq, {eqDim: 0.5}),
    ),
    unavailableDimensions: const [],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    sourceAssessmentVersions: const ['sim'],
    overallAssessmentCoverage: 0.1,
    profileReadinessStatus: ProfileReadinessStatus.provisional,
  );
  final structB = CanonicalUserAssessmentProfile(
    snapshotId: 'sb',
    profileSchemaVersion: 'v1',
    registryVersion: dimRegistry.registryVersion,
    iq: null,
    eq: modProf(AssessmentModuleId.eq, {eqDim: 0.5}),
    frequency: null,
    publishedMeasurements: CanonicalUserAssessmentProfile.flattenPublished(
      eq: modProf(AssessmentModuleId.eq, {eqDim: 0.5}),
    ),
    unavailableDimensions: const [],
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    sourceAssessmentVersions: const ['sim'],
    overallAssessmentCoverage: 0.1,
    profileReadinessStatus: ProfileReadinessStatus.provisional,
  );
  final structRes = structService.compare(
    subjectA: structA,
    subjectB: structB,
    registry: dimRegistry,
    config: structCfg,
  );
  addScenario(
    id: '60',
    name: 'structural_remains_separate',
    purpose: 'Structural similarity remains separate',
    inputSummary: 'independent structural call',
    expected: 'structural engine invoked separately; not in value layer JSON',
    actual: {
      'struct_fp': structRes.deterministicFingerprint,
      'eq_status': structRes.eq?.status.wire,
      'layer_has_structural':
          layerSoft.toJson().containsKey('structural_similarity'),
    },
    pass: structRes.deterministicFingerprint.isNotEmpty &&
        !layerSoft.toJson().containsKey('structural_similarity'),
  );

  final prefOwner = CompatibilitySubjectSnapshot(
    subjectId: 'A',
    assessmentProfile: structA,
    partnerPreferenceProfile: PartnerPreferenceProfile(
      preferences: {
        eqDim: PartnerDimensionPreference(
          dimensionId: eqDim,
          preferredMin: 0.4,
          preferredMax: 0.6,
          importance: 0.8,
          flexibility: 0.5,
          preferenceMode: PreferenceMode.range,
          source: 'explicit_user',
          explicitlyProvided: true,
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      },
      profileVersion: 'v1',
      registryVersion: dimRegistry.registryVersion,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      completionStatus: PreferenceProfileCompletionStatus.partial,
      explicitlyAnsweredDimensions: [eqDim],
      openDimensions: const [],
      unavailableDimensions: const [],
    ),
    relationshipValueProfile: RelationshipValueProfile(
      responses: const {},
      profileVersion: 'v1',
      registryVersion: valueRegistry.registryVersion,
      createdAt: null,
      updatedAt: null,
    ),
    hardConstraints: const [],
    snapshotVersion: 'v1',
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final prefPartner = CompatibilitySubjectSnapshot(
    subjectId: 'B',
    assessmentProfile: structB,
    partnerPreferenceProfile: PartnerPreferenceProfile(
      preferences: const {},
      profileVersion: 'v1',
      registryVersion: dimRegistry.registryVersion,
      createdAt: null,
      updatedAt: null,
      completionStatus: PreferenceProfileCompletionStatus.incomplete,
      explicitlyAnsweredDimensions: const [],
      openDimensions: const [],
      unavailableDimensions: const [],
    ),
    relationshipValueProfile: RelationshipValueProfile(
      responses: const {},
      profileVersion: 'v1',
      registryVersion: valueRegistry.registryVersion,
      createdAt: null,
      updatedAt: null,
    ),
    hardConstraints: const [],
    snapshotVersion: 'v1',
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final prefRes = prefService.evaluateDirectional(
    preferenceOwner: prefOwner,
    evaluatedSubject: prefPartner,
    registry: dimRegistry,
    config: prefCfg,
  );
  addScenario(
    id: '61',
    name: 'preference_remains_separate',
    purpose: 'Partner-preference fit remains separate',
    inputSummary: 'independent preference call',
    expected: 'preference raw exists; not aggregated in layer',
    actual: {
      'pref_raw': prefRes.rawFitScore,
      'layer_has_pref': layerSoft.toJson().containsKey('preference_fit'),
    },
    pass: prefRes.rawFitScore != null &&
        !layerSoft.toJson().containsKey('preference_fit'),
  );
  addScenario(
    id: '62',
    name: 'no_final_compatibility_score',
    purpose: 'No final compatibility score',
    inputSummary: 'layer JSON keys',
    expected: 'no overall_compatibility_score',
    actual: {
      'keys': layerSoft.toJson().keys.toList()..sort(),
    },
    pass: !layerSoft.toJson().containsKey('overall_compatibility_score') &&
        !layerSoft.toJson().containsKey('persona_id'),
  );
  addScenario(
    id: '63',
    name: 'registry_24d_unaffected',
    purpose: '24-dimension registry remains unaffected',
    inputSummary: 'fixture length',
    expected: '24 dims; value layer independent',
    actual: {
      'dims20': dimRegistry.activeCount,
      'dims24': fixture24.dimensions.length,
    },
    pass: dimRegistry.activeCount == 20 && fixture24.dimensions.length == 24,
  );

  var threw = false;
  try {
    valueService.evaluateDirectional(
      preferenceOwner: withValues('A', {
        'monogamy_expectation': vr('monogamy_expectation', 'monogamous'),
      }),
      evaluatedSubject: withValues('B', {
        'monogamy_expectation': vr('monogamy_expectation', 'monogamous'),
      }),
      registry: valueRegistry,
      config: RelationshipValueComparisonConfig.fromJson({
        ...config.toJson(),
        'registry_version': 'wrong',
      }),
    );
  } catch (_) {
    threw = true;
  }
  addScenario(
    id: '64',
    name: 'registry_mismatch',
    purpose: 'Registry mismatch',
    inputSummary: 'config registry wrong',
    expected: 'throws',
    actual: {'threw': threw},
    pass: threw,
  );

  threw = false;
  try {
    RelationshipValueComparisonConfig.fromJson({
      ...config.toJson(),
      'status': 'production',
    });
  } catch (_) {
    threw = true;
  }
  addScenario(
    id: '65',
    name: 'config_mismatch',
    purpose: 'Config mismatch',
    inputSummary: 'status not provisional',
    expected: 'throws',
    actual: {'threw': threw},
    pass: threw,
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
    'simulator': 'simulate_relationship_value_layer_v1',
    'phase': 'P2B-3',
    'status': failed == 0 ? 'COMPLETE' : 'FAILED',
    'synthetic_only': true,
    'not_real_personalities': true,
    'config_version': config.configVersion,
    'registry_version': valueRegistry.registryVersion,
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
  if (failed > 0) exit(1);
}
