import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../matching/domain/canonical_20d_group_normalized_shadow.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';

/// Stage B2 dual-path shadow collector (legacy vs group-normalized 20D).
///
/// Privacy-safe, in-memory only. Disabled unless [enabled] is true.
/// Never affects Discover ranking/UI. No fusion, temporal, QI, Persona, RVI,
/// or imputation of missing 20D values.
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

  /// Attach structural distances + ranks after legacy sort (authoritative order).
  ///
  /// [rankedCandidates] must already be sorted by live CompatibilityScoring.
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
    final meSubject = DiscoverCanonical20dShadowSubjectBuilder
        .fromCanonicalProfile(meCanonicalProfile);

    final pairs = <DiscoverStageB2PairDiagnostic>[];
    for (var i = 0; i < rankedCandidates.length; i++) {
      final candidate = rankedCandidates[i];
      final legacy = _legacyByUid[candidate.uid];
      final candidateAnon = _anon(salt, candidate.uid);
      final pairId = _hashId('pair|$salt|$viewerUid|${candidate.uid}');

      final legacyAvailable = legacy?.available ??
          (candidate.compatibilityScore != null);
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
        final other = DiscoverCanonical20dShadowSubjectBuilder
            .fromCanonicalProfile(profile);
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
          legacyRank: i + 1,
          structuralAvailable: structuralAvailable,
          structuralDistance: dStructural,
          structuralMissingReason: structuralMissing,
          structuralCoverage: structuralCoverage,
          structuralComparableDims: structuralComparableDims,
          structuralRank: null, // filled below
        ),
      );
    }

    // Structural ranks among structural-available pairs only (closer = better).
    final availableIdx = <int>[];
    for (var i = 0; i < pairs.length; i++) {
      if (pairs[i].structuralAvailable &&
          pairs[i].structuralDistance != null) {
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

  static String _anon(String salt, String uid) =>
      _hashId('anon|$salt|$uid');

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

  static const String exportVersion =
      'discover_stage_b2_dual_path_session_v1';

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
