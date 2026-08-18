import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../assessment/utils/assessment_language.dart';
import '../../assessment/utils/assessment_result_display_resolver.dart';
import '../../profile/utils/profile_option_labels.dart';
import '../models/discover_user_model.dart';
import '../utils/discover_identity_format.dart';
import 'qmatch_candidate_photo.dart';

/// Modern Discover candidate card. Presentation only — no Firebase / scoring.
///
/// Compatibility % chips render only when [DiscoverUserModel.compatibilityScore]
/// is already set (legacy rollback). Structural L2 ranking does not attach a
/// percentage, so this card must not invent one from `structural_distance`.
///
/// [showLegacyCompatibilityUi] is the `legacy_v1` presentation switch:
/// category/archetype chips and the compatibility hint. `structural_l2_v1`
/// keeps this false.
class QMatchCandidateCard extends StatelessWidget {
  const QMatchCandidateCard({
    super.key,
    required this.candidate,
    this.photoImageProvider,
    this.showLegacyCompatibilityUi = false,
  });

  final DiscoverUserModel candidate;

  /// Test-only deterministic photo (goldens). Production never sets this.
  final ImageProvider? photoImageProvider;

  /// When true (`legacy_v1`), show category/archetype chips and hint text.
  final bool showLegacyCompatibilityUi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final identity = formatDiscoverIdentity(
      name: candidate.name,
      age: candidate.age > 0 ? candidate.age : null,
    );
    final compatibilityLabel = candidate.compatibilityLabel == null
        ? null
        : _localizeCompatibilityLabel(l10n, candidate.compatibilityLabel!);

    return QGlassCard(
      key: const Key('qmatch-candidate-card'),
      emphasized: true,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 420;
          final photoFlex = short ? 5 : 6;
          final detailsFlex = short ? 4 : 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: photoFlex,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.card),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      QMatchCandidatePhoto(
                        photoUrl: candidate.primaryPhotoUrl,
                        semanticLabel: l10n.discoverPhotoSemanticLabel(
                          identity ?? l10n.discoverTitle,
                        ),
                        missingPhotoLabel: l10n.discoverMissingPhotoLabel,
                        imageProvider: photoImageProvider,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x66060A10),
                              Color(0xCC060A10),
                            ],
                            stops: [0.45, 0.72, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: _IdentityOverlay(
                          identity: identity,
                          compatibilityLabel: compatibilityLabel,
                          compatibilityScore: candidate.compatibilityScore,
                          percentLabelBuilder:
                              l10n.discoverPercentCompatibility,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: detailsFlex,
                child: SingleChildScrollView(
                  key: const Key('qmatch-candidate-details-scroll'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: _CandidateDetails(
                    candidate: candidate,
                    showLegacyCompatibilityUi: showLegacyCompatibilityUi,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityOverlay extends StatelessWidget {
  const _IdentityOverlay({
    required this.identity,
    required this.compatibilityLabel,
    required this.compatibilityScore,
    required this.percentLabelBuilder,
  });

  final String? identity;
  final String? compatibilityLabel;
  final double? compatibilityScore;
  final String Function(int percent) percentLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (identity != null)
          Text(
            key: const Key('qmatch-candidate-identity'),
            identity!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        if (compatibilityLabel != null || compatibilityScore != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (compatibilityLabel != null)
                _MetaChip(
                  key: const Key('qmatch-candidate-compat-label'),
                  label: compatibilityLabel!,
                  emphasized: true,
                ),
              if (compatibilityScore != null)
                _MetaChip(
                  key: const Key('qmatch-candidate-compat-score'),
                  label: percentLabelBuilder(
                    ((compatibilityScore!.clamp(0.0, 1.0)) * 100).round(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CandidateDetails extends StatelessWidget {
  const _CandidateDetails({
    required this.candidate,
    required this.showLegacyCompatibilityUi,
  });

  final DiscoverUserModel candidate;
  final bool showLegacyCompatibilityUi;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = AssessmentLanguage.languageUsed(
      languageCode: Localizations.maybeLocaleOf(context)?.languageCode,
    );

    final reasons = candidate.compatibilityReasons ?? const <String>[];
    final fromCategory =
        (candidate.category != null && candidate.category!.isNotEmpty)
            ? AssessmentResultDisplayResolver.resolveIqEqLevel(
                candidate.category!,
                languageCode: languageCode,
              )
            : null;
    final fromName =
        (candidate.archetype != null && candidate.archetype!.isNotEmpty)
            ? AssessmentResultDisplayResolver.resolveArchetypeLabel(
                candidate.archetype!,
                languageCode: languageCode,
              )
            : null;
    final primary = showLegacyCompatibilityUi ? fromCategory ?? fromName : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reasons.isNotEmpty)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: reasons
                .take(3)
                .map(
                  (r) => _MetaChip(
                    label: _localizeCompatibilityReason(l10n, r),
                  ),
                )
                .toList(),
          ),
        if (primary != null) ...[
          if (reasons.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          Wrap(
            key: const Key('qmatch-candidate-legacy-archetype-chips'),
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaChip(label: primary.title, emphasized: true),
              if (primary.tags.isNotEmpty) _MetaChip(label: primary.tags.first),
            ],
          ),
        ],
        if (candidate.bio.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            key: const Key('qmatch-candidate-bio'),
            candidate.bio.trim(),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
        if (candidate.interests.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            key: const Key('qmatch-candidate-interests-heading'),
            l10n.discoverInterests,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFDAC8ED),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: candidate.interests.take(12).map((interest) {
              return _MetaChip(
                label: ProfileOptionLabels.interest(l10n, interest),
              );
            }).toList(),
          ),
        ],
        if (showLegacyCompatibilityUi) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            key: const Key('qmatch-candidate-hint'),
            candidate.compatibilityHintLocalized(languageCode),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    super.key,
    required this.label,
    this.emphasized = false,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.resonanceViolet.withValues(alpha: 0.28)
            : AppColors.glassSurface,
        borderRadius: AppRadii.pillBorder,
        border: Border.all(
          color: emphasized
              ? AppColors.borderGlow.withValues(alpha: 0.55)
              : AppColors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _localizeCompatibilityLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'exceptional':
      return l10n.compatibilityLabelExceptional;
    case 'strong':
      return l10n.compatibilityLabelStrong;
    case 'good':
      return l10n.compatibilityLabelGood;
    case 'potential':
      return l10n.compatibilityLabelPotential;
    case 'low_signal':
      return l10n.compatibilityLabelLowSignal;
    default:
      return labelKey;
  }
}

String _localizeCompatibilityReason(AppLocalizations l10n, String reasonKey) {
  switch (reasonKey) {
    case 'archetype':
      return l10n.compatReasonArchetype;
    case 'thinking':
      return l10n.compatReasonThinking;
    case 'emotional':
      return l10n.compatReasonEmotional;
    case 'frequency':
      return l10n.compatReasonFrequency;
    case 'interests':
      return l10n.compatReasonInterests;
    case 'recency':
      return l10n.compatReasonRecency;
    default:
      return reasonKey;
  }
}
