import 'dart:math' as math;

class CompatibilityResult {
  /// 0..1 when [available]; null when evidence is insufficient.
  final double? scoreTotal;
  final bool available;
  final int comparableDimensionCount;
  final String? reason;
  final String label;
  final List<String> reasons;
  final Map<String, double> breakdown;

  const CompatibilityResult({
    required this.scoreTotal,
    required this.available,
    required this.comparableDimensionCount,
    required this.reason,
    required this.label,
    required this.reasons,
    required this.breakdown,
  });
}

/// Outcome of Frequency vector comparison (P1B-1.1 sparse-safe).
class FrequencyVectorSimilarityResult {
  final double? score;
  final bool available;
  final int comparableDimensionCount;
  final String? reason;

  const FrequencyVectorSimilarityResult({
    required this.score,
    required this.available,
    required this.comparableDimensionCount,
    this.reason,
  });
}

/// Pure helper utilities for MVP / cold-start ranking.
///
/// Phase 3R-A2 cold-start guard:
/// - Prefer Frequency 6D vector similarity when present.
/// - Prefer IQ/EQ **bands** over raw normalized closeness (avoids 51 vs 59 noise).
/// - Lower archetype weight (HH…LL are coarse).
/// - No fake percentiles.
///
/// P1B-1.1: sparse Frequency vectors compare only shared dims; below
/// [minComparableFrequencyDimensions] the overall score is unavailable
/// (not filled with 0.5 / 0.42 dimension invent).
class CompatibilityScoring {
  // --- Cold-start weights (must sum to 1.0) ---
  /// Behavioral rhythm / connection style (primary cold-start signal).
  static const double frequencyVectorWeight = 0.32;

  /// Coarse Frequency type/tags (supporting; Balanced Frequency is weak alone).
  static const double frequencyTypeTagWeight = 0.10;

  /// HH…LL / archetype name (supporting explanation only).
  static const double archetypeWeight = 0.15;

  /// IQ H/M/L band affinity (not raw 0–100 closeness).
  static const double iqBandWeight = 0.08;

  /// EQ H/M/L band affinity (not raw 0–100 closeness).
  static const double eqBandWeight = 0.08;

  /// Shared interests Jaccard.
  static const double interestsWeight = 0.15;

  /// Recent activity boost.
  static const double recencyWeight = 0.12;

  /// Slightly below midpoint: missing *non-Frequency* signals only.
  /// Never used as a fabricated Frequency dimension value.
  static const double missingSignalNeutral = 0.42;

  /// Minimum shared Frequency dims required for an available compatibility score.
  /// Documented temporary policy (P1B-1.1): half of the six legacy dims.
  static const int minComparableFrequencyDimensions = 3;

  static const String reasonInsufficientFrequencyEvidence =
      'insufficient_frequency_evidence';

  static const List<String> frequencyDimensionKeys = [
    'depth',
    'socialEnergy',
    'spontaneity',
    'stability',
    'emotionalOpenness',
    'conversationPace',
  ];

  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  static double normalizeScore(dynamic value) {
    if (value == null) return missingSignalNeutral;
    if (value is num) {
      final n = value.toDouble();
      if (n >= 0 && n <= 1) return _clamp01(n);
      if (n >= 0 && n <= 100) return _clamp01(n / 100.0);
      return missingSignalNeutral;
    }
    return missingSignalNeutral;
  }

  /// Legacy raw closeness (kept for debug / optional callers). Prefer [bandClosenessScore].
  static double closenessScore(dynamic a, dynamic b) {
    if (a == null || b == null) return missingSignalNeutral;
    final na = normalizeScore(a);
    final nb = normalizeScore(b);
    return _clamp01(1.0 - (na - nb).abs());
  }

  /// Map normalized 0–100 (or 0–1) into H / M / L using ArchetypeCalculator bands.
  static String? scoreBand(dynamic value) {
    if (value == null) return null;
    if (value is! num) return null;
    var n = value.toDouble();
    if (n >= 0 && n <= 1) n = n * 100.0;
    if (n < 0 || n > 100) return null;
    if (n > 66) return 'H';
    if (n >= 34) return 'M';
    return 'L';
  }

  /// Band affinity: same band stronger; adjacent weaker; H↔L weakest.
  /// Missing either side → [missingSignalNeutral] (not a free 0.5 boost).
  static double bandClosenessScore(dynamic a, dynamic b) {
    final ba = scoreBand(a);
    final bb = scoreBand(b);
    if (ba == null || bb == null) return missingSignalNeutral;
    if (ba == bb) return 0.72;
    final adjacent = (ba == 'H' && bb == 'M') ||
        (ba == 'M' && bb == 'H') ||
        (ba == 'M' && bb == 'L') ||
        (ba == 'L' && bb == 'M');
    if (adjacent) return 0.52;
    return 0.32; // H vs L
  }

  static double tagOverlapScore(List<String> a, List<String> b) {
    final sa =
        a.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    final sb =
        b.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    // Both empty: do not reward as a match (cold-start guard).
    if (sa.isEmpty && sb.isEmpty) return missingSignalNeutral;
    // One empty: weak signal, not zero (avoid punishing incomplete profiles harshly).
    if (sa.isEmpty || sb.isEmpty) return 0.38;
    final inter = sa.intersection(sb).length.toDouble();
    final uni = sa.union(sb).length.toDouble();
    if (uni == 0) return missingSignalNeutral;
    return _clamp01(inter / uni);
  }

  static double archetypeAffinity({
    String? myCategory,
    String? candidateCategory,
    String? myArchetype,
    String? candidateArchetype,
  }) {
    final a = myCategory?.trim();
    final b = candidateCategory?.trim();
    if ((a == null || a.isEmpty) && (b == null || b.isEmpty)) {
      final ma = myArchetype?.trim();
      final ca = candidateArchetype?.trim();
      if (ma != null &&
          ca != null &&
          ma.isNotEmpty &&
          ca.isNotEmpty &&
          ma == ca) {
        return 0.62;
      }
      return missingSignalNeutral;
    }
    if (a != null && b != null && a.isNotEmpty && b.isNotEmpty) {
      if (a == b) return 0.70; // was 0.85 — coarse HH…LL should not dominate
      if (a.length >= 2 && b.length >= 2) {
        final first = a[0] == b[0];
        final second = a[1] == b[1];
        if (first) return 0.58;
        if (second) return 0.55;
      }
    }
    final ma = myArchetype?.trim();
    final ca = candidateArchetype?.trim();
    if (ma != null &&
        ca != null &&
        ma.isNotEmpty &&
        ca.isNotEmpty &&
        ma == ca) {
      return 0.62;
    }
    return missingSignalNeutral;
  }

  static double recencyScore(DateTime? lastActiveAt) {
    if (lastActiveAt == null) return 0.4;
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);
    if (diff.inHours <= 24) return 1.0;
    if (diff.inDays <= 7) return 0.75;
    if (diff.inDays <= 30) return 0.55;
    return 0.35;
  }

  /// Parse Frequency 6D vector from user/assessment maps.
  /// Accepts `frequency_vector` or nested `vector`. Sparse maps are allowed.
  static Map<String, double>? parseFrequencyVector(Map<String, dynamic> data) {
    dynamic raw = data['frequency_vector'] ?? data['vector'];
    if (raw is! Map) return null;
    final out = <String, double>{};
    for (final key in frequencyDimensionKeys) {
      final v = raw[key];
      if (v is num) out[key] = v.toDouble().clamp(0.0, 1.0);
    }
    if (out.isEmpty) return null;
    return out;
  }

  /// Compare only dimensions present and valid for both users.
  ///
  /// Equal weight per comparable dim (mean absolute distance → similarity).
  /// Below [minComparableFrequencyDimensions] → unavailable (not 0.5/0.42).
  static FrequencyVectorSimilarityResult frequencyVectorSimilarityDetailed(
    Map<String, double>? a,
    Map<String, double>? b,
  ) {
    if (a == null || a.isEmpty || b == null || b.isEmpty) {
      return const FrequencyVectorSimilarityResult(
        score: null,
        available: false,
        comparableDimensionCount: 0,
        reason: reasonInsufficientFrequencyEvidence,
      );
    }

    var sumAbs = 0.0;
    var n = 0;
    for (final key in frequencyDimensionKeys) {
      final va = a[key];
      final vb = b[key];
      if (va == null || vb == null) continue;
      if (va.isNaN || vb.isNaN) continue;
      sumAbs += (va - vb).abs();
      n++;
    }

    if (n < minComparableFrequencyDimensions) {
      return FrequencyVectorSimilarityResult(
        score: null,
        available: false,
        comparableDimensionCount: n,
        reason: reasonInsufficientFrequencyEvidence,
      );
    }

    final score = _clamp01(1.0 - (sumAbs / n));
    if (score.isNaN) {
      return FrequencyVectorSimilarityResult(
        score: null,
        available: false,
        comparableDimensionCount: n,
        reason: reasonInsufficientFrequencyEvidence,
      );
    }

    return FrequencyVectorSimilarityResult(
      score: score,
      available: true,
      comparableDimensionCount: n,
    );
  }

  /// Legacy double API: returns similarity when available, else null.
  /// Does **not** invent 0.5 / 0.42 for sparse vectors.
  static double? frequencyVectorSimilarity(
    Map<String, double>? a,
    Map<String, double>? b,
  ) {
    return frequencyVectorSimilarityDetailed(a, b).score;
  }

  /// Tags Jaccard, else type equality, else missing-neutral.
  static double frequencyTypeTagScore({
    required List<String> myTags,
    required List<String> candidateTags,
    String? myType,
    String? candidateType,
  }) {
    if (myTags.isNotEmpty || candidateTags.isNotEmpty) {
      return tagOverlapScore(myTags, candidateTags);
    }
    final mt = myType?.trim();
    final ct = candidateType?.trim();
    if (mt != null &&
        ct != null &&
        mt.isNotEmpty &&
        ct.isNotEmpty &&
        mt == ct) {
      // Same type alone is weak (Balanced Frequency is common).
      if (mt == 'Balanced Frequency') return 0.48;
      return 0.62;
    }
    if ((mt == null || mt.isEmpty) && (ct == null || ct.isEmpty)) {
      return missingSignalNeutral;
    }
    return missingSignalNeutral;
  }

  static CompatibilityResult calculateCompatibility({
    required Map<String, dynamic> me,
    required Map<String, dynamic> candidate,
  }) {
    final myCategory = me['category'] as String?;
    final candidateCategory = candidate['category'] as String?;
    final myArchetype = me['archetype'] as String?;
    final candidateArchetype = candidate['archetype'] as String?;

    final archetype = archetypeAffinity(
      myCategory: myCategory,
      candidateCategory: candidateCategory,
      myArchetype: myArchetype,
      candidateArchetype: candidateArchetype,
    );

    final iq =
        bandClosenessScore(me['iq_normalized'], candidate['iq_normalized']);
    final eq =
        bandClosenessScore(me['eq_normalized'], candidate['eq_normalized']);

    final myVector = parseFrequencyVector(me);
    final candVector = parseFrequencyVector(candidate);
    final freqSim = frequencyVectorSimilarityDetailed(myVector, candVector);

    final myFreqTags = (me['frequency_tags'] is List)
        ? List<String>.from(me['frequency_tags'] as List)
        : <String>[];
    final candFreqTags = (candidate['frequency_tags'] is List)
        ? List<String>.from(candidate['frequency_tags'] as List)
        : <String>[];
    final frequencyTypeTag = frequencyTypeTagScore(
      myTags: myFreqTags,
      candidateTags: candFreqTags,
      myType: (me['frequency_type'] as String?)?.trim(),
      candidateType: (candidate['frequency_type'] as String?)?.trim(),
    );

    final myInterests = (me['interests'] is List)
        ? List<String>.from(me['interests'] as List)
        : <String>[];
    final candInterests = (candidate['interests'] is List)
        ? List<String>.from(candidate['interests'] as List)
        : <String>[];
    final interests = tagOverlapScore(myInterests, candInterests);

    final recency = recencyScore(candidate['last_active_at'] as DateTime?);

    final breakdown = <String, double>{
      'frequency_type_tag': frequencyTypeTag,
      'archetype': archetype,
      'iq': iq,
      'eq': eq,
      'interests': interests,
      'recency': recency,
    };

    if (!freqSim.available || freqSim.score == null) {
      return CompatibilityResult(
        scoreTotal: null,
        available: false,
        comparableDimensionCount: freqSim.comparableDimensionCount,
        reason: freqSim.reason ?? reasonInsufficientFrequencyEvidence,
        label: 'insufficient_evidence',
        reasons: const [],
        breakdown: breakdown,
      );
    }

    final frequencyVector = freqSim.score!;
    breakdown['frequency_vector'] = frequencyVector;

    final score = _clamp01(
      (frequencyVector * frequencyVectorWeight) +
          (frequencyTypeTag * frequencyTypeTagWeight) +
          (archetype * archetypeWeight) +
          (iq * iqBandWeight) +
          (eq * eqBandWeight) +
          (interests * interestsWeight) +
          (recency * recencyWeight),
    );

    String label;
    if (score >= 0.85) {
      label = 'exceptional';
    } else if (score >= 0.70) {
      label = 'strong';
    } else if (score >= 0.55) {
      label = 'good';
    } else if (score >= 0.40) {
      label = 'potential';
    } else {
      label = 'low_signal';
    }

    // Reasons use stable keys already localized in Discover UI.
    // Prefer the stronger Frequency signal under the existing `frequency` key.
    final frequencyReason = math.max(frequencyVector, frequencyTypeTag);

    final signals = <String, double>{
      'frequency': frequencyReason,
      'archetype': archetype,
      'thinking': iq,
      'emotional': eq,
      'interests': interests,
      'recency': recency,
    };

    final sorted = signals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final reasons = <String>[];
    for (final e in sorted) {
      if (reasons.length >= 4) break;
      if (e.value >= 0.70) {
        reasons.add(e.key);
      }
    }
    while (reasons.length < 2 &&
        sorted.isNotEmpty &&
        reasons.length < sorted.length) {
      final next = sorted[reasons.length];
      if (!reasons.contains(next.key)) reasons.add(next.key);
    }

    return CompatibilityResult(
      scoreTotal: score,
      available: true,
      comparableDimensionCount: freqSim.comparableDimensionCount,
      reason: null,
      label: label,
      reasons: reasons.take(4).toList(),
      breakdown: breakdown,
    );
  }

  /// Discover sort: available scores first (desc), then unavailable by recency.
  /// Never treats null as 0.5.
  static int compareDiscoverCandidates({
    required double? aScore,
    required double? bScore,
    required int aLastActiveMs,
    required int bLastActiveMs,
  }) {
    final aAvail = aScore != null;
    final bAvail = bScore != null;
    if (aAvail != bAvail) return aAvail ? -1 : 1;
    if (aAvail && bAvail) {
      final byScore = bScore.compareTo(aScore);
      if (byScore != 0) return byScore;
    }
    return bLastActiveMs.compareTo(aLastActiveMs);
  }
}
