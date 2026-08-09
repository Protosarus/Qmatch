// Deterministic statistics for offline robustness evaluation.
// No external numeric dependencies. CLI/test-only.

import 'dart:math' as math;

class DistributionSummary {
  final int count;
  final int nullOrInsufficientCount;
  final int blockedCount;
  final double? mean;
  final double? stdDev;
  final double? min;
  final double? max;
  final double? median;
  final Map<String, double> quantiles;
  final double? iqr;
  final List<int> histogram;
  final double? proportionBelow010;
  final double? proportionAbove090;
  final double? proportionInNeutralWindow;
  final List<double> values;

  DistributionSummary({
    required this.count,
    required this.nullOrInsufficientCount,
    required this.blockedCount,
    required this.mean,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.median,
    required this.quantiles,
    required this.iqr,
    required this.histogram,
    required this.proportionBelow010,
    required this.proportionAbove090,
    required this.proportionInNeutralWindow,
    required this.values,
  });

  Map<String, dynamic> toJson() => {
        'count': count,
        'null_or_insufficient_count': nullOrInsufficientCount,
        'blocked_count': blockedCount,
        'available_numeric_count': values.length,
        'mean': mean,
        'std_dev': stdDev,
        'min': min,
        'max': max,
        'median': median,
        'quantiles': quantiles,
        'iqr': iqr,
        'histogram': histogram,
        'histogram_bin_sum': histogram.fold<int>(0, (a, b) => a + b),
        'proportion_below_0_10': proportionBelow010,
        'proportion_above_0_90': proportionAbove090,
        'proportion_in_neutral_window': proportionInNeutralWindow,
      };
}

DistributionSummary summarizeDistribution(
  List<double?> raw, {
  required List<double> quantilePoints,
  required int histogramBins,
  required double neutralMin,
  required double neutralMax,
  int blockedCount = 0,
  double scoreMin = 0.0,
  double scoreMax = 1.0,
}) {
  final nullCount = raw.where((e) => e == null || !e.isFinite).length;
  final values = [
    for (final v in raw)
      if (v != null && v.isFinite) v,
  ]..sort();
  if (values.isEmpty) {
    return DistributionSummary(
      count: raw.length,
      nullOrInsufficientCount: nullCount,
      blockedCount: blockedCount,
      mean: null,
      stdDev: null,
      min: null,
      max: null,
      median: null,
      quantiles: {},
      iqr: null,
      histogram: List<int>.filled(histogramBins, 0),
      proportionBelow010: null,
      proportionAbove090: null,
      proportionInNeutralWindow: null,
      values: const [],
    );
  }

  final n = values.length;
  final mean = values.fold<double>(0, (a, b) => a + b) / n;
  var varSum = 0.0;
  for (final v in values) {
    final d = v - mean;
    varSum += d * d;
  }
  final std = math.sqrt(varSum / n);
  final qs = <String, double>{};
  for (final q in quantilePoints) {
    qs[q.toStringAsFixed(2)] = _quantile(values, q);
  }
  final q25 = _quantile(values, 0.25);
  final q75 = _quantile(values, 0.75);
  final hist = List<int>.filled(histogramBins, 0);
  final width = (scoreMax - scoreMin) / histogramBins;
  for (final v in values) {
    var bin = ((v - scoreMin) / width).floor();
    if (bin < 0) bin = 0;
    if (bin >= histogramBins) bin = histogramBins - 1;
    hist[bin]++;
  }
  final below = values.where((v) => v < 0.10).length / n;
  final above = values.where((v) => v > 0.90).length / n;
  final neutral =
      values.where((v) => v >= neutralMin && v <= neutralMax).length / n;

  return DistributionSummary(
    count: raw.length,
    nullOrInsufficientCount: nullCount,
    blockedCount: blockedCount,
    mean: mean,
    stdDev: std,
    min: values.first,
    max: values.last,
    median: _quantile(values, 0.50),
    quantiles: qs,
    iqr: q75 - q25,
    histogram: hist,
    proportionBelow010: below,
    proportionAbove090: above,
    proportionInNeutralWindow: neutral,
    values: values,
  );
}

double _quantile(List<double> sorted, double q) {
  if (sorted.isEmpty) {
    throw StateError('empty');
  }
  if (q <= 0) return sorted.first;
  if (q >= 1) return sorted.last;
  final pos = (sorted.length - 1) * q;
  final lo = pos.floor();
  final hi = pos.ceil();
  if (lo == hi) return sorted[lo];
  final w = pos - lo;
  return sorted[lo] * (1 - w) + sorted[hi] * w;
}

/// Average ranks with deterministic midrank ties.
List<double> averageRanks(List<double> values) {
  final indexed = [
    for (var i = 0; i < values.length; i++) (i, values[i]),
  ]..sort((a, b) {
      final c = a.$2.compareTo(b.$2);
      if (c != 0) return c;
      return a.$1.compareTo(b.$1);
    });
  final ranks = List<double>.filled(values.length, 0);
  var i = 0;
  while (i < indexed.length) {
    var j = i;
    while (j + 1 < indexed.length && indexed[j + 1].$2 == indexed[i].$2) {
      j++;
    }
    final avg = ((i + 1) + (j + 1)) / 2.0;
    for (var k = i; k <= j; k++) {
      ranks[indexed[k].$1] = avg;
    }
    i = j + 1;
  }
  return ranks;
}

double? pearsonCorrelation(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 2) return null;
  final n = x.length;
  final mx = x.fold<double>(0, (a, b) => a + b) / n;
  final my = y.fold<double>(0, (a, b) => a + b) / n;
  var num = 0.0;
  var dx = 0.0;
  var dy = 0.0;
  for (var i = 0; i < n; i++) {
    final a = x[i] - mx;
    final b = y[i] - my;
    num += a * b;
    dx += a * a;
    dy += b * b;
  }
  if (dx == 0 || dy == 0) return null;
  return num / math.sqrt(dx * dy);
}

double? spearmanCorrelation(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 2) return null;
  return pearsonCorrelation(averageRanks(x), averageRanks(y));
}

/// Deterministic Kendall tau-b style concordance in [-1, 1].
double? kendallTauBStyle(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 2) return null;
  final n = x.length;
  var concordant = 0;
  var discordant = 0;
  var tiesX = 0;
  var tiesY = 0;
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final dx = x[i].compareTo(x[j]);
      final dy = y[i].compareTo(y[j]);
      if (dx == 0 && dy == 0) continue;
      if (dx == 0) {
        tiesX++;
        continue;
      }
      if (dy == 0) {
        tiesY++;
        continue;
      }
      if (dx.sign == dy.sign) {
        concordant++;
      } else {
        discordant++;
      }
    }
  }
  final denom = math.sqrt(
    (concordant + discordant + tiesX) * (concordant + discordant + tiesY),
  );
  if (denom == 0) return null;
  return (concordant - discordant) / denom;
}

String correlationBand(
  double? r, {
  required double moderate,
  required double high,
  required double veryHigh,
}) {
  if (r == null || !r.isFinite) return 'undefined';
  final a = r.abs();
  if (a < moderate) return 'low';
  if (a < high) return 'moderate';
  if (a < veryHigh) return 'high';
  return 'very_high';
}

double jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final inter = a.intersection(b).length;
  final union = a.union(b).length;
  if (union == 0) return 1.0;
  return inter / union;
}

/// Rank vectors (1 = best / highest score). Ties broken by index.
List<int> ranksDescending(List<double> scores) {
  final indexed = [
    for (var i = 0; i < scores.length; i++) (i, scores[i]),
  ]..sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      if (c != 0) return c;
      return a.$1.compareTo(b.$1);
    });
  final ranks = List<int>.filled(scores.length, 0);
  for (var r = 0; r < indexed.length; r++) {
    ranks[indexed[r].$1] = r + 1;
  }
  return ranks;
}

double topKOverlap(List<int> ranksA, List<int> ranksB, double fraction) {
  if (ranksA.length != ranksB.length || ranksA.isEmpty) return 0;
  final k = math.max(1, (ranksA.length * fraction).round());
  final setA = {
    for (var i = 0; i < ranksA.length; i++)
      if (ranksA[i] <= k) i,
  };
  final setB = {
    for (var i = 0; i < ranksB.length; i++)
      if (ranksB[i] <= k) i,
  };
  return setA.intersection(setB).length / k;
}

double bottomKOverlap(List<int> ranksA, List<int> ranksB, double fraction) {
  if (ranksA.length != ranksB.length || ranksA.isEmpty) return 0;
  final k = math.max(1, (ranksA.length * fraction).round());
  final n = ranksA.length;
  final setA = {
    for (var i = 0; i < ranksA.length; i++)
      if (ranksA[i] > n - k) i,
  };
  final setB = {
    for (var i = 0; i < ranksB.length; i++)
      if (ranksB[i] > n - k) i,
  };
  return setA.intersection(setB).length / k;
}

Map<String, dynamic> rankStabilityReport({
  required List<double> baselineScores,
  required List<double> otherScores,
  int kendallMaxN = 400,
}) {
  final rA = ranksDescending(baselineScores);
  final rB = ranksDescending(otherScores);
  final movements = [
    for (var i = 0; i < rA.length; i++) (rA[i] - rB[i]).abs(),
  ]..sort();
  final spearman = spearmanCorrelation(
    [for (final r in rA) r.toDouble()],
    [for (final r in rB) r.toDouble()],
  );
  final kendallSkipped = baselineScores.length > kendallMaxN;
  return {
    'pair_count': baselineScores.length,
    'spearman': spearman,
    'kendall_tau_b_style':
        kendallSkipped ? null : kendallTauBStyle(baselineScores, otherScores),
    'kendall_skipped_for_size': kendallSkipped,
    'top_1_pct_overlap': topKOverlap(rA, rB, 0.01),
    'top_5_pct_overlap': topKOverlap(rA, rB, 0.05),
    'top_10_pct_overlap': topKOverlap(rA, rB, 0.10),
    'bottom_10_pct_overlap': bottomKOverlap(rA, rB, 0.10),
    'median_abs_rank_movement': movements.isEmpty
        ? null
        : _quantile([for (final m in movements) m.toDouble()], 0.5),
    'max_abs_rank_movement':
        movements.isEmpty ? null : movements.last.toDouble(),
  };
}

bool isFiniteBounded(num? v, {required double min, required double max}) {
  if (v == null) return true;
  if (v is! double && v is! int) return false;
  final d = v.toDouble();
  if (!d.isFinite) return false;
  return d >= min - 1e-12 && d <= max + 1e-12;
}
