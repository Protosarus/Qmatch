import 'dart:math';

class CompatibilityResult {
  final double scoreTotal; // 0..1
  final String label;
  final List<String> reasons;
  final Map<String, double> breakdown;

  const CompatibilityResult({
    required this.scoreTotal,
    required this.label,
    required this.reasons,
    required this.breakdown,
  });
}

/// Pure helper utilities for MVP ranking/matching.
class CompatibilityScoring {
  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  static double normalizeScore(dynamic value) {
    if (value == null) return 0.5;
    if (value is num) {
      final n = value.toDouble();
      if (n >= 0 && n <= 1) return _clamp01(n);
      if (n >= 0 && n <= 100) return _clamp01(n / 100.0);
      // Unknown scale: treat as neutral.
      return 0.5;
    }
    return 0.5;
  }

  static double closenessScore(dynamic a, dynamic b) {
    final na = normalizeScore(a);
    final nb = normalizeScore(b);
    return _clamp01(1.0 - (na - nb).abs());
  }

  static double tagOverlapScore(List<String> a, List<String> b) {
    final sa =
        a.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    final sb =
        b.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
    if (sa.isEmpty && sb.isEmpty) return 0.5;
    final inter = sa.intersection(sb).length.toDouble();
    final uni = sa.union(sb).length.toDouble();
    if (uni == 0) return 0.5;
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
        return 0.75;
      }
      return 0.5;
    }
    if (a != null && b != null && a.isNotEmpty && b.isNotEmpty) {
      if (a == b) return 0.85;
      if (a.length >= 2 && b.length >= 2) {
        final first = a[0] == b[0];
        final second = a[1] == b[1];
        if (first) return 0.70;
        if (second) return 0.65;
      }
    }
    final ma = myArchetype?.trim();
    final ca = candidateArchetype?.trim();
    if (ma != null &&
        ca != null &&
        ma.isNotEmpty &&
        ca.isNotEmpty &&
        ma == ca) {
      return 0.75;
    }
    return 0.50;
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

    final iq = closenessScore(me['iq_normalized'], candidate['iq_normalized']);
    final eq = closenessScore(me['eq_normalized'], candidate['eq_normalized']);

    // Frequency: prefer tags overlap; fallback to type match; else neutral.
    final myFreqTags = (me['frequency_tags'] is List)
        ? List<String>.from(me['frequency_tags'] as List)
        : <String>[];
    final candFreqTags = (candidate['frequency_tags'] is List)
        ? List<String>.from(candidate['frequency_tags'] as List)
        : <String>[];
    double frequency;
    if (myFreqTags.isNotEmpty || candFreqTags.isNotEmpty) {
      frequency = tagOverlapScore(myFreqTags, candFreqTags);
    } else {
      final myType = (me['frequency_type'] as String?)?.trim();
      final candType = (candidate['frequency_type'] as String?)?.trim();
      if (myType != null &&
          candType != null &&
          myType.isNotEmpty &&
          candType.isNotEmpty &&
          myType == candType) {
        frequency = 0.75;
      } else if (myType == null && candType == null) {
        frequency = 0.5;
      } else {
        frequency = 0.5;
      }
    }

    final myInterests = (me['interests'] is List)
        ? List<String>.from(me['interests'] as List)
        : <String>[];
    final candInterests = (candidate['interests'] is List)
        ? List<String>.from(candidate['interests'] as List)
        : <String>[];
    final interests = tagOverlapScore(myInterests, candInterests);

    final recency = recencyScore(candidate['last_active_at'] as DateTime?);

    // Weights
    final score = _clamp01(
      (archetype * 0.35) +
          (iq * 0.15) +
          (eq * 0.15) +
          (frequency * 0.20) +
          (interests * 0.10) +
          (recency * 0.05),
    );

    String label;
    if (score >= 0.85) {
      label = 'Exceptional match';
    } else if (score >= 0.70) {
      label = 'Strong match';
    } else if (score >= 0.55) {
      label = 'Good match';
    } else if (score >= 0.40) {
      label = 'Potential match';
    } else {
      label = 'Low signal';
    }

    final breakdown = <String, double>{
      'archetype': archetype,
      'iq': iq,
      'eq': eq,
      'frequency': frequency,
      'interests': interests,
      'recency': recency,
    };

    // Reasons: take 2-4 strongest signals.
    final signals = <String, double>{
      'Strong archetype alignment': archetype,
      'Compatible thinking style': iq,
      'Similar emotional rhythm': eq,
      'Shared frequency tags': frequency,
      'Similar interests': interests,
      'Recently active': recency,
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
      label: label,
      reasons: reasons.take(4).toList(),
      breakdown: breakdown,
    );
  }
}
