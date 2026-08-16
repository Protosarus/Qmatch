import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/compatibility_scoring.dart';
import '../../matching/domain/canonical_20d_group_normalized_shadow.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';

/// Stage B2 dual-path shadow collector (legacy vs group-normalized 20D).
///
/// Privacy-safe, in-memory only. Disabled unless [enabled] is true.
/// Diagnostic only — never reorders Discover. Live ranking is trusted
/// backend L2; this collector's Dart matcher is not the ranking path.
/// No fusion, temporal, QI, Persona, RVI, or imputation of missing 20D.
class DiscoverStageB2DualPathCollector {
  DiscoverStageB2DualPathCollector({
    this.enabled = false,
    Canonical20dGroupNormalizedShadowMatcher structuralMatcher =
        const Canonical20dGroupNormalizedShadowMatcher(),
    String Function()? sessionSaltFactory,
  })  : _structural = structuralMatcher,
        _sessionSaltFactory = sessionSaltFactory ?? _defaultSalt;

  /// Must stay false in production release paths unless an internal debug
  /// build explicitly opts in.
  final bool enabled;

  final Canonical20dGroupNormalizedShadowMatcher _structural;
  final String Function() _sessionSaltFactory;

  DiscoverStageB2Session? _session;
  final Map<String, _LegacyCapture> _legacyByUid = {};
  String? _sessionSalt;
  String? _viewerUid;

  /// Last finalized session (null if disabled / not finalized).
  DiscoverStageB2Session? get lastSession => _session;

  void reset() {
    _session = null;
    _legacyByUid.clear();
    _sessionSalt = null;
    _viewerUid = null;
  }

  /// Start a new collection window for one [getCandidates] batch.
  void beginSession({required String viewerUid}) {
    if (!enabled) {
      reset();
      return;
    }
    _legacyByUid.clear();
    _session = null;
    _viewerUid = viewerUid;
    _sessionSalt = _sessionSaltFactory();
  }

  /// Capture legacy CompatibilityScoring outcome for one eligible candidate.
  ///
  /// Call only for candidates that will enter the Discover batch (post L1
  /// filters). Does not store uid in the exported session — uid is hashed.
  void recordLegacyPair({
    required String candidateUid,
    required bool legacyAvailable,
    required double? legacyScore,
    required String? legacyMissingReason,
  }) {
    if (!enabled) return;
    _legacyByUid[candidateUid] = _LegacyCapture(
      available: legacyAvailable,
      score: legacyAvailable ? legacyScore : null,
      missingReason: legacyAvailable
          ? null
          : (legacyMissingReason ?? 'legacy_unavailable'),
    );
  }

  /// Independent diagnostic ranks from stored CompatibilityScoring captures.
  ///
  /// Same comparator as live rollback: available scores first (desc), then
  /// recency. Never uses the live Discover / L2 batch index.
  Map<String, int> _independentLegacyRanks(
    List<DiscoverUserModel> l1Candidates,
  ) {
    final order = List<DiscoverUserModel>.of(l1Candidates);
    order.sort((a, b) {
      return CompatibilityScoring.compareDiscoverCandidates(
        aScore: _legacyScoreForRank(a),
        bScore: _legacyScoreForRank(b),
        aLastActiveMs: a.lastActiveAt?.millisecondsSinceEpoch ?? 0,
        bLastActiveMs: b.lastActiveAt?.millisecondsSinceEpoch ?? 0,
      );
    });
    return {
      for (var i = 0; i < order.length; i++) order[i].uid: i + 1,
    };
  }

  double? _legacyScoreForRank(DiscoverUserModel candidate) {
    final captured = _legacyByUid[candidate.uid];
    if (captured != null) {
      return captured.available ? captured.score : null;
    }
    return candidate.compatibilityScore;
  }

  /// Attach structural distances + ranks. Does not reorder Discover.
  void finalizeBatch({
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, dynamic>? meCanonicalProfile,
    required Map<String, Map<String, dynamic>?> candidateCanonicalProfiles,
  }) {
    if (!enabled) {
      reset();
      return;
    }
    final salt = _sessionSalt;
    final viewerUid = _viewerUid;
    if (salt == null || viewerUid == null) {
      reset();
      return;
    }

    final sessionId = _hashId('session|$salt');
    final viewerAnon = _anon(salt, viewerUid);
    final legacyRankByUid = _independentLegacyRanks(rankedCandidates);
    final meSubject =
        DiscoverCanonical20dShadowSubjectBuilder.fromCanonicalProfile(
            meCanonicalProfile);

    final pairs = <DiscoverStageB2PairDiagnostic>[];
    for (var i = 0; i < rankedCandidates.length; i++) {
      final candidate = rankedCandidates[i];
      final legacy = _legacyByUid[candidate.uid];
      final candidateAnon = _anon(salt, candidate.uid);
      final pairId = _hashId('pair|$salt|$viewerUid|${candidate.uid}');

      final legacyAvailable =
          legacy?.available ?? (candidate.compatibilityScore != null);
      final legacyScore = legacy?.score ?? candidate.compatibilityScore;
      final legacyMissing = legacyAvailable
          ? null
          : (legacy?.missingReason ??
              candidate.compatibilityLabel ??
              'legacy_unavailable');

      String? structuralMissing;
      bool structuralAvailable = false;
      double? dStructural;
      double? structuralCoverage;
      int? structuralComparableDims;

      if (meSubject == null) {
        structuralMissing = 'viewer_canonical_profile_missing';
      } else {
        final profile = candidateCanonicalProfiles[candidate.uid];
        final other =
            DiscoverCanonical20dShadowSubjectBuilder.fromCanonicalProfile(
                profile);
        if (other == null) {
          structuralMissing = 'candidate_canonical_profile_missing';
        } else {
          final result = _structural.compareMeasuredPresence(
            a: meSubject,
            b: other,
          );
          structuralAvailable = result.available;
          dStructural = result.combinedDistance;
          structuralCoverage = result.totalCoverage;
          structuralComparableDims = result.totalComparableDimensionCount;
          if (!result.available) {
            structuralMissing = 'no_shared_measured_modules';
          }
        }
      }

      pairs.add(
        DiscoverStageB2PairDiagnostic(
          pairId: pairId,
          candidateAnonId: candidateAnon,
          legacyAvailable: legacyAvailable,
          legacyScore: legacyScore,
          legacyMissingReason: legacyMissing,
          legacyRank: legacyRankByUid[candidate.uid]!,
          structuralAvailable: structuralAvailable,
          structuralDistance: dStructural,
          structuralMissingReason: structuralMissing,
          structuralCoverage: structuralCoverage,
          structuralComparableDims: structuralComparableDims,
          structuralRank: null, // filled below
        ),
      );
    }

    _storeFinalizedPairs(
      pairs: pairs,
      sessionId: sessionId,
      viewerAnon: viewerAnon,
    );
  }

  /// Attach trusted L2 pair diagnostics. Does not reorder Discover.
  ///
  /// [trustedPairs] must be 1:1 with [rankedCandidates].
  /// [legacyRank] is independent of that list's current order.
  void finalizeTrustedBatch({
    required List<DiscoverUserModel> rankedCandidates,
    required List<DiscoverStageB2TrustedPairResult> trustedPairs,
  }) {
    if (!enabled) {
      reset();
      return;
    }
    final salt = _sessionSalt;
    final viewerUid = _viewerUid;
    if (salt == null || viewerUid == null) {
      reset();
      return;
    }

    final sessionId = _hashId('session|$salt');
    final viewerAnon = _anon(salt, viewerUid);
    final legacyRankByUid = _independentLegacyRanks(rankedCandidates);
    final pairs = <DiscoverStageB2PairDiagnostic>[];
    for (var i = 0; i < rankedCandidates.length; i++) {
      final candidate = rankedCandidates[i];
      final legacy = _legacyByUid[candidate.uid];
      final candidateAnon = _anon(salt, candidate.uid);
      final pairId = _hashId('pair|$salt|$viewerUid|${candidate.uid}');
      final trusted = i < trustedPairs.length ? trustedPairs[i] : null;

      final legacyAvailable =
          legacy?.available ?? (candidate.compatibilityScore != null);
      final legacyScore = legacy?.score ?? candidate.compatibilityScore;
      final legacyMissing = legacyAvailable
          ? null
          : (legacy?.missingReason ??
              candidate.compatibilityLabel ??
              'legacy_unavailable');

      pairs.add(
        DiscoverStageB2PairDiagnostic(
          pairId: pairId,
          candidateAnonId: candidateAnon,
          legacyAvailable: legacyAvailable,
          legacyScore: legacyScore,
          legacyMissingReason: legacyMissing,
          legacyRank: legacyRankByUid[candidate.uid]!,
          structuralAvailable: trusted?.available ?? false,
          structuralDistance:
              trusted?.available == true ? trusted!.structuralDistance : null,
          structuralMissingReason: trusted?.available == true
              ? null
              : (trusted?.unavailableReason ??
                  'candidate_canonical_profile_missing'),
          structuralCoverage: trusted?.totalCoverage,
          structuralComparableDims: trusted?.comparableDimensions,
          structuralRank: null,
        ),
      );
    }

    _storeFinalizedPairs(
      pairs: pairs,
      sessionId: sessionId,
      viewerAnon: viewerAnon,
    );
  }

  void _storeFinalizedPairs({
    required List<DiscoverStageB2PairDiagnostic> pairs,
    required String sessionId,
    required String viewerAnon,
  }) {
    final availableIdx = <int>[];
    for (var i = 0; i < pairs.length; i++) {
      if (pairs[i].structuralAvailable && pairs[i].structuralDistance != null) {
        availableIdx.add(i);
      }
    }
    availableIdx.sort((a, b) {
      final da = pairs[a].structuralDistance!;
      final db = pairs[b].structuralDistance!;
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
      return pairs[a].legacyRank.compareTo(pairs[b].legacyRank);
    });
    final structuralRankByIndex = <int, int>{};
    for (var r = 0; r < availableIdx.length; r++) {
      structuralRankByIndex[availableIdx[r]] = r + 1;
    }

    final finalized = <DiscoverStageB2PairDiagnostic>[
      for (var i = 0; i < pairs.length; i++)
        pairs[i].copyWith(structuralRank: structuralRankByIndex[i]),
    ];

    _session = DiscoverStageB2Session(
      sessionId: sessionId,
      viewerAnonId: viewerAnon,
      pairCount: finalized.length,
      pairs: finalized,
      capturedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
    _legacyByUid.clear();
    DiscoverStageB2ComparisonLog.debugPrintSession(_session!);
  }

  /// JSON export of [lastSession], or null if none.
  String? exportLastSessionJson({String indent = ' '}) {
    final map = exportLastSessionMap();
    if (map == null) return null;
    return JsonEncoder.withIndent(indent).convert(map);
  }

  Map<String, dynamic>? exportLastSessionMap() {
    final session = _session;
    if (session == null) return null;
    return session.toExportMap();
  }

  static String _defaultSalt() =>
      '${DateTime.now().toUtc().microsecondsSinceEpoch}|${DateTime.now().timeZoneName}';

  static String _anon(String salt, String uid) => _hashId('anon|$salt|$uid');

  static String _hashId(String material) {
    final digest = sha256.convert(utf8.encode(material));
    return digest.toString().substring(0, 16);
  }
}

class _LegacyCapture {
  const _LegacyCapture({
    required this.available,
    required this.score,
    required this.missingReason,
  });

  final bool available;
  final double? score;
  final String? missingReason;
}

/// Public pair payload from the trusted Stage B2 L2 callable.
/// Never includes 20D vectors.
class DiscoverStageB2TrustedPairResult {
  const DiscoverStageB2TrustedPairResult({
    required this.available,
    this.structuralDistance,
    required this.totalCoverage,
    required this.comparableDimensions,
    this.unavailableReason,
  });

  factory DiscoverStageB2TrustedPairResult.unavailable(String reason) {
    return DiscoverStageB2TrustedPairResult(
      available: false,
      totalCoverage: 0,
      comparableDimensions: 0,
      unavailableReason: reason,
    );
  }

  factory DiscoverStageB2TrustedPairResult.fromPublicMap(Object? raw) {
    if (raw is! Map) {
      return DiscoverStageB2TrustedPairResult.unavailable(
        'trusted_l2_callable_failed',
      );
    }
    final available = raw['available'] == true;
    final coverage = (raw['total_coverage'] as num?)?.toDouble() ?? 0.0;
    final dims = (raw['comparable_dimensions'] as num?)?.toInt() ?? 0;
    if (!available) {
      return DiscoverStageB2TrustedPairResult(
        available: false,
        totalCoverage: coverage,
        comparableDimensions: dims,
        unavailableReason: raw['unavailable_reason'] as String? ??
            'candidate_canonical_profile_missing',
      );
    }
    return DiscoverStageB2TrustedPairResult(
      available: true,
      structuralDistance: (raw['structural_distance'] as num?)?.toDouble(),
      totalCoverage: coverage,
      comparableDimensions: dims,
    );
  }

  final bool available;
  final double? structuralDistance;
  final double totalCoverage;
  final int comparableDimensions;
  final String? unavailableReason;

  /// Rankable only when the trusted callable returned a finite distance.
  /// Missing / failed L2 is never treated as 0, 0.5, or 0.42.
  bool get isRankable {
    if (!available) return false;
    final d = structuralDistance;
    if (d == null || d.isNaN || d.isInfinite || d < 0) return false;
    return true;
  }
}

/// One privacy-safe dual-path pair diagnostic.
class DiscoverStageB2PairDiagnostic {
  const DiscoverStageB2PairDiagnostic({
    required this.pairId,
    required this.candidateAnonId,
    required this.legacyAvailable,
    required this.legacyScore,
    required this.legacyMissingReason,
    required this.legacyRank,
    required this.structuralAvailable,
    required this.structuralDistance,
    required this.structuralMissingReason,
    required this.structuralCoverage,
    required this.structuralComparableDims,
    required this.structuralRank,
  });

  final String pairId;
  final String candidateAnonId;
  final bool legacyAvailable;
  final double? legacyScore;
  final String? legacyMissingReason;
  final int legacyRank;
  final bool structuralAvailable;
  final double? structuralDistance;
  final String? structuralMissingReason;
  final double? structuralCoverage;
  final int? structuralComparableDims;
  final int? structuralRank;

  DiscoverStageB2PairDiagnostic copyWith({int? structuralRank}) {
    return DiscoverStageB2PairDiagnostic(
      pairId: pairId,
      candidateAnonId: candidateAnonId,
      legacyAvailable: legacyAvailable,
      legacyScore: legacyScore,
      legacyMissingReason: legacyMissingReason,
      legacyRank: legacyRank,
      structuralAvailable: structuralAvailable,
      structuralDistance: structuralDistance,
      structuralMissingReason: structuralMissingReason,
      structuralCoverage: structuralCoverage,
      structuralComparableDims: structuralComparableDims,
      structuralRank: structuralRank ?? this.structuralRank,
    );
  }

  Map<String, dynamic> toExportMap() => {
        'pair_id': pairId,
        'candidate_anon_id': candidateAnonId,
        'legacy_available': legacyAvailable,
        if (legacyScore != null) 'legacy_score': legacyScore,
        if (legacyMissingReason != null)
          'legacy_missing_reason': legacyMissingReason,
        'legacy_rank': legacyRank,
        'structural_available': structuralAvailable,
        if (structuralDistance != null) 'D_structural': structuralDistance,
        if (structuralMissingReason != null)
          'structural_missing_reason': structuralMissingReason,
        if (structuralCoverage != null)
          'structural_coverage': structuralCoverage,
        if (structuralComparableDims != null)
          'structural_comparable_dims': structuralComparableDims,
        if (structuralRank != null) 'structural_rank': structuralRank,
      };
}

/// One Discover [getCandidates] dual-path shadow session.
class DiscoverStageB2Session {
  const DiscoverStageB2Session({
    required this.sessionId,
    required this.viewerAnonId,
    required this.pairCount,
    required this.pairs,
    required this.capturedAtIso,
  });

  final String sessionId;
  final String viewerAnonId;
  final int pairCount;
  final List<DiscoverStageB2PairDiagnostic> pairs;
  final String capturedAtIso;

  static const String exportVersion = 'discover_stage_b2_dual_path_session_v1';

  Map<String, dynamic> toExportMap() => {
        'export_version': exportVersion,
        'stage': 'B2',
        'architecture_ref': 'qmatch_final_matching_architecture_v1',
        'shadow_only': true,
        'affects_discover_ranking': false,
        'affects_ui': false,
        'fusion_weights': false,
        'temporal_included': false,
        'qi_included': false,
        'persona_included': false,
        'rvi_included': false,
        'imputation': false,
        'legacy_authoritative': true,
        'structural_scoring':
            Canonical20dGroupNormalizedShadowContract.scoringVersion,
        'structural_policy_status':
            Canonical20dGroupNormalizedShadowContract.policyStatus,
        'session_id': sessionId,
        'viewer_anon_id': viewerAnonId,
        'captured_at': capturedAtIso,
        'pair_count': pairCount,
        'privacy': const {
          'stores_raw_uid': false,
          'stores_profile_text': false,
          'stores_message_content': false,
          'stores_raw_answers': false,
          'anonymous_ids': 'sha256_truncated_hex16',
        },
        'pairs': [for (final p in pairs) p.toExportMap()],
      };
}

/// DEBUG-only Stage B2 comparison printer. Does not affect ranking or scores.
class DiscoverStageB2ComparisonLog {
  DiscoverStageB2ComparisonLog._();

  static const String prefix = 'Discover Stage B2 comparison:';

  static void debugPrintSession(DiscoverStageB2Session session) {
    if (!kDebugMode) return;
    for (final line in lines(session)) {
      debugPrint(line);
    }
  }

  static List<String> lines(DiscoverStageB2Session session) {
    final pairs = session.pairs;
    final byLegacy = List<DiscoverStageB2PairDiagnostic>.of(pairs)
      ..sort((a, b) => a.legacyRank.compareTo(b.legacyRank));
    final byStructural = pairs
        .where((p) => p.structuralAvailable && p.structuralRank != null)
        .toList()
      ..sort((a, b) => a.structuralRank!.compareTo(b.structuralRank!));

    final coverages = <double>[];
    final coverageParts = <String>[];
    for (final p in byLegacy) {
      final cov = p.structuralCoverage;
      final dims = p.structuralComparableDims;
      if (cov != null) coverages.add(cov);
      coverageParts.add(
        '${p.candidateAnonId}:'
        'cov=${cov == null ? 'n/a' : _n(cov)}'
        ' dims=${dims ?? 'n/a'}'
        '${p.structuralAvailable ? '' : ' missing=${p.structuralMissingReason ?? 'n/a'}'}',
      );
    }
    final coverageSummary = coverages.isEmpty
        ? 'available=0/${pairs.length} mean=n/a min=n/a max=n/a'
        : 'available=${coverages.length}/${pairs.length} '
            'mean=${_n(coverages.reduce((a, b) => a + b) / coverages.length)} '
            'min=${_n(coverages.reduce((a, b) => a < b ? a : b))} '
            'max=${_n(coverages.reduce((a, b) => a > b ? a : b))}';

    final rankDeltas = <String>[];
    for (final p in byLegacy) {
      final sr = p.structuralRank;
      rankDeltas.add(
        sr == null
            ? '${p.candidateAnonId}:n/a'
            : '${p.candidateAnonId}:${sr - p.legacyRank}',
      );
    }

    String overlapLine(int k) {
      final legacyTop = byLegacy.take(k).map((p) => p.candidateAnonId).toList();
      final structTop =
          byStructural.take(k).map((p) => p.candidateAnonId).toList();
      final a = legacyTop.toSet();
      final b = structTop.toSet();
      if (a.isEmpty || b.isEmpty) {
        return 'k=$k overlap=0/0 rate=n/a intersection=[] '
            'legacy=$legacyTop l2=$structTop';
      }
      final inter = a.intersection(b).toList()..sort();
      final denom = a.length < b.length ? a.length : b.length;
      return 'k=$k overlap=${inter.length}/$denom '
          'rate=${_n(inter.length / denom)} '
          'intersection=$inter legacy=$legacyTop l2=$structTop';
    }

    var inversions = 0;
    var compared = 0;
    for (var i = 0; i < byStructural.length; i++) {
      for (var j = i + 1; j < byStructural.length; j++) {
        final a = byStructural[i];
        final b = byStructural[j];
        compared++;
        final legacyPrefersA = a.legacyRank < b.legacyRank;
        final structuralPrefersA = a.structuralRank! < b.structuralRank!;
        if (legacyPrefersA != structuralPrefersA) inversions++;
      }
    }
    final disagreement = compared == 0
        ? 'inversions=0/0 rate=n/a'
        : 'inversions=$inversions/$compared rate=${_n(inversions / compared)}';

    return [
      '$prefix 20D coverage: $coverageSummary pairs=[$coverageParts]',
      '$prefix legacy candidate order: '
          '${[for (final p in byLegacy) p.candidateAnonId]}',
      '$prefix L2 group-normalized 20D order: '
          '${[for (final p in byStructural) p.candidateAnonId]}',
      '$prefix rank delta per candidate (l2-legacy): $rankDeltas',
      '$prefix top-3 overlap: ${overlapLine(3)}',
      '$prefix top-5 overlap: ${overlapLine(5)}',
      '$prefix pairwise disagreement: $disagreement',
    ];
  }

  static String _n(double v) => v.toStringAsFixed(3);
}
