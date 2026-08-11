import '../../matching/domain/canonical_20d_shadow_distance.dart';
import '../models/discover_user_model.dart';
import 'discover_canonical_20d_shadow.dart';

/// Attaches shadow 20D distance diagnostics **after** legacy ranking.
///
/// Pure helper: never reorders [rankedCandidates] and never mutates
/// compatibility score / label / reasons on returned models.
class DiscoverShadowDistanceAttacher {
  const DiscoverShadowDistanceAttacher({
    Canonical20dShadowDistanceMatcher matcher =
        const Canonical20dShadowDistanceMatcher(),
  }) : _matcher = matcher;

  final Canonical20dShadowDistanceMatcher _matcher;

  /// Returns the same candidate list (identity order + live compat fields)
  /// plus a uid→diagnostic map for in-memory inspection only.
  ({
    List<DiscoverUserModel> candidates,
    Map<String, DiscoverShadowDistanceDiagnostic> diagnostics,
  }) attach({
    required List<DiscoverUserModel> rankedCandidates,
    required Map<String, dynamic>? meCanonicalProfile,
    required Map<String, Map<String, dynamic>?> candidateCanonicalProfiles,
  }) {
    final meSubject = DiscoverCanonical20dShadowSubjectBuilder
        .fromCanonicalProfile(meCanonicalProfile);
    final diagnostics = <String, DiscoverShadowDistanceDiagnostic>{};

    if (meSubject != null) {
      for (final candidate in rankedCandidates) {
        final profile = candidateCanonicalProfiles[candidate.uid];
        final other = DiscoverCanonical20dShadowSubjectBuilder
            .fromCanonicalProfile(profile);
        if (other == null) continue;
        final result = _matcher.compare(a: meSubject, b: other);
        diagnostics[candidate.uid] =
            DiscoverShadowDistanceDiagnostic.fromResult(result);
      }
    }

    // Defensive copy of the list reference order — models unchanged.
    return (
      candidates: List<DiscoverUserModel>.unmodifiable(rankedCandidates),
      diagnostics: Map.unmodifiable(diagnostics),
    );
  }
}
