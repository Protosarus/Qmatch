import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:qmatch/features/assessment/domain/trait_scoring/trait_scoring.dart';

/// Offline helpers for Frequency pilot scoring fixtures (not production).
class FrequencyPilotV1Loader {
  FrequencyPilotV1Loader._();

  static const pilotPath =
      'assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json';
  static const configPath = 'assets/data/trait_scoring_config_v1.json';

  static String get repoRoot => Directory.current.path;

  static Map<String, dynamic> loadForm() {
    final text = File('$repoRoot/$pilotPath').readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static TraitScoringConfig loadConfig() {
    return TraitScoringParser.parseConfigJson(
      File('$repoRoot/$configPath').readAsStringSync(),
    );
  }

  static List<AssessmentItemDefinition> loadItems(TraitScoringConfig config) {
    final form = loadForm();
    return TraitScoringParser.parseItemBank(
      form['items'] as List<dynamic>,
      expectedModule: 'frequency',
      source: 'frequency_pilot_tr_v1.json',
      config: config,
    );
  }

  static List<AssessmentResponse> validateResponses({
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
  }) {
    final known = {for (final q in items) q.questionId};
    final seen = <String>{};
    final errors = <TraitValidationError>[];
    for (final r in responses) {
      if (!known.contains(r.questionId)) {
        errors.add(TraitValidationError(
          questionId: r.questionId,
          fieldPath: 'question_id',
          reasonCode: 'unknown_question_id',
          explanation: 'Response references unknown question',
        ));
      }
      if (!seen.add(r.questionId)) {
        errors.add(TraitValidationError(
          questionId: r.questionId,
          fieldPath: 'question_id',
          reasonCode: 'duplicate_response',
          explanation: 'Duplicate response for question',
        ));
      }
    }
    if (errors.isNotEmpty) {
      throw TraitScoringValidationException('Invalid responses', errors);
    }
    return responses;
  }

  static TraitScoringSessionInput session({
    required TraitScoringConfig config,
    required List<AssessmentItemDefinition> items,
    required List<AssessmentResponse> responses,
    String assessmentStatus = 'complete',
  }) {
    final form = loadForm();
    final validated = validateResponses(items: items, responses: responses);
    final pairRegistry = form['pair_registry'] as Map? ?? const {};
    return TraitScoringSessionInput(
      module: 'frequency',
      schemaVersion: config.questionSchemaVersion,
      contentVersion: form['content_version'] as String,
      traitScoringVersion: config.traitScoringVersion,
      locale: 'tr',
      setId: form['set_id'] as String,
      questionDefinitions: items,
      submittedResponses: validated,
      assessmentStatus: assessmentStatus,
      reversePairDescriptors: ReversePairDescriptor.parseRegistry(
        pairRegistry['reverse_pairs'],
      ),
    );
  }

  static AssessmentOptionDefinition pickOptionMaximizing(
    AssessmentItemDefinition item,
    String dimension,
  ) {
    AssessmentOptionDefinition? best;
    var bestVal = double.negativeInfinity;
    for (final o in item.options) {
      final v = o.dimensionDeltas[dimension] ?? 0.0;
      if (v > bestVal) {
        bestVal = v;
        best = o;
      }
    }
    return best ?? item.options.first;
  }

  static AssessmentOptionDefinition pickOptionMinimizing(
    AssessmentItemDefinition item,
    String dimension,
  ) {
    AssessmentOptionDefinition? best;
    var bestVal = double.infinity;
    for (final o in item.options) {
      final v = o.dimensionDeltas[dimension] ?? 0.0;
      if (v < bestVal) {
        bestVal = v;
        best = o;
      }
    }
    return best ?? item.options.first;
  }

  static AssessmentOptionDefinition pickOptionModerate(
    AssessmentItemDefinition item, {
    String? dimension,
  }) {
    final dim = dimension ?? item.primaryDimension;
    AssessmentOptionDefinition? best;
    var bestAbs = double.infinity;
    for (final o in item.options) {
      final v = (o.dimensionDeltas[dim] ?? 0.0).abs();
      if (v < bestAbs) {
        bestAbs = v;
        best = o;
      }
    }
    return best ?? item.options[item.options.length ~/ 2];
  }

  static AssessmentOptionDefinition pickOptionPrimarySign(
    AssessmentItemDefinition item,
    int desiredSign,
  ) {
    AssessmentOptionDefinition? best;
    var bestMag = -1.0;
    for (final o in item.options) {
      final v = o.dimensionDeltas[item.primaryDimension] ?? 0.0;
      if (v == 0) continue;
      if (v.sign == desiredSign && v.abs() >= bestMag) {
        bestMag = v.abs();
        best = o;
      }
    }
    return best ?? pickOptionModerate(item);
  }

  static AssessmentOptionDefinition pickIdealizedImpression(
    AssessmentItemDefinition item,
  ) {
    if (!item.responseValidityRoles.contains('social_impression_risk')) {
      return pickOptionModerate(item);
    }
    var best = item.options.first;
    var bestScore = double.negativeInfinity;
    for (final o in item.options) {
      final primary = o.dimensionDeltas[item.primaryDimension] ?? 0.0;
      final sdrBoost = o.socialDesirabilityRisk == 'high'
          ? 2.0
          : o.socialDesirabilityRisk == 'moderate'
              ? 1.0
              : 0.0;
      final score = primary + sdrBoost + o.extremity;
      if (score > bestScore) {
        bestScore = score;
        best = o;
      }
    }
    return best;
  }

  static List<AssessmentResponse> fromPicker(
    List<AssessmentItemDefinition> items,
    AssessmentOptionDefinition Function(AssessmentItemDefinition) pick, {
    int baseMs = 6000,
  }) =>
      [
        for (var i = 0; i < items.length; i++)
          AssessmentResponse(
            questionId: items[i].questionId,
            selectedOptionId: pick(items[i]).optionId,
            responseTimeMilliseconds: baseMs + (i * 137) % 4000,
          ),
      ];

  static List<AssessmentResponse> balancedMixed(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, pickOptionModerate);

  static List<AssessmentResponse> sortResponses(
    List<AssessmentResponse> responses,
  ) =>
      [...responses]..sort((a, b) => a.questionId.compareTo(b.questionId));

  static List<AssessmentResponse> fullCoverageMaxPrimary(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(
        items,
        (q) => pickOptionMaximizing(q, q.primaryDimension),
      );

  static List<AssessmentResponse> highDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      fromPicker(
        items,
        (q) => q.primaryDimension == dimension
            ? pickOptionMaximizing(q, dimension)
            : pickOptionModerate(q),
      );

  static List<AssessmentResponse> lowDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      fromPicker(
        items,
        (q) => q.primaryDimension == dimension
            ? pickOptionMinimizing(q, dimension)
            : pickOptionModerate(q),
      );

  static List<AssessmentResponse> highDepthPreference(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'depth_preference');

  static List<AssessmentResponse> lowDepthPreference(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'depth_preference');

  static List<AssessmentResponse> highSocialEnergy(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'social_energy');

  static List<AssessmentResponse> lowSocialEnergy(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'social_energy');

  static List<AssessmentResponse> highSpontaneity(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'spontaneity');

  static List<AssessmentResponse> lowSpontaneity(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'spontaneity');

  static List<AssessmentResponse> highStability(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'stability');

  static List<AssessmentResponse> lowStability(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'stability');

  static List<AssessmentResponse> highDisclosurePace(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'disclosure_pace');

  static List<AssessmentResponse> lowDisclosurePace(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'disclosure_pace');

  static List<AssessmentResponse> highCommunicationPace(
    List<AssessmentItemDefinition> items,
  ) =>
      highDimension(items, 'communication_pace');

  static List<AssessmentResponse> lowCommunicationPace(
    List<AssessmentItemDefinition> items,
  ) =>
      lowDimension(items, 'communication_pace');

  static List<AssessmentResponse> _dualPrimary(
    List<AssessmentItemDefinition> items, {
    required String highDim,
    required String lowDim,
  }) =>
      fromPicker(items, (q) {
        if (q.primaryDimension == highDim) {
          return pickOptionMaximizing(q, highDim);
        }
        if (q.primaryDimension == lowDim) {
          return pickOptionMinimizing(q, lowDim);
        }
        return pickOptionModerate(q);
      });

  static List<AssessmentResponse> highDepthSlowCommunication(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'depth_preference',
        lowDim: 'communication_pace',
      );

  static List<AssessmentResponse> lowDepthFastCommunication(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'communication_pace',
        lowDim: 'depth_preference',
      );

  static List<AssessmentResponse> highSpontaneityHighStability(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.primaryDimension == 'spontaneity') {
          return pickOptionMaximizing(q, 'spontaneity');
        }
        if (q.primaryDimension == 'stability') {
          return pickOptionMaximizing(q, 'stability');
        }
        return pickOptionModerate(q);
      });

  static List<AssessmentResponse> lowSpontaneityLowStability(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.primaryDimension == 'spontaneity') {
          return pickOptionMinimizing(q, 'spontaneity');
        }
        if (q.primaryDimension == 'stability') {
          return pickOptionMinimizing(q, 'stability');
        }
        return pickOptionModerate(q);
      });

  static List<AssessmentResponse> highStabilityLowSpontaneity(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'stability',
        lowDim: 'spontaneity',
      );

  static List<AssessmentResponse> highSpontaneityLowStability(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'spontaneity',
        lowDim: 'stability',
      );

  static List<AssessmentResponse> fastDisclosureSlowCommunication(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'disclosure_pace',
        lowDim: 'communication_pace',
      );

  static List<AssessmentResponse> slowDisclosureFastCommunication(
    List<AssessmentItemDefinition> items,
  ) =>
      _dualPrimary(
        items,
        highDim: 'communication_pace',
        lowDim: 'disclosure_pace',
      );

  /// Lower contact / more independent spacing preferences.
  static List<AssessmentResponse> highlyIndependentPattern(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.primaryDimension == 'communication_pace' ||
            q.primaryDimension == 'social_energy' ||
            q.primaryDimension == 'disclosure_pace') {
          return pickOptionMinimizing(q, q.primaryDimension);
        }
        return pickOptionModerate(q);
      });

  /// Higher contact / continuity preferences.
  static List<AssessmentResponse> highlyContactOrientedPattern(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.primaryDimension == 'communication_pace' ||
            q.primaryDimension == 'social_energy' ||
            q.primaryDimension == 'disclosure_pace') {
          return pickOptionMaximizing(q, q.primaryDimension);
        }
        return pickOptionModerate(q);
      });

  static List<AssessmentResponse> semanticConsistent(
    List<AssessmentItemDefinition> items,
  ) {
    return fromPicker(items, (q) {
      if (q.semanticPairId == null) return pickOptionModerate(q);
      return pickOptionPrimarySign(q, 1);
    });
  }

  static List<AssessmentResponse> semanticInconsistent(
    List<AssessmentItemDefinition> items,
  ) {
    final seenPair = <String>{};
    return fromPicker(items, (q) {
      if (q.semanticPairId == null) return pickOptionModerate(q);
      final pairId = q.semanticPairId!;
      if (seenPair.add(pairId)) {
        return pickOptionPrimarySign(q, 1);
      }
      return pickOptionPrimarySign(q, -1);
    });
  }

  /// Behavioral correspondence: same primary-delta sign on both pair members.
  static List<AssessmentResponse> reverseConsistent(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) {
        if (q.reversePairId == null) return pickOptionModerate(q);
        return pickOptionPrimarySign(q, 1);
      });

  /// Behavioral inconsistency: opposite primary-delta signs across members.
  static List<AssessmentResponse> reverseInconsistent(
    List<AssessmentItemDefinition> items,
  ) {
    final seenPair = <String>{};
    return fromPicker(items, (q) {
      if (q.reversePairId == null) return pickOptionModerate(q);
      final pairId = q.reversePairId!;
      if (seenPair.add(pairId)) {
        return pickOptionPrimarySign(q, 1);
      }
      return pickOptionPrimarySign(q, -1);
    });
  }

  static List<AssessmentResponse> alwaysOptionA(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) => q.options.firstWhere((o) => o.optionId == 'A'));

  static List<AssessmentResponse> alwaysOptionD(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, (q) => q.options.firstWhere((o) => o.optionId == 'D'));

  static List<AssessmentResponse> randomSeeded(
    List<AssessmentItemDefinition> items, {
    int seed = 42,
  }) {
    final rng = Random(seed);
    return [
      for (final q in items)
        AssessmentResponse(
          questionId: q.questionId,
          selectedOptionId: q.options[rng.nextInt(q.options.length)].optionId,
          responseTimeMilliseconds: 5000 + rng.nextInt(7000),
        ),
    ];
  }

  static List<AssessmentResponse> omitPrimaryDimension(
    List<AssessmentItemDefinition> items,
    String dimension,
  ) =>
      [
        for (final q in items)
          if (q.primaryDimension != dimension)
            AssessmentResponse(
              questionId: q.questionId,
              selectedOptionId: pickOptionModerate(q).optionId,
              responseTimeMilliseconds: 6500,
            ),
      ];

  static List<AssessmentResponse> idealizedHighSdrClustering(
    List<AssessmentItemDefinition> items,
  ) =>
      fromPicker(items, pickIdealizedImpression);

  static Map<String, int> primaryCounts(List<Map<String, dynamic>> rawItems) {
    final counts = <String, int>{};
    for (final j in rawItems) {
      final d = j['primary_dimension']?.toString() ?? '';
      counts[d] = (counts[d] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> scenarioFamilyCounts(Map<String, dynamic> form) {
    final families = form['item_scenario_families'] as Map? ?? {};
    final counts = <String, int>{};
    for (final fam in families.values) {
      final k = fam.toString();
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> secondaryAppearances(List<Map<String, dynamic>> raw) {
    final counts = <String, int>{};
    for (final j in raw) {
      for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
        final k = s.toString();
        counts[k] = (counts[k] ?? 0) + 1;
      }
    }
    return counts;
  }

  static Map<String, Set<String>> independentContexts(
    Map<String, dynamic> form,
    List<Map<String, dynamic>> rawItems,
  ) {
    final families = Map<String, dynamic>.from(
      form['item_scenario_families'] as Map? ?? {},
    );
    final contexts = {
      for (final d in PersonaDimensionIds.frequency) d: <String>{},
    };
    for (final j in rawItems) {
      final qid = j['question_id']?.toString() ?? '';
      final fam = families[qid]?.toString();
      if (fam == null) continue;
      final primary = j['primary_dimension']?.toString() ?? '';
      if (contexts.containsKey(primary)) contexts[primary]!.add(fam);
      for (final s in (j['secondary_dimensions'] as List?) ?? const []) {
        final sd = s.toString();
        if (contexts.containsKey(sd)) contexts[sd]!.add(fam);
      }
    }
    return contexts;
  }
}
