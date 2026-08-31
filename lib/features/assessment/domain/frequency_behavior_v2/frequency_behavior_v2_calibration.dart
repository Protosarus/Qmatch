import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';
import 'frequency_behavior_v2_telemetry.dart';

class FrequencyBehaviorV2OptionCalibrationRow {
  const FrequencyBehaviorV2OptionCalibrationRow({
    required this.optionId,
    required this.impressions,
    required this.selections,
    required this.selectionShare,
    required this.selectionByPresentedPosition,
    required this.changedAwayCount,
    required this.changedToCount,
    required this.sampleSize,
    this.latencyP25Ms,
    this.latencyMedianMs,
    this.latencyP75Ms,
  });

  final String optionId;
  final int impressions;
  final int selections;
  final double selectionShare;
  final List<int> selectionByPresentedPosition;
  final int changedAwayCount;
  final int changedToCount;
  final int sampleSize;
  final double? latencyP25Ms;
  final double? latencyMedianMs;
  final double? latencyP75Ms;

  Map<String, dynamic> toJson() => {
        'option_id': optionId,
        'impressions': impressions,
        'selections': selections,
        'selection_share': selectionShare,
        'selection_by_presented_position': selectionByPresentedPosition,
        'changed_away_count': changedAwayCount,
        'changed_to_count': changedToCount,
        'sample_size': sampleSize,
        'response_latency': {
          'p25': latencyP25Ms,
          'median': latencyMedianMs,
          'p75': latencyP75Ms,
        },
      };
}

class FrequencyBehaviorV2QuestionCalibrationRow {
  const FrequencyBehaviorV2QuestionCalibrationRow({
    required this.questionId,
    required this.primaryDimension,
    required this.impressions,
    required this.finalChangedCount,
    required this.finalChangedRate,
    required this.sampleSize,
    required this.options,
    this.latencyP25Ms,
    this.latencyMedianMs,
    this.latencyP75Ms,
  });

  final String questionId;
  final String primaryDimension;
  final int impressions;
  final int finalChangedCount;
  final double finalChangedRate;
  final int sampleSize;
  final double? latencyP25Ms;
  final double? latencyMedianMs;
  final double? latencyP75Ms;
  final List<FrequencyBehaviorV2OptionCalibrationRow> options;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'primary_dimension': primaryDimension,
        'impressions': impressions,
        'final_changed_count': finalChangedCount,
        'final_changed_rate': finalChangedRate,
        'sample_size': sampleSize,
        'response_latency': {
          'p25': latencyP25Ms,
          'median': latencyMedianMs,
          'p75': latencyP75Ms,
        },
        'options': [for (final o in options) o.toJson()],
      };
}

class FrequencyBehaviorV2CrossCheckPairRow {
  const FrequencyBehaviorV2CrossCheckPairRow({
    required this.dimensionId,
    required this.questionIdA,
    required this.questionIdB,
    required this.pairCount,
    required this.directionalAgreement,
    required this.directionalDisagreement,
    required this.sampleSize,
  });

  final String dimensionId;
  final String questionIdA;
  final String questionIdB;
  final int pairCount;
  final int directionalAgreement;
  final int directionalDisagreement;
  final int sampleSize;

  Map<String, dynamic> toJson() => {
        'dimension_id': dimensionId,
        'question_id_a': questionIdA,
        'question_id_b': questionIdB,
        'pair_count': pairCount,
        'directional_agreement': directionalAgreement,
        'directional_disagreement': directionalDisagreement,
        'sample_size': sampleSize,
        'not_claims': const [
          'lie_detection',
          'inconsistent_character',
          'dishonesty',
        ],
      };
}

class FrequencyBehaviorV2CohortSlice {
  const FrequencyBehaviorV2CohortSlice({
    required this.cohortKey,
    required this.cohortValue,
    required this.sampleSize,
    required this.suppressed,
    this.reason,
  });

  final String cohortKey;
  final String cohortValue;
  final int sampleSize;
  final bool suppressed;
  final String? reason;

  Map<String, dynamic> toJson() => {
        'cohort_key': cohortKey,
        'cohort_value': cohortValue,
        'sample_size': sampleSize,
        'suppressed': suppressed,
        'reason': reason,
      };
}

class FrequencyBehaviorV2CalibrationReport {
  const FrequencyBehaviorV2CalibrationReport({
    required this.questions,
    required this.crossChecks,
    required this.cohortSlices,
    required this.sessionCount,
    required this.eventCount,
    this.schemaVersion =
        FrequencyBehaviorV2Contract.calibrationAggregateSchemaVersion,
    this.minCohortN = FrequencyBehaviorV2Contract.telemetryMinCohortN,
    this.shrinkageEnabled = false,
  });

  final String schemaVersion;
  final int sessionCount;
  final int eventCount;
  final int minCohortN;
  final bool shrinkageEnabled;
  final List<FrequencyBehaviorV2QuestionCalibrationRow> questions;
  final List<FrequencyBehaviorV2CrossCheckPairRow> crossChecks;
  final List<FrequencyBehaviorV2CohortSlice> cohortSlices;

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'session_count': sessionCount,
        'event_count': eventCount,
        'min_cohort_n': minCohortN,
        'shrinkage_enabled': shrinkageEnabled,
        'questions': [for (final q in questions) q.toJson()],
        'cross_checks': [for (final c in crossChecks) c.toJson()],
        'cohort_slices': [for (final c in cohortSlices) c.toJson()],
      };
}

/// Offline / tooling-only aggregator. Does not write evidence priors.
class FrequencyBehaviorV2CalibrationAggregator {
  const FrequencyBehaviorV2CalibrationAggregator({
    this.minCohortN = FrequencyBehaviorV2Contract.telemetryMinCohortN,
  });

  final int minCohortN;

  /// Future smoothing hook. Phase 4C does not invent coefficients.
  double? shrinkToGlobal({
    required int n,
    required double localShare,
    required double globalShare,
  }) {
    return null;
  }

  FrequencyBehaviorV2CalibrationReport aggregate({
    required List<FrequencyBehaviorV2TelemetrySessionRecord> records,
    FrequencyBehaviorV2PoolDocument? pool,
  }) {
    final questionEvents =
        <String, List<FrequencyBehaviorV2ResponseTelemetryEvent>>{};
    final primaryOf = <String, String>{};
    for (final rec in records) {
      for (final e in rec.events) {
        questionEvents.putIfAbsent(e.questionId, () => []).add(e);
        primaryOf[e.questionId] = e.primaryDimension;
      }
    }
    final questions = <FrequencyBehaviorV2QuestionCalibrationRow>[];
    final qIds = questionEvents.keys.toList()..sort();
    for (final qid in qIds) {
      questions.add(_questionRow(qid, primaryOf[qid]!, questionEvents[qid]!));
    }

    final cross = pool == null
        ? const <FrequencyBehaviorV2CrossCheckPairRow>[]
        : _crossChecks(records, pool);

    final cohortSlices = _cohortSlices(records);

    var eventCount = 0;
    for (final rec in records) {
      eventCount += rec.events.length;
    }
    return FrequencyBehaviorV2CalibrationReport(
      sessionCount: records.length,
      eventCount: eventCount,
      minCohortN: minCohortN,
      shrinkageEnabled: false,
      questions: questions,
      crossChecks: cross,
      cohortSlices: cohortSlices,
    );
  }

  FrequencyBehaviorV2QuestionCalibrationRow _questionRow(
    String questionId,
    String primary,
    List<FrequencyBehaviorV2ResponseTelemetryEvent> events,
  ) {
    final impressions = events.length;
    var finalChanged = 0;
    final latencies = <int>[];
    final optionIds = <String>{};
    for (final e in events) {
      if (e.finalChanged) finalChanged++;
      if (e.latencyValid && e.responseLatencyMs != null) {
        latencies.add(e.responseLatencyMs!);
      }
      optionIds.addAll(e.presentedOptionOrder);
      optionIds.add(e.selectedOptionId);
    }
    final optionRows = <FrequencyBehaviorV2OptionCalibrationRow>[];
    final ids = optionIds.toList()..sort();
    for (final oid in ids) {
      optionRows.add(_optionRow(oid, events, impressions));
    }
    final qLat = _percentiles(latencies);
    return FrequencyBehaviorV2QuestionCalibrationRow(
      questionId: questionId,
      primaryDimension: primary,
      impressions: impressions,
      finalChangedCount: finalChanged,
      finalChangedRate: impressions == 0 ? 0 : finalChanged / impressions,
      sampleSize: impressions,
      latencyP25Ms: qLat[0],
      latencyMedianMs: qLat[1],
      latencyP75Ms: qLat[2],
      options: optionRows,
    );
  }

  FrequencyBehaviorV2OptionCalibrationRow _optionRow(
    String optionId,
    List<FrequencyBehaviorV2ResponseTelemetryEvent> events,
    int impressions,
  ) {
    var selections = 0;
    var away = 0;
    var to = 0;
    final pos = List<int>.filled(4, 0);
    final latencies = <int>[];
    for (final e in events) {
      if (e.selectedOptionId == optionId) {
        selections++;
        final p = e.selectedPresentedPosition;
        if (p != null && p >= 0 && p < 4) pos[p]++;
        if (e.latencyValid && e.responseLatencyMs != null) {
          latencies.add(e.responseLatencyMs!);
        }
      }
      final seq = e.selectionSequence;
      for (var i = 0; i < seq.length; i++) {
        if (seq[i] != optionId) continue;
        if (i < seq.length - 1) away++;
        if (i > 0) to++;
      }
    }
    final lat = _percentiles(latencies);
    return FrequencyBehaviorV2OptionCalibrationRow(
      optionId: optionId,
      impressions: impressions,
      selections: selections,
      selectionShare: impressions == 0 ? 0 : selections / impressions,
      selectionByPresentedPosition: pos,
      changedAwayCount: away,
      changedToCount: to,
      sampleSize: impressions,
      latencyP25Ms: lat[0],
      latencyMedianMs: lat[1],
      latencyP75Ms: lat[2],
    );
  }

  List<FrequencyBehaviorV2CrossCheckPairRow> _crossChecks(
    List<FrequencyBehaviorV2TelemetrySessionRecord> records,
    FrequencyBehaviorV2PoolDocument pool,
  ) {
    final byDim = <String, List<String>>{};
    for (final item in pool.items) {
      if (item.primaryDimensions.length != 1) continue;
      final dim = item.primaryDimensions.single;
      byDim.putIfAbsent(dim, () => []).add(item.itemId);
    }
    final rows = <FrequencyBehaviorV2CrossCheckPairRow>[];
    for (final dim in FrequencyBehaviorV2Contract.canonicalDimensions) {
      final ids = [...(byDim[dim] ?? [])]..sort();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final a = pool.itemsById[ids[i]];
          final b = pool.itemsById[ids[j]];
          if (a == null || b == null) continue;
          if (a.semanticCluster == b.semanticCluster) continue;
          var pairCount = 0;
          var agree = 0;
          var disagree = 0;
          for (final rec in records) {
            FrequencyBehaviorV2ResponseTelemetryEvent? ea;
            FrequencyBehaviorV2ResponseTelemetryEvent? eb;
            for (final e in rec.events) {
              if (e.questionId == a.itemId) ea = e;
              if (e.questionId == b.itemId) eb = e;
            }
            if (ea == null || eb == null) continue;
            final sa = _primarySign(a, ea.selectedOptionId);
            final sb = _primarySign(b, eb.selectedOptionId);
            if (sa == 0 || sb == 0) continue;
            pairCount++;
            if (sa == sb) {
              agree++;
            } else {
              disagree++;
            }
          }
          if (pairCount == 0) continue;
          rows.add(
            FrequencyBehaviorV2CrossCheckPairRow(
              dimensionId: dim,
              questionIdA: a.itemId,
              questionIdB: b.itemId,
              pairCount: pairCount,
              directionalAgreement: agree,
              directionalDisagreement: disagree,
              sampleSize: pairCount,
            ),
          );
        }
      }
    }
    return rows;
  }

  int _primarySign(FrequencyBehaviorV2Item item, String optionId) {
    final opt = item.optionById(optionId);
    if (opt == null || item.primaryDimensions.length != 1) return 0;
    final w = opt.behavioralWeights[item.primaryDimensions.single];
    if (w == null || w == 0) return 0;
    return w > 0 ? 1 : -1;
  }

  List<FrequencyBehaviorV2CohortSlice> _cohortSlices(
    List<FrequencyBehaviorV2TelemetrySessionRecord> records,
  ) {
    final counts = <String, Map<String, int>>{
      'age_bucket': {},
      'profession_category': {},
      'country': {},
      'region': {},
      'city': {},
    };
    for (final rec in records) {
      final c = rec.session.cohort;
      if (c == null) continue;
      void add(String key, String? value) {
        if (value == null || value.isEmpty) return;
        counts[key]![value] = (counts[key]![value] ?? 0) + 1;
      }

      add('age_bucket', c.ageBucket);
      add('profession_category', c.professionCategory);
      add('country', c.country);
      add('region', c.region);
      add('city', c.city);
    }
    final out = <FrequencyBehaviorV2CohortSlice>[];
    for (final key in counts.keys) {
      final values = counts[key]!.keys.toList()..sort();
      for (final value in values) {
        final n = counts[key]![value]!;
        final suppressed = n < minCohortN;
        out.add(
          FrequencyBehaviorV2CohortSlice(
            cohortKey: key,
            cohortValue: value,
            sampleSize: n,
            suppressed: suppressed,
            reason: suppressed ? 'n_below_min_cohort_n' : null,
          ),
        );
      }
    }
    return out;
  }

  List<double?> _percentiles(List<int> values) {
    if (values.isEmpty) return const [null, null, null];
    final sorted = [...values]..sort();
    return [
      _percentile(sorted, 0.25),
      _percentile(sorted, 0.50),
      _percentile(sorted, 0.75),
    ];
  }

  double _percentile(List<int> sorted, double p) {
    if (sorted.length == 1) return sorted.first.toDouble();
    final pos = p * (sorted.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo].toDouble();
    final w = pos - lo;
    return sorted[lo] * (1 - w) + sorted[hi] * w;
  }
}
